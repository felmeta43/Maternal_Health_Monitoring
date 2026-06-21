# IoT-Enabled Maternal Health Monitoring System

A smart wearable + mobile + cloud system for real-time maternal health monitoring in
low-resource settings (developed for the Gedeo Zone, Ethiopia context). See
`docs/executive_summary.md` for the project rationale and `docs/architecture.md` for the
end-to-end design.

## Stack

| Layer | Tech | Directory |
|---|---|---|
| Wearable firmware | ESP32, Arduino/PlatformIO, C++ | `firmware/` |
| Mobile app | Flutter (Dart) | `mobile/` |
| Backend | Python, FastAPI, PostgreSQL | `backend/` |
| Docs | Markdown | `docs/` |

## Why this design

Continuous internet/cellular connectivity from the wearable itself isn't assumed. The
wearable talks BLE to a nearby phone; the phone is offline-first (local cache + on-device
rule check) and syncs to the cloud backend whenever connectivity allows. The cloud
backend runs the canonical rule-based expert system (richer, history-aware checks) and
dispatches alerts to healthcare providers. Full rationale: `docs/architecture.md`.

## System Workflow (Start to End)

This is the full lifecycle of a single vital-sign reading, from sensor to clinician
action. Step numbers map to the data flow diagram in `docs/architecture.md`.

1. **Sensing (wearable).** The ESP32 wearable samples the MAX30102 (heart rate) and
   MLX90614 (body temperature) on a fixed interval (`SAMPLE_INTERVAL_MS` in
   `firmware/include/config.h`, default 5s). Each `SensorDriver`
   (`firmware/src/sensors/sensor_driver.h`) only fills in the fields it owns; a reading
   with no valid samples this cycle is skipped rather than sent (`firmware/src/main.cpp`).

2. **Transport (wearable → phone).** A valid reading is serialized to JSON and pushed
   over a BLE GATT characteristic notification (`firmware/src/ble_transport.cpp`). BLE is
   used instead of WiFi/cellular because the wearable cannot assume internet
   connectivity in the field; it only needs a nearby phone.

3. **Receive + cache (mobile app).** The Flutter app's `BleService`
   (`mobile/lib/services/ble_service.dart`) listens for notifications, decodes the JSON
   into a `VitalReading`, and immediately writes it to a local SQLite cache
   (`mobile/lib/services/local_db.dart`) marked unsynced. This makes the reading durable
   even with zero connectivity.

4. **Immediate local check (mobile app).** The same reading is run through
   `checkLocalThresholds()` (`mobile/lib/services/local_rules.dart`), a lightweight
   mirror of the single-vital thresholds in `docs/clinical_thresholds.md`. Any warning or
   critical result is shown instantly on `DashboardScreen`
   (`mobile/lib/screens/dashboard_screen.dart`) — this is a fallback so a danger sign is
   visible on the patient's/CHW's phone even before the backend ever sees the data.

5. **Sync (phone → cloud, opportunistic).** `SyncService`
   (`mobile/lib/services/sync_service.dart`) polls the local cache for unsynced readings
   on a timer and POSTs each to the backend via `ApiService`
   (`mobile/lib/services/api_service.dart`). A failed POST (no connectivity, backend
   down) just leaves the row unsynced for the next attempt — nothing is lost or
   double-sent once it succeeds.

6. **Ingestion (backend).** `POST /api/v1/readings`
   (`backend/app/routers/readings.py`) persists the reading, then loads that patient's
   last `HISTORY_WINDOW` (10) readings to give the expert system context beyond the
   single data point the mobile app's local check had.

7. **Diagnosis (backend expert system).** `expert_system.engine.evaluate()`
   (`backend/app/expert_system/engine.py`) runs the full rule set
   (`backend/app/expert_system/rules.py`) against the new reading and its history —
   single-vital thresholds (heart rate, SpO2, temperature, blood pressure), and
   composite/history-aware patterns such as sustained tachycardia + fever
   (`POSSIBLE_SEPSIS`) that the on-device check in step 4 can't evaluate alone.

8. **Alerting.** Every rule that fires creates an `Alert` row
   (`backend/app/models.py`) tied to the patient and the triggering reading, with a
   severity of `warning` or `critical`. `dispatch_alert()`
   (`backend/app/services/alerts_service.py`) is called for each new alert — currently
   logs the alert; an SMS/push gateway plugs in here without touching the rest of the
   pipeline.

9. **Clinical review.** Healthcare providers query `GET /api/v1/alerts`
   (`backend/app/routers/alerts.py`), scoped to the patients assigned to them, see the
   alert with its rule code and message, and acknowledge it via
   `POST /api/v1/alerts/{id}/acknowledge` once they've acted (e.g. contacted the patient,
   escalated to a facility) — closing the loop from sensor reading to clinical
   decision-making.

## Getting started

```bash
# Backend (FastAPI + SQLite for dev, or docker compose for Postgres)
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
pytest   # rule-engine + API tests

# Firmware (requires PlatformIO + ESP32 toolchain + the sensors listed in firmware/README.md)
cd firmware
pio run

# Mobile app (requires the Flutter SDK)
cd mobile
flutter pub get
flutter run
```

Each subdirectory has its own README with more detail. Clinical threshold definitions
used by both the backend's expert system and the mobile app's on-device fallback checks
are documented once in `docs/clinical_thresholds.md`.

## Status

This is an initial scaffold: a working FastAPI backend (tested end-to-end, including the
rule-based alert engine), an ESP32 firmware skeleton with a sensor driver abstraction,
and a Flutter app skeleton with BLE pairing, offline caching, and sync. See each
component's README for what's stubbed vs. fully implemented, and `docs/architecture.md`
for the security/production-readiness TODOs before any field deployment with real
patient data.
