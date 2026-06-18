#!/usr/bin/env python3
"""Version-truth drift guard: shipped docs must not reintroduce pre-1.0 release language.

Fail-closed CI guard (sibling of the 8 check_*.py brand-token guards). It scans the
criterion-1 shipped doc surface for stale pre-1.0 version CLAIMS — the language the v2.0
milestone exists to eliminate — and exits non-zero if any reappears.

Usage (from repo root):
    python3 scripts/check_version_truth.py
Exits 0 and prints "VERSION TRUTH OK (N files clean)" on success; exits 1, prints a
drift header, and lists each "path:line: <hit>" on drift.

Scope (CONTEXT D-06): an explicit fixed README/maintainer-doc list PLUS a recursive
glob of guides/. Deliberately does NOT scan .planning/, prompts/, rulestead/doc/, or
examples/ — those carry historically accurate pre-1.0 references.

Landmine guard (D-06): the anchored upstream-pin pattern uses a negative lookahead so the
legitimate third-party dependency pin (a two-segment "~> 0.1" followed by a further
".<digit>") is never flagged, while a bare two-segment pin still is.

Upgrade-arrow exemption (ROADMAP SC-4 coherence): a line that states the sanctioned
upgrade path FROM the old major TO 1.0 — i.e. an "old → 1.0" arrow line, Unicode or
ASCII — is the one mandated upgrade-path instruction, not a stale claim. Such a line is
exempt from ALL pattern checks. The exemption is line-scoped and arrow-gated: every other
occurrence of a stale claim on any other line is still caught.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

FIXED_FILES = [
    "README.md",
    "rulestead/README.md",
    "rulestead_admin/README.md",
    "open_feature_rulestead/README.md",
    "MAINTAINING.md",
    "CONTRIBUTING.md",  # zero hits today, but the guard must cover it for future drift
]

# Drift patterns (the load-bearing set). The anchored upstream-pin pattern carries the
# mandatory negative lookahead so a three-segment third-party pin is never flagged while a
# bare two-segment pin still is.
PATTERNS = [
    re.compile(r"0\.1\.x"),
    re.compile(r"0\.1\.7"),
    re.compile(r"future[^\n]*1\.0", re.I),
    re.compile(r"1\.0 API freeze"),
    re.compile(r"Two version lines"),
    re.compile(r"~> 0\.1(?![.\d])"),  # anchored upstream-pin guard (the lookahead landmine)
]

# Sanctioned upgrade-arrow exemption: a line stating the "old → 1.0" / "old -> 1.0" path.
# Matches the old two-segment-x major followed by an arrow (Unicode or ASCII) to 1.0.
UPGRADE_ARROW = re.compile(r"0\.1\.x\s*(?:→|->)\s*1\.0")


def iter_target_files():
    yield from FIXED_FILES
    for p in sorted(ROOT.joinpath("guides").rglob("*.md")):
        yield str(p.relative_to(ROOT))
    for p in sorted(ROOT.joinpath("guides").rglob("*.cheatmd")):
        yield str(p.relative_to(ROOT))


def main() -> int:
    hits = []
    scanned = 0
    for rel in iter_target_files():
        path = ROOT / rel
        if not path.exists():
            continue
        scanned += 1
        for n, line in enumerate(path.read_text().splitlines(), start=1):
            if UPGRADE_ARROW.search(line):
                continue  # sanctioned upgrade-path instruction — exempt this line entirely
            for pat in PATTERNS:
                if pat.search(line):
                    hits.append(f"{rel}:{n}: {line.strip()}")
                    break

    if hits:
        print("VERSION TRUTH DRIFT DETECTED")
        for h in hits:
            print(f"  {h}")
        return 1

    print(f"VERSION TRUTH OK ({scanned} files clean)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
