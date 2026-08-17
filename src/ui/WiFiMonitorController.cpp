#include "WiFiMonitorController.h"

WiFiMonitorController::WiFiMonitorController(QObject *parent)
    : QObject(parent),
      platform(),
      monitor(&platform)
{
    currentNetwork = monitor.getCurrentNetwork();

    m_connected = currentNetwork.connected;

    platform.setLinkChangeCallback(
        [this]()
        {
            refresh();
        }
    );

    timer.setInterval(1000);

    connect(&timer, &QTimer::timeout,
            this, &WiFiMonitorController::refresh);

    timer.start();
}

int WiFiMonitorController::signalStrength() const
{
    return currentNetwork.signalStrength;
}

QString WiFiMonitorController::ssid() const
{
    return QString::fromStdString(currentNetwork.ssid);
}

QString WiFiMonitorController::bssid() const
{
    return QString::fromStdString(currentNetwork.bssid);
}

int WiFiMonitorController::noise() const
{
    return currentNetwork.noise;
}

double WiFiMonitorController::transmitRate() const
{
    return currentNetwork.transmitRate;
}

int WiFiMonitorController::channel() const
{
    return currentNetwork.channel;
}

QString WiFiMonitorController::band() const
{
    return QString::fromStdString(currentNetwork.band);
}

QString WiFiMonitorController::phyMode() const
{
    return QString::fromStdString(currentNetwork.phyMode);
}

QString WiFiMonitorController::channelWidth() const
{
    return QString::fromStdString(currentNetwork.channelWidth);
}

bool WiFiMonitorController::connected() const
{
    return m_connected;
}

void WiFiMonitorController::refresh()
{
    WiFiNetwork newNetwork = monitor.getCurrentNetwork();

    bool newConnected = newNetwork.connected;

    if (newConnected != m_connected)
    {
        m_connected = newConnected;
        emit connectedChanged();
    }

    if (newNetwork.connected != currentNetwork.connected)
{
    currentNetwork.connected = newNetwork.connected;
}

    if (newNetwork.signalStrength != currentNetwork.signalStrength)
    {
        currentNetwork.signalStrength = newNetwork.signalStrength;
        emit signalStrengthChanged();
    }

    if (newNetwork.ssid != currentNetwork.ssid)
    {
        currentNetwork.ssid = newNetwork.ssid;
        emit ssidChanged();
    }

    if (newNetwork.bssid != currentNetwork.bssid)
    {
        currentNetwork.bssid = newNetwork.bssid;
        emit bssidChanged();
    }

    if (newNetwork.noise != currentNetwork.noise)
    {
        currentNetwork.noise = newNetwork.noise;
        emit noiseChanged();
    }

    if (newNetwork.transmitRate != currentNetwork.transmitRate)
    {
        currentNetwork.transmitRate = newNetwork.transmitRate;
        emit transmitRateChanged();
    }

    if (newNetwork.channel != currentNetwork.channel)
    {
        currentNetwork.channel = newNetwork.channel;
        emit channelChanged();
    }

    if (newNetwork.band != currentNetwork.band)
    {
        currentNetwork.band = newNetwork.band;
        emit bandChanged();
    }

    if (newNetwork.phyMode != currentNetwork.phyMode)
    {
        currentNetwork.phyMode = newNetwork.phyMode;
        emit phyModeChanged();
    }

    if (newNetwork.channelWidth != currentNetwork.channelWidth)
    {
        currentNetwork.channelWidth = newNetwork.channelWidth;
        emit channelWidthChanged();
    }
}