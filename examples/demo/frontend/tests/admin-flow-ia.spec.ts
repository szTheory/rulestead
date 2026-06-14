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
    evidence: "Find the flag that needs review",
  },
  {
    name: "rules",
    path: "/admin/flags/enable-new-dashboard/rules?env=staging",
    heading: "enable-new-dashboard",
    evidence: "First answer:",
  },
  {
    name: "kill",
    path: "/admin/flags/enable-new-dashboard/kill?env=staging",
    heading: "enable-new-dashboard kill switch",
    evidence: "Emergency evidence",
  },
  {
    name: "audience",
    path: "/admin/flags/audiences?env=staging",
    heading: "Audiences",
    evidence: "Review reusable targeting before changing flags",
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

const forbiddenSourceTerms = [
  "toHave" + "Screenshot",
  "match" + "Snapshot",
  "pixel" + "match",
  "visual" + "-diff",
  "pixel" + "-baseline",
  "Story" + "book",
  "Phoenix" + "Story" + "book",
] as const;

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

  test("command palette exposes grouped route options on a real admin route", async ({
    browser,
  }) => {
    const { context, page } = await openAdminSurface(
      browser,
      viewports[0],
      themes[0],
      "/admin/flags",
    );

    try {
      await expect(page.locator(".rs-shell__search")).toBeVisible();
      await expect(page.locator("#rs-cmdk")).toBeAttached();
      await expect(page.locator("#rs-cmdk-input")).toBeAttached();
      await expect(page.locator("#rs-cmdk [role=option]").first()).toBeAttached();

      const keywords = await page
        .locator("#rs-cmdk [role=option]")
        .evaluateAll((options) =>
          options.map((option) => (option as HTMLElement).dataset.keywords ?? ""),
        );

      expect(keywords.some((keyword) => keyword.includes("audit"))).toBe(true);
      expect(keywords.some((keyword) => keyword.includes("audiences"))).toBe(true);
    } finally {
      await context.close();
    }
  });

  test("home, inventory, and audience expose route-owned first answers", async ({
    browser,
  }) => {
    const { context: homeContext, page: homePage } = await openAdminSurface(
      browser,
      viewports[0],
      themes[0],
      "/admin/flags",
    );

    try {
      await expect(
        homePage.getByRole("navigation", { name: "Start a task" }),
      ).toBeVisible();
      await expect(
        homePage.getByRole("heading", { name: "Build & release" }),
      ).toBeVisible();
      await expect(
        homePage.getByText(/No urgent operator work|Needs you now/).first(),
      ).toBeVisible();
    } finally {
      await homeContext.close();
    }

    const { context: inventoryContext, page: inventoryPage } =
      await openAdminSurface(
        browser,
        viewports[0],
        themes[0],
        "/admin/flags/flags?env=staging&view=all",
      );

    try {
      await expect(
        inventoryPage.getByRole("heading", {
          name: "Find the flag that needs review",
        }),
      ).toBeVisible();
      await expect(
        inventoryPage.getByText(
          "First answer: filter by key, owner, tag, or description, then pick a view that explains why each result is here.",
        ),
      ).toBeVisible();
      await expect(
        inventoryPage.getByRole("navigation", { name: "Flag inventory views" }),
      ).toBeVisible();
      await expect(
        inventoryPage.getByRole("combobox", { name: "Sort" }),
      ).toBeVisible();
    } finally {
      await inventoryContext.close();
    }

    const { context: audienceContext, page: audiencePage } =
      await openAdminSurface(
        browser,
        viewports[0],
        themes[0],
        "/admin/flags/audiences?env=staging",
      );

    try {
      await expect(
        audiencePage.getByRole("region", { name: "Audience route summary" }),
      ).toBeVisible();
      await expect(
        audiencePage.getByRole("heading", {
          name: "Review reusable targeting before changing flags",
        }),
      ).toBeVisible();
      await expect(
        audiencePage.getByText("Dependency visibility can be partial"),
      ).toBeVisible();
      await expect(
        audiencePage.getByRole("table", { name: "Audience list" }),
      ).toBeVisible();
      await expect(
        audiencePage.getByRole("link", { name: "Review dependencies" }).first(),
      ).toBeVisible();
    } finally {
      await audienceContext.close();
    }
  });

  test("kill switch route keeps keyboard focus in visible route controls", async ({
    browser,
  }) => {
    const { context, page } = await openAdminSurface(
      browser,
      viewports[0],
      themes[0],
      "/admin/flags/enable-new-dashboard/kill?env=staging",
    );

    try {
      await expect(
        page.getByRole("region", { name: "Kill switch state" }).first(),
      ).toBeVisible();
      await expect(
        page
          .getByRole("region", { name: /Engage override|Release override/ })
          .first(),
      ).toBeVisible();
      await expect(
        page.getByRole("region", { name: "After-action context" }),
      ).toBeVisible();

      for (let index = 0; index < 16; index += 1) {
        await page.keyboard.press("Tab");
        const focused = await page.evaluate(() => {
          const active = document.activeElement;

          if (!(active instanceof HTMLElement)) {
            return {
              insideBody: false,
              hiddenPaletteControl: false,
            };
          }

          return {
            insideBody: document.body.contains(active),
            hiddenPaletteControl: Boolean(active.closest("#rs-cmdk[hidden]")),
          };
        });

        expect(focused.insideBody).toBe(true);
        expect(focused.hiddenPaletteControl).toBe(false);
        await expectNoHorizontalOverflow(page);
      }
    } finally {
      await context.close();
    }
  });

  test("rules and kill routes expose action sequence before dense detail", async ({
    browser,
  }) => {
    const { context: rulesContext, page: rulesPage } = await openAdminSurface(
      browser,
      viewports[0],
      themes[0],
      "/admin/flags/enable-new-dashboard/rules?env=staging",
    );

    try {
      await expect(
        rulesPage.getByRole("region", { name: "Rules publish readiness" }),
      ).toBeVisible();
      await expect(
        rulesPage.getByRole("region", { name: "Draft and publish actions" }),
      ).toBeVisible();
      await expect(
        rulesPage.getByText(/No validation blockers|Resolve validation blockers/),
      ).toBeVisible();

      const rulesOrder = await rulesPage.evaluate(() => {
        const readiness = document.querySelector(
          "[aria-label='Rules publish readiness']",
        );
        const actions = document.querySelector(
          "[aria-label='Draft and publish actions']",
        );
        const audience = document.querySelector("[aria-label='Audience library']");

        return {
          readinessBeforeActions:
            Boolean(readiness && actions) &&
            readiness.compareDocumentPosition(actions) &
              Node.DOCUMENT_POSITION_FOLLOWING,
          actionsBeforeAudience:
            Boolean(actions && audience) &&
            actions.compareDocumentPosition(audience) &
              Node.DOCUMENT_POSITION_FOLLOWING,
        };
      });

      expect(Boolean(rulesOrder.readinessBeforeActions)).toBe(true);
      expect(Boolean(rulesOrder.actionsBeforeAudience)).toBe(true);
    } finally {
      await rulesContext.close();
    }

    const { context: killContext, page: killPage } = await openAdminSurface(
      browser,
      viewports[0],
      themes[0],
      "/admin/flags/enable-new-dashboard/kill?env=staging",
    );

    try {
      await expect(
        killPage.getByRole("region", { name: "Kill switch state" }).first(),
      ).toBeVisible();
      await expect(
        killPage.getByRole("region", { name: "Emergency evidence" }),
      ).toBeVisible();
      await expect(
        killPage
          .getByRole("region", { name: /Engage override|Release override/ })
          .first(),
      ).toBeVisible();
      await expect(
        killPage.getByRole("region", { name: "After-action context" }),
      ).toBeVisible();

      const killOrder = await killPage.evaluate(() => {
        const state = document.querySelector("[aria-label='Kill switch state']");
        const evidence = document.querySelector(
          "[aria-label='Emergency evidence']",
        );
        const action = document.querySelector("[aria-label='Engage override']");
        const context = document.querySelector(
          "[aria-label='After-action context']",
        );

        return {
          stateBeforeEvidence:
            Boolean(state && evidence) &&
            state.compareDocumentPosition(evidence) &
              Node.DOCUMENT_POSITION_FOLLOWING,
          evidenceBeforeAction:
            Boolean(evidence && action) &&
            evidence.compareDocumentPosition(action) &
              Node.DOCUMENT_POSITION_FOLLOWING,
          actionBeforeContext:
            Boolean(action && context) &&
            action.compareDocumentPosition(context) &
              Node.DOCUMENT_POSITION_FOLLOWING,
        };
      });

      expect(Boolean(killOrder.stateBeforeEvidence)).toBe(true);
      expect(Boolean(killOrder.evidenceBeforeAction)).toBe(true);
      expect(Boolean(killOrder.actionBeforeContext)).toBe(true);

      await killPage.getByRole("textbox", { name: "Reason" }).focus();
      await expect(killPage.getByRole("textbox", { name: "Reason" })).toBeFocused();
    } finally {
      await killContext.close();
    }
  });

  test("admin flow spec keeps generated artifacts out of source baselines", () => {
    const source = fs.readFileSync(
      path.resolve(__dirname, "admin-flow-ia.spec.ts"),
      "utf8",
    );

    for (const term of forbiddenSourceTerms) {
      expect(source.includes(term)).toBe(false);
    }
  });
});
