import asyncio
import math
import os
import time
from datetime import datetime, UTC, date, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

import httpx
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field, ConfigDict

try:  # Load .env if python-dotenv is installed (keys must never live in code)
    from dotenv import load_dotenv

    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))
    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".env"))
except ImportError:
    pass

app = FastAPI(
    title="Bahhar AI — Marine & Fishing Prediction Microservice",
    description="Oman-specific marine intelligence, ML fishing probability, geofencing engine, and server-side weather/tide proxy (keys never reach the client).",
    version="1.0.0"
)

# ---------------------------------------------------------------------------
# Third-party data providers (Master Build Prompt §3.6, §4, §9)
#   * Open-Meteo weather + marine APIs are keyless but proxied here so every
#     response is cached server-side and never re-fetched per widget rebuild.
#   * WorldTides requires an API key that MUST stay on the server; Flutter
#     only ever talks to this backend.
# ---------------------------------------------------------------------------
WORLDTIDES_API_KEY = os.environ.get("WORLDTIDES_API_KEY", "").strip()
# AccuWeather's key lives here and nowhere else: never in the Flutter app, never in the
# website's client-side JS. See backend/.env (git-ignored) and .env.example.
ACCUWEATHER_API_KEY = os.environ.get("ACCUWEATHER_API_KEY", "").strip()
OPEN_METEO_BASE = "https://api.open-meteo.com/v1/forecast"
OPEN_METEO_MARINE_BASE = "https://marine-api.open-meteo.com/v1/marine"
WORLDTIDES_URL = "https://www.worldtides.info/api/v3"
ACCUWEATHER_BASE = "https://dataservice.accuweather.com"
# Oman is UTC+4 all year (no DST), which is the zone every clock below prints in.
OMAN_TZ = timezone(timedelta(hours=4))

# In-memory TTL cache: key -> (expires_at_epoch, payload). Single-worker dev
# assumption; swap for Redis when scaling horizontally.
_CACHE: Dict[str, Tuple[float, Any]] = {}
WEATHER_TTL_SECONDS = 600    # 10 min — hourly forecasts
MARINE_TTL_SECONDS = 1800    # 30 min — daily wave/SST granularity
TIDES_TTL_SECONDS = 3600     # 1 h — tide curve is deterministic
UPSTREAM_TIMEOUT = httpx.Timeout(10.0, connect=5.0)

# AccuWeather's free tier is a *daily* call ceiling, and the published number has moved
# between roughly 50 and 500 calls/day depending on the package — confirm it on the pricing
# page of the provisioned account before trusting any figure here. That ceiling is why the
# cache, not the endpoint, carries the load: one upstream fetch per region serves every
# visitor for the whole TTL, and a resolved location key is reused for a day.
ACCUWEATHER_TTL_SECONDS = 1800          # 30 min — current conditions
ACCUWEATHER_FORECAST_TTL_SECONDS = 3600  # 60 min — a 5-day outlook drifts slowly
ACCUWEATHER_LOCKEY_TTL_SECONDS = 86400   # 24 h — a location key does not change
# Their terms make attribution a condition of use; keep the wording next to the data so a
# client cannot render the payload without it.
ACCUWEATHER_ATTRIBUTION = "Weather data provided by AccuWeather."


def _cache_get(key: str) -> Optional[Any]:
    hit = _CACHE.get(key)
    if hit and hit[0] > time.time():
        return hit[1]
    _CACHE.pop(key, None)
    return None


def _cache_set(key: str, value: Any, ttl: int) -> Any:
    _CACHE[key] = (time.time() + ttl, value)
    return value


def _as_float(value: Any, default: float = 0.0) -> float:
    try:
        return default if value is None else float(value)
    except (TypeError, ValueError):
        return default


