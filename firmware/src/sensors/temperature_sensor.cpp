#include "temperature_sensor.h"

bool TemperatureSensor::begin() {
    return mlx_.begin();
}

bool TemperatureSensor::sample(VitalReading &reading) {
    float objectTempC = mlx_.readObjectTempC();
    if (isnan(objectTempC) || objectTempC < 20.0f || objectTempC > 45.0f) {
        // Out of plausible human body temperature range — likely a bad
        // reading (sensor not against skin) rather than a real value.
        return false;
    }
    reading.body_temperature_c = objectTempC;
    return true;
}
