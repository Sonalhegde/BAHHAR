from fastapi.testclient import TestClient
import httpx
from main import app

client = TestClient(app)

def test_health():
    res = client.get("/")
    assert res.status_code == 200
    assert res.json()["status"] == "online"

def test_predict_kingfish_optimal():
    payload = {
        "latitude": 23.68,
        "longitude": 58.50,
        "target_species": "Kingfish",
        "sea_temp_c": 27.2,
        "wind_speed_kts": 12.0,
        "wave_height_m": 0.8,
        "tide_state": "Rising",
        "depth_meters": 38
    }
    res = client.post("/api/v1/predict", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["probability"] >= 75
    assert data["confidence"] > 0.8
    assert len(data["contributing_factors"]) > 0

def test_geofence_daymaniyat_protected():
    payload = {
        "latitude": 23.8617,
        "longitude": 58.0933
    }
    res = client.post("/api/v1/geofence/verify", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "Protected"
    assert "Daymaniyat" in data["reserve_name"]
    assert "23/96" in data["legal_decree"]


# ---------------------------------------------------------------------------
# Marine / tide proxy endpoints — all upstream calls are monkeypatched so the
# suite stays offline-safe (CI has no network credentials).
# ---------------------------------------------------------------------------
from datetime import datetime, UTC, timedelta, date
import asyncio

import main


def test_tide_state_from_extremes_rising():
    now = datetime.now(UTC)
    extremes = [
        {"dt": str(int((now - timedelta(hours=3)).timestamp())), "height": 0.4, "type": "low"},
        {"dt": str(int((now + timedelta(hours=3)).timestamp())), "height": 2.1, "type": "high"},
    ]
    state, height, _ = main._tide_state_from_extremes(extremes, now=now)
    assert state == "Rising"
    assert 0.4 <= height <= 2.1


def test_tide_state_from_extremes_high_water():
    now = datetime.now(UTC)
    extremes = [
        {"dt": str(int((now - timedelta(hours=6)).timestamp())), "height": 0.3, "type": "low"},
        {"dt": str(int((now - timedelta(minutes=10)).timestamp())), "height": 2.0, "type": "high"},
        {"dt": str(int((now + timedelta(hours=5)).timestamp())), "height": 0.2, "type": "low"},
    ]
    state, _height, _ = main._tide_state_from_extremes(extremes, now=now)
    assert state == "High"


FAKE_WEATHER = {
    "current": {
        "temperature_2m": 30.5,
        "wind_speed_10m": 14.4,  # km/h -> ~8 kt
        "wind_direction_10m": 120,
        "wind_gusts_10m": 21.0,
        "cloud_cover": 25,
        "pressure_msl": 1008,
        "weather_code": 1,
        "is_day": 1,
    }
}

FAKE_MARINE = {
    "hourly": {
        "time": [datetime.now(UTC).strftime("%Y-%m-%dT%H:00")],
        "wave_height": [1.2],
        "wave_period": [6.5],
        "wave_direction": [130],
        "sea_surface_temperature": [27.8],
    }
}


def _fake_fetcher(result):
    async def _fetch(client, lat, lon):
        return result
    return _fetch


def test_marine_conditions_proxy_offline(monkeypatch):
    main._CACHE.clear()
    monkeypatch.setattr(main, "_fetch_open_meteo_weather", _fake_fetcher(FAKE_WEATHER))
    monkeypatch.setattr(main, "_fetch_open_meteo_marine", _fake_fetcher(FAKE_MARINE))
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "")  # tide gracefully unavailable

    res = client.get("/api/v1/marine/conditions", params={"lat": 23.61, "lon": 58.54})
    assert res.status_code == 200
    data = res.json()
    assert data["wave_height_m"] == 1.2
    assert data["sea_temperature_c"] == 27.8
    assert data["wind_speed_kts"] == 8  # 14.4 km/h = 7.8 kt (Open-Meteo's wind unit is km/h)
    assert data["tide_state"] == "Unavailable"
    assert data["cached"] is False

    # Second call must be served from the server-side TTL cache (no upstream hit).
    def _boom(client, lat, lon):
        raise AssertionError("cache miss: upstream called twice")
    monkeypatch.setattr(main, "_fetch_open_meteo_weather", _boom)
    res2 = client.get("/api/v1/marine/conditions", params={"lat": 23.61, "lon": 58.54})
    assert res2.status_code == 200
    assert res2.json()["cached"] is True


def test_marine_conditions_proxy_with_tides(monkeypatch):
    main._CACHE.clear()
    now = datetime.now(UTC)
    fake_tides = {
        "extremes": [
            {"dt": str(int((now - timedelta(hours=2)).timestamp())), "height": 0.5, "type": "low"},
            {"dt": str(int((now + timedelta(hours=4)).timestamp())), "height": 2.2, "type": "high"},
        ],
        "copyright": "test",
    }
    monkeypatch.setattr(main, "_fetch_open_meteo_weather", _fake_fetcher(FAKE_WEATHER))
    monkeypatch.setattr(main, "_fetch_open_meteo_marine", _fake_fetcher(FAKE_MARINE))
    monkeypatch.setattr(main, "_fetch_worldtides_extremes", _fake_fetcher(fake_tides))
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "test-key")

    res = client.get("/api/v1/marine/conditions", params={"lat": 23.6, "lon": 58.5})
    assert res.status_code == 200
    data = res.json()
    assert data["tide_state"] == "Rising"
    assert data["tide_source"] == "WorldTides"
    assert data["tide_height_m"] > 0.5


