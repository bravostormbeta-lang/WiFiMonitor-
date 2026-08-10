#ifndef I_WIFI_PLATFORM_H
#define I_WIFI_PLATFORM_H

#include "WiFiNetwork.h"

class IWiFiPlatform
{
public:
    virtual WiFiNetwork getCurrentNetwork() = 0;

    virtual ~IWiFiPlatform() = default;
};

#endif