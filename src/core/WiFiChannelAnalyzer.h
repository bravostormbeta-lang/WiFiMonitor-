#ifndef WIFI_CHANNEL_ANALYZER_H
#define WIFI_CHANNEL_ANALYZER_H

#include "WiFiNetwork.h"

#include <string>
#include <vector>


// ============================================================
// ChannelRecommendation
//
// Describes the analyzer's recommended channel.
//
// confidence is an explanatory score, not a probability.
// ============================================================

struct ChannelRecommendation
{
    int channel = 0;

    int score = 0;

    int confidence = 0;

    std::string confidenceLabel;

    std::string reason;
};


// ============================================================
// ChannelAnalysis
//
// Represents the analysed state of one observed Wi-Fi channel.
//
// congestionScore is an observed-environment score. It combines:
//
//   - number of detected APs
//   - signal strength
//   - neighbouring-channel overlap
//   - channel-width pressure
//
// The score is NOT a measurement of total RF interference.
// ============================================================

struct ChannelAnalysis
{
    int channel = 0;

    std::string band;

    int networkCount = 0;

    int strongestRssi = -100;

    int averageRssi = -100;

    int congestionScore = 0;

    std::string quality;

    // Maximum channel width observed on this channel.
    //
    // Examples:
    //   20
    //   40
    //   80
    //   160
    //
    // 0 means unknown / unavailable.
    int maxChannelWidthMHz = 0;
};


// ============================================================
// WiFiChannelAnalyzer
//
// Pure C++ analysis layer.
// No Qt/QML dependencies.
// ============================================================

class WiFiChannelAnalyzer
{
public:

    // ========================================================
    // Analyse all detected networks.
    // ========================================================

    std::vector<ChannelAnalysis> analyze(
        const std::vector<WiFiNetwork>& networks
    ) const;


    // ========================================================
    // Basic same-channel congestion component.
    // ========================================================

    int congestionScore(
        int networkCount,
        int strongestRssi
    ) const;


    // ========================================================
    // Human-readable congestion quality.
    // ========================================================

    std::string quality(
        int congestionScore
    ) const;


    // ========================================================
    // Recommend a practical channel.
    //
    // 2.4 GHz:
    //     evaluates 1 / 6 / 11
    //
    // 5 GHz:
    //     evaluates common primary channels
    //     while accounting for observed channel widths.
    //
    // 6 GHz:
    //     returns 0 until actual 6 GHz scan data exists.
    // ========================================================

    int recommendedChannel(
        const std::vector<ChannelAnalysis>& channels,
        const std::string& band
    ) const;


    // ========================================================
    // Full recommendation including explanation and confidence.
    // ========================================================

    ChannelRecommendation recommendation(
        const std::vector<ChannelAnalysis>& channels,
        const std::string& band
    ) const;


private:

    // ========================================================
    // RSSI-weighted congestion.
    // ========================================================

    int weightedCongestion(
        int networkCount,
        int strongestRssi,
        int averageRssi
    ) const;


    // ========================================================
    // Width-aware overlap penalty.
    // ========================================================

    int overlapPenalty(
        int candidateChannel,
        const ChannelAnalysis& observed
    ) const;


    // ========================================================
    // Calculate score for one candidate channel.
    // ========================================================

    int candidateScore(
        int candidateChannel,
        const std::vector<ChannelAnalysis>& channels,
        const std::string& band
    ) const;
};

#endif