#ifndef WIFI_NETWORK_H
#define WIFI_NETWORK_H

#include <string>

struct WiFiNetwork
{
    bool connected = false;

    std::string ssid;
    std::string bssid;

    int signalStrength = 0;
    int noise = 0;

    double transmitRate = 0.0;

    int channel = 0;

    std::string band;
    std::string phyMode;
    std::string channelWidth;
};

#endif