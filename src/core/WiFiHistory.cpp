#include "WiFiHistory.h"

WiFiHistory::WiFiHistory(std::size_t maxSamples)
    : maxSamples(maxSamples)
{
}

void WiFiHistory::addSample(int rssi,
                            int snr,
                            int noise,
                            double transmitRate)
{
    rssiSamples.push_back(rssi);
    snrSamples.push_back(snr);
    noiseSamples.push_back(noise);
    transmitRateSamples.push_back(transmitRate);

    trim();
}

const std::deque<int>& WiFiHistory::rssi() const
{
    return rssiSamples;
}

const std::deque<int>& WiFiHistory::snr() const
{
    return snrSamples;
}

const std::deque<int>& WiFiHistory::noise() const
{
    return noiseSamples;
}

const std::deque<double>& WiFiHistory::transmitRate() const
{
    return transmitRateSamples;
}

void WiFiHistory::clear()
{
    rssiSamples.clear();
    snrSamples.clear();
    noiseSamples.clear();
    transmitRateSamples.clear();
}

void WiFiHistory::trim()
{
    while (rssiSamples.size() > maxSamples)
        rssiSamples.pop_front();

    while (snrSamples.size() > maxSamples)
        snrSamples.pop_front();

    while (noiseSamples.size() > maxSamples)
        noiseSamples.pop_front();

    while (transmitRateSamples.size() > maxSamples)
        transmitRateSamples.pop_front();
}