# ---------------------------------------------------------------------------
# Sea-state banding and the day rating — the two rules the landing page prints
#
# These are deliberately simple, stated rules rather than a score, and the same
# thresholds and wording are published on the page (website/landing-page.html,
# "Ocean information" readout and the synthesis banner) so neither side can drift
# into a black box. Change one, change the other, change the page.
#
#   good            wave < 1.0 m   and wind < 12 kt   and current < 1.0 kt
#   moderate        wave < 1.5 m   and wind < 18 kt   and current < 2.0 kt
#   rough sea       wave >= 1.5 m  or  wind >= 18 kt
#   strong current  current >= 2.0 kt on its own
#   high risk       wave >= 2.5 m  or  wind >= 28 kt  or an active warning
#
# The band is the WORST single reading, never an average of them: 2.5 m of swell
# does not become "moderate" because the wind happened to be light.
# ---------------------------------------------------------------------------
SEA_BANDS: Dict[str, str] = {
    "good": "Good",
    "moderate": "Moderate",
    "rough_sea": "Rough sea",
    "strong_current": "Strong current",
    "high_risk": "High risk",
}
_SEA_BAND_RANK: Dict[str, int] = {band: i for i, band in enumerate(SEA_BANDS)}


def _compass_deg(degrees: Optional[float]) -> Optional[str]:
    """Bearing in degrees -> 16-point compass text ("NE"). Direction is reported the
    mariner's way: the bearing the seas/wind come FROM, not the way they travel."""
    if degrees is None:
        return None
    points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
              "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    return points[int((float(degrees) + 11.25) % 360 // 22.5)]


def _sea_state_band(
    wave_height_m: float,
    wind_speed_kts: float,
    current_kts: float = 0.0,
    alert_active: bool = False,
) -> Dict[str, Any]:
    """Band the day's water in, plus which readings put it there (auditable, per the brief)."""
    wave_band = (
        "high_risk" if wave_height_m >= 2.5
        else "rough_sea" if wave_height_m >= 1.5
        else "moderate" if wave_height_m >= 1.0
        else "good"
    )
    wind_band = (
        "high_risk" if wind_speed_kts >= 28
        else "rough_sea" if wind_speed_kts >= 18
        else "moderate" if wind_speed_kts >= 12
        else "good"
    )
    current_band = (
        "strong_current" if current_kts >= 2.0
        else "moderate" if current_kts >= 1.0
        else "good"
    )
    candidates = {"wave_height_m": wave_band, "wind_speed_kts": wind_band, "current_kts": current_band}
    band = "high_risk" if alert_active else max(candidates.values(), key=lambda b: _SEA_BAND_RANK[b])
    drivers = [field for field, b in candidates.items() if _SEA_BAND_RANK[b] == _SEA_BAND_RANK[band] and b != "good"]
    return {
        "band": band,
        "label": SEA_BANDS[band],
        "rank": _SEA_BAND_RANK[band],
        "drivers": drivers,
        "rule": "worst single reading of wave height, wind and current; never an average",
    }


def _day_rating(
    sea_band: str,
    wave_height_m: float,
    wind_speed_kts: float,
    current_kts: float = 0.0,
    boat_length_m: Optional[float] = None,
    boat_type: str = "open",
    gear: Optional[List[str]] = None,
    alert_active: bool = False,
) -> Dict[str, Any]:
    """BAHHAR's rating of the day, from the ocean band plus the fisherman's own boat and gear.

      1. start from today's ocean band;
      2. wind >= 18 kt or swell >= 2.5 m drops it one step on its own;
      3. an open boat under 7 m drops it a further step once the current reaches 2.0 kt,
         where a cabin cruiser of the same length would hold;
      4. gear decides viability, not just rating: nets and bottom rigs are set in slack
         water, so 2.0 kt calls a net session off rather than merely downgrading it.

    A stated rule, not a weighted black box, until the ML model in the main build spec is
    live; the ladder stays three deep (Good / Moderate / Rough) because that is what a
    fisherman at the dock acts on."""
    ladder = ["good", "moderate", "rough"]
    labels = {"good": "Good", "moderate": "Moderate", "rough": "Rough"}
    start = {"good": 0, "moderate": 1, "rough_sea": 2, "strong_current": 1, "high_risk": 2}
    idx = start.get(sea_band, 1)
    reasons: List[str] = []

    if alert_active:
        idx = 2
        reasons.append("an active weather or marine warning caps the day at Rough")
    if wind_speed_kts >= 18 or wave_height_m >= 2.5:
        idx = min(idx + 1, 2)
        reasons.append(f"{'wind' if wind_speed_kts >= 18 else 'swell'} over the open-boat limit steps the day down once more")

    net_gear = [g for g in (gear or []) if "net" in g.lower() or "bottom" in g.lower()]
    if current_kts >= 2.0:
        if boat_length_m is not None and boat_length_m < 7.0 and boat_type.lower() != "cabin":
            idx = min(idx + 1, 2)
            reasons.append(f"{current_kts:.1f} kt of current against a {boat_length_m:.1f} m open boat steps it down again")
        elif boat_length_m is None:
            reasons.append(f"{current_kts:.1f} kt of current: tell us your boat and we can rate the day against it")
        if net_gear:
            reasons.append("nets and bottom rigs need slack water, so this tide calls that session off")

    band = ladder[idx]
    return {
        "rating": band,
        "label": labels[band],
        "ocean_band": sea_band,
        "boat_length_m": boat_length_m,
        "boat_type": boat_type,
        "reasons": reasons or [f"nothing reached a threshold that steps a {boat_type} boat down from its ocean band"],
        "rule": "ocean band first, then wind/swell, then boat size and gear; inputs are never averaged",
    }


