"""
RhythmAether AI Chart Generator
Generates RACF chart files from any audio input using music analysis.

Pipeline: Audio → Beat/Onset Detection → Pattern Generation → RACF JSON
"""

import json
import os
from dataclasses import dataclass, field
from typing import Optional

import librosa
import numpy as np


LANES = [0.125, 0.375, 0.625, 0.875]


@dataclass
class ChartConfig:
    difficulty: str = "Normal"  # Easy, Normal, Hard, Expert, Ethereal
    level: int = 5
    title: str = "Unknown"
    artist: str = "Unknown"
    charter: str = "AI Generator"
    audio_file: str = ""


@dataclass
class AudioAnalysis:
    """Results of analyzing an audio file."""
    duration: float = 0.0
    bpm: float = 120.0
    offset: float = 0.0  # Time of first beat in seconds
    beat_times: list = field(default_factory=list)
    onset_times: list = field(default_factory=list)
    onset_strengths: list = field(default_factory=list)
    # Per-beat data
    beat_has_kick: list = field(default_factory=list)
    beat_has_snare: list = field(default_factory=list)
    beat_has_hat: list = field(default_factory=list)
    beat_onset_strength: list = field(default_factory=list)
    # Section energy (per 16-beat block)
    section_energies: list = field(default_factory=list)


def analyze_audio(audio_path: str) -> AudioAnalysis:
    """Analyze audio file to extract rhythm information."""
    y, sr = librosa.load(audio_path, sr=44100, mono=True)
    analysis = AudioAnalysis()
    analysis.duration = len(y) / sr

    # Tempo and beats
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr)
    tempo_val = float(tempo) if np.ndim(tempo) == 0 else float(tempo[0])

    # Round BPM to nearest integer
    analysis.bpm = round(tempo_val)
    beat_dur = 60.0 / analysis.bpm

    # Find optimal offset by aligning to percussion hits
    y_h, y_p = librosa.effects.hpss(y)
    perc_frames = librosa.onset.onset_detect(y=y_p, sr=sr, units='frames')
    perc_times = librosa.frames_to_time(perc_frames, sr=sr)

    onset_env = librosa.onset.onset_strength(y=y, sr=sr)

    # Search for best offset
    first_beat = float(beat_times[0]) if len(beat_times) > 0 else 0.0
    best_offset = first_beat
    best_score = 0
    for test_i in range(60):
        test_off = max(0, first_beat - 0.3) + test_i * 0.01
        score = 0
        for b in range(min(64, int((analysis.duration - test_off) / beat_dur))):
            t = test_off + b * beat_dur
            diffs = np.abs(perc_times - t)
            if len(diffs) > 0 and float(np.min(diffs)) < 0.03:
                score += 1
        if score > best_score:
            best_score = score
            best_offset = test_off

    analysis.offset = best_offset
    total_beats = int((analysis.duration - analysis.offset) / beat_dur)

    # Frequency band analysis
    S = np.abs(librosa.stft(y))
    freqs = librosa.fft_frequencies(sr=sr)
    low_mask = (freqs >= 20) & (freqs <= 150)
    mid_mask = (freqs > 150) & (freqs <= 2000)
    high_mask = (freqs > 2000) & (freqs <= 10000)

    low_energy = S[low_mask].mean(axis=0)
    mid_energy = S[mid_mask].mean(axis=0)
    high_energy = S[high_mask].mean(axis=0)

    low_median = float(np.median(low_energy))
    mid_median = float(np.median(mid_energy))
    high_median = float(np.median(high_energy))

    # Per-beat analysis
    for b in range(total_beats):
        t = analysis.offset + b * beat_dur
        frame = librosa.time_to_frames(t, sr=sr)
        analysis.beat_times.append(t)

        if frame < len(onset_env):
            analysis.beat_onset_strength.append(float(onset_env[frame]))
        else:
            analysis.beat_onset_strength.append(0.0)

        if frame < len(low_energy):
            analysis.beat_has_kick.append(float(low_energy[frame]) > low_median * 1.2)
        else:
            analysis.beat_has_kick.append(False)

        if frame < len(mid_energy):
            analysis.beat_has_snare.append(float(mid_energy[frame]) > mid_median * 1.1)
        else:
            analysis.beat_has_snare.append(False)

        if frame < len(high_energy):
            analysis.beat_has_hat.append(float(high_energy[frame]) > high_median * 1.0)
        else:
            analysis.beat_has_hat.append(False)

    # Section energies (per 16-beat block)
    for start in range(0, total_beats, 16):
        end = min(start + 16, total_beats)
        avg_onset = np.mean(analysis.beat_onset_strength[start:end]) if end > start else 0
        kick_ratio = sum(analysis.beat_has_kick[start:end]) / max(end - start, 1)
        analysis.section_energies.append({
            "start_beat": start,
            "end_beat": end,
            "avg_onset": float(avg_onset),
            "kick_ratio": float(kick_ratio),
        })

    # Onset times for half-beat detection
    analysis.onset_times = [float(t) for t in perc_times]

    return analysis


