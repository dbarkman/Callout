# Sounds

Voice lines come from ElevenLabs text-to-speech, voice "Brian" (`nPczCjzI2devNBz1zQrb`, a deep, resonant American male), model `eleven_multilingual_v2`, stability 0.4, style 0.45, speed 0.85 (slightly slower than normal). Sources are in `sounds-src/`; `tools/prep_audio.py` trims silence, normalizes to -1 dBFS peak and writes `Callout/Sounds/`.

| File | Cue | Source |
|---|---|---|
| chime.wav | 0:45 | Synthesized single digital ding (E6) |
| thirty.wav | 0:30 | TTS "Thirty seconds!" |
| fifteen.wav | 0:15 | "Fifteen" cut from a TTS "Fifteen seconds!" take (stability 0.3, style 0.65) |
| ten.wav | 0:10 | "Ten" cut from a TTS "Ten seconds!" take (stability 0.3, style 0.65) |
| five … one.wav | 0:05 to 0:01 | TTS "Five!" … "One!" |
| tick.wav | 0:14–0:11, 0:09–0:06 | Synthesized 70 ms 1.4 kHz beep |
| cheer1–3.wav | 0:00 (random pick) | ElevenLabs SFX: "stadium crowd applause and cheering, enthusiastic whistles and clapping…", 4 s, 1 s fade-out |

A word said alone ends with a falling pitch and sounds flat. "Fifteen" and "Ten" are therefore generated as "Fifteen seconds!" and "Ten seconds!", and the number is cut out using ElevenLabs forced alignment. That keeps the same lift as "Thirty" in "Thirty seconds!". In this voice the "s" of "seconds" starts right where the number ends, so the cut keeps 120 ms past the aligned end, low-passed to drop the hiss, and fades it out so the final "n" rings out instead of being chopped. Takes are ranked against "Thirty" cut the same way:

```bash
uv run --no-project --with numpy python tools/cut_word.py sounds-src/takes2/fifteen_9.wav sounds-src/fifteen.wav "Fifteen seconds!"
uv run --no-project --with numpy python tools/match.py sounds-src/cuts/thirty_word.wav sounds-src/cuts/fifteen_*.wav
```

To regenerate a line:

```bash
python3 tools/voice.py --voice nPczCjzI2devNBz1zQrb --stability 0.4 --style 0.45 --speed 0.85 --text "Ten seconds!" --out sounds-src/ten.wav
python3 tools/prep_audio.py
```
