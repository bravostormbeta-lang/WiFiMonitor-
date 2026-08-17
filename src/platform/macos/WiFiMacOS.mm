#include "WiFiMacOS.h"

#import <CoreWLAN/CoreWLAN.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#include <functional>
#include <string>

@interface WiFiLocationDelegate : NSObject <CLLocationManagerDelegate>
@end

@implementation WiFiLocationDelegate

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    NSLog(@"WiFi Monitor location authorization status: %ld",
          (long)manager.authorizationStatus);
}

@end


@interface WiFiEventDelegate : NSObject <CWEventDelegate>

@property(nonatomic, copy) void (^linkChangeHandler)(NSString *interfaceName);

@end

@implementation WiFiEventDelegate

- (void)linkDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName
{
    if (self.linkChangeHandler)
    {
        self.linkChangeHandler(interfaceName);
    }
}

@end


class WiFiMacOSPrivate
{
public:

    CWWiFiClient *client;

    __strong WiFiEventDelegate *delegate;

    __strong CLLocationManager *locationManager;
    __strong WiFiLocationDelegate *locationDelegate;

    std::function<void(NSString *)> linkChangeHandler;

    WiFiMacOSPrivate()
    {
        client = [CWWiFiClient sharedWiFiClient];

        delegate = [[WiFiEventDelegate alloc] init];

        locationDelegate = [[WiFiLocationDelegate alloc] init];

        locationManager = [[CLLocationManager alloc] init];

        locationManager.delegate = locationDelegate;

        /*
         * Request macOS Location Services permission.
         *
         * SSID/BSSID access can be restricted by macOS privacy
         * controls even though other CoreWLAN measurements work.
         */
        if (locationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined)
        {
            [locationManager requestWhenInUseAuthorization];
        }

        /*
         * Forward CoreWLAN link-change events to the C++ layer.
         */
        delegate.linkChangeHandler =
            ^(NSString *interfaceName)
            {
                if (linkChangeHandler)
                {
                    linkChangeHandler(interfaceName);
                }
            };

        client.delegate = delegate;

        NSError *error = nil;

        BOOL success =
            [client startMonitoringEventWithType:
                        CWEventTypeLinkDidChange
                                         error:&error];

        if (success)
        {
            NSLog(@"CoreWLAN link-change event monitoring started.");
        }
        else
        {
            NSLog(@"Failed to start CoreWLAN link-change event monitoring: %@",
                  error);
        }
    }
};


WiFiMacOS::WiFiMacOS()
    : d(new WiFiMacOSPrivate)
{
}


WiFiMacOS::~WiFiMacOS()
{
    delete d;
}


void WiFiMacOS::setLinkChangeCallback(
    std::function<void()> callback)
{
    d->linkChangeHandler =
        [callback](NSString *)
        {
            if (callback)
            {
                callback();
            }
        };
}


WiFiNetwork WiFiMacOS::getCurrentNetwork()
{
    WiFiNetwork network;

    CWWiFiClient *client = [CWWiFiClient sharedWiFiClient];

    CWInterface *interface = [client interface];

    if (interface == nil)
    {
        return network;
    }

    /*
     * Determine connection state using the active PHY mode.
     *
     * kCWPHYModeNone means the interface is not participating
     * in a Wi-Fi network.
     */
    CWPHYMode activePHYMode = [interface activePHYMode];

    network.connected =
        (activePHYMode != kCWPHYModeNone);

    /*
     * SSID
     *
     * Prefer ssidData because it gives us the raw SSID bytes.
     */
    NSData *ssidData = [interface ssidData];

    if (ssidData != nil)
    {
        NSString *ssid =
            [[NSString alloc] initWithData:ssidData
                                   encoding:NSUTF8StringEncoding];

        if (ssid != nil)
        {
            network.ssid = [ssid UTF8String];
        }
    }

    /*
     * Fallback to the string-based SSID API.
     */
    if (network.ssid.empty())
    {
        NSString *ssid = [interface ssid];

        if (ssid != nil)
        {
            network.ssid = [ssid UTF8String];
        }
    }

    /*
     * BSSID
     */
    NSString *bssid = [interface bssid];

    if (bssid != nil)
    {
        network.bssid = [bssid UTF8String];
    }

    /*
     * Live radio measurements.
     */
    network.signalStrength =
        [interface rssiValue];

    network.noise =
        [interface noiseMeasurement];

    network.transmitRate =
        [interface transmitRate];

    /*
     * PHY mode.
     */
    switch (activePHYMode)
    {
        case kCWPHYMode11a:
            network.phyMode = "802.11a";
            break;

        case kCWPHYMode11b:
            network.phyMode = "802.11b";
            break;

        case kCWPHYMode11g:
            network.phyMode = "802.11g";
            break;

        case kCWPHYMode11n:
            network.phyMode = "802.11n";
            break;

        case kCWPHYMode11ac:
            network.phyMode = "802.11ac";
            break;

        case kCWPHYMode11ax:
            network.phyMode = "802.11ax";
            break;

        default:
            network.phyMode = "Unknown";
            break;
    }

    /*
     * Channel, band and channel width.
     */
    CWChannel *channel =
        [interface wlanChannel];

    if (channel != nil)
    {
        network.channel =
            [channel channelNumber];

        switch ([channel channelBand])
        {
            case kCWChannelBand2GHz:
                network.band = "2.4 GHz";
                break;

            case kCWChannelBand5GHz:
                network.band = "5 GHz";
                break;

            case kCWChannelBand6GHz:
                network.band = "6 GHz";
                break;

            default:
                network.band = "Unknown";
                break;
        }

        switch ([channel channelWidth])
        {
            case kCWChannelWidth20MHz:
                network.channelWidth = "20 MHz";
                break;

            case kCWChannelWidth40MHz:
                network.channelWidth = "40 MHz";
                break;

            case kCWChannelWidth80MHz:
                network.channelWidth = "80 MHz";
                break;

            case kCWChannelWidth160MHz:
                network.channelWidth = "160 MHz";
                break;

            default:
                network.channelWidth = "Unknown";
                break;
        }
    }

    return network;
}