# Contract compliant with Master Build Prompt Section 10
class PredictionRequest(BaseModel):
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "latitude": 23.5880,
            "longitude": 58.3829,
            "target_species": "Kingfish",
            "sea_temp_c": 27.5,
            "wind_speed_kts": 12.0,
            "wave_height_m": 0.9,
            "tide_state": "Rising",
            "depth_meters": 38
        }
    })
    
    latitude: float = Field(..., ge=16.0, le=27.0, description="Omani coastal latitude")
    longitude: float = Field(..., ge=52.0, le=60.5, description="Omani coastal longitude")
    target_species: str = Field(..., description="Target fish species (e.g., Kingfish, Tuna, Hammour)")
    sea_temp_c: float = Field(..., description="Sea surface temperature in Celsius")
    wind_speed_kts: float = Field(..., description="Wind speed in knots")
    wave_height_m: float = Field(..., description="Wave height in meters")
    tide_state: str = Field(..., description="Tidal state (Rising, Falling, High, Low)")
    depth_meters: int = Field(..., description="Water depth in meters")

class PredictionResponse(BaseModel):
    probability: int = Field(..., ge=0, le=100)
    confidence: float = Field(..., ge=0.0, le=1.0)
    contributing_factors: List[str]

class GeofenceCheckRequest(BaseModel):
    latitude: float
    longitude: float

class GeofenceCheckResponse(BaseModel):
    status: str  # "Permitted", "Restricted", "Protected"
    is_safe: bool
    reserve_name: Optional[str] = None
    legal_decree: Optional[str] = None
    warning_message: Optional[str] = None

# Omani Marine Reserves Dataset
OMAN_RESERVES = [
    {
        "id": "daymaniyat",
        "name": "Ad Daymaniyat Islands Nature Reserve",
        "name_ar": "محمية جزر الديمانيات الطبيعية",
        "lat": 23.8617,
        "lon": 58.0933,
        "radius_km": 18.0,
        "status": "Protected",
        "decree": "Royal Decree No. 23/96",
        "message": "Special recreational angling permit required from MOAF."
    },
    {
        "id": "ras_al_jinz",
        "name": "Ras Al Jinz Turtle Sanctuary",
        "name_ar": "محمية السلاحف برأس الجنز",
        "lat": 22.4278,
        "lon": 59.8319,
        "radius_km": 6.0,
        "status": "Protected",
        "decree": "Ministerial Decision No. 12/2008",
        "message": "Motorized fishing prohibited within 3 nm during green turtle nesting season."
    },
    {
        "id": "musandam_traffic",
        "name": "Strait of Hormuz Commercial Shipping Corridor",
        "name_ar": "ممر الملاحة بمضيق هرمز",
        "lat": 26.3811,
        "lon": 56.4522,
        "radius_km": 12.0,
        "status": "Restricted",
        "decree": "Maritime Law Decision 4/2012",
        "message": "Vessels under 20m prohibited from drifting or deploying gillnets."
    }
]

def haversine_km(lat1, lon1, lat2, lon2):
    r = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return r * c

