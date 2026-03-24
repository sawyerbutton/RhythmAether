"""
RhythmAether Backend API
Provides AI chart generation and music generation endpoints.
"""

import os
import shutil
import tempfile
import uuid

from fastapi import FastAPI, UploadFile, File, Query
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from app.services.chart_generator import generate_chart_from_audio

app = FastAPI(
    title="RhythmAether API",
    description="AI-powered chart and music generation for RhythmAether",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = os.environ.get("UPLOAD_DIR", "./uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/api/generate-chart")
async def generate_chart(
    audio: UploadFile = File(...),
    title: str = Query("Unknown"),
    artist: str = Query("Unknown"),
    difficulty: str = Query("Normal"),
    level: int = Query(5),
):
    """
    Upload an audio file and get back a RACF chart JSON.

    Supports: mp3, ogg, wav, flac, m4a
    """
    # Save uploaded file
    ext = os.path.splitext(audio.filename)[1] if audio.filename else ".mp3"
    file_id = str(uuid.uuid4())[:8]
    audio_path = os.path.join(UPLOAD_DIR, f"{file_id}{ext}")

    with open(audio_path, "wb") as f:
        shutil.copyfileobj(audio.file, f)

    try:
        chart = generate_chart_from_audio(
            audio_path=audio_path,
            title=title,
            artist=artist,
            difficulty=difficulty,
            level=level,
        )
        # Update audio file reference to use the uploaded filename
        chart["metadata"]["audioFile"] = audio.filename or f"{file_id}{ext}"
        return JSONResponse(content=chart)
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": str(e)},
        )
    finally:
        # Clean up
        if os.path.exists(audio_path):
            os.remove(audio_path)


@app.post("/api/generate-charts-multi")
async def generate_charts_multi(
    audio: UploadFile = File(...),
    title: str = Query("Unknown"),
    artist: str = Query("Unknown"),
):
    """
    Generate charts for all difficulty levels at once.
    Returns a dictionary of {difficulty: chart}.
    """
    ext = os.path.splitext(audio.filename)[1] if audio.filename else ".mp3"
    file_id = str(uuid.uuid4())[:8]
    audio_path = os.path.join(UPLOAD_DIR, f"{file_id}{ext}")

    with open(audio_path, "wb") as f:
        shutil.copyfileobj(audio.file, f)

    try:
        difficulties = [
            ("Easy", 3),
            ("Normal", 5),
            ("Hard", 8),
        ]
        results = {}
        for diff, lvl in difficulties:
            chart = generate_chart_from_audio(
                audio_path=audio_path,
                title=title,
                artist=artist,
                difficulty=diff,
                level=lvl,
            )
            chart["metadata"]["audioFile"] = audio.filename or f"{file_id}{ext}"
            results[diff] = chart

        return JSONResponse(content=results)
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": str(e)},
        )
    finally:
        if os.path.exists(audio_path):
            os.remove(audio_path)
