# DAFTARI — The Miner's Ledger

**A ledger that cannot be lost, built for a working day that is never orderly.**

DAFTARI is a Flutter app for small-scale gold miners and traders in Tanzania who currently keep their entire business in a paper exercise book. A user presses one button, speaks freely — one sentence or a whole day's transactions in one breath — and DAFTARI splits that sentence into separate entries, shows exactly what it understood, and asks only about the parts it couldn't read with confidence. Everything above works with the aeroplane-mode switch on. That is not a feature; it is the premise.

Built for the **[All Things Agentic Hackathon](https://allthingsagentichackathon.devpost.com/)** — Track: **The Taskmaster**.

> **A note on gold price.** DAFTARI deliberately does not fetch, cache, publish, or compare against any external "gold price," anywhere in this product — on the app, on this website, or in any agent. Gold varies by purity, grade, and buyer, so a single published figure would misrepresent what any individual miner actually receives. What DAFTARI shows instead is arithmetic entirely within the user's own control: what a batch cost to produce, and what a buyer is offering for it right now. See [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) for the full reasoning.

---

## What's in this repository

| Path | What it is | Deploys to |
|---|---|---|
| `flutter/daftari/` | The Android + Web app — the source of truth | Google Play / Android device, and a static web build |
| `app/`, `components/`, `lib/` (repo root) | The marketing/landing website (Next.js) | **Vercel** |
| `agents/sikio/` | Refines an uncertain field from the on-device interpreter | Cloud Run |
| `agents/daftari/` | Deterministic validation, deduplication, batch arithmetic | Cloud Run |
| `agents/mkumbushi/` | Evening gap detection + one Gemini-phrased question | Cloud Run |
| `agents/mlinganishi/` | Reconciles two linked parties' records | Cloud Run |
| `docs/` | Architecture, limitations, and deployment documentation | — |

Four independent Cloud Run services, one Vercel-deployed website, one Flutter app. Nothing in this list requires any of the others to be running — the app works fully offline with zero agents deployed at all (Rule #2).

---

## Quick start

### The website (Next.js, deploys to Vercel)

```bash
npm install
npm run dev        # http://localhost:3000
```

To deploy: connect this repository to a new Vercel project and deploy the repository root. No environment variables are required for the default build; set `NEXT_PUBLIC_REPO_URL` to this repo's URL if you want the footer's "Code" link to point somewhere specific.

### The app (Flutter)

```bash
cd flutter/daftari
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates database.g.dart
flutter run
```

> **Honesty note on this repository's provenance:** this codebase was developed and hand-verified in a sandboxed environment with no access to the Flutter SDK or pub.dev. Every Dart file was written and statically checked (import resolution, brace balance, and a full cross-reference of every localization key used against every key defined) by script, but **has not been run through `flutter analyze` or `flutter test` on a real Flutter toolchain.** Do that first, before treating this as final. `dart run build_runner build` is required once, to generate `lib/l10n/app_localizations*.dart`'s real counterpart if you run `flutter gen-l10n`, and `lib/data/database.g.dart` — see [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) for the complete list of what has and hasn't been verified on real tooling, and why.

Run the tests (101 test cases across 7 files, covering the domain logic that actually matters — `Money`, `Numerals`, `Interpreter`, `Ledger`, `GapDetector`, `Entry`, and shared widgets):

```bash
flutter test
```

### The agents (Python, deploy to Cloud Run)

Each agent in `agents/` is an independent service. To run one locally:

```bash
cd agents/daftari      # or sikio, mkumbushi, mlinganishi
pip install -r requirements.txt --break-system-packages
python main.py          # http://localhost:8080
```

`agents/daftari`, `agents/mkumbushi`, and `agents/mlinganishi` each ship a `test_*.py` file runnable with `pytest` and require no external credentials to test their deterministic logic. `agents/sikio`, `agents/mkumbushi`, and `agents/mlinganishi` additionally call Gemini (via Google ADK) for the specific sub-task a model is actually a good fit for — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for what each one does and why it's split that way.

Full deployment instructions (Cloud Run, Cloud Scheduler, Firestore, secrets) are in [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

---

## The Ten Rules

From the project's Master Specification — every one of these is enforced in code, not just written down:

1. **Never invent a figure.** A value that could not be read is a question, never a plausible guess.
2. **Everything needed at the moment of a decision works with no network.**
3. **The user's own words are never edited or deleted**, including the parts not understood.
4. **Every figure traces back to the sentence that produced it**, in one tap.
5. **Nothing is updated in place and nothing is deleted.** A correction writes a new row; a removal writes a marker. (Verified in `flutter/daftari/lib/data/database.dart`: the only two columns ever written after insert are the two lifecycle pointers.)
6. **Money is stored as whole integer units, never a decimal type.**
7. **A price... is not a concept this product uses at all** — see the note at the top of this file. (This rule has been superseded by a stronger one: DAFTARI compares only numbers the user directly controls.)
8. **The application never advises whether to sell.** It reports the user's own cost and profit arithmetic only.
9. **Reports count their own gaps out loud** and show a completeness percentage.
10. **One language at a time.** A Swahili user never sees an English word, and the reverse.

---

## License

Apache-2.0 — see [`LICENSE`](LICENSE).
