/* Scratch render harness — Phase 106. Not committed (scratch/ is git-ignored). */
const path = require("path");
const { chromium } = require(path.resolve(
  __dirname,
  "../../../../examples/demo/frontend/node_modules/playwright-core",
));

const url =
  "file://" + path.resolve(__dirname, "../../../../brandbook/index.html");
const out = (name) => path.resolve(__dirname, name + ".png");

(async () => {
  const browser = await chromium.launch();
  for (const theme of ["light", "dark"]) {
    const context = await browser.newContext({
      viewport: { width: 1440, height: 1000 },
      deviceScaleFactor: 2,
      colorScheme: theme,
    });
    const page = await context.newPage();
    await page.goto(url);
    await page.waitForTimeout(900); // fonts

    // Cover (first viewport)
    await page.screenshot({ path: out(`cover-${theme}`) });

    // Mid-document: color section (swatches + AA badges)
    await page.locator("#color").scrollIntoViewIfNeeded();
    await page.waitForTimeout(400);
    await page.screenshot({ path: out(`color-${theme}`) });

    // Semantic swatches specifically
    const sem = page.locator(".sem-grid").first();
    if (await sem.count()) {
      await sem.screenshot({ path: out(`sem-${theme}`) });
    }

    // Logo plates
    await page.locator("#logo").scrollIntoViewIfNeeded();
    await page.waitForTimeout(400);
    const plates = page.locator(".plate-grid");
    if (await plates.count()) {
      await plates.screenshot({ path: out(`plates-${theme}`) });
    }
    const clear = page.locator(".clearspace");
    if (await clear.count()) {
      await clear.screenshot({ path: out(`clearspace-${theme}`) });
    }
    const usage = page.locator(".usage-grid");
    if (await usage.count()) {
      await usage.screenshot({ path: out(`usage-${theme}`) });
    }

    // Typical reading view (overview top, shows rail + section head)
    await page.locator("#overview").scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);
    await page.screenshot({ path: out(`reading-${theme}`) });

    await context.close();
  }

  // Print preview emulation (light)
  const pctx = await browser.newContext({
    viewport: { width: 1440, height: 1000 },
    deviceScaleFactor: 2,
    colorScheme: "light",
  });
  const ppage = await pctx.newPage();
  await ppage.goto(url);
  await ppage.emulateMedia({ media: "print" });
  await ppage.waitForTimeout(600);
  await ppage.screenshot({ path: out("print-top") });
  await pctx.close();

  // Narrow viewport
  const mctx = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    colorScheme: "light",
  });
  const mpage = await mctx.newPage();
  await mpage.goto(url);
  await mpage.waitForTimeout(600);
  await mpage.screenshot({ path: out("mobile-top") });
  await mpage.locator("#overview").scrollIntoViewIfNeeded();
  await mpage.waitForTimeout(300);
  await mpage.screenshot({ path: out("mobile-reading") });
  await mctx.close();

  await browser.close();
  console.log("done");
})();
