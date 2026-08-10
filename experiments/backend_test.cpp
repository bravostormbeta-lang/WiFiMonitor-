#include <iostream>

#include "../src/core/WiFiMonitor.h"
#include "../src/platform/macos/WiFiMacOS.h"

int main()
{
    WiFiMacOS platform;

    WiFiMonitor monitor(&platform);

    WiFiNetwork network = monitor.getCurrentNetwork();

    std::cout << "WiFi Monitor Backend Test\n";
    std::cout << "-------------------------\n";

    std::cout << "SSID: "
              << (network.ssid.empty() ? "Not available" : network.ssid)
              << '\n';

    std::cout << "BSSID: "
              << (network.bssid.empty() ? "Not available" : network.bssid)
              << '\n';

    std::cout << "RSSI: "
              << network.signalStrength
              << " dBm\n";

    std::cout << "Noise: "
              << network.noise
              << " dBm\n";

    std::cout << "Transmit Rate: "
              << network.transmitRate
              << " Mbps\n";

    std::cout << "Channel: "
              << network.channel
              << '\n';

    std::cout << "Band: "
              << (network.band.empty() ? "Not available" : network.band)
              << '\n';

    std::cout << "PHY: "
              << (network.phyMode.empty() ? "Not available" : network.phyMode)
              << '\n';

    std::cout << "Channel Width: "
              << (network.channelWidth.empty()
                      ? "Not available"
                      : network.channelWidth)
              << '\n';

    return 0;
}