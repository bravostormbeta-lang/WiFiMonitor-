#ifndef WIFI_NETWORK_H
#define WIFI_NETWORK_H

#include <string>

struct WiFiNetwork
{
    std::string ssid;
    std::string bssid;

    int signalStrength;
    int noise;

    double transmitRate;

    int channel;

    std::string band;
    std::string phyMode;
    std::string channelWidth;
};

#endif