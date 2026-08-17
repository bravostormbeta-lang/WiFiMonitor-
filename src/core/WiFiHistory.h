#ifndef WIFI_HISTORY_H
#define WIFI_HISTORY_H

#include <deque>

class WiFiHistory
{
public:
    explicit WiFiHistory(std::size_t maxSamples = 60);

    void addSample(int rssi,
                   int snr,
                   int noise,
                   double transmitRate);

    const std::deque<int>& rssi() const;
    const std::deque<int>& snr() const;
    const std::deque<int>& noise() const;
    const std::deque<double>& transmitRate() const;

    void clear();

private:
    std::size_t maxSamples;

    std::deque<int> rssiSamples;
    std::deque<int> snrSamples;
    std::deque<int> noiseSamples;
    std::deque<double> transmitRateSamples;

    void trim();
};

#endif