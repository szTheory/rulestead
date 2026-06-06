/**
 * brandbook.spec.ts -- Phase 101 / BOOK-01 / BOOK-02 browser evidence
 *
 * Validates the generated brandbook/index.html artifact through file:// so no
 * Phoenix, Next.js, or demo server is required.
 */

import { expect, test } from "@playwright/test";
import path from "path";

const brandbookUrl =
  "file://" +
  path.resolve(__dirname, "../../../../brandbook/index.html");

const requiredSections = [
  "#overview",
  "#voice-and-messaging",
  "#color",
  "#typography",
  "#logo",
  "#layout-and-components",
  "#iconography-and-imagery",
  "#motion",
  "#assets-and-maintenance",
];

test("desktop file:// brand book exposes required landmarks and sections", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto(brandbookUrl);

  await expect(page.locator("[data-rulestead-brandbook]")).toBeVisible();
  await expect(page.locator("header")).toBeVisible();
  await expect(page.locator("nav")).toBeVisible();
  await expect(page.locator("main")).toBeVisible();

  for (const sectionId of requiredSections) {
    await expect(page.locator(sectionId)).toBeVisible();
  }
});

test("mobile file:// brand book keeps primary content visible", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(brandbookUrl);

  await expect(page.locator("[data-rulestead-brandbook]")).toBeVisible();
  await expect(page.locator("nav")).toBeVisible();
  await expect(page.locator("#overview")).toBeVisible();
  await expect(page.locator("#color")).toBeVisible();
  await expect(page.locator("#assets-and-maintenance")).toBeVisible();
});

test("theme control toggles dark, light, and system modes", async ({ page }) => {
  const wrapper = page.locator("[data-rulestead-brandbook]");

  await page.goto(brandbookUrl);

  await page.locator("[data-value='dark']").click();
  await expect(wrapper).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("[data-value='dark']")).toHaveAttribute(
    "aria-checked",
    "true",
  );

  await page.locator("[data-value='light']").click();
  await expect(wrapper).toHaveAttribute("data-theme", "light");
  await expect(page.locator("[data-value='light']")).toHaveAttribute(
    "aria-checked",
    "true",
  );

  await page.locator("[data-value='system']").click();
  await expect(wrapper).not.toHaveAttribute("data-theme", /.+/);
  await expect(page.locator("[data-value='system']")).toHaveAttribute(
    "aria-checked",
    "true",
  );
});

test("JavaScript-disabled file:// brand book keeps content and inline SVGs visible", async ({
  browser,
}) => {
  const context = await browser.newContext({
    javaScriptEnabled: false,
    colorScheme: "dark",
  });
  const page = await context.newPage();

  await page.goto(brandbookUrl);

  await expect(page.locator("[data-rulestead-brandbook]")).toBeVisible();
  await expect(page.locator("nav")).toBeVisible();
  await expect(page.locator("#color")).toBeVisible();
  await expect(page.locator("#logo")).toBeVisible();
  await expect(page.locator("#assets-and-maintenance")).toBeVisible();
  await expect(page.locator("svg").first()).toBeVisible();

  await context.close();
});

test("keyboard focus reaches nav links and theme options", async ({ page }) => {
  await page.goto(brandbookUrl);

  const firstNavLink = page.locator("nav a").first();
  await firstNavLink.focus();
  await expect(firstNavLink).toBeFocused();

  await page.locator("[data-value='system']").focus();
  await expect(page.locator("[data-value='system']")).toBeFocused();

  await page.keyboard.press("ArrowRight");

  await expect(page.locator("[data-value='light']")).toBeFocused();
  await expect(page.locator("[data-value='light']")).toHaveAttribute(
    "aria-checked",
    "true",
  );
});

test("required previews use inline SVGs instead of img elements", async ({
  page,
}) => {
  await page.goto(brandbookUrl);

  await expect(page.locator("img")).toHaveCount(0);
  await expect(page.locator(".asset-card svg").first()).toBeVisible();
  await expect(page.locator("#logo .asset-card svg")).not.toHaveCount(0);
  await expect(page.locator("#layout-and-components .asset-card svg")).not.toHaveCount(0);
});
