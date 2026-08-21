#include "WiFiMonitorController.h"

#include <QVariantMap>

#include "../core/WiFiChannelAnalyzer.h"

#include <map>
#include <string>
#include <vector>


// ============================================================
// Constructor
// ============================================================

WiFiMonitorController::WiFiMonitorController(
    IWiFiPlatform* platform,
    QObject *parent
)
    : QObject(parent),
      platform(platform),
      monitor(platform),
      history(60)
{
    // ============================================================
    // Initial current-network state
    // ============================================================

    currentNetwork =
        monitor.getCurrentNetwork();


    // ============================================================
    // Current-network refresh timer
    //
    // Frequency: 1 second
    // ============================================================

    timer.setInterval(1000);

    connect(
        &timer,
        &QTimer::timeout,
        this,
        &WiFiMonitorController::refresh
    );

    timer.start();


    // ============================================================
    // Nearby-network scan timer
    //
    // Frequency: 3 seconds
    // ============================================================

    scanTimer.setInterval(3000);

    connect(
        &scanTimer,
        &QTimer::timeout,
        this,
        &WiFiMonitorController::scanNetworks
    );


    // ============================================================
    // Initial state
    // ============================================================

    refresh();
}


// ============================================================
// Current connection
// ============================================================

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
    return QString::fromStdString(
        currentNetwork.ssid
    );
}


QString WiFiMonitorController::bssid() const
{
    return QString::fromStdString(
        currentNetwork.bssid
    );
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
    return QString::fromStdString(
        currentNetwork.band
    );
}


QString WiFiMonitorController::phyMode() const
{
    return QString::fromStdString(
        currentNetwork.phyMode
    );
}


QString WiFiMonitorController::channelWidth() const
{
    return QString::fromStdString(
        currentNetwork.channelWidth
    );
}


int WiFiMonitorController::snr() const
{
    return currentNetwork.snr;
}


QString WiFiMonitorController::signalQuality() const
{
    return QString::fromStdString(
        currentNetwork.signalQuality
    );
}


QString WiFiMonitorController::snrQuality() const
{
    return QString::fromStdString(
        currentNetwork.snrQuality
    );
}


// ============================================================
// Current connection history
// ============================================================

QVariantList WiFiMonitorController::rssiHistory() const
{
    QVariantList result;

    for (const int value : history.rssi())
    {
        result.append(value);
    }

    return result;
}


QVariantList WiFiMonitorController::snrHistory() const
{
    QVariantList result;

    for (const int value : history.snr())
    {
        result.append(value);
    }

    return result;
}


QVariantList WiFiMonitorController::noiseHistory() const
{
    QVariantList result;

    for (const int value : history.noise())
    {
        result.append(value);
    }

    return result;
}


QVariantList WiFiMonitorController::transmitRateHistory() const
{
    QVariantList result;

    for (const double value : history.transmitRate())
    {
        result.append(value);
    }

    return result;
}


// ============================================================
// Nearby networks
// ============================================================

QVariantList WiFiMonitorController::nearbyNetworks() const
{
    return m_nearbyNetworks;
}


int WiFiMonitorController::nearbyNetworkCount() const
{
    return m_nearbyNetworkCount;
}


int WiFiMonitorController::networks24GHz() const
{
    return m_networks24GHz;
}


int WiFiMonitorController::networks5GHz() const
{
    return m_networks5GHz;
}


int WiFiMonitorController::networks6GHz() const
{
    return m_networks6GHz;
}


// ============================================================
// Channel statistics
// ============================================================

QVariantList WiFiMonitorController::channelStatistics() const
{
    return m_channelStatistics;
}


// ============================================================
// Nearby monitoring state
// ============================================================

bool WiFiMonitorController::nearbyMonitoring() const
{
    return m_nearbyMonitoring;
}


// ============================================================
// Selected nearby network
// ============================================================

QString WiFiMonitorController::selectedNetworkBssid() const
{
    return QString::fromStdString(
        m_selectedNetworkBssid
    );
}


QVariantList WiFiMonitorController::selectedNetworkRssiHistory() const
{
    QVariantList result;

    if (m_selectedNetworkBssid.empty())
    {
        return result;
    }


    auto iterator =
        nearbyHistories.find(
            m_selectedNetworkBssid
        );


    if (iterator == nearbyHistories.end())
    {
        return result;
    }


    for (const int value : iterator->second.rssi())
    {
        result.append(value);
    }


    return result;
}


