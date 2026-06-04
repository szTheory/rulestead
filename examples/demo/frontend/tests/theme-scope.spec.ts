/**
 * theme-scope.spec.ts — Phase 87 / THM-05
 *
 * Validates that theme tokens are scoped to .rs-shell and do NOT leak to
 * :root, <html>, or elements outside the shell.
 *
 * These tests verify scope AFTER Plan 02 moves the variant token declarations
 * off :root and onto .rs-shell. They act as a regression guard: if any future
 * change inadvertently re-adds color tokens to :root, these tests will fail.
 *
 * Test 3 (outside-shell --rs-bg) will only be meaningful after Plan 02
 * completes the :root token migration.
 */

import { expect, test } from "@playwright/test";
import path from "path";

const harnessUrl =
  "file://" +
  path.resolve(
    __dirname,
    "../../../../rulestead_admin/priv/static/theme-harness.html",
  );

test(":root has no --rs-neutral-0 color token", async ({ page }) => {
  await page.goto(harnessUrl);

  // After Plan 02 moves the neutral ramp off :root, getPropertyValue on
  // :root must return an empty string — the token is not declared there.
  const value = await page.evaluate((): string =>
    getComputedStyle(document.documentElement)
      .getPropertyValue("--rs-neutral-0")
      .trim(),
  );
  expect(value).toBe("");
});

test(":root has no --rs-bg color token", async ({ page }) => {
  await page.goto(harnessUrl);

  // --rs-bg is a semantic alias onto the neutral ramp; it too must not be
  // declared on :root after the Plan 02 refactor.
  const value = await page.evaluate((): string =>
    getComputedStyle(document.documentElement)
      .getPropertyValue("--rs-bg")
      .trim(),
  );
  expect(value).toBe("");
});

test("element outside .rs-shell has no --rs-bg value", async ({ page }) => {
  await page.goto(harnessUrl);

  // The harness includes <div id="outside-shell" style="background: var(--rs-bg, red)">
  // If --rs-bg is correctly scoped to .rs-shell, the token is undefined outside it
  // and the CSS var() fallback `red` = rgb(255, 0, 0) applies.
  //
  // NOTE: This test will only pass after Plan 02 moves --rs-bg off :root.
  // Until then, --rs-bg resolves via :root inheritance and the background will
  // be the light surface color, not red.
  const bgColor = await page.evaluate((): string => {
    const el = document.querySelector("#outside-shell");
    if (!el) throw new Error("#outside-shell not found in harness");
    return getComputedStyle(el).backgroundColor;
  });
  // Fallback red — token not inherited outside .rs-shell
  expect(bgColor).toBe("rgb(255, 0, 0)");
});
