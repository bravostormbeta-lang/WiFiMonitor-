#include "../src/core/WiFiChannelAnalyzer.h"
#include "../src/core/WiFiNetwork.h"

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>


namespace
{

int testsRun = 0;
int testsPassed = 0;


void check(
    bool condition,
    const std::string& name
)
{
    ++testsRun;

    if (condition)
    {
        ++testsPassed;

        std::cout
            << "[PASS] "
            << name
            << '\n';
    }
    else
    {
        std::cout
            << "[FAIL] "
            << name
            << '\n';
    }
}


WiFiNetwork makeNetwork(
    const std::string& band,
    int channel,
    int rssi,
    const std::string& width = "20 MHz"
)
{
    WiFiNetwork network;

    network.ssid =
        "TEST";

    network.bssid =
        "00:00:00:00:00:01";

    network.signalStrength =
        rssi;

    network.noise =
        -95;

    network.channel =
        channel;

    network.band =
        band;

    network.channelWidth =
        width;

    return network;
}


const ChannelAnalysis* findChannel(
    const std::vector<ChannelAnalysis>& analyses,
    const std::string& band,
    int channel
)
{
    for (const ChannelAnalysis& analysis : analyses)
    {
        if (
            analysis.band == band &&
            analysis.channel == channel
        )
        {
            return &analysis;
        }
    }

    return nullptr;
}


void printRecommendation(
    const std::string& testName,
    const ChannelRecommendation& recommendation
)
{
    std::cout
        << "    "
        << testName
        << ": channel="
        << recommendation.channel
        << ", score="
        << recommendation.score
        << ", confidence="
        << recommendation.confidence
        << " ("
        << recommendation.confidenceLabel
        << ")\n";
}

}


