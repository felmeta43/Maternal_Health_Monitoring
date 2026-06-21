# System Architecture

## Overview

```
 ┌──────────────────┐      BLE (JSON)      ┌────────────────────┐      HTTPS (REST)     ┌─────────────────────┐
 │  Wearable Device  │ ───────────────────▶ │  Mobile App         │ ─────────────────────▶ │  Cloud Backend       │
 │  (ESP32 + sensors)│ ◀─────────────────── │  (Flutter, patient/ │ ◀───────────────────── │  (FastAPI + Postgres)│
 └──────────────────┘   commands/config     │   CHW device)       │   sync ack / alerts     └─────────────────────┘
                                             │  - offline cache    │                                  │
                                             │  - local alerting   │                                  │ rule-based
                                             └────────────────────┘                                  │ expert system
                                                                                                       ▼
                                                                                          ┌─────────────────────┐
                                                                                          │ Healthcare provider  │
                                                                                          │ dashboard + SMS/push │
                                                                                          │ alerts                │
                                                                                          └─────────────────────┘
```

## Why this topology

The Gedeo Zone deployment context has unreliable WiFi/cellular coverage. Continuous
cloud connectivity from the wearable itself is not assumed. Instead:

1. **Wearable → Phone (BLE):** the ESP32 wearable only needs a short-range, low-power
   link to a nearby smartphone (the patient's own phone or a community health worker's
   phone). BLE keeps wearable power draw low, which matters for a battery-powered device
   worn for extended periods.
2. **Phone → Cloud (HTTPS, opportunistic):** the mobile app is offline-first. Readings are
   cached locally (SQLite/Hive) and synced to the backend whenever connectivity is
   available. Critical rule-based alerts are also evaluated **on-device** as a fallback so
   a danger sign can be surfaced even before a sync succeeds.
3. **Cloud backend:** durable storage, the canonical rule-based expert system evaluation
   (richer rule set + history-aware trends), provider dashboards, and outbound
   notifications (SMS via a gateway, push notification, or in-app alert) to clinicians.

## Components

| Component | Stack | Responsibility |
|---|---|---|
| `firmware/` | ESP32 (Arduino framework, PlatformIO, C++) | Sensor sampling, local thresholding, BLE GATT server |
| `mobile/` | Flutter (Dart) | BLE pairing, offline cache, sync, patient/CHW UI, local alerts |
| `backend/` | Python, FastAPI, PostgreSQL, SQLAlchemy, Alembic | Ingestion API, persistence, expert system, alert dispatch, provider dashboard API |
| `docs/` | Markdown | Architecture, clinical thresholds, executive summary |

## Sensors (wearable v1)

| Parameter | Sensor | Notes |
|---|---|---|
| Heart rate & SpO2 | MAX30102 (PPG) | I2C, finger/wrist contact |
| Body temperature | MLX90614 (IR, contactless) or DS18B18 (contact) | Configurable driver |
| Motion / fall / activity | MPU6050 (accelerometer + gyro) | Used for signal-quality gating and fall detection |
| Blood pressure | *Not continuously sensed in v1* | See note below |

**Blood pressure note:** reliable continuous cuffless BP sensing (e.g. pulse-transit-time)
requires calibration per patient and is a known research gap. v1 treats BP as a
**manually entered** vital (via an oscillometric cuff reading entered through the mobile
app) rather than a wearable sensor reading, but the firmware's sensor driver interface
(`SensorDriver`, see `firmware/src/sensors/`) is designed so a BP module can be added later
without changing the transport or backend contract.

## Data flow

1. ESP32 samples sensors on a fixed interval, runs basic signal-quality checks, and
   pushes a JSON reading payload over a BLE GATT characteristic.
2. The Flutter app receives the payload, stores it locally, runs the same rule thresholds
   for an immediate on-device warning, and queues it for sync.
3. On connectivity, the app POSTs queued readings to `backend` `/api/v1/readings`.
4. The backend persists the reading, runs `expert_system.engine.evaluate()` against the
   patient's reading history, and creates an `Alert` row if any rule fires.
5. New alerts are pushed to the provider dashboard and dispatched via the configured
   notification channel (SMS gateway / push), per `backend/app/services/alerts_service.py`.

## Security & data sensitivity

This is clinical data. The backend scaffold includes a `patients` access boundary and JWT
auth stubs (`app/routers/auth.py`); production deployment must add TLS termination,
encryption at rest for PostgreSQL, and role-based access control before handling real
patient data. These are called out as TODOs rather than implemented in full here.
