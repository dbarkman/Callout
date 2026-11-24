#!/usr/bin/env python3
"""Cut the first word out of a take like "Fifteen seconds!", so the word keeps its mid-phrase lift.

Word timings come from ElevenLabs forced alignment (tools/align.py). In this voice the "s" of
"seconds" starts right where the number ends, so a hard cut chops the final "n". Instead the word
keeps a --tail of the audio after its aligned end, low-passed below --lowpass Hz (which removes the
"s" hiss and leaves the "n" ringing), and that tail fades out to silence.

  uv run --no-project --with numpy python tools/cut_word.py IN.wav OUT.wav "Fifteen seconds!" [--tail 0.12]
"""
import argparse, json, os, subprocess, sys, wave
import numpy as np

p = argparse.ArgumentParser()
p.add_argument("src"); p.add_argument("out"); p.add_argument("text")
p.add_argument("--tail", type=float, default=0.12)
p.add_argument("--lowpass", type=float, default=1200.0)
a = p.parse_args()

words = json.loads(subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__), "align.py"), a.src, a.text],
                                  capture_output=True, text=True, check=True).stdout)
word = words[0]
w = wave.open(a.src); sr = w.getframerate()
x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float64)
first = int(np.argmax(np.abs(x) > 0.01 * np.abs(x).max()))
start = max(0, first - int(sr * 0.005))
end = int(word["end"] * sr)
stop = min(len(x), end + int(a.tail * sr))

# Low-pass by zeroing FFT bins above the cutoff, over a window with margin so the edges stay clean.
pad = int(0.05 * sr)
seg = x[end - pad:stop]
spec = np.fft.rfft(seg)
spec[np.fft.rfftfreq(len(seg), 1 / sr) > a.lowpass] = 0
low = np.fft.irfft(spec, len(seg))

out = x[start:stop].copy()
xf = int(0.02 * sr)                       # 20 ms crossfade into the low-passed tail
o = end - start
ramp = np.linspace(0, 1, xf)
out[o - xf:o] = out[o - xf:o] * (1 - ramp) + low[pad - xf:pad] * ramp
out[o:] = low[pad:]
fade = len(out) - o
out[o:] *= np.linspace(1, 0, fade) ** 2   # tail decays smoothly to silence

ow = wave.open(a.out, "w"); ow.setnchannels(1); ow.setsampwidth(2); ow.setframerate(sr)
ow.writeframes(np.clip(out, -32768, 32767).astype(np.int16).tobytes())
print(f"{a.out}: {len(out) / sr:.2f}s ({word['text']} {word['start']:.2f}-{word['end']:.2f})")
