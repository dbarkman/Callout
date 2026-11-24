#!/usr/bin/env python3
"""Cut the first word out of a take like "Fifteen seconds!", so the word keeps its mid-phrase lift.

Word timings come from ElevenLabs forced alignment (tools/align.py). The cut ends --tail seconds
after the aligned word end, with a 30 ms fade.

  python3 tools/cut_word.py IN.wav OUT.wav "Fifteen seconds!" [--tail 0.03]
"""
import argparse, json, struct, subprocess, sys, wave, os

p = argparse.ArgumentParser()
p.add_argument("src"); p.add_argument("out"); p.add_argument("text")
p.add_argument("--tail", type=float, default=0.03)
a = p.parse_args()

words = json.loads(subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__), "align.py"), a.src, a.text],
                                  capture_output=True, text=True, check=True).stdout)
word = words[0]
w = wave.open(a.src); sr = w.getframerate(); n = w.getnframes()
x = list(struct.unpack("<%dh" % n, w.readframes(n)))
peak = max(abs(v) for v in x)
first = next(i for i, v in enumerate(x) if abs(v) > 0.01 * peak)
end = min(n, int((word["end"] + a.tail) * sr))
cut = [float(v) for v in x[max(0, first - int(sr * 0.005)):end]]
fade = int(sr * 0.03)
for i in range(fade):
    cut[-1 - i] *= i / fade
o = wave.open(a.out, "w"); o.setnchannels(1); o.setsampwidth(2); o.setframerate(sr)
o.writeframes(struct.pack("<%dh" % len(cut), *[int(v) for v in cut]))
print(f"{a.out}: {len(cut) / sr:.2f}s ({word['text']} {word['start']:.2f}-{word['end']:.2f})")
