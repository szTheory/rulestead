import { expect, test } from "@playwright/test";

const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://localhost:4000";

test("demo sign-in, kill switch, and frontend refresh loop", async ({ browser, page }) => {
  await page.goto("/");
  await expect(
    page.getByText("The new operator cockpit is live."),
  ).toBeVisible();

  const adminPage = await browser.newPage();

  await adminPage.goto(`${backendUrl}/demo/sign-in`);
  await adminPage.goto(
    `${backendUrl}/admin/flags/enable-new-dashboard/kill?env=staging`,
  );

  await adminPage.getByLabel("Reason").fill("Compose demo browser proof");
  await adminPage.getByRole("button", { name: "Confirm kill switch" }).click();

  await expect(
    adminPage.getByText("Kill switch engaged for Staging."),
  ).toBeVisible();

  await expect(
    page.getByText("The classic cockpit is holding."),
  ).toBeVisible({ timeout: 20_000 });
});
