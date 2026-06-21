# Backend — FastAPI + PostgreSQL

Ingestion API, persistence, the rule-based expert system, and alert dispatch for the
Maternal Health Monitoring platform.

## Local development (SQLite, no Docker)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

By default `DATABASE_URL` is `sqlite:///./dev.db`, so no external database is required
to develop and run tests. Tables are auto-created on startup for this dev path.

Run tests:

```bash
pytest
```

## With PostgreSQL (Docker Compose)

```bash
docker compose up --build
```

This starts PostgreSQL and the API together, with the API's `DATABASE_URL` pointed at
the `db` service. Use Alembic for schema migrations against Postgres:

```bash
alembic revision --autogenerate -m "description"
alembic upgrade head
```

## API overview

- `POST /api/v1/auth/register`, `POST /api/v1/auth/login` — provider/CHW accounts (JWT).
- `POST /api/v1/patients`, `GET /api/v1/patients` — patient registry, scoped to the
  authenticated provider.
- `POST /api/v1/readings` — ingest a vital reading; runs the expert system
  (`app/expert_system/`) against the reading and the patient's recent history, persists
  any resulting `Alert` rows, and dispatches notifications.
- `GET /api/v1/readings/{patient_id}` — reading history for a patient.
- `GET /api/v1/alerts`, `POST /api/v1/alerts/{id}/acknowledge` — provider alert inbox.

See `docs/clinical_thresholds.md` at the repo root for the rule definitions and
`docs/architecture.md` for how this fits into the wearable → mobile → cloud pipeline.
