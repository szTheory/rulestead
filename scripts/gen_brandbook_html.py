#!/usr/bin/env python3
"""Generate the source-controlled Rulestead HTML brand book."""
import json
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT = REPO_ROOT / "brandbook" / "index.html"

REQUIRED_FILES = [
    "brandbook/brand-book.md",
    "brandbook/tokens.json",
    "brandbook/tokens.css",
    "brandbook/VOICE.md",
    "brandbook/COPY.md",
    "brandbook/BUDGET.md",
    "brandbook/README.md",
    "brandbook/docs/brand-usage.md",
]

FINAL_LOGOS = [
    "rs-wordmark.svg",
    "rs-wordmark-dark.svg",
    "rs-mark.svg",
    "rs-mark-dark.svg",
    "rs-mark-mono.svg",
    "rs-favicon.svg",
    "rs-social-card.svg",
]

SPECIMENS = [
    "palette.svg",
    "typography.svg",
    "components.svg",
    "code-block.svg",
    "readme-header.svg",
    "social-card.svg",
]

SECTION_ORDER = [
    "overview",
    "voice-and-messaging",
    "color",
    "typography",
    "logo",
    "layout-and-components",
    "iconography-and-imagery",
    "motion",
    "assets-and-maintenance",
]


class BrandbookError(RuntimeError):
    """Short, user-actionable generation failure."""


def require_file(repo_root: Path, rel_path: str) -> Path:
    path = repo_root / rel_path
    if not path.is_file():
        raise BrandbookError(f"ERROR: missing required source file: {rel_path}")
    return path


def read_text(repo_root: Path, rel_path: str) -> str:
    return require_file(repo_root, rel_path).read_text(encoding="utf-8")


def load_json(repo_root: Path, rel_path: str) -> Any:
    try:
        return json.loads(read_text(repo_root, rel_path))
    except json.JSONDecodeError as exc:
        raise BrandbookError(f"ERROR: invalid JSON in {rel_path}: {exc}") from exc


def load_sources(repo_root: Path) -> dict[str, Any]:
    sources: dict[str, Any] = {}
    for rel_path in REQUIRED_FILES:
        if rel_path.endswith(".json"):
            sources[rel_path] = load_json(repo_root, rel_path)
        else:
            sources[rel_path] = read_text(repo_root, rel_path)
    return sources


def render_brandbook(repo_root: Path) -> str:
    load_sources(repo_root)
    return "<!doctype html>\n"


def main() -> int:
    try:
        output = render_brandbook(REPO_ROOT)
    except BrandbookError as exc:
        print(str(exc))
        return 1

    OUTPUT.write_text(output, encoding="utf-8")
    size = len(output.encode("utf-8"))
    print(f"WROTE {OUTPUT.relative_to(REPO_ROOT)} ({size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
