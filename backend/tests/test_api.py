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
from datetime import datetime, UTC, timedelta

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
    assert data["wind_speed_kts"] == 28  # 14.4 km/h * 1.943844
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
            "surface_current_eastward": [0.0], "surface_current_northward": [-0.3],
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
    assert data["sea_state"]["drivers"] == ["wave_height_m", "wind_speed_kts"]
    assert data["day_rating"]["ocean_band"] == "moderate"
    assert "next_high_tide" not in data              # no tide station: field absent, not guessed


def test_weather_endpoint_serves_the_documented_mock_shape(monkeypatch):
    main._CACHE.clear()
    monkeypatch.setattr(main, "ACCUWEATHER_API_KEY", "")
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
    assert "AccuWeather is not connected" in data["note"]

    res2 = client.get("/api/v1/weather", params={"lat": 23.61, "lon": 58.54})
    assert res2.json()["cached"] is True

