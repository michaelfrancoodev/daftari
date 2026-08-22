"""
Mlinganishi ("Reconciler") — the fuzzy half.

`reconcile.py` is a deterministic exact-match pass (same kind, same day,
same amount) that needs no model. This file is called only afterwards, and
only on the entries that pass left unmatched, to answer one narrow
question: could "Juma" on one side and "Juma Mwita" on the other
plausibly be the same person, given the rest of what matched?

ADK orchestration pattern: Parallel and Custom (per the Master
Specification's Agent Fleet table) — in practice, one Gemini call per
unmatched pair, which a caller can run concurrently.
"""

from __future__ import annotations

from google.adk.agents.llm_agent import Agent

GEMINI_MODEL = "gemini-3.5-flash"

root_agent = Agent(
    name="mlinganishi",
    model=GEMINI_MODEL,
    description="Judges whether two differently-spelled counterparty names plausibly refer to the same person.",
    instruction=(
        "You are given two counterparty names from two different people's "
        "records of what should be the same real-world transaction — same "
        "kind of transaction, same date, same amount — except the name "
        "differs: for example 'Juma' versus 'Juma Mwita', or 'Kondo' "
        "versus 'Salehe Kondo'. Names may be Swahili or English, and "
        "spelling can vary.\n\n"
        "Respond with ONLY a single JSON object, no markdown fences, no "
        'commentary: {"same_person": true | false, "confidence": "high" | '
        '"low"}.\n\n'
        "Say true only when one name is plausibly a shorter or longer form "
        "of the other (a first name matching a full name, an obvious "
        "nickname, a spelling variant). Say false for two names that share "
        "no clear relationship, even if the transaction otherwise lines "
        "up — a coincidence in timing and amount is not evidence about "
        "identity, and Rule #1 of this product means a wrong guess here is "
        "worse than leaving two entries unmatched for a person to check."
    ),
    tools=[],
)
