import { expect, test } from "@playwright/test";

import { accounts, login } from "./helpers";

/**
 * Web steps of the cross-platform scenarios, driven by tests/integration/cross-platform.mjs.
 * Each step only runs when its environment variable is set, so `npm run test:e2e` skips them.
 */
const adminTitle = process.env.CROSS_ADMIN_TITLE;
const customerTitle = process.env.CROSS_CUSTOMER_TITLE;

test("admin moves a request created on another platform to InReview", async ({ page }) => {
  test.skip(!adminTitle, "CROSS_ADMIN_TITLE not set");
  await login(page, accounts.admin, /\/yonetim$/);

  const row = page.getByTestId("request-row").filter({ hasText: adminTitle! });
  await expect(row).toHaveCount(1);
  await expect(row).toContainText("Yeni");
  await row.getByRole("link", { name: adminTitle! }).click();

  await page.getByLabel("Not (isteğe bağlı)").fill("Web yönetici paneli: çapraz platform testi");
  await page.locator("[data-transition=InReview]").click();
  await expect(page.getByText("Durum güncellendi: İnceleniyor.")).toBeVisible();
});

test("customer creates a request and sees a status changed on another platform without reloading", async ({ page }) => {
  test.skip(!customerTitle, "CROSS_CUSTOMER_TITLE not set");
  test.setTimeout(6 * 60_000);

  await login(page, accounts.customerA, /\/musteri$/);
  await page.getByLabel("Başlık").fill(customerTitle!);
  await page.getByLabel("Açıklama").fill("Çapraz platform testi: webden oluşturulan talep.");
  await page.getByRole("button", { name: "Talebi gönder" }).click();
  await expect(page.getByText(/Talebiniz oluşturuldu \(LC-\d+\)\./)).toBeVisible();

  const item = page.getByTestId("request-item").filter({ hasText: customerTitle! });
  await expect(item).toContainText("Yeni");
  await expect(page.locator("[data-connection-state]")).toHaveAttribute("data-connection-state", "connected");

  const navigations = await page.evaluate(() => performance.getEntriesByType("navigation").length);
  console.log("LEDCARE_READY");

  await expect(item).toContainText("İnceleniyor", { timeout: 5 * 60_000 });
  expect(await page.evaluate(() => performance.getEntriesByType("navigation").length)).toBe(navigations);
});
