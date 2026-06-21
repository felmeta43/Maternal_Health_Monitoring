import logging

from app.config import settings
from app.models import Alert, Patient

logger = logging.getLogger("alerts")


def dispatch_alert(alert: Alert, patient: Patient) -> None:
    """Send a notification for a newly created alert.

    No SMS gateway is wired up in this scaffold; dispatch is logged so the
    call site and data flow are in place once a provider (e.g. Twilio, a
    local telco SMS gateway) is integrated.
    """
    if not settings.sms_gateway_url:
        logger.info(
            "ALERT [%s] patient=%s rule=%s message=%s (no SMS gateway configured)",
            alert.severity.value,
            patient.full_name,
            alert.rule_code,
            alert.message,
        )
        return

    logger.info(
        "Would dispatch SMS to provider for patient=%s rule=%s via %s",
        patient.full_name,
        alert.rule_code,
        settings.sms_gateway_url,
    )
