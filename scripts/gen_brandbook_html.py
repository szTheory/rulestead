#!/usr/bin/env python3
"""Generate the source-controlled Rulestead HTML brand book."""
import json
import html
import re
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

SECTION_RE = re.compile(r"^##\s+(?P<num>\d+)\.\s+(?P<title>.+?)\s*$", re.MULTILINE)

REQUIRED_BRAND_SECTIONS = {
    "3": "Brand essence",
    "4": "Product narrative",
    "5": "Audience",
    "7": "Messaging architecture",
    "8": "Tagline directions",
    "9": "Verbal identity",
    "12": "Color system",
    "13": "Typography",
    "14": "Logo direction",
    "15": "Layout system",
    "16": "Iconography",
    "17": "Imagery",
    "18": "Motion",
    "19": "UI writing standards",
    "25": "Practical implementation defaults",
    "26": "Internal summary for future LLM or design context",
    "27": "Final brand mantra",
}

REQUIRED_TOKEN_GROUPS = ["primitive", "light", "dark", "admin_css_mapping"]

REQUIRED_CSS_INVARIANTS = [
    "--rs-font-display",
    "--rs-font-sans",
    "--rs-font-mono",
    "--rs-text-base",
    "--rs-text-xl",
    "--rs-text-2xl",
    "--rs-motion-fast",
    "--rs-motion-base",
    "--rs-motion-slow",
    "--rs-motion-slower",
    "--rs-ease-standard",
    "--rs-ease-out",
    "--rs-ease-in",
    "--rs-ease-in-out",
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


def extract_numbered_section(markdown, number) -> str:
    number = str(number)
    matches = list(SECTION_RE.finditer(markdown))
    for index, match in enumerate(matches):
        if match.group("num") == number:
            start = match.end()
            end = matches[index + 1].start() if index + 1 < len(matches) else len(markdown)
            return markdown[start:end].strip()
    raise BrandbookError(f"ERROR: required brand-book section {number} not found")


def extract_brand_sections(markdown: str) -> dict[str, dict[str, str]]:
    sections: dict[str, dict[str, str]] = {}
    for number, label in REQUIRED_BRAND_SECTIONS.items():
        body = extract_numbered_section(markdown, number)
        sections[number] = {
            "label": label,
            "body": body,
            "html": render_markdown(body),
        }
    return sections


def render_inline(text: str) -> str:
    rendered = html.escape(text, quote=True)
    rendered = re.sub(r"`([^`]+)`", r"<code>\1</code>", rendered)
    rendered = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", rendered)
    rendered = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", rendered)

    def link(match: re.Match[str]) -> str:
        label = match.group(1)
        href = html.escape(match.group(2), quote=True)
        return f'<a href="{href}">{label}</a>'

    return re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link, rendered)


def table_cells(row: str) -> list[str]:
    return [cell.strip() for cell in row.strip().strip("|").split("|")]


def is_table_separator(row: str) -> bool:
    cells = table_cells(row)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell.strip()) for cell in cells)


def render_table(rows: list[str]) -> str:
    if len(rows) < 2:
        return "\n".join(f"<p>{render_inline(row)}</p>" for row in rows)

    header = table_cells(rows[0])
    body_rows = rows[2:] if is_table_separator(rows[1]) else rows[1:]
    thead = "".join(f"<th>{render_inline(cell)}</th>" for cell in header)
    body = []
    for row in body_rows:
        cells = "".join(f"<td>{render_inline(cell)}</td>" for cell in table_cells(row))
        body.append(f"<tr>{cells}</tr>")
    return "<table><thead><tr>" + thead + "</tr></thead><tbody>" + "".join(body) + "</tbody></table>"


def render_markdown(markdown: str) -> str:
    lines = markdown.splitlines()
    blocks: list[str] = []
    paragraph: list[str] = []
    index = 0

    def flush_paragraph() -> None:
        if paragraph:
            blocks.append(f"<p>{render_inline(' '.join(paragraph))}</p>")
            paragraph.clear()

    while index < len(lines):
        line = lines[index]
        stripped = line.strip()

        if not stripped:
            flush_paragraph()
            index += 1
            continue

        if stripped == "---":
            flush_paragraph()
            blocks.append('<hr aria-hidden="true">')
            index += 1
            continue

        if stripped.startswith("```"):
            flush_paragraph()
            fence_lang = stripped[3:].strip()
            code_lines: list[str] = []
            index += 1
            while index < len(lines) and not lines[index].strip().startswith("```"):
                code_lines.append(lines[index])
                index += 1
            index += 1 if index < len(lines) else 0
            class_attr = f' class="language-{html.escape(fence_lang, quote=True)}"' if fence_lang else ""
            blocks.append(f"<pre><code{class_attr}>{html.escape(chr(10).join(code_lines))}</code></pre>")
            continue

        heading = re.match(r"^(#{3,6})\s+(.+)$", stripped)
        if heading:
            flush_paragraph()
            level = min(len(heading.group(1)) + 1, 6)
            blocks.append(f"<h{level}>{render_inline(heading.group(2))}</h{level}>")
            index += 1
            continue

        if stripped.startswith("|") and stripped.endswith("|"):
            flush_paragraph()
            table_rows: list[str] = []
            while index < len(lines) and lines[index].strip().startswith("|") and lines[index].strip().endswith("|"):
                table_rows.append(lines[index].strip())
                index += 1
            blocks.append(render_table(table_rows))
            continue

        if stripped.startswith(">"):
            flush_paragraph()
            quote_lines: list[str] = []
            while index < len(lines) and lines[index].strip().startswith(">"):
                quote_lines.append(lines[index].strip().lstrip(">").strip())
                index += 1
            blocks.append(f"<blockquote>{render_markdown(chr(10).join(quote_lines))}</blockquote>")
            continue

        if re.match(r"^[-*]\s+", stripped):
            flush_paragraph()
            items: list[str] = []
            while index < len(lines):
                item = re.match(r"^[-*]\s+(.+)$", lines[index].strip())
                if not item:
                    break
                items.append(f"<li>{render_inline(item.group(1))}</li>")
                index += 1
            blocks.append("<ul>" + "".join(items) + "</ul>")
            continue

        if re.match(r"^\d+\.\s+", stripped):
            flush_paragraph()
            items = []
            while index < len(lines):
                item = re.match(r"^\d+\.\s+(.+)$", lines[index].strip())
                if not item:
                    break
                items.append(f"<li>{render_inline(item.group(1))}</li>")
                index += 1
            blocks.append("<ol>" + "".join(items) + "</ol>")
            continue

        paragraph.append(stripped)
        index += 1

    flush_paragraph()
    return "\n".join(blocks)


