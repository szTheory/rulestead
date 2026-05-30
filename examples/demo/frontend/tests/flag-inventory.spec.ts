import { expect, test } from "@playwright/test";

import { backendUrl, openAdminPage } from "./support/admin";

test("admin flag inventory lists FleetDesk adoption-lab seeds", async ({ browser }) => {
  const adminPage = await openAdminPage(browser);

  await expect(adminPage.getByRole("heading", { name: "Flag inventory" })).toBeVisible();
  await expect(adminPage.getByText("enable-new-dashboard", { exact: true })).toBeVisible();
  await expect(adminPage.getByText("fleet-map-v2", { exact: true })).toBeVisible();
  await expect(adminPage.getByText("dispatch-ops-copy", { exact: true })).toBeVisible();
  await expect(adminPage.getByText("ops-banner-config", { exact: true })).toBeVisible();
  await expect(adminPage.getByText("Staging", { exact: true })).toBeVisible();

  const response = await adminPage.request.get(`${backendUrl}/api/demo/personas`);
  expect(response.ok()).toBeTruthy();
});
