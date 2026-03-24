"""
RhythmAether Music Generator
Uses Google Lyria RealTime to generate instrumental music based on style prompts.
"""

import asyncio
import os
import struct
import wave
from dataclasses import dataclass
from typing import Optional

from google import genai
from google.genai import types


# Dota 2 hero-inspired music profiles
HERO_PROFILES = {
    "invoker": {
        "name": "Invoker",
        "prompt": "epic orchestral, dramatic strings, brass fanfare, mystical arcane energy, powerful crescendo, heroic theme",
        "bpm": 130,
        "density": 0.7,
        "brightness": 0.6,
        "temperature": 1.1,
    },
    "phantom_assassin": {
        "name": "Phantom Assassin",
        "prompt": "dark electronic, aggressive synths, deep bass, stealthy atmosphere, sharp percussive hits, shadowy tension",
        "bpm": 140,
        "density": 0.8,
        "brightness": 0.3,
        "temperature": 1.0,
    },
    "crystal_maiden": {
        "name": "Crystal Maiden",
        "prompt": "ethereal ambient, crystalline bells, soft piano, ice textures, delicate arpeggios, frozen beauty, winter atmosphere",
        "bpm": 100,
        "density": 0.5,
        "brightness": 0.8,
        "temperature": 1.2,
    },
    "juggernaut": {
        "name": "Juggernaut",
        "prompt": "intense drum and bass, japanese taiko drums, fast electronic beat, warrior energy, katana slashes, relentless momentum",
        "bpm": 160,
        "density": 0.9,
        "brightness": 0.5,
        "temperature": 1.0,
    },
    "io": {
        "name": "Io",
        "prompt": "ambient glitch, abstract electronic, cosmic textures, pulsating energy, minimal techno, alien soundscape, ethereal pads",
        "bpm": 120,
        "density": 0.4,
        "brightness": 0.7,
        "temperature": 1.3,
    },
    "tidehunter": {
        "name": "Tidehunter",
        "prompt": "heavy dubstep, deep ocean bass, powerful sub frequencies, crushing waves, massive drops, primal force",
        "bpm": 140,
        "density": 0.8,
        "brightness": 0.2,
        "temperature": 1.0,
    },
}


@dataclass
class MusicGenConfig:
    hero_key: str = "invoker"
    duration_seconds: float = 60.0
    custom_prompt: Optional[str] = None


async def generate_music_async(
    api_key: str,
    config: MusicGenConfig,
    output_path: str,
) -> str:
    """
    Generate music using Lyria RealTime and save to WAV file.

    Args:
        api_key: Google Gemini API key
        config: Music generation configuration
        output_path: Where to save the WAV file

    Returns:
        Path to saved WAV file
    """
    client = genai.Client(api_key=api_key)

    # Get hero profile or use defaults
    profile = HERO_PROFILES.get(config.hero_key, HERO_PROFILES["invoker"])

    prompt_text = config.custom_prompt or profile["prompt"]
    bpm = profile["bpm"]
    density = profile["density"]
    brightness = profile["brightness"]
    temperature = profile["temperature"]

    print(f"Generating music for: {profile['name']}")
    print(f"  Prompt: {prompt_text}")
    print(f"  BPM: {bpm}, Duration: {config.duration_seconds}s")

    # Collect audio samples
    all_samples = bytearray()
    target_bytes = int(config.duration_seconds * 48000 * 2 * 2)  # 48kHz, 16-bit, stereo

    async with client.aio.live.music.connect(model='models/lyria-realtime-exp') as session:
        await session.set_weighted_prompts(
            prompts=[types.WeightedPrompt(text=prompt_text, weight=1.0)]
        )
        await session.set_music_generation_config(
            config=types.LiveMusicGenerationConfig(
                bpm=bpm,
                density=density,
                brightness=brightness,
                temperature=temperature,
            )
        )
        await session.play()

        async for chunk in session.receive():
            if chunk.data:
                all_samples.extend(chunk.data)
                progress = len(all_samples) / target_bytes * 100
                if int(progress) % 10 == 0:
                    print(f"  Progress: {progress:.0f}%", end='\r')
            if len(all_samples) >= target_bytes:
                break

        await session.stop()

    print(f"\n  Collected {len(all_samples)} bytes of audio")

    # Save as WAV (48kHz, 16-bit, stereo)
    with wave.open(output_path, 'wb') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(48000)
        wf.writeframes(bytes(all_samples[:target_bytes]))

    print(f"  Saved to: {output_path}")
    return output_path


def generate_music(
    api_key: str,
    hero_key: str = "invoker",
    duration: float = 60.0,
    output_path: str = "output.wav",
    custom_prompt: Optional[str] = None,
) -> str:
    """Synchronous wrapper for music generation."""
    config = MusicGenConfig(
        hero_key=hero_key,
        duration_seconds=duration,
        custom_prompt=custom_prompt,
    )
    return asyncio.run(generate_music_async(api_key, config, output_path))


def list_heroes() -> dict:
    """Return available hero profiles."""
    return {k: {"name": v["name"], "prompt": v["prompt"], "bpm": v["bpm"]}
            for k, v in HERO_PROFILES.items()}


if __name__ == "__main__":
    import sys
    api_key = os.environ.get("GEMINI_API_KEY", "")
    if len(sys.argv) > 1:
        api_key = sys.argv[1]

    hero = sys.argv[2] if len(sys.argv) > 2 else "invoker"
    duration = float(sys.argv[3]) if len(sys.argv) > 3 else 30.0
    output = sys.argv[4] if len(sys.argv) > 4 else f"{hero}_music.wav"

    if not api_key:
        print("Usage: python music_generator.py <api_key> [hero] [duration] [output]")
        print(f"Available heroes: {', '.join(HERO_PROFILES.keys())}")
        sys.exit(1)

    generate_music(api_key, hero, duration, output)
