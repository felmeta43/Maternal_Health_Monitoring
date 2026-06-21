#pragma once

#include <MAX30105.h>
#include "sensor_driver.h"

// Heart rate (via PPG beat detection) and SpO2 from a MAX30102 pulse
// oximeter module over I2C.
class Max30102Sensor : public SensorDriver {
public:
    bool begin() override;
    bool sample(VitalReading &reading) override;

private:
    MAX30105 particleSensor_;

    static constexpr int kBeatHistorySize = 4;
    long beatHistoryMs_[kBeatHistorySize] = {0};
    int beatHistoryIndex_ = 0;
    long lastBeatMs_ = 0;

    // SpO2 estimation is computed by Maxim's reference algorithm
    // (see lib_deps note in platformio.ini / SparkFun examples). This driver
    // exposes the IR/red buffers it needs; wire in spo2_algorithm.h's
    // maxim_heart_rate_and_oxygen_saturation() here once that vendor file is
    // added to the project, rather than reimplementing it from scratch.
    float estimateSpo2();

    bool isFingerDetected();
};
