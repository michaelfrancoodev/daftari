"""
HTTP surface for the Sikio agent, deployed to Cloud Run.

One route, called only when the app has a network and only for a field
the on-device Interpreter already flagged as uncertain — never on the
critical path of capturing an entry.
"""

from __future__ import annotations

import json
import os
import re
from typing import Literal, Optional

from fastapi import FastAPI, HTTPException
from google.adk.runners import InMemoryRunner
from pydantic import BaseModel

from agent import root_agent

app = FastAPI(title="daftari-sikio-agent")


class ResolveFieldRequest(BaseModel):
    verbatim_text: str
    uncertain_field: Literal["amount", "quantity", "counterparty"]
    known_kind: Optional[str] = None
    known_amount: Optional[int] = None
    known_quantity: Optional[float] = None
    known_counterparty: Optional[str] = None


class ResolveFieldResponse(BaseModel):
    resolved: Optional[str] = None
    confidence: Literal["high", "low"] = "low"


def _extract_json(text: str) -> dict:
    cleaned = text.strip()
    cleaned = re.sub(r"^```(json)?", "", cleaned).strip()
    cleaned = re.sub(r"```$", "", cleaned).strip()
    return json.loads(cleaned)


def _build_prompt(req: ResolveFieldRequest) -> str:
    known = {
        "kind": req.known_kind,
        "amount": req.known_amount,
        "quantity": req.known_quantity,
        "counterparty": req.known_counterparty,
    }
    return (
        f'Sentence: "{req.verbatim_text}"\n'
        f"Uncertain field: {req.uncertain_field}\n"
        f"Already known: {json.dumps(known)}\n"
        "Resolve the uncertain field."
    )


@app.get("/healthz")
def healthz() -> dict:
    return {"ok": True}


@app.post("/resolve-field", response_model=ResolveFieldResponse)
async def resolve_field(req: ResolveFieldRequest) -> dict:
    runner = InMemoryRunner(agent=root_agent)
    try:
        result = await runner.run_debug(_build_prompt(req), verbose=False)
        response_text = result if isinstance(result, str) else getattr(result, "text", None) or str(result)
        parsed = _extract_json(response_text)
    except Exception as exc:  # noqa: BLE001 — any failure here means "unresolved", not a crash.
        raise HTTPException(status_code=502, detail=f"Sikio could not process this field: {exc}") from exc

    return {
        "resolved": None if parsed.get("resolved") is None else str(parsed["resolved"]),
        "confidence": parsed.get("confidence", "low"),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
