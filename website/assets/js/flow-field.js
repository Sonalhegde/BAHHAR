/* =====================================================================
   BAHHAR flow-field data layer — wind & ocean-current grid.
   Technique adapted from cambecc/earth (MIT) and Esri's wind-js
   (Apache 2.0) — interpolation and particle advection only.

   Pure data: talks to /api/v1/wind-field, models the grid, bilinear
   sampling, and ships an honest synthetic fallback. No DOM here.
   ===================================================================== */

export const BOUNDS = { latMax: 26.5, latMin: 16.5, lonMin: 52.0, lonMax: 60.0 };
export const KNOTS = 1.9438;

const API_URLS = [
  '/api/v1/wind-field',                    // same-origin once the backend rewrite lands
  'http://localhost:8000/api/v1/wind-field' // local dev, CORS-open by design
];

/* ---- Fetch (live) --------------------------------------------------- */

async function tryFetch(url) {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 4000);
  try {
    const res = await fetch(url, { signal: ctl.signal });
    if (!res.ok) throw new Error('HTTP ' + res.status);
    return await res.json();
  } finally {
    clearTimeout(timer);
  }
}

export async function loadField() {
  for (const url of API_URLS) {
    try {
      const payload = await tryFetch(url);
      const f = parseFieldPayload(payload);
      if (f) {
        f.synthetic = false;
        f.meta = { generatedAt: payload.generated_at, cached: !!payload.cached };
        f.provenance = 'Live grid · /api/v1/wind-field · ' + payload.attribution;
        return f;
      }
    } catch (e) {
      /* try the next candidate */
    }
  }
  const f = syntheticField();
  f.meta = {};
  f.provenance = 'Illustrative sample — synthetic vectors, not measurements';
  return f;
}

export function parseFieldPayload(payload) {
  const h = payload.header;
  const fields = {};
  for (const name of ['wind', 'current']) {
    const src = payload.fields && payload.fields[name];
    if (h && src && Array.isArray(src.u) && Array.isArray(src.v)) {
      fields[name] = new Field(h, src.u, src.v);
    }
  }
  return Object.keys(fields).length ? fields : null;
}

/* ---- Field model ----------------------------------------------------- */

export class Field {
  constructor(header, u, v) {
    Object.assign(this, header);
    this.u = u;
    this.v = v;
  }
  at(ix, iy) {
    const i = iy * this.nx + ix;
    return [this.u[i] || 0, this.v[i] || 0];
  }
  cell(lng, lat) {
    return [
      Math.round((lng - this.lo1) / this.dx),
      Math.round((this.la1 - lat) / this.dy)
    ];
  }
  maxSpeed() {
    let m = 0.001;
    for (let i = 0; i < this.u.length; i++) {
      if (this.u[i] == null) continue;
      const s = Math.hypot(this.u[i], this.v[i]);
      if (s > m) m = s;
    }
    return m;
  }
  /* Bilinear interpolation; null (land/missing) corners are skipped and
     the weights renormalised, so the coast reads as a fade-out, not a wall. */
  sample(lng, lat) {
    const fx = (lng - this.lo1) / this.dx;
    const fy = (this.la1 - lat) / this.dy;
    if (fx < -0.5 || fy < -0.5 || fx > this.nx - 0.5 || fy > this.ny - 0.5) return null;
    const x0 = Math.max(0, Math.min(this.nx - 1, Math.floor(fx)));
    const y0 = Math.max(0, Math.min(this.ny - 1, Math.floor(fy)));
    const x1 = Math.min(this.nx - 1, x0 + 1);
    const y1 = Math.min(this.ny - 1, y0 + 1);
    const tx = Math.max(0, Math.min(1, fx - x0));
    const ty = Math.max(0, Math.min(1, fy - y0));
    let u = 0, v = 0, w = 0;
    const corners = [
      [x0, y0, (1 - tx) * (1 - ty)],
      [x1, y0, tx * (1 - ty)],
      [x0, y1, (1 - tx) * ty],
      [x1, y1, tx * ty]
    ];
    for (const [cx, cy, cw] of corners) {
      const i = cy * this.nx + cx;
      if (this.u[i] == null) continue;
      u += this.u[i] * cw;
      v += this.v[i] * cw;
      w += cw;
    }
    if (w < 0.25) return null;
    return [u / w, v / w];
  }
}

/* ---- Synthetic fallback ----------------------------------------------
   Swirling trade-wind pattern + a gyre in the current field, so the
   visualization and its interaction model stay demonstrable offline.
   Clearly labeled in the UI as non-measurement. -------------------------- */

export function syntheticField() {
  const { latMax, latMin, lonMin, lonMax } = BOUNDS;
  const dx = 0.5, dy = 0.5;
  const nx = Math.round((lonMax - lonMin) / dx) + 1;   // 17
  const ny = Math.round((latMax - latMin) / dy) + 1;   // 21
  const mk = () => new Array(nx * ny).fill(null);

  const windU = mk(), windV = mk(), curU = mk(), curV = mk();
  const cx = 56.6, cy = 23.6; // gyre centre off Duqm

  for (let iy = 0; iy < ny; iy++) {
    for (let ix = 0; ix < nx; ix++) {
      const i = iy * nx + ix;
      const lng = lonMin + ix * dx;
      const lat = latMax - iy * dy;
      // A simple coast proxy: land rises west of a diagonal
      const landEdge = 58.3 - (lat - 16.5) * 0.42;
      if (lng < landEdge) continue; // land → null
      const wx = 5.2 + 3.4 * Math.sin((lng - 52) * 0.55) * Math.cos((lat - 17) * 0.5);
      const wy = -6.8 + 2.4 * Math.sin((lat - 17) * 0.9);
      windU[i] = wx;
      windV[i] = wy;
      const dxg = lng - cx, dyg = (lat - cy) * 1.6;
      const r = Math.hypot(dxg, dyg) + 0.35;
      const swirl = 0.75 * Math.exp(-r * r / 18);
      curU[i] = -dyg / r * swirl * 3 + 0.28;
      curV[i] = dxg / r * swirl * 3 - 0.18;
    }
  }

  const header = { version: 1, nx, ny, lo1: lonMin, la1: latMax, dx, dy, scan: 'row, w→e, n→s', unit: 'm/s' };
  return {
    wind: new Field(header, windU, windV),
    current: new Field(header, curU, curV),
    synthetic: true
  };
}

/* ---- Formatting -------------------------------------------------------- */

export const COMPASS = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
  'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];

export function toCompass(deg) {
  const d = ((deg % 360) + 360) % 360;
  return COMPASS[Math.round(d / 22.5) % 16];
}
