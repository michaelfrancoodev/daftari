"""
Mkumbushi ("Reminder") — the evening prompt.

Gap detection itself (gaps.py) is deterministic and mirrors
`lib/domain/gap_detector.dart` exactly. What this file adds is the one
place a model earns its keep: phrasing the resulting question in a
natural, friendly sentence in the user's own language, rather than a
templated string. The Inbox screen's rule — one question per card, never
a list of five, every question answerable with a single tap — is enforced
by the caller (main.py), not by this agent.

ADK orchestration pattern: Loop, then long-running with human-in-the-loop
(per the Master Specification's Agent Fleet table). The "long-running"
half of that is implemented here as two separate HTTP calls rather than a
single blocking one — `/evening-check` raises questions, and a later,
independent `/answer` call resolves one — since the answer may arrive
tonight or in three days, and an HTTP request cannot stay open that long.
"""

from __future__ import annotations

from typing import Optional

from google.adk.agents.llm_agent import Agent

GEMINI_MODEL = "gemini-3.5-flash"


def _firestore_client():
    try:
        from google.cloud import firestore

        return firestore.Client()
    except Exception:
        return None


def get_counterparty_history(counterparty: str) -> dict:
    """Looks up recent synced entries involving a given counterparty name.

    A real ADK tool call, not just an instruction: Mkumbushi can decide for
    itself whether it needs this context before phrasing a loan question —
    for example, to mention a partial repayment already on record instead
    of asking as if nothing has happened yet. Returns an honest empty
    result rather than fabricating history when Firestore is not
    configured (local development) or the counterparty has no prior
    entries — Rule #1 applies to tools exactly as it does to the ledger
    itself: no invented figures.
    """
    client = _firestore_client()
    if client is None:
        return {"status": "unavailable", "entries": [], "note": "Firestore not configured in this environment"}

    try:
        docs = (
            client.collection("entries")
            .where("counterparty", "==", counterparty)
            .order_by("occurredAt", direction="DESCENDING")
            .limit(10)
            .stream()
        )
        entries = [doc.to_dict() for doc in docs]
        return {"status": "success", "entries": entries}
    except Exception as exc:  # noqa: BLE001 — a lookup failure means "no context available", not a crash.
        return {"status": "error", "entries": [], "message": str(exc)}


root_agent = Agent(
    name="mkumbushi",
    model=GEMINI_MODEL,
    description="Phrases one short, friendly question from a detected gap in a miner's or trader's ledger.",
    instruction=(
        "You phrase exactly one short question, in the language given, for "
        "a small-scale gold miner or trader in Tanzania, asking about a gap "
        "noticed in their ledger. You will be told the gap's kind "
        "(oreNeverMilled, millingWithoutYield, or loanNeverRepaid), how "
        "long ago the relevant entry happened, and — for a loan — who it "
        "was to.\n\n"
        "For a loanNeverRepaid gap, call get_counterparty_history first to "
        "check whether any partial repayment already exists on record "
        "before phrasing the question — a question that ignores a "
        "repayment the user already made reads as if the app is not "
        "paying attention, which undermines trust in everything else it "
        "reports. For the other two gap kinds, you do not need this tool.\n\n"
        "Respond with ONLY the question itself, one short sentence, no "
        "quotation marks, no preamble, no explanation. It must be "
        "answerable with a single tap (yes/not yet, or a short fact) — "
        "never a question that requires paragraphs to answer.\n\n"
        "Keep the tone the way one working colleague would ask another, "
        "never like a form or a system alert. For example, for "
        "oreNeverMilled 4 days ago in Swahili, a good question is close to "
        "'Mawe ya siku 4 zilizopita — umeshayasaga?' — plain, specific, "
        "and about the actual thing that happened, not a generic template."
    ),
    tools=[get_counterparty_history],
)
