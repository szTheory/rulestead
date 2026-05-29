import { expect, test } from "@playwright/test";

const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://localhost:4000";

test.describe("FleetDesk adoption journeys", () => {
  test("loads adoption lab shell with seeded remote-config banner", async ({ page }) => {
    await page.goto("/");

    await expect(page.getByRole("heading", { name: "FleetDesk dispatch" })).toBeVisible();
    await expect(
      page.getByText("Winter storm advisory — review reroute playbook."),
    ).toBeVisible();
    await expect(page.getByText("enable-new-dashboard")).toBeVisible();
    await expect(page.getByText("fleet-map-v2")).toBeVisible();
    await expect(page.getByText("dispatch-ops-copy")).toBeVisible();
    await expect(page.getByText("ops-banner-config")).toBeVisible();
  });

  test("enterprise persona sees map v2 enabled via targeting", async ({ page }) => {
    await page.goto("/");

    await page.selectOption("#persona-select", { label: "Fleet manager" });

    await expect(page.getByText("Map renderer: vector map v2")).toBeVisible({
      timeout: 15_000,
    });
  });

  test("explain API surfaces a support-safe trace", async ({ page }) => {
    await page.goto("/");

    await expect(page.getByText("Support journey · explain API")).toBeVisible();
    await expect(page.getByText(/Matched rule|Environment staging|snapshot v/i)).toBeVisible({
      timeout: 15_000,
    });
  });

  test("personas API matches backend fixture set", async ({ request }) => {
    const response = await request.get(`${backendUrl}/api/demo/personas`);
    expect(response.ok()).toBeTruthy();

    const payload = await response.json();
    expect(payload.product).toBe("FleetDesk");
    expect(payload.personas).toHaveLength(3);
    expect(payload.flags).toHaveLength(4);
  });
});
