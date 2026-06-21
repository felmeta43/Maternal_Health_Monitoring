#include "max30102_sensor.h"
#include <Wire.h>
#include <heartRate.h>

bool Max30102Sensor::begin() {
    if (!particleSensor_.begin(Wire, I2C_SPEED_FAST)) {
        return false;
    }
    particleSensor_.setup(/*ledBrightness=*/0x1F, /*sampleAverage=*/4,
                           /*ledMode=*/2, /*sampleRate=*/100,
                           /*pulseWidth=*/411, /*adcRange=*/4096);
    return true;
}

bool Max30102Sensor::isFingerDetected() {
    // A low IR reading means nothing is in contact with the sensor.
    return particleSensor_.getIR() > 50000;
}

bool Max30102Sensor::sample(VitalReading &reading) {
    if (!isFingerDetected()) {
        return false;
    }

    long irValue = particleSensor_.getIR();
    if (checkForBeat(irValue)) {
        long now = millis();
        long delta = now - lastBeatMs_;
        lastBeatMs_ = now;

        if (delta > 0) {
            float bpm = 60000.0f / delta;
            if (bpm > 30 && bpm < 220) {
                beatHistoryMs_[beatHistoryIndex_] = delta;
                beatHistoryIndex_ = (beatHistoryIndex_ + 1) % kBeatHistorySize;

                long avgDelta = 0;
                for (int i = 0; i < kBeatHistorySize; i++) {
                    avgDelta += beatHistoryMs_[i];
                }
                avgDelta /= kBeatHistorySize;
                reading.heart_rate_bpm = 60000.0f / avgDelta;
            }
        }
    }

    reading.spo2_percent = estimateSpo2();
    return has_value(reading.heart_rate_bpm) || has_value(reading.spo2_percent);
}

float Max30102Sensor::estimateSpo2() {
    // TODO: integrate Maxim's maxim_heart_rate_and_oxygen_saturation() from
    // spo2_algorithm.h (SparkFun MAX3010x examples) against buffered
    // IR/red samples. Returning NaN keeps the field absent until that
    // calibration-sensitive algorithm is wired in and bench-validated,
    // rather than reporting an unvalidated number.
    return std::numeric_limits<float>::quiet_NaN();
}