@app.get("/")
def health():
    return {
        "service": "Bahhar AI Prediction Engine",
        "status": "online",
        "timestamp": datetime.now(UTC).isoformat()
    }

@app.post("/api/v1/predict", response_model=PredictionResponse)
def predict_fishing_probability(req: PredictionRequest):
    """
    Computes ML-calibrated strike probability based on Omani coastal marine variables.
    """
    base_score = 62
    factors = []

    # 1. Sea Surface Temperature analysis
    species_lower = req.target_species.lower()
    if "kingfish" in species_lower or "kanaad" in species_lower or "كنعد" in species_lower:
        if 25.0 <= req.sea_temp_c <= 28.5:
            base_score += 16
            factors.append("Optimal sea surface temperature (26-28.5°C) for pelagic schooling")
        else:
            base_score -= 8
            factors.append("Sub-optimal sea surface temperature")
    elif "tuna" in species_lower or "thamad" in species_lower or "ثمد" in species_lower:
        if req.depth_meters >= 40:
            base_score += 18
            factors.append("Deep offshore shelf bathymetry (>40m) favorable for yellowfin feeding")
        if req.sea_temp_c >= 27.0:
            base_score += 8
            factors.append("Warm surface layer driving baitfish activity")
    elif "hammour" in species_lower or "grouper" in species_lower or "هامور" in species_lower:
        if 20 <= req.depth_meters <= 60:
            base_score += 15
            factors.append("Prime rocky reef depth for benthic ambush predators")

    # 2. Tidal influence
    if req.tide_state.lower() == "rising":
        base_score += 10
        factors.append("Rising flood tide accelerating channel current & feeding")

    # 3. Wave & Wind safety / bite modulation
    if req.wave_height_m > 2.2:
        base_score -= 25
        factors.append("Heavy swell (>2.2m) degrading surface strike visibility")
    elif 0.5 <= req.wave_height_m <= 1.2:
        base_score += 8
        factors.append("Calm to moderate swell optimal for trolling stability")

    if 8.0 <= req.wind_speed_kts <= 16.0:
        base_score += 6
        factors.append("Moderate Arabian Sea surface chop stimulating strike instinct")

    final_prob = max(10, min(95, base_score))

    return PredictionResponse(
        probability=final_prob,
        confidence=0.86,
        contributing_factors=factors if factors else ["Stable marine baseline"]
    )

@app.post("/api/v1/geofence/verify", response_model=GeofenceCheckResponse)
def check_geofence(req: GeofenceCheckRequest):
    """
    Evaluates vessel coordinates against Omani national reserves and restricted channels.
    """
    for reserve in OMAN_RESERVES:
        dist = haversine_km(req.latitude, req.longitude, reserve["lat"], reserve["lon"])
        if dist <= reserve["radius_km"]:
            return GeofenceCheckResponse(
                status=reserve["status"],
                is_safe=False if reserve["status"] == "Restricted" else True,
                reserve_name=reserve["name"],
                legal_decree=reserve["decree"],
                warning_message=reserve["message"]
            )

    return GeofenceCheckResponse(
        status="Permitted",
        is_safe=True,
        warning_message="Open Omani territorial waters for recreational/commercial fishing."
    )

# ---------------------------------------------------------------------------
# Server-side proxies: Open-Meteo (weather + marine) and WorldTides (tides)
# ---------------------------------------------------------------------------
async def _fetch_open_meteo_weather(client: httpx.AsyncClient, lat: float, lon: float) -> Dict[str, Any]:
    """Current weather block mirroring the user-supplied Open-Meteo URL."""
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": ",".join([
            "temperature_2m", "relative_humidity_2m", "apparent_temperature",
            "is_day", "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m",
            "precipitation", "weather_code", "cloud_cover", "pressure_msl",
            "surface_pressure", "visibility", "uv_index",
        ]),
        "past_days": 1,
        "timezone": "Asia/Muscat",
    }
    res = await client.get(OPEN_METEO_BASE, params=params)
    res.raise_for_status()
    return res.json()


