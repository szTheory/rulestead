#!/usr/bin/env python3
"""Generate the source-controlled Rulestead HTML brand book."""
import json
import html
import re
import sys
from pathlib import Path
from string import Template
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
    "rs-wordmark-tagline.svg",
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

BRAND_VERSION = "v1.15"
BRAND_DATE = "June 2026"

# Token-defined contrast check surfaces (see tokens.json primitive descriptions).
LIGHT_PAIR_BG = "#E8ECE8"  # Stone Mist — Gap-2 canonical check surface
LIGHT_PAIR_LABEL = "Stone Mist"
DARK_PAIR_BG = "#10161f"  # neutral-ramp dark-0 — dark surface base
DARK_PAIR_LABEL = "dark surface"

# Intended-surface captions for the logo plate duals.
LOGO_PLATE_INFO = {
    "rs-wordmark.svg": ("light", "Primary lockup — light surfaces"),
    "rs-wordmark-dark.svg": ("dark", "Primary lockup — dark surfaces"),
    "rs-wordmark-tagline.svg": ("light", "Tagline lockup — light surfaces, generous widths only"),
    "rs-mark.svg": ("light", "d-sigil mark — light surfaces"),
    "rs-mark-dark.svg": ("dark", "d-sigil mark — dark surfaces"),
    "rs-mark-mono.svg": ("light", "Monochrome mark — single-ink contexts"),
    "rs-favicon.svg": ("any", "Favicon — browser chrome, any theme"),
    "rs-social-card.svg": ("any", "Social card — self-backed, theme-independent"),
}

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
    "14": "Logo system",
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

UNSAFE_SVG_MARKERS = ["base64", "<image", "<script", "<foreignObject"]
UNSAFE_URI_SCHEMES = {"javascript", "data", "file"}


def srgb_channel(value: int) -> float:
    scaled = value / 255
    return scaled / 12.92 if scaled <= 0.03928 else ((scaled + 0.055) / 1.055) ** 2.4


