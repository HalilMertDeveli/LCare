import { expect, test, type Page, type WebSocket } from "@playwright/test";

import { accounts, login } from "./helpers";

/**
 * Phase 0 end-to-end flow against the real API:
 * (a) customer A creates a request, (b) admin moves it to InReview,
 * (c) customer A sees "İnceleniyor" without reloading (realtime), (d) customer B cannot see it.
 */
test.describe.configure({ mode: "serial" });

const title = `E2E LED talebi ${Date.now()}`;
const description = "Playwright uçtan uca testi: ekranın sağ üst modülünde görüntü yok.";

let customerPage: Page;
let requestId = "";
const hubSockets: WebSocket[] = [];
const hubEvents: string[] = [];

test.afterAll(async () => {
  await customerPage?.context().close();
});

test("(a) customer A logs in, creates a request and sees it in the list", async ({ browser }) => {
  const context = await browser.newContext();
  customerPage = await context.newPage();
  customerPage.on("websocket", (ws) => {
    if (!ws.url().includes("/hubs/notifications")) return;
    hubSockets.push(ws);
    ws.on("framereceived", (frame) => {
      const payload = typeof frame.payload === "string" ? frame.payload : frame.payload.toString();
      if (payload.includes("serviceRequestChanged")) hubEvents.push(payload);
    });
  });

  await login(customerPage, accounts.customerA, /\/musteri$/);
  await expect(customerPage.getByRole("heading", { name: "Servis taleplerim" })).toBeVisible();

  await customerPage.getByLabel("Başlık").fill(title);
  await customerPage.getByLabel("Açıklama").fill(description);
  await customerPage.getByRole("button", { name: "Talebi gönder" }).click();
  await expect(customerPage.getByText(/Talebiniz oluşturuldu \(LC-\d+\)\./)).toBeVisible();

  const item = customerPage.getByTestId("request-item").filter({ hasText: title });
  await expect(item).toHaveCount(1);
  await expect(item).toContainText("Yeni");

  const href = await item.getByRole("link").getAttribute("href");
  requestId = href?.split("/").pop() ?? "";
  expect(requestId).toMatch(/^[0-9a-f-]{36}$/);

  // Realtime must be connected before the admin acts, so the update arrives as a push.
  await expect(customerPage.locator("[data-connection-state]")).toHaveAttribute(
    "data-connection-state",
    "connected",
  );
});

test("(b) admin sees the request and changes the status to InReview", async ({ browser }) => {
  const context = await browser.newContext();
  const page = await context.newPage();
  await login(page, accounts.admin, /\/yonetim$/);

  const row = page.getByTestId("request-row").filter({ hasText: title });
  await expect(row).toHaveCount(1);
  await expect(row).toContainText("Örnek Reklam A.Ş.");
  await expect(row).toContainText(/LC-\d+/);

  await row.getByRole("link", { name: title }).click();
  await expect(page).toHaveURL(new RegExp(`/yonetim/talepler/${requestId}$`));
  await page.getByLabel("Not (isteğe bağlı)").fill("E2E: inceleme başladı");
  await page.locator("[data-transition=InReview]").click();
  await expect(page.getByText("Durum güncellendi: İnceleniyor.")).toBeVisible();
  await expect(page.getByTestId("status-history")).toContainText("E2E: inceleme başladı");
  // Only transitions allowed from InReview are offered now.
  await expect(page.locator("[data-transition=InReview]")).toHaveCount(0);
  await expect(page.locator("[data-transition=Resolved]")).toHaveCount(1);
  await context.close();
});

test("(c) customer A sees İnceleniyor without a manual reload (realtime)", async () => {
  const navigationsBefore = await customerPage.evaluate(
    () => performance.getEntriesByType("navigation").length,
  );
  const startUrl = customerPage.url();
  const item = customerPage.getByTestId("request-item").filter({ hasText: title });

  await expect(item).toContainText("İnceleniyor", { timeout: 15_000 });
  expect(customerPage.url()).toBe(startUrl);
  expect(
    await customerPage.evaluate(() => performance.getEntriesByType("navigation").length),
  ).toBe(navigationsBefore);

  const transport =
    hubSockets.length > 0 ? "WebSockets" : "non-WebSocket fallback (ServerSentEvents/LongPolling)";
  test.info().annotations.push({
    type: "realtime-transport",
    description: `${transport}; serviceRequestChanged frames over WebSocket: ${hubEvents.length}`,
  });
  console.log(`[realtime] transport=${transport} wsEvents=${hubEvents.length}`);
  if (hubSockets.length > 0) expect(hubEvents.length).toBeGreaterThan(0);

  // And after a reload, straight from REST.
  await customerPage.reload();
  const reloaded = customerPage.getByTestId("request-item").filter({ hasText: title });
  await expect(reloaded).toContainText("İnceleniyor");
  await reloaded.getByRole("link").click();
  await expect(customerPage.getByTestId("status-history")).toContainText("İnceleniyor");
});

test("(d) customer B cannot see customer A's request", async ({ browser }) => {
  const context = await browser.newContext();
  const page = await context.newPage();
  await login(page, accounts.customerB, /\/musteri$/);
  await expect(page.getByRole("heading", { name: /^Taleplerim/ })).toBeVisible();
  await expect(page.getByText("Yükleniyor…")).toHaveCount(0);
  await expect(page.getByTestId("request-item").filter({ hasText: title })).toHaveCount(0);

  await page.goto(`/musteri/talepler/${requestId}`);
  await expect(
    page.getByText("Talep bulunamadı veya bu talebi görüntüleme yetkiniz yok."),
  ).toBeVisible();
  await expect(page.getByText(title)).toHaveCount(0);
  await context.close();
});
