/* =====================================================================
   BAHHAR · Marine Charts page wiring — Leaflet chart, hotspot markers,
   legend, filter, sidebar read-out, and the flow-layer lifecycle.

   Data comes from flow-field.js, visuals from flow-render.js; the
   particle technique credit (cambecc/earth MIT, Esri wind-js Apache 2.0)
   lives with the renderer. This file only glues UI to those two.
   ===================================================================== */

import { loadField, toCompass, KNOTS } from './flow-field.js';
import { FlowRenderer, RAMPS, rampCss } from './flow-render.js';

/* ---- The chart --------------------------------------------------------- */

const map = L.map('map', {
  center: [23.72, 58.28],
  zoom: 10,
  zoomControl: false,
  scrollWheelZoom: false,   // don't hijack the landing page's scroll
  dragging: true
});

// Tile use requires visible credit to OpenStreetMap - kept on purpose.
// Leaflet writes this into the control with innerHTML, so the link is real markup.
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  maxZoom: 19,
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
}).addTo(map);

// The reserve and the fishing spots live in their own layer groups so the
// sidebar checkboxes switch each off without touching anything else.
const protectedLayer = L.layerGroup();
L.circle([23.8617, 58.0933], {
  color: '#0f7a7a', fillColor: '#0f7a7a', fillOpacity: 0.1,
  radius: 8000, weight: 2, dashArray: '5, 5', className: 'reserve-ring'
}).addTo(protectedLayer);
protectedLayer.addTo(map);

function markerIcon(score, cls) {
  return L.divIcon({
    className: 'leaflet-marker-icon',
    html: '<span class="halo"></span><div class="custom-marker ' + cls + '">' +
          score + '</div>',
    iconSize: [34, 34], iconAnchor: [17, 17]
  });
}

// The three spots match the home-dashboard mock on the landing page.
const spots = [
  { at: [23.80, 58.12], score: 85, species: 'Kingfish', name: 'Daymaniyat Drop-Off' },
  { at: [23.61, 58.54], score: 72, species: 'Hammour', name: 'Mutrah Rocky Bank' },
  { at: [23.55, 58.28], score: 68, species: 'Grouper', name: 'Al Bustan Reef', moderate: true }
];
const spotsLayer = L.layerGroup();
spots.forEach((s) => {
  s.marker = L.marker(s.at, {
    icon: markerIcon(String(s.score), s.moderate ? 'moderate-marker' : ''),
    title: s.name
  }).addTo(spotsLayer);
});
spotsLayer.addTo(map);

/* ---- Sidebar controls -------------------------------------------------- */

const el = {
  filter: document.getElementById('filterBtn'),
  readout: document.getElementById('readout'),
  srcNote: document.getElementById('srcNote'),
  scale: document.getElementById('flowScale'),
  scaleLo: document.getElementById('scaleLo'),
  scaleHi: document.getElementById('scaleHi'),
  mWind: document.getElementById('mWind'),
  mCur: document.getElementById('mCur'),
  mOff: document.getElementById('mOff')
};

// Filter is a working control: cycle the target species, dim the rest.
const faces = ['all species'].concat(spots.map((s) => s.species));
let face = 0;
el.filter.addEventListener('click', () => {
  face = (face + 1) % faces.length;
  const want = faces[face];
  el.filter.textContent = 'Filter: ' + want + ' ▾';
  spots.forEach((s) => {
    const node = s.marker.getElement();
    if (node) node.querySelector('.custom-marker').style.opacity =
      (want === 'all species' || s.species === want) ? '1' : '0.25';
  });
});

document.getElementById('tSpots').addEventListener('change', (e) => {
  e.target.checked ? spotsLayer.addTo(map) : map.removeLayer(spotsLayer);
});
document.getElementById('tProt').addEventListener('change', (e) => {
  e.target.checked ? protectedLayer.addTo(map) : map.removeLayer(protectedLayer);
});

/* ---- Flow layer lifecycle ---------------------------------------------- */

const renderer = new FlowRenderer(document.getElementById('flow'), map);
let live = null;               // {wind: Field, current: Field, synthetic, meta}

function paintScale() {
  const mode = renderer.mode === 'current' ? 'current' : 'wind';
  const r = RAMPS[mode];
  el.scale.style.background = rampCss(mode);
  el.scaleLo.textContent = r.lo;
  el.scaleHi.textContent = r.hi;
}

