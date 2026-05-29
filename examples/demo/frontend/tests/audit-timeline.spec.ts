import { expect, test } from "@playwright/test";

import { backendUrl, openAdminPage } from "./support/admin";

test("audit timeline lists seeded flag activity after kill switch", async ({ browser }) => {
  const adminPage = await openAdminPage(browser);

  await adminPage.goto(`${backendUrl}/admin/flags/enable-new-dashboard/kill?env=staging`);
  await adminPage.getByLabel("Reason").fill("Adoption lab audit timeline proof");
  await adminPage.getByRole("button", { name: "Confirm kill switch" }).click();
  await expect(adminPage.getByText("Kill switch engaged for Staging.")).toBeVisible();

  await adminPage.goto(`${backendUrl}/admin/flags/audit?env_filter=all`);

  await expect(adminPage.getByText("Kill switch engaged")).toBeVisible({ timeout: 15_000 });
  await expect(adminPage.getByText("enable-new-dashboard")).toBeVisible();

  const filtered = adminPage.locator("form[aria-label='Audit filters']");
  await filtered.getByLabel("Flag key").fill("enable-new-dashboard");
  await filtered.getByRole("button", { name: "Apply filters" }).click();

  await expect(adminPage.getByText("enable-new-dashboard")).toBeVisible();
  await expect(adminPage.getByText("Kill switch engaged")).toBeVisible();
});