int main()
{
    WiFiChannelAnalyzer analyzer;


    std::cout
        << "==================================================\n"
        << "WiFiChannelAnalyzer Test Suite\n"
        << "==================================================\n\n";


    // ========================================================
    // 1. RSSI weighting
    //
    // A strong AP should contribute more congestion than a
    // weak AP on an otherwise equivalent channel.
    // ========================================================

    {
        const std::vector<WiFiNetwork> networks = {
            makeNetwork("2.4 GHz", 1, -40),
            makeNetwork("2.4 GHz", 6, -80)
        };

        const auto analyses =
            analyzer.analyze(networks);

        const ChannelAnalysis* strong =
            findChannel(
                analyses,
                "2.4 GHz",
                1
            );

        const ChannelAnalysis* weak =
            findChannel(
                analyses,
                "2.4 GHz",
                6
            );

        check(
            strong != nullptr &&
            weak != nullptr &&
            strong->congestionScore >
                weak->congestionScore,
            "RSSI weighting: strong AP > weak AP"
        );
    }


    // ========================================================
    // 2. AP count weighting
    //
    // Multiple APs should materially increase congestion.
    // ========================================================

    {
        std::vector<WiFiNetwork> networks;

        networks.push_back(
            makeNetwork(
                "2.4 GHz",
                1,
                -60
            )
        );

        for (int i = 0; i < 4; ++i)
        {
            networks.push_back(
                makeNetwork(
                    "2.4 GHz",
                    6,
                    -70
                )
            );
        }

        const auto analyses =
            analyzer.analyze(networks);

        const ChannelAnalysis* oneAp =
            findChannel(
                analyses,
                "2.4 GHz",
                1
            );

        const ChannelAnalysis* fourAps =
            findChannel(
                analyses,
                "2.4 GHz",
                6
            );

        check(
            oneAp != nullptr &&
            fourAps != nullptr &&
            fourAps->networkCount == 4 &&
            fourAps->congestionScore >
                oneAp->congestionScore,
            "AP count: four APs > one AP"
        );
    }


    // ========================================================
    // 3. 2.4 GHz overlap
    //
    // A strong AP on channel 3 should make channel 11 look
    // cleaner than channel 6, while channel 1 also receives
    // overlap pressure.
    // ========================================================

    {
        const std::vector<WiFiNetwork> networks = {
            makeNetwork(
                "2.4 GHz",
                3,
                -40
            )
        };

        const auto analyses =
            analyzer.analyze(networks);

        const ChannelRecommendation recommendation =
            analyzer.recommendation(
                analyses,
                "2.4 GHz"
            );

        printRecommendation(
            "2.4 GHz overlap",
            recommendation
        );

        check(
            recommendation.channel == 11,
            "2.4 GHz overlap: CH 11 preferred over CH 6"
        );
    }


    // ========================================================
    // 4. 2.4 GHz 40 MHz width
    //
    // A 40 MHz AP on CH 1 should place additional pressure
    // on CH 6, making CH 11 the cleanest of 1/6/11.
    // ========================================================

    {
        const std::vector<WiFiNetwork> networks = {
            makeNetwork(
                "2.4 GHz",
                1,
                -40,
                "40 MHz"
            )
        };

        const auto analyses =
            analyzer.analyze(networks);

        const ChannelAnalysis* channel1 =
            findChannel(
                analyses,
                "2.4 GHz",
                1
            );

        const ChannelRecommendation recommendation =
            analyzer.recommendation(
                analyses,
                "2.4 GHz"
            );

        printRecommendation(
            "2.4 GHz 40 MHz",
            recommendation
        );

        check(
            channel1 != nullptr &&
            channel1->maxChannelWidthMHz == 40,
            "40 MHz is captured in ChannelAnalysis"
        );

        check(
            recommendation.channel == 11,
            "40 MHz: CH 11 preferred over affected CH 6"
        );
    }


    // ========================================================
    // 5. 5 GHz 80 MHz overlap
    //
    // CH 36 at 80 MHz occupies the 36/40/44/48 block.
    // The recommendation should move outside that block.
    // ========================================================

    {
        const std::vector<WiFiNetwork> networks = {
            makeNetwork(
                "5 GHz",
                36,
                -40,
                "80 MHz"
            )
        };

        const auto analyses =
            analyzer.analyze(networks);

        const ChannelAnalysis* channel36 =
            findChannel(
                analyses,
                "5 GHz",
                36
            );

        const ChannelRecommendation recommendation =
            analyzer.recommendation(
                analyses,
                "5 GHz"
            );

        printRecommendation(
            "5 GHz 80 MHz",
            recommendation
        );

        check(
            channel36 != nullptr &&
            channel36->maxChannelWidthMHz == 80,
            "80 MHz is captured in ChannelAnalysis"
        );

        check(
            recommendation.channel != 36 &&
            recommendation.channel != 40 &&
            recommendation.channel != 44 &&
            recommendation.channel != 48,
            "80 MHz: recommendation leaves the occupied 80 MHz block"
        );
    }


    // ========================================================
    // 6. 5 GHz 160 MHz overlap
    //
    // CH 36 at 160 MHz occupies the common 36-64 block.
    // ========================================================

    {
        const std::vector<WiFiNetwork> networks = {
            makeNetwork(
                "5 GHz",
                36,
                -40,
                "160 MHz"
            )
        };

        const auto analyses =
            analyzer.analyze(networks);

        const ChannelAnalysis* channel36 =
            findChannel(
                analyses,
                "5 GHz",
                36
            );

        const ChannelRecommendation recommendation =
            analyzer.recommendation(
                analyses,
                "5 GHz"
            );

        printRecommendation(
            "5 GHz 160 MHz",
            recommendation
        );

        check(
            channel36 != nullptr &&
            channel36->maxChannelWidthMHz == 160,
            "160 MHz is captured in ChannelAnalysis"
        );

        check(
            recommendation.channel != 36 &&
            recommendation.channel != 40 &&
            recommendation.channel != 44 &&
            recommendation.channel != 48 &&
            recommendation.channel != 52 &&
            recommendation.channel != 56 &&
            recommendation.channel != 60 &&
            recommendation.channel != 64,
            "160 MHz: recommendation leaves the occupied 160 MHz block"
        );
    }


    // ========================================================
    // 7. DFS tie handling
    //
    // Construct an environment where CH 36 (non-DFS) and
    // CH 52 (DFS) are tied for the best score. The analyzer
    // should prefer the non-DFS channel.
    // ========================================================

    {
        std::vector<WiFiNetwork> networks;

        const int candidates[] = {
            36, 40, 44, 48,
            52, 56, 60, 64,
            100, 104, 108, 112,
            116, 120, 124, 128,
            132, 136, 140, 144,
            149, 153, 157, 161
        };

        for (const int channel : candidates)
        {
            if (
                channel == 36 ||
                channel == 52
            )
            {
                continue;
            }

            networks.push_back(
                makeNetwork(
                    "5 GHz",
                    channel,
                    -30
                )
            );
        }

        networks.push_back(
            makeNetwork(
                "5 GHz",
                36,
                -40
            )
        );

        networks.push_back(
            makeNetwork(
                "5 GHz",
                52,
                -40
            )
        );

        const auto analyses =
            analyzer.analyze(networks);

        const ChannelRecommendation recommendation =
            analyzer.recommendation(
                analyses,
                "5 GHz"
            );

        printRecommendation(
            "DFS tie",
            recommendation
        );

        check(
            recommendation.channel == 36,
            "DFS tie: non-DFS CH 36 wins over DFS CH 52"
        );
    }


    // ========================================================
    // 8. Confidence reacts to separation
    //
    // A clear recommendation should receive higher confidence
    // than an exactly tied environment.
    // ========================================================

    {
        const auto clearAnalyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "2.4 GHz",
                        3,
                        -40
                    )
                }
            );

        const auto tiedAnalyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "2.4 GHz",
                        1,
                        -40
                    ),
                    makeNetwork(
                        "2.4 GHz",
                        6,
                        -40
                    ),
                    makeNetwork(
                        "2.4 GHz",
                        11,
                        -40
                    )
                }
            );

        const ChannelRecommendation clear =
            analyzer.recommendation(
                clearAnalyses,
                "2.4 GHz"
            );

        const ChannelRecommendation tied =
            analyzer.recommendation(
                tiedAnalyses,
                "2.4 GHz"
            );

        printRecommendation(
            "Clear confidence",
            clear
        );

        printRecommendation(
            "Tie confidence",
            tied
        );

        check(
            clear.confidence >
                tied.confidence,
            "Confidence: larger score margin produces higher confidence"
        );

        check(
            clear.confidenceLabel == "High" &&
            tied.confidenceLabel == "Low",
            "Confidence labels match the score ranges"
        );
    }


    // ========================================================
    // 9. Very weak AP
    //
    // An AP at -95 dBm should not create a high congestion
    // score by itself.
    // ========================================================

    {
        const auto analyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "2.4 GHz",
                        1,
                        -95
                    )
                }
            );

        const ChannelAnalysis* channel1 =
            findChannel(
                analyses,
                "2.4 GHz",
                1
            );

        check(
            channel1 != nullptr &&
            channel1->congestionScore < 30,
            "Very weak AP: -95 dBm is not high congestion"
        );
    }


    // ========================================================
    // 10. Strong wide AP affects neighboring candidates
    //
    // Compare a narrow 20 MHz AP with an otherwise identical
    // 80 MHz AP on CH 36. The wider AP should push the
    // recommendation farther away from the 36/40/44/48 block.
    // ========================================================

    {
        const auto narrowAnalyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "5 GHz",
                        36,
                        -40,
                        "20 MHz"
                    ),
                    makeNetwork(
                        "5 GHz",
                        149,
                        -40,
                        "20 MHz"
                    )
                }
            );

        const auto wideAnalyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "5 GHz",
                        36,
                        -40,
                        "80 MHz"
                    ),
                    makeNetwork(
                        "5 GHz",
                        149,
                        -40,
                        "20 MHz"
                    )
                }
            );

        const ChannelRecommendation narrow =
            analyzer.recommendation(
                narrowAnalyses,
                "5 GHz"
            );

        const ChannelRecommendation wide =
            analyzer.recommendation(
                wideAnalyses,
                "5 GHz"
            );

        printRecommendation(
            "Narrow AP",
            narrow
        );

        printRecommendation(
            "Wide AP",
            wide
        );

        check(
            narrow.channel !=
                wide.channel,
            "Wide AP: recommendation changes when width increases"
        );

        check(
            wide.channel != 36 &&
            wide.channel != 40 &&
            wide.channel != 44 &&
            wide.channel != 48,
            "Wide AP: recommendation leaves the 80 MHz block"
        );
    }


    // ========================================================
    // 11. Empty scan data
    //
    // An empty scan must not produce a recommendation or
    // fabricated channel analysis.
    // ========================================================

    {
        const auto analyses =
            analyzer.analyze(
                {}
            );

        const ChannelRecommendation recommendation24 =
            analyzer.recommendation(
                analyses,
                "2.4 GHz"
            );

        const ChannelRecommendation recommendation5 =
            analyzer.recommendation(
                analyses,
                "5 GHz"
            );

        check(
            analyses.empty(),
            "Empty scan: produces no channel analyses"
        );

        check(
            recommendation24.channel == 0 &&
            recommendation24.confidence == 0 &&
            recommendation5.channel == 0 &&
            recommendation5.confidence == 0,
            "Empty scan: produces no recommendations"
        );
    }


    // ========================================================
    // 12. Unknown channel
    //
    // Channel 0 means the operating system did not provide a
    // usable channel. It should not become a real candidate.
    // ========================================================

    {
        const auto analyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "5 GHz",
                        0,
                        -50
                    ),
                    makeNetwork(
                        "5 GHz",
                        149,
                        -60
                    )
                }
            );

        const ChannelAnalysis* unknown =
            findChannel(
                analyses,
                "5 GHz",
                0
            );

        const ChannelAnalysis* valid =
            findChannel(
                analyses,
                "5 GHz",
                149
            );

        check(
            unknown == nullptr,
            "Unknown channel: channel 0 is ignored"
        );

        check(
            valid != nullptr &&
            valid->channel == 149,
            "Unknown channel: valid channel remains available"
        );
    }


    // ========================================================
    // 13. Unknown channel width
    //
    // An unavailable/unknown width must not be interpreted as
    // a wide channel. The stored width should remain 0.
    // ========================================================

    {
        const auto analyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "5 GHz",
                        36,
                        -50,
                        "Unknown"
                    )
                }
            );

        const ChannelAnalysis* channel36 =
            findChannel(
                analyses,
                "5 GHz",
                36
            );

        check(
            channel36 != nullptr &&
            channel36->maxChannelWidthMHz == 0,
            "Unknown width: stored width remains unknown"
        );
    }


    // ========================================================
    // 14. Zero/invalid RSSI
    //
    // A zero RSSI is not a realistic received-signal value.
    // It must not make a channel appear extremely congested.
    // ========================================================

    {
        const auto analyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "2.4 GHz",
                        1,
                        0
                    )
                }
            );

        const ChannelAnalysis* channel1 =
            findChannel(
                analyses,
                "2.4 GHz",
                1
            );

        check(
            channel1 != nullptr &&
            channel1->congestionScore < 30,
            "Invalid RSSI: 0 dBm is not high congestion"
        );
    }


    // ========================================================
    // 15. Unknown band
    //
    // Unsupported band information should not result in a
    // fabricated recommendation.
    // ========================================================

    {
        const auto analyses =
            analyzer.analyze(
                {
                    makeNetwork(
                        "Unknown",
                        36,
                        -50
                    )
                }
            );

        const ChannelRecommendation recommendation =
            analyzer.recommendation(
                analyses,
                "Unknown"
            );

        check(
            recommendation.channel == 0 &&
            recommendation.confidence == 0,
            "Unknown band: no fabricated recommendation"
        );
    }


    // ========================================================
    // 16. Partial network information
    //
    // Missing optional fields should not prevent the analyzer
    // from processing a network with otherwise valid channel
    // and signal information.
    // ========================================================

    {
        WiFiNetwork network;

        network.channel = 11;
        network.band = "2.4 GHz";
        network.signalStrength = -60;

        const auto analyses =
            analyzer.analyze(
                {
                    network
                }
            );

        const ChannelAnalysis* channel11 =
            findChannel(
                analyses,
                "2.4 GHz",
                11
            );

        check(
            channel11 != nullptr &&
            channel11->networkCount == 1,
            "Partial network: valid radio data is still analysed"
        );
    }


    // ========================================================
    // 6 GHz no-data behavior
    //
    // Extra safety test: no fabricated 6 GHz recommendation.
    // ========================================================

    {
        const ChannelRecommendation recommendation =
            analyzer.recommendation(
                {},
                "6 GHz"
            );

        check(
            recommendation.channel == 0 &&
            recommendation.confidence == 0,
            "6 GHz: no data produces no recommendation"
        );
    }


    std::cout
        << "\n==================================================\n"
        << "Results: "
        << testsPassed
        << "/"
        << testsRun
        << " tests passed\n"
        << "==================================================\n";


    return
        testsPassed == testsRun
        ? 0
        : 1;
}