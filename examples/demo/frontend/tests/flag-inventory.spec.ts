import { expect, test } from "@playwright/test";

import {
  backendUrl,
  openAdminPage,
  waitForAdminLiveView,
} from "./support/admin";

test("admin flag inventory lists FleetDesk adoption-lab seeds", async ({
  browser,
}) => {
  const adminPage = await openAdminPage(browser);

  // The admin home now lives at the mount root; the flag inventory moved to /flags.
  await adminPage.goto(`${backendUrl}/admin/flags/flags?env=staging&view=all`);
  await waitForAdminLiveView(adminPage);

  await expect(
    adminPage.getByRole("heading", { name: /Feature flags/ }),
  ).toBeVisible();
  await expect(adminPage.locator(".rs-shell__breadcrumbs")).toBeVisible();
  await expect(adminPage.locator(".rs-shell__breadcrumb-current")).toHaveText(
    "Flags",
  );
  await expect(
    adminPage.locator(".rs-shell__breadcrumbs a", { hasText: "Flags" }),
  ).toHaveCount(0);

  for (const key of [
    "enable-new-dashboard",
    "fleet-map-v2",
    "dispatch-ops-copy",
    "ops-banner-config",
  ]) {
    await expect(adminPage.getByText(key).first()).toBeVisible();
  }

  const response = await adminPage.request.get(
    `${backendUrl}/api/demo/personas`,
  );
  expect(response.ok()).toBeTruthy();
});

