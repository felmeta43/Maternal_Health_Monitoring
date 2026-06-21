#pragma once

#include "vital_reading.h"

// Common interface for any biomedical sensor module on the wearable.
// Each driver only fills in the VitalReading field(s) it is responsible for,
// leaving the rest untouched. This lets new sensors (e.g. a future BP
// module, see docs/architecture.md) be added without changing the transport
// layer or the main sampling loop.
class SensorDriver {
public:
    virtual ~SensorDriver() = default;

    // Initializes the underlying hardware. Returns false if the sensor could
    // not be found/initialized (e.g. not wired up, I2C address mismatch).
    virtual bool begin() = 0;

    // Takes a sample and writes it into `reading`. Returns false if no valid
    // sample could be produced this cycle (e.g. poor finger contact for PPG).
    virtual bool sample(VitalReading &reading) = 0;
};
