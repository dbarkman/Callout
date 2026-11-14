#!/usr/bin/env python3
"""Text-to-speech for Callout's voice cues, through the ElevenLabs helper's key handling.

  voice.py --voice VOICE_ID --text "Thirty seconds" --out sounds-src/thirty.wav
"""
import argparse, importlib.util, json, os, subprocess, tempfile

spec = importlib.util.spec_from_file_location("sfx", os.path.expanduser("~/.config/elevenlabs/sfx.py"))
sfx = importlib.util.module_from_spec(spec); spec.loader.exec_module(sfx)

p = argparse.ArgumentParser()
p.add_argument("--voice", required=True)
p.add_argument("--text", required=True)
p.add_argument("--out", required=True)
p.add_argument("--stability", type=float, default=0.5)
p.add_argument("--style", type=float, default=0.3)
a = p.parse_args()
body = {"text": a.text, "model_id": "eleven_multilingual_v2",
        "voice_settings": {"stability": a.stability, "similarity_boost": 0.8, "style": a.style, "use_speaker_boost": True}}
audio, headers = sfx.request("POST", f"/v1/text-to-speech/{a.voice}?output_format=mp3_44100_128", body, accept="audio/mpeg")
with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as t:
    t.write(audio); mp3 = t.name
try:
    subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16", mp3, os.path.abspath(a.out)], check=True)
finally:
    os.remove(mp3)
info = sfx.analyze(a.out)
info.pop("envelope_0.1s", None)
print(json.dumps(info))
