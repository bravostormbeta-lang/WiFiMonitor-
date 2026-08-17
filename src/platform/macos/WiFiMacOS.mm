#include "WiFiMacOS.h"

#import <CoreWLAN/CoreWLAN.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#include <functional>
#include <string>


// ================================================================
// Location Services Delegate
// ================================================================

@interface WiFiLocationDelegate : NSObject <CLLocationManagerDelegate>
@end

@implementation WiFiLocationDelegate

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    NSLog(@"WiFi Monitor location authorization status: %ld",
          (long)manager.authorizationStatus);
}

@end


// ================================================================
// CoreWLAN Event Delegate
// ================================================================

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


// ================================================================
// Private implementation
// ================================================================

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

        locationDelegate =
            [[WiFiLocationDelegate alloc] init];

        locationManager =
            [[CLLocationManager alloc] init];

        locationManager.delegate =
            locationDelegate;


        // --------------------------------------------------------
        // Request Location Services permission.
        //
        // macOS may restrict SSID/BSSID information unless
        // Location Services permission is available.
        // --------------------------------------------------------

        if (locationManager.authorizationStatus ==
            kCLAuthorizationStatusNotDetermined)
        {
            [locationManager requestWhenInUseAuthorization];
        }


        // --------------------------------------------------------
        // Forward CoreWLAN link-change events to C++.
        // --------------------------------------------------------

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


// ================================================================
// Constructor / Destructor
// ================================================================

WiFiMacOS::WiFiMacOS()
    : d(new WiFiMacOSPrivate)
{
}


WiFiMacOS::~WiFiMacOS()
{
    delete d;
}


// ================================================================
// Link-change callback
// ================================================================

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


// ================================================================
// Get current Wi-Fi network
// ================================================================

WiFiNetwork WiFiMacOS::getCurrentNetwork()
{
    WiFiNetwork network;


    CWWiFiClient *client =
        [CWWiFiClient sharedWiFiClient];

    CWInterface *interface =
        [client interface];


    // ------------------------------------------------------------
    // No Wi-Fi interface available.
    // ------------------------------------------------------------

    if (interface == nil)
    {
        return network;
    }


    // ------------------------------------------------------------
    // Determine connection state.
    //
    // kCWPHYModeNone means the interface isn't currently
    // participating in a Wi-Fi network.
    // ------------------------------------------------------------

    CWPHYMode activePHYMode =
        [interface activePHYMode];


    network.connected =
        (activePHYMode != kCWPHYModeNone);


    // ============================================================
    // If disconnected, return the default network.
    //
    // This prevents stale SSID/BSSID/radio information from
    // remaining on the dashboard after Wi-Fi is turned off.
    // ============================================================

    if (!network.connected)
    {
        network.signalStrength = 0;
        network.noise = 0;
        network.transmitRate = 0.0;

        network.channel = 0;

        network.snr = 0;

        network.ssid.clear();
        network.bssid.clear();

        network.band.clear();
        network.phyMode.clear();
        network.channelWidth.clear();

        network.signalQuality.clear();
        network.snrQuality.clear();

        return network;
    }


    // ============================================================
    // SSID
    // ============================================================

    NSData *ssidData =
        [interface ssidData];


    if (ssidData != nil)
    {
        NSString *ssid =
            [[NSString alloc]
                initWithData:ssidData
                    encoding:NSUTF8StringEncoding];


        if (ssid != nil)
        {
            network.ssid =
                [ssid UTF8String];
        }
    }


    // ------------------------------------------------------------
    // Fallback to string-based SSID API.
    // ------------------------------------------------------------

    if (network.ssid.empty())
    {
        NSString *ssid =
            [interface ssid];


        if (ssid != nil)
        {
            network.ssid =
                [ssid UTF8String];
        }
    }


    // ============================================================
    // BSSID
    // ============================================================

    NSString *bssid =
        [interface bssid];


    if (bssid != nil)
    {
        network.bssid =
            [bssid UTF8String];
    }


    // ============================================================
    // LIVE RADIO MEASUREMENTS
    // ============================================================

    network.signalStrength =
        [interface rssiValue];


    network.noise =
        [interface noiseMeasurement];


    network.transmitRate =
        [interface transmitRate];


    // ============================================================
    // SNR
    //
    // SNR = RSSI - Noise
    //
    // Example:
    //
    // RSSI  = -55 dBm
    // Noise = -90 dBm
    //
    // SNR = -55 - (-90)
    //     = 35 dB
    // ============================================================

    network.snr =
        network.signalStrength - network.noise;


    // ============================================================
    // SIGNAL QUALITY
    // ============================================================

    if (network.signalStrength >= -50)
    {
        network.signalQuality = "Excellent";
    }
    else if (network.signalStrength >= -60)
    {
        network.signalQuality = "Good";
    }
    else if (network.signalStrength >= -70)
    {
        network.signalQuality = "Fair";
    }
    else
    {
        network.signalQuality = "Weak";
    }


    // ============================================================
    // SNR QUALITY
    // ============================================================

    if (network.snr >= 40)
    {
        network.snrQuality = "Excellent";
    }
    else if (network.snr >= 25)
    {
        network.snrQuality = "Good";
    }
    else if (network.snr >= 15)
    {
        network.snrQuality = "Fair";
    }
    else
    {
        network.snrQuality = "Poor";
    }


    // ============================================================
    // PHY MODE
    // ============================================================

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


    // ============================================================
    // CHANNEL / BAND / CHANNEL WIDTH
    // ============================================================

    CWChannel *channel =
        [interface wlanChannel];


    if (channel != nil)
    {
        // --------------------------------------------------------
        // Channel number
        // --------------------------------------------------------

        network.channel =
            [channel channelNumber];


        // --------------------------------------------------------
        // Frequency band
        // --------------------------------------------------------

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


        // --------------------------------------------------------
        // Channel width
        // --------------------------------------------------------

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