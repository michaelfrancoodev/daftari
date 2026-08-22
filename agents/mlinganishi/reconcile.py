"""
Deterministic reconciliation core for Mlinganishi ("Reconciler").

Two linked parties — say a sponsor and a miner sharing a DFT-#### code —
each record their own side of the same transactions. This module answers:
for each of party A's entries, is there a matching entry from party B, and
if so, do the two versions actually agree?

The exact-match pass here needs no model at all: same kind, same date
(within a day), same amount is either a match or it is not. Where this
gets genuinely hard — and where `agent.py` calls Gemini — is deciding
whether "Juma" and "Juma Mwita" plausibly refer to the same counterparty
when no other signal disambiguates them. That fuzzy step is optional and
additive: this deterministic pass alone already finds every case where
both parties recorded the counterparty identically.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional

MATCH_WINDOW = timedelta(days=1)


@dataclass(frozen=True)
class PartyEntry:
    id: str
    kind: str
    occurred_at: datetime
    amount_minor_units: Optional[int]
    counterparty: Optional[str]


@dataclass(frozen=True)
class Match:
    party_a_id: str
    party_b_id: str
    agrees: bool
    reason: str


def reconcile(party_a: list[PartyEntry], party_b: list[PartyEntry]) -> tuple[list[Match], list[PartyEntry], list[PartyEntry]]:
    """Returns (matches, unmatched_a, unmatched_b).

    A match with `agrees=False` is exactly the case the Master
    Specification calls out by name: "a sponsor who logged one figure
    against a miner who logged another" — surfaced with both sources
    shown, never silently resolved one way.
    """
    matches: list[Match] = []
    matched_b_ids: set[str] = set()

    for a in party_a:
        candidate = next(
            (
                b
                for b in party_b
                if b.id not in matched_b_ids
                and b.kind == a.kind
                and abs(b.occurred_at - a.occurred_at) <= MATCH_WINDOW
            ),
            None,
        )
        if candidate is None:
            continue

        matched_b_ids.add(candidate.id)
        agrees = a.amount_minor_units == candidate.amount_minor_units
        reason = (
            "amounts match exactly"
            if agrees
            else f"amount disagreement: party A recorded {a.amount_minor_units}, party B recorded {candidate.amount_minor_units}"
        )
        matches.append(Match(party_a_id=a.id, party_b_id=candidate.id, agrees=agrees, reason=reason))

    matched_a_ids = {m.party_a_id for m in matches}
    unmatched_a = [a for a in party_a if a.id not in matched_a_ids]
    unmatched_b = [b for b in party_b if b.id not in matched_b_ids]

    return matches, unmatched_a, unmatched_b
