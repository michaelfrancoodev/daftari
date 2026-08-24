# Hackathon Readiness — Gap Analysis Against the Official Rules

This document checks DAFTARI against the **exact** judging rubric published on the Contest's Rules page (fetched directly from `https://allthingsagentichackathon.devpost.com/rules`), not a paraphrase of it. Where DAFTARI falls short, that is stated plainly — this document exists to be acted on, not to reassure.

## Mandatory requirements (Stage One — pass/fail)

| Requirement | Status | Evidence |
|---|---|---|
| Gemini 3.5 or newer, via Gemini API or Vertex AI | ✅ Met | `gemini-3.5-flash` used in `agents/sikio`, `agents/mkumbushi`, `agents/mlinganishi` — confirmed as a real, current, GA model as of this check |
| At least one Google Agent Framework (ADK / GenAI SDK / Antigravity / GenKit) | ✅ Met | Google ADK (`google.adk.agents.llm_agent.Agent`) in all three agents above |
| At least one Google Cloud infrastructure service | ✅ Met (in code; **not yet deployed** — see below) | Cloud Run (all four agent services), Firestore (question/entry storage) |
| Category selected | ✅ Met | Taskmaster |
| Project built during the Submission Period (Aug 3–31, 2026) | ✅ Met | All work in this repository was done within that window |
| README with spin-up instructions | ✅ Met | Root `README.md` + `flutter/daftari/README.md` + `docs/DEPLOYMENT.md` |
| Public code repository | ✅ Met | `https://github.com/michaelfrancoodev/daftari` |

## The one honest gap: nothing is actually deployed yet

Everything above is true **of the code**. It is not yet true of a **running system**. As of this document, no agent has been deployed to Cloud Run, and the website has not been deployed to Vercel. This matters because the rubric is explicit and specific about this:

> **Demo & Production Readiness (30%)** — "Is there visual proof of Google Cloud deployment in the video?" ... "Must demonstrate the backend is running on Google Cloud (i.e.: Google Cloud Console, Cloud Run dashboard, Vertex AI logs, URL of .run, etc)"

**This cannot be satisfied by code alone, and it cannot be done from this development environment** — it requires a real Google Cloud project with billing enabled (the $150 credit form linked in the Rules, section 5, covers this), which only the project owner can set up. `docs/DEPLOYMENT.md` has the exact `gcloud` commands already. **This is the single highest-priority remaining task before submission.**

## Stage Two — weighted judging criteria

### Innovation & Operational Utility — 40% (the largest single weight)

The Taskmaster-specific question the rubric asks: *"Does the agent successfully intercept and complete a multi-step background workflow without human intervention? Did the team successfully utilize the 'Bring Your Own Friction' (BYOF) mandate to solve a unique, personal problem?"*

