#!/usr/bin/env python3
"""Split a sequence take into its spoken parts at silent gaps.

  python3 tools/split_takes.py sounds-src/takes/seq1.wav  -> seq1_part1.wav, seq1_part2.wav, ...
"""
import struct, sys, wave

for path in sys.argv[1:]:
    w = wave.open(path); sr = w.getframerate(); n = w.getnframes()
    x = struct.unpack("<%dh" % n, w.readframes(n))
    win = int(sr * 0.01)
    peak = max(abs(v) for v in x)
    loud = [max(abs(v) for v in x[i:i + win]) > peak * 0.03 for i in range(0, n, win)]
    parts, start, quiet = [], None, 0
    for k, on in enumerate(loud + [False] * 30):
        if on:
            start = k if start is None else start; quiet = 0
        elif start is not None:
            quiet += 1
            if quiet >= 15:  # 150 ms of silence ends a part
                parts.append((start, k - quiet + 1)); start = None
    for j, (a, b) in enumerate(parts, 1):
        a, b = max(0, a * win - int(sr * 0.01)), min(n, b * win + int(sr * 0.06))
        o = wave.open(path.replace(".wav", f"_part{j}.wav"), "w")
        o.setnchannels(1); o.setsampwidth(2); o.setframerate(sr)
        o.writeframes(struct.pack("<%dh" % (b - a), *x[a:b]))
        print(f"{path} part{j}: {(b - a) / sr:.2f}s")
