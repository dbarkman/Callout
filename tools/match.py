#!/usr/bin/env python3
"""Rank voice takes by how closely they match a reference clip's delivery.

Compares, after trimming silence: the pitch contour (semitones, sampled at 20 points across the
voiced span), the loudness envelope shape, the spectral brightness, and the overall length.
Lower score = closer.

  uv run --no-project --with numpy python tools/match.py REF.wav TAKE.wav [...]
"""
import sys, wave
import numpy as np

def load(path):
    w = wave.open(path); sr = w.getframerate(); ch = w.getnchannels()
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float).reshape(-1, ch).mean(axis=1) / 32768
    env = np.abs(x) > 0.01 * np.abs(x).max()
    idx = np.flatnonzero(env)
    return x[idx[0]:idx[-1] + 1], sr

def features(path):
    x, sr = load(path)
    frame, hop = int(sr * 0.04), int(sr * 0.01)
    gate = 10 ** (-30 / 20) * np.abs(x).max()
    f0, rms, cent = [], [], []
    freqs = np.fft.rfftfreq(frame, 1 / sr)
    for i in range(0, len(x) - frame, hop):
        seg = x[i:i + frame] - x[i:i + frame].mean()
        r = np.sqrt((seg ** 2).mean()); rms.append(r)
        spec = np.abs(np.fft.rfft(seg * np.hanning(frame)))
        cent.append((freqs * spec).sum() / max(spec.sum(), 1e-9))
        if r < gate:
            continue
        ac = np.correlate(seg, seg, "full")[frame - 1:]
        lo, hi = int(sr / 250), int(sr / 60)  # deep male voice range
        lag = lo + int(np.argmax(ac[lo:hi]))
        if ac[lag] > 0.5 * ac[0]:
            f0.append(12 * np.log2(sr / lag / 100))
    def resample(v, n=20):
        v = np.asarray(v); return np.interp(np.linspace(0, len(v) - 1, n), np.arange(len(v)), v)
    rms = np.asarray(rms)
    return dict(dur=len(x) / sr, f0=resample(f0), env=resample(rms / rms.max()),
                cent=float(np.average(cent, weights=rms)))

ref = features(sys.argv[1])
rows = []
for p in sys.argv[2:]:
    f = features(p)
    pitch = float(np.sqrt(((f["f0"] - ref["f0"]) ** 2).mean()))          # semitones
    shape = float(np.sqrt(((f["env"] - ref["env"]) ** 2).mean())) * 10
    bright = abs(np.log2(f["cent"] / ref["cent"])) * 10
    length = abs(np.log2(f["dur"] / ref["dur"])) * 10
    rows.append((pitch + shape + bright + length, p, pitch, shape, bright, f["dur"],
                 f["f0"][:5].mean() - f["f0"][-5:].mean()))
print(f"ref {sys.argv[1]}: {ref['dur']:.2f}s, pitch fall start->end {ref['f0'][:5].mean() - ref['f0'][-5:].mean():.1f} st")
for s, p, pitch, shape, bright, dur, fall in sorted(rows):
    print(f"{s:5.2f}  {p}  pitch {pitch:.1f} st  env {shape:.2f}  bright {bright:.2f}  {dur:.2f}s  fall {fall:.1f} st")
