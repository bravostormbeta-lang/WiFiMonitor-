#import <CoreWLAN/CoreWLAN.h>

#include <iostream>

int main()
{
    std::cout << "WiFi Monitor - CoreWLAN Test\n";
    std::cout << "--------------------------------\n";

    CWWiFiClient *client = [CWWiFiClient sharedWiFiClient];

    CWInterface *interface = [client interface];

    if (interface == nil)
    {
        std::cout << "No Wi-Fi interface found.\n";
        return 1;
    }

    std::cout << "Wi-Fi interface found.\n";

    NSString *ssid = [interface ssid];

    if (ssid != nil)
    {
        std::cout << "SSID: "
                  << [[ssid description] UTF8String]
                  << '\n';
    }
    else
    {
        std::cout << "SSID: Not available\n";
    }

    NSString *bssid = [interface bssid];

if (bssid != nil)
{
    std::cout << "BSSID: "
              << [[bssid description] UTF8String]
              << '\n';
}
else
{
    std::cout << "BSSID: Not available\n";
}

    std::cout << "RSSI: "
              << [interface rssiValue]
              << " dBm\n";

    std::cout << "Noise: "
              << [interface noiseMeasurement]
              << " dBm\n";

    std::cout << "Transmit Rate: "
              << [interface transmitRate]
              << " Mbps\n";

    CWPHYMode phyMode = [interface activePHYMode];

switch (phyMode)
{
    case kCWPHYMode11a:
        std::cout << "PHY: 802.11a\n";
        break;

    case kCWPHYMode11b:
        std::cout << "PHY: 802.11b\n";
        break;

    case kCWPHYMode11g:
        std::cout << "PHY: 802.11g\n";
        break;

    case kCWPHYMode11n:
        std::cout << "PHY: 802.11n\n";
        break;

    case kCWPHYMode11ac:
        std::cout << "PHY: 802.11ac\n";
        break;

    case kCWPHYMode11ax:
        std::cout << "PHY: 802.11ax\n";
        break;

    default:
        std::cout << "PHY: Unknown\n";
        break;
}         

    CWChannel *channel = [interface wlanChannel];

if (channel != nil)
{
    std::cout << "Channel: "
              << [channel channelNumber]
              << '\n';

    switch ([channel channelBand])
    {
        case kCWChannelBand2GHz:
            std::cout << "Band: 2.4 GHz\n";
            break;

        case kCWChannelBand5GHz:
            std::cout << "Band: 5 GHz\n";
            break;

        case kCWChannelBand6GHz:
            std::cout << "Band: 6 GHz\n";
            break;

        default:
            std::cout << "Band: Unknown\n";
            break;
    }

    switch ([channel channelWidth])
    {
        case kCWChannelWidth20MHz:
            std::cout << "Channel Width: 20 MHz\n";
            break;

        case kCWChannelWidth40MHz:
            std::cout << "Channel Width: 40 MHz\n";
            break;

        case kCWChannelWidth80MHz:
            std::cout << "Channel Width: 80 MHz\n";
            break;

        case kCWChannelWidth160MHz:
            std::cout << "Channel Width: 160 MHz\n";
            break;

        default:
            std::cout << "Channel Width: Unknown\n";
            break;
    }
}
else
{
    std::cout << "Channel: Not available\n";
    std::cout << "Band: Not available\n";
    std::cout << "Channel Width: Not available\n";
}

return 0;
}