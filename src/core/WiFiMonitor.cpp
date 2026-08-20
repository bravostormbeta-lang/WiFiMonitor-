#include "WiFiMonitor.h"


WiFiMonitor::WiFiMonitor(
    IWiFiPlatform* platform
)
    : platform(platform)
{
}


// ============================================================
// Current connection
// ============================================================

WiFiNetwork WiFiMonitor::getCurrentNetwork() const
{
    return platform->getCurrentNetwork();
}


// ============================================================
// Nearby networks
// ============================================================

std::vector<WiFiNetwork> WiFiMonitor::scanNetworks() const
{
    return platform->scanNetworks();
}