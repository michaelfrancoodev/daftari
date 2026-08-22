"""
HTTP surface for the Mlinganishi agent, deployed to Cloud Run.

Called during sync, only when a share-code link exists between two
parties (the "Recommended," not "Must have," linking feature in the
Master Specification's feature list).
"""

from __future__ import annotations

import json
import os
import re
from datetime import datetime
from typing import Optional

from fastapi import FastAPI
from google.adk.runners import InMemoryRunner
from pydantic import BaseModel

from agent import root_agent
from reconcile import Match, PartyEntry, reconcile

app = FastAPI(title="daftari-mlinganishi-agent")


class EntryPayload(BaseModel):
    id: str
    kind: str
    occurred_at: datetime
    amount_minor_units: Optional[int] = None
    counterparty: Optional[str] = None


class ReconcileRequest(BaseModel):
    party_a: list[EntryPayload]
    party_b: list[EntryPayload]
    try_fuzzy_name_matching: bool = False


class MatchResult(BaseModel):
    party_a_id: str
    party_b_id: str
    agrees: bool
    reason: str


class ReconcileResponse(BaseModel):
    matches: list[MatchResult]
    unmatched_a: list[str]
    unmatched_b: list[str]


def _extract_json(text: str) -> dict:
    cleaned = re.sub(r"^```(json)?", "", text.strip()).strip()
    cleaned = re.sub(r"```$", "", cleaned).strip()
    return json.loads(cleaned)


async def _plausibly_same_person(name_a: str, name_b: str) -> bool:
    runner = InMemoryRunner(agent=root_agent)
    try:
        result = await runner.run_debug(f"Name A: {name_a}\nName B: {name_b}", verbose=False)
        text = result if isinstance(result, str) else getattr(result, "text", None) or str(result)
        parsed = _extract_json(text)
        return bool(parsed.get("same_person")) and parsed.get("confidence") == "high"
    except Exception:  # noqa: BLE001 — a failed fuzzy check just means "no match found", not a crash.
        return False


@app.get("/healthz")
def healthz() -> dict:
    return {"ok": True}


@app.post("/reconcile", response_model=ReconcileResponse)
async def reconcile_endpoint(req: ReconcileRequest) -> dict:
    party_a = [
        PartyEntry(id=e.id, kind=e.kind, occurred_at=e.occurred_at, amount_minor_units=e.amount_minor_units, counterparty=e.counterparty)
        for e in req.party_a
    ]
    party_b = [
        PartyEntry(id=e.id, kind=e.kind, occurred_at=e.occurred_at, amount_minor_units=e.amount_minor_units, counterparty=e.counterparty)
        for e in req.party_b
    ]

    matches, unmatched_a, unmatched_b = reconcile(party_a, party_b)

    if req.try_fuzzy_name_matching and unmatched_a and unmatched_b:
        still_unmatched_a: list[PartyEntry] = []
        remaining_b = list(unmatched_b)
        for a in unmatched_a:
            found = None
            for b in remaining_b:
                if a.counterparty and b.counterparty and await _plausibly_same_person(a.counterparty, b.counterparty):
                    found = b
                    break
            if found is not None:
                remaining_b.remove(found)
                matches.append(Match(party_a_id=a.id, party_b_id=found.id, agrees=True, reason="fuzzy name match"))
            else:
                still_unmatched_a.append(a)
        unmatched_a = still_unmatched_a
        unmatched_b = remaining_b

    return {
        "matches": [
            {"party_a_id": m.party_a_id, "party_b_id": m.party_b_id, "agrees": m.agrees, "reason": m.reason} for m in matches
        ],
        "unmatched_a": [e.id for e in unmatched_a],
        "unmatched_b": [e.id for e in unmatched_b],
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
