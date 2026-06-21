#pragma once

#include "vital_reading.h"

// Advertises a BLE GATT service with one characteristic that carries a JSON
// vital reading payload. The paired mobile app (see mobile/lib/services/
// ble_service.dart) subscribes to notifications on this characteristic,
// caches readings locally, and syncs them to the backend when connectivity
// allows.
namespace BleTransport {

void begin();
void notifyReading(const VitalReading &reading);
bool isClientConnected();

}  // namespace BleTransport
