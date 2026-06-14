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

type AdminFlowRoute = {
  name:
    | "overview"
    | "inventory"
    | "rules"
    | "kill"
    | "audience"
    | "audit"
    | "explain"
    | "simulate";
  path: string;
  heading: string | RegExp;
  evidence: string | RegExp;
};

const viewports: ViewportCase[] = [
  { name: "desktop", width: 1280, height: 900 },
  { name: "mobile", width: 390, height: 844 },
];

const themes: ThemeCase[] = [
  { name: "light", colorScheme: "light", storedTheme: "light" },
  { name: "dark", colorScheme: "light", storedTheme: "dark" },
  { name: "system-dark", colorScheme: "dark", storedTheme: null },
];

const adminFlowRoutes: AdminFlowRoute[] = [
  {
    name: "overview",
    path: "/admin/flags",
    heading: /What's happening in Staging/,
    evidence: "Needs you now",
  },
  {
    name: "inventory",
    path: "/admin/flags/flags?env=staging&view=all",
    heading: "Flags",
    evidence: "Feature flags",
  },
  {
    name: "rules",
    path: "/admin/flags/enable-new-dashboard/rules?env=staging",
    heading: "enable-new-dashboard",
    evidence: "Rules workspace",
  },
  {
    name: "kill",
    path: "/admin/flags/enable-new-dashboard/kill?env=staging",
    heading: "enable-new-dashboard kill switch",
    evidence: "Authored behavior active",
  },
  {
    name: "audience",
    path: "/admin/flags/audiences?env=staging",
    heading: "Audiences",
    evidence: "Reusable targeting",
  },
  {
    name: "audit",
    path: "/admin/flags/audit?env=staging",
    heading: "Audit timeline",
    evidence: "Change history",
  },
  {
    name: "explain",
    path: "/admin/flags/enable-new-dashboard/explain?env=staging&targeting_key=support-user-42&tenant_key=acme",
    heading: "enable-new-dashboard explain",
    evidence: "Decision explainer",
  },
  {
    name: "simulate",
    path: "/admin/flags/enable-new-dashboard/simulate?env=staging",
    heading: "enable-new-dashboard simulation",
    evidence: "Simulation",
  },
];

async function openAdminSurface(
  browser: Browser,
  viewport: ViewportCase,
  theme: ThemeCase,
  path: string,
) {
  const context = await browser.newContext({
    colorScheme: theme.colorScheme,
    viewport: { width: viewport.width, height: viewport.height },
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

  await page.goto(`${backendUrl}${path}`);
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

test.describe("admin flow IA route evidence", () => {
  test("covers the selected primary admin route clusters", () => {
    expect(adminFlowRoutes.map((route) => route.name)).toEqual([
      "overview",
      "inventory",
      "rules",
      "kill",
      "audience",
      "audit",
      "explain",
      "simulate",
    ]);
  });

  for (const viewport of viewports) {
    for (const theme of themes) {
      for (const route of adminFlowRoutes) {
        test(`route ${route.name} renders shell evidence: ${theme.name} / ${viewport.name}`, async ({
          browser,
        }, testInfo) => {
          const { context, page } = await openAdminSurface(
            browser,
            viewport,
            theme,
            route.path,
          );

          try {
            await expect(
              page.getByRole("heading", { name: route.heading }).first(),
            ).toBeVisible();
            await expect(page.getByText(route.evidence).first()).toBeVisible();
            await expectNoHorizontalOverflow(page);

            await page.screenshot({
              fullPage: true,
              path: testInfo.outputPath(
                `flow-${route.name}-${theme.name}-${viewport.name}.png`,
              ),
            });
          } finally {
            await context.close();
          }
        });
      }
    }
  }
});
