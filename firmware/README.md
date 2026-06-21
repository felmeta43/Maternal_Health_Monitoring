# Firmware — ESP32 Wearable

PlatformIO project for the maternal health wearable: samples biomedical sensors and
streams readings to a paired phone over BLE.

## Hardware (v1)

- ESP32 dev board (Arduino framework)
- MAX30102 — heart rate (PPG beat detection) + SpO2 (I2C)
- MLX90614 — contactless infrared body temperature (I2C)
- (Optional, not yet wired into `main.cpp`) MPU6050 — motion/fall detection

Blood pressure is **not** continuously sensed by the wearable in v1 — see
`docs/architecture.md` for why, and how it's captured instead.

## Build

```bash
pio run                 # build
pio run -t upload       # flash
pio device monitor      # serial logs
```

## Adding a sensor

Implement `SensorDriver` (`src/sensors/sensor_driver.h`): `begin()` to initialize the
hardware, `sample(VitalReading&)` to write into whichever `VitalReading` field(s) that
sensor owns. Instantiate it in `main.cpp` and call `sample()` in the loop — no changes
needed to `ble_transport.cpp` or the JSON payload shape beyond adding the new field.

## BLE contract

The device advertises as `MHM-Wearable` with one GATT characteristic
(`BLE_READING_CHARACTERISTIC_UUID` in `include/config.h`) that notifies a JSON payload
per sample, e.g.:

```json
{"device_id": "esp32-001", "timestamp_ms": 1234567, "heart_rate_bpm": 78.2, "body_temperature_c": 37.1}
```

Fields with no valid sample this cycle are omitted rather than sent as null/zero. The
mobile app (`mobile/lib/services/ble_service.dart`) is the consumer of this contract.