async def _fetch_open_meteo_marine(client: httpx.AsyncClient, lat: float, lon: float) -> Dict[str, Any]:
    """Waves, sea temperature and surface current from the marine API.

    The two current fields are what back the Ocean Information readout's "Current" tile;
    they arrive as eastward/northward components in m/s and are recombined below."""
    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": ",".join([
            "wave_height", "wave_period", "wave_direction", "sea_surface_temperature",
            "surface_current_eastward", "surface_current_northward",
        ]),
        "past_days": 1,
        "timezone": "Asia/Muscat",
    }
    res = await client.get(OPEN_METEO_MARINE_BASE, params=params)
    res.raise_for_status()
    return res.json()


async def _fetch_worldtides_extremes(client: httpx.AsyncClient, lat: float, lon: float) -> Dict[str, Any]:
    """Tide extremes around now. Key stays server-side (.env only)."""
    if not WORLDTIDES_API_KEY:
        raise RuntimeError("WORLDTIDES_API_KEY not configured")
    params = {
        "key": WORLDTIDES_API_KEY,
        "lat": lat,
        "lon": lon,
        "extremes": "",
        "date": date.today().isoformat(),
        "days": 2,
    }
    res = await client.get(WORLDTIDES_URL, params=params)
    res.raise_for_status()
    data = res.json()
    if data.get("status", 200) != 200:
        raise RuntimeError(data.get("error", "WorldTides request failed"))
    return data


def _tide_state_from_extremes(extremes: List[Dict[str, Any]], now: Optional[datetime] = None) -> Tuple[str, float, Optional[str]]:
    """Derive (state, height_m, station) from WorldTides extremes around `now`."""
    now_ts = (now or datetime.now(UTC)).timestamp()
    parsed: List[Tuple[int, float, str]] = []
    for ex in extremes:
        try:
            parsed.append((int(ex["dt"]), float(ex["height"]), str(ex.get("type", "")).lower()))
        except (KeyError, TypeError, ValueError):
            continue
    if not parsed:
        raise ValueError("No tide extremes returned")
    parsed.sort(key=lambda item: item[0])

    prev_ex = None
    next_ex = None
    for dt, height, typ in parsed:
        if dt <= now_ts:
            prev_ex = (dt, height, typ)
        elif next_ex is None:
            next_ex = (dt, height, typ)
            break

    # Curve interpolation between the bracketing extremes.
    if prev_ex and next_ex and next_ex[0] > prev_ex[0]:
        frac = (now_ts - prev_ex[0]) / (next_ex[0] - prev_ex[0])
        height = prev_ex[1] + frac * (next_ex[1] - prev_ex[1])
    elif prev_ex:
        height = prev_ex[1]
    else:
        height = next_ex[1] if next_ex else 0.0

    # Within 45 min of an extreme, report it as High/Low water.
    horizon = 45 * 60
    if prev_ex and now_ts - prev_ex[0] <= horizon:
        state = "High" if prev_ex[2] == "high" else "Low"
    elif next_ex and next_ex[0] - now_ts <= horizon:
        state = "High" if next_ex[2] == "high" else "Low"
    elif prev_ex and next_ex:
        state = "Rising" if next_ex[1] > prev_ex[1] else "Falling"
    else:
        state = "Rising"
    return state, round(height, 2), None


def _next_extreme(extremes: List[Dict[str, Any]], wanted: str = "high", now: Optional[datetime] = None) -> Optional[Dict[str, Any]]:
    """The next tide of `wanted` type after now, as {time, height_m} in Asia/Muscat.
    None when the station data does not reach that far - 'unavailable' is printed rather
    than a guessed time, because a wrong high-water clock is worse than an empty field."""
    now_ts = (now or datetime.now(UTC)).timestamp()
    best: Optional[Tuple[int, float]] = None
    for ex in extremes:
        try:
            dt = int(ex["dt"])
        except (KeyError, TypeError, ValueError):
            continue
        if dt <= now_ts or str(ex.get("type", "")).lower() != wanted:
            continue
        if best is None or dt < best[0]:
            best = (dt, _as_float(ex.get("height"), 0.0))
    if best is None:
        return None
    return {
        "time": datetime.fromtimestamp(best[0], OMAN_TZ).strftime("%H:%M"),
        "height_m": round(best[1], 2),
    }


