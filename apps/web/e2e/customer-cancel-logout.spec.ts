import { expect, test } from "@playwright/test";

import { accounts, login } from "./helpers";

test("customer cancels own request, loses the action, then logs out", async ({ page }) => {
  const title = `E2E iptal ${Date.now()}`;
  await login(page, accounts.customerA, /\/musteri$/);

  await page.getByLabel("Başlık").fill(title);
  await page.getByLabel("Açıklama").fill("Playwright: müşteri iptal akışı testi.");
  await page.getByRole("button", { name: "Talebi gönder" }).click();
  await page.getByTestId("request-item").filter({ hasText: title }).getByRole("link").click();

  const cancel = page.getByRole("button", { name: "Talebi iptal et" });
  await cancel.click();
  await expect(page.getByText("Bu talebi iptal etmek istediğinizden emin misiniz?")).toBeVisible();
  await cancel.click();
  await expect(page.getByText("Talebiniz iptal edildi.")).toBeVisible();
  await expect(page.getByTestId("status-history")).toContainText("İptal Edildi");
  await expect(cancel).toHaveCount(0);

  await page.getByRole("button", { name: "Çıkış yap" }).first().click();
  await expect(page).toHaveURL(/\/giris/);

  // The session is really gone: protected pages send the user back to login.
  await page.goto("/musteri");
  await expect(page).toHaveURL(/\/giris/);
  const me = await page.request.get("/api/me");
  expect(me.status()).toBe(401);
});
