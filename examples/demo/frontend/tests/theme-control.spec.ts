/**
 * theme-control.spec.ts — Phase 90 / THM-02 / THM-04
 *
 * Validates tri-state theme control behaviors against the standalone
 * theme-control-harness.html fixture via file://, so no Phoenix or demo server
 * is required.
 *
 * Test cases:
 *  1.  select dark — applies data-theme=dark on shell
 *  2.  persists dark — localStorage written on select
 *  3.  persists across reload — dark theme restored after page reload
 *  4.  system removes attr — selecting system removes data-theme
 *  5.  system follows OS — matchMedia dark OS change live-updates in system mode
 *  6.  pinned ignores OS — pinned dark ignores OS color-scheme change
 *  7.  keyboard nav — trigger opens menu and arrows move between choices
 *  8.  aria-checked — tracks active option on click
 *  9.  menu dismissal — Escape and outside click close the menu
 *  10. no animated wipe — data-theme-pending absent after hook mount
 *  11. pending cleared — data-theme-pending removed after load regardless of pinned value
 *  12. input validation — unknown localStorage value defaults to system
 */

import { expect, test } from "@playwright/test";
import path from "path";

const harnessUrl =
  "file://" +
  path.resolve(
    __dirname,
    "../../../../rulestead_admin/priv/static/theme-control-harness.html",
  );

// Helper: get the data-theme attribute on #shell (null when absent = system mode).
async function getShellTheme(
  page: import("@playwright/test").Page,
): Promise<string | null> {
  return page.locator("#shell").getAttribute("data-theme");
}

// Helper: read localStorage value for the theme key.
async function getStoredTheme(
  page: import("@playwright/test").Page,
): Promise<string | null> {
  return page.evaluate(() =>
    localStorage.getItem("rulestead_admin.theme"),
  );
}

// Helper: set localStorage theme value before (or during) the test.
async function setStoredTheme(
  page: import("@playwright/test").Page,
  value: string,
): Promise<void> {
  await page.evaluate(
    (v: string) => localStorage.setItem("rulestead_admin.theme", v),
    value,
  );
}

async function openThemeMenu(
  page: import("@playwright/test").Page,
): Promise<void> {
  await page.locator("#rs-theme-trigger").click();
  await expect(page.locator("#rs-theme-menu")).toBeVisible();
}

async function chooseTheme(
  page: import("@playwright/test").Page,
  value: "system" | "light" | "dark",
): Promise<void> {
  await openThemeMenu(page);
  await page.locator(`#rs-theme-menu [data-value='${value}']`).click();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test("select dark — applies data-theme=dark on shell", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  await chooseTheme(page, "dark");

  // data-theme should be set to "dark" on #shell
  expect(await getShellTheme(page)).toBe("dark");

  await context.close();
});

test("persists dark — localStorage written on select", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  await chooseTheme(page, "dark");

  // localStorage must have been written synchronously by the click handler
  expect(await getStoredTheme(page)).toBe("dark");

  await context.close();
});

test("persists across reload — dark theme restored after page reload", async ({
  browser,
}) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  // Write dark to localStorage then reload — hook must read it on mount
  await setStoredTheme(page, "dark");
  await page.reload();

  expect(await getShellTheme(page)).toBe("dark");

  await context.close();
});

test("system removes attr — selecting system removes data-theme", async ({
  browser,
}) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();

  // Navigate first (file:// needs a page to be loaded before localStorage is accessible)
  await page.goto(harnessUrl);

  // Pin to dark via localStorage, then reload so hook reads it on mount
  await setStoredTheme(page, "dark");
  await page.reload();

  // Confirm dark is applied
  expect(await getShellTheme(page)).toBe("dark");

  // Choose System — must REMOVE data-theme (not set it to "system")
  await chooseTheme(page, "system");

  expect(await getShellTheme(page)).toBeNull();

  await context.close();
});

test("system follows OS — matchMedia dark OS change live-updates in system mode", async ({
  browser,
}) => {
  // Start with light OS, no localStorage (= system mode)
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  // In system mode there is no data-theme attribute — CSS @media handles theming
  expect(await getShellTheme(page)).toBeNull();

  // Emulate dark OS change while in system mode
  // System hook must stay in system mode — data-theme stays absent (CSS @media takes over)
  await page.emulateMedia({ colorScheme: "dark" });

  // JS does NOT set data-theme for system; CSS @media handles it
  // data-theme must still be absent
  expect(await getShellTheme(page)).toBeNull();

  await context.close();
});

test("pinned ignores OS — pinned dark ignores OS color-scheme change", async ({
  browser,
}) => {
  const context = await browser.newContext({ colorScheme: "dark" });
  const page = await context.newPage();

  // Navigate first, then pin dark via localStorage, reload so hook reads it on mount
  await page.goto(harnessUrl);
  await setStoredTheme(page, "dark");
  await page.reload();

  // Confirm dark is pinned
  expect(await getShellTheme(page)).toBe("dark");

  // Emulate OS change to light — pinned mode must not react
  await page.emulateMedia({ colorScheme: "light" });

  // data-theme must remain "dark" — matchMedia listener no-ops when mode !== "system"
  expect(await getShellTheme(page)).toBe("dark");

  await context.close();
});

