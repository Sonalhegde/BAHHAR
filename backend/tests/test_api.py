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

