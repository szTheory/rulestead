import { type Browser, type Page } from "@playwright/test";

const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://localhost:4000";

export async function openAdminPage(browser: Browser): Promise<Page> {
  const adminPage = await browser.newPage();
  await adminPage.goto(`${backendUrl}/demo/sign-in`);
  await adminPage.waitForURL(/\/admin\/flags/);
  return adminPage;
}

export { backendUrl };
