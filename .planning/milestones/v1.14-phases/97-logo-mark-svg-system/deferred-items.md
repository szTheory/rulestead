# Phase 97 Deferred Items

Items discovered during Phase 97 execution that are out of scope for this phase.

## lint.sh CWD bug — check_synced_pair.py fails after `cd rulestead/`

**Discovered:** Phase 97-04 (Nyquist sweep)
**Origin:** Phase 96, commit `0423183`
**Severity:** lint.sh exits 1 before reaching SVG budget section

**Description:**
`scripts/ci/lint.sh` runs `cd "${RULESTEAD_REPO}/rulestead"` for mix commands, then calls:
```
python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"
```
That script opens `rulestead_admin/priv/static/css/rulestead_admin.css` as a **relative path**
(line 17: `CSS = "rulestead_admin/priv/static/css/rulestead_admin.css"`). When executed from
`rulestead/`, the relative path resolves to `rulestead/rulestead_admin/...` (doesn't exist).

**Impact:** SVG budget section of lint.sh never runs (but SVG budget passes when verified directly).
**Fix:** Either run `python3 ... check_synced_pair.py` from `${RULESTEAD_REPO}` (not `rulestead/`),
or make the Python script use `os.path.join(os.path.dirname(os.path.dirname(__file__)), ...)` for an absolute path.

**Fix owner:** Phase 98 (runs lint.sh end-to-end) or maintenance task.