def relative_luminance(hex_color: str) -> float:
    digits = hex_color.lstrip("#")
    if len(digits) == 3:
        digits = "".join(ch * 2 for ch in digits)
    red, green, blue = (srgb_channel(int(digits[i : i + 2], 16)) for i in (0, 2, 4))
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def contrast_ratio(foreground: str, background: str) -> float:
    lighter, darker = sorted((relative_luminance(foreground), relative_luminance(background)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def wcag_badge(ratio: float) -> tuple[str, str]:
    """Return (label, modifier class) for a WCAG text-contrast ratio."""
    if ratio >= 7.0:
        return "AAA", "sem-badge--aaa"
    if ratio >= 4.5:
        return "AA", "sem-badge--aa"
    if ratio >= 3.0:
        return "AA large", "sem-badge--large"
    return "Below AA", "sem-badge--below"


def uri_scheme(value: str) -> str:
    match = re.match(r"^\s*([a-z][a-z0-9+.-]*)\s*:", html.unescape(value), flags=re.IGNORECASE)
    return match.group(1).lower() if match else ""


def assert_safe_href(href: str) -> None:
    scheme = uri_scheme(href)
    if scheme in UNSAFE_URI_SCHEMES:
        raise BrandbookError(f"ERROR: unsafe markdown link scheme: {scheme}")


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
    rendered = rendered.replace("base64", "base&#54;4")
    rendered = re.sub(r"`([^`]+)`", r"<code>\1</code>", rendered)
    rendered = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", rendered)
    rendered = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", rendered)

    def link(match: re.Match[str]) -> str:
        label = match.group(1)
        raw_href = match.group(2).strip()
        assert_safe_href(raw_href)
        href = html.escape(raw_href, quote=True)
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

        heading = re.match(r"^(#{1,6})\s+(.+)$", stripped)
        if heading:
            flush_paragraph()
            level = min(max(len(heading.group(1)), 3), 6)
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
                if item:
                    items.append(item.group(1))
                    index += 1
                    continue
                if items and lines[index].startswith((" ", "\t")) and lines[index].strip():
                    items[-1] = f"{items[-1]} {lines[index].strip()}"
                    index += 1
                    continue
                break
            blocks.append("<ul>" + "".join(f"<li>{render_inline(item)}</li>" for item in items) + "</ul>")
            continue

        if re.match(r"^\d+\.\s+", stripped):
            flush_paragraph()
            items: list[str] = []
            while index < len(lines):
                item = re.match(r"^\d+\.\s+(.+)$", lines[index].strip())
                if item:
                    items.append(item.group(1))
                    index += 1
                    continue
                if items and lines[index].startswith((" ", "\t")) and lines[index].strip():
                    items[-1] = f"{items[-1]} {lines[index].strip()}"
                    index += 1
                    continue
                break
            blocks.append("<ol>" + "".join(f"<li>{render_inline(item)}</li>" for item in items) + "</ol>")
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
            ref = ""
            if isinstance(raw, str) and re.fullmatch(r"\{[A-Za-z0-9_.-]+\}", raw):
                ref = raw.strip("{}")
            values.append({
                "name": ".".join(parts),
                "value": str(resolved),
                "ref": ref,
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


def asset_label(filename: str) -> str:
    return Path(filename).stem.replace("-", " ").title()


def asset_prefix(filename: str) -> str:
    return f"{Path(filename).stem}__"


def assert_safe_svg(rel_path: str, svg_text: str) -> None:
    lowered = svg_text.lower()
    for marker in UNSAFE_SVG_MARKERS:
        if marker.lower() in lowered:
            raise BrandbookError(f"ERROR: unsafe SVG content in {rel_path}")
    if re.search(r"\s+on[a-z0-9_-]+\s*=", svg_text, flags=re.IGNORECASE):
        raise BrandbookError(f"ERROR: unsafe SVG event handler in {rel_path}")
    if re.search(r"\b(?:href|xlink:href)\s*=\s*(['\"])\s*(?:javascript|data|file)\s*:", svg_text, flags=re.IGNORECASE):
        raise BrandbookError(f"ERROR: unsafe SVG URI in {rel_path}")
    if re.search(r"url\(\s*(['\"]?)\s*(?:javascript|data|file)\s*:", svg_text, flags=re.IGNORECASE):
        raise BrandbookError(f"ERROR: unsafe SVG CSS URI in {rel_path}")


def add_svg_role(svg_text: str) -> str:
    root_match = re.match(r"\s*<svg\b([^>]*)>", svg_text)
    if not root_match:
        return svg_text
    root = root_match.group(0)
    if re.search(r"\srole\s*=", root):
        return svg_text
    return svg_text[: root_match.start()] + root.replace("<svg", '<svg role="img"', 1) + svg_text[root_match.end() :]


def prefix_id_list(value: str, id_map: dict[str, str]) -> str:
    return " ".join(id_map.get(part, part) for part in value.split())


def prefix_svg_ids(rel_path: str, svg_text: str, prefix: str) -> str:
    id_map: dict[str, str] = {}

    def replace_id(match: re.Match[str]) -> str:
        quote = match.group(1)
        old_id = match.group(2)
        new_id = f"{prefix}{old_id}"
        id_map[old_id] = new_id
        return f"id={quote}{new_id}{quote}"

    prefixed = re.sub(r"\bid=(['\"])([^'\"]+)\1", replace_id, svg_text)

    def replace_aria(match: re.Match[str]) -> str:
        attr = match.group(1)
        quote = match.group(2)
        value = prefix_id_list(match.group(3), id_map)
        return f"{attr}={quote}{value}{quote}"

    prefixed = re.sub(r"\b(aria-labelledby|aria-describedby)=(['\"])([^'\"]+)\2", replace_aria, prefixed)

    def replace_href(match: re.Match[str]) -> str:
        attr = match.group(1)
        quote = match.group(2)
        value = match.group(3)
        if value.startswith("#") and value[1:] in id_map:
            value = f"#{id_map[value[1:]]}"
        return f"{attr}={quote}{value}{quote}"

    prefixed = re.sub(r"\b(href|xlink:href)=(['\"])([^'\"]+)\2", replace_href, prefixed)

    for old_id, new_id in sorted(id_map.items(), key=lambda item: len(item[0]), reverse=True):
        prefixed = re.sub(rf"url\(\s*#{re.escape(old_id)}\s*\)", f"url(#{new_id})", prefixed)

    if 'aria-labelledby="' not in prefixed and "aria-labelledby='" not in prefixed:
        raise BrandbookError(f"ERROR: required SVG aria-labelledby missing in {rel_path}")
    return add_svg_role(prefixed)


def load_svg_asset(repo_root: Path, directory: str, filename: str) -> dict[str, Any]:
    rel_path = f"{directory}/{filename}"
    svg_text = read_text(repo_root, rel_path)
    assert_safe_svg(rel_path, svg_text)
    return {
        "source_path": rel_path,
        "label": asset_label(filename),
        "bytes": len(svg_text.encode("utf-8")),
        "svg": prefix_svg_ids(rel_path, svg_text, asset_prefix(filename)),
    }


def load_svg_assets(repo_root: Path, directory: str, filenames: list[str]) -> list[dict[str, Any]]:
    return [load_svg_asset(repo_root, directory, filename) for filename in filenames]


def page_href(repo_rel_path: str) -> str:
    if repo_rel_path.startswith("brandbook/"):
        return repo_rel_path.removeprefix("brandbook/")
    return f"../{repo_rel_path}"


def source_refs(paths: list[str]) -> str:
    links = []
    for path in paths:
        href = page_href(path)
        label = href
        links.append(f'<a href="{html.escape(href, quote=True)}">{html.escape(label)}</a>')
    return '<div class="source-refs"><span>Sources</span>' + "".join(links) + "</div>"


def section_title(section_id: str) -> str:
    titles = {
        "overview": "Overview",
        "voice-and-messaging": "Voice and messaging",
        "color": "Color",
        "typography": "Typography",
        "logo": "Logo",
        "layout-and-components": "Layout and components",
        "iconography-and-imagery": "Iconography and imagery",
        "motion": "Motion",
        "assets-and-maintenance": "Assets and maintenance",
    }
    return titles[section_id]


def brand_section_html(sources: dict[str, Any], numbers: list[str]) -> str:
    return "\n".join(sources["brand_sections"][number]["html"] for number in numbers)


def extract_tagline(sources: dict[str, Any]) -> str:
    body = sources["brand_sections"]["8"]["body"]
    match = re.search(r"### Recommended default tagline\s+\*\*(.+?)\*\*", body, flags=re.S)
    if not match:
        raise BrandbookError("ERROR: required default tagline not found in brand-book section 8")
    return match.group(1).strip()


def extract_mantra(sources: dict[str, Any]) -> str:
    body = sources["brand_sections"]["27"]["body"]
    match = re.search(r"\*\*(.+?)\*\*", body, flags=re.S)
    if not match:
        raise BrandbookError("ERROR: required brand mantra not found in brand-book section 27")
    return match.group(1).strip()


def token_rows(tokens: list[dict[str, str]]) -> str:
    rows = []
    for token in tokens:
        rows.append(
            "<tr>"
            f"<td><code>{html.escape(token['name'])}</code></td>"
            f"<td><code>{html.escape(token['value'])}</code></td>"
            f"<td>{render_inline(token['description'])}</td>"
            "</tr>"
        )
    return "<table><thead><tr><th>Token</th><th>Value</th><th>Policy</th></tr></thead><tbody>" + "".join(rows) + "</tbody></table>"


def render_color_swatches(tokens: list[dict[str, str]]) -> str:
    swatches = []
    for token in tokens:
        value = token["value"]
        if not value.startswith("#"):
            continue
        role = token["description"].split("—")[1].strip() if "—" in token["description"] else token["description"]
        swatches.append(
            '<article class="swatch" style="--swatch-color: '
            f'{html.escape(value, quote=True)}">'
            '<span class="swatch__chip" aria-hidden="true"></span>'
            '<span class="swatch__meta">'
            f'<strong>{html.escape(token["name"].removeprefix("primitive."))}</strong>'
            f'<code>{html.escape(value)}</code>'
            "</span>"
            f'<span class="swatch__role">{render_inline(role)}</span>'
            "</article>"
        )
    return '<div class="swatch-grid">' + "".join(swatches) + "</div>"


def render_semantic_swatches(tokens: list[dict[str, str]], group: str, pair_bg: str, pair_label: str) -> str:
    cards = []
    for token in tokens:
        value = token["value"]
        if not value.startswith("#"):
            continue
        ratio = contrast_ratio(value, pair_bg)
        badge_label, badge_class = wcag_badge(ratio)
        short_name = token["name"].removeprefix(f"{group}.")
        ref = token["ref"]
        ref_html = f'<code class="sem-ref">&rarr; {html.escape(ref)}</code>' if ref else ""
        cards.append(
            '<article class="sem-card">'
            '<span class="sem-chip" aria-hidden="true" style="'
            f"--pair-bg: {html.escape(pair_bg, quote=True)}; --pair-fg: {html.escape(value, quote=True)}"
            '">Aa</span>'
            '<span class="sem-meta">'
            f"<strong>{html.escape(short_name)}</strong>"
            f"{ref_html}"
            f"<code>{html.escape(value)}</code>"
            "</span>"
            '<span class="sem-verdict">'
            f'<span class="sem-badge {badge_class}">{badge_label}</span>'
            f'<span class="sem-ratio">{ratio:.2f}:1 on {html.escape(pair_label)} '
            f"<code>{html.escape(pair_bg)}</code></span>"
            "</span>"
            "</article>"
        )
    return '<div class="sem-grid">' + "".join(cards) + "</div>"


def render_invariant_rows(tokens: dict[str, Any], group: str) -> str:
    group_data = tokens["raw"]["invariant"].get(group, {})
    rows = []
    for key in sorted(k for k in group_data if not k.startswith("$")):
        value = group_data[key].get("$value") if isinstance(group_data.get(key), dict) else None
        if isinstance(value, (str, int, float)):
            rows.append({"name": f"invariant.{group}.{key}", "value": str(value), "description": group_data[key].get("$description", "")})
    return token_rows(rows)


def render_css_var_table(values: dict[str, str], names: list[str]) -> str:
    rows = [
        {
            "name": name,
            "value": values[name],
            "description": "",
        }
        for name in names
        if name in values
    ]
    return token_rows(rows)


def render_admin_mapping_table(mapping: dict[str, str]) -> str:
    rows = [
        {
            "name": name,
            "value": value,
            "description": "admin_css_mapping token",
        }
        for name, value in sorted(mapping.items())
        if name.startswith("--rs-")
    ]
    return token_rows(rows)


def render_asset_grid(assets: list[dict[str, Any]]) -> str:
    cards = []
    for asset in assets:
        href = page_href(asset["source_path"])
        source_path = asset["source_path"]
        compact = source_path.endswith("/rs-favicon.svg") or source_path.endswith("/rs-mark-mono.svg")
        card_class = "asset-card asset-card--compact" if compact else "asset-card"
        preview_class = "asset-preview asset-preview--compact" if compact else "asset-preview"
        cards.append(
            f'<figure class="{card_class}">'
            f'<div class="{preview_class}">{asset["svg"]}</div>'
            f'<figcaption><strong>{html.escape(asset["label"])}</strong>'
            f'<span>{asset["bytes"]} bytes</span>'
            f'<a href="{html.escape(href, quote=True)}">{html.escape(href)}</a>'
            "</figcaption>"
            "</figure>"
        )
    return '<div class="asset-grid">' + "".join(cards) + "</div>"


def set_svg_root_id(svg_text: str, root_id: str) -> str:
    root_match = re.match(r"\s*<svg\b([^>]*)>", svg_text)
    if not root_match:
        raise BrandbookError("ERROR: SVG root element not found while assigning plate ID")
    root = root_match.group(0)
    if re.search(r"\sid\s*=", root):
        raise BrandbookError("ERROR: SVG root already carries an ID; refusing to overwrite")
    return svg_text[: root_match.start()] + root.replace("<svg", f'<svg id="{root_id}"', 1) + svg_text[root_match.end() :]


def svg_view_box(svg_text: str) -> str:
    match = re.search(r'viewBox="([^"]+)"', svg_text)
    if not match:
        raise BrandbookError("ERROR: SVG viewBox not found for plate reuse")
    return match.group(1)


def svg_use(root_id: str, view_box: str) -> str:
    return (
        f'<svg viewBox="{html.escape(view_box, quote=True)}" aria-hidden="true" focusable="false">'
        f'<use href="#{html.escape(root_id, quote=True)}"></use>'
        "</svg>"
    )


def plate_root_id(filename: str) -> str:
    return f"plate-{Path(filename).stem}"


def render_logo_plates(assets: list[dict[str, Any]]) -> str:
    plates = []
    for asset in assets:
        filename = Path(asset["source_path"]).name
        intended, caption = LOGO_PLATE_INFO[filename]
        root_id = plate_root_id(filename)
        inline_svg = set_svg_root_id(asset["svg"], root_id)
        view_box = svg_view_box(asset["svg"])
        compact = filename in {"rs-mark.svg", "rs-mark-dark.svg", "rs-mark-mono.svg", "rs-favicon.svg"}
        plate_class = "plate plate--compact" if compact else "plate plate--wide"
        href = page_href(asset["source_path"])
        light_tag = '<span class="plate-tag">primary surface</span>' if intended == "light" else ""
        dark_tag = '<span class="plate-tag plate-tag--dark">primary surface</span>' if intended == "dark" else ""
        if filename == "rs-mark-mono.svg":
            dark_tag = '<span class="plate-tag plate-tag--dark">single ink &mdash; light surfaces only</span>'
        plates.append(
            f'<figure class="{plate_class}">'
            '<div class="plate-tiles">'
            f'<div class="plate-tile plate-tile--light">{inline_svg}{light_tag}</div>'
            f'<div class="plate-tile plate-tile--dark">{svg_use(root_id, view_box)}{dark_tag}</div>'
            "</div>"
            "<figcaption>"
            f'<strong>{html.escape(asset["label"])}</strong>'
            f"<span>{html.escape(caption)}</span>"
            f'<span class="plate-file"><a href="{html.escape(href, quote=True)}">{html.escape(href)}</a> &middot; {asset["bytes"]} bytes</span>'
            "</figcaption>"
            "</figure>"
        )
    return '<div class="plate-grid">' + "".join(plates) + "</div>"


def render_clearspace_diagram(assets: list[dict[str, Any]]) -> str:
    wordmark = next(asset for asset in assets if asset["source_path"].endswith("/rs-wordmark.svg"))
    view_box = svg_view_box(wordmark["svg"])
    return (
        '<figure class="clearspace">'
        '<div class="clearspace-stage">'
        '<div class="clearspace-zone">'
        '<span class="clearspace-mark clearspace-mark--top" aria-hidden="true">1 cap</span>'
        '<span class="clearspace-mark clearspace-mark--right" aria-hidden="true">1 cap</span>'
        '<span class="clearspace-mark clearspace-mark--bottom" aria-hidden="true">1 cap</span>'
        '<span class="clearspace-mark clearspace-mark--left" aria-hidden="true">1 cap</span>'
        f'{svg_use(plate_root_id("rs-wordmark.svg"), view_box)}'
        "</div>"
        "</div>"
        "<figcaption>Clear space &mdash; keep at least one cap height (the height of the R) free on every side "
        "of the lockup. The dashed boundary marks the exclusion zone: no copy, rules, or competing marks inside it.</figcaption>"
        "</figure>"
    )


def render_logo_usage(assets: list[dict[str, Any]]) -> str:
    by_name = {Path(asset["source_path"]).name: asset for asset in assets}
    wordmark_vb = svg_view_box(by_name["rs-wordmark.svg"]["svg"])
    wordmark_dark_vb = svg_view_box(by_name["rs-wordmark-dark.svg"]["svg"])
    mark_vb = svg_view_box(by_name["rs-mark.svg"]["svg"])

    def card(kind: str, tile: str, verdict: str, caption: str) -> str:
        symbol = "&#10003;" if kind == "do" else "&#10007;"
        return (
            f'<figure class="usage usage--{kind}">'
            f'<div class="usage-tile">{tile}</div>'
            "<figcaption>"
            f'<span class="usage-verdict usage-verdict--{kind}" aria-hidden="true">{symbol}</span>'
            f"<strong>{html.escape(verdict)}</strong>"
            f"<span>{html.escape(caption)}</span>"
            "</figcaption>"
            "</figure>"
        )

    correct = card(
        "do",
        svg_use(plate_root_id("rs-wordmark.svg"), wordmark_vb),
        "Correct",
        "The lockup as shipped, on a calm surface, with full clear space.",
    )
    container = card(
        "dont",
        f'<span class="usage-mock usage-mock--container">{svg_use(plate_root_id("rs-wordmark-dark.svg"), wordmark_dark_vb)}</span>',
        "No container shapes",
        "Never box the lockup inside a filled rectangle, pill, or badge.",
    )
    recompose = card(
        "dont",
        '<span class="usage-mock usage-mock--recompose">'
        f'{svg_use(plate_root_id("rs-mark.svg"), mark_vb)}'
        '<span class="usage-mock-text" aria-hidden="true">Rulestead</span>'
        "</span>",
        "No icon-left recomposition",
        "Never rebuild an icon-plus-text lockup; the d-sigil already lives inside the wordmark.",
    )
    tagline = card(
        "dont",
        '<span class="usage-mock usage-mock--tagline">'
        f'{svg_use(plate_root_id("rs-wordmark.svg"), wordmark_vb)}'
        '<span class="usage-mock-text usage-mock-text--tagline" aria-hidden="true">Runtime decisions, made clear.</span>'
        "</span>",
        "No tagline in the primary lockup",
        "Never attach the tagline to the primary lockup; use rs-wordmark-tagline where it is already set.",
    )
    return '<div class="usage-grid">' + correct + container + recompose + tagline + "</div>"


def css_declarations(mapping: dict[str, Any]) -> str:
    lines = []
    for name, value in sorted(mapping.items()):
        if name.startswith("--rs-"):
            lines.append(f"  {name}: {value};")
    return "\n".join(lines)


def theme_alias_declarations(theme: str) -> str:
    aliases = {
        "light": {
            "--rs-bg": "#f4f6f8",
            "--rs-surface": "#ffffff",
            "--rs-surface-muted": "#eef1f5",
            "--rs-text": "#1a2332",
            "--rs-text-muted": "#5c6b7a",
            "--rs-border": "#d8dee6",
            "--rs-border-subtle": "#e7ebf0",
            "--rs-focus-ring-color": "rgba(58, 111, 143, 0.58)",
            "--rs-focus-ring": "0 0 0 var(--rs-focus-ring-offset) #ffffff, 0 0 0 calc(var(--rs-focus-ring-offset) + 3px) var(--rs-focus-ring-color)",
        },
        "dark": {
            "--rs-bg": "#19222e",
            "--rs-surface": "#141c27",
            "--rs-surface-muted": "#1f2a38",
            "--rs-text": "#e8edf3",
            "--rs-text-muted": "#a8b9ca",
            "--rs-border": "#2e3d52",
            "--rs-border-subtle": "#253243",
            "--rs-focus-ring-color": "rgba(88, 133, 160, 0.78)",
            "--rs-focus-ring": "0 0 0 var(--rs-focus-ring-offset) #141c27, 0 0 0 calc(var(--rs-focus-ring-offset) + 3px) var(--rs-focus-ring-color)",
        },
    }
    return "\n".join(f"  {name}: {value};" for name, value in aliases[theme].items())


def root_css_declarations(css_text: str) -> str:
    declarations = extract_css_declarations(strip_css_comments(css_text), ":root")
    return "\n".join(f"  {name}: {value};" for name, value in sorted(declarations.items()))


BRANDBOOK_CSS = Template("""
body {
  margin: 0;
}

[data-rulestead-brandbook] {
$css_root
$light
$light_aliases
  min-height: 100vh;
  background: var(--rs-bg);
  color: var(--rs-text);
  font-family: var(--rs-font-sans);
  font-size: var(--rs-text-base);
  line-height: var(--rs-leading-normal);
  letter-spacing: 0;
}

@media (prefers-color-scheme: dark) {
  [data-rulestead-brandbook]:not([data-theme]) {
$dark
$dark_aliases
  }
}

[data-rulestead-brandbook][data-theme="light"] {
$light
$light_aliases
}

[data-rulestead-brandbook][data-theme="dark"] {
$dark
$dark_aliases
}

[data-rulestead-brandbook] *,
[data-rulestead-brandbook] *::before,
[data-rulestead-brandbook] *::after {
  box-sizing: border-box;
}

[data-rulestead-brandbook] a {
  color: var(--rs-primary);
  font-weight: 600;
}

[data-rulestead-brandbook] strong {
  font-weight: 600;
}

[data-rulestead-brandbook] a:focus-visible,
[data-rulestead-brandbook] button:focus-visible {
  outline: none;
  box-shadow: var(--rs-focus-ring);
}

/* ---------- Cover ---------- */

.brand-cover {
  display: flex;
  flex-direction: column;
  min-height: 94vh;
  padding: 36px clamp(24px, 6vw, 88px) 40px;
  background: #0F1720;
  color: #e8edf3;
}

.cover-bar {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 8px 24px;
  padding-bottom: 18px;
  border-bottom: 1px solid rgba(232, 237, 243, 0.14);
  color: #7a8fa3;
  font-family: var(--rs-font-mono);
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.cover-center {
  display: grid;
  flex: 1;
  width: 100%;
  max-width: 920px;
  margin: 0 auto;
  padding: 72px 0 56px;
  align-content: center;
  justify-items: start;
  gap: 36px;
}

.cover-logo {
  display: block;
  width: min(560px, 92%);
}

.cover-logo svg {
  display: block;
  width: 100%;
  height: auto;
}

.cover-logo--print {
  display: none;
}

.cover-kicker {
  margin: 0;
  color: #a8b9ca;
  font-family: var(--rs-font-display);
  font-size: 0.82rem;
  font-weight: 400;
  letter-spacing: 0.34em;
  text-transform: uppercase;
}

.cover-rule {
  width: 76px;
  height: 2px;
  background: #ba6b3c;
}

.cover-mantra {
  margin: 0;
  max-width: 20ch;
  font-family: var(--rs-font-display);
  font-size: clamp(2.1rem, 4.3vw, 3.35rem);
  font-weight: 600;
  line-height: 1.16;
  letter-spacing: -0.015em;
  color: #f0f4f8;
}

.cover-foot {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 8px 24px;
  padding-top: 18px;
  border-top: 1px solid rgba(232, 237, 243, 0.14);
  color: #7a8fa3;
  font-family: var(--rs-font-mono);
  font-size: 0.72rem;
  letter-spacing: 0.04em;
}

.cover-foot em {
  font-style: normal;
  color: #a8b9ca;
}

/* ---------- Layout: rail + content ---------- */

.brand-layout {
  display: grid;
  grid-template-columns: 232px minmax(0, 1fr);
  gap: clamp(32px, 5vw, 72px);
  max-width: var(--rs-shell-max);
  margin: 0 auto;
  padding: 0 clamp(20px, 4vw, 48px);
}

.brand-rail {
  position: sticky;
  top: 0;
  display: grid;
  gap: 20px;
  align-self: start;
  align-content: start;
  max-height: 100vh;
  overflow-y: auto;
  padding: 44px 0 24px;
}

.rail-title {
  margin: 0;
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: 0.66rem;
  font-weight: 600;
  letter-spacing: 0.18em;
  text-transform: uppercase;
}

.rail-list {
  display: grid;
  margin: 0;
  padding: 0;
  list-style: none;
}

.rail-list a {
  display: flex;
  align-items: baseline;
  gap: 12px;
  padding: 9px 12px 9px 14px;
  border-left: 2px solid var(--rs-border-subtle);
  color: var(--rs-text-muted);
  font-size: 0.88rem;
  font-weight: 500;
  text-decoration: none;
}

.rail-num {
  min-width: 2ch;
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: 0.68rem;
  opacity: 0.75;
}

.rail-list a:hover {
  color: var(--rs-text);
}

.rail-list a[aria-current="true"] {
  border-left-color: var(--rs-accent);
  background: var(--rs-surface);
  color: var(--rs-text);
  font-weight: 600;
}

.rail-list a[aria-current="true"] .rail-num {
  color: var(--rs-accent);
  opacity: 1;
}

.theme-cluster {
  display: grid;
  gap: 8px;
  padding-top: 18px;
  border-top: 1px solid var(--rs-border-subtle);
}

.theme-label {
  margin: 0;
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: 0.66rem;
  font-weight: 600;
  letter-spacing: 0.18em;
  text-transform: uppercase;
}

.theme-control {
  display: inline-flex;
  width: fit-content;
  min-height: 44px;
  padding: 4px;
  gap: 4px;
  border: 1px solid var(--rs-border);
  border-radius: var(--rs-radius-full);
  background: var(--rs-surface);
}

.theme-control button {
  min-height: 36px;
  border: 1px solid transparent;
  border-radius: var(--rs-radius-full);
  padding: 0 12px;
  background: transparent;
  color: var(--rs-text-muted);
  font: inherit;
  font-size: 0.85rem;
  font-weight: 600;
}

.theme-control [aria-checked="true"] {
  border-color: var(--rs-primary);
  background: var(--rs-primary-soft, var(--rs-surface-muted));
  color: var(--rs-primary-hover, var(--rs-primary));
}

/* ---------- Sections: editorial rhythm ---------- */

.brand-main {
  padding: 24px 0 64px;
}

.brand-section {
  display: grid;
  gap: 12px;
  padding: 64px 0 44px;
  border-top: 1px solid var(--rs-border-subtle);
  scroll-margin-top: 16px;
}

.brand-section:first-child {
  border-top: 0;
  padding-top: 44px;
}

.section-head {
  display: grid;
  gap: 0;
  margin-bottom: 12px;
}

.section-num {
  font-family: var(--rs-font-display);
  font-size: 3.6rem;
  font-weight: 700;
  line-height: 1;
  letter-spacing: -0.03em;
  color: transparent;
  -webkit-text-stroke: 1.25px var(--rs-border);
}

.section-head h2 {
  margin: 10px 0 0;
  font-family: var(--rs-font-display);
  font-size: 1.9rem;
  line-height: var(--rs-leading-tight);
  font-weight: 600;
  letter-spacing: -0.015em;
}

.section-copy > p,
.section-copy > ul,
.section-copy > ol,
.section-copy > blockquote {
  max-width: 68ch;
}

.section-copy p,
.section-copy li {
  color: var(--rs-text);
  line-height: 1.7;
}

.section-copy > h3 {
  margin: 44px 0 14px;
  font-family: var(--rs-font-display);
  font-size: 1.22rem;
  line-height: var(--rs-leading-snug);
  font-weight: 600;
  letter-spacing: -0.01em;
}

.section-copy > h3::before {
  content: "";
  display: block;
  width: 28px;
  height: 2px;
  margin-bottom: 10px;
  background: var(--rs-accent);
}

.section-copy h4,
.doc-excerpt h3,
.doc-excerpt h4 {
  margin: 24px 0 8px;
  font-family: var(--rs-font-display);
  font-size: 1.02rem;
  line-height: var(--rs-leading-snug);
  font-weight: 600;
  letter-spacing: 0;
}

.section-copy blockquote {
  margin: 30px 0;
  padding: 6px 0 6px 26px;
  border-left: 3px solid var(--rs-accent);
  color: var(--rs-text);
}

.section-copy blockquote p {
  margin: 0 0 6px;
  font-family: var(--rs-font-display);
  font-size: 1.22rem;
  line-height: 1.55;
  font-weight: 400;
}

.section-lede {
  font-family: var(--rs-font-display);
  font-size: 1.3rem;
  line-height: 1.5;
  color: var(--rs-text);
}

.policy-note,
.plate-note {
  color: var(--rs-text-muted);
}

.source-refs {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 8px;
  margin-top: 16px;
  padding-top: 14px;
  border-top: 1px dashed var(--rs-border-subtle);
}

.source-refs span {
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: 0.66rem;
  font-weight: 600;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  margin-right: 6px;
}

.source-refs a {
  display: inline-flex;
  align-items: center;
  max-width: 100%;
  overflow-wrap: anywhere;
  word-break: break-all;
  border: 1px solid var(--rs-border-subtle);
  border-radius: var(--rs-radius-sm);
  padding: 4px 9px;
  background: var(--rs-surface);
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: var(--rs-text-xs);
  font-weight: 400;
  text-decoration: none;
}

.source-refs a:hover {
  color: var(--rs-text);
  border-color: var(--rs-border);
}

/* ---------- Token swatches ---------- */

.swatch-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(216px, 1fr));
  gap: 14px;
}

.asset-grid,
.doc-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}

.swatch,
.sem-card,
.asset-card,
.doc-excerpt {
  border: 1px solid var(--rs-border-subtle);
  border-radius: var(--rs-radius-md);
  background: var(--rs-surface);
}

.swatch {
  display: grid;
  gap: 10px;
  padding: 14px;
  align-content: start;
}

.swatch__chip {
  display: block;
  aspect-ratio: 7 / 2;
  border: 1px solid var(--rs-border-subtle);
  border-radius: 6px;
  background: var(--swatch-color);
}

.swatch__meta {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 8px;
}

.swatch__meta strong {
  font-family: var(--rs-font-display);
  font-size: 0.88rem;
}

.swatch__role {
  color: var(--rs-text-muted);
  font-size: var(--rs-text-xs);
  line-height: 1.55;
}

.sem-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(310px, 1fr));
  gap: 14px;
}

.sem-card {
  display: grid;
  grid-template-columns: 56px minmax(0, 1fr);
  grid-template-rows: auto auto;
  gap: 6px 14px;
  padding: 14px;
  align-items: center;
}

.sem-chip {
  grid-row: 1 / span 2;
  display: grid;
  place-items: center;
  width: 56px;
  height: 56px;
  border: 1px solid var(--rs-border-subtle);
  border-radius: var(--rs-radius-sm);
  background: var(--pair-bg);
  color: var(--pair-fg);
  font-family: var(--rs-font-display);
  font-size: 1.25rem;
  font-weight: 600;
}

.sem-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 4px 10px;
}

.sem-meta strong {
  font-family: var(--rs-font-display);
  font-size: 0.9rem;
}

.sem-meta code,
.sem-ref {
  color: var(--rs-text-muted);
  font-size: var(--rs-text-xs);
}

.sem-verdict {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.sem-badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 9px;
  border: 1px solid currentColor;
  border-radius: var(--rs-radius-full);
  font-family: var(--rs-font-mono);
  font-size: 0.62rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.sem-badge--aaa,
.sem-badge--aa {
  color: var(--rs-success);
}

.sem-badge--large {
  color: var(--rs-warning);
}

.sem-badge--below {
  border-style: dashed;
  color: var(--rs-text-muted);
}

.sem-ratio {
  color: var(--rs-text-muted);
  font-size: var(--rs-text-xs);
}

/* ---------- Logo plates ---------- */

.plate-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.plate {
  margin: 0;
  overflow: hidden;
  border: 1px solid var(--rs-border-subtle);
  border-radius: var(--rs-radius-md);
  background: var(--rs-surface);
}

.plate--wide {
  grid-column: 1 / -1;
}

.plate-tiles {
  display: grid;
  grid-template-columns: 1fr 1fr;
}

.plate-tile {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 150px;
  padding: 30px 26px;
}

.plate-tile--light {
  background: #f4f6f8;
}

.plate-tile--dark {
  background: #10161f;
}

.plate-tile svg {
  display: block;
  width: 100%;
  max-width: 330px;
  max-height: 116px;
  height: auto;
}

.plate--compact .plate-tile svg {
  max-width: 84px;
}

.plate-tag {
  position: absolute;
  top: 10px;
  left: 12px;
  padding: 2px 8px;
  border: 1px solid rgba(26, 35, 50, 0.22);
  border-radius: var(--rs-radius-full);
  color: #5c6b7a;
  font-family: var(--rs-font-mono);
  font-size: 0.58rem;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.plate-tag--dark {
  border-color: rgba(232, 237, 243, 0.26);
  color: #a8b9ca;
}

.plate figcaption {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 4px 14px;
  padding: 12px 16px;
}

.plate figcaption strong {
  font-family: var(--rs-font-display);
  font-size: 0.88rem;
}

.plate figcaption span {
  color: var(--rs-text-muted);
  font-size: var(--rs-text-xs);
}

.plate-file,
.plate-file a {
  font-family: var(--rs-font-mono);
}

.plate-file a {
  color: var(--rs-text-muted);
  font-size: var(--rs-text-xs);
  font-weight: 400;
}

/* ---------- Clear space ---------- */

.clearspace {
  display: grid;
  gap: 12px;
  margin: 8px 0 0;
}

.clearspace-stage {
  display: grid;
  place-items: center;
  padding: clamp(28px, 6vw, 64px);
  border: 1px solid var(--rs-border-subtle);
  border-radius: var(--rs-radius-md);
  background: #f4f6f8;
}

.clearspace-zone {
  position: relative;
  padding: min(11%, 52px);
  border: 1.5px dashed #8fa0b0;
}

.clearspace-zone svg {
  display: block;
  width: min(440px, 56vw);
  height: auto;
}

.clearspace-mark {
  position: absolute;
  color: #5c6b7a;
  font-family: var(--rs-font-mono);
  font-size: 0.6rem;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.clearspace-mark--top {
  top: 6px;
  left: 50%;
  transform: translateX(-50%);
}

.clearspace-mark--bottom {
  bottom: 6px;
  left: 50%;
  transform: translateX(-50%);
}

.clearspace-mark--left {
  top: 50%;
  left: 8px;
  transform: translateY(-50%);
}

.clearspace-mark--right {
  top: 50%;
  right: 8px;
  transform: translateY(-50%);
}

.clearspace figcaption {
  max-width: 64ch;
  color: var(--rs-text-muted);
  font-size: var(--rs-text-sm);
  line-height: 1.6;
}

/* ---------- Do / don't ---------- */

.usage-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 640px) {
  .usage-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}

.usage {
  margin: 0;
  overflow: hidden;
  border: 1px solid var(--rs-border-subtle);
  border-radius: var(--rs-radius-md);
  background: var(--rs-surface);
}

.usage-tile {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 136px;
  padding: 26px 22px;
  background: #f4f6f8;
}

.usage-tile > svg {
  width: min(210px, 84%);
  height: auto;
}

.usage--dont .usage-tile::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: linear-gradient(to top right, transparent calc(50% - 1.5px), rgba(176, 72, 72, 0.85) calc(50% - 1.5px) calc(50% + 1.5px), transparent calc(50% + 1.5px));
}

.usage figcaption {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: 2px 10px;
  padding: 12px 14px;
  align-items: baseline;
}

.usage figcaption strong {
  font-family: var(--rs-font-display);
  font-size: 0.88rem;
}

.usage figcaption > span:last-child {
  grid-column: 2;
  color: var(--rs-text-muted);
  font-size: var(--rs-text-xs);
  line-height: 1.55;
}

.usage-verdict {
  font-weight: 700;
  line-height: 1;
}

.usage-verdict--do {
  color: var(--rs-success);
}

.usage-verdict--dont {
  color: var(--rs-error);
}

.usage-mock {
  display: block;
}

.usage-mock--container {
  width: min(230px, 86%);
  padding: 18px 22px;
  border-radius: 12px;
  background: #3A6F8F;
}

.usage-mock--container svg {
  display: block;
  width: 100%;
  height: auto;
}

.usage-mock--recompose {
  display: flex;
  align-items: center;
  gap: 12px;
}

.usage-mock--recompose svg {
  width: 44px;
  height: auto;
}

.usage-mock-text {
  font-family: var(--rs-font-display);
  font-size: 1.45rem;
  font-weight: 700;
  letter-spacing: -0.01em;
  color: #183247;
}

.usage-mock--tagline {
  display: grid;
  gap: 4px;
  justify-items: center;
  width: min(220px, 84%);
}

.usage-mock--tagline svg {
  display: block;
  width: 100%;
  height: auto;
}

.usage-mock-text--tagline {
  font-family: var(--rs-font-sans);
  font-size: 0.58rem;
  font-weight: 600;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #5c6b7a;
  white-space: nowrap;
}

/* ---------- Code, tables, docs, assets ---------- */

code,
pre {
  font-family: var(--rs-font-mono);
}

.section-copy code,
.swatch code,
table code {
  font-size: var(--rs-text-xs);
}

pre {
  overflow: auto;
  border-radius: 8px;
  padding: 16px;
  background: var(--rs-neutral-0);
  color: var(--rs-text);
}

table {
  width: 100%;
  border-collapse: collapse;
  overflow-wrap: anywhere;
}

th,
td {
  border-bottom: 1px solid var(--rs-border-subtle);
  padding: 12px 8px;
  text-align: left;
  vertical-align: top;
}

th {
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: 0.68rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.asset-card {
  margin: 0;
  overflow: hidden;
}

.asset-preview {
  display: grid;
  min-height: 180px;
  aspect-ratio: 16 / 9;
  place-items: center;
  overflow: hidden;
  padding: 16px;
  background: var(--rs-surface-muted);
}

.asset-preview svg {
  max-width: min(100%, 720px);
  max-height: 100%;
  height: auto;
}

.asset-preview--compact {
  min-height: 120px;
  aspect-ratio: 1 / 1;
}

.asset-preview--compact svg {
  max-width: min(100%, 96px);
  max-height: 96px;
}

.asset-card figcaption {
  display: grid;
  gap: 4px;
  padding: 12px;
}

.asset-card figcaption span,
.asset-card figcaption a {
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: var(--rs-text-xs);
}

.doc-excerpt {
  min-width: 0;
  padding: 16px;
  overflow-wrap: anywhere;
}

.brand-footer {
  max-width: var(--rs-shell-max);
  margin: 0 auto;
  padding: 24px clamp(20px, 4vw, 48px) 32px;
  border-top: 1px solid var(--rs-border-subtle);
  color: var(--rs-text-muted);
  font-size: var(--rs-text-sm);
}

/* ---------- Motion ---------- */

@media (prefers-reduced-motion: no-preference) {
  [data-rulestead-brandbook] {
    scroll-behavior: smooth;
  }

  [data-rulestead-brandbook] a,
  [data-rulestead-brandbook] button,
  [data-rulestead-brandbook] .asset-card {
    transition: color var(--rs-motion-fast) var(--rs-ease-standard), background-color var(--rs-motion-fast) var(--rs-ease-standard), border-color var(--rs-motion-fast) var(--rs-ease-standard), box-shadow var(--rs-motion-base) var(--rs-ease-standard);
  }
}

@media (prefers-reduced-motion: reduce) {
  [data-rulestead-brandbook],
  [data-rulestead-brandbook] * {
    scroll-behavior: auto !important;
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}

/* ---------- Narrow viewports ---------- */

@media (max-width: 960px) {
  .brand-layout {
    grid-template-columns: minmax(0, 1fr);
    gap: 0;
  }

  .brand-rail {
    position: static;
    max-height: none;
    overflow: visible;
    padding: 28px 0 20px;
    border-bottom: 1px solid var(--rs-border-subtle);
  }

  .rail-list {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  .rail-list a {
    border: 1px solid var(--rs-border-subtle);
    border-radius: var(--rs-radius-full);
    padding: 7px 13px;
    background: var(--rs-surface);
  }

  .rail-list a[aria-current="true"] {
    border-color: var(--rs-accent);
  }

  .brand-section {
    padding: 44px 0 32px;
  }

  .section-num {
    font-size: 2.6rem;
  }

  .section-head h2 {
    font-size: 1.55rem;
  }

  .plate-grid {
    grid-template-columns: minmax(0, 1fr);
  }

  .plate--wide {
    grid-column: auto;
  }

  .plate-tiles {
    grid-template-columns: minmax(0, 1fr);
  }

  .brand-cover {
    min-height: 88vh;
    padding: 24px 20px 28px;
  }

  .cover-center {
    padding: 56px 0 44px;
  }
}

/* ---------- Print ---------- */

@media print {
  body {
    background: #ffffff;
  }

  [data-rulestead-brandbook],
  [data-rulestead-brandbook][data-theme="dark"],
  [data-rulestead-brandbook][data-theme="light"] {
$light
$light_aliases
    background: #ffffff;
  }

  .brand-rail,
  .theme-cluster,
  .source-refs {
    display: none;
  }

  .brand-cover {
    min-height: auto;
    padding: 36pt 0 24pt;
    background: #ffffff;
    color: #1a2332;
  }

  .cover-bar,
  .cover-foot {
    color: #5c6b7a;
    border-color: #d8dee6;
  }

  .cover-kicker {
    color: #5c6b7a;
  }

  .cover-mantra {
    color: #0F1720;
  }

  .cover-logo--screen {
    display: none;
  }

  .cover-logo--print {
    display: block;
  }

  .brand-layout {
    display: block;
    max-width: none;
    padding: 0;
  }

  .brand-section {
    border-top: 0;
    padding: 0 0 18pt;
    break-before: page;
    page-break-before: always;
  }

  .swatch,
  .sem-card,
  .plate,
  .usage,
  .asset-card,
  .doc-excerpt,
  .clearspace-stage,
  blockquote,
  tr {
    break-inside: avoid;
    page-break-inside: avoid;
  }

  .swatch__chip,
  .sem-chip,
  .plate-tile,
  .usage-tile,
  .usage-mock--container,
  .asset-preview {
    print-color-adjust: exact;
    -webkit-print-color-adjust: exact;
  }

  .swatch code,
  .sem-meta code {
    font-size: 0.78rem;
    font-weight: 700;
    color: #1a2332;
  }

  .section-num {
    color: transparent;
    -webkit-text-stroke: 1.25px #d8dee6;
  }

  [data-rulestead-brandbook] a {
    color: #1a2332;
    text-decoration: none;
  }
}
""")


def render_styles(sources: dict[str, Any]) -> str:
    mappings = sources["tokens"]["admin_css_mapping"]
    return BRANDBOOK_CSS.substitute(
        css_root=root_css_declarations(sources["brandbook/tokens.css"]),
        light=css_declarations(mappings["light"]),
        dark=css_declarations(mappings["dark"]),
        light_aliases=theme_alias_declarations("light"),
        dark_aliases=theme_alias_declarations("dark"),
    )


def render_theme_script() -> str:
    return """
  <script>
    (() => {
      const wrapper = document.querySelector("[data-rulestead-brandbook]");
      const control = document.querySelector("[data-brandbook-theme-control]");
      if (!wrapper || !control) return;

      const valid = ["system", "light", "dark"];
      const storageKey = "rulestead.brandbook.theme";
      const options = Array.from(control.querySelectorAll("[role='radio'][data-value]"));

      const readTheme = () => {
        try {
          const value = window.localStorage.getItem(storageKey);
          return valid.includes(value) ? value : "system";
        } catch (_error) {
          return "system";
        }
      };

      const writeTheme = (value) => {
        try {
          window.localStorage.setItem(storageKey, value);
        } catch (_error) {}
      };

      const syncOptions = (value) => {
        options.forEach((option) => {
          const active = option.dataset.value === value;
          option.setAttribute("aria-checked", String(active));
          option.tabIndex = active ? 0 : -1;
        });
      };

      const applyTheme = (value) => {
        const next = valid.includes(value) ? value : "system";
        if (next === "light" || next === "dark") {
          wrapper.setAttribute("data-theme", next);
        } else {
          wrapper.removeAttribute("data-theme");
        }
        syncOptions(next);
      };

      let current = readTheme();
      applyTheme(current);

      control.addEventListener("click", (event) => {
        const option = event.target.closest("[role='radio'][data-value]");
        if (!option) return;
        current = valid.includes(option.dataset.value) ? option.dataset.value : "system";
        writeTheme(current);
        applyTheme(current);
        option.focus();
      });

      control.addEventListener("keydown", (event) => {
        const index = options.findIndex((option) => option.tabIndex === 0);
        let nextIndex = -1;
        if (event.key === "ArrowRight" || event.key === "ArrowDown") {
          event.preventDefault();
          nextIndex = (index + 1) % options.length;
        } else if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
          event.preventDefault();
          nextIndex = (index - 1 + options.length) % options.length;
        } else if (event.key === "Home") {
          event.preventDefault();
          nextIndex = 0;
        } else if (event.key === "End") {
          event.preventDefault();
          nextIndex = options.length - 1;
        }
        if (nextIndex < 0) return;
        current = options[nextIndex].dataset.value;
        writeTheme(current);
        applyTheme(current);
        options[nextIndex].focus();
      });
    })();

    (() => {
      const rail = document.querySelector("[data-brandbook-rail]");
      if (!rail || !("IntersectionObserver" in window)) return;

      const links = new Map();
      rail.querySelectorAll("a[href^='#']").forEach((link) => {
        links.set(link.getAttribute("href").slice(1), link);
      });

      const sections = Array.from(
        document.querySelectorAll(".brand-section[id]"),
      ).filter((section) => links.has(section.id));
      if (sections.length === 0) return;

      const setActive = (id) => {
        links.forEach((link, key) => {
          if (key === id) {
            link.setAttribute("aria-current", "true");
          } else {
            link.removeAttribute("aria-current");
          }
        });
      };

      const visible = new Set();
      const pickActive = () => {
        const candidate = sections.find((section) => visible.has(section.id));
        if (candidate) setActive(candidate.id);
      };

      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              visible.add(entry.target.id);
            } else {
              visible.delete(entry.target.id);
            }
          });
          pickActive();
        },
        { rootMargin: "-12% 0px -55% 0px", threshold: 0 },
      );

      sections.forEach((section) => observer.observe(section));
      setActive(sections[0].id);
    })();
  </script>
"""


def section_number(section_id: str) -> str:
    return f"{SECTION_ORDER.index(section_id) + 1:02d}"


def render_section(section_id: str, refs: list[str], body: str) -> str:
    title = section_title(section_id)
    number = section_number(section_id)
    return (
        f'<section id="{section_id}" class="brand-section" aria-labelledby="{section_id}-title">\n'
        '<header class="section-head">\n'
        f'<span class="section-num" aria-hidden="true">{number}</span>\n'
        f'<h2 id="{section_id}-title">{html.escape(title)}</h2>\n'
        "</header>\n"
        f'<div class="section-copy">{body}</div>\n'
        f"{source_refs(refs)}\n"
        "</section>"
    )


def render_overview_section(sources: dict[str, Any]) -> str:
    tagline = extract_tagline(sources)
    return (
        f'<p class="section-lede"><strong>{html.escape(tagline)}</strong></p>'
        + brand_section_html(sources, ["3", "4", "5", "26", "27"])
    )


def render_voice_messaging_section(sources: dict[str, Any]) -> str:
    return (
        brand_section_html(sources, ["7", "8", "9", "19"])
        + '<div class="doc-grid">'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/VOICE.md"])}</article>'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/COPY.md"])}</article>'
        + "</div>"
    )


def render_color_section(sources: dict[str, Any]) -> str:
    tokens = sources["tokens"]
    mappings = tokens["admin_css_mapping"]
    return (
        brand_section_html(sources, ["12"])
        + '<p class="policy-note"><strong>Signal Gold <code>#D2A94E</code> is decorative-only.</strong> Never use it as normal-weight text.</p>'
        + "<h3>Primitive palette</h3>"
        + render_color_swatches(tokens["primitive"])
        + "<h3>Light semantic tokens</h3>"
        + '<p class="plate-note">Each card maps the semantic role to its primitive, with the WCAG verdict computed '
        + "at generation time against the token-defined light check surface.</p>"
        + render_semantic_swatches(tokens["light"], "light", LIGHT_PAIR_BG, LIGHT_PAIR_LABEL)
        + "<h3>Dark semantic tokens</h3>"
        + render_semantic_swatches(tokens["dark"], "dark", DARK_PAIR_BG, DARK_PAIR_LABEL)
        + "<h3>Light admin CSS mapping</h3>"
        + render_admin_mapping_table(mappings["light"])
        + "<h3>Dark admin CSS mapping</h3>"
        + render_admin_mapping_table(mappings["dark"])
        + render_asset_grid([asset for asset in sources["specimens"] if asset["source_path"].endswith("/palette.svg")])
    )


def render_typography_section(sources: dict[str, Any]) -> str:
    invariants = sources["tokens_css_invariants"]
    font_names = ["--rs-font-display", "--rs-font-sans", "--rs-font-mono"]
    type_names = ["--rs-text-base", "--rs-text-xl", "--rs-text-2xl"]
    return (
        brand_section_html(sources, ["13"])
        + "<h3>Font invariants</h3>"
        + render_css_var_table(invariants, font_names)
        + "<h3>Type-scale invariants</h3>"
        + render_css_var_table(invariants, type_names)
        + render_asset_grid([asset for asset in sources["specimens"] if asset["source_path"].endswith("/typography.svg")])
    )


def render_logo_section(sources: dict[str, Any]) -> str:
    logos = sources["logos"]
    return (
        brand_section_html(sources, ["14"])
        + "<h3>Logo plates</h3>"
        + '<p class="plate-note">Every shipped file, rendered live on both reference surfaces '
        + "(<code>#f4f6f8</code> light &middot; <code>#10161f</code> dark). The tagged tile is the variant&rsquo;s primary surface.</p>"
        + render_logo_plates(logos)
        + "<h3>Clear space</h3>"
        + render_clearspace_diagram(logos)
        + "<h3>Use and misuse</h3>"
        + render_logo_usage(logos)
    )


def render_layout_components_section(sources: dict[str, Any]) -> str:
    specimen_names = {"/components.svg", "/code-block.svg"}
    specimens = [asset for asset in sources["specimens"] if any(asset["source_path"].endswith(name) for name in specimen_names)]
    return (
        brand_section_html(sources, ["15"])
        + "<h3>Spacing tokens</h3>"
        + render_invariant_rows(sources["tokens"], "spacing")
        + "<h3>Radius tokens</h3>"
        + render_invariant_rows(sources["tokens"], "radius")
        + render_asset_grid(specimens)
    )


def render_iconography_imagery_section(sources: dict[str, Any]) -> str:
    specimen_names = {"/readme-header.svg", "/social-card.svg"}
    specimens = [asset for asset in sources["specimens"] if any(asset["source_path"].endswith(name) for name in specimen_names)]
    return brand_section_html(sources, ["16", "17"]) + render_asset_grid(specimens)


def render_motion_section(sources: dict[str, Any]) -> str:
    invariants = sources["tokens_css_invariants"]
    motion_names = [
        "--rs-motion-fast",
        "--rs-motion-base",
        "--rs-motion-slow",
        "--rs-motion-slower",
        "--rs-ease-standard",
        "--rs-ease-out",
        "--rs-ease-in",
        "--rs-ease-in-out",
    ]
    return brand_section_html(sources, ["18"]) + render_css_var_table(invariants, motion_names)


def render_assets_maintenance_section(sources: dict[str, Any]) -> str:
    return (
        brand_section_html(sources, ["25"])
        + '<div class="doc-grid">'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/README.md"])}</article>'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/BUDGET.md"])}</article>'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/docs/brand-usage.md"])}</article>'
        + "</div>"
        + "<h3>Generation and guard commands</h3>"
        + "<ul>"
        + "<li><code>python3 scripts/gen_brandbook_html.py</code></li>"
        + "<li><code>python3 scripts/check_brandbook_html.py</code></li>"
        + "<li><code>bash scripts/ci/lint.sh</code></li>"
        + "</ul>"
    )


