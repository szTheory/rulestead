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

UNSAFE_SVG_MARKERS = ["base64", "<image", "<script", "<foreignObject"]


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


def asset_label(filename: str) -> str:
    return Path(filename).stem.replace("-", " ").title()


def asset_prefix(filename: str) -> str:
    return f"{Path(filename).stem}__"


def assert_safe_svg(rel_path: str, svg_text: str) -> None:
    lowered = svg_text.lower()
    for marker in UNSAFE_SVG_MARKERS:
        if marker.lower() in lowered:
            raise BrandbookError(f"ERROR: unsafe SVG content in {rel_path}")


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
        swatches.append(
            '<article class="swatch" style="--swatch-color: '
            f'{html.escape(value, quote=True)}">'
            '<span class="swatch__chip" aria-hidden="true"></span>'
            f'<strong>{html.escape(token["name"])}</strong>'
            f'<code>{html.escape(value)}</code>'
            "</article>"
        )
    return '<div class="swatch-grid">' + "".join(swatches) + "</div>"


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


def render_asset_grid(assets: list[dict[str, Any]]) -> str:
    cards = []
    for asset in assets:
        href = page_href(asset["source_path"])
        cards.append(
            '<figure class="asset-card">'
            f'<div class="asset-preview">{asset["svg"]}</div>'
            f'<figcaption><strong>{html.escape(asset["label"])}</strong>'
            f'<span>{asset["bytes"]} bytes</span>'
            f'<a href="{html.escape(href, quote=True)}">{html.escape(href)}</a>'
            "</figcaption>"
            "</figure>"
        )
    return '<div class="asset-grid">' + "".join(cards) + "</div>"


def css_declarations(mapping: dict[str, Any]) -> str:
    lines = []
    for name, value in sorted(mapping.items()):
        if name.startswith("--rs-"):
            lines.append(f"  {name}: {value};")
    return "\n".join(lines)


def root_css_declarations(css_text: str) -> str:
    declarations = extract_css_declarations(strip_css_comments(css_text), ":root")
    return "\n".join(f"  {name}: {value};" for name, value in sorted(declarations.items()))