def test_marine_conditions_upstream_failure_returns_502(monkeypatch):
    main._CACHE.clear()

    async def _fail(client, lat, lon):
        raise httpx.ConnectError("down")

    monkeypatch.setattr(main, "_fetch_open_meteo_weather", _fail)
    monkeypatch.setattr(main, "_fetch_open_meteo_marine", _fail)
    res = client.get("/api/v1/marine/conditions", params={"lat": 23.6, "lon": 58.5})
    assert res.status_code == 502
    main._CACHE.clear()


def test_tides_endpoint_requires_key(monkeypatch):
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "")
    res = client.get("/api/v1/tides", params={"lat": 23.6, "lon": 58.5})
    assert res.status_code == 503


# ---------------------------------------------------------------------------
# Tide height curve (/api/v1/tides/curve) — the continuous line behind the
# Rising/Falling number. Upstream monkeypatched so the suite stays offline.
# ---------------------------------------------------------------------------
def test_tide_state_from_heights_reads_nearest_sample():
    now = datetime.now(UTC)
    pts = [
        {"dt": int((now - timedelta(hours=1)).timestamp()), "height": 1.0},
        {"dt": int(now.timestamp()), "height": 1.5},
        {"dt": int((now + timedelta(hours=1)).timestamp()), "height": 2.4},
    ]
    state, height = main._tide_state_from_heights(pts, now=now)
    assert state == "Rising"
    assert height == 1.5


def test_tide_state_from_heights_falling():
    now = datetime.now(UTC)
    pts = [
        {"dt": int(now.timestamp()), "height": 2.0},
        {"dt": int((now + timedelta(hours=1)).timestamp()), "height": 0.6},
    ]
    state, _height = main._tide_state_from_heights(pts, now=now)
    assert state == "Falling"


def test_tides_curve_requires_key(monkeypatch):
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "")
    res = client.get("/api/v1/tides/curve", params={"lat": 23.6, "lon": 58.5})
    assert res.status_code == 503


def test_tides_curve_proxy_and_cache(monkeypatch):
    main._CACHE.clear()
    now = datetime.now(UTC)
    fake = {
        "heights": [
            {"dt": int((now + timedelta(minutes=30 * i)).timestamp()),
             "height": round(0.5 + 0.2 * i, 2)}
            for i in range(0, 8)
        ],
        "station": "TEST STATION",
        "atlas": "FES2022",
        "copyright": "test",
    }

    async def _fake(client, lat, lon, hours):
        return fake

    monkeypatch.setattr(main, "_fetch_worldtides_heights", _fake)
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "test-key")

    res = client.get("/api/v1/tides/curve",
                     params={"lat": 23.6, "lon": 58.5, "hours": 6})
    assert res.status_code == 200
    data = res.json()
    assert data["cached"] is False
    assert data["station"] == "TEST STATION"
    assert len(data["points"]) == 8
    assert data["points"][0]["height_m"] == 0.5
    assert data["tide_state"] in {"Rising", "Falling"}

    # Second call served from the server-side TTL cache (no upstream re-hit).
    async def _boom(client, lat, lon, hours):
        raise AssertionError("cache miss: upstream called twice")

    monkeypatch.setattr(main, "_fetch_worldtides_heights", _boom)
    res2 = client.get("/api/v1/tides/curve",
                      params={"lat": 23.6, "lon": 58.5, "hours": 6})
    assert res2.status_code == 200
    assert res2.json()["cached"] is True
    main._CACHE.clear()


# ---------------------------------------------------------------------------
# Sea-state banding and the day rating — the rule the landing page prints, so a
# threshold that drifts here has to fail a test there.
# ---------------------------------------------------------------------------
def test_sea_state_band_good_and_moderate():
    assert main._sea_state_band(0.6, 8.0)["band"] == "good"
    # 1.2 m of wave alone is enough for Moderate (wave >= 1.0).
    assert main._sea_state_band(1.2, 4.0)["band"] == "moderate"


