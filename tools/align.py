#!/usr/bin/env python3
"""Word timings for a clip from ElevenLabs forced alignment.

  python3 tools/align.py CLIP.wav "Fifteen seconds!"   -> prints JSON words with start/end seconds
"""
import importlib.util, json, os, sys, urllib.request, uuid

spec = importlib.util.spec_from_file_location("sfx", os.path.expanduser("~/.config/elevenlabs/sfx.py"))
sfx = importlib.util.module_from_spec(spec); spec.loader.exec_module(sfx)

path, text = sys.argv[1], sys.argv[2]
boundary = uuid.uuid4().hex
body = b"".join([
    f"--{boundary}\r\nContent-Disposition: form-data; name=\"text\"\r\n\r\n{text}\r\n".encode(),
    f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"clip.wav\"\r\nContent-Type: audio/wav\r\n\r\n".encode(),
    open(path, "rb").read(), f"\r\n--{boundary}--\r\n".encode(),
])
req = urllib.request.Request(sfx.API + "/v1/forced-alignment", data=body, method="POST")
req.add_header("xi-api-key", sfx.key())
req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
try:
    with urllib.request.urlopen(req, timeout=120) as r:
        out = json.loads(r.read())
except urllib.error.HTTPError as e:
    sys.exit(f"HTTP {e.code}: {e.read()[:300].decode(errors='replace')}")
print(json.dumps([{k: w[k] for k in ("text", "start", "end")} for w in out["words"]]))
