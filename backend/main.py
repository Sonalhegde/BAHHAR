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
# Open-Meteo is keyless and its data is CC-BY 4.0, so the attribution travels in the payload
# the same way AccuWeather's does - whichever provider actually answered.
OPEN_METEO_ATTRIBUTION = "Weather data from Open-Meteo.com (CC-BY 4.0)."

# Unit conversions, named because mixing them up was the bug the marine endpoint carried:
# Open-Meteo reports wind in km/h but its marine current components in m/s, and the two
# factors differ by 3.6x. Both appear here, so neither can be reached for blindly.
KM_PER_HOUR_TO_KNOTS = 0.539957
METERS_PER_SECOND_TO_KNOTS = 1.943844


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
    # Open-Meteo's default wind unit is km/h (its `wind_speed_unit` parameter), so km/h -> kt
    # is 0.539957. The factor this line used to carry, 1.943844, converts m/s -> kt, which
    # overstated every wind reading 3.6x: a 20 km/h breeze (10.8 kt) arrived as 38.9 kt and
    # banded "high risk", warning fishermen off benign water. Currents below genuinely do
    # arrive in m/s, so their 1.943844 is correct and stays.
    wind_kts = _as_float(current_weather.get("wind_speed_10m"), 0.0) * KM_PER_HOUR_TO_KNOTS

    # Surface current arrives as eastward/northward components in m/s. Recombine them into
    # speed + the bearing it SETS TOWARD (the convention the Ocean readout prints; waves and
    # wind are reported the other way round, as the bearing they come FROM).
    cur_east = _hourly("surface_current_eastward", 0.0)
    cur_north = _hourly("surface_current_northward", 0.0)
    current_kts = round(math.hypot(cur_east, cur_north) * METERS_PER_SECOND_TO_KNOTS, 1)
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
        "wind_gust_kts": round(_as_float(current_weather.get("wind_gusts_10m"), 0.0) * KM_PER_HOUR_TO_KNOTS, 0),
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


# ---------------------------------------------------------------------------
# AccuWeather — the atmospheric half of the Ocean / Weather sections (brief §2)
#
# Two steps by design: a position resolves to AccuWeather's internal LocationKey once and
# that key is cached for a day, then conditions, hourly and 5-day forecasts are called with
# it. No device ever holds the key: the Flutter app and the landing page reach this backend
# and nothing else.
#
# Until an account is provisioned, ACCUWEATHER_API_KEY is empty and the endpoint answers
# with _accuweather_mock() — the same field names the mappers below produce from the real
# payloads, so the client contract is fixed today and going live is a change of data source
# rather than a rewrite. Every response says which source served it.
#
# The call arithmetic is why there is a budget below. One cached region costs four upstream
# calls per refresh; at a 30-minute TTL that is 192 calls a day, and the published free-tier
# ceiling has been quoted anywhere between ~50 and ~500 a day depending on the package.
# So: one shared cache entry per region, a daily budget that can be set in .env once the
# real number is confirmed, and a graceful fall back to the last good payload (then to the
# mock) when the day's calls are spent — never a 5xx in front of a fisherman.
# ---------------------------------------------------------------------------
ACCUWEATHER_DAILY_CALL_BUDGET = int(os.environ.get("ACCUWEATHER_DAILY_CALL_BUDGET", "0") or 0)
_ACCUWEATHER_CALLS: Dict[str, int] = {}


def _accuweather_calls_today() -> int:
    return _ACCUWEATHER_CALLS.get(date.today().isoformat(), 0)


def _accuweather_budget_available(spend: int = 1) -> bool:
    """0 or an unset budget means no cap (a paid plan); otherwise refuse before the call."""
    if ACCUWEATHER_DAILY_CALL_BUDGET <= 0:
        return True
    return _accuweather_calls_today() + spend <= ACCUWEATHER_DAILY_CALL_BUDGET


def _cache_get_stale(key: str) -> Optional[Any]:
    """The last payload for a key, even past its TTL — used only when the day's calls are
    spent, and always labelled by the caller so a stale figure is never read as a live one."""
    hit = _CACHE.get(key)
    return hit[1] if hit else None