def test_sea_state_band_is_worst_reading_not_an_average():
    # Calm waves, calm wind, one 2.1 kt current: the current is the only driver.
    band = main._sea_state_band(0.4, 3.0, current_kts=2.1)
    assert band["band"] == "strong_current"
    assert band["drivers"] == ["current_kts"]
    assert "never an average" in band["rule"]


def test_sea_state_band_rough_and_high_risk():
    assert main._sea_state_band(1.6, 10.0)["band"] == "rough_sea"
    assert main._sea_state_band(0.5, 30.0)["band"] == "high_risk"
    # An active warning outranks every calm reading on the page.
    assert main._sea_state_band(0.5, 4.0, alert_active=True)["band"] == "high_risk"


def test_day_rating_boat_and_gear_are_what_change_the_answer():
    # 2.0 kt of current, everything else benign: an open 5 m boat steps down,
    # a cabin cruiser of the same length holds its ocean band.
    kwargs = dict(current_kts=2.2, wave_height_m=0.8, wind_speed_kts=8.0)
    open_boat = main._day_rating("good", boat_length_m=5.0, boat_type="open", **kwargs)
    cabin = main._day_rating("good", boat_length_m=5.0, boat_type="cabin", **kwargs)
    assert open_boat["rating"] == "moderate"
    assert cabin["rating"] == "good"
    # Gear calls a session off rather than merely downgrading it.
    nets = main._day_rating("good", gear=["Gill net"], **kwargs)
    assert any("slack water" in r for r in nets["reasons"])
    # Wind over the open-boat limit is its own step down.
    assert main._day_rating("good", 2.0, 20.0)["rating"] != "good"


def test_next_extreme_picks_the_following_high_in_oman_time():
    now = datetime(2026, 9, 20, 6, 0, tzinfo=UTC)  # 10:00 in Muscat
    extremes = [
        {"dt": str(int((now - timedelta(hours=5)).timestamp())), "height": 2.0, "type": "high"},
        {"dt": str(int((now + timedelta(hours=2)).timestamp())), "height": 1.8, "type": "high"},
        {"dt": str(int((now + timedelta(hours=1)).timestamp())), "height": 0.3, "type": "low"},
    ]
    assert main._next_extreme(extremes, now=now) == {"time": "12:00", "height_m": 1.8}
    assert main._next_extreme(extremes[:1], now=now) is None  # nothing ahead: say so


def test_marine_conditions_carry_wave_direction_current_and_band(monkeypatch):
    main._CACHE.clear()
    weather = {
        "current": {**FAKE_WEATHER["current"], "wind_speed_10m": 7.2,  # 7.2 km/h -> 14 kt
                    "visibility": 8000, "uv_index": 9},
        "hourly": {"time": ["x"]},
    }
    marine = {
        "hourly": {
            "time": [datetime.now(UTC).strftime("%Y-%m-%dT%H:00")],
            "wave_height": [1.2], "wave_period": [7.0], "wave_direction": [45],
            "sea_surface_temperature": [27.4],
            "ocean_current_velocity": [0.3], "ocean_current_direction": [0.0],
        }
    }
    monkeypatch.setattr(main, "_fetch_open_meteo_weather", _fake_fetcher(weather))
    monkeypatch.setattr(main, "_fetch_open_meteo_marine", _fake_fetcher(marine))
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "")

    res = client.get("/api/v1/marine/conditions",
                     params={"lat": 23.61, "lon": 58.54, "boat_length_m": 6.7,
                             "boat_type": "open", "gear": "Handline"})
    assert res.status_code == 200
    data = res.json()
    assert data["wave_direction"] == "NE"            # comes from the north-east
    assert data["visibility_km"] == 8.0
    assert data["current_speed_kts"] == 0.6
    assert data["current_sets_to"] == "S"            # sets toward the south
    assert data["sea_state"]["band"] == "moderate"
    assert data["sea_state"]["drivers"] == ["wave_height_m"]
    assert data["day_rating"]["ocean_band"] == "moderate"
    assert "next_high_tide" not in data              # no tide station: field absent, not guessed


