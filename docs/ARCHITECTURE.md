# Architecture

## The governing rule

The device holds the truth. The cloud adds intelligence over time, but nothing on the device's critical path — capturing an entry, seeing a batch's cost per gram, checking a pre-sale margin — ever requires a network. This is Rule #2, and it is why the diagram below has two halves that can each run completely independently of the other.

```
┌─────────────────────────────────────────────────────────────┐
│  DEVICE (Flutter, Android + Web)                              │
│                                                                │
│  Voice / Typed / Quick capture                                │
│         │                                                     │
│         ▼                                                     │
│  Interpreter (pure Dart, no network)                          │
│         │  splits one utterance into draft entries            │
│         ▼                                                     │
│  Review → commit → SQLite (Drift): CaptureRows + EntryRows    │
│         │                                                     │
│         ▼                                                     │
│  Ledger / GapDetector (pure Dart)                              │
│         │  cost per gram, day/month reports, gap detection    │
│         ▼                                                     │
│  Home / Batch / Presale / Reports / Inbox screens              │
└───────────────────────────┬────────────────────────────────────┘
                             │ (only when a network appears —
                             │  never required for the above)
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  GOOGLE CLOUD — four independent Cloud Run services            │
│                                                                │
│  Sikio        — refines one uncertain field (Gemini)           │
│  Daftari      — validates + deduplicates synced entries        │
│                 (deterministic, no model)                      │
│  Mkumbushi    — evening gap check + one phrased question       │
│                 (deterministic detection, Gemini for phrasing) │
│  Mlinganishi  — reconciles two linked parties' records          │
│                 (deterministic exact-match, optional Gemini    │
│                 fuzzy name pass)                                │
│                                                                │
│  Cloud Scheduler wakes Mkumbushi every evening — nobody asks.  │
│  Firestore holds synced entries and pending questions.         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  VERCEL — the marketing / landing website (Next.js)             │
│  Deployed entirely separately from the agents above.           │
│  Static content plus two informational pages (/architecture,   │
│  /privacy). No gold price, no live data feed, no dependency     │
│  on any Cloud Run service.                                      │
└─────────────────────────────────────────────────────────────┘
```

## Why no "Bei" (price) agent

An earlier iteration of this project's design included a fifth agent that fetched and published a daily gold reference price. That design was deliberately abandoned: gold is not a fungible commodity at the point a small-scale miner sells it — purity, recovery, grade, and buyer trust all move the number a single published figure cannot capture. Publishing one anyway would have taught users to trust a number that systematically misrepresents their actual position. See [`LIMITATIONS.md`](LIMITATIONS.md) for the full reasoning and what replaced it.

## The agent fleet, in detail

### Sikio ("Ear") — `agents/sikio/`
**Pattern:** Sequential. **Model:** Gemini 3.5 Flash. **Tool:** `get_known_counterparties` (Firestore, read-only).

The on-device `Interpreter` (`flutter/daftari/lib/domain/interpreter.dart`) is a hand-written parser: a fixed vocabulary of Swahili numerals, entry-kind verb stems, and regex-based clause splitting. It has to work offline and instantly, so it is deliberately literal — it refuses anything outside its known vocabulary rather than guessing (Rule #1). Sikio is what handles the refusal case, *if and when a network appears*: given the one field the device already flagged as uncertain, plus everything else it already read confidently, Gemini's general language understanding can often resolve what a fixed grammar cannot. When the uncertain field is a counterparty name, Sikio calls its `get_known_counterparties` tool first — a name already established in this user's own records is far more likely correct than a new spelling guessed from scratch. It is never on the capture path — an entry is fully usable, saved, and correct the moment the device confirms it, with or without Sikio ever running.

### Daftari ("Ledger") — `agents/daftari/`
**Pattern:** Sequential. **Model:** none — deterministic.

The Master Specification is explicit that this agent's mechanism is "deterministic, not a model," and this implementation honors that literally: `agents/daftari/agent.py` contains plain, fully-tested Python functions with no LLM call anywhere. Its job exists because two devices in one working group can each record overlapping entries — most often, two people both speaking about the same transaction — and merging two devices' entries into one shared ledger needs one authoritative place to decide what counts once. It validates entry types (Rule #6: money must be an integer), deduplicates near-simultaneous entries from *different* devices with identical kind/amount/quantity/counterparty, and recomputes cost-per-gram with the exact same arithmetic as the on-device `Ledger` class, so a server-side figure can never disagree with what the user already saw on their phone.

### Mkumbushi ("Reminder") — `agents/mkumbushi/`
**Pattern:** Loop, then long-running with human-in-the-loop. **Model:** Gemini 3.5 Flash (phrasing only). **Tool:** `get_counterparty_history` (Firestore, read-only).

Split into two files on purpose. `gaps.py` is a direct, tested port of `lib/domain/gap_detector.dart` — the same three rules (ore never milled after 3 days, milling with no yield after 1 day, a loan unpaid after 60 days), so the cloud and the device can never disagree about what counts as a gap. `agent.py` is where a model earns its keep in this agent: phrasing the resulting question naturally, in the user's language, rather than from a fixed template. Before phrasing a `loanNeverRepaid` question specifically, the agent calls `get_counterparty_history` to check for a partial repayment already on record — asking as if nothing has happened yet, when the user has in fact already paid something back, would read as the app not paying attention. The human-in-the-loop half of the ADK pattern is implemented as two independent HTTP calls (`POST /evening-check` and `POST /answer`) rather than one blocking request, since an answer may arrive that same evening or three days later, and Firestore — not an in-memory run — is what remembers the question in between.

### Mlinganishi ("Reconciler") — `agents/mlinganishi/`
**Pattern:** Parallel and Custom. **Model:** Gemini 3.5 Flash (optional, fuzzy name matching only).

`reconcile.py` is a deterministic exact-match pass between two linked parties' entries (same kind, same day, same amount is a match; a mismatched amount is surfaced as a disagreement — exactly the "sponsor logged one figure, miner logged another" case the Master Specification names directly — never silently resolved one way). Only entries that pass leaves unmatched are optionally handed to Gemini to judge whether a differently-spelled counterparty name ("Juma" vs. "Juma Mwita") plausibly refers to the same person. This agent depends on the share-code linking feature, which the Master Specification itself marks "Recommended," not "Must have" — it is genuinely optional depth, not a load-bearing part of the product.

## Data model

Three layers, matching the Master Specification exactly, implemented in `flutter/daftari/lib/domain/`:

1. **Capture** — the verbatim sentence, exactly as spoken or typed, never edited.
2. **Entry** — a structured transaction, pointing back to the exact words it came from (`sourceSpan`). Insert-only: `supersededBy` and `voidedBy` are the *only* two columns ever written after an entry's initial insert (`flutter/daftari/lib/data/database.dart`).
3. **Reports** — a projection over live (non-superseded, non-voided) entries, never a re-computation from scratch.

## Localization tooling note

This repository's `lib/l10n/app_localizations*.dart` files were generated by a Python script (`scripts/gen_l10n_dart.py`, referenced from the Flutter README) rather than by `flutter gen-l10n`, because the sandbox this project was built in has no access to the Flutter SDK or pub.dev. The script reads the same `.arb` files `flutter gen-l10n` would and produces an equivalent, hand-verified `L` class (matching `l10n.yaml`'s `output-class: L`). Every localization key used anywhere in `lib/features/` has been cross-referenced by script against every key the generator produced — see the Flutter README's Localization section for how to regenerate this properly with the real tool.
