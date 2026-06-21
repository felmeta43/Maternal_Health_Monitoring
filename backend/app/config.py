from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Maternal Health Monitoring API"
    database_url: str = "sqlite:///./dev.db"
    jwt_secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    sms_gateway_url: str | None = None
    sms_gateway_api_key: str | None = None


settings = Settings()