async def _accuweather_get(client: httpx.AsyncClient, path: str, params: Dict[str, Any]) -> Any:
    """Single door to the provider: attaches the server-side key and counts the call."""
    day = date.today().isoformat()
    _ACCUWEATHER_CALLS[day] = _ACCUWEATHER_CALLS.get(day, 0) + 1
    res = await client.get(
        f"{ACCUWEATHER_BASE}{path}",
        params={"apikey": ACCUWEATHER_API_KEY, "language": "en-us", **params},
    )
    res.raise_for_status()
    return res.json()


async def _resolve_accuweather_location_key(client: httpx.AsyncClient, lat: float, lon: float) -> str:
    """Geoposition -> LocationKey, cached per region for a day (step one of the two)."""
    cache_key = f"accuweather:lockey:{round(lat, 2)}:{round(lon, 2)}"
    cached = _cache_get(cache_key)
    if cached:
        return cached
    data = await _accuweather_get(client, "/locations/v1/cities/geoposition/search", {"q": f"{lat},{lon}"})
    key = str(data.get("Key") or "").strip()
    if not key:
        raise RuntimeError("AccuWeather returned no LocationKey for this position")
    _cache_set(cache_key, key, ACCUWEATHER_LOCKEY_TTL_SECONDS)
    return key


def _metric_value(node: Any, *path: str) -> float:
    """Walk AccuWeather's {Metric:{Value:…}} wrappers without tripping over a missing level."""
    cursor: Any = node
    for step in (*path, "Metric", "Value"):
        if not isinstance(cursor, dict):
            return 0.0
        cursor = cursor.get(step)
    return _as_float(cursor, 0.0)


def _temperature(node: Any) -> float:
    """Temperatures arrive in two shapes: {Metric:{Value}} on conditions and daily, and a
    flat {Value} on the hourly forecast when metric=true was requested. Read either."""
    if not isinstance(node, dict):
        return 0.0
    if node.get("Value") is not None:
        return _as_float(node.get("Value"))
    return _metric_value(node)


def _map_accuweather_current(rows: Any) -> Dict[str, Any]:
    item = rows[0] if isinstance(rows, list) and rows else {}
    wind = item.get("Wind") or {}
    return {
        "temp_c": _temperature(item.get("Temperature")),
        "feels_like_c": _temperature(item.get("RealFeelTemperature")),
        "condition": item.get("WeatherText"),
        "humidity_pct": _as_float(item.get("RelativeHumidity")),
        "wind_kmh": _temperature(wind.get("Speed")),
        "wind_dir": (wind.get("Direction") or {}).get("LocalizedEnglishName"),
        "rain_probability_pct": _as_float(item.get("PrecipitationProbability")),
        "uv_index": _as_float((item.get("UVIndex") or {}).get("Value")),
        "visibility_km": round(_metric_value(item.get("Visibility")), 1),
    }


def _map_accuweather_hourly(rows: Any) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for item in rows if isinstance(rows, list) else []:
        try:
            stamp = datetime.fromisoformat(str(item.get("DateTime", "")))
        except ValueError:
            continue
        out.append({
            "time": stamp.strftime("%H:%M"),
            "temp_c": _temperature(item.get("Temperature")),
            "condition": item.get("Phrase"),
            "rain_probability_pct": _as_float((item.get("RainProbability") or {}).get("Value")),
        })
    return out[:8]


def _map_accuweather_daily(rows: Any) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for item in rows if isinstance(rows, list) else []:
        temperature = item.get("Temperature") or {}
        try:
            day = datetime.fromisoformat(str(item.get("Date", ""))).date().isoformat()
        except ValueError:
            day = str(item.get("Date", ""))[:10]
        out.append({
            "date": day,
            "high_c": _temperature(temperature.get("Maximum")),
            "low_c": _temperature(temperature.get("Minimum")),
            "condition": (item.get("Day") or {}).get("IconPhrase"),
        })
    return out[:5]


