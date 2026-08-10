#ifndef WIFI_MACOS_H
#define WIFI_MACOS_H

#include "../../core/IWiFiPlatform.h"

class WiFiMacOS : public IWiFiPlatform
{
public:
    WiFiNetwork getCurrentNetwork() override;
};

#endif