# --- Difficulty presets ---
DIFFICULTY_PRESETS = {
    "Easy": {"density": 0.3, "max_simultaneous": 1, "use_holds": False, "use_16th": False, "half_beat_ratio": 0.1},
    "Normal": {"density": 0.55, "max_simultaneous": 2, "use_holds": True, "use_16th": False, "half_beat_ratio": 0.3},
    "Hard": {"density": 0.75, "max_simultaneous": 2, "use_holds": True, "use_16th": True, "half_beat_ratio": 0.5},
    "Expert": {"density": 0.9, "max_simultaneous": 3, "use_holds": True, "use_16th": True, "half_beat_ratio": 0.7},
    "Ethereal": {"density": 1.0, "max_simultaneous": 4, "use_holds": True, "use_16th": True, "half_beat_ratio": 0.85},
}


def generate_chart(analysis: AudioAnalysis, config: ChartConfig) -> dict:
    """Generate a RACF chart from audio analysis."""
    preset = DIFFICULTY_PRESETS.get(config.difficulty, DIFFICULTY_PRESETS["Normal"])
    beat_dur = 60.0 / analysis.bpm
    total_beats = len(analysis.beat_times)
    notes = []
    rng = np.random.RandomState(42)  # Deterministic for same input

    # Compute per-section density multiplier based on energy
    section_density = []
    if analysis.section_energies:
        max_onset = max(s["avg_onset"] for s in analysis.section_energies)
        min_onset = min(s["avg_onset"] for s in analysis.section_energies)
        onset_range = max(max_onset - min_onset, 0.01)
        for s in analysis.section_energies:
            normalized = (s["avg_onset"] - min_onset) / onset_range
            section_density.append(0.3 + normalized * 0.7)  # 0.3 to 1.0
    else:
        section_density = [0.7]

    def get_section_density(beat):
        idx = beat // 16
        if idx < len(section_density):
            return section_density[idx]
        return 0.5

    # Track last used lanes to create varied patterns
    last_lane = 1
    pattern_counter = 0

    def pick_lane(avoid=None):
        nonlocal last_lane
        choices = list(range(4))
        if avoid is not None:
            choices = [c for c in choices if c != avoid]
        # Prefer adjacent lanes for smooth movement
        weights = [1.0] * len(choices)
        for i, c in enumerate(choices):
            if abs(c - last_lane) <= 1:
                weights[i] = 2.0
        weights = np.array(weights) / sum(weights)
        lane = rng.choice(choices, p=weights)
        last_lane = lane
        return lane

    def add_tap(beat, lane):
        notes.append({"type": "tap", "beat": float(beat), "x": LANES[lane]})

    def add_hold(beat, end_beat, lane):
        notes.append({"type": "hold", "beat": float(beat), "endBeat": float(end_beat), "x": LANES[lane]})

    # --- Pattern generators ---
    def pattern_single(beat):
        add_tap(beat, pick_lane())

    def pattern_double(beat):
        l1 = rng.choice([0, 1])
        l2 = l1 + 2
        add_tap(beat, l1)
        add_tap(beat, l2)

    def pattern_alternating_8th(beat):
        l = pick_lane()
        add_tap(beat, l)
        add_tap(beat + 0.5, pick_lane(avoid=l))

    def pattern_sweep_right(beat):
        add_tap(beat, 0)
        add_tap(beat + 0.5, 1)
        add_tap(beat + 1.0, 2)
        add_tap(beat + 1.5, 3)

    def pattern_sweep_left(beat):
        add_tap(beat, 3)
        add_tap(beat + 0.5, 2)
        add_tap(beat + 1.0, 1)
        add_tap(beat + 1.5, 0)

    def pattern_hold_with_tap(beat):
        hold_lane = rng.choice([0, 3])
        tap_lane = 1 if hold_lane == 0 else 2
        add_hold(beat, beat + 2, hold_lane)
        add_tap(beat + 1, tap_lane)

    def pattern_burst_16th(beat):
        lanes_seq = [1, 2, 1, 2]
        for i in range(4):
            add_tap(beat + i * 0.25, lanes_seq[i])

    def pattern_quad(beat):
        for l in range(4):
            add_tap(beat, l)

    # --- Main generation loop ---
    beat = 0
    while beat < total_beats:
        sec_density = get_section_density(beat)
        effective_density = preset["density"] * sec_density

        # Skip some beats based on density
        if rng.random() > effective_density and beat > 4:
            beat += 1
            continue

        onset_str = analysis.beat_onset_strength[beat] if beat < len(analysis.beat_onset_strength) else 0.5
        has_kick = analysis.beat_has_kick[beat] if beat < len(analysis.beat_has_kick) else False
        has_snare = analysis.beat_has_snare[beat] if beat < len(analysis.beat_has_snare) else False
        bar_pos = beat % 4

        # Choose pattern based on context
        if beat < 8:
            # Intro: sparse single taps
            pattern_single(beat)
            beat += 2 if beat < 4 else 1

        elif bar_pos == 0 and onset_str > 0.7 and sec_density > 0.7:
            # Strong downbeat in energetic section
            if rng.random() < 0.3 and preset["max_simultaneous"] >= 4:
                pattern_quad(beat)
                beat += 1
            else:
                pattern_double(beat)
                beat += 1

        elif sec_density > 0.8 and preset["use_16th"] and rng.random() < 0.2:
            # High energy: 16th note burst
            pattern_burst_16th(beat)
            beat += 1

        elif sec_density > 0.6 and rng.random() < 0.15 and preset["use_holds"] and beat + 3 < total_beats:
            # Hold note with tap
            pattern_hold_with_tap(beat)
            beat += 3

        elif rng.random() < 0.2 and beat + 3 < total_beats and sec_density > 0.5:
            # Sweep pattern
            if rng.random() < 0.5:
                pattern_sweep_right(beat)
            else:
                pattern_sweep_left(beat)
            beat += 2

        elif rng.random() < preset["half_beat_ratio"]:
            # 8th note alternating
            pattern_alternating_8th(beat)
            beat += 1

        elif has_kick and bar_pos in [0, 2]:
            # Kick hit
            pattern_single(beat)
            beat += 1

        elif has_snare:
            # Snare hit
            if rng.random() < 0.3 and preset["max_simultaneous"] >= 2:
                pattern_double(beat)
            else:
                pattern_single(beat)
            beat += 1

        else:
            pattern_single(beat)
            beat += 1

    # Sort notes by beat
    notes.sort(key=lambda n: n["beat"])

    # Build RACF
    chart = {
        "version": "1.0.0",
        "metadata": {
            "title": config.title,
            "artist": config.artist,
            "charter": config.charter,
            "audioFile": config.audio_file,
            "difficulty": {
                "label": config.difficulty,
                "level": config.level,
            }
        },
        "timing": [{
            "beat": 0,
            "bpm": analysis.bpm,
            "timeSignature": {"numerator": 4, "denominator": 4}
        }],
        "offset": round(analysis.offset, 4),
        "notes": notes,
        "events": []
    }

    return chart


