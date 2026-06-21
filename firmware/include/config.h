#pragma once

// Device identity — must match the `device_id` registered for the patient
// in the backend (see backend/app/models.py Patient.device_id).
#define DEVICE_ID "esp32-001"

// BLE identifiers. Generate fresh UUIDs per deployment/product if this ships
// beyond a prototype, to avoid cross-talk between nearby devices.
#define BLE_SERVICE_UUID "5f1a1b2c-0001-4e6b-9b1a-2f6a0c9d1a01"
#define BLE_READING_CHARACTERISTIC_UUID "5f1a1b2c-0002-4e6b-9b1a-2f6a0c9d1a01"
#define BLE_DEVICE_NAME "MHM-Wearable"

// How often a vital reading is sampled and pushed over BLE, in milliseconds.
constexpr unsigned long SAMPLE_INTERVAL_MS = 5000;

// I2C pins (ESP32 default).
constexpr int I2C_SDA_PIN = 21;
constexpr int I2C_SCL_PIN = 22;
