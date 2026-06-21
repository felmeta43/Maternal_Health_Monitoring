#pragma once

#include <Adafruit_MLX90614.h>
#include "sensor_driver.h"

// Contactless infrared body temperature via MLX90614 over I2C.
class TemperatureSensor : public SensorDriver {
public:
    bool begin() override;
    bool sample(VitalReading &reading) override;

private:
    Adafruit_MLX90614 mlx_;
};
