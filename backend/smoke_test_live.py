"""Live end-to-end smoke test for the marine/tide proxy endpoints."""
import json
import httpx

BASE = "http://127.0.0.1:8010"

r1 = httpx.get(f"{BASE}/api/v1/marine/conditions", params={"lat": 23.6143, "lon": 58.5453}, timeout=30)
print("== /api/v1/marine/conditions ->", r1.status_code)
print(json.dumps(r1.json(), indent=2))

r2 = httpx.get(f"{BASE}/api/v1/tides", params={"lat": 23.6143, "lon": 58.5453}, timeout=30)
print("== /api/v1/tides ->", r2.status_code)
d2 = r2.json()
d2["extremes"] = d2.get("extremes", [])[:4]
print(json.dumps(d2, indent=2))

r3 = httpx.get(f"{BASE}/api/v1/marine/conditions", params={"lat": 23.6143, "lon": 58.5453}, timeout=30)
print("== repeat call cached flag ->", r3.json().get("cached"))