def test_marine_request_only_asks_for_variables_the_live_api_accepts():
    """A field name this provider does not publish is not a missing tile - it is no Ocean
    readout at all.

    The marine API answers 400 for the whole request when any one hourly variable is unknown, and
    the endpoint turns that into a 502 with nothing to show. That is how asking for
    `surface_current_eastward` took down wave, temperature and current together, which every
    upstream-mocked test happily passed. This is the one test that looks at what goes out rather
    than at what comes back, so the regression cannot come back in through a stub."""
    seen = {}

    class _Response:
        def raise_for_status(self) -> None:
            pass

        def json(self):
            return {"hourly": {"time": []}}

    class _Client:
        async def get(self, url, params=None):
            seen["url"] = url
            seen["params"] = params
            return _Response()

    asyncio.run(main._fetch_open_meteo_marine(_Client(), 23.61, 58.54))
    requested = seen["params"]["hourly"].split(",")
    assert tuple(requested) == main.OPEN_METEO_MARINE_HOURLY
    assert "ocean_current_velocity" in requested and "ocean_current_direction" in requested
    assert not [v for v in requested if v.startswith("surface_current_")]


def test_current_bearing_is_printed_the_way_a_fisherman_reads_it(monkeypatch):
    """The provider gives the bearing the water comes from; the readout prints where it sets.

    A bearing printed half a circle out is a wrong bearing on a navigational screen, so the
    conversion is pinned here rather than trusted to the comment above it."""
    main._CACHE.clear()
    marine = {
        "hourly": {
            "time": [datetime.now(UTC).strftime("%Y-%m-%dT%H:00")],
            "wave_height": [0.5], "wave_period": [6.0], "wave_direction": [45],
            "sea_surface_temperature": [27.0],
            "ocean_current_velocity": [1.0], "ocean_current_direction": [90],
        }
    }
    monkeypatch.setattr(main, "_fetch_open_meteo_weather",
                        _fake_fetcher({"current": FAKE_WEATHER["current"], "hourly": {"time": ["x"]}}))
    monkeypatch.setattr(main, "_fetch_open_meteo_marine", _fake_fetcher(marine))
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "")

    data = client.get("/api/v1/marine/conditions",
                      params={"lat": 23.61, "lon": 58.54}).json()
    assert data["current_speed_kts"] == 1.9          # 1 m/s, not 1 kt
    assert data["current_direction_deg"] == 270      # from the east, so it sets west
    assert data["current_sets_to"] == "W"
    assert data["wave_direction"] == "NE"            # waves keep their own from-bearing


def test_current_conversion_survives_a_wrap(monkeypatch):
    """A south-setting current must not come out as bearing 270 or -90."""
    main._CACHE.clear()
    marine = {
        "hourly": {
            "time": [datetime.now(UTC).strftime("%Y-%m-%dT%H:00")],
            "wave_height": [0.4], "wave_period": [6.0], "wave_direction": [0],
            "sea_surface_temperature": [27.0],
            "ocean_current_velocity": [0.5], "ocean_current_direction": [180],
        }
    }
    monkeypatch.setattr(main, "_fetch_open_meteo_weather",
                        _fake_fetcher({"current": FAKE_WEATHER["current"], "hourly": {"time": ["x"]}}))
    monkeypatch.setattr(main, "_fetch_open_meteo_marine", _fake_fetcher(marine))
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "")

    data = client.get("/api/v1/marine/conditions",
                      params={"lat": 23.61, "lon": 58.54}).json()
    assert data["current_direction_deg"] == 0
    assert data["current_sets_to"] == "N"


def test_weather_endpoint_serves_the_documented_mock_shape(monkeypatch):
    main._CACHE.clear()
    monkeypatch.setattr(main, "ACCUWEATHER_API_KEY", "")
    _offline_open_meteo(monkeypatch)
    res = client.get("/api/v1/weather", params={"lat": 23.61, "lon": 58.54, "region": "Muscat"})
    assert res.status_code == 200
    data = res.json()
    assert data["source"] == "mock"
    assert data["attribution"] == main.ACCUWEATHER_ATTRIBUTION  # attribution is in the payload
    assert data["alerts"] == []                        # nothing to draw, so nothing is drawn
    assert data["cached"] is False
    current = data["current"]
    for field in ("temp_c", "feels_like_c", "condition", "humidity_pct",
                  "wind_kmh", "wind_dir", "rain_probability_pct", "uv_index", "visibility_km"):
        assert field in current, field
    assert len(data["hourly"]) >= 6 and len(data["daily"]) == 5
    assert "No weather provider is reachable" in data["note"]

    res2 = client.get("/api/v1/weather", params={"lat": 23.61, "lon": 58.54})
    assert res2.json()["cached"] is True


# ---------------------------------------------------------------------------
# Keyless Open-Meteo weather fallback - the provider that answers when no
# ACCUWEATHER_API_KEY is set, so the app shows live readings instead of the
# sample shape. Upstream is monkeypatched; the suite never touches the network.
# ---------------------------------------------------------------------------