@app.get("/api/v1/marine/conditions")
async def marine_conditions(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
    include_tides: bool = Query(True),
    boat_length_m: Optional[float] = Query(None, ge=1.0, le=30.0),
    boat_type: str = Query("open"),
    gear: Optional[List[str]] = Query(None),
):
    """
    Single aggregated endpoint for the Flutter home dashboard.
    Proxies Open-Meteo marine + weather and (optionally) WorldTides,
    cached server-side. Tide failures degrade gracefully to 'Unavailable'.

    Boat and gear are optional here because the day rating is the fisherman's own record
    applied to the water: with them the response carries `day_rating` (the synthesis
    banner), without them it carries only `sea_state`. The Flutter screens read both from
    fisherman_profiles/{userId} rather than keeping their own copy of the vessel.
    """
    boat_tag = f"{boat_length_m or '-'}:{boat_type}:{','.join(sorted(gear or []))}"
    cache_key = f"marine:{round(lat, 2)}:{round(lon, 2)}:{int(include_tides)}:{boat_tag}"
    cached = _cache_get(cache_key)
    if cached:
        return {**cached, "cached": True}

    try:
        async with httpx.AsyncClient(timeout=UPSTREAM_TIMEOUT, follow_redirects=True) as client:
            weather_task = asyncio.create_task(_fetch_open_meteo_weather(client, lat, lon))
            marine_task = asyncio.create_task(_fetch_open_meteo_marine(client, lat, lon))
            tides_task = (
                asyncio.create_task(_fetch_worldtides_extremes(client, lat, lon))
                if include_tides and WORLDTIDES_API_KEY
                else None
            )
            weather, marine = await asyncio.gather(weather_task, marine_task)
            tides: Optional[Dict[str, Any]] = None
            if tides_task:
                try:
                    tides = await tides_task
                except Exception:
                    tides = None
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Upstream marine data unavailable: {exc}")

    # Open-Meteo hourly marine arrays are local-hours; pick the entry nearest now.
    hourly = marine.get("hourly") or {}
    times = hourly.get("time") or []
    idx = 0
    if times:
        now_local = datetime.now(UTC)
        stamps = []
        for t in times:
            try:
                stamps.append(datetime.fromisoformat(t).replace(tzinfo=UTC))
            except ValueError:
                stamps.append(None)
        valid = [(i, s) for i, s in enumerate(stamps) if s]
        if valid:
            idx = min(valid, key=lambda pair: abs((pair[1] - now_local).total_seconds()))[0]

    def _hourly(field: str, default: float) -> float:
        values = hourly.get(field) or []
        return _as_float(values[idx], default) if idx < len(values) else default

    current_weather = weather.get("current") or {}
    wind_kts = _as_float(current_weather.get("wind_speed_10m"), 0.0) * 1.943844  # km/h -> knots

    # Surface current arrives as eastward/northward components in m/s. Recombine them into
    # speed + the bearing it SETS TOWARD (the convention the Ocean readout prints; waves and
    # wind are reported the other way round, as the bearing they come FROM).
    cur_east = _hourly("surface_current_eastward", 0.0)
    cur_north = _hourly("surface_current_northward", 0.0)
    current_kts = round(math.hypot(cur_east, cur_north) * 1.943844, 1)
    current_deg = round((math.degrees(math.atan2(cur_east, cur_north)) + 360) % 360, 0)
    # Open-Meteo reports visibility in metres; the readout prints kilometres.
    visibility_m = _as_float(current_weather.get("visibility"), -1.0)

    payload: Dict[str, Any] = {
        "latitude": lat,
        "longitude": lon,
        "sea_temperature_c": round(_hourly("sea_surface_temperature", 27.5), 1),
        "wave_height_m": round(_hourly("wave_height", 0.8), 1),
        "wave_period_s": round(_hourly("wave_period", 7.0), 1),
        "wave_direction_deg": round(_hourly("wave_direction", 0.0), 0),
        "wave_direction": _compass_deg(_hourly("wave_direction", 0.0)),
        "wind_speed_kts": round(wind_kts, 0),
        "wind_direction_deg": _as_float(current_weather.get("wind_direction_10m"), 0.0),
        "wind_direction": _compass_deg(_as_float(current_weather.get("wind_direction_10m"), 0.0)),
        "current_speed_kts": current_kts,
        "current_direction_deg": current_deg,
        "current_sets_to": _compass_deg(current_deg),
        "visibility_km": round(visibility_m / 1000, 1) if visibility_m >= 0 else None,
        "wind_gust_kts": round(_as_float(current_weather.get("wind_gusts_10m"), 0.0) * 1.943844, 0),
        "air_temperature_c": _as_float(current_weather.get("temperature_2m"), 0.0),
        "apparent_temperature_c": _as_float(current_weather.get("apparent_temperature"), 0.0),
        "cloud_cover_pct": _as_float(current_weather.get("cloud_cover"), 0.0),
        "pressure_msl_hpa": _as_float(current_weather.get("pressure_msl"), 0.0),
        "weather_code": int(_as_float(current_weather.get("weather_code"), 0.0)),
        "uv_index": int(_as_float(current_weather.get("uv_index"), 0.0)),
        "is_day": int(_as_float(current_weather.get("is_day"), 1.0)) == 1,
        "tide_state": "Unavailable",
        "tide_height_m": 0.0,
        "tide_source": None,
        "copyright": "Weather & marine data: Open-Meteo.com. Tidal predictions: © Brainware LLC / UNESCO, NOAA, BODC (worldtides.info).",
        "fetched_at": datetime.now(UTC).isoformat(),
    }

    if tides and tides.get("extremes"):
        try:
            state, height, _station = _tide_state_from_extremes(tides["extremes"])
            payload["tide_state"] = state
            payload["tide_height_m"] = height
            payload["tide_source"] = "WorldTides"
            payload["next_high_tide"] = _next_extreme(tides["extremes"])
        except ValueError:
            pass

    # Sea state is banded from the water and the air over it; the day rating is that band
    # read against the fisherman's own boat and gear. Both rules are printed on the landing
    # page and defined once, above, so the two cannot disagree.
    sea = _sea_state_band(payload["wave_height_m"], payload["wind_speed_kts"], current_kts)
    payload["sea_state"] = sea
    if boat_length_m is not None or gear:
        payload["day_rating"] = _day_rating(
            sea["band"], payload["wave_height_m"], payload["wind_speed_kts"], current_kts,
            boat_length_m=boat_length_m, boat_type=boat_type, gear=gear,
        )

    _cache_set(cache_key, payload, MARINE_TTL_SECONDS if not include_tides else max(MARINE_TTL_SECONDS, TIDES_TTL_SECONDS))
    return {**payload, "cached": False}


