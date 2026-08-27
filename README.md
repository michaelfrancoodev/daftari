# DAFTARI — The Ledger That Cannot Be Lost

**Speak what happened. It works with no network. Nothing is ever lost.**

DAFTARI is an offline-first ledger for anyone whose work doesn't happen at a desk — a small-scale miner, a trader, a shopkeeper, anyone running a business where the day is unpredictable and a notebook is the only record. Press one button, speak freely — one sentence or a whole day's transactions in one breath — and DAFTARI splits that sentence into separate entries, shows exactly what it understood, and asks only about the parts it couldn't read with confidence.

Built for the **[All Things Agentic Hackathon](https://allthingsagentichackathon.devpost.com/)** — Track: **Taskmaster**.

---

## What's in this repository

| Path | What it is | Deploys to |
|---|---|---|
| `flutter/daftari/` | The Android + Web app — the source of truth | Android device, and a static web build |
| `app/`, `components/`, `lib/` (repo root) | The marketing website (Next.js) | Vercel |
| `agents/sikio/` | Refines an uncertain field from the on-device interpreter | Cloud Run |
| `agents/daftari/` | Deterministic validation, deduplication, batch arithmetic | Cloud Run |
| `agents/mkumbushi/` | Evening gap detection + one Gemini-phrased question | Cloud Run |
| `agents/mlinganishi/` | Reconciles two linked parties' records | Cloud Run |
| `docs/` | Architecture, limitations, and deployment guides | — |

Four independent Cloud Run services, one Vercel website, one Flutter app — none required for any of the others to work. The app is fully usable offline with zero agents deployed.

See [`docs/HACKATHON_READINESS.md`](docs/HACKATHON_READINESS.md) for how this project maps to the hackathon's judging rubric.

---

## Quick start

### Website (Next.js → Vercel)
```bash
npm install
npm run dev
```

### App (Flutter)
```bash
cd flutter/daftari
flutter pub get
dart run flutter_launcher_icons
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```
See [`flutter/daftari/README.md`](flutter/daftari/README.md) for full details, including producing a signed release APK.

### Agents (Python → Cloud Run)
```bash
cd agents/daftari   # or sikio, mkumbushi, mlinganishi
pip install -r requirements.txt --break-system-packages
python main.py
```
Full deployment commands (Cloud Run, Cloud Scheduler, Firestore) are in [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

---

## Design principles

1. **Never invent a figure.** Something the app couldn't read with confidence is a question, never a guess.
2. **Everything needed in the moment works with no network.**
3. **A person's own words are never edited or deleted** — a correction adds a new entry, it never overwrites history.
4. **Every figure traces back to what produced it**, in one tap.
5. **Money is a whole number, never a decimal.**
6. **The app reports your own cost and profit — nothing external.** It doesn't fetch, publish, or compare against any outside market figure; the numbers it shows always come from what the person themselves recorded.
7. **One language on screen at a time.**
8. **Reports state their own gaps out loud**, with a completeness figure — a report that hides what it doesn't know isn't trustworthy.

## License

Apache-2.0 — see [`LICENSE`](LICENSE).
