import { expect, test } from "@playwright/test";

import { openAdminPage } from "./support/admin";

test("rollout controls surface staged percentage rule for fleet-map-v2", async ({ browser }) => {
  const adminPage = await openAdminPage(browser);

  await adminPage.goto(
    `${process.env.DEMO_BACKEND_URL ?? "http://localhost:4000"}/admin/flags/fleet-map-v2/rollouts?env=staging`,
  );

  await expect(adminPage.getByText("Rollout controls")).toBeVisible({ timeout: 15_000 });
  await expect(adminPage.getByText("Pro plan staged rollout")).toBeVisible();
  await expect(adminPage.getByText("Enterprise fleet managers")).toBeVisible();
});
