import { expect, test } from "@playwright/test";

import { backendUrl, openAdminPage } from "./support/admin";

test("audit timeline lists seeded flag activity after kill switch", async ({ browser }) => {
  const adminPage = await openAdminPage(browser);

  await adminPage.goto(`${backendUrl}/admin/flags/enable-new-dashboard/kill?env=staging`);

  const confirmKill = adminPage.getByRole("button", { name: "Confirm kill switch" });

  if (await confirmKill.isVisible()) {
    await adminPage.getByLabel("Reason").fill("Adoption lab audit timeline proof");
    await confirmKill.click();
    await expect(adminPage.getByText("Kill switch engaged for Staging.")).toBeVisible();
  } else {
    await expect(adminPage.getByRole("heading", { name: "Kill switch active" })).toBeVisible({
      timeout: 15_000,
    });
  }

  await adminPage.goto(`${backendUrl}/admin/flags/audit?env_filter=all`);

  const killSwitchEntry = adminPage
    .locator("article")
    .filter({ has: adminPage.getByRole("heading", { name: "Kill switch engaged" }) })
    .filter({ hasText: "enable-new-dashboard" })
    .first();

  await expect(killSwitchEntry).toBeVisible({ timeout: 15_000 });
  await expect(
    killSwitchEntry.locator("code").filter({ hasText: "enable-new-dashboard" }).first(),
  ).toBeVisible();

  const filtered = adminPage.locator("form[aria-label='Audit filters']");
  await filtered.getByLabel("Mutation type filter").selectOption("kill_switch.engage");

  await expect(killSwitchEntry).toBeVisible();
  await expect(killSwitchEntry.getByRole("heading", { name: "Kill switch engaged" })).toBeVisible();
});
