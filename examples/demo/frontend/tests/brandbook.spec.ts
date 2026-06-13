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
import { wcagRatio } from "./support/contrast-check";

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

const brandAnchorHexes = [
  "#183247",
  "#3A6F8F",
  "#9b5931",
  "#0F1720",
  "#F5F7F6",
  "#E8ECE8",
  "#C4CCD1",
  "#D2A94E",
];

function rgbStringToHex(value: string): string {
  const match = value.match(
    /^rgba?\(\s*(\d+),\s*(\d+),\s*(\d+)(?:,\s*[\d.]+)?\s*\)$/,
  );
  if (!match) {
    throw new Error(`Expected an rgb()/rgba() color, got "${value}"`);
  }

  return [match[1], match[2], match[3]]
    .map((channel) => Number(channel).toString(16).padStart(2, "0"))
    .join("")
    .replace(/^/, "#");
}

function blendHex(foreground: string, background: string, alpha: number): string {
  const fg = foreground.replace(/^#/, "");
  const bg = background.replace(/^#/, "");

  return [0, 2, 4]
    .map((offset) => {
      const fgChannel = parseInt(fg.slice(offset, offset + 2), 16);
      const bgChannel = parseInt(bg.slice(offset, offset + 2), 16);
      return Math.round(fgChannel * alpha + bgChannel * (1 - alpha))
        .toString(16)
        .padStart(2, "0");
    })
    .join("")
    .replace(/^/, "#");
}

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

test("section numbers use filled readable text in light and dark themes", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto(brandbookUrl);

  const wrapper = page.locator("[data-rulestead-brandbook]");
  const sectionNum = page.locator("#voice-and-messaging .section-num");

  async function assertSectionNumber(theme: "dark" | "light") {
    await page.locator(`[data-value='${theme}']`).click();
    await expect(wrapper).toHaveAttribute("data-theme", theme);
    await expect(sectionNum).toBeVisible();

    const styles = await sectionNum.evaluate((element) => {
      const sectionStyle = getComputedStyle(element);
      const wrapperElement = element.closest("[data-rulestead-brandbook]");

      if (!wrapperElement) {
        throw new Error("Missing brand book wrapper for section number");
      }

      return {
        background: getComputedStyle(wrapperElement).backgroundColor,
        color: sectionStyle.color,
        opacity: sectionStyle.opacity,
        strokeWidth: sectionStyle.getPropertyValue(
          "-webkit-text-stroke-width",
        ),
      };
    });

    const opacity = Number(styles.opacity);
    const foreground = rgbStringToHex(styles.color);
    const background = rgbStringToHex(styles.background);
    const effectiveForeground = blendHex(foreground, background, opacity);

    expect(styles.strokeWidth).toBe("0px");
    expect(foreground).not.toBe(background);
    expect(opacity).toBeGreaterThanOrEqual(0.74);
    expect(wcagRatio(effectiveForeground, background)).toBeGreaterThanOrEqual(
      3,
    );
  }

  await assertSectionNumber("dark");
  await assertSectionNumber("light");
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

  const anchors = page.locator("#color .brand-anchors .anchor-card");
  await expect(anchors).toHaveCount(8);

  for (const hex of brandAnchorHexes) {
    await expect(page.locator("#color .brand-anchors")).toContainText(hex);
  }

  const badges = page.locator("#color .sem-badge");
  expect(await badges.count()).toBeGreaterThan(10);
  await expect(badges.first()).toBeVisible();

  const badgeText = await badges.allTextContents();
  expect(
    badgeText.every((text) => /^(AAA|AA|AA large|Below AA)$/.test(text.trim())),
  ).toBe(true);
  expect(badgeText.some((text) => /^AA(A)?$/.test(text.trim()))).toBe(true);
});

test("voice and copy reference docs stack with scroll-safe tables", async ({
  page,
}) => {
  await page.goto(brandbookUrl);

  const docStack = page.locator("#voice-and-messaging .doc-stack");
  const docs = docStack.locator(":scope > .doc-excerpt");

  await expect(docStack).toBeVisible();
  await expect(docs).toHaveCount(2);
  await expect(docs.nth(0).locator("h3").first()).toHaveText(
    "Rulestead Voice and Microcopy",
  );
  await expect(docs.nth(1).locator("h3").first()).toHaveText(
    "Rulestead Copy Kit",
  );

  const [firstBox, secondBox] = await Promise.all([
    docs.nth(0).boundingBox(),
    docs.nth(1).boundingBox(),
  ]);
  expect(firstBox).not.toBeNull();
  expect(secondBox).not.toBeNull();
  expect(secondBox!.y).toBeGreaterThan(firstBox!.y + firstBox!.height - 1);

  const voiceTable = docs.nth(0).locator("table");
  await expect(voiceTable).toBeVisible();
  const tableStyle = await voiceTable.evaluate((table) => {
    const firstCell = table.querySelector("th:first-child");
    if (!firstCell) {
      throw new Error("Voice table is missing first header cell");
    }

    return {
      minWidth: getComputedStyle(table).minWidth,
      firstColumnWhitespace: getComputedStyle(firstCell).whiteSpace,
      wrapperOverflowX: getComputedStyle(table.closest(".doc-excerpt")!).overflowX,
    };
  });

  expect(tableStyle.minWidth).toBe("720px");
  expect(tableStyle.firstColumnWhitespace).toBe("nowrap");
  expect(tableStyle.wrapperOverflowX).toBe("auto");
});

test("logo plates render primary surface first with compatibility checks", async ({
  page,
}) => {
  await page.goto(brandbookUrl);

  const plates = page.locator("#logo .plate");
  await expect(plates).toHaveCount(7);
  await expect(page.locator("#logo .plate-tile--light")).toHaveCount(7);
  await expect(page.locator("#logo .plate-tile--dark")).toHaveCount(7);

  const expectedPlates = [
    ["Rs Wordmark", "light", "dark", "primary surface", "compatibility check"],
    ["Rs Wordmark Dark", "dark", "light", "primary surface", "compatibility check"],
    ["Rs Wordmark Tagline", "light", "dark", "primary surface", "compatibility check"],
    ["Rs Mark", "light", "dark", "primary surface", "compatibility check"],
    ["Rs Mark Dark", "dark", "light", "primary surface", "compatibility check"],
    ["Rs Mark Mono", "light", "dark", "primary surface", "compatibility check"],
    ["Rs Favicon", "light", "dark", "valid surface", "valid surface"],
  ] as const;

  await expect(page.locator("#logo .plate-diagnostic")).toHaveCount(6);

  for (const [
    label,
    primarySurface,
    secondarySurface,
    primaryLabel,
    secondaryLabel,
  ] of expectedPlates) {
    const plate = plates.nth(expectedPlates.findIndex(([name]) => name === label));
    await expect(plate.locator("figcaption strong")).toHaveText(label);
    const primaryTile = plate.locator("[data-plate-role='primary']");
    const secondaryTile = plate.locator("[data-plate-role='secondary']");

    await expect(primaryTile).toHaveAttribute(
      "data-plate-surface",
      primarySurface,
    );
    await expect(secondaryTile).toHaveAttribute(
      "data-plate-surface",
      secondarySurface,
    );
    await expect(primaryTile.locator(".plate-tag")).toHaveText(primaryLabel);
    await expect(secondaryTile.locator(".plate-tag")).toHaveText(secondaryLabel);

    if (secondaryLabel === "compatibility check") {
      await expect(secondaryTile.locator(".plate-diagnostic-title")).toHaveText(
        `Do not use on ${secondarySurface} surface`,
      );
      await expect(secondaryTile.locator(".plate-diagnostic-sample svg")).toHaveCount(
        1,
      );

      const diagnosticContrast = await secondaryTile.evaluate((tile) => {
        const title = tile.querySelector(".plate-diagnostic-title");
        if (!title) {
          throw new Error("Expected compatibility diagnostic title");
        }

        return {
          background: getComputedStyle(tile).backgroundColor,
          color: getComputedStyle(title).color,
        };
      });

      expect(
        wcagRatio(
          rgbStringToHex(diagnosticContrast.color),
          rgbStringToHex(diagnosticContrast.background),
        ),
      ).toBeGreaterThanOrEqual(4.5);
    } else {
      await expect(secondaryTile.locator(".plate-diagnostic")).toHaveCount(0);
      await expect(secondaryTile.locator(":scope > svg")).toHaveCount(1);
    }
  }

  const socialExports = page.locator("#logo .social-card-export");
  await expect(socialExports).toHaveCount(2);
  await expect(socialExports.nth(0)).toHaveAttribute("data-social-surface", "dark");
  await expect(socialExports.nth(1)).toHaveAttribute("data-social-surface", "light");
  await expect(socialExports.nth(0).locator("figcaption strong")).toHaveText(
    "Rs Social Card",
  );
  await expect(socialExports.nth(1).locator("figcaption strong")).toHaveText(
    "Rs Social Card Light",
  );
  await expect(socialExports.nth(0)).toContainText("assets/logo/rs-social-card.svg");
  await expect(socialExports.nth(1)).toContainText(
    "assets/logo/rs-social-card-light.svg",
  );
  await expect(page.locator("#logo .social-card-preview > svg")).toHaveCount(2);
  await expect(page.locator("#logo .social-card-export .plate-tile")).toHaveCount(0);

  await expect(page.locator("#logo .clearspace")).toBeVisible();
  await expect(page.locator("#logo .usage--dont")).toHaveCount(3);
});

test("assets and maintenance docs stack with readable tables", async ({ page }) => {
  await page.goto(brandbookUrl);

  const docStack = page.locator(
    "#assets-and-maintenance .doc-stack--maintenance",
  );
  const docs = docStack.locator(":scope > .doc-excerpt");

  await expect(docStack).toBeVisible();
  await expect(docs).toHaveCount(3);
  await expect(docs.nth(0).locator("h3").first()).toHaveText("brandbook/");
  await expect(docs.nth(1).locator("h3").first()).toHaveText(
    "Brand Asset Budget",
  );
  await expect(docs.nth(2).locator("h3").first()).toHaveText(
    "Brand Token Usage",
  );

  const boxes = await Promise.all([
    docs.nth(0).boundingBox(),
    docs.nth(1).boundingBox(),
    docs.nth(2).boundingBox(),
  ]);
  for (const box of boxes) {
    expect(box).not.toBeNull();
  }
  expect(boxes[1]!.y).toBeGreaterThan(boxes[0]!.y + boxes[0]!.height - 1);
  expect(boxes[2]!.y).toBeGreaterThan(boxes[1]!.y + boxes[1]!.height - 1);

  const budgetTable = docs.nth(1).locator("table");
  await expect(budgetTable).toBeVisible();
  const tableStyle = await budgetTable.evaluate((table) => ({
    minWidth: getComputedStyle(table).minWidth,
    wrapperOverflowX: getComputedStyle(table.closest(".doc-excerpt")!).overflowX,
  }));
  expect(tableStyle.minWidth).toBe("720px");
  expect(tableStyle.wrapperOverflowX).toBe("auto");
});