FAKE_OM_FORECAST = {
    "current": {
        "time": "2026-04-18T09:00",
        "temperature_2m": 31.4,
        "apparent_temperature": 35.1,
        "relative_humidity_2m": 62,
        "weather_code": 2,
        "wind_speed_10m": 14.0,
        "wind_direction_10m": 45.0,
        "precipitation_probability": 5,
        "uv_index": 8.2,
        "visibility": 24000.0,
    },
    "hourly": {
        # A full day from midnight, so slicing to the current hour is observable.
        "time": [f"2026-04-18T{h:02d}:00" for h in range(24)],
        "temperature_2m": [28.0 + h * 0.1 for h in range(24)],
        "weather_code": [0] * 24,
        "precipitation_probability": [h for h in range(24)],
    },
    "daily": {
        "time": [f"2026-04-{17 + d:02d}" for d in range(5)],
        "weather_code": [0, 1, 2, 3, 45],
        "temperature_2m_max": [33.0, 33.5, 32.0, 31.0, 32.5],
        "temperature_2m_min": [26.0, 26.5, 25.5, 25.0, 26.0],
    },
}


def _offline_open_meteo(monkeypatch):
    """Make the keyless provider unreachable, so the mock branch is testable offline."""
    async def boom(client, lat, lon):
        raise httpx.ConnectError("offline")

    monkeypatch.setattr(main, "_fetch_open_meteo_forecast", boom)


def _fake_open_meteo(monkeypatch, raw=FAKE_OM_FORECAST):
    async def fake(client, lat, lon):
        return raw

    monkeypatch.setattr(main, "_fetch_open_meteo_forecast", fake)


def test_wmo_phrase_translates_codes_without_inventing_conditions():
    assert main._wmo_phrase(2) == "Partly cloudy"
    assert main._wmo_phrase(95) == "Thunderstorm"
    assert main._wmo_phrase(None) == "Mixed"      # no reading, no claim
    assert main._wmo_phrase(9999) == "Mixed"      # code outside the table


def test_open_meteo_mapper_matches_the_weather_contract():
    mapped = main._map_open_meteo_weather(FAKE_OM_FORECAST)
    cur = mapped["current"]
    assert cur["temp_c"] == 31.4 and cur["feels_like_c"] == 35.1
    assert cur["condition"] == "Partly cloudy"    # code 2, not the number 2
    assert cur["wind_dir"] == "NE"                # 45 degrees, the bearing wind comes FROM
    assert cur["visibility_km"] == 24.0           # metres in the API, km in the contract
    assert cur["uv_index"] == 8.2
    assert mapped["hourly"][0]["time"] == "09:00"  # the strip starts now, not at midnight
    assert len(mapped["hourly"]) == 8
    assert mapped["daily"][4]["condition"] == "Fog"
    assert mapped["alerts"] == []                 # Open-Meteo has no alert feed for Oman


def test_open_meteo_mapper_leaves_a_missing_bearing_null():
    raw = {"current": {k: v for k, v in FAKE_OM_FORECAST["current"].items()
                       if k != "wind_direction_10m"}}
    assert main._map_open_meteo_weather(raw)["current"]["wind_dir"] is None


def test_weather_endpoint_prefers_live_open_meteo_over_the_mock(monkeypatch):
    main._CACHE.clear()
    monkeypatch.setattr(main, "ACCUWEATHER_API_KEY", "")
    _fake_open_meteo(monkeypatch)
    res = client.get("/api/v1/weather", params={"lat": 23.61, "lon": 58.54})
    data = res.json()
    assert data["source"] == "open-meteo"
    assert data["attribution"] == main.OPEN_METEO_ATTRIBUTION
    assert data["current"]["temp_c"] == 31.4
    assert data["alerts"] == []
    # The absent alert feed is disclosed rather than rendered as an all-clear.
    assert "alert banner cannot light up" in data["note"]


def test_weather_endpoint_degrades_past_a_spent_accuweather_budget(monkeypatch):
    """The daily call ceiling belongs to AccuWeather, not to the page: once it is spent the
    endpoint must fall back to the keyless provider instead of answering 5xx."""
    main._CACHE.clear()
    monkeypatch.setattr(main, "ACCUWEATHER_API_KEY", "test-key")
    monkeypatch.setattr(main, "ACCUWEATHER_DAILY_CALL_BUDGET", 1)
    monkeypatch.setitem(main._ACCUWEATHER_CALLS, date.today().isoformat(), 99)
    _fake_open_meteo(monkeypatch)
    res = client.get("/api/v1/weather", params={"lat": 23.61, "lon": 58.54})
    assert res.status_code == 200
    data = res.json()
    assert data["source"] == "open-meteo"
    assert "budget is spent" in data["note"]


