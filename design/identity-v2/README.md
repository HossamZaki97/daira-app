# Daira identity v2 — Phase 0 (C1: night navy + amber)

Design only. Nothing in the app or backend code reads these files yet; phases 1–4 wire them in.

- `design-tokens.json` — single source for colors (light/dark/status), type, spacing, radius, elevation, motion.
- `logo/` — "Rounds ring" mark. `daira-icon.svg` is the master (1024). Android adaptive = foreground + background, themed = monochrome. Notification icon is white only.
- `logo/odoo-icon.svg` + `icon.png` → will replace `daira_backend/static/description/icon.png`.
- `guide.html` — full identity guide (components, states, all screens, backend). Open in a browser.

Rules: one amber action per screen; text on amber is always navy; statuses never use amber; icons 24 grid / 1.75 stroke / round caps.
