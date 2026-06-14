#!/usr/bin/env python3
"""Source guard for Phase 118 design-system evidence invariants.

Checks deterministic source posture only:
  - matrix and workflow Playwright evidence keeps required coverage hooks
  - selected static contrast and backend fixture-health proof stays present
  - generated screenshots remain artifacts, not visual baselines

Usage:
    python3 scripts/check_design_system_evidence.py
"""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]

UI_MATRIX_SPEC = ROOT / "examples/demo/frontend/tests/ui-matrix.spec.ts"
ADMIN_FLOW_SPEC = ROOT / "examples/demo/frontend/tests/admin-flow-ia.spec.ts"
DESIGN_SYSTEM_SPEC = ROOT / "examples/demo/frontend/tests/design-system.spec.ts"
UI_MATRIX_LIVE_TEST = (
    ROOT / "examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs"
)

SCAN_PATHS = [
    UI_MATRIX_SPEC,
    ADMIN_FLOW_SPEC,
    DESIGN_SYSTEM_SPEC,
    ROOT / "package.json",
    ROOT / "rulestead/mix.exs",
    ROOT / "rulestead_admin/mix.exs",
    ROOT / "examples/demo/backend/mix.exs",
    ROOT / "examples/demo/frontend/package.json",
]

MATRIX_SECTIONS = [
    "overview-shell",
    "foundations-reference",
    "primitives",
    "composites",
    "mutation-flows",
    "dense-tables",
    "timelines",
    "rule-editor",
    "rollout-panels",
    "command-palette",
    "workflow-states",
    "rare-states",
    "static-fixtures",
]

WORKFLOW_ROUTES = [
    "overview",
    "inventory",
    "rules",
    "kill",
    "audience",
    "audit",
    "explain",
    "simulate",
]

WORKFLOW_LABELS = [
    "Overview",
    "Inventory",
    "Rules",
    "Kill switch",
    "Audiences",
    "Audit",
    "Explain",
    "Simulate",
]

RARE_STATES = [
    ":empty",
    ":permission_denied",
    ":read_only",
    ":unavailable",
    ":destructive",
    ":loading",
    ":error",
]

FORBIDDEN_ADOPTION_STRINGS = [
    "toHaveScreenshot(",
    ".toHaveScreenshot",
    "toMatchSnapshot(",
    "matchSnapshot(",
    "pixelmatch",
    "snapshotPath",
    "testInfo.snapshotPath",
    "__screenshots__",
    "screenshots/",
    "/screenshots",
    "-snapshots",
    "snapshots/",
    "/snapshots",
    "@storybook",
    "Storybook",
    "phoenix_storybook",
    "PhoenixStorybook",
]

MANIFEST_FORBIDDEN_ADOPTION_STRINGS = [
    '"pixelmatch"',
    "'pixelmatch'",
    '"storybook"',
    "'storybook'",
]


def read_text(path):
    try:
        return path.read_text()
    except FileNotFoundError:
        return None


def rel(path):
    return str(path.relative_to(ROOT))


def require_contains(failures, label, source, markers):
    for marker in markers:
        if marker not in source:
            failures.append(f"{label} missing required marker: {marker}")


def route_names_in_order(source):
    pattern = r'name:\s*"(' + "|".join(WORKFLOW_ROUTES) + r')"'
    return re.findall(pattern, source)


def check_ui_matrix_spec(failures):
    source = read_text(UI_MATRIX_SPEC)
    if source is None:
        failures.append(f"missing source file: {rel(UI_MATRIX_SPEC)}")
        return

    require_contains(
        failures,
        rel(UI_MATRIX_SPEC),
        source,
        [
            '/dev/rulestead-admin/ui-matrix',
            '"desktop"',
            '"mobile"',
            '"light"',
            '"dark"',
            '"system-dark"',
            "reducedMotion",
            "expectNoHorizontalOverflow",
            "#rs-cmdk",
            ".rs-task-link",
            "for (const sectionName of matrixSections)",
            'page.locator(`[data-matrix-section="${sectionName}"]`)',
            "testInfo.outputPath",
            "ui-matrix-${sectionName}-${theme.name}-${viewport.name}-${motion.name}.png",
        ],
    )

    for section in MATRIX_SECTIONS:
        if f'"{section}"' not in source and f"'{section}'" not in source:
            failures.append(f"{rel(UI_MATRIX_SPEC)} missing matrix section: {section}")


def check_admin_flow_spec(failures):
    source = read_text(ADMIN_FLOW_SPEC)
    if source is None:
        failures.append(f"missing source file: {rel(ADMIN_FLOW_SPEC)}")
        return

    routes = route_names_in_order(source)
    if routes[: len(WORKFLOW_ROUTES)] != WORKFLOW_ROUTES:
        failures.append(
            f"{rel(ADMIN_FLOW_SPEC)} route order drifted: expected {WORKFLOW_ROUTES}, got {routes[:len(WORKFLOW_ROUTES)]}"
        )

    require_contains(
        failures,
        rel(ADMIN_FLOW_SPEC),
        source,
        [
            "expectNoHorizontalOverflow",
            'page.keyboard.press("Tab")',
            "hiddenPaletteControl",
            'getByRole("textbox", { name: "Reason" })',
            "testInfo.outputPath",
            "flow-${route.name}-${theme.name}-${viewport.name}.png",
        ],
    )


def check_design_system_spec(failures):
    source = read_text(DESIGN_SYSTEM_SPEC)
    if source is None:
        failures.append(f"missing source file: {rel(DESIGN_SYSTEM_SPEC)}")
        return

    require_contains(
        failures,
        rel(DESIGN_SYSTEM_SPEC),
        source,
        [
            "--rs-text on --rs-surface",
            "--rs-on-primary",
            "badge text on soft surfaces",
            "known sub-AA exception",
            "text placeholder ratio is documented",
        ],
    )


def check_ui_matrix_live_test(failures):
    source = read_text(UI_MATRIX_LIVE_TEST)
    if source is None:
        failures.append(f"missing source file: {rel(UI_MATRIX_LIVE_TEST)}")
        return

    for label in WORKFLOW_LABELS:
        if f'"{label}"' not in source:
            failures.append(f"{rel(UI_MATRIX_LIVE_TEST)} missing route label: {label}")

    for state in RARE_STATES:
        if state not in source:
            failures.append(f"{rel(UI_MATRIX_LIVE_TEST)} missing rare state: {state}")

    require_contains(
        failures,
        rel(UI_MATRIX_LIVE_TEST),
        source,
        ['refute admin_router_source =~ "ui-matrix"'],
    )


def check_forbidden_adoption(failures):
    for path in SCAN_PATHS:
        source = read_text(path)
        if source is None:
            continue

        markers = list(FORBIDDEN_ADOPTION_STRINGS)
        if path.name in {"package.json", "mix.exs"}:
            markers.extend(MANIFEST_FORBIDDEN_ADOPTION_STRINGS)

        for marker in markers:
            if marker in source:
                failures.append(f"{rel(path)} contains forbidden visual-baseline tooling: {marker}")


def main():
    failures = []

    check_ui_matrix_spec(failures)
    check_admin_flow_spec(failures)
    check_design_system_spec(failures)
    check_ui_matrix_live_test(failures)
    check_forbidden_adoption(failures)

    if failures:
        print("DESIGN SYSTEM EVIDENCE DRIFT DETECTED")
        for failure in failures:
            print(f"  {failure}")
        return 1

    print("DESIGN SYSTEM EVIDENCE OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
