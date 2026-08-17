#ifndef WIFI_MACOS_H
#define WIFI_MACOS_H

#include "../../core/IWiFiPlatform.h"

#include <functional>

class WiFiMacOSPrivate;

class WiFiMacOS : public IWiFiPlatform
{
public:
    using LinkChangeCallback = std::function<void()>;

    WiFiMacOS();
    ~WiFiMacOS();

    WiFiNetwork getCurrentNetwork() override;

    void setLinkChangeCallback(LinkChangeCallback callback);

private:
    WiFiMacOSPrivate *d;
};

#endif