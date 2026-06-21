from app.expert_system.rules import DEFAULT_RULES, RuleResult
from app.models import VitalReading


def evaluate(reading: VitalReading, history: list[VitalReading]) -> list[RuleResult]:
    """Run all rules against a reading and that patient's recent history.

    `history` should be ordered most-recent-first and excludes `reading` itself.
    """
    results: list[RuleResult] = []
    for rule in DEFAULT_RULES:
        result = rule(reading, history)
        if result is not None:
            results.append(result)
    return results
