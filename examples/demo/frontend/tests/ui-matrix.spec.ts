import { expect, test, type Browser, type Page } from "@playwright/test";
import fs from "fs";
import path from "path";

import { backendUrl } from "./support/admin";

type ViewportCase = {
  name: "desktop" | "mobile";
  width: number;
  height: number;
};

type ThemeCase = {
  name: "light" | "dark" | "system-dark";
  colorScheme: "light" | "dark";
  storedTheme: "light" | "dark" | null;
};

type MotionCase = {
  name: "standard" | "reduce";
  reducedMotion: "no-preference" | "reduce";
};

const matrixPath = "/dev/rulestead-admin/ui-matrix";

const viewports: ViewportCase[] = [
  { name: "desktop", width: 1280, height: 900 },
  { name: "mobile", width: 390, height: 844 },
];

const themes: ThemeCase[] = [
  { name: "light", colorScheme: "light", storedTheme: "light" },
  { name: "dark", colorScheme: "light", storedTheme: "dark" },
  { name: "system-dark", colorScheme: "dark", storedTheme: null },
];

const standardMotion: MotionCase = {
  name: "standard",
  reducedMotion: "no-preference",
};

const reducedMotion: MotionCase = {
  name: "reduce",
  reducedMotion: "reduce",
};

const matrixSections = [
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
] as const;

const staticFixturePaths = [
  "../../../../rulestead_admin/priv/static/design-system.html",
  "../../../../rulestead_admin/priv/static/theme-control-harness.html",
  "../../../../rulestead_admin/priv/static/theme-harness.html",
] as const;

const adminCssPath =
  "../../../../rulestead_admin/priv/static/css/rulestead_admin.css";

const forbiddenSourceTerms = [
  "toHave" + "Screenshot",
  "match" + "Snapshot",
  "pixel" + "match",
  "visual" + "-diff",
  "pixel" + "-baseline",
  "Story" + "book",
  "Phoenix" + "Story" + "book",
  "phoenix" + "_" + "storybook",
] as const;

const phaseRequirementEvidence = {
  "CMP-01": [
    "Support trace",
    "Review Matrix Evidence",
    "No matrix examples match this section",
  ],
  "CMP-02": ["Review evidence", "Read-only policy", "Return to matrix overview"],
  "CMP-03": [
    "Destructive confirmation",
    "Unavailable confirmation",
    "Read-only confirmation",
  ],
  "CMP-04": [
    "Provenance",
    "Guardrail decision",
    "Preview uncertainty",
    "Governance severity",
    "Support-safe trace",
    "Audience trace state",
  ],
  "CMP-05": [
    "Host evidence is stale",
    "Blocked by guardrail health",
    "Authored-state boundary",
    "Hidden references",
  ],
} as const;

const browserCases = [
  ...viewports.flatMap((viewport) =>
    themes.map((theme) => ({ viewport, theme, motion: standardMotion })),
  ),
  {
    viewport: viewports[0],
    theme: themes[0],
    motion: reducedMotion,
  },
];

async function openMatrixSurface(
  browser: Browser,
  viewport: ViewportCase,
  theme: ThemeCase,
  motion: MotionCase,
) {
  const context = await browser.newContext({
    colorScheme: theme.colorScheme,
    viewport: { width: viewport.width, height: viewport.height },
    reducedMotion: motion.reducedMotion,
  });
  const page = await context.newPage();

  await page.goto(`${backendUrl}/demo/sign-in`);
  await page.waitForURL(/\/admin\/flags/);
  await page.evaluate((storedTheme) => {
    if (storedTheme) {
      localStorage.setItem("rulestead_admin.theme", storedTheme);
    } else {
      localStorage.removeItem("rulestead_admin.theme");
    }
  }, theme.storedTheme);

  await page.goto(`${backendUrl}${matrixPath}`);
  await expect(page.locator(".rs-shell")).toBeVisible();

  return { context, page };
}

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

