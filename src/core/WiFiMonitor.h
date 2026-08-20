#ifndef WIFI_MONITOR_H
#define WIFI_MONITOR_H

#include "WiFiNetwork.h"
#include "IWiFiPlatform.h"

#include <vector>

class WiFiMonitor
{
public:

    explicit WiFiMonitor(
        IWiFiPlatform* platform
    );


    // ============================================================
    // Current connection
    // ============================================================

    WiFiNetwork getCurrentNetwork() const;


    // ============================================================
    // Nearby networks
    // ============================================================

    std::vector<WiFiNetwork> scanNetworks() const;


private:

    IWiFiPlatform* platform;
};

#endif