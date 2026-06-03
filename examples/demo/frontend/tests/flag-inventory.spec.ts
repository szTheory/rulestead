import { expect, test } from "@playwright/test";

import { backendUrl, openAdminPage } from "./support/admin";

test("admin flag inventory lists FleetDesk adoption-lab seeds", async ({ browser }) => {
  const adminPage = await openAdminPage(browser);

  // The admin home now lives at the mount root; the flag inventory moved to /flags.
  await adminPage.goto(`${backendUrl}/admin/flags/flags?env=staging&view=all`);

  await expect(adminPage.getByRole("heading", { name: /Feature flags/ })).toBeVisible();

  for (const key of [
    "enable-new-dashboard",
    "fleet-map-v2",
    "dispatch-ops-copy",
    "ops-banner-config",
  ]) {
    await expect(adminPage.getByText(key).first()).toBeVisible();
  }

  const response = await adminPage.request.get(`${backendUrl}/api/demo/personas`);
  expect(response.ok()).toBeTruthy();
});
