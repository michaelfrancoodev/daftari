"""
Deterministic gap detection, mirroring `lib/domain/gap_detector.dart`
exactly (same three rules, same thresholds), so a server-side evening
check can never disagree with what the device already knows how to find
on its own when offline.

Deliberately kept separate from the Gemini call in agent.py: *finding* a
gap is a fact-check with a definite right answer and must never depend on
a model's judgement; *phrasing* the resulting question in a natural,
friendly way is where an LLM is actually a good fit.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional


@dataclass(frozen=True)
class Entry:
    id: str
    kind: str
    occurred_at: datetime
    counterparty: Optional[str] = None
    is_live: bool = True


@dataclass(frozen=True)
class Gap:
    entry_id: str
    kind: str  # "oreNeverMilled" | "millingWithoutYield" | "loanNeverRepaid"
    occurred_at: datetime


ORE_TO_MILL_GRACE = timedelta(days=3)
MILL_TO_YIELD_GRACE = timedelta(days=1)
LOAN_REPAYMENT_GRACE = timedelta(days=60)


def detect(entries: list[Entry], now: datetime) -> list[Gap]:
    live = [e for e in entries if e.is_live]
    gaps: list[Gap] = []

    has_any_milling = any(e.kind == "milling" for e in live)
    for e in live:
        if e.kind == "orePurchase" and now - e.occurred_at > ORE_TO_MILL_GRACE and not has_any_milling:
            gaps.append(Gap(entry_id=e.id, kind="oreNeverMilled", occurred_at=e.occurred_at))

    has_any_yield = any(e.kind == "goldYield" for e in live)
    for e in live:
        if e.kind == "milling" and now - e.occurred_at > MILL_TO_YIELD_GRACE and not has_any_yield:
            gaps.append(Gap(entry_id=e.id, kind="millingWithoutYield", occurred_at=e.occurred_at))

    repaid_counterparties = {e.counterparty for e in live if e.kind == "repayment" and e.counterparty}
    for e in live:
        if (
            e.kind == "loan"
            and e.counterparty
            and e.counterparty not in repaid_counterparties
            and now - e.occurred_at > LOAN_REPAYMENT_GRACE
        ):
            gaps.append(Gap(entry_id=e.id, kind="loanNeverRepaid", occurred_at=e.occurred_at))

    return gaps