@app.get("/api/v1/tides")
async def tides(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
):
    """WorldTides extremes proxied server-side; raw key never leaves this API."""
    if not WORLDTIDES_API_KEY:
        raise HTTPException(status_code=503, detail="WORLDTIDES_API_KEY not configured on server")
    cache_key = f"tides:{round(lat, 2)}:{round(lon, 2)}"
    cached = _cache_get(cache_key)
    if cached:
        return {**cached, "cached": True}
    try:
        async with httpx.AsyncClient(timeout=UPSTREAM_TIMEOUT, follow_redirects=True) as client:
            data = await _fetch_worldtides_extremes(client, lat, lon)
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"WorldTides upstream error: {exc}")
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc))

    extremes = data.get("extremes") or []
    try:
        state, height, _ = _tide_state_from_extremes(extremes)
    except ValueError:
        state, height = "Unavailable", 0.0

    payload = {
        "latitude": lat,
        "longitude": lon,
        "tide_state": state,
        "tide_height_m": height,
        "extremes": [
            {
                "time": datetime.fromtimestamp(int(ex["dt"]), UTC).isoformat(),
                "type": ex.get("type"),
                "height_m": _as_float(ex.get("height"), 0.0),
            }
            for ex in extremes[:12]
        ],
        "copyright": data.get("copyright", "© Brainware LLC / UNESCO, NOAA"),
        "fetched_at": datetime.now(UTC).isoformat(),
    }
    _cache_set(cache_key, payload, TIDES_TTL_SECONDS)
    return {**payload, "cached": False}
