from fastapi import FastAPI

from app.config import settings
from app.database import Base, engine
from app.routers import alerts, auth, patients, readings

Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.app_name)

app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(readings.router)
app.include_router(alerts.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