QVariantList WiFiMonitorController::selectedNetworkSnrHistory() const
{
    QVariantList result;

    if (m_selectedNetworkBssid.empty())
    {
        return result;
    }


    auto iterator =
        nearbyHistories.find(
            m_selectedNetworkBssid
        );


    if (iterator == nearbyHistories.end())
    {
        return result;
    }


    for (const int value : iterator->second.snr())
    {
        result.append(value);
    }


    return result;
}


void WiFiMonitorController::selectNetwork(
    const QString &bssid
)
{
    const std::string newBssid =
        bssid.toStdString();


    if (newBssid ==
        m_selectedNetworkBssid)
    {
        return;
    }


    m_selectedNetworkBssid =
        newBssid;


    emit selectedNetworkChanged();

    emit selectedNetworkHistoryChanged();
}


// ============================================================
// Channel intelligence
// ============================================================

QVariantList WiFiMonitorController::channelAnalyses() const
{
    return m_channelAnalyses;
}


int WiFiMonitorController::recommended24GHzChannel() const
{
    return m_recommended24GHzChannel;
}


int WiFiMonitorController::recommended5GHzChannel() const
{
    return m_recommended5GHzChannel;
}


int WiFiMonitorController::recommended6GHzChannel() const
{
    return m_recommended6GHzChannel;
}


QVariantList WiFiMonitorController::channelRecommendations() const
{
    return m_channelRecommendations;
}


// ============================================================
// Scan nearby networks
// ============================================================