def render_page(sources: dict[str, Any]) -> str:
    tagline = extract_tagline(sources)
    mantra = extract_mantra(sources)
    logos_by_name = {Path(asset["source_path"]).name: asset for asset in sources["logos"]}
    cover_logo_dark = prefix_svg_ids(
        logos_by_name["rs-wordmark-dark.svg"]["source_path"],
        logos_by_name["rs-wordmark-dark.svg"]["svg"],
        "cover-",
    )
    cover_logo_print = prefix_svg_ids(
        logos_by_name["rs-wordmark.svg"]["source_path"],
        logos_by_name["rs-wordmark.svg"]["svg"],
        "coverprint-",
    )
    rail_items = "".join(
        f'<li><a href="#{section_id}">'
        f'<span class="rail-num" aria-hidden="true">{section_number(section_id)}</span>'
        f"{html.escape(section_title(section_id))}</a></li>"
        for section_id in SECTION_ORDER
    )

    section_bodies = {
        "overview": (
            [
                "brandbook/brand-book.md",
                ".planning/milestones/v1.14-phases/101-html-brand-book/101-UI-SPEC.md",
                "rulestead_admin/lib/rulestead_admin/components/shell.ex",
                "brandbook/assets/logo/rs-wordmark.svg",
            ],
            render_overview_section(sources),
        ),
        "voice-and-messaging": (
            ["brandbook/brand-book.md", "brandbook/VOICE.md", "brandbook/COPY.md"],
            render_voice_messaging_section(sources),
        ),
        "color": (
            ["brandbook/brand-book.md", "brandbook/tokens.json", "brandbook/assets/specimens/palette.svg"],
            render_color_section(sources),
        ),
        "typography": (
            ["brandbook/brand-book.md", "brandbook/tokens.css", "brandbook/assets/specimens/typography.svg"],
            render_typography_section(sources),
        ),
        "logo": (
            ["brandbook/brand-book.md", *[asset["source_path"] for asset in sources["logos"]]],
            render_logo_section(sources),
        ),
        "layout-and-components": (
            ["brandbook/brand-book.md", "brandbook/tokens.json", "brandbook/assets/specimens/components.svg", "brandbook/assets/specimens/code-block.svg"],
            render_layout_components_section(sources),
        ),
        "iconography-and-imagery": (
            ["brandbook/brand-book.md", "brandbook/assets/specimens/readme-header.svg", "brandbook/assets/specimens/social-card.svg"],
            render_iconography_imagery_section(sources),
        ),
        "motion": (
            ["brandbook/brand-book.md", "brandbook/tokens.css"],
            render_motion_section(sources),
        ),
        "assets-and-maintenance": (
            ["brandbook/brand-book.md", "brandbook/README.md", "brandbook/BUDGET.md", "brandbook/docs/brand-usage.md", "scripts/gen_brandbook_html.py", "scripts/check_brandbook_html.py", "scripts/ci/lint.sh"],
            render_assets_maintenance_section(sources),
        ),
    }

    sections = "\n".join(
        render_section(section_id, section_bodies[section_id][0], section_bodies[section_id][1])
        for section_id in SECTION_ORDER
    )

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Rulestead Brand Book</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=Inter:wght@400;600&family=Sora:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
{render_styles(sources)}
  </style>
