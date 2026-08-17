#ifndef WIFIMONITORCONTROLLER_H
#define WIFIMONITORCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QString>

#include "../core/WiFiMonitor.h"
#include "../core/WiFiHistory.h"
#include "../platform/macos/WiFiMacOS.h"

class WiFiMonitorController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(
        bool connected
        READ connected
        NOTIFY connectedChanged
    )

    Q_PROPERTY(
        int signalStrength
        READ signalStrength
        NOTIFY signalStrengthChanged
    )

    Q_PROPERTY(
        QString ssid
        READ ssid
        NOTIFY ssidChanged
    )

    Q_PROPERTY(
        QString bssid
        READ bssid
        NOTIFY bssidChanged
    )

    Q_PROPERTY(
        int noise
        READ noise
        NOTIFY noiseChanged
    )

    Q_PROPERTY(
        double transmitRate
        READ transmitRate
        NOTIFY transmitRateChanged
    )

    Q_PROPERTY(
        int channel
        READ channel
        NOTIFY channelChanged
    )

    Q_PROPERTY(
        QString band
        READ band
        NOTIFY bandChanged
    )

    Q_PROPERTY(
        QString phyMode
        READ phyMode
        NOTIFY phyModeChanged
    )

    Q_PROPERTY(
        QString channelWidth
        READ channelWidth
        NOTIFY channelWidthChanged
    )

    Q_PROPERTY(
        int snr
        READ snr
        NOTIFY snrChanged
    )

    Q_PROPERTY(
        QString signalQuality
        READ signalQuality
        NOTIFY signalQualityChanged
    )

    Q_PROPERTY(
        QString snrQuality
        READ snrQuality
        NOTIFY snrQualityChanged
    )

    Q_PROPERTY(
        QVariantList rssiHistory
        READ rssiHistory
        NOTIFY historyChanged
    )

    Q_PROPERTY(
        QVariantList snrHistory
        READ snrHistory
        NOTIFY historyChanged
    )

    Q_PROPERTY(
        QVariantList noiseHistory
        READ noiseHistory
        NOTIFY historyChanged
    )

    Q_PROPERTY(
        QVariantList transmitRateHistory
        READ transmitRateHistory
        NOTIFY historyChanged
    )


public:

    explicit WiFiMonitorController(
        QObject *parent = nullptr
    );

    bool connected() const;

    int signalStrength() const;

    QString ssid() const;

    QString bssid() const;

    int noise() const;

    double transmitRate() const;

    int channel() const;

    QString band() const;

    QString phyMode() const;

    QString channelWidth() const;

    int snr() const;

    QString signalQuality() const;

    QString snrQuality() const;

    QVariantList rssiHistory() const;

    QVariantList snrHistory() const;

    QVariantList noiseHistory() const;

    QVariantList transmitRateHistory() const;

    void refresh();


signals:

    void connectedChanged();

    void signalStrengthChanged();

    void ssidChanged();

    void bssidChanged();

    void noiseChanged();

    void transmitRateChanged();

    void channelChanged();

    void bandChanged();

    void phyModeChanged();

    void channelWidthChanged();

    void snrChanged();

    void signalQualityChanged();

    void snrQualityChanged();

    void historyChanged();


private:

    WiFiMacOS platform;

    WiFiMonitor monitor;

    QTimer timer;

    WiFiNetwork currentNetwork;

    WiFiHistory history;
};

#endif