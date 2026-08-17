#include "WiFiMonitorController.h"

WiFiMonitorController::WiFiMonitorController(QObject *parent)
    : QObject(parent),
      platform(),
      monitor(&platform),
      history(60)
{
    currentNetwork = monitor.getCurrentNetwork();

    timer.setInterval(1000);

    connect(&timer,
            &QTimer::timeout,
            this,
            &WiFiMonitorController::refresh);

    timer.start();

    refresh();
}

bool WiFiMonitorController::connected() const
{
    return currentNetwork.connected;
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

int WiFiMonitorController::snr() const
{
    return currentNetwork.snr;
}

QString WiFiMonitorController::signalQuality() const
{
    return QString::fromStdString(currentNetwork.signalQuality);
}

QString WiFiMonitorController::snrQuality() const
{
    return QString::fromStdString(currentNetwork.snrQuality);
}

QVariantList WiFiMonitorController::rssiHistory() const
{
    QVariantList result;

    for (const int value : history.rssi())
        result.append(value);

    return result;
}

QVariantList WiFiMonitorController::snrHistory() const
{
    QVariantList result;

    for (const int value : history.snr())
        result.append(value);

    return result;
}

QVariantList WiFiMonitorController::noiseHistory() const
{
    QVariantList result;

    for (const int value : history.noise())
        result.append(value);

    return result;
}

QVariantList WiFiMonitorController::transmitRateHistory() const
{
    QVariantList result;

    for (const double value : history.transmitRate())
        result.append(value);

    return result;
}

void WiFiMonitorController::refresh()
{
    WiFiNetwork newNetwork = monitor.getCurrentNetwork();

    bool oldConnected = currentNetwork.connected;

    if (newNetwork.connected != currentNetwork.connected)
    {
        currentNetwork.connected = newNetwork.connected;
        emit connectedChanged();
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

    if (newNetwork.snr != currentNetwork.snr)
    {
        currentNetwork.snr = newNetwork.snr;
        emit snrChanged();
    }

    if (newNetwork.signalQuality != currentNetwork.signalQuality)
    {
        currentNetwork.signalQuality = newNetwork.signalQuality;
        emit signalQualityChanged();
    }

    if (newNetwork.snrQuality != currentNetwork.snrQuality)
    {
        currentNetwork.snrQuality = newNetwork.snrQuality;
        emit snrQualityChanged();
    }

    /*
     * Only record samples while connected.
     *
     * When Wi-Fi disconnects, we don't want a stream of
     * meaningless zero values filling the history graph.
     */
    if (newNetwork.connected)
    {
        history.addSample(
            newNetwork.signalStrength,
            newNetwork.snr,
            newNetwork.noise,
            newNetwork.transmitRate
        );

        emit historyChanged();
    }
    else if (oldConnected)
    {
        /*
         * Wi-Fi has just disconnected.
         *
         * Clear the old history so that when a new connection
         * appears, the graph starts fresh.
         */
        history.clear();
        emit historyChanged();
    }
}