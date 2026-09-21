"""Live end-to-end smoke test: hits the real upstreams through a running backend.

The pytest suite stubs every upstream call, which is what keeps CI offline and fast - and is
also how a variable name the provider has never published survived an entire pass, because the
marine API rejects a whole request when any one hourly variable is unknown, so an invented field
name takes the waves and the sea temperature down with it. This script is the check that cannot
be fooled by a stub. Run it against a live backend:

    uvicorn main:app --port 8000      # then
    python smoke_test_live.py         # or ML_API_BASE_URL=http://host:8000 python smoke_test_live.py
"""
import json
import os

import httpx

BASE = os.environ.get("ML_API_BASE_URL", "http://127.0.0.1:8000").rstrip("/")
# Al Bustan, Muscat - the same reading position the landing page's sample readout uses.
LAT, LON = 23.6143, 58.5453

TIMEOUT = 30


def show(label: str, payload, keys=None) -> None:
    """Print a whole response, or only the named keys when the payload is too wide to read."""
    print(f"\n== {label}")
    if keys is None:
        print(json.dumps(payload, indent=2))
        return
    print(json.dumps({k: payload.get(k) for k in keys}, indent=2, default=str))


def main() -> int:
    failures = 0

    r = httpx.get(f"{BASE}/", timeout=TIMEOUT)
    show("GET / (health)", {"status": r.json().get("status"), "version": r.json().get("version")})
    failures += r.status_code != 200

    # Ocean: the fields the app's Ocean screen prints, and the band those fields produced. The
    # boat and gear are sent because `day_rating` is derived from them - and because they are part
    # of the cache key, so the repeat below has to ask for exactly the same thing to be served
    # from the TTL cache.
    ocean_params = {"lat": LAT, "lon": LON, "boat_length_m": 6.7, "gear": "Handline"}
    r = httpx.get(f"{BASE}/api/v1/marine/conditions", params=ocean_params, timeout=TIMEOUT)
    ocean = r.json()
    show(f"GET /api/v1/marine/conditions -> {r.status_code}", ocean, [
        "sea_temperature_c", "wave_height_m", "wave_period_s", "wave_direction",
        "wind_speed_kts", "wind_direction", "current_speed_kts", "current_sets_to",
        "visibility_km", "uv_index", "tide_state", "tide_height_m", "next_high_tide",
        "sea_state", "day_rating", "cached",
    ])
    # A 502 here means an upstream rejected the request - check the variable names in
    # OPEN_METEO_MARINE_HOURLY before suspecting the network.
    failures += r.status_code != 200

    # Weather: live, with no key of any kind. `source` and `note` say who answered.
    r = httpx.get(f"{BASE}/api/v1/weather",
                  params={"lat": LAT, "lon": LON, "region": "Muscat"}, timeout=TIMEOUT)
    weather = r.json()
    show(f"GET /api/v1/weather -> {r.status_code}", weather, [
        "source", "attribution", "note", "current", "alerts",
    ])
    print("   hourly:", json.dumps((weather.get("hourly") or [])[:3], default=str))
    print("   daily: ", json.dumps(weather.get("daily") or [], default=str))
    failures += r.status_code != 200

    # Trip optimizer: three real spots at increasing distance. The radius and the fuel budget are
    # wide enough that all three can be in range, so the response shows the ranking rather than
    # three rejections - and `over_budget`/`outside_radius` stay visible if the numbers change.
    body = {
        "target_species": "Hammour",
        "departure_lat": LAT, "departure_lon": LON,
        "max_radius_nmi": 40, "max_budget_omr": 120, "duration_hours": 8,
        "boat_length_m": 6.7, "cruising_speed_kts": 18, "liters_per_nmi": 3.5,
        "candidates": [
            {"id": "h1", "name": "Daymaniyat North", "latitude": 23.85, "longitude": 58.15,
             "depth_meters": 24, "probability": 78, "target_species": ["Hammour", "Kingfish"]},
            {"id": "h2", "name": "Qurayyat Ridge", "latitude": 23.62, "longitude": 58.58,
             "depth_meters": 40, "probability": 54, "target_species": ["Snapper"]},
            {"id": "h3", "name": "Far offshore", "latitude": 26.95, "longitude": 60.24,
             "depth_meters": 60, "probability": 88, "target_species": ["Kingfish", "Tuna"]},
        ],
    }
    r = httpx.post(f"{BASE}/api/v1/trip/optimize", json=body, timeout=TIMEOUT)
    trip = r.json()
    show(f"POST /api/v1/trip/optimize -> {r.status_code}", trip, [
        "strategy", "conditions", "conditions_note", "candidates_evaluated",
        "viable_options", "recommended", "rejected",
    ])
    # `conditions` is null when the optimizer had no water to rank against. The app treats that
    # as the offline case, so it is worth seeing here rather than in a stack trace.
    if trip.get("conditions") is None:
        print("   NOTE: the ranking flew blind - no live marine data for the departure position.")
    failures += r.status_code != 200

    # Cached repeat: the same question, asked twice, must come from the TTL cache the second time
    # rather than hitting the upstream again.
    r = httpx.get(f"{BASE}/api/v1/marine/conditions", params=ocean_params, timeout=TIMEOUT)
    print(f"\n== repeat call cached flag -> {r.json().get('cached')}")
    failures += r.json().get("cached") is not True

    print(f"\n== {'OK' if not failures else f'{failures} endpoint(s) failed'}")
    return failures


if __name__ == "__main__":
    raise SystemExit(main())
