"""
HTTP surface for the Daftari agent, deployed to Cloud Run.

Called during sync, whenever more than one device has entries to merge
into a shared ledger for a linked working group.
"""

from __future__ import annotations

import os
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from agent import ValidationError, RawEntry, cost_per_gram, deduplicate, validate_entry

app = FastAPI(title="daftari-daftari-agent")


class EntryPayload(BaseModel):
    id: str
    kind: str
    occurred_at: datetime
    amount_minor_units: Optional[int] = None
    quantity: Optional[float] = None
    counterparty: Optional[str] = None
    device_id: str


class ReconcileRequest(BaseModel):
    entries: list[EntryPayload]


class ReconcileResponse(BaseModel):
    kept: list[EntryPayload]
    duplicates_removed: int
    cost_per_gram_minor_units: Optional[int]


@app.get("/healthz")
def healthz() -> dict:
    return {"ok": True}


@app.post("/reconcile-batch", response_model=ReconcileResponse)
def reconcile_batch(req: ReconcileRequest) -> dict:
    raw_entries = [
        RawEntry(
            id=e.id,
            kind=e.kind,
            occurred_at=e.occurred_at,
            amount_minor_units=e.amount_minor_units,
            quantity=e.quantity,
            counterparty=e.counterparty,
            device_id=e.device_id,
        )
        for e in req.entries
    ]

    for entry in raw_entries:
        try:
            validate_entry(entry)
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=f"Entry {entry.id}: {exc}") from exc

    kept, dropped = deduplicate(raw_entries)
    kept_ids = {e.id for e in kept}

    return {
        "kept": [e for e in req.entries if e.id in kept_ids],
        "duplicates_removed": len(dropped),
        "cost_per_gram_minor_units": cost_per_gram(kept),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