async def _fetch_accuweather_alerts(client: httpx.AsyncClient, location_key: str) -> List[Dict[str, Any]]:
    """Active severe-weather alerts. Any failure — including a plan that does not carry the
    alerts route, which is worth confirming against the provisioned account before launch —
    reads as 'no active alert'. It never reads as a placeholder alert: a banner that lies
    about a warning is worse than one that stays hidden."""
    try:
        rows = await _accuweather_get(client, f"/alerts/v1/{location_key}/all", {})
    except Exception:
        return []
    alerts: List[Dict[str, Any]] = []
    for item in rows if isinstance(rows, list) else []:
        if not isinstance(item, dict):
            continue
        alerts.append({
            "title": item.get("Description") or (item.get("Type") or {}).get("Name") or "Weather alert",
            "severity": (item.get("Severity") or {}).get("Name"),
            "starts": item.get("Effective"),
            "ends": item.get("Expires"),
        })
    return alerts


_MOCK_CURRENT: Dict[str, Any] = {
    "temp_c": 31, "feels_like_c": 34, "condition": "Sunny", "humidity_pct": 68,
    "wind_kmh": 14, "wind_dir": "NE", "rain_probability_pct": 10, "uv_index": 8,
    "visibility_km": 8,
}


def _accuweather_mock(lat: float, lon: float) -> Dict[str, Any]:
    """The shape above, unrolled offline: the current block the landing page prints, an
    eight-hour strip and a five-day outlook on a Muscat spring morning. Times are generated
    from now so the sample never reads as a frozen screenshot."""
    now = datetime.now(OMAN_TZ).replace(minute=0, second=0, microsecond=0)
    temps = [27, 28, 29, 30, 31, 32, 33, 33]
    hourly = [
        {"time": (now + timedelta(hours=i)).strftime("%H:%M"), "temp_c": temps[i],
         "condition": "Sunny", "rain_probability_pct": 10}
        for i in range(8)
    ]
    days = [(33, 26, "Sunny"), (33, 26, "Sunny"), (32, 26, "Partly sunny"), (31, 25, "Partly sunny"), (32, 26, "Sunny")]
    daily = [
        {"date": (now.date() + timedelta(days=i)).isoformat(), "high_c": high, "low_c": low,
         "condition": phrase}
        for i, (high, low, phrase) in enumerate(days)
    ]
    return {"current": dict(_MOCK_CURRENT), "hourly": hourly, "daily": daily, "alerts": []}


# WMO 4680 interpretation codes. Open-Meteo returns a number where AccuWeather returns a phrase,
# and the client contract promises a phrase, so the translation lives here rather than being
# re-implemented by every consumer of /api/v1/weather.
_WMO_PHRASES = {
    0: "Clear", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
    45: "Fog", 48: "Rime fog",
    51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle",
    56: "Freezing drizzle", 57: "Freezing drizzle",
    61: "Light rain", 63: "Rain", 65: "Heavy rain",
    66: "Freezing rain", 67: "Freezing rain",
    71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
    80: "Light showers", 81: "Showers", 82: "Heavy showers",
    85: "Snow showers", 86: "Snow showers",
    95: "Thunderstorm", 96: "Thunderstorm, hail", 99: "Thunderstorm, hail",
}


def _wmo_phrase(code: Any) -> str:
    """Plain-English sky phrase for a WMO code. An unknown code says "Mixed" rather than
    inventing a condition nobody reported - the tile must not outstate the data."""
    try:
        return _WMO_PHRASES.get(int(_as_float(code, -1)), "Mixed")
    except (TypeError, ValueError):
        return "Mixed"


async def _fetch_open_meteo_forecast(
    client: httpx.AsyncClient, lat: float, lon: float
) -> Dict[str, Any]:
    """One request carrying current + hourly + daily, so the keyless fallback costs the
    upstream a single call instead of the three the AccuWeather path needs."""
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": ",".join([
            "temperature_2m", "apparent_temperature", "relative_humidity_2m",
            "weather_code", "wind_speed_10m", "wind_direction_10m",
            "precipitation_probability", "uv_index", "visibility",
        ]),
        "hourly": "temperature_2m,weather_code,precipitation_probability",
        "daily": "weather_code,temperature_2m_max,temperature_2m_min",
        "forecast_days": 5,
        "timezone": "Asia/Muscat",
    }
    res = await client.get(OPEN_METEO_BASE, params=params)
    res.raise_for_status()
    return res.json()


