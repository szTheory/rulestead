---
phase: 102
slug: logo-delta-audit-tournament-studio
status: final
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-11
---

# Phase 102 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Framework: Bash/grep/Python inline assertions — no test framework needed.
> All validations are file-existence checks, grep counts, and CLI smoke tests.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash / grep / Python inline (no pytest/jest — docs+tooling phase) |
| **Config file** | none |
| **Quick run command** | `python3 scripts/gen_glyph_paths.py --font-url "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf" --text "RS" 2>/dev/null \| grep -c 'path transform'` (expect 2) |
| **Full suite command** | `bash scripts/ci/lint.sh` (SVG budget + brand tokens; no new committed SVGs in Phase 102) |
| **Estimated runtime** | < 15 seconds (font download + grep; lint.sh ~10s) |

---

## Sampling Rate

- **After every task commit:** Run quick run command (per-glyph count check)
- **After every plan wave:** Run full suite (`bash scripts/ci/lint.sh`)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** < 15 seconds

---

## Wave 0 Requirements

None — no test framework files to create. All validations are inline commands.

> Existing infrastructure covers all phase requirements. No scaffolding wave needed.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 102-01-T1 | 01 | 1 | LOGO-06 | `--font-url` assert rejects non-gstatic URLs | smoke | `python3 scripts/gen_glyph_paths.py --font-url "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf" --text "RS" 2>/dev/null \| grep -c 'path transform'` (expect 2) | No — Wave 1 creates it | ⬜ pending |
| 102-01-T1 | 01 | 1 | LOGO-06 | curl fetch only (no urllib) | code-review | `grep -v '^#' scripts/gen_glyph_paths.py \| grep -c "urllib"` (expect 0) | No | ⬜ pending |
| 102-01-T1 | 01 | 1 | LOGO-06 | 9 per-glyph paths for "Rulestead" | unit | `python3 scripts/gen_glyph_paths.py --font-url "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf" --text "Rulestead" 2>/dev/null \| grep -c 'path transform'` (expect 9) | No | ⬜ pending |
| 102-01-T2 | 01 | 1 | LOGO-06 | Studio HTML exists in phase dir | smoke | `test -f .planning/phases/102-logo-delta-audit-tournament-studio/102-studio.html && echo ok` | No — Wave 1 creates it | ⬜ pending |
| 102-01-T2 | 01 | 1 | LOGO-06 | Render helper exists in phase dir | smoke | `test -f .planning/phases/102-logo-delta-audit-tournament-studio/render_studio.sh && echo ok` | No — Wave 1 creates it | ⬜ pending |
| 102-01-T2 | 01 | 1 | LOGO-06 | PNGs are git-ignored | smoke | `git check-ignore -v ".planning/phases/102-logo-delta-audit-tournament-studio/studio-render-test.png" 2>/dev/null` (expect match in .gitignore) | No | ⬜ pending |
| 102-01-T3 | 01 | 1 | LOGO-06 | Test render at 3 sizes (visual verify) | manual | See plan 01 checkpoint: run render_studio.sh, inspect PNG | No — checkpoint creates it | ⬜ pending |
| 102-02-T1 | 02 | 1 | BRD-06 | 102-AUDIT.md exists | smoke | `test -f .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md && echo ok` | No — Wave 1 creates it | ⬜ pending |
| 102-02-T1 | 02 | 1 | BRD-06 | KEEP/TIGHTEN/REWORK verdicts present | content | `grep -c "REWORK\|KEEP\|TIGHTEN" .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md` (expect ≥ 5) | No | ⬜ pending |
| 102-02-T1 | 02 | 1 | BRD-06 | index.html section with ratings | content | `grep -c "Solid\|Adequate\|Weak" .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md` (expect ≥ 4) | No | ⬜ pending |
| 102-02-T1 | 02 | 1 | BRD-06 | Phase 106 improvement list present | content | `grep -c "Phase 106" .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md` (expect ≥ 3) | No | ⬜ pending |
| 102-02-T1 | 02 | 1 | BRD-06 | Icon-left anchor finding documented | content | `grep -i "icon.left" .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md \| head -1` (expect at least one line) | No | ⬜ pending |
| 102-02-T1 | 02 | 1 | BRD-06 | OFL licensing section present | content | `grep -c "OFL" .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md` (expect ≥ 3) | No | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Studio render PNG legible at 36px and 16px | LOGO-06 | Visual rendering at sub-pixel sizes cannot be verified by grep; requires human inspection of the PNG | Run `bash render_studio.sh`; open the PNG; confirm wordmark is legible (not blank/inverted) in the 36px header strip and 16px favicon cell |
| Incumbent control render matches shipped wordmark | LOGO-06 | Visual equivalence judgment | Compare the studio render to the live admin shell at 36px height; paths should produce the same visual as Sora Bold set in a browser |

---

## Full Validation Sweep (end of phase)

Run in sequence after both plans complete and the render checkpoint is approved:

```bash
# 1. Quick pipeline check
python3 scripts/gen_glyph_paths.py \
  --font-url "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf" \
  --text "RS" 2>/dev/null | grep -c 'path transform'
# expect: 2

# 2. Full word check
python3 scripts/gen_glyph_paths.py \
  --font-url "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf" \
  --text "Rulestead" 2>/dev/null | grep -c 'path transform'
# expect: 9

# 3. No urllib in new script
grep -v '^#' scripts/gen_glyph_paths.py | grep -c "urllib"
# expect: 0

# 4. Studio artifacts
test -f .planning/phases/102-logo-delta-audit-tournament-studio/102-studio.html && echo "studio html: ok"
test -f .planning/phases/102-logo-delta-audit-tournament-studio/render_studio.sh && echo "render helper: ok"

# 5. PNG git-ignored
git check-ignore -v ".planning/phases/102-logo-delta-audit-tournament-studio/studio-render-test.png" 2>/dev/null | grep -q "gitignore" && echo "gitignore: ok"

# 6. Audit file exists with verdicts
test -f .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md && echo "audit: ok"
grep -c "REWORK\|KEEP\|TIGHTEN" .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md
# expect: >= 5

# 7. Phase 106 improvement list
grep -c "Phase 106" .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md
# expect: >= 3

# 8. CI lint (SVG budget + brand tokens synced — no new committed binaries)
bash scripts/ci/lint.sh
# expect: exit 0
```

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands or documented manual-only rationale
- [x] Sampling continuity: every task has at least one automated check; no 3-consecutive-task gap
- [x] Wave 0: not needed (no test framework scaffolding required)
- [x] No watch-mode flags used anywhere
- [x] Feedback latency < 15 seconds for quick run command
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
