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
