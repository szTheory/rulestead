import { expect, test } from "@playwright/test";

import { backendUrl, waitForAdminLiveView } from "./support/admin";

test("pinned light theme is primed before paint and survives shell navigation", async ({
  browser,
}) => {
  const context = await browser.newContext({ colorScheme: "dark" });

  await context.addInitScript(() => {
    localStorage.setItem("rulestead_admin.theme", "light");

    const windowWithSamples = window as unknown as {
      __rsDocId: string;
      __rsThemeSamples: Array<{
        label: string;
        path: string;
        hasShell: boolean;
        hasControl: boolean;
        attr: string | null;
        pending: boolean | null;
        checked: string | null;
        bg: string | null;
      }>;
    };

    windowWithSamples.__rsDocId = Math.random().toString(36).slice(2);
    windowWithSamples.__rsThemeSamples = [];

    const sample = (label: string) => {
      const shell = document.querySelector(".rs-shell");
      const control = document.querySelector("#rs-theme-control");
      const checked = control?.querySelector(
        "[role=menuitemradio][aria-checked='true']",
      );

      windowWithSamples.__rsThemeSamples.push({
        label,
        path: location.pathname + location.search,
        hasShell: Boolean(shell),
        hasControl: Boolean(control),
        attr: shell?.getAttribute("data-theme") ?? null,
        pending: shell?.hasAttribute("data-theme-pending") ?? null,
        checked: checked?.getAttribute("data-value") ?? null,
        bg: shell
          ? getComputedStyle(shell).getPropertyValue("--rs-bg").trim()
          : null,
      });
    };

    const observer = new MutationObserver(() => sample("mutation"));
    observer.observe(document.documentElement, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["data-theme", "data-theme-pending", "aria-checked"],
    });

    document.addEventListener("DOMContentLoaded", () =>
      sample("domcontentloaded"),
    );
    window.addEventListener("load", () => sample("load"));
    setTimeout(() => observer.disconnect(), 2_000);
  });

  const page = await context.newPage();
  await page.goto(`${backendUrl}/demo/sign-in`);
  await page.waitForURL(/\/admin\/flags/);
  await waitForAdminLiveView(page);

  const shell = page.locator(".rs-shell");
  await expect(shell).toHaveAttribute("data-theme", "light");
  await expect(shell).not.toHaveAttribute("data-theme-pending", /.+/);
  await expect(
    page.locator("#rs-theme-control [data-value='light']"),
  ).toHaveAttribute("aria-checked", "true");
  await expect(page.locator("#rs-theme-trigger")).toHaveAttribute(
    "aria-label",
    "Theme: Light",
  );

  const documentId = await page.evaluate(
    () => (window as unknown as { __rsDocId: string }).__rsDocId,
  );

  const experimentsLink = page.locator(".rs-shell__rail-link", {
    hasText: "Experiments",
  });
  await expect(experimentsLink).toHaveAttribute("data-phx-link", "redirect");

  await experimentsLink.click();
  await page.waitForURL(/\/admin\/flags\/experiments\?env=staging/);
  await waitForAdminLiveView(page);
  await expect(page.locator(".rs-shell__breadcrumb-current")).toHaveText(
    "Experiments",
  );
  await expect(page.locator(".rs-shell__page-summary")).toContainText(
    "Dense operator inventory for experiments",
  );
  await expect(page.locator(".rs-shell__header h1")).toHaveCount(0);
  await expect(shell).toHaveAttribute("data-theme", "light");

  await expect
    .poll(
      async () =>
        page.evaluate(
          () => (window as unknown as { __rsDocId: string }).__rsDocId,
        ),
      { message: "admin shell navigation should not reload the document" },
    )
    .toBe(documentId);

  const brandLink = page.locator(".rs-shell__brand");
  await expect(brandLink).toBeVisible();
  await expect(brandLink).toHaveAttribute(
    "href",
    /\/admin\/flags\?env=staging$/,
  );
  await expect(brandLink.locator(".rs-shell__wordmark")).toHaveAttribute(
    "viewBox",
    "0 0 372 64",
  );
  await brandLink.click();
  await page.waitForURL(/\/admin\/flags\?env=staging$/);
  await waitForAdminLiveView(page);
  await expect(page.locator(".rs-shell__breadcrumb-current")).toHaveText(
    "Overview",
  );
  await expect(page.locator(".rs-shell__page-summary")).toContainText(
    "A live read of this environment",
  );
  await expect(page.locator(".rs-shell__kicker")).toHaveCount(0);
  await expect(shell).toHaveAttribute("data-theme", "light");
  await expect(page.locator("#rs-theme-trigger")).toHaveAttribute(
    "aria-label",
    "Theme: Light",
  );

  await expect
    .poll(
      async () =>
        page.evaluate(
          () => (window as unknown as { __rsDocId: string }).__rsDocId,
        ),
      { message: "brand overview navigation should not reload the document" },
    )
    .toBe(documentId);

  const samples = await page.evaluate(
    () =>
      (
        window as unknown as {
          __rsThemeSamples: Array<{
            label: string;
            path: string;
            hasShell: boolean;
            hasControl: boolean;
            attr: string | null;
            pending: boolean | null;
            checked: string | null;
            bg: string | null;
          }>;
        }
      ).__rsThemeSamples,
  );

  const badSamples = samples.filter(
    (sample) =>
      sample.path.startsWith("/admin/") &&
      sample.hasShell &&
      (sample.attr !== "light" ||
        (sample.hasControl && sample.checked !== "light") ||
        (sample.hasControl && sample.pending)),
  );

  expect(badSamples).toEqual([]);

  await context.close();
});