test("diagnostics page actions stay out of the stable shell header", async ({
  browser,
}) => {
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
  });
  const adminPage = await context.newPage();

  await adminPage.goto(`${backendUrl}/demo/sign-in`);
  await adminPage.waitForURL(/\/admin\/flags/);
  await adminPage.goto(`${backendUrl}/admin/flags/flags?env=staging&view=all`);
  await waitForAdminLiveView(adminPage);
  await expect(
    adminPage.getByRole("heading", { name: /Feature flags/ }),
  ).toBeVisible();
  await expect(adminPage.locator(".rs-shell__header h1")).toHaveCount(0);

  const inventoryHeaderHeight = await adminPage
    .locator(".rs-shell__header")
    .evaluate((node) => Math.round(node.getBoundingClientRect().height));

  await adminPage.goto(`${backendUrl}/admin/flags/diagnostics?env=staging`);
  await waitForAdminLiveView(adminPage);
  await expect(adminPage.locator(".rs-shell__breadcrumb-current")).toHaveText(
    "Diagnostics",
  );
  await expect(adminPage.locator(".rs-shell__page-summary")).toHaveText(
    "Read current-node cache freshness, sync latency, and adapter health without leaving the mounted admin surface.",
  );
  await expect(adminPage.locator(".rs-shell__header h1")).toHaveCount(0);
  await expect(adminPage.locator("main h1.sr-only")).toHaveText("Diagnostics");

  const brand = adminPage.locator(".rs-shell__brand");
  await expect(brand).toBeVisible();
  await expect(brand).toHaveAttribute("href", /\/admin\/flags\?env=staging$/);
  const wordmark = brand.locator(".rs-shell__wordmark");
  await expect(wordmark).toBeVisible();
  await expect(wordmark).toHaveAttribute("viewBox", "0 0 372 64");
  await expect(brand.locator(".rs-shell__brand-word")).toHaveCount(0);
  await expect(brand.locator(".rs-shell__brand-mark")).toHaveCount(0);
  await expect(adminPage.locator(".rs-shell__kicker")).toHaveCount(0);
  await expect(adminPage.locator(".rs-shell__brand-divider")).toHaveCount(0);
  await expect(
    adminPage.locator(".rs-shell__header .rs-shell__context-label"),
  ).toHaveCount(0);
  await expect(
    adminPage.locator(".rs-shell__header .rs-shell__context-help"),
  ).toHaveCount(0);
  await expect(adminPage.locator(".rs-theme-control__group")).toHaveCount(0);

  const accessReadout = adminPage.locator(".rs-shell__access-readout");
  await expect(accessReadout).toBeVisible();
  await expect(accessReadout).toContainText("Access");
  await expect(accessReadout).toContainText("Admin");
  await expect(accessReadout).toHaveAttribute("data-capability", "admin");
  await expect(accessReadout).toHaveAttribute("title", /Edit: true/);
  await expect(
    adminPage.locator(".rs-shell__header .rs-shell__context-item", {
      hasText: "Admin",
    }),
  ).toHaveCount(0);

  const envTrigger = adminPage.locator("#rs-env-trigger");
  await expect(envTrigger).toBeVisible();
  await expect(envTrigger).toHaveAttribute("aria-haspopup", "menu");
  await expect(envTrigger).toHaveAttribute("aria-expanded", "false");
  await expect(envTrigger).toHaveAttribute(
    "aria-label",
    "Environment: Staging",
  );
  await expect(envTrigger).toContainText("Staging");
  await expect(envTrigger).not.toContainText("Viewing");
  await envTrigger.click();
  const envMenu = adminPage.locator("#rs-env-menu");
  await expect(envMenu).toBeVisible();
  await expect(envMenu.locator("[data-current='true']")).toContainText(
    "Staging",
  );
  await expect(envMenu.locator("a[data-current='true']")).toHaveCount(0);
  await envMenu.locator("a", { hasText: "Production" }).click();
  await expect(adminPage).toHaveURL(/env=prod/);
  await waitForAdminLiveView(adminPage);
  await expect(adminPage.locator("#rs-env-trigger")).toHaveAttribute(
    "aria-label",
    "Environment: Production",
  );
  const envTriggerLayout = await adminPage
    .locator("#rs-env-trigger")
    .evaluate((node) => {
      const tone = node.querySelector(".rs-env-switcher__tone");
      const label = node.querySelector(".rs-env-switcher__trigger-label");
      const chevron = node.querySelector(".rs-env-switcher__chevron");
      const triggerRect = node.getBoundingClientRect();
      const toneRect = tone?.getBoundingClientRect();
      const labelRect = label?.getBoundingClientRect();
      const chevronRect = chevron?.getBoundingClientRect();
      const triggerStyle = window.getComputedStyle(node);
      const toneStyle = tone ? window.getComputedStyle(tone) : null;

      return {
        labelAfterTone: Math.round(
          (labelRect?.left ?? 0) - (toneRect?.right ?? 0),
        ),
        toneCenterDeltaY: Math.round(
          (toneRect?.top ?? 0) +
            (toneRect?.height ?? 0) / 2 -
            (triggerRect.top + triggerRect.height / 2),
        ),
        chevronInset: Math.round(triggerRect.right - (chevronRect?.right ?? 0)),
        triggerRadius: Math.round(parseFloat(triggerStyle.borderRadius)),
        triggerHeight: Math.round(triggerRect.height),
        toneShadow: toneStyle?.boxShadow ?? "",
      };
    });

  expect(envTriggerLayout.labelAfterTone).toBeGreaterThanOrEqual(4);
  expect(envTriggerLayout.labelAfterTone).toBeLessThanOrEqual(12);
  expect(Math.abs(envTriggerLayout.toneCenterDeltaY)).toBeLessThanOrEqual(1);
  expect(envTriggerLayout.chevronInset).toBeGreaterThanOrEqual(4);
  expect(envTriggerLayout.chevronInset).toBeLessThanOrEqual(12);
  expect(envTriggerLayout.triggerRadius).toBeGreaterThanOrEqual(8);
  expect(envTriggerLayout.triggerRadius).toBeLessThanOrEqual(12);
  expect(envTriggerLayout.triggerHeight).toBeGreaterThanOrEqual(40);
  expect(envTriggerLayout.toneShadow).toBe("none");

  const themeTrigger = adminPage.locator("#rs-theme-trigger");
  await expect(themeTrigger).toBeVisible();
  await expect(themeTrigger).toHaveAttribute("aria-haspopup", "menu");
  await expect(themeTrigger).toHaveAttribute("aria-expanded", "false");
  await expect(themeTrigger).toHaveAttribute("aria-label", "Theme: System");
  const themeTriggerWidth = await themeTrigger.evaluate((node) =>
    Math.round(node.getBoundingClientRect().width),
  );
  expect(themeTriggerWidth).toBeLessThanOrEqual(150);
  await expect
    .poll(async () =>
      themeTrigger.evaluate((node) =>
        Math.round(parseFloat(window.getComputedStyle(node).borderRadius)),
      ),
    )
    .toBeLessThanOrEqual(12);

  const controlMetrics = await adminPage
    .locator(".rs-shell__controls")
    .evaluate((root) =>
      Array.from(
        root.querySelectorAll(".rs-shell__access, .rs-shell__context"),
      ).map((section) => {
        const primary = section.querySelector(
          ".rs-shell__access-readout, .rs-env-switcher__trigger, .rs-shell__scope-picker, .rs-shell__scope-static, .rs-theme-control__trigger",
        );
        const rect = (primary ?? section).getBoundingClientRect();
        return {
          top: Math.round(rect.top),
          height: Math.round(rect.height),
          radius: Math.round(
            parseFloat(
              window.getComputedStyle(primary ?? section).borderRadius,
            ),
          ),
        };
      }),
    );

  expect(controlMetrics.length).toBeGreaterThanOrEqual(3);
  expect(
    Math.max(...controlMetrics.map((metric) => metric.top)) -
      Math.min(...controlMetrics.map((metric) => metric.top)),
  ).toBeLessThanOrEqual(1);
  expect(
    Math.min(...controlMetrics.map((metric) => metric.height)),
  ).toBeGreaterThanOrEqual(40);
  expect(
    Math.max(...controlMetrics.map((metric) => metric.height)) -
      Math.min(...controlMetrics.map((metric) => metric.height)),
  ).toBeLessThanOrEqual(2);
  expect(
    Math.max(...controlMetrics.map((metric) => metric.radius)),
  ).toBeLessThanOrEqual(12);

  const faviconHref = await adminPage
    .locator("head link[rel='icon'][type='image/svg+xml']")
    .getAttribute("href");
  expect(faviconHref).toMatch(/favicon.*\.svg(\?vsn=d)?$/);

  const faviconUrl = new URL(faviconHref ?? "", adminPage.url());
  const faviconResponse = await adminPage.request.get(faviconUrl.toString());
  expect(faviconResponse.ok()).toBeTruthy();
  expect(faviconResponse.headers()["content-type"]).toContain("image/svg+xml");
  await expect(faviconResponse.text()).resolves.toContain(
    '<title id="rs-favicon-title">Rulestead</title>',
  );

  const refresh = adminPage.getByRole("button", {
    name: "Refresh diagnostics",
  });
  await expect(refresh).toBeVisible();
  await expect(
    adminPage.locator(".rs-shell__header").getByRole("button", {
      name: "Refresh diagnostics",
    }),
  ).toHaveCount(0);
  await expect(adminPage.locator(".rs-shell__header-actions")).toHaveCount(0);
  await expect(
    adminPage.locator(".rs-banner__actions").getByRole("button", {
      name: "Refresh diagnostics",
    }),
  ).toHaveCount(1);

  const diagnosticsHeaderHeight = await adminPage
    .locator(".rs-shell__header")
    .evaluate((node) => Math.round(node.getBoundingClientRect().height));

  expect(diagnosticsHeaderHeight).toBeLessThanOrEqual(
    inventoryHeaderHeight + 8,
  );

  await context.close();

  const mobileContext = await browser.newContext({
    viewport: { width: 390, height: 760 },
  });
  const mobilePage = await mobileContext.newPage();

  await mobilePage.goto(`${backendUrl}/demo/sign-in`);
  await mobilePage.waitForURL(/\/admin\/flags/);
  await mobilePage.goto(`${backendUrl}/admin/flags/diagnostics?env=staging`);
  await waitForAdminLiveView(mobilePage);
  await expect(mobilePage.locator(".rs-shell__breadcrumb-current")).toHaveText(
    "Diagnostics",
  );
  await expect(mobilePage.locator(".rs-shell__page-summary")).toBeVisible();
  await expect(mobilePage.locator(".rs-shell__header h1")).toHaveCount(0);
  await expect(mobilePage.locator(".rs-shell__controls")).toBeVisible();
  await expect(
    mobilePage.locator(".rs-shell__header .rs-shell__context-label"),
  ).toHaveCount(0);
  await expect(mobilePage.locator(".rs-shell__brand")).toBeVisible();
  await expect(mobilePage.locator(".rs-shell__wordmark")).toBeVisible();
  await expect(mobilePage.locator(".rs-shell__access-readout")).toBeVisible();
  await expect(mobilePage.locator(".rs-shell__access-label")).toBeHidden();
  await expect(mobilePage.locator(".rs-shell__access-value")).toHaveText(
    "Admin",
  );

  await mobilePage.locator("#rs-env-trigger").click();
  const mobileEnvMenu = mobilePage.locator("#rs-env-menu");
  await expect(mobileEnvMenu).toBeVisible();
  const mobileEnvMenuBounds = await mobileEnvMenu.evaluate((node) => {
    const rect = node.getBoundingClientRect();
    return {
      left: Math.round(rect.left),
      right: Math.round(rect.right),
      viewportWidth: window.innerWidth,
    };
  });
  expect(mobileEnvMenuBounds.left).toBeGreaterThanOrEqual(0);
  expect(mobileEnvMenuBounds.right).toBeLessThanOrEqual(
    mobileEnvMenuBounds.viewportWidth,
  );
  await mobilePage.keyboard.press("Escape");
  await expect(mobileEnvMenu).toBeHidden();

  await mobilePage.locator("#rs-theme-trigger").click();
  const mobileThemeMenu = mobilePage.locator("#rs-theme-menu");
  await expect(mobileThemeMenu).toBeVisible();

  const mobileOverflow = await mobilePage.evaluate(
    () =>
      document.documentElement.scrollWidth -
      document.documentElement.clientWidth,
  );
  expect(mobileOverflow).toBeLessThanOrEqual(1);
  const mobileMenuBounds = await mobileThemeMenu.evaluate((node) => {
    const rect = node.getBoundingClientRect();
    return {
      left: Math.round(rect.left),
      right: Math.round(rect.right),
      viewportWidth: window.innerWidth,
    };
  });
  expect(mobileMenuBounds.left).toBeGreaterThanOrEqual(0);
  expect(mobileMenuBounds.right).toBeLessThanOrEqual(
    mobileMenuBounds.viewportWidth,
  );

  await mobileContext.close();
});

