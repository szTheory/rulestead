---
created: 2026-06-19T15:06:58.862Z
title: Wire favicon into brandbook HTML head
area: ui
files:
  - brandbook/ (brand book HTML page)
  - brandbook/assets/logo/rs-favicon.svg (existing favicon asset)
---

## Problem

The rulestead brandbook is an HTML page but does not reference the favicon in its
`<head>`, so browser tabs/bookmarks for the brand book show no brand mark. The
favicon asset (`rs-favicon.svg`) already ships in `brandbook/assets/logo/` — it
just isn't wired into the brand book HTML. Low-priority polish; no rush.

## Solution

Add a `<link rel="icon" type="image/svg+xml" href="...rs-favicon.svg">` to the
brandbook HTML `<head>`, pointing at the existing `rs-favicon.svg` asset. Confirm
the relative path resolves when the HTML is rendered/served. Quick, idiomatic fix
— can be done standalone now or folded into the next brandbook/HTML touch.