void WiFiMonitorController::scanNetworks()
{
    /*
     * Ask the platform implementation for a fresh scan.
     *
     * Every scan provides fresh:
     *
     *     RSSI
     *     Noise
     *     SNR
     *
     * values.
     */

    const std::vector<WiFiNetwork> networks =
        monitor.scanNetworks();


    // ============================================================
    // CHANNEL INTELLIGENCE
    // ============================================================

    // Convert the raw Wi-Fi scan into analysed channel data.
    // The analyzer expects ChannelAnalysis objects for channel
    // recommendations; passing the raw WiFiNetwork vector here
    // would be a type error.
    const std::vector<ChannelAnalysis> analyses =
        channelAnalyzer.analyze(
            networks
        );


    // Convert the C++ analysis objects into QVariantMap objects
    // for QML.
    QVariantList analysisResults;

    for (const ChannelAnalysis &analysis : analyses)
    {
        QVariantMap map;

        map["channel"] =
            analysis.channel;

        map["band"] =
            QString::fromStdString(
                analysis.band
            );

        map["networkCount"] =
            analysis.networkCount;

        map["strongestRssi"] =
            analysis.strongestRssi;

        map["averageRssi"] =
            analysis.averageRssi;

        map["congestionScore"] =
            analysis.congestionScore;

        map["quality"] =
            QString::fromStdString(
                analysis.quality
            );

        analysisResults.append(
            map
        );
    }


    m_channelAnalyses =
        analysisResults;


    // IMPORTANT: recommendations operate on ChannelAnalysis,
    // not on WiFiNetwork.
    const ChannelRecommendation recommendation24 =
        channelAnalyzer.recommendation(
            analyses,
            "2.4 GHz"
        );

    const ChannelRecommendation recommendation5 =
        channelAnalyzer.recommendation(
            analyses,
            "5 GHz"
        );

    const ChannelRecommendation recommendation6 =
        channelAnalyzer.recommendation(
            analyses,
            "6 GHz"
        );

    m_recommended24GHzChannel =
        recommendation24.channel;

    m_recommended5GHzChannel =
        recommendation5.channel;

    m_recommended6GHzChannel =
        recommendation6.channel;


    QVariantList recommendationResults;

    const ChannelRecommendation recommendations[] = {
        recommendation24,
        recommendation5,
        recommendation6
    };

    const std::string recommendationBands[] = {
        "2.4 GHz",
        "5 GHz",
        "6 GHz"
    };


    for (int i = 0; i < 3; ++i)
    {
        QVariantMap map;

        map["band"] =
            QString::fromStdString(
                recommendationBands[i]
            );

        map["channel"] =
            recommendations[i].channel;

        map["score"] =
            recommendations[i].score;

        map["confidence"] =
            recommendations[i].confidence;

        map["confidenceLabel"] =
            QString::fromStdString(
                recommendations[i].confidenceLabel
            );

        map["reason"] =
            QString::fromStdString(
                recommendations[i].reason
            );

        recommendationResults.append(
            map
        );
    }


    m_channelRecommendations =
        recommendationResults;


    QVariantList results;


    // ============================================================
    // Band counters
    // ============================================================

    int count24GHz = 0;

    int count5GHz = 0;

    int count6GHz = 0;


    // ============================================================
    // Channel aggregation
    // ============================================================

    struct ChannelInfo
    {
        int channel = 0;

        std::string band;

        int networkCount = 0;

        int strongestRssi = -1000;
    };


    std::map<std::string, ChannelInfo> channelMap;


    // ============================================================
    // Automatically select strongest network
    //
    // Only happens when there is currently no selection.
    // ============================================================

    if (m_selectedNetworkBssid.empty() &&
        !networks.empty())
    {
        const WiFiNetwork *strongest =
            &networks.front();


        for (const WiFiNetwork &network : networks)
        {
            if (network.signalStrength >
                strongest->signalStrength)
            {
                strongest =
                    &network;
            }
        }


        if (!strongest->bssid.empty())
        {
            m_selectedNetworkBssid =
                strongest->bssid;

            emit selectedNetworkChanged();
        }
    }


    // ============================================================
    // Process every detected network
    // ============================================================

    for (const WiFiNetwork &network : networks)
    {
        // ========================================================
        // Per-network live history
        //
        // BSSID is used as the key because each physical
        // access point has its own BSSID.
        // ========================================================

        if (!network.bssid.empty())
        {
            auto result =
                nearbyHistories.emplace(
                    network.bssid,
                    WiFiHistory(60)
                );


            result.first->second.addSample(
                network.signalStrength,
                network.snr,
                network.noise,
                network.transmitRate
            );
        }


        // ========================================================
        // Convert network to QVariantMap
        // ========================================================

        QVariantMap map;


        // --------------------------------------------------------
        // Identity
        // --------------------------------------------------------

        map["ssid"] =
            QString::fromStdString(
                network.ssid
            );


        map["bssid"] =
            QString::fromStdString(
                network.bssid
            );


        // --------------------------------------------------------
        // Signal
        // --------------------------------------------------------

        map["signalStrength"] =
            network.signalStrength;


        map["noise"] =
            network.noise;


        map["snr"] =
            network.snr;


        map["signalQuality"] =
            QString::fromStdString(
                network.signalQuality
            );


        map["snrQuality"] =
            QString::fromStdString(
                network.snrQuality
            );


        // --------------------------------------------------------
        // Radio
        // --------------------------------------------------------

        map["channel"] =
            network.channel;


        map["band"] =
            QString::fromStdString(
                network.band
            );


        map["channelWidth"] =
            QString::fromStdString(
                network.channelWidth
            );


        results.append(map);


        // ========================================================
        // Band statistics
        // ========================================================

        if (network.band == "2.4 GHz")
        {
            ++count24GHz;
        }
        else if (network.band == "5 GHz")
        {
            ++count5GHz;
        }
        else if (network.band == "6 GHz")
        {
            ++count6GHz;
        }


        // ========================================================
        // Channel statistics
        // ========================================================

        if (network.channel > 0 &&
            !network.band.empty())
        {
            const std::string key =
                network.band +
                ":" +
                std::to_string(
                    network.channel
                );


            auto iterator =
                channelMap.find(key);


            if (iterator == channelMap.end())
            {
                ChannelInfo info;


                info.channel =
                    network.channel;


                info.band =
                    network.band;


                info.networkCount =
                    1;


                info.strongestRssi =
                    network.signalStrength;


                channelMap[key] =
                    info;
            }
            else
            {
                iterator->second.networkCount++;


                if (network.signalStrength >
                    iterator->second.strongestRssi)
                {
                    iterator->second.strongestRssi =
                        network.signalStrength;
                }
            }
        }
    }


    // ============================================================
    // Convert channel map → QVariantList
    // ============================================================

    QVariantList channelResults;


    for (const auto &entry : channelMap)
    {
        const ChannelInfo &info =
            entry.second;


        QVariantMap channelMapEntry;


        channelMapEntry["channel"] =
            info.channel;


        channelMapEntry["band"] =
            QString::fromStdString(
                info.band
            );


        channelMapEntry["networkCount"] =
            info.networkCount;


        channelMapEntry["strongestRssi"] =
            info.strongestRssi;


        channelResults.append(
            channelMapEntry
        );
    }


    // ============================================================
    // Replace nearby-network snapshot
    // ============================================================

    m_nearbyNetworks =
        results;


    m_nearbyNetworkCount =
        static_cast<int>(
            networks.size()
        );


    m_networks24GHz =
        count24GHz;


    m_networks5GHz =
        count5GHz;


    m_networks6GHz =
        count6GHz;


    m_channelStatistics =
        channelResults;


    // ============================================================
    // Notify QML
    // ============================================================

    emit nearbyNetworksChanged();

    emit nearbyNetworkStatsChanged();

    emit channelStatisticsChanged();

    emit channelAnalysesChanged();

    emit channelRecommendationsChanged();

    emit selectedNetworkHistoryChanged();


    // ============================================================
    // Start automatic live monitoring
    //
    // The first manual scan enables the 3-second timer.
    // ============================================================

    if (!m_nearbyMonitoring)
    {
        m_nearbyMonitoring =
            true;


        emit nearbyMonitoringChanged();


        scanTimer.start();
    }
}


