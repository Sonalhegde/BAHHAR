# BAHHAR Landing Page Deployment Guide (Vercel)

The marketing site lives entirely in the [`website/`](website) folder — `landing-page.html`
(the page), `index.html` (redirects to it), `privacy.html`, `terms.html`, `map-mockup.html`,
`vercel.json`, and its own `assets/images/`. It is a fully static site: **no build step**.

---

## 🚀 Quick Deploy to Vercel (recommended)

### Option A — Vercel CLI (from this repo)

```bash
# 1. Install the CLI once
npm i -g vercel

# 2. Authorize (opens a browser to log in)
vercel login

# 3. Deploy the website/ folder to production
vercel deploy website --prod
```

Because `vercel.json` lives inside `website/`, deploy that folder as the project root. The
first run links the directory to a new/selected Vercel project; subsequent runs reuse the link
(stored in `website/.vercel/`, which is git-ignored).

### Option B — Vercel dashboard (Git integration)

1. Go to https://vercel.com/ and sign in with GitHub.
2. **Add New → Project**, import the **BAHHAR** repository.
3. In **Settings → General → Root Directory**, set it to **`website`**.
4. Framework preset: **Other**; build command: *(empty)*; output directory: *(empty)*.
5. Click **Deploy**. Vercel auto-detects the static site and reads `website/vercel.json`.

**Site URL:** `https://<project>.vercel.app` (rename the project for a nicer subdomain, e.g.
`bahhar.vercel.app`).

---

## 🔧 Vercel Configuration Explained

### `website/vercel.json`
```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/landing-page.html" }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-XSS-Protection", "value": "1; mode=block" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    }
  ]
}
```

- **rewrites** — any unknown path falls back to `landing-page.html`. Real files
  (`/privacy.html`, `/terms.html`, `/assets/...`) are served first because Vercel checks the
  filesystem before applying rewrites. `/` is served by `index.html`, which redirects to
  `landing-page.html`.
- **headers** — the same security headers previously set by `netlify.toml`.

### `.vercelignore` (repo root)
Excludes secrets and non-web source (`.env*`, `lib/`, `test/`, `backend/`, `android/`, `ios/`,
`.git/`) so only web assets are uploaded when deploying from the repository.

---

## 📁 Files Required for Deployment

- ✅ `website/landing-page.html` — main landing page
- ✅ `website/index.html` — redirect to the landing page
- ✅ `website/privacy.html`, `website/terms.html` — legal pages
- ✅ `website/map-mockup.html` — embedded Leaflet/OpenStreetMap chart
- ✅ `website/assets/images/*` — photos, fish illustrations, icon
- ✅ `website/vercel.json` — Vercel routing + headers

---

## 🎨 Updating the Live Site

1. Edit files under `website/` locally.
2. Commit and push:
   ```bash
   git add website
   git commit -m "Update landing page content"
   git push origin main
   ```
3. **Vercel auto-deploys** (Git integration) in ~30–60 seconds, or redeploy manually with
   `vercel deploy website --prod`.

---

## 🔍 Troubleshooting

### Site shows 404
Make sure the project's **Root Directory is `website`** (dashboard) or that you deployed the
`website/` folder (CLI). The site has no root-level `index.html`.

### Changes not showing
- Hard-refresh (Ctrl+Shift+R) to bypass the CDN cache.
- Check the deployment log at https://vercel.com/dashboard.
- Wait ~1 minute for CDN propagation.

### Custom domain not working
- **Project → Settings → Domains**, add your domain and follow the DNS instructions.
- Allow time for DNS propagation.

---

## 🔐 Security Headers (Configured)

- **X-Frame-Options** — prevents clickjacking
- **X-Content-Type-Options** — prevents MIME sniffing
- **X-XSS-Protection** — legacy XSS filter
- **Referrer-Policy** — controls referrer leakage

---

## 📈 Analytics (Optional)

Add to `<head>` in `website/landing-page.html`:
```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```
Vercel Analytics can also be enabled from the project dashboard.

---

## 🌐 Alternatives

- **GitHub Pages** — Settings → Pages → source `main` branch, folder `/website` →
  `https://sonalhegde.github.io/BAHHAR/`.
- **Cloudflare Pages** — build command empty, output directory `website`.

---

## 🆘 Support

**Vercel:** docs https://vercel.com/docs · support via the dashboard.
**BAHHAR:** GitHub Issues https://github.com/Sonalhegde/BAHHAR/issues · support@bahharai.com

---

**Last Updated:** September 20, 2026
**Deployment Status:** Live on Vercel
**Estimated Deploy Time:** < 5 minutes
