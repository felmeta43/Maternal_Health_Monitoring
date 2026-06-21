#include <Arduino.h>
#include <Wire.h>

#include "ble_transport.h"
#include "config.h"
#include "sensors/max30102_sensor.h"
#include "sensors/temperature_sensor.h"
#include "vital_reading.h"

Max30102Sensor pulseOxSensor;
TemperatureSensor temperatureSensor;

unsigned long lastSampleMs = 0;

void setup() {
    Serial.begin(115200);
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);

    if (!pulseOxSensor.begin()) {
        Serial.println("MAX30102 not detected — heart rate/SpO2 disabled");
    }
    if (!temperatureSensor.begin()) {
        Serial.println("MLX90614 not detected — temperature disabled");
    }

    BleTransport::begin();
    Serial.println("Wearable ready, advertising over BLE as " BLE_DEVICE_NAME);
}

void loop() {
    unsigned long now = millis();
    if (now - lastSampleMs < SAMPLE_INTERVAL_MS) {
        return;
    }
    lastSampleMs = now;

    VitalReading reading;
    reading.timestamp_ms = now;

    pulseOxSensor.sample(reading);
    temperatureSensor.sample(reading);

    if (has_value(reading.heart_rate_bpm) || has_value(reading.spo2_percent) ||
        has_value(reading.body_temperature_c)) {
        BleTransport::notifyReading(reading);
    }
}
