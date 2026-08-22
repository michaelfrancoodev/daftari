# The Mkumbushi agent: deterministic gap detection plus one
# Gemini-phrased question. See DEPLOYMENT.md for the Cloud Scheduler job
# that calls /evening-check every evening.

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["python", "main.py"]