test("keyboard nav — trigger opens menu and arrows move between choices", async ({
  browser,
}) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  await page.locator("#rs-theme-trigger").focus();
  await page.keyboard.press("Enter");
  await expect(page.locator("#rs-theme-menu")).toBeVisible();
  await expect(page.locator("[data-value='system']")).toBeFocused();

  // ArrowDown moves focus to Light without selecting until Enter/Space.
  await page.keyboard.press("ArrowDown");
  await expect(page.locator("[data-value='light']")).toBeFocused();
  expect(
    await page.locator("[data-value='system']").getAttribute("aria-checked"),
  ).toBe("true");

  await page.keyboard.press("Enter");
  expect(
    await page.locator("[data-value='light']").getAttribute("aria-checked"),
  ).toBe("true");
  expect(
    await page.locator("[data-value='light']").getAttribute("tabindex"),
  ).toBe("0");
  await expect(page.locator("#rs-theme-menu")).toBeHidden();
  await expect(page.locator("#rs-theme-trigger")).toBeFocused();

  await page.keyboard.press("Enter");
  await expect(page.locator("#rs-theme-menu")).toBeVisible();
  await expect(page.locator("[data-value='light']")).toBeFocused();
  await page.keyboard.press("ArrowDown");
  await expect(page.locator("[data-value='dark']")).toBeFocused();
  await page.keyboard.press(" ");

  expect(
    await page.locator("[data-value='dark']").getAttribute("aria-checked"),
  ).toBe("true");
  expect(
    await page.locator("[data-value='dark']").getAttribute("tabindex"),
  ).toBe("0");

  // Confirm System and Light are now unchecked
  expect(
    await page.locator("[data-value='system']").getAttribute("aria-checked"),
  ).toBe("false");
  expect(
    await page.locator("[data-value='light']").getAttribute("aria-checked"),
  ).toBe("false");

  await context.close();
});

test("aria-checked — tracks active option on click", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  await chooseTheme(page, "dark");

  expect(
    await page.locator("[data-value='dark']").getAttribute("aria-checked"),
  ).toBe("true");
  expect(
    await page.locator("[data-value='system']").getAttribute("aria-checked"),
  ).toBe("false");
  expect(
    await page.locator("[data-value='light']").getAttribute("aria-checked"),
  ).toBe("false");

  await context.close();
});

test("menu closes with Escape and outside click", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  await openThemeMenu(page);
  await page.keyboard.press("Escape");
  await expect(page.locator("#rs-theme-menu")).toBeHidden();
  await expect(page.locator("#rs-theme-trigger")).toBeFocused();

  await openThemeMenu(page);
  await page.locator("#outside-shell").click();
  await expect(page.locator("#rs-theme-menu")).toBeHidden();

  await context.close();
});

test("no animated wipe — data-theme-pending absent after hook mount", async ({
  browser,
}) => {
  // Transition suppression is guaranteed by CSS rule '[data-theme-pending] * { transition: none }'
  // which is lifted when the attribute is removed. This test verifies the attribute is gone
  // synchronously after the hook's DOMContentLoaded handler runs.
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  // data-theme-pending should be absent — hook removes it synchronously
  expect(
    await page.locator("#shell").getAttribute("data-theme-pending"),
  ).toBeNull();

  await context.close();
});

test("pending cleared — data-theme-pending removed after load regardless of pinned value", async ({
  browser,
}) => {
  // Transition suppression is guaranteed by CSS rule '[data-theme-pending] * { transition: none }'
  // which is lifted when the attribute is removed. Even with a pinned theme (dark), the
  // data-theme-pending attribute must be removed and data-theme must be set correctly.
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();

  // Navigate first, then pin dark via localStorage, reload so hook reads it on mount
  await page.goto(harnessUrl);
  await setStoredTheme(page, "dark");
  await page.reload();

  // data-theme-pending must be gone
  expect(
    await page.locator("#shell").getAttribute("data-theme-pending"),
  ).toBeNull();

  // data-theme must be set to "dark"
  expect(await getShellTheme(page)).toBe("dark");

  await context.close();
});

test("input validation — unknown localStorage value defaults to system", async ({
  browser,
}) => {
  // T-90-01: localStorage tampering mitigation — unknown values silently default to "system"
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();

  // Tamper: set an invalid value
  await page.goto(harnessUrl);
  await page.evaluate(() =>
    localStorage.setItem("rulestead_admin.theme", "purple"),
  );
  await page.reload();

  // System mode = data-theme ABSENT (not "system", not "purple")
  expect(await getShellTheme(page)).toBeNull();

  // System button should be aria-checked
  expect(
    await page.locator("[data-value='system']").getAttribute("aria-checked"),
  ).toBe("true");

  await context.close();
});
