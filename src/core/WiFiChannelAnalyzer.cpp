#include "WiFiChannelAnalyzer.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <numeric>


namespace
{

// ============================================================
// Signal contribution
//
// -95 dBm and below:
//     effectively negligible.
//
// -30 dBm and above:
//     maximum observed impact.
// ============================================================

int signalWeight(int rssi)
{
    // RSSI == 0 is used by WiFiNetwork as an
    // unavailable / uninitialized signal value.
    // It must not be interpreted as -30 dBm.
    if (rssi == 0)
        return 0;

    const int clamped =
        std::max(
            -95,
            std::min(
                -30,
                rssi
            )
        );

    return
        (clamped + 95) * 100 / 65;
}


// ============================================================
// Channel distance
//
// Wi-Fi channel numbers use 5 MHz numbering.
//
// Example:
//
// 36 -> 40
// distance = 4
//
// This corresponds to one 20 MHz channel step.
// ============================================================

int channelDistance(
    int a,
    int b
)
{
    return std::abs(a - b);
}


// ============================================================
// Parse channel-width string.
//
// Examples:
//
// "20 MHz"  -> 20
// "40 MHz"  -> 40
// "80 MHz"  -> 80
// "160 MHz" -> 160
//
// Unknown values return 0.
// ============================================================

int channelWidthMHz(
    const std::string& width
)
{
    if (width.find("160") != std::string::npos)
        return 160;

    if (width.find("80") != std::string::npos)
        return 80;

    if (width.find("40") != std::string::npos)
        return 40;

    if (width.find("20") != std::string::npos)
        return 20;

    return 0;
}


// ============================================================
// Determine whether a 5 GHz channel belongs to an 80 MHz block.
//
// Common 80 MHz blocks:
//
// 36 40 44 48
// 52 56 60 64
// 100 104 108 112
// 116 120 124 128
// 132 136 140 144
// 149 153 157 161
// ============================================================

bool same80MHzBlock(
    int a,
    int b
)
{
    const int blocks[][4] =
    {
        {36, 40, 44, 48},
        {52, 56, 60, 64},
        {100, 104, 108, 112},
        {116, 120, 124, 128},
        {132, 136, 140, 144},
        {149, 153, 157, 161}
    };


    for (const auto& block : blocks)
    {
        bool foundA = false;
        bool foundB = false;


        for (int i = 0; i < 4; ++i)
        {
            if (block[i] == a)
                foundA = true;

            if (block[i] == b)
                foundB = true;
        }


        if (foundA && foundB)
            return true;
    }


    return false;
}


// ============================================================
// Determine whether a 5 GHz channel belongs to a 40 MHz block.
//
// We use common 20 MHz channel pairs.
//
// Example:
//
// 36 <-> 40
// 44 <-> 48
// 149 <-> 153
// 157 <-> 161
// ============================================================

bool same40MHzBlock(
    int a,
    int b
)
{
    const int pairs[][2] =
    {
        {36, 40},
        {44, 48},

        {52, 56},
        {60, 64},

        {100, 104},
        {108, 112},

        {116, 120},
        {124, 128},

        {132, 136},
        {140, 144},

        {149, 153},
        {157, 161}
    };


    for (const auto& pair : pairs)
    {
        if (
            (pair[0] == a && pair[1] == b) ||
            (pair[0] == b && pair[1] == a)
        )
        {
            return true;
        }
    }


    return false;
}


// ============================================================
// Determine whether a 5 GHz channel belongs to a 160 MHz block.
//
// Common 160 MHz blocks:
//
// 36 - 64
// 100 - 128
//
// We intentionally keep this conservative rather than inventing
// region-specific 160 MHz availability.
// ============================================================

bool same160MHzBlock(
    int a,
    int b
)
{
    const bool firstBlock =
        a >= 36 &&
        a <= 64 &&
        b >= 36 &&
        b <= 64;


    const bool secondBlock =
        a >= 100 &&
        a <= 128 &&
        b >= 100 &&
        b <= 128;


    return
        firstBlock ||
        secondBlock;
}


// ============================================================
// Width-aware overlap.
//
// Returns:
//
// 0    = no meaningful overlap
// >0   = increasing pressure
//
// The candidate itself is treated as a 20 MHz primary channel.
// Observed AP width determines how much spectrum it occupies.
// ============================================================

int widthAwareOverlapPenalty(
    int candidateChannel,
    const ChannelAnalysis& observed
)
{
    const int width =
        observed.maxChannelWidthMHz;


    const int signal =
        signalWeight(
            observed.strongestRssi
        );


    const int apMultiplier =
        std::max(
            1,
            observed.networkCount
        );


    // ========================================================
    // Unknown width
    //
    // Fall back to conservative 20 MHz behaviour.
    // ========================================================

    if (width <= 0)
    {
        const int distance =
            channelDistance(
                candidateChannel,
                observed.channel
            );


        if (observed.band == "2.4 GHz")
        {
            if (distance >= 5)
                return 0;


            const int overlapFactor =
                100 -
                distance * 20;


            return
                overlapFactor *
                signal *
                apMultiplier /
                100;
        }


        if (
            observed.band == "5 GHz" ||
            observed.band == "6 GHz"
        )
        {
            if (distance >= 4)
                return 0;


            const int overlapFactor =
                100 -
                distance * 25;


            return
                overlapFactor *
                signal *
                apMultiplier /
                100;
        }


        return 0;
    }


    // ========================================================
    // 2.4 GHz
    //
    // 40 MHz networks occupy considerably more spectrum.
    // ========================================================

    if (observed.band == "2.4 GHz")
    {
        const int distance =
            channelDistance(
                candidateChannel,
                observed.channel
            );


        if (width >= 40)
        {
            if (distance >= 9)
                return 0;


            const int overlapFactor =
                100 -
                distance * 10;


            return
                overlapFactor *
                signal *
                apMultiplier *
                12 /
                1000;
        }


        if (distance >= 5)
            return 0;


        const int overlapFactor =
            100 -
            distance * 20;


        return
            overlapFactor *
            signal *
            apMultiplier /
            100;
    }


    // ========================================================
    // 5 GHz
    //
    // Evaluate actual occupied blocks for wide networks.
    // ========================================================

    if (observed.band == "5 GHz")
    {
        bool overlaps = false;

        int overlapStrength = 0;


        // ----------------------------------------------------
        // 160 MHz
        // ----------------------------------------------------

        if (width >= 160)
        {
            if (
                same160MHzBlock(
                    candidateChannel,
                    observed.channel
                )
            )
            {
                overlaps = true;

                overlapStrength = 100;
            }
        }


        // ----------------------------------------------------
        // 80 MHz
        // ----------------------------------------------------

        else if (width >= 80)
        {
            if (
                same80MHzBlock(
                    candidateChannel,
                    observed.channel
                )
            )
            {
                overlaps = true;

                overlapStrength = 90;
            }
        }


        // ----------------------------------------------------
        // 40 MHz
        // ----------------------------------------------------

        else if (width >= 40)
        {
            if (
                candidateChannel ==
                observed.channel
            )
            {
                overlaps = true;

                overlapStrength = 100;
            }
            else if (
                same40MHzBlock(
                    candidateChannel,
                    observed.channel
                )
            )
            {
                overlaps = true;

                overlapStrength = 75;
            }
        }


        // ----------------------------------------------------
        // 20 MHz
        // ----------------------------------------------------

        else
        {
            if (
                candidateChannel ==
                observed.channel
            )
            {
                overlaps = true;

                overlapStrength = 100;
            }
            else
            {
                const int distance =
                    channelDistance(
                        candidateChannel,
                        observed.channel
                    );


                if (distance < 4)
                {
                    overlaps = true;

                    overlapStrength =
                        100 -
                        distance * 25;
                }
            }
        }


        if (!overlaps)
            return 0;


        return
            overlapStrength *
            signal *
            apMultiplier /
            100;
    }


    // ========================================================
    // 6 GHz
    //
    // Keep conservative 20 MHz-style behaviour for now.
    // We can make this width-aware separately once real 6 GHz
    // scan data is available.
    // ========================================================

    if (observed.band == "6 GHz")
    {
        const int distance =
            channelDistance(
                candidateChannel,
                observed.channel
            );


        if (distance >= 4)
            return 0;


        const int overlapFactor =
            100 -
            distance * 25;


        return
            overlapFactor *
            signal *
            apMultiplier /
            100;
    }


    return 0;
}

}


