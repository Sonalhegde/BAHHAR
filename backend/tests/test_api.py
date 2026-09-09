from fastapi.testclient import TestClient
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