test("admin overview attention cards fill the available grid", async ({
  browser,
}) => {
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
  });
  const adminPage = await context.newPage();

  await adminPage.goto(`${backendUrl}/demo/sign-in`);
  await adminPage.waitForURL(/\/admin\/flags/);
  await adminPage.goto(`${backendUrl}/admin/flags?env=production`);
  await waitForAdminLiveView(adminPage);

  const attentionCards = adminPage.locator(".rs-attention__card");
  await expect(attentionCards).toHaveCount(3);

  const gridMetrics = await adminPage
    .locator(".rs-attention")
    .evaluate((grid) => {
      const gridRect = grid.getBoundingClientRect();
      const cards = Array.from(
        grid.querySelectorAll(".rs-attention__card"),
      ).map((card) => {
        const rect = card.getBoundingClientRect();
        return {
          left: Math.round(rect.left),
          right: Math.round(rect.right),
          top: Math.round(rect.top),
          width: Math.round(rect.width),
        };
      });

      const firstRowTop = Math.min(...cards.map((card) => card.top));
      const firstRow = cards.filter((card) => card.top === firstRowTop);

      return {
        gridLeft: Math.round(gridRect.left),
        gridRight: Math.round(gridRect.right),
        firstRow,
      };
    });

  expect(gridMetrics.firstRow).toHaveLength(3);
  expect(
    Math.min(...gridMetrics.firstRow.map((card) => card.left)) -
      gridMetrics.gridLeft,
  ).toBeLessThanOrEqual(2);
  expect(
    gridMetrics.gridRight -
      Math.max(...gridMetrics.firstRow.map((card) => card.right)),
  ).toBeLessThanOrEqual(2);
  expect(
    Math.max(...gridMetrics.firstRow.map((card) => card.width)) -
      Math.min(...gridMetrics.firstRow.map((card) => card.width)),
  ).toBeLessThanOrEqual(2);

  await context.close();
});

