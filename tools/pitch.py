#!/usr/bin/env python3
"""Pitch summary of voice clips, for matching takes: duration, mean F0, and F0 at the start vs the end.

  uv run --no-project --with numpy python tools/pitch.py Callout/Sounds/thirty.wav sounds-src/*.wav
"""
import sys, wave
import numpy as np

def f0_track(path):
    w = wave.open(path); sr = w.getframerate(); ch = w.getnchannels()
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)
    x = x.reshape(-1, ch).mean(axis=1) / 32768
    frame, hop = int(sr * 0.04), int(sr * 0.01)
    gate = 10 ** (-30 / 20) * np.abs(x).max()
    out = []
    for i in range(0, len(x) - frame, hop):
        seg = x[i:i + frame] - x[i:i + frame].mean()
        if np.sqrt((seg ** 2).mean()) < gate:
            continue
        ac = np.correlate(seg, seg, "full")[frame - 1:]
        lo, hi = int(sr / 300), int(sr / 70)
        lag = lo + int(np.argmax(ac[lo:hi]))
        if ac[lag] > 0.5 * ac[0]:
            out.append((i / sr, sr / lag))
    return len(x) / sr, out

for p in sys.argv[1:]:
    dur, track = f0_track(p)
    f = np.array([v for _, v in track])
    if len(f) < 4:
        print(f"{p}: too few voiced frames"); continue
    q = max(1, len(f) // 4)
    print(f"{p}: {dur:.2f}s  voiced {len(f) * 0.01:.2f}s  mean F0 {f.mean():.0f} Hz  start {f[:q].mean():.0f} -> end {f[-q:].mean():.0f} Hz")