# ---------------------------------------------------------------------------
# Trip optimisation, and the wind-unit bug it exposed in the marine proxy.
# ---------------------------------------------------------------------------

def _patch_water(monkeypatch, wind_kmh=9.0, wave_m=0.6):
    """Calm water by default, so a test that says nothing about weather is not silently
    being scored on a storm."""
    main._CACHE.clear()
    weather = {"current": {**FAKE_WEATHER["current"], "wind_speed_10m": wind_kmh}}
    marine = {"hourly": {**FAKE_MARINE["hourly"], "wave_height": [wave_m]}}
    monkeypatch.setattr(main, "_fetch_open_meteo_weather", _fake_fetcher(weather))
    monkeypatch.setattr(main, "_fetch_open_meteo_marine", _fake_fetcher(marine))
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "")


def test_marine_wind_is_converted_from_kilometres_per_hour(monkeypatch):
    """Open-Meteo sends km/h. The m/s factor this line used to carry turned a 20 km/h breeze
    into 38.9 kt and banded it "high risk" - a warning that sends fishermen home for nothing."""
    _patch_water(monkeypatch, wind_kmh=20.0, wave_m=0.5)
    data = client.get("/api/v1/marine/conditions",
                      params={"lat": 23.61, "lon": 58.54}).json()
    assert data["wind_speed_kts"] == 11.0        # 20 km/h = 10.8 kt, not 38.9
    assert data["sea_state"]["band"] == "good"   # the old factor banded this "high_risk"


def _spot(spot_id, lat, lon, prob, species, depth=30):
    return {"id": spot_id, "name": spot_id.title(), "latitude": lat, "longitude": lon,
            "probability": prob, "target_species": species, "depth_meters": depth}


TRIP_BODY = {
    "target_species": "Kingfish",
    "departure_lat": 23.6143,
    "departure_lon": 58.5453,
    "max_radius_nmi": 15,
    "max_budget_omr": 35,
    "cruising_speed_kts": 20,
    "liters_per_nmi": 0.85,
}


def test_trip_optimize_prefers_the_species_match_over_the_closer_spot(monkeypatch):
    _patch_water(monkeypatch)
    body = {**TRIP_BODY, "candidates": [
        _spot("near", 23.63, 58.56, 70, ["Grouper"]),
        _spot("far", 23.70, 58.62, 65, ["Kingfish"], depth=45),
    ]}
    data = client.post("/api/v1/trip/optimize", json=body).json()
    assert data["recommended"]["id"] == "far"
    assert "species_match" in data["recommended"]["reasons"]
    assert data["alternatives"][0]["id"] == "near"


def test_trip_optimize_reports_what_the_boat_cannot_do(monkeypatch):
    _patch_water(monkeypatch)
    body = {**TRIP_BODY, "max_budget_omr": 0.15, "candidates": [
        _spot("too-far", 24.30, 58.90, 90, ["Kingfish"]),
        _spot("affordable", 23.62, 58.55, 50, ["Kingfish"]),
    ]}
    data = client.post("/api/v1/trip/optimize", json=body).json()
    blockers = {r["id"]: r["blockers"] for r in data["rejected"]}
    assert "outside_radius" in blockers["too-far"]
    assert "over_budget" in blockers["affordable"]
    assert data["viable_options"] == 0
    # Nothing fits, so the shortest crossing is offered - and labelled as not a real plan.
    assert data["recommended"]["id"] == "affordable"
    assert data["recommended"]["fallback"] is True
    assert "no_viable_option" in data["recommended"]["reasons"]


def test_trip_optimize_sea_state_and_boat_size_change_the_score(monkeypatch):
    candidates = [_spot("a", 23.70, 58.62, 65, ["Kingfish"])]

    _patch_water(monkeypatch, wind_kmh=9.0, wave_m=0.6)
    calm = client.post("/api/v1/trip/optimize",
                       json={**TRIP_BODY, "candidates": candidates}).json()

    _patch_water(monkeypatch, wind_kmh=40.0, wave_m=2.2)
    big = client.post("/api/v1/trip/optimize",
                      json={**TRIP_BODY, "boat_length_m": 12.0,
                            "candidates": candidates}).json()
    small = client.post("/api/v1/trip/optimize",
                        json={**TRIP_BODY, "boat_length_m": 5.0,
                              "candidates": candidates}).json()

    assert calm["conditions"]["sea_state_band"] == "good"
    assert big["conditions"]["sea_state_band"] == "rough_sea"
    assert big["recommended"]["score"] < calm["recommended"]["score"]
    # The same water is a different proposition in a 5 m open boat than in a 12 m one.
    assert small["recommended"]["score"] < big["recommended"]["score"]
    assert "small_boat_in_this_sea" in small["recommended"]["reasons"]


