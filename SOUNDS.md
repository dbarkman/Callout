# Sounds

Voice lines come from ElevenLabs text-to-speech, voice "Brian" (`nPczCjzI2devNBz1zQrb`, a deep, resonant American male), model `eleven_multilingual_v2`, stability 0.4, style 0.45. Sources are in `sounds-src/`; `tools/prep_audio.py` trims silence, normalizes to -1 dBFS peak and writes `Callout/Sounds/`.

| File | Cue | Source |
|---|---|---|
| thirty.wav | 0:30 | TTS "Thirty seconds!" |
| fifteen.wav | 0:15 | TTS "Fifteen!" |
| ten.wav | 0:10 | TTS "Ten!" |
| five … one.wav | 0:05 to 0:01 | TTS "Five!" … "One!" |
| tick.wav | 0:14–0:11, 0:09–0:06 | Synthesized 70 ms 1.4 kHz beep |
| fanfare1.wav | 0:00 (random pick) | ElevenLabs SFX: "short triumphant brass fanfare, trumpets, victory stinger…", 3 s |
| fanfare2.wav | 0:00 (random pick) | ElevenLabs SFX: "short triumphant orchestral brass fanfare with timpani hit…", 3 s |

To regenerate a line:

```bash
python3 tools/voice.py --voice nPczCjzI2devNBz1zQrb --stability 0.4 --style 0.45 --text "Ten!" --out sounds-src/ten.wav
python3 tools/prep_audio.py
```
