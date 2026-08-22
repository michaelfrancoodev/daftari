# Deployment

Two independent deployment targets: the website (Vercel) and four agent services (Cloud Run). Neither depends on the other being deployed.

## Website → Vercel

1. Push this repository to GitHub (or connect Vercel directly to your Git provider).
2. In the Vercel dashboard: **Add New Project** → import this repository → leave the root directory as the repository root (the Next.js app lives at the repo root, not in a subfolder).
3. Framework preset: **Next.js** (auto-detected).
4. Environment variables (optional):
   - `NEXT_PUBLIC_REPO_URL` — set to this repository's URL so the footer's "Code" link and the download page point at the right place.
5. Deploy. No other configuration, database, or secret is required — the site has no backend dependency of its own.

## Agents → Google Cloud Run

One-time setup:

```bash
gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com aiplatform.googleapis.com \
  cloudscheduler.googleapis.com firestore.googleapis.com

gcloud artifacts repositories create daftari \
  --repository-format=docker --location=us-central1

gcloud firestore databases create --location=us-central1
```

Authentication for Gemini: either set `GOOGLE_API_KEY` (a Gemini API key from Google AI Studio) as an environment variable on each service, or configure the service to use Vertex AI with a service account that has the `Vertex AI User` role — Google ADK supports both transparently.

### Deploying each agent

The same pattern applies to all four services (`sikio`, `daftari`, `mkumbushi`, `mlinganishi`):

```bash
cd agents/<name>

gcloud builds submit \
  --tag us-central1-docker.pkg.dev/$PROJECT_ID/daftari/<name>:latest .

gcloud run deploy daftari-<name> \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/daftari/<name>:latest \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --min-instances=0 \
  --max-instances=3 \
  --set-env-vars GOOGLE_API_KEY=$GEMINI_API_KEY
```

`agents/daftari` does not call Gemini at all — omit `GOOGLE_API_KEY` for that one if you prefer.

### Cloud Scheduler — waking Mkumbushi every evening

This is the concrete proof of autonomy the hackathon's Taskmaster track asks for: nobody calls this endpoint by hand.

```bash
gcloud scheduler jobs create http mkumbushi-evening-check \
  --location=us-central1 \
  --schedule="0 18 * * *" \
  --uri="$(gcloud run services describe daftari-mkumbushi --region=us-central1 --format='value(status.url)')/evening-check" \
  --http-method=POST \
  --headers="Content-Type=application/json" \
  --message-body='{"entries": [], "language_code": "sw"}'
```

In production, replace the empty `entries` body with a real payload assembled from Firestore-synced entries for each user — this example demonstrates the schedule is wired up end-to-end without requiring a populated database to prove it.

### Connecting the Flutter app to the deployed agents

None of this is required for the app to work — it is fully functional offline with zero agents deployed (Rule #2). Once agents are deployed, wire up a `lib/data/sync_service.dart` (not yet built — see `docs/LIMITATIONS.md`) pointing at each service's Cloud Run URL. `agents/sikio`'s `/resolve-field` and `agents/daftari`'s `/reconcile-batch` are the two endpoints an initial sync integration would call.

## Verifying a deployment

Every agent exposes `GET /healthz`:

```bash
curl "$(gcloud run services describe daftari-daftari --region=us-central1 --format='value(status.url)')/healthz"
# {"ok": true}
```

`agents/daftari`'s deterministic logic can be exercised end-to-end with no Gemini key at all:

```bash
curl -X POST "$SERVICE_URL/reconcile-batch" \
  -H "Content-Type: application/json" \
  -d '{"entries": [
        {"id": "1", "kind": "orePurchase", "occurred_at": "2026-08-12T09:00:00", "amount_minor_units": 500000, "device_id": "a"},
        {"id": "2", "kind": "goldYield", "occurred_at": "2026-08-12T14:00:00", "quantity": 4.2, "device_id": "a"}
      ]}'
```
