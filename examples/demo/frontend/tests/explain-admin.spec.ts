import { expect, test } from "@playwright/test";

import { openAdminPage } from "./support/admin";

const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://localhost:4000";

test("admin explain permalink renders support-safe trace", async ({ browser }) => {
  const adminPage = await openAdminPage(browser);

  await adminPage.goto(
    `${backendUrl}/admin/flags/enable-new-dashboard/explain?env=staging&targeting_key=demo-user`,
  );

  await expect(adminPage.getByText("Decision explainer")).toBeVisible({ timeout: 15_000 });
  await expect(adminPage.getByText("Traits are never stored")).toBeVisible();
  await expect(adminPage.getByText(/Matched rule|No rule matched|default/i)).toBeVisible({
    timeout: 15_000,
  });
});