function renderProvenance() {
  if (renderer.mode === 'off') {
    el.srcNote.textContent = 'Flow layer is off — choose Wind or Current.';
    el.srcNote.className = 'side-note';
    return;
  }
  if (!live) { el.srcNote.textContent = 'Loading flow data…'; el.srcNote.className = 'side-note'; return; }
  if (live.synthetic) {
    el.srcNote.innerHTML = 'Illustrative sample — synthetic vectors, not measurements. ' +
      'The live grid comes from Bahhar\u2019s /api/v1/wind-field (Open-Meteo models).';
    el.srcNote.className = 'side-note sample';
    return;
  }
  const when = live.meta.generatedAt ? new Date(live.meta.generatedAt).toUTCString().slice(17, 22) : '—';
  const maxW = live.wind ? (live.wind.maxSpeed() * KNOTS).toFixed(0) : '—';
  const maxC = live.current ? (live.current.maxSpeed() * KNOTS).toFixed(1) : '—';
  const exaggeration = renderer.mode === 'current'
    ? 'Current motion exaggerated for visibility'
    : 'Wind shown at true relative speed';
  el.srcNote.innerHTML = 'Live Open-Meteo grid · 0.5° · ' +
    (live.meta.cached ? 'server-cached' : 'fresh fetch') + ' · model time ' + when + ' UTC<br>' +
    'Strongest wind ' + maxW + ' kt · strongest current ' + maxC + ' kt<br>' +
    exaggeration + ' · data: Open-Meteo.com (CC-BY 4.0)';
  el.srcNote.className = 'side-note live';
}

/* ---- Read-out ----------------------------------------------------------- */

function uvLine(label, uv, verb) {
  if (!uv) return `${label} <span class="dim">no water here</span>`;
  const kt = Math.hypot(uv[0], uv[1]) * KNOTS;
  const toDeg = (Math.atan2(uv[0], uv[1]) * 180 / Math.PI + 360) % 360;
  const dir = verb === 'from' ? toCompass(toDeg + 180) : toCompass(toDeg);
  const pct = Math.min(100, (kt / (verb === 'from' ? 30 : 4)) * 100);
  return `${label} <b>${kt.toFixed(verb === 'from' ? 0 : 1)} kt</b> ${verb} ${dir}` +
    `<span class="rbar"><i style="width:${pct.toFixed(0)}%"></i></span>`;
}

let pinned = null;
function renderReadout(latlng, locked) {
  const wf = live && live.wind, cf = live && live.current;
  const w = wf && wf.sample(latlng.lng, latlng.lat);
  const c = cf && cf.sample(latlng.lng, latlng.lat);
  el.readout.innerHTML =
    `<b>${latlng.lat.toFixed(2)}° ${latlng.lng.toFixed(2)}°</b>` +
    (locked ? ' <span class="dim">· pinned, tap to release</span>' : '') + '<br>' +
    uvLine('Wind', w, 'from') + '<br>' +
    uvLine('Current', c, 'setting');
}

map.on('mousemove', (e) => { if (!pinned && live) renderReadout(e.latlng, false); });
map.on('click', (e) => {
  if (pinned) { pinned = null; return; }
  if (!live) return;
  pinned = e.latlng;
  renderReadout(pinned, true);
});
map.on('movestart zoomstart', () => { renderer.clear(); renderer.clearTint(); });
map.on('moveend zoomend resize', () => renderer.onViewChanged());
window.addEventListener('resize', () => {
  renderer.resize();
  renderer.onViewChanged();
});

function setMode(next) {
  renderer.setMode(next);
  const ids = { wind: 'mWind', current: 'mCur', off: 'mOff' };
  Object.entries(ids).forEach(([m, id]) => document.getElementById(id).classList.toggle('on', m === next));
  if (renderer.reduced && next !== 'off') {
    el.readout.insertAdjacentHTML('afterbegin',
      '<span class="dim">Motion reduced per your system setting — showing static vectors.</span><br>');
  }
  paintScale();
  renderProvenance();   // an off -> wind/current switch restores the live note
}
el.mWind.addEventListener('click', () => setMode('wind'));
el.mCur.addEventListener('click', () => setMode('current'));
el.mOff.addEventListener('click', () => setMode('off'));

/* ---- Boot --------------------------------------------------------------- */

(async function boot() {
  live = await loadField();
  renderer.fields = live;
  setMode('wind');   // one path for chrome + renderer, like a button press
  // Debug/verification handle, mirroring how map libs expose the instance.
  window.__bahhar = { renderer, map, fields: () => live };
})();
