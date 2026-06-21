#pragma once

#include <limits>

// NaN is used as the "no value" sentinel for optional fields, mirroring the
// optional vitals on the backend's VitalReadingCreate schema. A sensor driver
// that doesn't support a given parameter (or hasn't produced a valid sample
// yet) simply leaves that field as NAN.
struct VitalReading {
    float heart_rate_bpm = std::numeric_limits<float>::quiet_NaN();
    float spo2_percent = std::numeric_limits<float>::quiet_NaN();
    float body_temperature_c = std::numeric_limits<float>::quiet_NaN();
    unsigned long timestamp_ms = 0;
};

inline bool has_value(float v) {
    return !isnan(v);
}
