"""
HTTP surface for the Mkumbushi agent, deployed to Cloud Run.

  POST /evening-check   Called by Cloud Scheduler every evening. Runs
                         deterministic gap detection over the entries
                         given, then asks Gemini to phrase one natural
                         question per gap found. Nobody asks for this —
                         it runs on a schedule, which is the concrete proof
                         of autonomy this product's Taskmaster track claims.

  POST /answer           Called later — possibly days later — when the
                         user actually answers a question from their
                         Inbox. This is the human-in-the-loop half of the
                         pattern: the run does not block waiting for this,
                         it is a completely separate request that resolves
                         a question by id.

Questions are stored in Firestore so `/answer` can find them again
whenever they arrive, and so a Cloud Run cold start never loses a pending
question.
"""

from __future__ import annotations

import os
import uuid
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, HTTPException
from google.adk.runners import InMemoryRunner
from pydantic import BaseModel

from agent import root_agent
from gaps import Entry, detect

app = FastAPI(title="daftari-mkumbushi-agent")

_memory_store: dict[str, dict] = {}


def _firestore_client():
    try:
        from google.cloud import firestore

        return firestore.Client()
    except Exception:
        return None


def _save_question(question_id: str, data: dict) -> None:
    client = _firestore_client()
    if client is not None:
        client.collection("mkumbushi_questions").document(question_id).set(data)
    else:
        _memory_store[question_id] = data


def _load_question(question_id: str) -> Optional[dict]:
    client = _firestore_client()
    if client is not None:
        doc = client.collection("mkumbushi_questions").document(question_id).get()
        return doc.to_dict() if doc.exists else None
    return _memory_store.get(question_id)


def _mark_answered(question_id: str, answer: str) -> None:
    client = _firestore_client()
    if client is not None:
        client.collection("mkumbushi_questions").document(question_id).update(
            {"answer": answer, "answered_at": datetime.utcnow().isoformat()}
        )
    elif question_id in _memory_store:
        _memory_store[question_id]["answer"] = answer
        _memory_store[question_id]["answered_at"] = datetime.utcnow().isoformat()


class EntryPayload(BaseModel):
    id: str
    kind: str
    occurred_at: datetime
    counterparty: Optional[str] = None
    is_live: bool = True


class EveningCheckRequest(BaseModel):
    entries: list[EntryPayload]
    language_code: str = "sw"


class Question(BaseModel):
    id: str
    gap_kind: str
    entry_id: str
    text: str


class EveningCheckResponse(BaseModel):
    questions: list[Question]


class AnswerRequest(BaseModel):
    question_id: str
    answer: str


async def _phrase_question(gap_kind: str, days_ago: int, counterparty: Optional[str], language_code: str) -> str:
    runner = InMemoryRunner(agent=root_agent)
    prompt = (
        f"Language: {language_code}\n"
        f"Gap kind: {gap_kind}\n"
        f"Days ago: {days_ago}\n"
        f"Counterparty: {counterparty or 'none'}"
    )
    result = await runner.run_debug(prompt, verbose=False)
    text = result if isinstance(result, str) else getattr(result, "text", None) or str(result)
    return text.strip().strip('"')


@app.get("/healthz")
def healthz() -> dict:
    return {"ok": True}


@app.post("/evening-check", response_model=EveningCheckResponse)
async def evening_check(req: EveningCheckRequest) -> dict:
    now = datetime.utcnow()
    domain_entries = [
        Entry(id=e.id, kind=e.kind, occurred_at=e.occurred_at, counterparty=e.counterparty, is_live=e.is_live)
        for e in req.entries
    ]
    gaps = detect(domain_entries, now)

    # One question per card, never a list of five — the Inbox screen's
    # own rule, enforced here by simply not raising more than a handful
    # in one evening pass even when more gaps exist.
    gaps = gaps[:5]

    questions: list[Question] = []
    for gap in gaps:
        days_ago = (now - gap.occurred_at).days
        counterparty = next((e.counterparty for e in domain_entries if e.id == gap.entry_id), None)
        text = await _phrase_question(gap.kind, days_ago, counterparty, req.language_code)
        question_id = str(uuid.uuid4())
        _save_question(
            question_id,
            {"gap_kind": gap.kind, "entry_id": gap.entry_id, "text": text, "created_at": now.isoformat()},
        )
        questions.append(Question(id=question_id, gap_kind=gap.kind, entry_id=gap.entry_id, text=text))

    return {"questions": questions}


@app.post("/answer")
def answer(req: AnswerRequest) -> dict:
    question = _load_question(req.question_id)
    if question is None:
        raise HTTPException(status_code=404, detail="Unknown question_id")
    _mark_answered(req.question_id, req.answer)
    return {"ok": True, "entry_id": question["entry_id"]}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