// ============================================================
// Analyse all detected networks
// ============================================================

std::vector<ChannelAnalysis>
WiFiChannelAnalyzer::analyze(
    const std::vector<WiFiNetwork>& networks
) const
{
    struct ChannelAccumulator
    {
        int channel = 0;

        std::string band;

        int networkCount = 0;

        int strongestRssi = -100;

        int rssiTotal = 0;

        int maxChannelWidthMHz = 0;
    };


    std::map<std::string, ChannelAccumulator>
        channelMap;


    // ========================================================
    // Aggregate networks by band + channel.
    // ========================================================

    for (
        const WiFiNetwork& network :
        networks
    )
    {
        if (network.channel <= 0)
            continue;

        if (network.band.empty())
            continue;


        const std::string key =
            network.band +
            ":" +
            std::to_string(
                network.channel
            );


        auto iterator =
            channelMap.find(
                key
            );


        const int width =
            channelWidthMHz(
                network.channelWidth
            );


        if (
            iterator ==
            channelMap.end()
        )
        {
            ChannelAccumulator accumulator;


            accumulator.channel =
                network.channel;


            accumulator.band =
                network.band;


            accumulator.networkCount =
                1;


            accumulator.strongestRssi =
                network.signalStrength;


            accumulator.rssiTotal =
                network.signalStrength;


            accumulator.maxChannelWidthMHz =
                width;


            channelMap.emplace(
                key,
                accumulator
            );
        }
        else
        {
            ChannelAccumulator& accumulator =
                iterator->second;


            accumulator.networkCount++;


            accumulator.rssiTotal +=
                network.signalStrength;


            accumulator.strongestRssi =
                std::max(
                    accumulator.strongestRssi,
                    network.signalStrength
                );


            accumulator.maxChannelWidthMHz =
                std::max(
                    accumulator.maxChannelWidthMHz,
                    width
                );
        }
    }


    // ========================================================
    // Convert to ChannelAnalysis.
    // ========================================================

    std::vector<ChannelAnalysis>
        results;


    results.reserve(
        channelMap.size()
    );


    for (
        const auto& entry :
        channelMap
    )
    {
        const ChannelAccumulator&
            accumulator =
                entry.second;


        ChannelAnalysis analysis;


        analysis.channel =
            accumulator.channel;


        analysis.band =
            accumulator.band;


        analysis.networkCount =
            accumulator.networkCount;


        analysis.strongestRssi =
            accumulator.strongestRssi;


        analysis.averageRssi =
            accumulator.networkCount > 0
            ?
            accumulator.rssiTotal /
            accumulator.networkCount
            :
            -100;


        analysis.maxChannelWidthMHz =
            accumulator.maxChannelWidthMHz;


        // ----------------------------------------------------
        // Start with same-channel congestion.
        // ----------------------------------------------------

        analysis.congestionScore =
            weightedCongestion(
                analysis.networkCount,
                analysis.strongestRssi,
                analysis.averageRssi
            );


        analysis.quality =
            quality(
                analysis.congestionScore
            );


        results.push_back(
            analysis
        );
    }


    // ========================================================
    // Add width-aware neighbouring-channel pressure.
    // ========================================================

    for (
        ChannelAnalysis& target :
        results
    )
    {
        int totalOverlap =
            0;


        for (
            const ChannelAnalysis& observed :
            results
        )
        {
            if (
                observed.band !=
                target.band
            )
            {
                continue;
            }


            if (
                observed.channel ==
                target.channel
            )
            {
                continue;
            }


            totalOverlap +=
                widthAwareOverlapPenalty(
                    target.channel,
                    observed
                );
        }


        // Keep the observed score bounded.
        //
        // We deliberately do not allow neighbouring APs to
        // completely dominate the actual same-channel score.
        target.congestionScore =
            std::min(
                100,
                target.congestionScore +
                totalOverlap / 2
            );


        target.quality =
            quality(
                target.congestionScore
            );
    }


    // ========================================================
    // Sort by band then channel.
    // ========================================================

    std::sort(
        results.begin(),
        results.end(),
        [](
            const ChannelAnalysis& a,
            const ChannelAnalysis& b
        )
        {
            if (a.band != b.band)
                return a.band < b.band;


            return
                a.channel <
                b.channel;
        }
    );


    return results;
}


