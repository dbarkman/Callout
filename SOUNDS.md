# Sounds

Voice lines come from ElevenLabs text-to-speech, voice "Brian" (`nPczCjzI2devNBz1zQrb`, a deep, resonant American male), model `eleven_multilingual_v2`, stability 0.4, style 0.45, speed 0.85 (slightly slower than normal). Sources are in `sounds-src/`; `tools/prep_audio.py` trims silence, normalizes to -1 dBFS peak and writes `Callout/Sounds/`.

| File | Cue | Source |
|---|---|---|
| chime.wav | 0:45 | Synthesized single digital ding (E6) |
| thirty.wav | 0:30 | TTS "Thirty seconds!" |
| fifteen.wav | 0:15 | TTS "Fifteen seconds!" (take picked with `tools/match.py` against thirty.wav) |
| ten.wav | 0:10 | TTS "Ten seconds!" (take picked with `tools/match.py` against thirty.wav) |
| five … one.wav | 0:05 to 0:01 | TTS "Five!" … "One!" |
| tick.wav | 0:13–0:11, 0:09–0:06 | Synthesized 70 ms 1.4 kHz beep |
| cheer1–3.wav | 0:00 (random pick) | ElevenLabs SFX: "stadium crowd applause and cheering, enthusiastic whistles and clapping…", 4 s, 1 s fade-out |

To regenerate a line:

```bash
python3 tools/voice.py --voice nPczCjzI2devNBz1zQrb --stability 0.4 --style 0.45 --speed 0.85 --text "Ten seconds!" --out sounds-src/ten.wav
python3 tools/prep_audio.py
```
