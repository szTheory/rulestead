/**
 * brandbook.spec.ts -- Phase 101 / BOOK-01 / BOOK-02 browser evidence,
 * extended in Phase 106 (BOOK-03/BOOK-04) for the elevated chrome: cover,
 * sticky scrollspy rail, AA-badged token swatches, logo plates, print styles.
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
  await expect(page.locator("header.brand-cover")).toBeVisible();
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
  await expect(page.locator("#logo .plate svg")).not.toHaveCount(0);
  await expect(page.locator("#layout-and-components .asset-card svg")).not.toHaveCount(0);
});

test("cover renders as a designed brand statement", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto(brandbookUrl);

  const cover = page.locator(".brand-cover");
  await expect(cover).toBeVisible();
  await expect(cover.locator(".cover-logo--screen svg")).toBeVisible();
  await expect(cover.locator(".cover-mantra")).toHaveText(
    "Rulestead makes change feel governed, not chaotic.",
  );
  await expect(cover).toContainText("Brand System v1.15");
});

test("section rail is present and sticky on desktop", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto(brandbookUrl);

  const rail = page.locator(".brand-rail");
  await expect(rail).toBeVisible();
  await expect(rail.locator(".rail-list a")).toHaveCount(9);
  await expect(rail.locator(".rail-num").first()).toHaveText("01");

  const position = await rail.evaluate(
    (element) => getComputedStyle(element).position,
  );
  expect(position).toBe("sticky");
});

test("scrollspy activates rail links while scrolling", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto(brandbookUrl);

  await expect(
    page.locator(".rail-list a[aria-current='true']"),
  ).toHaveAttribute("href", "#overview");

  await page.evaluate(() =>
    document.querySelector("#logo")?.scrollIntoView(),
  );
  await expect(
    page.locator(".rail-list a[aria-current='true']"),
  ).toHaveAttribute("href", "#logo");

  await page.evaluate(() =>
    document.querySelector("#motion")?.scrollIntoView(),
  );
  await expect(
    page.locator(".rail-list a[aria-current='true']"),
  ).toHaveAttribute("href", "#motion");
});

test("print stylesheet exists and hides screen chrome", async ({ page }) => {
  await page.goto(brandbookUrl);

  const hasPrintBlock = await page.evaluate(() =>
    Array.from(document.querySelectorAll("style")).some((style) =>
      (style.textContent ?? "").includes("@media print"),
    ),
  );
  expect(hasPrintBlock).toBe(true);

  await page.emulateMedia({ media: "print" });
  await expect(page.locator(".brand-rail")).toBeHidden();
  await expect(page.locator(".theme-control")).toBeHidden();
  await expect(page.locator(".cover-logo--print svg")).toBeVisible();
});

test("token swatches expose computed WCAG badges", async ({ page }) => {
  await page.goto(brandbookUrl);

  const badges = page.locator("#color .sem-badge");
  expect(await badges.count()).toBeGreaterThan(10);
  await expect(badges.first()).toBeVisible();

  const badgeText = await badges.allTextContents();
  expect(
    badgeText.every((text) => /^(AAA|AA|AA large|Below AA)$/.test(text.trim())),
  ).toBe(true);
  expect(badgeText.some((text) => /^AA(A)?$/.test(text.trim()))).toBe(true);
});

test("logo plates render the full family on light and dark tiles", async ({
  page,
}) => {
  await page.goto(brandbookUrl);

  await expect(page.locator("#logo .plate")).toHaveCount(8);
  await expect(page.locator("#logo .plate-tile--light")).toHaveCount(8);
  await expect(page.locator("#logo .plate-tile--dark")).toHaveCount(8);
  await expect(page.locator("#logo .clearspace")).toBeVisible();
  await expect(page.locator("#logo .usage--dont")).toHaveCount(3);
});
