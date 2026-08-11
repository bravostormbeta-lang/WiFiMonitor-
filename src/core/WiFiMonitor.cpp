#include "WiFiMonitor.h"

WiFiMonitor::WiFiMonitor(IWiFiPlatform* platform)
    : platform(platform)
{
}

WiFiNetwork WiFiMonitor::getCurrentNetwork() const
{
    return platform->getCurrentNetwork();
}