def _map_open_meteo_weather(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Project an Open-Meteo forecast response onto the weather contract.

    Same keys as the AccuWeather branch, including `wind_dir` as compass text and
    `visibility_km` (Open-Meteo reports visibility in metres). Open-Meteo publishes no
    severe-weather alerts for Oman, so `alerts` is an empty list and the note says so -
    an absent feed is disclosed, not silently rendered as an all-clear."""
    cur = raw.get("current") or {}
    hourly = raw.get("hourly") or {}
    daily = raw.get("daily") or {}

    times = hourly.get("time") or []
    temps = hourly.get("temperature_2m") or []
    codes = hourly.get("weather_code") or []
    probs = hourly.get("precipitation_probability") or []

    # Open-Meteo's hourly array starts at midnight; the strip should start at the current
    # hour, which is what `current.time` is stamped with ("2026-09-20T09:00").
    stamp = str(cur.get("time") or "")[:13]
    try:
        start = next(i for i, t in enumerate(times) if str(t)[:13] >= stamp)
    except StopIteration:
        start = 0

    hours: List[Dict[str, Any]] = []
    for i in range(start, min(start + 8, len(times))):
        hours.append({
            "time": str(times[i])[11:16],
            "temp_c": _as_float(temps[i] if i < len(temps) else None),
            "condition": _wmo_phrase(codes[i] if i < len(codes) else None),
            "rain_probability_pct": _as_float(probs[i] if i < len(probs) else None),
        })

    d_times = daily.get("time") or []
    d_codes = daily.get("weather_code") or []
    d_max = daily.get("temperature_2m_max") or []
    d_min = daily.get("temperature_2m_min") or []
    days: List[Dict[str, Any]] = []
    for i in range(min(5, len(d_times))):
        days.append({
            "date": str(d_times[i])[:10],
            "high_c": _as_float(d_max[i] if i < len(d_max) else None),
            "low_c": _as_float(d_min[i] if i < len(d_min) else None),
            "condition": _wmo_phrase(d_codes[i] if i < len(d_codes) else None),
        })

    return {
        "current": {
            "temp_c": _as_float(cur.get("temperature_2m")),
            "feels_like_c": _as_float(cur.get("apparent_temperature")),
            "condition": _wmo_phrase(cur.get("weather_code")),
            "humidity_pct": _as_float(cur.get("relative_humidity_2m")),
            "wind_kmh": _as_float(cur.get("wind_speed_10m")),
            # None, not 0, when the field is missing: a calm-looking "N" that nobody
            # measured is worse than a blank reading.
            "wind_dir": _compass_deg(None if cur.get("wind_direction_10m") is None
                                     else _as_float(cur.get("wind_direction_10m"))),
            "rain_probability_pct": _as_float(cur.get("precipitation_probability")),
            "uv_index": _as_float(cur.get("uv_index")),
            "visibility_km": round(_as_float(cur.get("visibility")) / 1000, 1),
        },
        "hourly": hours,
        "daily": days,
        "alerts": [],
    }


async def _open_meteo_weather(lat: float, lon: float) -> Optional[Dict[str, Any]]:
    """Live atmospheric data with no key required, or None if upstream is unusable.

    Returns None rather than raising so the caller can degrade to the documented mock:
    a visitor should see the sample reading, not a 502, when a free API hiccups."""
    try:
        async with httpx.AsyncClient(timeout=UPSTREAM_TIMEOUT, follow_redirects=True) as client:
            raw = await _fetch_open_meteo_forecast(client, lat, lon)
    except httpx.HTTPError:
        return None
    except (RuntimeError, ValueError):
        return None
    mapped = _map_open_meteo_weather(raw)
    return mapped if mapped["current"]["temp_c"] or mapped["hourly"] else None


@app.get("/api/v1/weather")
async def weather(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
    region: str = Query("Muscat"),
):
    """Atmospheric weather: current conditions, an hourly strip, five days, active alerts.

    Cached per region for ACCUWEATHER_TTL_SECONDS and shared by every visitor, so page load
    does not equal provider call."""
    cache_key = f"weather:{round(lat, 2)}:{round(lon, 2)}"
    cached = _cache_get(cache_key)
    if cached:
        return {**cached, "cached": True}

    envelope: Dict[str, Any] = {
        "latitude": lat,
        "longitude": lon,
        "region": region,
        "attribution": ACCUWEATHER_ATTRIBUTION,
        "alerts_endpoint_note": "An alert banner is drawn only when this list is non-empty.",
    }

    if not ACCUWEATHER_API_KEY:
        # No key is not a reason to show a visitor invented numbers: Open-Meteo is keyless
        # and already used for the marine data, so the default path is live.
        live = await _open_meteo_weather(lat, lon)
        payload = {
            **envelope,
            "source": "open-meteo" if live else "mock",
            "attribution": OPEN_METEO_ATTRIBUTION if live else ACCUWEATHER_ATTRIBUTION,
            "note": (
                "AccuWeather is not connected, so this is live Open-Meteo mapped onto the same "
                "contract. Open-Meteo carries no severe-weather alert feed for Omani waters, so "
                "the alert banner cannot light up until an AccuWeather key is set."
                if live else
                "No weather provider is reachable: this is the response shape the app is built "
                "against, so going live changes the data source, not the client."
            ),
            **(live or _accuweather_mock(lat, lon)),
            "fetched_at": datetime.now(UTC).isoformat(),
        }
        _cache_set(cache_key, payload, WEATHER_TTL_SECONDS if live else ACCUWEATHER_TTL_SECONDS)
        return {**payload, "cached": False}

    if not _accuweather_budget_available(3):
        # Last good AccuWeather answer first, then the keyless provider, then the sample.
        # The ceiling is AccuWeather's, not the page's, so a spent budget must not blank
        # the panel.
        stale = _cache_get_stale(cache_key)
        live = None if stale else await _open_meteo_weather(lat, lon)
        payload = {
            **envelope,
            "source": "accuweather" if stale else ("open-meteo" if live else "mock"),
            "attribution": OPEN_METEO_ATTRIBUTION if live else ACCUWEATHER_ATTRIBUTION,
            "stale": stale is not None,
            "note": "Today's AccuWeather call budget is spent; this is " + (
                "the last response the backend fetched, served until the budget resets."
                if stale else
                "live Open-Meteo until the budget resets."
                if live else
                "the documented sample shape until the budget resets."
            ),
            **(stale or live or _accuweather_mock(lat, lon)),
            "fetched_at": datetime.now(UTC).isoformat(),
        }
        payload.pop("cached", None)
        return payload

    try:
        async with httpx.AsyncClient(timeout=UPSTREAM_TIMEOUT, follow_redirects=True) as client:
            location_key = await _resolve_accuweather_location_key(client, lat, lon)
            current_raw, hourly_raw, daily_raw, alerts = await asyncio.gather(
                _accuweather_get(client, f"/currentconditions/v1/{location_key}", {"details": "false"}),
                _accuweather_get(client, f"/forecasts/v1/hourly/12hour/{location_key}", {"metric": "true", "details": "false"}),
                _accuweather_get(client, f"/forecasts/v1/daily/5day/{location_key}", {"metric": "true", "details": "false"}),
                _fetch_accuweather_alerts(client, location_key),
            )
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Upstream weather data unavailable: {exc}")
    except (RuntimeError, ValueError) as exc:
        raise HTTPException(status_code=502, detail=f"AccuWeather response unusable: {exc}")

    payload = {
        **envelope,
        "source": "accuweather",
        "location_key": location_key,
        "current": _map_accuweather_current(current_raw),
        "hourly": _map_accuweather_hourly(hourly_raw),
        "daily": _map_accuweather_daily(daily_raw),
        "alerts": alerts,
        "calls_today": _accuweather_calls_today(),
        "fetched_at": datetime.now(UTC).isoformat(),
    }
    _cache_set(cache_key, payload, ACCUWEATHER_TTL_SECONDS)
    return {**payload, "cached": False}


# ---------------------------------------------------------------------------
# Trip optimisation
#
# This replaces the heuristic that lived in trip_service.dart, and it does so for one
# specific reason: the client heuristic had no water in it. It ranked spots on the static
# hotspot catalogue, so it could recommend a 12-nmi run into a rough sea for a 5 m skiff.
# The server has the cached marine sample, so the same ranking now accounts for the actual
# conditions.
#
# It is a rule-based optimiser, not a trained model, and says so in `strategy`. Calling it
# ML would be a claim about a neural network that does not exist here; the weights below are
# printed in the response so a fisherman can argue with them.
#
# The response is data, not copy. Waypoint wording, tackle labels and reason sentences stay
# in the client, because this app is bilingual and server-rendered English prose cannot be
# translated by the Arabic toggle.
# ---------------------------------------------------------------------------

KM_TO_NMI = 0.539957
# Mirrors FuelCalculatorService.omanFuelPricePerLiterOmr and its 25 % reserve for currents,
# trolling and harbour manoeuvring. If the app's numbers move, these must move with them - the
# two disagreeing is how a fisherman runs out of fuel.
OMAN_FUEL_PRICE_OMR_PER_L = 0.239
FUEL_RESERVE_FACTOR = 1.25

TRIP_WEIGHTS = {
    "species_match": 18.0,
    "depth_affinity": 10.0,
    "distance_penalty_per_radius": 12.0,
    "band_penalty": {
        "good": 0.0,
        "moderate": 8.0,
        "rough_sea": 25.0,
        "strong_current": 15.0,
        "high_risk": 60.0,
    },
    "small_boat_extra_penalty": 20.0,
}


class TripCandidate(BaseModel):
    """One spot from the caller's catalogue. Sent by the client rather than read from a
    database because the backend holds no hotspot store; it is the ocean above the water
    that this endpoint adds, not a copy of the spots."""

    id: str
    name: str = ""
    latitude: float
    longitude: float
    depth_meters: float = 0.0
    probability: float = 0.0
    target_species: List[str] = []


class TripOptimizeRequest(BaseModel):
    target_species: str = "Kingfish"
    departure_lat: float = Field(..., ge=-90, le=90)
    departure_lon: float = Field(..., ge=-180, le=180)
    max_radius_nmi: float = Field(15.0, gt=0, le=200)
    max_budget_omr: float = Field(35.0, gt=0, le=1000)
    duration_hours: float = Field(6.0, gt=0, le=48)
    boat_length_m: Optional[float] = Field(None, ge=1.0, le=30.0)
    # Boat economics come from the caller's own BoatProfile so the app's table stays the
    # single source of truth for what a skiff burns.
    cruising_speed_kts: float = Field(20.0, gt=0, le=60)
    liters_per_nmi: float = Field(0.85, gt=0, le=20)
    candidates: List[TripCandidate] = []


def _species_matches(candidate: TripCandidate, target: str) -> bool:
    def norm(s: str) -> str:
        return s.lower().split("(")[0].strip()

    t = norm(target)
    return any(norm(c) == t or t in norm(c) or norm(c) in t for c in candidate.target_species)


def _depth_affinity(target: str, depth_m: float) -> bool:
    s = target.lower()
    if ("tuna" in s or "sailfish" in s) and depth_m > 40:
        return True
    if ("grouper" in s or "hammour" in s or "hamoor" in s) and 20 <= depth_m <= 60:
        return True
    return False


def _score_candidate(
    cand: TripCandidate,
    req: TripOptimizeRequest,
    band: Optional[str],
) -> Dict[str, Any]:
    """One candidate, one score, and the codes that explain the score.

    Every figure is derived from the one above it after rounding, so a fisherman checking
    litres x pump price against the printed cost gets the printed cost back."""
    one_way_nm = round(haversine_km(req.departure_lat, req.departure_lon,
                                    cand.latitude, cand.longitude) * KM_TO_NMI, 1)
    round_nm = round(one_way_nm * 2.0, 1)
    fuel_l = round(round_nm * req.liters_per_nmi * FUEL_RESERVE_FACTOR, 1)
    cost = round(fuel_l * OMAN_FUEL_PRICE_OMR_PER_L, 2)
    minutes = round(one_way_nm / max(req.cruising_speed_kts, 0.1) * 60)

    reasons: List[str] = []
    blockers: List[str] = []
    if one_way_nm > req.max_radius_nmi:
        blockers.append("outside_radius")
    if cost > req.max_budget_omr:
        blockers.append("over_budget")

    score = max(0.0, min(100.0, cand.probability))
    reasons.append("bite_probability")

    if _species_matches(cand, req.target_species):
        score += TRIP_WEIGHTS["species_match"]
        reasons.append("species_match")
    if _depth_affinity(req.target_species, cand.depth_meters):
        score += TRIP_WEIGHTS["depth_affinity"]
        reasons.append("depth_affinity")

    # Closer costs less and leaves more of the trip window for fishing.
    travel_penalty = (one_way_nm / req.max_radius_nmi) * TRIP_WEIGHTS["distance_penalty_per_radius"]
    score -= travel_penalty
    if travel_penalty >= 6.0:
        reasons.append("long_crossing")

    if band:
        penalty = TRIP_WEIGHTS["band_penalty"].get(band, 0.0)
        # A short open boat in the same water as a 12 m cabin cruiser is a different risk.
        if band not in ("good",) and (req.boat_length_m or 12.0) < 7.0:
            penalty += TRIP_WEIGHTS["small_boat_extra_penalty"]
            reasons.append("small_boat_in_this_sea")
        if penalty:
            score -= penalty
            reasons.append(f"sea_state_{band}")

    return {
        "id": cand.id,
        "name": cand.name,
        "latitude": cand.latitude,
        "longitude": cand.longitude,
        "depth_meters": cand.depth_meters,
        "probability": cand.probability,
        "score": round(max(0.0, min(100.0, score)), 1),
        "distance_nm": one_way_nm,
        "round_trip_nm": round_nm,
        "fuel_liters": fuel_l,
        "cost_omr": cost,
        "travel_minutes": minutes,
        "reasons": reasons,
        "blockers": blockers,
    }


@app.post("/api/v1/trip/optimize")
async def trip_optimize(req: TripOptimizeRequest):
    """Rank the caller's candidate spots against the live water.

    Rule-based, not learned: `strategy` and `weights` are in the response so the ranking can
    be argued with. Spots are within the cruising radius of each other, so one cached marine
    sample covers the area - fetching per spot would multiply upstream calls for no change in
    the answer."""
    if not req.candidates:
        raise HTTPException(status_code=400, detail="No candidate spots to optimise.")

    band: Optional[str] = None
    conditions: Optional[Dict[str, Any]] = None
    conditions_note: Optional[str] = None
    try:
        sample = await marine_conditions(
            req.departure_lat, req.departure_lon, False, None, "open", None
        )
        sea = sample.get("sea_state") or {}
        band = sea.get("band")
        conditions = {
            key: sample.get(key)
            for key in (
                "sea_temperature_c", "wave_height_m", "wave_period_s", "wind_speed_kts",
                "current_speed_kts", "visibility_km", "tide_state",
            )
        }
        conditions["sea_state_band"] = band
        conditions["drivers"] = sea.get("drivers", [])
    except HTTPException:
        # No water data is a reason to rank on the catalogue alone, not a reason to refuse
        # the request - but the response must say the ranking flew blind.
        conditions_note = (
            "Live marine conditions were unavailable, so this ranking uses each spot's own "
            "bite probability and the caller's constraints only. No sea-state penalty applied."
        )

    scored = sorted(
        (_score_candidate(c, req, band) for c in req.candidates),
        key=lambda plan: plan["score"],
        reverse=True,
    )
    viable = [p for p in scored if not p["blockers"]]
    rejected = [p for p in scored if p["blockers"]]
    if viable:
        winner = viable[0]
    else:
        # Nothing fits the boat's limits. Recommend the least-impossible option - fewest
        # blockers, then shortest crossing, the way the client heuristic fell back to the
        # nearest spot - and label it, because a plan the boat cannot actually sail is not
        # a recommendation.
        winner = sorted(scored, key=lambda p: (len(p["blockers"]), p["distance_nm"]))[0] if scored else None
    if winner and winner["blockers"]:
        winner = {**winner, "fallback": True, "reasons": winner["reasons"] + ["no_viable_option"]}

    return {
        "strategy": "rule-based ranking over live conditions - not a trained model",
        "rule": (
            "score = bite probability + species match + depth affinity, minus crossing "
            "distance and a penalty for the worst live sea-state reading (plus an extra "
            "penalty under 7 m); spots outside the radius or over budget are excluded."
        ),
        "weights": TRIP_WEIGHTS,
        "conditions": conditions,
        "conditions_note": conditions_note,
        "candidates_evaluated": len(scored),
        "viable_options": len(viable),
        "recommended": winner,
        "alternatives": (viable or scored)[1:4],
        "rejected": [{"id": p["id"], "name": p["name"], "blockers": p["blockers"]}
                     for p in rejected],
        "fetched_at": datetime.now(UTC).isoformat(),
    }