- **Multi-step background workflow, unattended**: `agents/mkumbushi`'s `/evening-check` endpoint, woken by Cloud Scheduler with nobody asking, is the strongest evidence here — it runs deterministic gap detection, then calls Gemini to phrase a question, entirely without a human initiating the run. Make sure the demo video shows this specific flow (Cloud Scheduler job history → the resulting question appearing) since it is the most literal match to the rubric's own wording.
- **BYOF ("Bring Your Own Friction")**: the Master Specification frames this as a real, observed friction (small-scale gold miners' paper ledgers), not a synthetic problem invented for the hackathon. When writing the Devpost text description, state explicitly *why* this friction was chosen and any personal or first-hand connection to it — the rubric names BYOF specifically, so the submission's written description should name it back, not leave the judge to infer it.
- **Gap addressed in this pass**: none of the three ADK agents previously called any tool at all — each was a single prompt-in, JSON-out call, which reads as "an LLM wrapper" rather than "an agent." Fixed in this pass: `agents/mkumbushi` now has a real `get_counterparty_history` tool (checks for an existing partial repayment before phrasing a loan question), and `agents/sikio` now has `get_known_counterparties` (checks the user's own established names before guessing a misheard one). Both are genuine, callable functions the model decides whether to invoke — not decorative.

### Architectural Discipline & Tech Stack — 30%

The rubric's own sub-questions: *"How well did your team decouple systems, manage state, and design robust, failure-tolerant agentic systems? ... Are the tools properly isolated and scoped for security?"*

- **Decoupling**: four independent Cloud Run services (`agents/sikio`, `agents/daftari`, `agents/mkumbushi`, `agents/mlinganishi`), each with its own `Dockerfile` and `requirements.txt`, none depending on another being deployed. The Flutter app works fully offline with zero agents running at all.
- **State management**: `flutter/daftari/lib/data/database.dart` (device) and Firestore (cloud) — the insert-only rule (no UPDATE/DELETE except two lifecycle pointers) is enforced in the schema itself, not just convention.
- **Failure tolerance**: every agent's Gemini-calling code path (`main.py` in `sikio`/`mkumbushi`/`mlinganishi`) wraps the model call in a try/except that degrades to an honest "unresolved" result rather than crashing or fabricating an answer — consistent with Rule #1 (never invent a figure) applied at the infrastructure level, not just the ledger level.
- **Tool isolation/scoping**: each new tool function (`get_counterparty_history`, `get_known_counterparties`) is read-only, scoped to exactly the query it needs, and fails closed (returns an empty result, never raises past its own boundary) — see `agents/mkumbushi/agent.py` and `agents/sikio/agent.py`.
- **Deterministic where it matters**: `agents/daftari` has zero model calls by design, since money validation must never depend on a model's judgement (Master Specification, Section 9) — worth stating explicitly in the demo video, since a judge skimming code might otherwise assume every agent should call Gemini and read the absence as a gap rather than a deliberate choice.

### Demo & Production Readiness — 30%

- **Proof of Action** (unedited live execution via terminal logs, DB updates, or UI changes): achievable once deployed — record the video showing `curl` against a live Cloud Run URL, or the Flutter app's Inbox screen receiving a real Mkumbushi-phrased question, not a mocked one.
- **Documentation**: `docs/ARCHITECTURE.md` has the full system diagram and per-agent rationale; every README has real, tested spin-up instructions (see `docs/LIMITATIONS.md` for exactly what has and hasn't been run against real tooling — an honest limitations doc is itself evidence of engineering discipline a judge is likely to notice favorably, not a weakness to hide).
- **Visual proof of Google Cloud deployment in the video**: not possible until deployment happens — see the gap noted above.

## Stage Three — bonus points (up to 0.6 of a possible 6.0 final score)

| Bonus | Value | Status |
|---|---|---|
| Public blog/podcast/video about how it was built, stating it was made for this hackathon | +0.2 | Not done — straightforward to add; this document plus `docs/LIMITATIONS.md`'s bug list is genuinely interesting written-up material |
| Public social media post with `#AllThingsAgenticHackathon` | +0.2 | Not done |
| Each additional Google AI model integrated (Gemma, Veo, Lyria), up to 0.6 | +0.2 each | Not attempted — genuinely optional; forcing one in without a real use would read as padding, which is worse than not having it |

## Comparing against what other agentic hackathons reward

A broader look at judging criteria across similar 2026 agentic-AI hackathons (Agentic Engineering Hack, Agentic AI Innovation Challenge, AgentHacks) shows a consistent pattern: **innovation/real-world value, technical execution, autonomy, and demo clarity** are the four criteria that recur everywhere, in roughly that order of weight. DAFTARI's specific strengths against that pattern:

- **Real-world value**: a genuinely underserved user (small-scale miners with no digital tooling at all — the Master Specification notes the best existing alternative is a printed paper pocketbook) rather than a incremental improvement on an already-served market.
- **Autonomy**: the Cloud Scheduler-triggered Mkumbushi flow is a concrete, demoable instance of "the agent speaks first" — not just a chat interface with a system prompt.
- **A finding worth stating explicitly in any submission material**: this project chose to remove a feature (an external "gold price" agent) after concluding it would misrepresent what users actually experience, and documented that reasoning in `docs/LIMITATIONS.md`. Most hackathon submissions accumulate features under time pressure; visibly reasoning about removing one is a positive signal for the "Architectural Discipline" criterion specifically, since it demonstrates the team evaluated a tradeoff rather than defaulting to "more integrations."

Where DAFTARI is currently weaker than a typical strong submission in this space: **most winning agentic hackathon demos show a live, deployed system in the video** — sandboxed development without Cloud deployment access means this project's strongest evidence (a real Cloud Scheduler job firing, a real Cloud Run log) does not exist yet. This is not a code problem; it is the single deployment step described above.
