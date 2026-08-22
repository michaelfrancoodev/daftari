"""
Daftari ("Ledger") — validates, deduplicates, and assembles synced entries
into batches.

Per the Master Specification's Agent Fleet table, this agent's pattern is
explicitly "Sequential" and its mechanism is "Deterministic, not a model" —
unlike Sikio and Mkumbushi, nothing here calls Gemini. Money is validated,
duplicates are detected, and batches are assembled with the exact same
rules `lib/domain/ledger.dart` already uses on the device, so a server-side
recomputation can never disagree with the number the user already saw on
their phone.

Why this exists server-side at all, given the device already does this:
two phones belonging to the same working group can each record an
overlapping set of entries (e.g. both partners speak about the same sale),
and syncing raw entries from both devices into one shared ledger needs a
single, authoritative place to decide what counts once. That is this
agent's entire job.

ADK orchestration pattern: Sequential (validate, then deduplicate, then
assemble) — deliberately implemented as plain, testable Python functions
rather than an LLM agent object, because Rule #6 (money is an integer,
never guessed) and Rule #5 (no UPDATE/DELETE except two lifecycle
pointers) are exactly the kind of rules that must never depend on a
model's judgement.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional

ENTRY_KINDS = frozenset(
    {"orePurchase", "fuel", "milling", "goldYield", "wages", "loan", "repayment", "sale"}
)

DEDUPLICATION_WINDOW = timedelta(minutes=2)


@dataclass(frozen=True)
class RawEntry:
    id: str
    kind: str
    occurred_at: datetime
    amount_minor_units: Optional[int]
    quantity: Optional[float]
    counterparty: Optional[str]
    device_id: str


class ValidationError(Exception):
    """Raised for an entry that cannot be a valid DAFTARI entry at all —
    never for one that is merely incomplete, which is a normal, legal
    state (Rule: incomplete is legal)."""


def validate_entry(entry: RawEntry) -> None:
    """Rejects a structurally invalid entry. Being uncertain about a field
    is fine; being the wrong *type* of value is not.

    Rule #6: money must always be a whole integer, never a float smuggled
    in as, say, 5000.5 shillings.
    """
    if entry.kind not in ENTRY_KINDS:
        raise ValidationError(f"Unknown entry kind: {entry.kind!r}")
    if entry.amount_minor_units is not None and not isinstance(entry.amount_minor_units, int):
        raise ValidationError("amount_minor_units must be an integer minor-unit count, never a float")
    if entry.quantity is not None and entry.quantity < 0:
        raise ValidationError("quantity cannot be negative")


def deduplicate(entries: list[RawEntry]) -> tuple[list[RawEntry], list[tuple[RawEntry, RawEntry]]]:
    """Returns (kept, duplicates_dropped_with_their_original).

    Two entries from *different* devices, close together in time, with
    identical kind/amount/quantity/counterparty are almost certainly the
    same real event synced twice — most commonly, two people in one
    working group both recording the same spoken sentence. Entries from
    the *same* device are never deduplicated this way, since a miner
    genuinely can buy two identical sacks of ore minutes apart.
    """
    kept: list[RawEntry] = []
    dropped: list[tuple[RawEntry, RawEntry]] = []

    for entry in sorted(entries, key=lambda e: e.occurred_at):
        duplicate_of = next(
            (
                existing
                for existing in kept
                if existing.device_id != entry.device_id
                and existing.kind == entry.kind
                and existing.amount_minor_units == entry.amount_minor_units
                and existing.quantity == entry.quantity
                and existing.counterparty == entry.counterparty
                and abs(existing.occurred_at - entry.occurred_at) <= DEDUPLICATION_WINDOW
            ),
            None,
        )
        if duplicate_of is not None:
            dropped.append((entry, duplicate_of))
        else:
            kept.append(entry)

    return kept, dropped


def cost_per_gram(entries: list[RawEntry]) -> Optional[int]:
    """The same arithmetic as `Ledger.summariseBatch` in
    lib/domain/ledger.dart, so a server-side figure can never disagree
    with what the device already showed the user.
    """
    cost_kinds = {"orePurchase", "fuel", "milling", "wages", "loan"}
    total_cost = sum(e.amount_minor_units or 0 for e in entries if e.kind in cost_kinds)
    total_grams = sum(e.quantity or 0 for e in entries if e.kind == "goldYield")
    if total_grams <= 0:
        return None
    return round(total_cost / total_grams)
