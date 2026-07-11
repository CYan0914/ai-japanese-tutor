"""Quick test script for the chat endpoint."""

import json
import sys
import urllib.request

sys.stdout.reconfigure(encoding="utf-8")  # type: ignore

BASE = "http://localhost:8123/api/v1"

# Step 1: Get auth token
print("[KEY] Getting token...")
req = urllib.request.Request(
    f"{BASE}/auth/token",
    data=json.dumps({}).encode(),
    headers={"Content-Type": "application/json"},
)
token = json.loads(urllib.request.urlopen(req).read())["token"]
print(f"  Token: {token[:16]}...\n")

# Step 2: Test chat
print("[CHAT] Testing chat...")
body = json.dumps({"message": "How do I say hello in Japanese?", "level": "N5"}).encode()
req = urllib.request.Request(
    f"{BASE}/chat",
    data=body,
    headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}",
    },
)
resp = json.loads(urllib.request.urlopen(req).read())

r = resp["response"]
print(f"""
Sakura: {r['your_message'][:200]}
Japanese: {r['japanese_phrase']} ({r['romaji']})
Tips: {r['pronunciation_tips'][:150]}
Corrections: {len(r['corrections'])}
Encouragement: {r['encouragement']}
Usage: {resp['usage']['lessons_used_today']}/{resp['usage']['lessons_remaining']}
Audio: {'yes' if resp['audio_url'] else 'no'}
""")
