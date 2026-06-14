import { expect, test, type Browser, type Page } from "@playwright/test";

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
});
