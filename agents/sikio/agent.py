"""
Sikio ("Ear") — server-side refinement of what the on-device Interpreter
already does offline.

`flutter/daftari/lib/domain/interpreter.dart` is a hand-written, regex and
atom-table based parser that runs entirely on the device, with no network
(Rule #2). It has to be fast and work with the aeroplane-mode switch on, so
it is deliberately literal: it recognises a fixed vocabulary and refuses
anything outside it rather than guessing (Rule #1).

Sikio is what that parser hands off to *if and when a network appears*. It
is strictly a refinement step, never a requirement: an entry the on-device
parser already read with confidence is never re-interpreted, and nothing
on this service's critical path blocks capture. Concretely, this agent is
useful for exactly the cases the device already flagged as uncertain — an
ambiguous quantity, a counterparty it couldn't name, a spoken amount using
vocabulary the hand-written parser doesn't cover — where Gemini's general
language understanding can resolve something a fixed grammar cannot.

ADK orchestration pattern: Sequential (per the Master Specification's
Agent Fleet table) — split, then interpret, in that order, same as the
on-device version.
"""

from __future__ import annotations

from google.adk.agents.llm_agent import Agent

GEMINI_MODEL = "gemini-3.5-flash"

ENTRY_KINDS = [
    "orePurchase",
    "fuel",
    "milling",
    "goldYield",
    "wages",
    "loan",
    "repayment",
    "sale",
]


def _firestore_client():
    try:
        from google.cloud import firestore

        return firestore.Client()
    except Exception:
        return None


def get_known_counterparties() -> dict:
    """Returns the distinct counterparty names already on record for this
    user, most recently used first.

    A real ADK tool, called when the uncertain field is a counterparty
    name: knowing that "Juma Mwita" is already an established supplier
    makes it far more likely that an unclear "Juma" in a new recording
    refers to the same person, rather than the model guessing from the
    audio-derived text alone. Returns an honest empty list — never a
    fabricated name — when Firestore is not configured or no history
    exists yet.
    """
    client = _firestore_client()
    if client is None:
        return {"status": "unavailable", "counterparties": []}

    try:
        docs = (
            client.collection("entries")
            .where("counterparty", "!=", None)
            .order_by("counterparty")
            .order_by("occurredAt", direction="DESCENDING")
            .limit(50)
            .stream()
        )
        seen: list[str] = []
        for doc in docs:
            name = doc.to_dict().get("counterparty")
            if name and name not in seen:
                seen.append(name)
        return {"status": "success", "counterparties": seen[:10]}
    except Exception as exc:  # noqa: BLE001 — a lookup failure just means no extra context is available.
        return {"status": "error", "counterparties": [], "message": str(exc)}


root_agent = Agent(
    name="sikio",
    model=GEMINI_MODEL,
    description=(
        "Refines an uncertain transaction from DAFTARI's on-device interpreter — "
        "resolving an ambiguous amount, quantity, or counterparty that the "
        "hand-written offline parser could not read with confidence."
    ),
    instruction=(
        "You help resolve ONE uncertain field in a single financial transaction "
        "spoken or typed by a small-scale gold miner or trader in Tanzania, in "
        "Swahili or English. You are called only for entries the on-device "
        "parser already flagged as uncertain — never re-interpret a field the "
        "device was already confident about.\n\n"
        f"Valid transaction kinds are exactly: {', '.join(ENTRY_KINDS)}.\n\n"
        "You will be given: the original verbatim sentence, which field is "
        "uncertain (amount, quantity, or counterparty), and what the "
        "on-device parser already extracted for the other fields.\n\n"
        "When the uncertain field is a counterparty, call "
        "get_known_counterparties first and check whether one of the "
        "returned names is a close match to what the sentence seems to say "
        "— a name already established in this user's own records is far "
        "more likely to be correct than a new spelling invented from "
        "scratch. For amount or quantity fields, this tool has nothing "
        "useful to offer and should not be called.\n\n"
        "Respond with ONLY a single JSON object, no markdown fences, no "
        'commentary: {"resolved": <the corrected value, or null>, '
        '"confidence": "high" | "low"}.\n\n'
        "For an amount, resolved must be a plain integer (Tanzanian "
        "shillings, no decimals). For a quantity, resolved must be a "
        "decimal number of grams. For a counterparty, resolved must be the "
        "name as a string.\n\n"
        "If you cannot resolve the field with genuine confidence, respond "
        'with {"resolved": null, "confidence": "low"}. Rule #1 of this '
        "product may never be broken: an unresolved figure must stay "
        "unresolved rather than become a guess that looks plausible. A "
        "wrong number that is believed is worse than an honest gap."
    ),
    tools=[get_known_counterparties],
)
