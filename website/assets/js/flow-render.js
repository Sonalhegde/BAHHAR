/* =====================================================================
   BAHHAR particle-flow renderer — the visual half of the layer.
   Technique ported from cambecc/earth (MIT) / Esri wind-js (Apache 2.0):
   particles advected through a bilinear U/V grid, trails faded with
   destination-out. Beautified beyond the stock trick:

   · continuous speed→colour (interpolated ramp, no banding)
   · two-pass strokes — soft glow underlay + speed-scaled core line
   · per-particle life envelope: streaks fade in and out, never pop
   · a blurred "speed tint" texture under the particles (nullschool's
     solid-mode feel) regenerated on map moves, zero per-frame cost

   Canvas 2D only — deliberately not WebGL (broken on Android/iOS
   browsers; this audience is mobile-first).
   ===================================================================== */

const KNOTS = 1.943844;

/* Continuous ramps in kt — the same teal→sand→copper→red language the
   Flutter app's marine cards use, sampled per-frame instead of banded. */
export const RAMPS = {
  wind: {
    stops: [[0, [91, 199, 195]], [5, [15, 122, 122]], [10, [216, 185, 140]],
      [16, [194, 116, 58]], [24, [168, 50, 50]], [32, [120, 26, 90]]],
    lo: 'calm', hi: '30+ kt'
  },
  current: {
    stops: [[0, [143, 184, 232]], [0.6, [77, 111, 174]], [1.4, [107, 79, 174]],
      [2.6, [61, 47, 134]], [4, [36, 26, 92]]],
    lo: 'calm', hi: '4 kt'
  }
};

export function rampRgb(mode, kt) {
  const stops = RAMPS[mode].stops;
  if (kt <= stops[0][0]) return stops[0][1];
  for (let i = stops.length - 1; i >= 0; i--) {
    if (kt >= stops[i][0]) {
      const [k0, c0] = stops[i];
      const [k1, c1] = stops[Math.min(i + 1, stops.length - 1)];
      const t = k1 === k0 ? 0 : Math.min(1, (kt - k0) / (k1 - k0));
      return [
        Math.round(c0[0] + (c1[0] - c0[0]) * t),
        Math.round(c0[1] + (c1[1] - c0[1]) * t),
        Math.round(c0[2] + (c1[2] - c0[2]) * t)
      ];
    }
  }
  return stops[0][1];
}

export function rampCss(mode, steps = 24) {
  const s = RAMPS[mode].stops;
  const max = s[s.length - 1][0];
  const parts = [];
  for (let i = 0; i <= steps; i++) {
    const kt = (max * i) / steps;
    const c = rampRgb(mode, kt);
    parts.push(`rgb(${c[0]},${c[1]},${c[2]}) ${((i / steps) * 100).toFixed(1)}%`);
  }
  return `linear-gradient(90deg, ${parts.join(',')})`;
}

const rgba = (c, a) => `rgba(${c[0]},${c[1]},${c[2]},${a})`;

export class FlowRenderer {
  constructor(canvas, map) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.map = map;
    this.dpr = Math.min(window.devicePixelRatio || 1, 2);
    this.mode = 'off';
    this.fields = null;         // {wind: Field, current: Field}
    this.particles = [];
    this.raf = 0;
    this.lastTs = 0;
    this.reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    // Tint texture: its own canvas below the particle canvas, so the
    // per-frame trail fade never touches it and it costs nothing to keep.
    this.tint = document.createElement('canvas');
    this.tint.id = 'flow-tint';
    this.tint.setAttribute('aria-hidden', 'true');
    this.tint.style.cssText =
      'position:absolute;inset:0;width:100%;height:100%;z-index:499;pointer-events:none;opacity:.8';
    canvas.parentNode.insertBefore(this.tint, canvas);
    this.tintCtx = this.tint.getContext('2d');

