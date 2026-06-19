---
created: 2026-06-19T15:10:00.000Z
title: Theme reverts to dark on logo navigation in admin
area: ui
files:
  - rulestead_admin/ (theme toggle + logo/home link)
---

## Problem

In the admin UI (observed at `/admin/flags?env=staging`), the light/dark theme
preference does not persist across navigation:

1. Click the **light mode** button → UI correctly switches to light mode.
2. Click the **Rulestead logo** (top-left, navigates home) → UI reverts to **dark mode**.

Likely cause: the theme choice isn't being persisted (cookie/localStorage/session)
or isn't re-applied on the destination page, so navigation falls back to the
default — possibly the OS `prefers-color-scheme` (reporter is unsure if their
system is currently dark). Reporter also flagged possible stale code / stale
Docker on their end, so **reproduce on fresh/current code first** before assuming
it's a live bug.

## Solution

TBD. Investigation steps:
- Confirm reproducible on current `main` + fresh build (rule out stale Docker).
- Determine how theme state is stored on toggle vs. how it's read on page load —
  check whether the logo link does a full nav (server re-render) that loses an
  in-memory/JS-only theme and re-defaults to system `prefers-color-scheme`.
- Persist the explicit user choice (cookie or localStorage) and re-apply it on
  every page load so it survives navigation and overrides the system default.
