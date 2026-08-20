#ifndef WIFIMONITORCONTROLLER_H
#define WIFIMONITORCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QString>

#include <map>
#include <string>

#include "../core/WiFiMonitor.h"
#include "../core/WiFiHistory.h"
#include "../core/WiFiChannelAnalyzer.h"
#include "../platform/macos/WiFiMacOS.h"


class WiFiMonitorController : public QObject
{
    Q_OBJECT

    // ============================================================
    // Current connection
    // ============================================================

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(int signalStrength READ signalStrength NOTIFY signalStrengthChanged)
    Q_PROPERTY(QString ssid READ ssid NOTIFY ssidChanged)
    Q_PROPERTY(QString bssid READ bssid NOTIFY bssidChanged)
    Q_PROPERTY(int noise READ noise NOTIFY noiseChanged)
    Q_PROPERTY(double transmitRate READ transmitRate NOTIFY transmitRateChanged)
    Q_PROPERTY(int channel READ channel NOTIFY channelChanged)
    Q_PROPERTY(QString band READ band NOTIFY bandChanged)
    Q_PROPERTY(QString phyMode READ phyMode NOTIFY phyModeChanged)
    Q_PROPERTY(QString channelWidth READ channelWidth NOTIFY channelWidthChanged)
    Q_PROPERTY(int snr READ snr NOTIFY snrChanged)
    Q_PROPERTY(QString signalQuality READ signalQuality NOTIFY signalQualityChanged)
    Q_PROPERTY(QString snrQuality READ snrQuality NOTIFY snrQualityChanged)

    // ============================================================
    // Current connection history
    // ============================================================

    Q_PROPERTY(QVariantList rssiHistory READ rssiHistory NOTIFY historyChanged)
    Q_PROPERTY(QVariantList snrHistory READ snrHistory NOTIFY historyChanged)
    Q_PROPERTY(QVariantList noiseHistory READ noiseHistory NOTIFY historyChanged)
    Q_PROPERTY(QVariantList transmitRateHistory READ transmitRateHistory NOTIFY historyChanged)

    // ============================================================
    // Nearby networks
    // ============================================================

    Q_PROPERTY(QVariantList nearbyNetworks READ nearbyNetworks NOTIFY nearbyNetworksChanged)
    Q_PROPERTY(int nearbyNetworkCount READ nearbyNetworkCount NOTIFY nearbyNetworkStatsChanged)
    Q_PROPERTY(int networks24GHz READ networks24GHz NOTIFY nearbyNetworkStatsChanged)
    Q_PROPERTY(int networks5GHz READ networks5GHz NOTIFY nearbyNetworkStatsChanged)
    Q_PROPERTY(int networks6GHz READ networks6GHz NOTIFY nearbyNetworkStatsChanged)

    Q_PROPERTY(QVariantList channelStatistics READ channelStatistics NOTIFY channelStatisticsChanged)

    Q_PROPERTY(bool nearbyMonitoring READ nearbyMonitoring NOTIFY nearbyMonitoringChanged)

    // ============================================================
    // Selected nearby network
    // ============================================================

    Q_PROPERTY(QString selectedNetworkBssid READ selectedNetworkBssid NOTIFY selectedNetworkChanged)
    Q_PROPERTY(QVariantList selectedNetworkRssiHistory READ selectedNetworkRssiHistory NOTIFY selectedNetworkHistoryChanged)
    Q_PROPERTY(QVariantList selectedNetworkSnrHistory READ selectedNetworkSnrHistory NOTIFY selectedNetworkHistoryChanged)

    // ============================================================
    // Channel intelligence
    // ============================================================

    Q_PROPERTY(QVariantList channelAnalyses READ channelAnalyses NOTIFY channelAnalysesChanged)
    Q_PROPERTY(int recommended24GHzChannel READ recommended24GHzChannel NOTIFY channelRecommendationsChanged)
    Q_PROPERTY(int recommended5GHzChannel READ recommended5GHzChannel NOTIFY channelRecommendationsChanged)
    Q_PROPERTY(int recommended6GHzChannel READ recommended6GHzChannel NOTIFY channelRecommendationsChanged)
    Q_PROPERTY(QVariantList channelRecommendations READ channelRecommendations NOTIFY channelRecommendationsChanged)


public:

    explicit WiFiMonitorController(QObject *parent = nullptr);

    // ============================================================
    // Current connection
    // ============================================================

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

    // ============================================================
    // History
    // ============================================================

    QVariantList rssiHistory() const;
    QVariantList snrHistory() const;
    QVariantList noiseHistory() const;
    QVariantList transmitRateHistory() const;

    // ============================================================
    // Nearby networks
    // ============================================================

    QVariantList nearbyNetworks() const;
    int nearbyNetworkCount() const;
    int networks24GHz() const;
    int networks5GHz() const;
    int networks6GHz() const;
    QVariantList channelStatistics() const;
    bool nearbyMonitoring() const;

    // ============================================================
    // Selected network
    // ============================================================

    QString selectedNetworkBssid() const;
    QVariantList selectedNetworkRssiHistory() const;
    QVariantList selectedNetworkSnrHistory() const;

    // ============================================================
    // Channel intelligence
    // ============================================================

    QVariantList channelAnalyses() const;
    int recommended24GHzChannel() const;
    int recommended5GHzChannel() const;
    int recommended6GHzChannel() const;
    QVariantList channelRecommendations() const;

    // ============================================================
    // Operations
    // ============================================================

    void refresh();

    Q_INVOKABLE void scanNetworks();
    Q_INVOKABLE void stopNearbyMonitoring();
    Q_INVOKABLE void selectNetwork(const QString &bssid);


signals:

    // Current connection
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

    // History
    void historyChanged();

    // Nearby networks
    void nearbyNetworksChanged();
    void nearbyNetworkStatsChanged();
    void channelStatisticsChanged();
    void nearbyMonitoringChanged();

    // Selected network
    void selectedNetworkChanged();
    void selectedNetworkHistoryChanged();

    // Channel intelligence
    void channelAnalysesChanged();
    void channelRecommendationsChanged();


private:

    WiFiMacOS platform;
    WiFiMonitor monitor;
    WiFiChannelAnalyzer channelAnalyzer;

    QTimer timer;
    QTimer scanTimer;

    WiFiNetwork currentNetwork;
    WiFiHistory history;

    QVariantList m_nearbyNetworks;
    int m_nearbyNetworkCount = 0;
    int m_networks24GHz = 0;
    int m_networks5GHz = 0;
    int m_networks6GHz = 0;
    QVariantList m_channelStatistics;

    bool m_nearbyMonitoring = false;

    std::string m_selectedNetworkBssid;
    std::map<std::string, WiFiHistory> nearbyHistories;

    QVariantList m_channelAnalyses;
    int m_recommended24GHzChannel = 0;
    int m_recommended5GHzChannel = 0;
    int m_recommended6GHzChannel = 0;
    QVariantList m_channelRecommendations;
};

#endif