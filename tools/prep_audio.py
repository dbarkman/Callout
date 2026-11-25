#!/usr/bin/env python3
"""Trim silence, normalize and copy cue audio into the app bundle folder; synthesize the tick beep.

  python3 tools/prep_audio.py
"""
import math, os, struct, wave

SRC, DST = "sounds-src", "Callout/Sounds"
os.makedirs(DST, exist_ok=True)

def read(path):
    w = wave.open(path); n, sr, ch = w.getnframes(), w.getframerate(), w.getnchannels()
    d = struct.unpack("<%dh" % (n * ch), w.readframes(n))
    return [sum(d[i:i + ch]) / ch for i in range(0, len(d), ch)], sr

def write(path, mono, sr):
    w = wave.open(path, "w"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
    w.writeframes(struct.pack("<%dh" % len(mono), *[max(-32767, min(32767, int(x))) for x in mono]))

def trim_norm(mono, sr, peak_db=-1.0, gate_db=-50.0, keep_tail=True, fade_s=0.05):
    # The gate is relative to the clip's peak, so a quiet take keeps its soft ending.
    gate = max(abs(x) for x in mono) * 10 ** (gate_db / 20)
    start = next(i for i, x in enumerate(mono) if abs(x) > gate)
    end = len(mono) - next(i for i, x in enumerate(reversed(mono)) if abs(x) > gate)
    start = max(0, start - int(sr * 0.005))  # 5 ms pre-roll keeps the attack
    end = min(len(mono), end + int(sr * 0.15)) if keep_tail else end
    seg = mono[start:end]
    gain = 32768 * 10 ** (peak_db / 20) / max(abs(x) for x in seg)
    fade = int(sr * fade_s)
    out = [x * gain for x in seg]
    for i in range(min(fade, len(out))):
        out[-1 - i] *= i / fade
    return out

for name in ["thirty", "fifteen", "ten", "five", "four", "three", "two", "one", "cheer1", "cheer2", "cheer3"]:
    mono, sr = read(f"{SRC}/{name}.wav")
    # Crowd takes fade out over a second instead of cutting off.
    out = trim_norm(mono, sr, fade_s=1.0) if name.startswith("cheer") else trim_norm(mono, sr)
    write(f"{DST}/{name}.wav", out, sr)
    print(f"{name}: {len(out) / sr:.2f}s")

# Tick: 70 ms 1.4 kHz beep with fast attack and exponential decay, about -6 dBFS.
sr = 44100
tick = [0.5 * 32768 * math.sin(2 * math.pi * 1400 * i / sr) * min(1, i / (sr * 0.002)) * math.exp(-i / (sr * 0.02))
        for i in range(int(sr * 0.07))]
write(f"{DST}/tick.wav", tick, sr)
print("tick: 0.07s")

# Chime: a single digital ding (E6), a sine with a soft octave and a bell decay.
chime = [0.5 * 32768 * min(1, i / (sr * 0.003)) * math.exp(-i / (sr * 0.16))
         * (math.sin(2 * math.pi * 1318.5 * i / sr) + 0.15 * math.sin(2 * math.pi * 2637 * i / sr))
         for i in range(int(sr * 0.7))]
write(f"{DST}/chime.wav", chime, sr)
print("chime: 0.70s")
