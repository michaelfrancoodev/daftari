# The Daftari agent: deterministic validation, deduplication, and batch
# arithmetic — no model in the loop. See DEPLOYMENT.md for the
# `gcloud run deploy` command.

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["python", "main.py"]