def token_path(tokens: dict[str, Any], path: str) -> Any:
    current: Any = tokens
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            raise BrandbookError(f"ERROR: required token reference {{{path}}} not found")
        current = current[part]
    return current


def resolve_token_value(tokens: dict[str, Any], value: Any) -> Any:
    if isinstance(value, str) and re.fullmatch(r"\{[A-Za-z0-9_.-]+\}", value):
        ref = value.strip("{}")
        target = token_path(tokens, ref)
        if not isinstance(target, dict) or "$value" not in target:
            raise BrandbookError(f"ERROR: required token reference {{{ref}}} has no $value")
        return resolve_token_value(tokens, target["$value"])
    return value


def assert_token_groups(tokens: Any) -> dict[str, Any]:
    if not isinstance(tokens, dict):
        raise BrandbookError("ERROR: brandbook/tokens.json must contain a JSON object")
    for group in REQUIRED_TOKEN_GROUPS:
        if group not in tokens:
            raise BrandbookError(f"ERROR: required token group {group} not found")
    return tokens


def iter_token_values(tokens: dict[str, Any], group: str) -> list[dict[str, str]]:
    values: list[dict[str, str]] = []

    def walk(node: Any, parts: list[str]) -> None:
        if isinstance(node, dict) and "$value" in node:
            raw = node["$value"]
            resolved = resolve_token_value(tokens, raw)
            values.append({
                "name": ".".join(parts),
                "value": str(resolved),
                "description": str(node.get("$description", "")),
            })
            return
        if isinstance(node, dict):
            for key in sorted(k for k in node if not k.startswith("$")):
                walk(node[key], [*parts, key])

    walk(tokens[group], [group])
    return values


def strip_css_comments(css: str) -> str:
    return re.sub(r"/\*.*?\*/", "", css, flags=re.S)


def extract_css_declarations(css: str, selector: str) -> dict[str, str]:
    index = css.find(selector)
    if index < 0:
        raise BrandbookError(f"ERROR: required CSS selector {selector} not found in brandbook/tokens.css")
    start = css.find("{", index)
    if start < 0:
        raise BrandbookError(f"ERROR: required CSS block {selector} has no opening brace")
    depth = 0
    end = start
    while end < len(css):
        if css[end] == "{":
            depth += 1
        elif css[end] == "}":
            depth -= 1
            if depth == 0:
                break
        end += 1
    if depth != 0:
        raise BrandbookError(f"ERROR: required CSS block {selector} has no closing brace")

    declarations: dict[str, str] = {}
    for line in css[start + 1 : end].splitlines():
        stripped = line.strip()
        if stripped.startswith("--rs-") and ":" in stripped:
            name, _, value = stripped.partition(":")
            declarations[name.strip()] = value.strip().rstrip(";")
    return declarations


def load_tokens_css_invariants(css_text: str) -> dict[str, str]:
    root_declarations = extract_css_declarations(strip_css_comments(css_text), ":root")
    invariants: dict[str, str] = {}
    for name in REQUIRED_CSS_INVARIANTS:
        if name not in root_declarations:
            raise BrandbookError(f"ERROR: required tokens.css invariant {name} not found")
        invariants[name] = root_declarations[name]
    return invariants


def load_token_bundle(tokens: Any) -> dict[str, Any]:
    token_data = assert_token_groups(tokens)
    return {
        "raw": token_data,
        "primitive": iter_token_values(token_data, "primitive"),
        "light": iter_token_values(token_data, "light"),
        "dark": iter_token_values(token_data, "dark"),
        "admin_css_mapping": token_data["admin_css_mapping"],
    }


def load_sources(repo_root: Path) -> dict[str, Any]:
    sources: dict[str, Any] = {}
    for rel_path in REQUIRED_FILES:
        if rel_path.endswith(".json"):
            sources[rel_path] = load_json(repo_root, rel_path)
        else:
            sources[rel_path] = read_text(repo_root, rel_path)
    sources["brand_sections"] = extract_brand_sections(sources["brandbook/brand-book.md"])
    sources["tokens"] = load_token_bundle(sources["brandbook/tokens.json"])
    sources["tokens_css_invariants"] = load_tokens_css_invariants(sources["brandbook/tokens.css"])
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
