#ifndef WIFI_MONITOR_H
#define WIFI_MONITOR_H

#include "WiFiNetwork.h"
#include "IWiFiPlatform.h"

class WiFiMonitor
{
public:
    explicit WiFiMonitor(IWiFiPlatform* platform);

    WiFiNetwork getCurrentNetwork();

private:
    IWiFiPlatform* platform;
};

#endif