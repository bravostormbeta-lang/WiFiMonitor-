#ifndef WIFIMONITORCONTROLLER_H
#define WIFIMONITORCONTROLLER_H

#include <QObject>
#include <QTimer>

#include "../core/WiFiMonitor.h"
#include "../platform/macos/WiFiMacOS.h"

class WiFiMonitorController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int signalStrength READ signalStrength NOTIFY signalStrengthChanged)
    Q_PROPERTY(QString ssid READ ssid NOTIFY ssidChanged)
    Q_PROPERTY(QString bssid READ bssid NOTIFY bssidChanged)
    Q_PROPERTY(int noise READ noise NOTIFY noiseChanged)
    Q_PROPERTY(double transmitRate READ transmitRate NOTIFY transmitRateChanged)
    Q_PROPERTY(int channel READ channel NOTIFY channelChanged)
    Q_PROPERTY(QString band READ band NOTIFY bandChanged)
    Q_PROPERTY(QString phyMode READ phyMode NOTIFY phyModeChanged)
    Q_PROPERTY(QString channelWidth READ channelWidth NOTIFY channelWidthChanged)

public:
    explicit WiFiMonitorController(QObject *parent = nullptr);

    int signalStrength() const;
    QString ssid() const;
    QString bssid() const;
    int noise() const;
    double transmitRate() const;
    int channel() const;
    QString band() const;
    QString phyMode() const;
    QString channelWidth() const;

    void refresh();

signals:
    void signalStrengthChanged();
    void ssidChanged();
    void bssidChanged();
    void noiseChanged();
    void transmitRateChanged();
    void channelChanged();
    void bandChanged();
    void phyModeChanged();
    void channelWidthChanged();
    

private:
    WiFiMacOS platform;
    WiFiMonitor monitor;
    QTimer timer;

    WiFiNetwork currentNetwork;
};

#endif