// ============================================================
// Stop nearby-network monitoring
// ============================================================

void WiFiMonitorController::stopNearbyMonitoring()
{
    if (!m_nearbyMonitoring)
    {
        return;
    }


    scanTimer.stop();


    m_nearbyMonitoring =
        false;


    emit nearbyMonitoringChanged();
}


// ============================================================
// Live refresh of current connection
// ============================================================

void WiFiMonitorController::refresh()
{
    WiFiNetwork newNetwork =
        monitor.getCurrentNetwork();


    bool oldConnected =
        currentNetwork.connected;


    // ============================================================
    // Connection state
    // ============================================================

    if (newNetwork.connected !=
        currentNetwork.connected)
    {
        currentNetwork.connected =
            newNetwork.connected;

        emit connectedChanged();
    }


    // ============================================================
    // RSSI
    // ============================================================

    if (newNetwork.signalStrength !=
        currentNetwork.signalStrength)
    {
        currentNetwork.signalStrength =
            newNetwork.signalStrength;

        emit signalStrengthChanged();
    }


    // ============================================================
    // SSID
    // ============================================================

    if (newNetwork.ssid !=
        currentNetwork.ssid)
    {
        currentNetwork.ssid =
            newNetwork.ssid;

        emit ssidChanged();
    }


    // ============================================================
    // BSSID
    // ============================================================

    if (newNetwork.bssid !=
        currentNetwork.bssid)
    {
        currentNetwork.bssid =
            newNetwork.bssid;

        emit bssidChanged();
    }


    // ============================================================
    // Noise
    // ============================================================

    if (newNetwork.noise !=
        currentNetwork.noise)
    {
        currentNetwork.noise =
            newNetwork.noise;

        emit noiseChanged();
    }


    // ============================================================
    // Transmit rate
    // ============================================================

    if (newNetwork.transmitRate !=
        currentNetwork.transmitRate)
    {
        currentNetwork.transmitRate =
            newNetwork.transmitRate;

        emit transmitRateChanged();
    }


    // ============================================================
    // Channel
    // ============================================================

    if (newNetwork.channel !=
        currentNetwork.channel)
    {
        currentNetwork.channel =
            newNetwork.channel;

        emit channelChanged();
    }


    // ============================================================
    // Band
    // ============================================================

    if (newNetwork.band !=
        currentNetwork.band)
    {
        currentNetwork.band =
            newNetwork.band;

        emit bandChanged();
    }


    // ============================================================
    // PHY
    // ============================================================

    if (newNetwork.phyMode !=
        currentNetwork.phyMode)
    {
        currentNetwork.phyMode =
            newNetwork.phyMode;

        emit phyModeChanged();
    }


    // ============================================================
    // Channel width
    // ============================================================

    if (newNetwork.channelWidth !=
        currentNetwork.channelWidth)
    {
        currentNetwork.channelWidth =
            newNetwork.channelWidth;

        emit channelWidthChanged();
    }


    // ============================================================
    // SNR
    // ============================================================

    if (newNetwork.snr !=
        currentNetwork.snr)
    {
        currentNetwork.snr =
            newNetwork.snr;

        emit snrChanged();
    }


    // ============================================================
    // Signal quality
    // ============================================================

    if (newNetwork.signalQuality !=
        currentNetwork.signalQuality)
    {
        currentNetwork.signalQuality =
            newNetwork.signalQuality;

        emit signalQualityChanged();
    }


    // ============================================================
    // SNR quality
    // ============================================================

    if (newNetwork.snrQuality !=
        currentNetwork.snrQuality)
    {
        currentNetwork.snrQuality =
            newNetwork.snrQuality;

        emit snrQualityChanged();
    }


    // ============================================================
    // Connected-network history
    // ============================================================

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
        history.clear();

        emit historyChanged();
    }
}