def test_trip_optimize_says_so_when_it_cannot_see_the_water(monkeypatch):
    main._CACHE.clear()

    async def fail(client, lat, lon):
        raise httpx.ConnectError("offline")

    monkeypatch.setattr(main, "_fetch_open_meteo_weather", fail)
    monkeypatch.setattr(main, "_fetch_open_meteo_marine", fail)
    monkeypatch.setattr(main, "WORLDTIDES_API_KEY", "")
    body = {**TRIP_BODY, "candidates": [
        _spot("dull", 23.62, 58.55, 50, ["Kingfish"]),
        _spot("likely", 23.70, 58.62, 80, ["Kingfish"]),
    ]}
    res = client.post("/api/v1/trip/optimize", json=body)
    assert res.status_code == 200            # blind, not broken
    data = res.json()
    assert data["conditions"] is None
    assert "No sea-state penalty applied" in data["conditions_note"]
    assert data["recommended"]["id"] == "likely"


def test_trip_optimize_fuel_arithmetic_matches_the_apps_calculator(monkeypatch):
    """The client owns the boat table and sends it; this checks the server used it the same
    way FuelCalculatorService.calculateTrip does: round trip, 25 % reserve, Omani pump price."""
    _patch_water(monkeypatch)
    body = {**TRIP_BODY, "candidates": [_spot("a", 23.70, 58.62, 65, ["Kingfish"])]}
    plan = client.post("/api/v1/trip/optimize", json=body).json()["recommended"]
    expected_fuel = round(plan["round_trip_nm"] * 0.85 * 1.25, 1)
    assert plan["fuel_liters"] == expected_fuel
    # Every figure is priced off the printed one above it, so the arithmetic is checkable.
    assert plan["cost_omr"] == round(plan["fuel_liters"] * 0.239, 2)
    assert plan["round_trip_nm"] == round(plan["distance_nm"] * 2, 1)
    assert plan["travel_minutes"] == round(plan["distance_nm"] / 20 * 60)


def test_trip_optimize_refuses_an_empty_catalogue():
    res = client.post("/api/v1/trip/optimize", json={**TRIP_BODY, "candidates": []})
    assert res.status_code == 400


def test_trip_optimize_declares_itself_a_rule_not_a_model(monkeypatch):
    """The endpoint is called ML in the roadmap; until a model exists the response must not
    let a caller believe one does."""
    _patch_water(monkeypatch)
    data = client.post("/api/v1/trip/optimize",
                       json={**TRIP_BODY, "candidates": [_spot("a", 23.62, 58.55, 50, [])]}).json()
    assert "not a trained model" in data["strategy"]
    assert "score =" in data["rule"]
    assert data["weights"]["species_match"] == 18.0


# ---------------------------------------------------------------------------
# /api/v1/wind-field — the grid behind the website's particle-flow layer.
# Upstream is faked (offline-safe like the rest of the suite), but the
# outgoing request parameters are asserted: a silent variable-name or unit
# drift against the live API is the failure mode this project pins by test.
# ---------------------------------------------------------------------------

_WF_NOW = datetime.now(UTC).strftime("%Y-%m-%dT%H:00")


def _wf_upstream(wind=(36.0, 270.0, "km/h"), current=(3.6, 180.0, "km/h"),
                 fail_base=None, null_coords=()):
    """Build (calls, fake) for monkeypatching the chunk fetcher.

    Wind 36 km/h FROM the west is +10 m/s eastward; current 3.6 km/h FROM the
    south is +1 m/s northward. Coordinates come back snapped off-grid like the
    live API really answers, so the nearest-cell mapping is exercised too.
    """
    calls = []

    async def _fake(client, base, hourly, chunk):
        calls.append((base, tuple(hourly), len(chunk)))
        if fail_base and fail_base in base:
            raise httpx.ConnectError("upstream down")
        speed, direction, unit = wind if "forecast" in base else current
        speed_key, dir_key = hourly
        return [
            {
                "latitude": lat + 0.008,
                "longitude": lon - 0.004,
                "hourly_units": {speed_key: unit},
                "hourly": {
                    "time": [_WF_NOW],
                    speed_key: [None if (lat, lon) in null_coords else speed],
                    dir_key: [direction],
                },
            }
            for lat, lon in chunk
        ]

    return calls, _fake


