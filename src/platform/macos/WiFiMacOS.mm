#include "WiFiMacOS.h"

#import <CoreWLAN/CoreWLAN.h>

WiFiNetwork WiFiMacOS::getCurrentNetwork()
{
    WiFiNetwork network;

    CWWiFiClient *client = [CWWiFiClient sharedWiFiClient];

    CWInterface *interface = [client interface];

    if (interface == nil)
    {
        return network;
    }

    NSString *ssid = [interface ssid];

    if (ssid != nil)
    {
        network.ssid = [[ssid description] UTF8String];
    }

    NSString *bssid = [interface bssid];

    if (bssid != nil)
    {
        network.bssid = [[bssid description] UTF8String];
    }

    network.signalStrength = [interface rssiValue];

    network.noise = [interface noiseMeasurement];

    network.transmitRate = [interface transmitRate];

    switch ([interface activePHYMode])
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

    CWChannel *channel = [interface wlanChannel];

    if (channel != nil)
    {
        network.channel = [channel channelNumber];

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