    this.resize();
  }

  resize() {
    for (const c of [this.canvas, this.tint]) {
      c.width = Math.round(c.clientWidth * this.dpr);
      c.height = Math.round(c.clientHeight * this.dpr);
    }
    this.ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    this.tintCtx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
  }

  activeField() {
    if (!this.fields || this.mode === 'off') return null;
    return this.fields[this.mode] || null;
  }

  /* ---- lifecycle ----------------------------------------------------- */

  start() {
    this.stopLoop();
    this.clear();
    if (!this.activeField()) { this.paintTint(); return; }
    this.rebuild();
    this.paintTint();
    if (this.reduced) { this.drawStatic(); return; }
    this.lastTs = performance.now();
    this.raf = requestAnimationFrame((t) => this.frame(t));
  }

  stopLoop() { cancelAnimationFrame(this.raf); this.raf = 0; }

  destroy() { this.stopLoop(); this.clear(); this.clearTint(); }

  setMode(mode) {
    this.mode = mode;
    this.start();
  }

  onViewChanged() {
    this.paintTint();
    if (!this.activeField()) return;
    if (this.reduced) this.drawStatic();
    else this.rebuild();
  }

  /* ---- particles ------------------------------------------------------ */

  particleCount() {
    const area = (this.canvas.clientWidth * this.canvas.clientHeight) / 1400;
    return Math.max(220, Math.min(900, Math.round(area)));
  }

  seed(p) {
    const b = this.map.getBounds().pad(0.15);
    for (let tries = 0; tries < 8; tries++) {
      const lat = b.getSouth() + Math.random() * (b.getNorth() - b.getSouth());
      const lng = b.getWest() + Math.random() * (b.getEast() - b.getWest());
      if (this.activeField().sample(lng, lat)) {
        p.lat = lat; p.lng = lng; p.age = 0;
        p.life = 60 + Math.random() * 110;   // frames; jitter kills sync-blinking
        return true;
      }
    }
    return false;
  }

  rebuild() {
    this.particles = [];
    const n = this.particleCount();
    for (let guard = 0; guard < n * 3 && this.particles.length < n; guard++) {
      const p = {};
      if (this.seed(p)) this.particles.push(p);
    }
  }

  /* Advection turns m/s into degrees/s. Currents get the larger gain or
     their 0–1 m/s motion would be invisible at a regional camera — the
     standard exaggeration of this technique, disclosed in the sidebar. */
  gainMs() { return this.mode === 'current' ? 0.16 : 0.05; }

  frame(ts) {
    this.raf = requestAnimationFrame((t) => this.frame(t));
    const f = this.activeField();
    if (!f) return;
    const dt = Math.min((ts - this.lastTs) / 1000 || 0.016, 0.05);
    this.lastTs = ts;

    const ctx = this.ctx;
    this.fade(0.052);                          // long, silky trails
    ctx.lineCap = 'round';
    const g = this.gainMs();
    const max = this.mode === 'current' ? 4 : 30;

    for (const p of this.particles) {
      const uv = f.sample(p.lng, p.lat);
      if (!uv || ++p.age > p.life) { this.seed(p); continue; }
      const kt = Math.hypot(uv[0], uv[1]) * KNOTS;
      const lat2 = p.lat + uv[1] * g * dt;
      const lng2 = p.lng + uv[0] * g * dt;
      const a = this.map.latLngToContainerPoint([p.lat, p.lng]);
      const b = this.map.latLngToContainerPoint([lat2, lng2]);

      const ratio = Math.min(kt / max, 1);
      // Life envelope: fade in over 12 frames, out over the last 22.
      const env = Math.min(1, p.age / 12, (p.life - p.age) / 22);
      const c = rampRgb(this.mode, kt);

      // Glow underlay — wide, faint, gives streaks a luminous body.
      ctx.strokeStyle = rgba(c, 0.10 * env + 0.02);
      ctx.lineWidth = 2.4 + 3.4 * ratio;
      ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
      // Core streak — narrow, bright, speed-scaled.
      ctx.strokeStyle = rgba(c, 0.85 * env);
      ctx.lineWidth = 0.8 + 1.3 * ratio;
      ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();

      p.lat = lat2; p.lng = lng2;
    }
    ctx.globalAlpha = 1;
  }

  fade(alpha) {
    const ctx = this.ctx;
    ctx.save();
    ctx.globalCompositeOperation = 'destination-out';
    ctx.fillStyle = `rgba(0, 0, 0, ${alpha})`;
    ctx.fillRect(0, 0, this.canvas.width / this.dpr, this.canvas.height / this.dpr);
    ctx.restore();
  }

  clear() {
    const ctx = this.ctx;
    ctx.save();
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    ctx.restore();
  }

  clearTint() {
    const t = this.tintCtx;
    t.save();
    t.setTransform(1, 0, 0, 1, 0, 0);
    t.clearRect(0, 0, this.tint.width, this.tint.height);
    t.restore();
  }

  /* ---- speed-tint texture ----------------------------------------------
     One soft coloured tile per water cell, blurred once per map move.
     Under the streaks this reads like nullschool's solid mode: the sea
     itself carries the speed, the particles carry the direction. ---------- */

  paintTint() {
    this.clearTint();
    const f = this.activeField();
    if (!f) return;
    const t = this.tintCtx;
    const canBlur = typeof t.filter === 'string';
    t.save();
    if (canBlur) t.filter = 'blur(10px)';
    const max = this.mode === 'current' ? 4 : 30;
    let w = 0;
    for (let iy = 0; iy < f.ny; iy++) {
      for (let ix = 0; ix < f.nx; ix++) {
        const i = iy * f.nx + ix;
        if (f.u[i] == null) continue;
        const lng = f.lo1 + ix * f.dx, lat = f.la1 - iy * f.dy;
        const a = this.map.latLngToContainerPoint([lat + f.dy / 2, lng - f.dx / 2]);
        const b = this.map.latLngToContainerPoint([lat - f.dy / 2, lng + f.dx / 2]);
        if (b.x < -30 || a.x > this.canvas.clientWidth + 30 ||
            b.y < -30 || a.y > this.canvas.clientHeight + 30) continue;
        const kt = Math.hypot(f.u[i], f.v[i]) * KNOTS;
        const ratio = Math.min(kt / max, 1);
        t.fillStyle = rgba(rampRgb(this.mode, kt), 0.055 + 0.19 * ratio);
        t.fillRect(a.x - 1, a.y - 1, (b.x - a.x) + 2, (b.y - a.y) + 2);
        w++;
      }
    }
    t.restore();
    if (!canBlur && w) {
      // Fallback for engines without canvas filter: re-blur by downsample
      // copy — cheap enough at ~360 cells, and old Safari still complies.
      const d = document.createElement('canvas');
      d.width = Math.max(1, Math.round(this.tint.width / 12));
      d.height = Math.max(1, Math.round(this.tint.height / 12));
      const dc = d.getContext('2d');
      dc.drawImage(this.tint, 0, 0, d.width, d.height);
      t.imageSmoothingEnabled = true;
      t.drawImage(d, 0, 0, this.tint.width / this.dpr, this.tint.height / this.dpr);
    }
  }

  /* ---- prefers-reduced-motion: all information, no animation -----------
     One coloured arrow per cell — the same data as the streaks. */

  drawStatic() {
    this.clear();
    const f = this.activeField();
    if (!f) return;
    const ctx = this.ctx;
    const max = f.maxSpeed() || 1;
    ctx.lineCap = 'round';
    for (let iy = 0; iy < f.ny; iy++) {
      for (let ix = 0; ix < f.nx; ix++) {
        const i = iy * f.nx + ix;
        if (f.u[i] == null) continue;
        const lat = f.la1 - iy * f.dy, lng = f.lo1 + ix * f.dx;
        const c = this.map.latLngToContainerPoint([lat, lng]);
        const s = Math.hypot(f.u[i], f.v[i]);
        const ratio = Math.min(s / max, 1);
        const len = 6 + 14 * ratio;
        const ux = f.u[i] / (s || 1), uy = -f.v[i] / (s || 1); // screen y is down
        const x2 = c.x + ux * len, y2 = c.y + uy * len;
        const col = rgba(rampRgb(this.mode, s * KNOTS), 0.9);
        ctx.strokeStyle = col;
        ctx.fillStyle = col;
        ctx.lineWidth = 1 + 1.6 * ratio;
        ctx.beginPath();
        ctx.moveTo(c.x - ux * len * 0.4, c.y - uy * len * 0.4);
        ctx.lineTo(x2, y2);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(x2, y2, 1.4 + 1.2 * ratio, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}