test("flag inventory pagination is a live patch and preserves pinned light theme", async ({
  browser,
}) => {
  const context = await browser.newContext({ colorScheme: "dark" });

  await context.addInitScript(() => {
    localStorage.setItem("rulestead_admin.theme", "light");
    (window as unknown as { __rsDocId: string }).__rsDocId = Math.random()
      .toString(36)
      .slice(2);
  });

  const adminPage = await context.newPage();
  await adminPage.goto(`${backendUrl}/demo/sign-in`);
  await adminPage.waitForURL(/\/admin\/flags/);
  await adminPage.goto(`${backendUrl}/admin/flags/flags?env=staging&view=all`);
  await waitForAdminLiveView(adminPage);

  const shell = adminPage.locator(".rs-shell");
  await expect(shell).toHaveAttribute("data-theme", "light");

  const documentId = await adminPage.evaluate(
    () => (window as unknown as { __rsDocId: string }).__rsDocId,
  );

  const keys = adminPage.locator("[data-flag-key]");
  const firstPageKeys = await keys.evaluateAll((nodes) =>
    nodes.map((node) => node.getAttribute("data-flag-key")),
  );

  const nextPage = adminPage.locator(".rs-pagination a[rel='next']");
  await expect(nextPage).toHaveAttribute("data-phx-link", "patch");
  await expect(adminPage.locator(".rs-pagination__meta")).toHaveCount(0);
  await nextPage.click();
  await expect(adminPage).toHaveURL(/after=/);

  await expect(shell).toHaveAttribute("data-theme", "light");
  await expect(adminPage.locator(".rs-pagination a[rel='prev']")).toBeVisible();
  await expect(adminPage.locator(".rs-pagination a[rel='next']")).toHaveCount(
    0,
  );

  const secondPageKeys = await keys.evaluateAll((nodes) =>
    nodes.map((node) => node.getAttribute("data-flag-key")),
  );

  expect(secondPageKeys.length).toBeGreaterThan(0);
  expect(secondPageKeys).not.toEqual(firstPageKeys);
  expect(secondPageKeys.some((key) => firstPageKeys.includes(key))).toBe(false);

  await expect
    .poll(
      async () =>
        adminPage.evaluate(
          () => (window as unknown as { __rsDocId: string }).__rsDocId,
        ),
      { message: "pagination should not reload the document" },
    )
    .toBe(documentId);

  await context.close();
});