// ============================================================
// Basic congestion score
// ============================================================

int WiFiChannelAnalyzer::congestionScore(
    int networkCount,
    int strongestRssi
) const
{
    if (networkCount <= 0)
        return 0;


    const int countComponent =
        std::min(
            65,
            networkCount * 13
        );


    const int signalComponent =
        signalWeight(
            strongestRssi
        ) *
        35 /
        100;


    return
        std::max(
            0,
            std::min(
                100,
                countComponent +
                signalComponent
            )
        );
}


// ============================================================
// Weighted congestion
// ============================================================

int WiFiChannelAnalyzer::weightedCongestion(
    int networkCount,
    int strongestRssi,
    int averageRssi
) const
{
    if (networkCount <= 0)
        return 0;


    const int countComponent =
        std::min(
            55,
            networkCount * 11
        );


    const int strongestComponent =
        signalWeight(
            strongestRssi
        ) *
        30 /
        100;


    const int averageComponent =
        signalWeight(
            averageRssi
        ) *
        15 /
        100;


    return
        std::max(
            0,
            std::min(
                100,
                countComponent +
                strongestComponent +
                averageComponent
            )
        );
}


// ============================================================
// Channel overlap penalty
//
// This public/internal helper remains compatible with the
// existing analyzer design.
//
// Width-aware calculations are performed by
// widthAwareOverlapPenalty().
// ============================================================

