import { expect, test } from "@playwright/test";

const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://localhost:4000";

test.describe("FleetDesk adoption journeys", () => {
  test("loads dispatch workspace with seeded storm advisory", async ({ page }) => {
    await page.goto("/");

    await expect(page.getByRole("heading", { name: "Live map" })).toBeVisible();

    await expect(
      page.getByText("Winter storm advisory — review reroute playbook."),
    ).toBeVisible();

    await page.getByRole("button", { name: "Developer tools" }).click();

    const devPanel = page.getByLabel("Developer tools");
    await expect(devPanel.getByText("enable-new-dashboard", { exact: true })).toBeVisible({
      timeout: 15_000,
    });
    await expect(devPanel.getByText("fleet-map-v2", { exact: true })).toBeVisible();
    await expect(devPanel.getByText("dispatch-ops-copy", { exact: true })).toBeVisible();
    await expect(devPanel.getByText("ops-banner-config", { exact: true })).toBeVisible();
  });

  test("enterprise account sees map v2 enabled via targeting", async ({ page }) => {
    await page.goto("/");

    await page.selectOption("#view-as-select", {
      label: "Morgan Chen · Acme Logistics (Enterprise)",
    });

    await expect(page.getByText("Vector map v2")).toBeVisible({
      timeout: 15_000,
    });
  });

  test("developer tools surfaces a support-safe explain trace", async ({ page }) => {
    await page.goto("/");

    await page.getByRole("button", { name: "Developer tools" }).click();

    const devPanel = page.getByLabel("Developer tools");
    await expect(devPanel.getByRole("heading", { name: "Explain trace" })).toBeVisible();
    await expect(devPanel.getByRole("heading", { name: "Flag snapshots" })).toBeVisible();
    await expect(devPanel.getByRole("heading", { name: "Bridge status" })).toBeVisible();
    await expect(devPanel.getByText("enable-new-dashboard", { exact: true })).toBeVisible({
      timeout: 15_000,
    });
  });

  test("personas API matches backend fixture set", async ({ request }) => {
    const response = await request.get(`${backendUrl}/api/demo/personas`);
    expect(response.ok()).toBeTruthy();

    const payload = await response.json();
    expect(payload.product).toBe("FleetDesk");
    expect(payload.personas).toHaveLength(3);
    expect(payload.flags).toHaveLength(6);
  });
});