def render_styles(sources: dict[str, Any]) -> str:
    mappings = sources["tokens"]["admin_css_mapping"]
    css_root = root_css_declarations(sources["brandbook/tokens.css"])
    light = css_declarations(mappings["light"])
    dark = css_declarations(mappings["dark"])
    return f"""
body {{
  margin: 0;
}}

[data-rulestead-brandbook] {{
{css_root}
{light}
  --rs-bg: var(--rs-neutral-50);
  --rs-surface: var(--rs-neutral-0);
  --rs-surface-muted: var(--rs-neutral-100);
  --rs-text: var(--rs-neutral-900);
  --rs-text-muted: var(--rs-neutral-600);
  --rs-border: var(--rs-neutral-300);
  --rs-border-subtle: var(--rs-neutral-200);
  --rs-focus-ring: 0 0 0 2px var(--rs-neutral-0), 0 0 0 4px var(--rs-primary);
  min-height: 100vh;
  background: var(--rs-bg);
  color: var(--rs-text);
  font-family: var(--rs-font-sans);
  font-size: var(--rs-text-base);
  line-height: var(--rs-leading-normal);
  letter-spacing: 0;
}}

@media (prefers-color-scheme: dark) {{
  [data-rulestead-brandbook]:not([data-theme]) {{
{dark}
    --rs-bg: var(--rs-neutral-50);
    --rs-surface: var(--rs-neutral-25);
    --rs-surface-muted: var(--rs-neutral-100);
    --rs-text: var(--rs-neutral-900);
    --rs-text-muted: var(--rs-neutral-600);
    --rs-border: var(--rs-neutral-300);
    --rs-border-subtle: var(--rs-neutral-200);
    --rs-focus-ring: 0 0 0 2px var(--rs-neutral-0), 0 0 0 4px var(--rs-primary);
  }}
}}

[data-rulestead-brandbook][data-theme="light"] {{
{light}
}}

[data-rulestead-brandbook][data-theme="dark"] {{
{dark}
  --rs-bg: var(--rs-neutral-50);
  --rs-surface: var(--rs-neutral-25);
  --rs-surface-muted: var(--rs-neutral-100);
  --rs-text: var(--rs-neutral-900);
  --rs-text-muted: var(--rs-neutral-600);
  --rs-border: var(--rs-neutral-300);
  --rs-border-subtle: var(--rs-neutral-200);
  --rs-focus-ring: 0 0 0 2px var(--rs-neutral-0), 0 0 0 4px var(--rs-primary);
}}

[data-rulestead-brandbook] *,
[data-rulestead-brandbook] *::before,
[data-rulestead-brandbook] *::after {{
  box-sizing: border-box;
}}

[data-rulestead-brandbook] a {{
  color: var(--rs-primary);
  font-weight: 600;
}}

[data-rulestead-brandbook] a:focus-visible,
[data-rulestead-brandbook] button:focus-visible {{
  outline: none;
  box-shadow: var(--rs-focus-ring);
}}

.brand-shell {{
  max-width: var(--rs-shell-max);
  margin: 0 auto;
  padding: 24px;
}}

.brand-header {{
  display: grid;
  gap: 24px;
  padding: 24px 0 32px;
  border-bottom: 1px solid var(--rs-border-subtle);
}}

.brand-identity {{
  display: grid;
  gap: 16px;
}}

.brand-identity svg {{
  width: min(360px, 100%);
  height: auto;
}}

.brand-title {{
  max-width: 760px;
}}

.brand-title h1 {{
  margin: 0 0 8px;
  font-family: var(--rs-font-display);
  font-size: 2rem;
  line-height: var(--rs-leading-tight);
  font-weight: 600;
  letter-spacing: 0;
}}

.brand-title p {{
  margin: 0;
  max-width: 66ch;
  color: var(--rs-text-muted);
}}

.theme-control {{
  display: inline-flex;
  width: fit-content;
  min-height: 44px;
  padding: 4px;
  gap: 4px;
  border: 1px solid var(--rs-border);
  border-radius: var(--rs-radius-full);
  background: var(--rs-surface);
}}

.theme-control button {{
  min-height: 36px;
  border: 1px solid transparent;
  border-radius: var(--rs-radius-full);
  padding: 0 14px;
  background: transparent;
  color: var(--rs-text-muted);
  font: inherit;
  font-weight: 600;
}}

.theme-control [aria-checked="true"] {{
  border-color: var(--rs-primary);
  background: var(--rs-primary-soft, var(--rs-surface-muted));
  color: var(--rs-primary-hover, var(--rs-primary));
}}

.brand-nav {{
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}}

.brand-nav a,
.source-refs a {{
  display: inline-flex;
  min-height: 32px;
  align-items: center;
  border: 1px solid var(--rs-border-subtle);
  border-radius: var(--rs-radius-sm);
  padding: 4px 8px;
  background: var(--rs-surface);
  color: var(--rs-text);
  font-size: var(--rs-text-sm);
  text-decoration: none;
}}

.brand-main {{
  display: grid;
  gap: 32px;
  padding: 32px 0;
}}

.brand-section {{
  display: grid;
  gap: 16px;
  padding: 32px 0;
  border-bottom: 1px solid var(--rs-border-subtle);
}}

.brand-section h2 {{
  margin: 0;
  font-family: var(--rs-font-display);
  font-size: 1.4rem;
  line-height: var(--rs-leading-tight);
  font-weight: 600;
  letter-spacing: 0;
}}

.section-copy {{
  max-width: 78ch;
}}

.section-copy h3,
.section-copy h4,
.doc-excerpt h3 {{
  margin: 24px 0 8px;
  font-family: var(--rs-font-display);
  font-size: 1.05rem;
  line-height: var(--rs-leading-snug);
  font-weight: 600;
  letter-spacing: 0;
}}

.section-copy p,
.section-copy li {{
  color: var(--rs-text);
}}

.section-copy blockquote {{
  margin: 16px 0;
  border-left: 3px solid var(--rs-accent);
  padding-left: 16px;
  color: var(--rs-text-muted);
}}

.source-refs {{
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}}

.source-refs span {{
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: var(--rs-text-xs);
}}

.swatch-grid,
.asset-grid,
.doc-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}}

.swatch,
.asset-card,
.doc-excerpt {{
  border: 1px solid var(--rs-border-subtle);
  border-radius: 8px;
  background: var(--rs-surface);
}}

.swatch {{
  display: grid;
  gap: 8px;
  padding: 12px;
}}

.swatch__chip {{
  display: block;
  aspect-ratio: 4 / 1;
  border: 1px solid var(--rs-border-subtle);
  border-radius: 6px;
  background: var(--swatch-color);
}}

code,
pre {{
  font-family: var(--rs-font-mono);
}}

.section-copy code,
.swatch code,
table code {{
  font-size: var(--rs-text-xs);
}}

pre {{
  overflow: auto;
  border-radius: 8px;
  padding: 16px;
  background: var(--rs-neutral-0);
  color: var(--rs-text);
}}

table {{
  width: 100%;
  border-collapse: collapse;
  overflow-wrap: anywhere;
}}

th,
td {{
  border-bottom: 1px solid var(--rs-border-subtle);
  padding: 10px 8px;
  text-align: left;
  vertical-align: top;
}}

th {{
  color: var(--rs-text-muted);
  font-size: var(--rs-text-sm);
  font-weight: 600;
}}

.asset-card {{
  margin: 0;
  overflow: hidden;
}}

.asset-preview {{
  display: grid;
  min-height: 180px;
  aspect-ratio: 16 / 9;
  place-items: center;
  overflow: hidden;
  padding: 16px;
  background: var(--rs-surface-muted);
}}

.asset-preview svg {{
  max-width: min(100%, 720px);
  max-height: 100%;
  height: auto;
}}

.asset-card figcaption {{
  display: grid;
  gap: 4px;
  padding: 12px;
}}

.asset-card figcaption span,
.asset-card figcaption a {{
  color: var(--rs-text-muted);
  font-family: var(--rs-font-mono);
  font-size: var(--rs-text-xs);
}}

.doc-excerpt {{
  padding: 16px;
}}

.brand-footer {{
  padding: 24px 0;
  color: var(--rs-text-muted);
  font-size: var(--rs-text-sm);
}}

@media (max-width: 720px) {{
  .brand-shell {{
    padding: 16px;
  }}

  .brand-header {{
    padding-top: 16px;
  }}
}}
"""


