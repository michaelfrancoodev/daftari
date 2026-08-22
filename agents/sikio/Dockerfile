# The Sikio agent: server-side refinement of the on-device Interpreter's
# uncertain fields. See DEPLOYMENT.md for the `gcloud run deploy` command
# and required environment variables (GOOGLE_API_KEY or Vertex AI project).

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["python", "main.py"]