test.describe("repo-native admin UI matrix evidence", () => {
  for (const { viewport, theme, motion } of browserCases) {
    test(`matrix renders required sections: ${theme.name} / ${viewport.name} / ${motion.name}`, async ({
      browser,
    }, testInfo) => {
      const { context, page } = await openMatrixSurface(
        browser,
        viewport,
        theme,
        motion,
      );

      try {
        for (const sectionName of matrixSections) {
          await expect(
            page.locator(`[data-matrix-section="${sectionName}"]`),
          ).toBeVisible();
        }

        await expectNoHorizontalOverflow(page);

        const sectionName = "overview-shell";
        await page
          .locator(`[data-matrix-section="${sectionName}"]`)
          .screenshot({
            path: testInfo.outputPath(
              `ui-matrix-${sectionName}-${theme.name}-${viewport.name}-${motion.name}.png`,
            ),
          });
      } finally {
        await context.close();
      }
    });
  }

  test("command palette exposes trigger, dialog, and searchable options", async ({
    browser,
  }) => {
    const { context, page } = await openMatrixSurface(
      browser,
      viewports[0],
      themes[0],
      standardMotion,
    );

    try {
      await expect(page.locator(".rs-shell__search")).toBeVisible();
      await expect(page.locator("#rs-cmdk")).toBeAttached();
      await expect(page.locator("#rs-cmdk-input")).toBeAttached();
      await expect(page.locator("#rs-cmdk [role=option]").first()).toBeAttached();

      const paletteState = await page.locator("#rs-cmdk").evaluate((element) => ({
        hidden: (element as HTMLElement).hidden,
        hook: element.getAttribute("phx-hook"),
      }));

      expect(paletteState.hidden).toBe(true);
      expect(paletteState.hook).toContain("CmdK");

      const keywords = await page
        .locator("#rs-cmdk [role=option]")
        .evaluateAll((options) =>
          options.map((option) => (option as HTMLElement).dataset.keywords ?? ""),
        );

      expect(keywords.some((keyword) => keyword.includes("audit"))).toBe(true);
    } finally {
      await context.close();
    }
  });

  test("reduced motion neutralizes nonessential task-link transforms", async ({
    browser,
  }) => {
    const { context, page } = await openMatrixSurface(
      browser,
      viewports[0],
      themes[0],
      reducedMotion,
    );

    try {
      const taskLink = page.locator(".rs-task-link").first();

      await expect(taskLink).toBeVisible();
      await taskLink.hover();

      const transform = await taskLink.evaluate((element) =>
        window.getComputedStyle(element).transform,
      );

      expect(transform).toBe("none");
    } finally {
      await context.close();
    }
  });

  test("raw audit detail contains technical overflow without page overflow", async ({
    browser,
  }) => {
    const { context, page } = await openMatrixSurface(
      browser,
      viewports[1],
      themes[0],
      standardMotion,
    );

    try {
      const rawDetail = page.locator(".rs-raw-detail").first();
      const rawPre = page.locator(".rs-raw-detail pre").first();

      await rawDetail.locator("summary").click();
      await expect(rawPre).toBeVisible();

      const metrics = await rawPre.evaluate((element) => ({
        scrollWidth: element.scrollWidth,
        clientWidth: element.clientWidth,
      }));

      expect(metrics.scrollWidth).toBeGreaterThanOrEqual(metrics.clientWidth);
      await expectNoHorizontalOverflow(page);
    } finally {
      await context.close();
    }
  });

  test("composite state labels stay visible and contained", async ({ browser }) => {
    const { context, page } = await openMatrixSurface(
      browser,
      viewports[1],
      themes[0],
      standardMotion,
    );

    try {
      for (const label of [
        "Preview uncertainty",
        "Governance severity",
        "Authored-state boundary",
        "Support-safe trace",
        "Audience trace state",
        "Guardrail decision",
        "Blocked by guardrail health",
      ]) {
        await expect(page.getByText(label).first()).toBeVisible();
      }

      const sectionBounds = await page
        .locator(
          [
            '[data-matrix-section="composites"]',
            '[data-matrix-section="rule-editor"]',
            '[data-matrix-section="rollout-panels"]',
            '[data-matrix-section="workflow-states"]',
            '[data-matrix-section="timelines"]',
          ].join(", "),
        )
        .evaluateAll((sections) =>
          sections.map((section) => {
            const rect = section.getBoundingClientRect();
            return {
              left: rect.left,
              right: rect.right,
              viewportWidth: window.innerWidth,
            };
          }),
        );

      for (const bounds of sectionBounds) {
        expect(bounds.left).toBeGreaterThanOrEqual(-1);
        expect(bounds.right).toBeLessThanOrEqual(bounds.viewportWidth + 1);
      }

      await expectNoHorizontalOverflow(page);
    } finally {
      await context.close();
    }
  });

  test("phase 116 requirement evidence stays visible without mobile overflow", async ({
    browser,
  }) => {
    const { context, page } = await openMatrixSurface(
      browser,
      viewports[1],
      themes[0],
      standardMotion,
    );

    try {
      for (const [requirement, labels] of Object.entries(
        phaseRequirementEvidence,
      )) {
        for (const label of labels) {
          await expect(
            page.getByText(label).first(),
            `${requirement} evidence label: ${label}`,
          ).toBeVisible();
        }
      }

      for (const sectionName of [
        "primitives",
        "mutation-flows",
        "composites",
        "timelines",
        "rule-editor",
        "rollout-panels",
        "workflow-states",
      ] as const) {
        await expect(
          page.locator(`[data-matrix-section="${sectionName}"]`),
        ).toBeVisible();
      }

      await expectNoHorizontalOverflow(page);
    } finally {
      await context.close();
    }
  });

  test("static token and theme fixtures remain present", () => {
    for (const fixturePath of staticFixturePaths) {
      const resolvedPath = path.resolve(__dirname, fixturePath);
      expect(fs.existsSync(resolvedPath)).toBe(true);
    }
  });

  test("admin foundation source guard markers remain present", () => {
    const source = fs.readFileSync(path.resolve(__dirname, adminCssPath), "utf8");

    expect(source).toContain("@media (prefers-reduced-motion: reduce)");
    expect(source).toContain("cmdk: inside modal");
  });

  test("matrix spec keeps screenshots as artifacts without source baselines", () => {
    const source = fs.readFileSync(
      path.resolve(__dirname, "ui-matrix.spec.ts"),
      "utf8",
    );

    for (const term of forbiddenSourceTerms) {
      expect(source.includes(term)).toBe(false);
    }
  });
});
