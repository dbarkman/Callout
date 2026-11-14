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

def trim_norm(mono, sr, peak_db=-1.0, gate_db=-40.0, keep_tail=True, fade_s=0.02):
    gate = 32768 * 10 ** (gate_db / 20)
    start = next(i for i, x in enumerate(mono) if abs(x) > gate)
    end = len(mono) - next(i for i, x in enumerate(reversed(mono)) if abs(x) > gate)
    start = max(0, start - int(sr * 0.005))  # 5 ms pre-roll keeps the attack
    end = min(len(mono), end + int(sr * 0.05)) if keep_tail else end
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

# Chime: a two-note digital chime (C6 then E6), each a sine with a soft third harmonic and a bell decay.
def note(freq, start, length=0.45):
    return [(start + i, 0.42 * 32768 * min(1, i / (sr * 0.003)) * math.exp(-i / (sr * 0.12))
             * (math.sin(2 * math.pi * freq * i / sr) + 0.2 * math.sin(2 * math.pi * 3 * freq * i / sr)))
            for i in range(int(sr * length))]
chime = [0.0] * int(sr * 0.6)
for i, v in note(1046.5, 0) + note(1318.5, int(sr * 0.13)):
    if i < len(chime):
        chime[i] += v
write(f"{DST}/chime.wav", chime, sr)
print("chime: 0.60s")
