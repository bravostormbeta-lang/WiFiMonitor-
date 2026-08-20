#ifndef WIFI_MACOS_H
#define WIFI_MACOS_H

#include "../../core/IWiFiPlatform.h"

#include <functional>
#include <vector>


class WiFiMacOSPrivate;


/*
 * macOS implementation of the platform-independent
 * IWiFiPlatform interface.
 *
 * WiFiMonitor only knows about IWiFiPlatform.
 * This class provides the actual macOS/CoreWLAN implementation.
 */
class WiFiMacOS : public IWiFiPlatform
{
public:

    // ============================================================
    // Construction / destruction
    // ============================================================

    WiFiMacOS();

    ~WiFiMacOS() override;


    // ============================================================
    // Current Wi-Fi connection
    // ============================================================

    /*
     * Implementation of IWiFiPlatform.
     *
     * Returns information about the Wi-Fi network currently
     * connected to this Mac.
     */
    WiFiNetwork getCurrentNetwork() override;


    // ============================================================
    // Nearby Wi-Fi networks
    // ============================================================

    /*
     * Scan for nearby Wi-Fi networks.
     *
     * This is macOS-specific functionality and therefore does
     * not need to be part of IWiFiPlatform yet.
     */
    std::vector<WiFiNetwork> scanNetworks() override;


    // ============================================================
    // Wi-Fi link-change notifications
    // ============================================================

    /*
     * Called when CoreWLAN detects that the Wi-Fi link changed.
     */
    void setLinkChangeCallback(
        std::function<void()> callback
    );


private:

    /*
     * PIMPL.
     *
     * Keeps CoreWLAN and Objective-C implementation details
     * inside WiFiMacOS.mm.
     */
    WiFiMacOSPrivate *d;
};

#endif