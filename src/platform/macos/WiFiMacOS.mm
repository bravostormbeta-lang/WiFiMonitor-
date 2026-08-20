#include "WiFiMacOS.h"

#import <CoreWLAN/CoreWLAN.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#include <algorithm>
#include <functional>
#include <string>
#include <vector>


// ============================================================
// Location Services delegate
// ============================================================

@interface WiFiLocationDelegate : NSObject <CLLocationManagerDelegate>
@end


@implementation WiFiLocationDelegate

- (void)locationManagerDidChangeAuthorization:
    (CLLocationManager *)manager
{
    NSLog(
        @"WiFi Monitor location authorization status: %ld",
        (long)manager.authorizationStatus
    );
}

@end


// ============================================================
// CoreWLAN event delegate
// ============================================================

@interface WiFiEventDelegate : NSObject <CWEventDelegate>

@property(nonatomic, copy)
    void (^linkChangeHandler)(NSString *interfaceName);

@end


@implementation WiFiEventDelegate

- (void)linkDidChangeForWiFiInterfaceWithName:
    (NSString *)interfaceName
{
    if (self.linkChangeHandler)
    {
        self.linkChangeHandler(interfaceName);
    }
}

@end


// ============================================================
// Private implementation
// ============================================================

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
        // --------------------------------------------------------
        // CoreWLAN client
        // --------------------------------------------------------

        client =
            [CWWiFiClient sharedWiFiClient];


        // --------------------------------------------------------
        // Wi-Fi event delegate
        // --------------------------------------------------------

        delegate =
            [[WiFiEventDelegate alloc] init];


        // --------------------------------------------------------
        // Location Services
        //
        // macOS can restrict SSID/BSSID information without
        // Location Services authorization.
        // --------------------------------------------------------

        locationDelegate =
            [[WiFiLocationDelegate alloc] init];

        locationManager =
            [[CLLocationManager alloc] init];

        locationManager.delegate =
            locationDelegate;


        if (locationManager.authorizationStatus ==
            kCLAuthorizationStatusNotDetermined)
        {
            [locationManager requestWhenInUseAuthorization];
        }


        // --------------------------------------------------------
        // Forward CoreWLAN link events into C++
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


        // --------------------------------------------------------
        // Start link-change monitoring
        // --------------------------------------------------------

        NSError *error = nil;

        BOOL success =
            [client startMonitoringEventWithType:
                        CWEventTypeLinkDidChange
                                           error:&error];

        if (success)
        {
            NSLog(
                @"CoreWLAN link-change event monitoring started."
            );
        }
        else
        {
            NSLog(
                @"Failed to start CoreWLAN link-change "
                @"event monitoring: %@",
                error
            );
        }
    }
};


// ============================================================
// WiFiMacOS
// ============================================================

WiFiMacOS::WiFiMacOS()
    : d(new WiFiMacOSPrivate)
{
}


WiFiMacOS::~WiFiMacOS()
{
    delete d;
}


// ============================================================
// Link-change callback
// ============================================================

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


// ============================================================
// Current network
// ============================================================

