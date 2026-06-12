#!/usr/bin/env python3
"""Generated HTML drift, static assertion, and size-budget guard."""
import difflib
import re
import sys
from html import unescape
from html.parser import HTMLParser
from pathlib import Path

from gen_brandbook_html import render_brandbook


REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT = REPO_ROOT / "brandbook" / "index.html"
HTML_BUDGET_BYTES = 262144

REQUIRED_SECTION_IDS = [
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

FINAL_LOGO_SOURCE_REFS = [
    "assets/logo/rs-wordmark.svg",
    "assets/logo/rs-wordmark-dark.svg",
    "assets/logo/rs-wordmark-tagline.svg",
    "assets/logo/rs-mark.svg",
    "assets/logo/rs-mark-dark.svg",
    "assets/logo/rs-mark-mono.svg",
    "assets/logo/rs-favicon.svg",
    "assets/logo/rs-social-card.svg",
]

SPECIMEN_SOURCE_REFS = [
    "assets/specimens/palette.svg",
    "assets/specimens/typography.svg",
    "assets/specimens/components.svg",
    "assets/specimens/code-block.svg",
    "assets/specimens/readme-header.svg",
    "assets/specimens/social-card.svg",
]

UNSAFE_PATTERNS = [
    ("script src", re.compile(r"<script\b[^>]*\bsrc\s*=", re.IGNORECASE)),
    ("img src", re.compile(r"<img\b[^>]*\bsrc\s*=", re.IGNORECASE)),
    ("base64", re.compile(r"base64", re.IGNORECASE)),
    ("<image", re.compile(r"<image\b", re.IGNORECASE)),
    ("foreignObject", re.compile(r"<foreignobject\b", re.IGNORECASE)),
    ("event handler attribute", re.compile(r"\s+on[a-z0-9_-]+\s*=", re.IGNORECASE)),
    (
        "unsafe href URI",
        re.compile(r"\b(?:href|xlink:href)\s*=\s*(['\"])\s*(?:javascript|data|file)\s*:", re.IGNORECASE),
    ),
    ("unsafe CSS url", re.compile(r"url\(\s*(['\"]?)\s*(?:javascript|data|file)\s*:", re.IGNORECASE)),
]

UNSAFE_URI_SCHEMES = {"javascript", "data", "file"}


class LinkAndIdParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.hrefs = []
        self._doc_excerpt_index = 0
        self._doc_excerpt_stack = []

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        classes = set(attrs_dict.get("class", "").split())
        if "doc-excerpt" in classes:
            self._doc_excerpt_index += 1
            self._doc_excerpt_stack.append(self._doc_excerpt_index)

        element_id = attrs_dict.get("id")
        if element_id:
            self.ids.append(element_id)

        href = attrs_dict.get("href")
        if href:
            source_index = self._doc_excerpt_stack[-1] if self._doc_excerpt_stack else None
            self.hrefs.append((href, source_index))

    def handle_endtag(self, tag):
        if self._doc_excerpt_stack and tag == "article":
            self._doc_excerpt_stack.pop()


def fail(message: str) -> int:
    print(f"ERROR: {message}")
    return 1


def print_drift(actual: str, expected: str) -> None:
    print("BRANDBOOK HTML DRIFT DETECTED")
    diff = list(
        difflib.unified_diff(
            actual.splitlines(),
            expected.splitlines(),
            fromfile="brandbook/index.html",
            tofile="generated",
            lineterm="",
        )
    )
    limit = 160
    for line in diff[:limit]:
        print(line)
    if len(diff) > limit:
        print(f"... diff truncated ({len(diff) - limit} additional lines)")


def assert_required_sections(actual: str) -> str | None:
    positions = []
    for section_id in REQUIRED_SECTION_IDS:
        match = re.search(rf"<section\b[^>]*\bid=(['\"]){re.escape(section_id)}\1", actual)
        if not match:
            return f"missing required section ID: {section_id}"
        positions.append(match.start())
    if positions != sorted(positions):
        return "required section IDs are out of order"
    return None


def assert_source_refs(actual: str) -> str | None:
    for source_ref in [*FINAL_LOGO_SOURCE_REFS, *SPECIMEN_SOURCE_REFS]:
        if source_ref not in actual:
            return f"missing visible final logo/specimen source reference: {source_ref}"
    return None


def assert_unsafe_patterns(actual: str) -> str | None:
    for label, pattern in UNSAFE_PATTERNS:
        if pattern.search(actual):
            return f"unsafe HTML/SVG marker found: {label}"
    return None


def assert_unique_ids(parser: LinkAndIdParser) -> str | None:
    seen = set()
    duplicate = []
    for element_id in parser.ids:
        if element_id in seen:
            duplicate.append(element_id)
        seen.add(element_id)
    if duplicate:
        return "duplicate inline SVG ID(s): " + ", ".join(sorted(set(duplicate)))
    return None


def href_scheme(href: str) -> str:
    match = re.match(r"^\s*([a-z][a-z0-9+.-]*)\s*:", unescape(href), flags=re.IGNORECASE)
    return match.group(1).lower() if match else ""


def should_skip_href(href: str) -> bool:
    return href.startswith("#")


def doc_excerpt_base(source_index: int | None) -> Path | None:
    # Doc excerpts render VOICE, COPY, README, BUDGET, then docs/brand-usage.
    bases = {
        1: OUTPUT.parent,
        2: OUTPUT.parent,
        3: OUTPUT.parent,
        4: OUTPUT.parent,
        5: OUTPUT.parent / "docs",
    }
    return bases.get(source_index)


def assert_local_links(parser: LinkAndIdParser) -> str | None:
    brandbook_root = OUTPUT.parent
    for href, source_index in parser.hrefs:
        if should_skip_href(href):
            continue
        scheme = href_scheme(href)
        if scheme in UNSAFE_URI_SCHEMES:
            return f"unsafe href scheme found: {href}"
        if scheme:
            continue
        local_path = href.split("#", 1)[0].split("?", 1)[0]
        if not local_path:
            continue
        target = (brandbook_root / local_path).resolve()
        if target.exists() and target.is_relative_to(REPO_ROOT):
            continue
        source_base = doc_excerpt_base(source_index)
        if source_base:
            source_target = (source_base / local_path).resolve()
            if source_target.exists() and source_target.is_relative_to(REPO_ROOT):
                continue
        return f"local non-fragment href does not resolve from brandbook/: {href}"
    return None


def assert_trailing_newline(actual: str) -> str | None:
    if not actual.endswith("\n"):
        return "brandbook/index.html is missing trailing newline"
    if actual.endswith("\n\n"):
        return "brandbook/index.html has more than one trailing newline"
    return None


def run_static_assertions(actual: str) -> str | None:
    parser = LinkAndIdParser()
    parser.feed(actual)

    checks = [
        assert_required_sections(actual),
        assert_source_refs(actual),
        assert_unsafe_patterns(actual),
        assert_unique_ids(parser),
        assert_local_links(parser),
        assert_trailing_newline(actual),
    ]
    for result in checks:
        if result:
            return result
    return None


def main() -> int:
    if not OUTPUT.is_file():
        print("ERROR: brandbook/index.html is missing; run python3 scripts/gen_brandbook_html.py")
        return 1

    actual = OUTPUT.read_text(encoding="utf-8")
    try:
        expected = render_brandbook(REPO_ROOT)
    except Exception as exc:
        print(f"ERROR: brand book render failed: {exc}")
        return 1

    if actual != expected:
        print_drift(actual, expected)
        return 1

    size = len(actual.encode("utf-8"))
    if size > HTML_BUDGET_BYTES:
        print(
            f"BRANDBOOK HTML BUDGET EXCEEDED: brandbook/index.html is {size} bytes "
            f"(limit: {HTML_BUDGET_BYTES})"
        )
        return 1

    static_error = run_static_assertions(actual)
    if static_error:
        return fail(static_error)

    print(f"BRANDBOOK HTML SYNCED ({size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
