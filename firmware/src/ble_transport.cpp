#include "ble_transport.h"
#include "config.h"

#include <ArduinoJson.h>
#include <BLE2902.h>
#include <BLECharacteristic.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

namespace {

BLECharacteristic *readingCharacteristic = nullptr;
bool clientConnected = false;

class ConnectionCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer *server) override { clientConnected = true; }
    void onDisconnect(BLEServer *server) override {
        clientConnected = false;
        server->getAdvertising()->start();
    }
};

}  // namespace

namespace BleTransport {

void begin() {
    BLEDevice::init(BLE_DEVICE_NAME);
    BLEServer *server = BLEDevice::createServer();
    server->setCallbacks(new ConnectionCallbacks());

    BLEService *service = server->createService(BLE_SERVICE_UUID);
    readingCharacteristic = service->createCharacteristic(
        BLE_READING_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ);
    readingCharacteristic->addDescriptor(new BLE2902());

    service->start();
    server->getAdvertising()->addServiceUUID(BLE_SERVICE_UUID);
    server->getAdvertising()->start();
}

bool isClientConnected() { return clientConnected; }

void notifyReading(const VitalReading &reading) {
    if (readingCharacteristic == nullptr || !clientConnected) {
        return;
    }

    JsonDocument doc;
    doc["device_id"] = DEVICE_ID;
    doc["timestamp_ms"] = reading.timestamp_ms;
    if (has_value(reading.heart_rate_bpm)) {
        doc["heart_rate_bpm"] = reading.heart_rate_bpm;
    }
    if (has_value(reading.spo2_percent)) {
        doc["spo2_percent"] = reading.spo2_percent;
    }
    if (has_value(reading.body_temperature_c)) {
        doc["body_temperature_c"] = reading.body_temperature_c;
    }

    String payload;
    serializeJson(doc, payload);

    readingCharacteristic->setValue(payload.c_str());
    readingCharacteristic->notify();
}

}  // namespace BleTransport