int WiFiChannelAnalyzer::overlapPenalty(
    int candidateChannel,
    const ChannelAnalysis& observed
) const
{
    return
        widthAwareOverlapPenalty(
            candidateChannel,
            observed
        );
}


// ============================================================
// Convert score to quality
// ============================================================

std::string WiFiChannelAnalyzer::quality(
    int score
) const
{
    if (score < 30)
        return "Low";


    if (score < 60)
        return "Moderate";


    if (score < 80)
        return "High";


    return "Very High";
}


// ============================================================
// Candidate score
//
// This evaluates channels even when zero APs were detected.
//
// The important change here is that an observed AP's
// channelWidth is already represented by
// ChannelAnalysis::maxChannelWidthMHz.
//
// Therefore:
//
//     80 MHz AP
//          ↓
//     occupied block
//          ↓
//     candidate inside block
//          ↓
//     stronger penalty
// ============================================================

int WiFiChannelAnalyzer::candidateScore(
    int candidateChannel,
    const std::vector<ChannelAnalysis>& channels,
    const std::string& band
) const
{
    int score = 0;


    for (
        const ChannelAnalysis& observed :
        channels
    )
    {
        if (
            observed.band !=
            band
        )
        {
            continue;
        }


        if (
            observed.channel ==
            candidateChannel
        )
        {
            score +=
                weightedCongestion(
                    observed.networkCount,
                    observed.strongestRssi,
                    observed.averageRssi
                );


            continue;
        }


        score +=
            widthAwareOverlapPenalty(
                candidateChannel,
                observed
            );
    }


    return
        std::max(
            0,
            std::min(
                100,
                score
            )
        );
}


// ============================================================
// Candidate channels
// ============================================================

static std::vector<int>
candidateChannelsForBand(
    const std::string& band
)
{
    if (band == "2.4 GHz")
    {
        return {
            1,
            6,
            11
        };
    }


    if (band == "5 GHz")
    {
        return {
            36,
            40,
            44,
            48,

            52,
            56,
            60,
            64,

            100,
            104,
            108,
            112,

            116,
            120,
            124,
            128,

            132,
            136,
            140,
            144,

            149,
            153,
            157,
            161
        };
    }


    return {};
}