</head>
<body>
  <div data-rulestead-brandbook>
    <header class="brand-cover">
      <div class="cover-bar">
        <span>Rulestead</span>
        <span>Brand System {html.escape(BRAND_VERSION)}</span>
      </div>
      <div class="cover-center">
        <span class="cover-logo cover-logo--screen">{cover_logo_dark}</span>
        <span class="cover-logo cover-logo--print" aria-hidden="true">{cover_logo_print}</span>
        <h1 class="cover-kicker" aria-label="Rulestead Brand Book">Brand Book</h1>
        <span class="cover-rule" aria-hidden="true"></span>
        <p class="cover-mantra">{html.escape(mantra)}</p>
      </div>
      <div class="cover-foot">
        <span><em>{html.escape(tagline)}</em></span>
        <span>Brand System {html.escape(BRAND_VERSION)} &middot; {html.escape(BRAND_DATE)}</span>
      </div>
    </header>
    <div class="brand-layout">
      <nav class="brand-rail" aria-label="Brand book sections" data-brandbook-rail>
        <p class="rail-title">Contents</p>
        <ol class="rail-list">
          {rail_items}
        </ol>
        <div class="theme-cluster">
          <p class="theme-label" id="brandbook-theme-label">Theme</p>
          <div class="theme-control" role="radiogroup" aria-labelledby="brandbook-theme-label" data-brandbook-theme-control>
            <button type="button" role="radio" aria-checked="true" tabindex="0" data-value="system">System</button>
            <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="light">Light</button>
            <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="dark">Dark</button>
          </div>
        </div>
      </nav>
      <main class="brand-main">
        {sections}
      </main>
    </div>
    <footer class="brand-footer">
      Rulestead Brand System {html.escape(BRAND_VERSION)} &middot; generated from canonical brandbook sources by <code>scripts/gen_brandbook_html.py</code>.
    </footer>
  </div>
{render_theme_script()}
</body>
</html>
"""


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
    sources["logos"] = load_svg_assets(repo_root, "brandbook/assets/logo", FINAL_LOGOS)
    sources["specimens"] = load_svg_assets(repo_root, "brandbook/assets/specimens", SPECIMENS)
    return sources


def render_brandbook(repo_root: Path) -> str:
    return render_page(load_sources(repo_root)).rstrip() + "\n"


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
