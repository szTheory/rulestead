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

const viewports: ViewportCase[] = [
  { name: "desktop", width: 1280, height: 900 },
  { name: "mobile", width: 390, height: 844 },
];

const themes: ThemeCase[] = [
  { name: "light", colorScheme: "light", storedTheme: "light" },
  { name: "dark", colorScheme: "light", storedTheme: "dark" },
  { name: "system-dark", colorScheme: "dark", storedTheme: null },
];

const fleetdeskFrontendUrl = new URL(
  process.env.DEMO_FRONTEND_URL ?? "http://127.0.0.1:3000",
);
const fleetdeskFrontendHref = fleetdeskFrontendUrl.href;
const fleetdeskFrontendOrigin = fleetdeskFrontendUrl.origin;

const adminSurfaces = [
  { name: "overview", path: "/admin/flags" },
  { name: "inventory", path: "/admin/flags/flags?env=staging&view=all" },
  { name: "rollouts", path: "/admin/flags/fleet-map-v2/rollouts?env=staging" },
  { name: "diagnostics", path: "/admin/flags/diagnostics" },
  { name: "review", path: "/admin/flags/change-requests" },
  { name: "explain", path: "/admin/flags/enable-new-dashboard/explain" },
  { name: "kill", path: "/admin/flags/enable-new-dashboard/kill" },
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

async function expectResolvedHref(
  locator: ReturnType<Page["getByRole"]>,
  expectedHref: string,
) {
  const actualHref = await locator.evaluate((element) => {
    if (!(element instanceof HTMLAnchorElement)) {
      throw new Error("Expected link locator to resolve to an anchor element");
    }

    return element.href;
  });

  expect(actualHref).toBe(expectedHref);
}

test.describe("brand-faithful UI evidence", () => {
  for (const viewport of viewports) {
    for (const theme of themes) {
      for (const surface of adminSurfaces) {
        test(`admin ${surface.name} renders branded shell: ${theme.name} / ${viewport.name}`, async ({
          browser,
        }, testInfo) => {
          const { context, page } = await openAdminSurface(
            browser,
            viewport,
            theme,
            surface.path,
          );

          await expect(page.locator(".rs-shell__brand").first()).toBeVisible();
          await expect(
            page.locator(".rs-shell__wordmark").first(),
          ).toBeVisible();
          await expect(
            page.locator(".rs-theme-control__group").first(),
          ).toBeVisible();
          await expectNoHorizontalOverflow(page);

          await page.screenshot({
            fullPage: true,
            path: testInfo.outputPath(
              `admin-${surface.name}-${theme.name}-${viewport.name}.png`,
            ),
          });

          await context.close();
        });
      }
    }
  }

  for (const viewport of viewports) {
    for (const colorScheme of ["light", "dark"] as const) {
      test(`demo launcher uses Rulestead chrome: ${colorScheme} / ${viewport.name}`, async ({
        browser,
      }, testInfo) => {
        const context = await browser.newContext({
          colorScheme,
          viewport: { width: viewport.width, height: viewport.height },
        });
        const page = await context.newPage();

        await page.goto(backendUrl);
        await expect(
          page.getByRole("main").getByAltText("Rulestead"),
        ).toBeVisible();
        await expectResolvedHref(
          page.getByRole("link", { name: "FleetDesk app" }),
          fleetdeskFrontendHref,
        );
        await expectResolvedHref(
          page.getByRole("link", { name: "FleetDesk", exact: true }),
          fleetdeskFrontendHref,
        );
        await expect(
          page.getByRole("heading", { name: /FleetDesk host/ }),
        ).toBeVisible();
        await expectNoHorizontalOverflow(page);

        await page.screenshot({
          fullPage: true,
          path: testInfo.outputPath(
            `demo-launcher-${colorScheme}-${viewport.name}.png`,
          ),
        });

        await context.close();
      });

      test(`FleetDesk launcher click-through reaches selected origin: ${colorScheme} / ${viewport.name}`, async ({
        browser,
      }) => {
        const context = await browser.newContext({
          colorScheme,
          viewport: { width: viewport.width, height: viewport.height },
        });
        const page = await context.newPage();

        await page.goto(backendUrl);
        await page.getByRole("link", { name: "FleetDesk app" }).click();

        expect(new URL(page.url()).origin).toBe(fleetdeskFrontendOrigin);
        await expect(page.locator(".fd-brand-name")).toHaveText("FleetDesk");
        await expect(page.locator(".fd-brand-mark")).toHaveText("FD");
        await expect(
          page.getByRole("heading", { name: "Live map" }),
        ).toBeVisible();

        await context.close();
      });

      test(`FleetDesk remains host-branded: ${colorScheme} / ${viewport.name}`, async ({
        browser,
      }, testInfo) => {
        const context = await browser.newContext({
          colorScheme,
          viewport: { width: viewport.width, height: viewport.height },
        });
        const page = await context.newPage();

        await page.goto("/");
        await expect(page.locator(".fd-brand-name")).toHaveText("FleetDesk");
        await expect(page.locator(".fd-brand-mark")).toHaveText("FD");
        await expect(
          page.getByRole("heading", { name: "Live map" }),
        ).toBeVisible();
        await expectNoHorizontalOverflow(page);

        await page.screenshot({
          fullPage: true,
          path: testInfo.outputPath(
            `fleetdesk-${colorScheme}-${viewport.name}.png`,
          ),
        });

        await context.close();
      });
    }
  }
});
