#!/usr/bin/env python3
"""Generates the Geiger-counter ping and celebration chime.

Pure stdlib (wave + math) so the assets can be regenerated anywhere:

    python3 tool/generate_audio.py

Outputs 44.1 kHz, 16-bit mono WAV files into assets/audio/.
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SR = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def write_wav(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.88 / peak if peak > 0.88 else 1.0
    frames = bytearray()
    for value in samples:
        clamped = max(-1.0, min(1.0, value * scale))
        frames += struct.pack("<h", int(clamped * 32767))
    path = OUT / name
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes(bytes(frames))
    print(f"wrote {path.relative_to(OUT.parent.parent)} ({path.stat().st_size / 1024:.1f} kB)")


def fade_tail(samples: list[float], milliseconds: float = 8.0) -> None:
    count = min(len(samples), int(SR * milliseconds / 1000))
    for i in range(count):
        samples[len(samples) - 1 - i] *= i / count


def ping(frequency: float, seconds: float, decay: float, brightness: float) -> list[float]:
    """Short, bright ping with an exponential envelope."""
    total = int(SR * seconds)
    out: list[float] = []
    for i in range(total):
        t = i / SR
        attack = 1.0 - math.exp(-t / 0.0016)
        envelope = attack * math.exp(-decay * t)
        tone = (
            math.sin(2 * math.pi * frequency * t)
            + brightness * math.sin(2 * math.pi * frequency * 2.01 * t)
            + brightness * 0.45 * math.sin(2 * math.pi * frequency * 3.03 * t)
        )
        # A tiny click transient makes the tick feel tactile, like a Geiger tube.
        click = 0.18 * math.exp(-t * 900) * math.sin(2 * math.pi * 5200 * t)
        out.append(0.5 * envelope * tone + click)
    fade_tail(out)
    return out


def success() -> list[float]:
    """Ascending C-major bell arpeggio for the 'device found' moment."""
    total = int(SR * 1.1)
    out = [0.0] * total
    notes = [(1046.50, 0.00), (1318.51, 0.085), (1567.98, 0.17), (2093.00, 0.27)]
    for frequency, start in notes:
        length = int(SR * 0.65)
        start_index = int(SR * start)
        for i in range(length):
            if start_index + i >= total:
                break
            t = i / SR
            envelope = (1.0 - math.exp(-t / 0.004)) * math.exp(-5.2 * t)
            tone = (
                math.sin(2 * math.pi * frequency * t)
                + 0.32 * math.sin(2 * math.pi * frequency * 2.0 * t)
                + 0.12 * math.sin(2 * math.pi * frequency * 3.0 * t)
            )
            out[start_index + i] += 0.26 * envelope * tone
    fade_tail(out, 140)
    return out


def main() -> None:
    write_wav("ping.wav", ping(1175.0, 0.20, 26.0, 0.30))
    write_wav("ping_warm.wav", ping(1480.0, 0.15, 32.0, 0.34))
    write_wav("ping_hot.wav", ping(1850.0, 0.12, 38.0, 0.40))
    write_wav("success.wav", success())


if __name__ == "__main__":
    main()