def generate_chart_from_audio(
    audio_path: str,
    output_path: Optional[str] = None,
    title: str = "Unknown",
    artist: str = "Unknown",
    difficulty: str = "Normal",
    level: int = 5,
) -> dict:
    """
    Full pipeline: audio file → RACF chart JSON.

    Args:
        audio_path: Path to audio file (mp3, ogg, wav, etc.)
        output_path: Where to save the RACF JSON (optional)
        title: Song title
        artist: Song artist
        difficulty: Easy/Normal/Hard/Expert/Ethereal
        level: Numeric difficulty level (1-15)

    Returns:
        RACF chart dictionary
    """
    print(f"Analyzing audio: {audio_path}")
    analysis = analyze_audio(audio_path)
    print(f"  BPM: {analysis.bpm}, Duration: {analysis.duration:.1f}s, Offset: {analysis.offset:.3f}s")
    print(f"  Total beats: {len(analysis.beat_times)}, Sections: {len(analysis.section_energies)}")

    # Determine audio file relative path for RACF
    audio_filename = os.path.basename(audio_path)

    config = ChartConfig(
        difficulty=difficulty,
        level=level,
        title=title,
        artist=artist,
        audio_file=audio_filename,
    )

    print(f"Generating {difficulty} Lv.{level} chart...")
    chart = generate_chart(analysis, config)
    print(f"  Generated {len(chart['notes'])} notes")

    if output_path:
        with open(output_path, 'w') as f:
            json.dump(chart, f, indent=2)
        print(f"  Saved to: {output_path}")

    return chart


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python chart_generator.py <audio_file> [output.json] [difficulty] [level]")
        sys.exit(1)

    audio = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) > 2 else audio.rsplit('.', 1)[0] + '_chart.json'
    diff = sys.argv[3] if len(sys.argv) > 3 else "Normal"
    lvl = int(sys.argv[4]) if len(sys.argv) > 4 else 5

    # Try to extract title from filename
    name = os.path.splitext(os.path.basename(audio))[0].replace('_', ' ').title()

    generate_chart_from_audio(audio, output, title=name, difficulty=diff, level=lvl)