test("flag inventory sort is a live patch and preserves scroll position", async ({
  browser,
}) => {
  const context = await browser.newContext({
    colorScheme: "dark",
    viewport: { width: 1280, height: 720 },
  });

  await context.addInitScript(() => {
    localStorage.setItem("rulestead_admin.theme", "light");
    (window as unknown as { __rsDocId: string }).__rsDocId = Math.random()
      .toString(36)
      .slice(2);
  });

  const adminPage = await context.newPage();
  await adminPage.goto(`${backendUrl}/demo/sign-in`);
  await adminPage.waitForURL(/\/admin\/flags/);
  await adminPage.goto(`${backendUrl}/admin/flags/flags?env=staging&view=all`);
  await waitForAdminLiveView(adminPage);
  await expect(adminPage.locator(".rs-shell")).toHaveAttribute(
    "data-theme",
    "light",
  );

  await adminPage.evaluate(() =>
    window.scrollTo(0, document.documentElement.scrollHeight),
  );
  await expect
    .poll(() => adminPage.evaluate(() => window.scrollY))
    .toBeGreaterThan(0);

  const before = await adminPage.evaluate(() => ({
    docId: (window as unknown as { __rsDocId: string }).__rsDocId,
    scrollY: window.scrollY,
    theme: document.querySelector(".rs-shell")?.getAttribute("data-theme"),
  }));

  await adminPage.selectOption(
    "form.rs-results-sort select[name='filters[sort]']",
    "inserted_at",
  );
  await expect(adminPage).toHaveURL(/sort=inserted_at/);

  const after = await adminPage.evaluate(() => ({
    docId: (window as unknown as { __rsDocId: string }).__rsDocId,
    scrollY: window.scrollY,
    theme: document.querySelector(".rs-shell")?.getAttribute("data-theme"),
  }));

  expect(after.docId).toBe(before.docId);
  expect(after.theme).toBe("light");
  expect(Math.abs(after.scrollY - before.scrollY)).toBeLessThanOrEqual(64);

  await context.close();
});

test("flag inventory hides pagination when all results fit on one page", async ({
  browser,
}) => {
  const adminPage = await openAdminPage(browser);

  await adminPage.goto(
    `${backendUrl}/admin/flags/flags?env=staging&view=all&limit=100`,
  );
  await waitForAdminLiveView(adminPage);

  await expect(
    adminPage.getByRole("heading", { name: /Feature flags/ }),
  ).toBeVisible();
  await expect(adminPage.locator(".rs-pagination")).toHaveCount(0);
});

test("experiment detail action cluster uses deliberate action icons", async ({
  browser,
}) => {
  const adminPage = await openAdminPage(browser);

  await adminPage.goto(
    `${backendUrl}/admin/flags/experiments/dispatch-guarded-rollout?env=staging`,
  );
  await waitForAdminLiveView(adminPage);

  const actions = adminPage.locator(".rs-detail__actions");
  const edit = actions.getByRole("link", { name: "Edit metadata" });
  const rules = actions.getByRole("link", { name: "Open rules workspace" });

  await expect(edit.locator(".rs-action-icon[data-icon='edit']")).toHaveCount(
    1,
  );
  await expect(rules.locator(".rs-action-icon[data-icon='rules']")).toHaveCount(
    1,
  );
});
