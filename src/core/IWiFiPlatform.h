#ifndef I_WIFI_PLATFORM_H
#define I_WIFI_PLATFORM_H

#include "WiFiNetwork.h"

#include <vector>

class IWiFiPlatform
{
public:

    virtual ~IWiFiPlatform() = default;


    // ============================================================
    // Current Wi-Fi connection
    // ============================================================

    virtual WiFiNetwork getCurrentNetwork() = 0;


    // ============================================================
    // Nearby Wi-Fi networks
    // ============================================================

    /*
     * Perform a fresh scan and return the networks currently
     * visible to the operating system.
     */
    virtual std::vector<WiFiNetwork> scanNetworks() = 0;
};

#endif