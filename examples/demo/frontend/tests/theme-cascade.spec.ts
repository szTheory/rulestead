/**
 * theme-cascade.spec.ts — Phase 87 / THM-01 / THM-03
 *
 * Validates the five cascade-precedence cases for the rs-shell theme system.
 * These specs run against the standalone theme-harness.html via file://, so no
 * Phoenix or demo server is required.
 *
 * Cases (from VALIDATION.md cascade-precedence matrix):
 *  1. No attr, light OS  → light tokens active
 *  2. No attr, dark OS   → dark tokens active (THM-01 system-dark)
 *  3. Pinned dark, light OS → dark tokens active (THM-03 explicit-wins)
 *  4. Pinned light, dark OS → light tokens active (THM-03 explicit-wins)
 *  5. Pinned dark, dark OS  → dark tokens active (redundant; still verified)
 *
 * NOTE: Tests 2, 3, and 5 will produce pending/partial results until Plan 03
 * completes the dark token set. They are the acceptance gate for that plan.
 */

import { expect, test } from "@playwright/test";
import path from "path";

const harnessUrl =
  "file://" +
  path.resolve(
    __dirname,
    "../../../../rulestead_admin/priv/static/theme-harness.html",
  );

// Helper: read a CSS custom property from the .rs-shell element.
async function shellVar(
  page: import("@playwright/test").Page,
  varName: string,
): Promise<string> {
  return page.evaluate((v: string) => {
    const shell = document.querySelector(".rs-shell");
    if (!shell) throw new Error(".rs-shell not found in harness");
    return getComputedStyle(shell).getPropertyValue(v).trim();
  }, varName);
}

test("no attr, light OS — light tokens active", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  // In light mode --rs-surface resolves through --rs-neutral-0 which is #ffffff
  const surface = await shellVar(page, "--rs-surface");
  expect(surface).toBe("#ffffff");

  await context.close();
});

test("no attr, dark OS — dark tokens active (THM-01)", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "dark" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  // In dark mode --rs-neutral-0 resolves to the mineral-dark base (~#10161f),
  // which starts with '#1' — not '#fff'. After Plan 03 completes the dark block
  // this will be the acceptance gate for THM-01.
  const neutral0 = await shellVar(page, "--rs-neutral-0");
  expect(neutral0.toLowerCase()).not.toBe("#ffffff");
  expect(neutral0.toLowerCase().startsWith("#1")).toBe(true);

  // --rs-surface must also not be the light value
  const surface = await shellVar(page, "--rs-surface");
  expect(surface).not.toBe("#ffffff");

  await context.close();
});

test("pinned dark, light OS — dark tokens active (THM-03)", async ({
  browser,
}) => {
  const context = await browser.newContext({ colorScheme: "light" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  // Pin explicitly to dark; the OS is light but the attribute must win
  await page.evaluate(() => (window as unknown as { setTheme: (t: string) => void }).setTheme("dark"));

  const neutral0 = await shellVar(page, "--rs-neutral-0");
  expect(neutral0.toLowerCase()).not.toBe("#ffffff");

  await context.close();
});

test("pinned light, dark OS — light tokens active (THM-03)", async ({
  browser,
}) => {
  const context = await browser.newContext({ colorScheme: "dark" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  // Pin explicitly to light; the OS is dark but the attribute must re-assert light
  await page.evaluate(() => (window as unknown as { setTheme: (t: string) => void }).setTheme("light"));

  const surface = await shellVar(page, "--rs-surface");
  expect(surface).toBe("#ffffff");

  await context.close();
});

test("pinned dark, dark OS — dark tokens active", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "dark" });
  const page = await context.newPage();
  await page.goto(harnessUrl);

  // Redundant case: both OS and attribute agree on dark
  await page.evaluate(() => (window as unknown as { setTheme: (t: string) => void }).setTheme("dark"));

  const neutral0 = await shellVar(page, "--rs-neutral-0");
  expect(neutral0.toLowerCase()).not.toBe("#ffffff");

  await context.close();
});
