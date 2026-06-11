import { type Browser, type Page } from "@playwright/test";

const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://localhost:4000";

export async function openAdminPage(browser: Browser): Promise<Page> {
  const adminPage = await browser.newPage();
  await adminPage.goto(`${backendUrl}/demo/sign-in`);
  await adminPage.waitForURL(/\/admin\/flags/);
  await waitForAdminLiveView(adminPage);
  return adminPage;
}

export async function waitForAdminLiveView(page: Page): Promise<void> {
  await page.locator("[data-phx-main].phx-connected").waitFor();
}

export { backendUrl };