def render_section(section_id: str, refs: list[str], body: str) -> str:
    title = section_title(section_id)
    return (
        f'<section id="{section_id}" class="brand-section">\n'
        f"<h2>{html.escape(title)}</h2>\n"
        f"{source_refs(refs)}\n"
        f'<div class="section-copy">{body}</div>\n'
        "</section>"
    )


def render_overview(sources: dict[str, Any]) -> str:
    return brand_section_html(sources, ["3", "4", "5", "26", "27"])


def render_voice(sources: dict[str, Any]) -> str:
    return (
        brand_section_html(sources, ["7", "8", "9", "19"])
        + '<div class="doc-grid">'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/VOICE.md"])}</article>'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/COPY.md"])}</article>'
        + "</div>"
    )


def render_color(sources: dict[str, Any]) -> str:
    tokens = sources["tokens"]
    return (
        brand_section_html(sources, ["12"])
        + "<h3>Primitive palette</h3>"
        + render_color_swatches(tokens["primitive"])
        + "<h3>Light semantic tokens</h3>"
        + token_rows(tokens["light"])
        + "<h3>Dark semantic tokens</h3>"
        + token_rows(tokens["dark"])
        + render_asset_grid([asset for asset in sources["specimens"] if asset["source_path"].endswith("/palette.svg")])
    )


def render_typography(sources: dict[str, Any]) -> str:
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


def render_logo(sources: dict[str, Any]) -> str:
    return brand_section_html(sources, ["14"]) + render_asset_grid(sources["logos"])


