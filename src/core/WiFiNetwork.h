#ifndef WIFI_NETWORK_H
#define WIFI_NETWORK_H

#include <string>

struct WiFiNetwork
{
    // Connection state
    bool connected = false;

    // Network identity
    std::string ssid;
    std::string bssid;

    // Signal / radio measurements
    int signalStrength = 0;
    int noise = 0;
    double transmitRate = 0.0;

    // Channel information
    int channel = 0;
    std::string band;
    std::string phyMode;
    std::string channelWidth;

    // Derived signal metrics
    int snr = 0;

    std::string signalQuality;
    std::string snrQuality;
};

#endif