WiFiNetwork WiFiMacOS::getCurrentNetwork()
{
    WiFiNetwork network;

    CWWiFiClient *client =
        [CWWiFiClient sharedWiFiClient];

    CWInterface *interface =
        [client interface];


    if (interface == nil)
    {
        return network;
    }


    // --------------------------------------------------------
    // Determine connection state
    // --------------------------------------------------------

    CWPHYMode activePHYMode =
        [interface activePHYMode];

    network.connected =
        (activePHYMode != kCWPHYModeNone);


    // --------------------------------------------------------
    // If we're not connected, return the default network.
    // --------------------------------------------------------

    if (!network.connected)
    {
        return network;
    }


    // --------------------------------------------------------
    // SSID
    // --------------------------------------------------------

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


    // --------------------------------------------------------
    // SSID fallback
    // --------------------------------------------------------

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


    // --------------------------------------------------------
    // BSSID
    // --------------------------------------------------------

    NSString *bssid =
        [interface bssid];

    if (bssid != nil)
    {
        network.bssid =
            [bssid UTF8String];
    }


    // --------------------------------------------------------
    // Signal measurements
    // --------------------------------------------------------

    network.signalStrength =
        [interface rssiValue];

    network.noise =
        [interface noiseMeasurement];

    network.transmitRate =
        [interface transmitRate];


    // --------------------------------------------------------
    // PHY mode
    // --------------------------------------------------------

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


    // --------------------------------------------------------
    // Channel
    // --------------------------------------------------------

    CWChannel *channel =
        [interface wlanChannel];

    if (channel != nil)
    {
        network.channel =
            [channel channelNumber];


        // ----------------------------------------------------
        // Band
        // ----------------------------------------------------

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


        // ----------------------------------------------------
        // Channel width
        // ----------------------------------------------------

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


    // --------------------------------------------------------
    // SNR
    // --------------------------------------------------------

    network.snr =
        network.signalStrength -
        network.noise;


    // --------------------------------------------------------
    // Signal quality
    // --------------------------------------------------------

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


    // --------------------------------------------------------
    // SNR quality
    // --------------------------------------------------------

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


    return network;
}


// ============================================================
// Nearby network scanner
// ============================================================

std::vector<WiFiNetwork> WiFiMacOS::scanNetworks()
{
    std::vector<WiFiNetwork> networks;


    // --------------------------------------------------------
    // Get Wi-Fi interface
    // --------------------------------------------------------

    CWWiFiClient *client =
        [CWWiFiClient sharedWiFiClient];

    CWInterface *interface =
        [client interface];


    if (interface == nil)
    {
        NSLog(
            @"WiFi Monitor: no Wi-Fi interface available."
        );

        return networks;
    }


    // --------------------------------------------------------
    // Make sure Wi-Fi is powered on
    // --------------------------------------------------------

    if (![interface powerOn])
    {
        NSLog(
            @"WiFi Monitor: Wi-Fi is powered off."
        );

        return networks;
    }


    NSLog(
        @"WiFi Monitor: starting nearby-network scan..."
    );


    // --------------------------------------------------------
    // Perform broadcast scan
    //
    // nil = scan for all available SSIDs
    // YES = include hidden networks when available
    // --------------------------------------------------------

    NSError *error = nil;

    NSSet<CWNetwork *> *results =
        [interface scanForNetworksWithName:nil
                             includeHidden:YES
                                     error:&error];


    if (results == nil)
    {
        NSLog(
            @"WiFi Monitor: scan failed: %@",
            error
        );

        return networks;
    }


    // --------------------------------------------------------
    // Convert CoreWLAN results into WiFiNetwork objects
    // --------------------------------------------------------

    for (CWNetwork *result in results)
    {
        if (result == nil)
        {
            continue;
        }


        WiFiNetwork network;


        // ----------------------------------------------------
        // A scanned network is not automatically the current
        // network.
        // ----------------------------------------------------

        network.connected = false;


        // ----------------------------------------------------
        // SSID
        // ----------------------------------------------------

        NSString *ssid =
            [result ssid];

        if (ssid != nil)
        {
            network.ssid =
                [ssid UTF8String];
        }


        // ----------------------------------------------------
        // BSSID
        // ----------------------------------------------------

        NSString *bssid =
            [result bssid];

        if (bssid != nil)
        {
            network.bssid =
                [bssid UTF8String];
        }


        // ----------------------------------------------------
        // RSSI
        // ----------------------------------------------------

        network.signalStrength =
            [result rssiValue];


        // ----------------------------------------------------
        // Noise
        // ----------------------------------------------------

        network.noise =
            [result noiseMeasurement];


        // ----------------------------------------------------
        // Channel
        // ----------------------------------------------------

        CWChannel *networkChannel =
            [result wlanChannel];

        if (networkChannel != nil)
        {
            network.channel =
                [networkChannel channelNumber];


            // ------------------------------------------------
            // Band
            // ------------------------------------------------

            switch ([networkChannel channelBand])
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


            // ------------------------------------------------
            // Channel width
            // ------------------------------------------------

            switch ([networkChannel channelWidth])
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


        // ----------------------------------------------------
        // Nearby networks do not provide the same current-link
        // transmit rate / PHY information.
        // ----------------------------------------------------

        network.transmitRate = 0.0;
        network.phyMode = "Unknown";


        // ----------------------------------------------------
        // Derived SNR
        // ----------------------------------------------------

        network.snr =
            network.signalStrength -
            network.noise;


        // ----------------------------------------------------
        // Signal quality
        // ----------------------------------------------------

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


        // ----------------------------------------------------
        // SNR quality
        // ----------------------------------------------------

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


        networks.push_back(network);
    }


    // --------------------------------------------------------
    // Sort strongest → weakest
    //
    // RSSI:
    // -40 dBm > -60 dBm > -80 dBm
    // --------------------------------------------------------

    std::sort(
        networks.begin(),
        networks.end(),
        [](const WiFiNetwork &a,
           const WiFiNetwork &b)
        {
            return a.signalStrength >
                   b.signalStrength;
        }
    );


    // --------------------------------------------------------
    // Print scan results for this development stage
    // --------------------------------------------------------

    NSLog(
        @"WiFi Monitor: scan found %lu networks.",
        (unsigned long)networks.size()
    );


    for (const WiFiNetwork &network : networks)
    {
        NSLog(
            @"WiFi NETWORK: SSID=\"%s\" "
            @"BSSID=\"%s\" "
            @"RSSI=%d dBm "
            @"Noise=%d dBm "
            @"SNR=%d dB "
            @"Channel=%d "
            @"Band=\"%s\"",
            network.ssid.c_str(),
            network.bssid.c_str(),
            network.signalStrength,
            network.noise,
            network.snr,
            network.channel,
            network.band.c_str()
        );
    }


    return networks;
}