// ============================================================
// Recommendation confidence label
// ============================================================

static std::string
confidenceLabel(
    int confidence
)
{
    if (confidence >= 80)
        return "High";


    if (confidence >= 60)
        return "Moderate";


    if (confidence > 0)
        return "Low";


    return "No data";
}


// ============================================================
// Recommendation
// ============================================================

ChannelRecommendation
WiFiChannelAnalyzer::recommendation(
    const std::vector<ChannelAnalysis>& channels,
    const std::string& band
) const
{
    ChannelRecommendation result;


    // ========================================================
    // 6 GHz
    //
    // Do not fabricate a recommendation when there is no
    // actual 6 GHz scan data.
    // ========================================================

    if (band == "6 GHz")
    {
        int bestChannel =
            0;


        int bestScore =
            std::numeric_limits<int>::max();


        int secondBestScore =
            std::numeric_limits<int>::max();


        int observedCount =
            0;


        for (
            const ChannelAnalysis& channel :
            channels
        )
        {
            if (
                channel.band !=
                band
            )
            {
                continue;
            }


            ++observedCount;


            const int score =
                candidateScore(
                    channel.channel,
                    channels,
                    band
                );


            if (
                score <
                bestScore
            )
            {
                secondBestScore =
                    bestScore;


                bestScore =
                    score;


                bestChannel =
                    channel.channel;
            }
            else if (
                score <
                secondBestScore
            )
            {
                secondBestScore =
                    score;
            }
        }


        if (
            bestChannel == 0
        )
        {
            result.reason =
                "No 6 GHz networks were detected.";


            return result;
        }


        result.channel =
            bestChannel;


        result.score =
            bestScore;


        const int margin =
            secondBestScore ==
            std::numeric_limits<int>::max()
            ?
            0
            :
            secondBestScore -
            bestScore;


        int confidence =
            55;


        confidence +=
            std::min(
                25,
                margin * 3
            );


        if (observedCount >= 3)
            confidence += 10;
        else if (observedCount >= 2)
            confidence += 5;


        result.confidence =
            std::min(
                90,
                confidence
            );


        result.confidenceLabel =
            confidenceLabel(
                result.confidence
            );


        result.reason =
            "Lowest estimated congestion among observed 6 GHz channels.";


        return result;
    }


    // ========================================================
    // 2.4 GHz / 5 GHz candidates
    // ========================================================

    const std::vector<int>
        candidates =
            candidateChannelsForBand(
                band
            );


    if (
        candidates.empty()
    )
    {
        result.reason =
            "No supported candidate channels for this band.";


        return result;
    }


    int observedCount =
        0;


    for (
        const ChannelAnalysis& channel :
        channels
    )
    {
        if (
            channel.band ==
            band
        )
        {
            ++observedCount;
        }
    }


    if (
        observedCount == 0
    )
    {
        result.reason =
            "No networks were detected in this band.";


        return result;
    }


    // ========================================================
    // Find best and second-best candidate.
    // ========================================================

    int bestChannel =
        0;


    int bestScore =
        std::numeric_limits<int>::max();


    int secondBestScore =
        std::numeric_limits<int>::max();


    for (
        const int candidate :
        candidates
    )
    {
        const int score =
            candidateScore(
                candidate,
                channels,
                band
            );


        if (
            bestChannel == 0 ||
            score < bestScore
        )
        {
            secondBestScore =
                bestScore;


            bestChannel =
                candidate;


            bestScore =
                score;


            continue;
        }


        if (
            score <
            secondBestScore
        )
        {
            secondBestScore =
                score;


            continue;
        }


        // ----------------------------------------------------
        // Tie handling.
        //
        // Prefer non-DFS channels on 5 GHz.
        // ----------------------------------------------------

        if (
            score ==
            bestScore
        )
        {
            if (
                band ==
                "5 GHz"
            )
            {
                const bool candidateNonDfs =
                    candidate < 52 ||
                    candidate >= 149;


                const bool bestNonDfs =
                    bestChannel < 52 ||
                    bestChannel >= 149;


                if (
                    candidateNonDfs &&
                    !bestNonDfs
                )
                {
                    bestChannel =
                        candidate;
                }
                else if (
                    candidateNonDfs ==
                    bestNonDfs
                )
                {
                    bestChannel =
                        std::min(
                            bestChannel,
                            candidate
                        );
                }
            }
            else
            {
                bestChannel =
                    std::min(
                        bestChannel,
                        candidate
                    );
            }
        }
    }


    if (
        bestChannel == 0
    )
    {
        result.reason =
            "No usable channel recommendation could be calculated.";


        return result;
    }


    result.channel =
        bestChannel;


    result.score =
        bestScore;


    // ========================================================
    // Confidence
    //
    // This is NOT a probability.
    //
    // It represents how clearly the observed scan favours the
    // selected candidate.
    // ========================================================

    const int margin =
        secondBestScore ==
        std::numeric_limits<int>::max()
        ?
        0
        :
        secondBestScore -
        bestScore;


    int confidence =
        50;


    confidence +=
        std::min(
            30,
            margin * 2
        );


    if (observedCount >= 5)
        confidence += 10;
    else if (observedCount >= 3)
        confidence += 7;
    else if (observedCount >= 2)
        confidence += 4;


    result.confidence =
        std::min(
            95,
            confidence
        );


    result.confidenceLabel =
        confidenceLabel(
            result.confidence
        );


    // ========================================================
    // Build explanation from actual observations.
    // ========================================================

    const ChannelAnalysis*
        recommendedObserved =
            nullptr;


    const ChannelAnalysis*
        strongestObserved =
            nullptr;


    for (
        const ChannelAnalysis& channel :
        channels
    )
    {
        if (
            channel.band !=
            band
        )
        {
            continue;
        }


        if (
            channel.channel ==
            bestChannel
        )
        {
            recommendedObserved =
                &channel;
        }


        if (
            strongestObserved ==
            nullptr ||
            channel.strongestRssi >
                strongestObserved->strongestRssi
        )
        {
            strongestObserved =
                &channel;
        }
    }


    // ========================================================
    // Recommended channel is not directly observed.
    // ========================================================

    if (
        recommendedObserved ==
        nullptr
    )
    {
        result.reason =
            "No detected AP on channel " +
            std::to_string(
                bestChannel
            ) +
            "; it has the lowest estimated congestion. ";


        if (
            strongestObserved !=
            nullptr
        )
        {
            result.reason +=
                "Strongest observed AP is CH " +
                std::to_string(
                    strongestObserved->channel
                ) +
                " at " +
                std::to_string(
                    strongestObserved->strongestRssi
                ) +
                " dBm.";


            if (
                strongestObserved->maxChannelWidthMHz > 0
            )
            {
                result.reason +=
                    " Observed width: " +
                    std::to_string(
                        strongestObserved->maxChannelWidthMHz
                    ) +
                    " MHz.";
            }
        }
    }


    // ========================================================
    // Recommended channel already has an observed AP.
    // ========================================================

    else
    {
        result.reason =
            std::to_string(
                recommendedObserved->networkCount
            ) +
            " AP" +
            (
                recommendedObserved->networkCount == 1
                ?
                ""
                :
                "s"
            ) +
            " detected on CH " +
            std::to_string(
                bestChannel
            ) +
            "; strongest is " +
            std::to_string(
                recommendedObserved->strongestRssi
            ) +
            " dBm.";


        if (
            recommendedObserved->maxChannelWidthMHz > 0
        )
        {
            result.reason +=
                " Maximum observed width: " +
                std::to_string(
                    recommendedObserved->maxChannelWidthMHz
                ) +
                " MHz.";
        }
    }


    return result;
}


// ============================================================
// Recommended channel
// ============================================================

int WiFiChannelAnalyzer::recommendedChannel(
    const std::vector<ChannelAnalysis>& channels,
    const std::string& band
) const
{
    return
        recommendation(
            channels,
            band
        ).channel;
}