def test_wind_field_grid_shape_uv_and_request_params(monkeypatch):
    main._CACHE.clear()
    calls, fake = _wf_upstream()
    monkeypatch.setattr(main, "_fetch_open_meteo_grid_chunk", fake)

    res = client.get("/api/v1/wind-field")
    assert res.status_code == 200
    data = res.json()

    header = data["header"]
    assert (header["nx"], header["ny"]) == (17, 21)
    assert header["lo1"] == 52.0 and header["la1"] == 26.5 and header["dx"] == 0.5
    n = header["nx"] * header["ny"]
    for name in ("wind", "current"):
        field = data["fields"][name]
        assert len(field["u"]) == n and len(field["v"]) == n
        assert field["unit"] == "m/s"

    # Every cell carries the derived vector: FROM-bearings rotated to TO-flow.
    assert data["fields"]["wind"]["u"][0] == 10.0
    assert abs(data["fields"]["wind"]["v"][0]) < 1e-6
    assert abs(data["fields"]["current"]["u"][0]) < 1e-6
    assert data["fields"]["current"]["v"][0] == 1.0
    assert data["stats"]["wind_max_ms"] == 10.0
    assert data["cached"] is False

    # Outgoing calls: both providers, each in 90-point chunks (357 = 90+90+90+87),
    # and the exact hourly variable names the live API accepts.
    bases = {c[0] for c in calls}
    assert main.OPEN_METEO_BASE in bases and main.OPEN_METEO_MARINE_BASE in bases
    assert all(c[2] <= main._WF_CHUNK for c in calls)
    assert sum(1 for c in calls if c[2] == 90) == 6 and len(calls) == 8
    wind_calls = [c for c in calls if "forecast" in c[0]]
    assert wind_calls[0][1] == ("wind_speed_10m", "wind_direction_10m")
    current_calls = [c for c in calls if "marine" in c[0]]
    assert current_calls[0][1] == ("ocean_current_velocity", "ocean_current_direction")


def test_wind_field_honors_the_units_the_api_labels(monkeypatch):
    """The live marine API answers ocean_current_velocity in km/h whatever the
    docs say; a grid that assumed m/s would ship vectors 3.6x too strong."""
    main._CACHE.clear()
    _, fake = _wf_upstream(current=(3.6, 180.0, "m/s"))
    monkeypatch.setattr(main, "_fetch_open_meteo_grid_chunk", fake)
    data = client.get("/api/v1/wind-field", params={"fields": "current"}).json()
    # Same number, labelled m/s this time: no /3.6 applied, so 3.6 not 1.0.
    assert data["fields"]["current"]["v"][0] == 3.6


def test_wind_field_land_points_stay_null_not_zero(monkeypatch):
    """The box covers inland Oman too. A land point must be null ("no water,
    no particle"), never 0 ("measured calm") — the frontend decides on that."""
    main._CACHE.clear()
    _, fake = _wf_upstream(null_coords={(26.5, 52.0)})
    monkeypatch.setattr(main, "_fetch_open_meteo_grid_chunk", fake)
    data = client.get("/api/v1/wind-field", params={"fields": "current"}).json()
    assert data["fields"]["current"]["u"][0] is None      # row 0, col 0: inland
    assert data["fields"]["current"]["u"][1] == 0.0       # neighbour still measured


def test_wind_field_is_cached_under_its_ttl(monkeypatch):
    main._CACHE.clear()
    calls, fake = _wf_upstream()
    monkeypatch.setattr(main, "_fetch_open_meteo_grid_chunk", fake)
    first = client.get("/api/v1/wind-field").json()
    hits = len(calls)
    second = client.get("/api/v1/wind-field").json()
    assert first["cached"] is False and second["cached"] is True
    assert len(calls) == hits  # cache served: the upstream was not called again


def test_wind_field_partial_failure_ships_the_survivor(monkeypatch):
    main._CACHE.clear()
    _, fake = _wf_upstream(fail_base="marine")
    monkeypatch.setattr(main, "_fetch_open_meteo_grid_chunk", fake)
    res = client.get("/api/v1/wind-field")
    assert res.status_code == 200
    data = res.json()
    assert "wind" in data["fields"] and "current" not in data["fields"]
    assert "current" in data["note"]


def test_wind_field_total_failure_is_502_not_an_empty_grid(monkeypatch):
    main._CACHE.clear()
    _, fake = _wf_upstream(fail_base="open-meteo")
    monkeypatch.setattr(main, "_fetch_open_meteo_grid_chunk", fake)
    res = client.get("/api/v1/wind-field")
    assert res.status_code == 502
    main._CACHE.clear()


def test_wind_field_rejects_unknown_field_names():
    res = client.get("/api/v1/wind-field", params={"fields": "wind,tides"})
    assert res.status_code == 422