def render_layout_components(sources: dict[str, Any]) -> str:
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


def render_iconography_imagery(sources: dict[str, Any]) -> str:
    specimen_names = {"/readme-header.svg", "/social-card.svg"}
    specimens = [asset for asset in sources["specimens"] if any(asset["source_path"].endswith(name) for name in specimen_names)]
    return brand_section_html(sources, ["16", "17"]) + render_asset_grid(specimens)


def render_motion(sources: dict[str, Any]) -> str:
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


def render_assets_maintenance(sources: dict[str, Any]) -> str:
    return (
        brand_section_html(sources, ["25"])
        + '<div class="doc-grid">'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/README.md"])}</article>'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/BUDGET.md"])}</article>'
        + f'<article class="doc-excerpt">{render_markdown(sources["brandbook/docs/brand-usage.md"])}</article>'
        + "</div>"
    )


def render_page(sources: dict[str, Any]) -> str:
    tagline = extract_tagline(sources)
    hero_logo = prefix_svg_ids(sources["logos"][0]["source_path"], sources["logos"][0]["svg"], "hero-")
    nav = "".join(
        f'<a href="#{section_id}">{html.escape(section_title(section_id))}</a>' for section_id in SECTION_ORDER
    )

    section_bodies = {
        "overview": (
            ["brandbook/brand-book.md", "brandbook/assets/logo/rs-wordmark.svg"],
            render_overview(sources),
        ),
        "voice-and-messaging": (
            ["brandbook/brand-book.md", "brandbook/VOICE.md", "brandbook/COPY.md"],
            render_voice(sources),
        ),
        "color": (
            ["brandbook/brand-book.md", "brandbook/tokens.json", "brandbook/assets/specimens/palette.svg"],
            render_color(sources),
        ),
        "typography": (
            ["brandbook/brand-book.md", "brandbook/tokens.css", "brandbook/assets/specimens/typography.svg"],
            render_typography(sources),
        ),
        "logo": (
            ["brandbook/brand-book.md", *[asset["source_path"] for asset in sources["logos"]]],
            render_logo(sources),
        ),
        "layout-and-components": (
            ["brandbook/brand-book.md", "brandbook/tokens.json", "brandbook/assets/specimens/components.svg", "brandbook/assets/specimens/code-block.svg"],
            render_layout_components(sources),
        ),
        "iconography-and-imagery": (
            ["brandbook/brand-book.md", "brandbook/assets/specimens/readme-header.svg", "brandbook/assets/specimens/social-card.svg"],
            render_iconography_imagery(sources),
        ),
        "motion": (
            ["brandbook/brand-book.md", "brandbook/tokens.css"],
            render_motion(sources),
        ),
        "assets-and-maintenance": (
            ["brandbook/brand-book.md", "brandbook/README.md", "brandbook/BUDGET.md", "brandbook/docs/brand-usage.md", "scripts/gen_brandbook_html.py"],
            render_assets_maintenance(sources),
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
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=Inter:wght@400;600&family=Sora:wght@400;600&display=swap" rel="stylesheet">
  <style>
{render_styles(sources)}
  </style>
</head>
<body>
  <div data-rulestead-brandbook>
    <div class="brand-shell">
      <header class="brand-header">
        <div class="brand-identity">
          {hero_logo}
          <div class="brand-title">
            <h1>Rulestead Brand Book</h1>
            <p>{html.escape(tagline)}</p>
          </div>
        </div>
        <div class="theme-control" role="radiogroup" aria-label="Theme">
          <button type="button" role="radio" aria-checked="true">System</button>
          <button type="button" role="radio" aria-checked="false">Light</button>
          <button type="button" role="radio" aria-checked="false">Dark</button>
        </div>
        <nav class="brand-nav" aria-label="Brand book sections">
          {nav}
        </nav>
      </header>
      <main class="brand-main">
        {sections}
      </main>
      <footer class="brand-footer">
        Generated from canonical brandbook sources by <code>scripts/gen_brandbook_html.py</code>.
      </footer>
    </div>
  </div>
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
