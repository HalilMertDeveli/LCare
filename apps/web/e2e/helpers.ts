import { readFileSync } from "node:fs";
import path from "node:path";
import { expect, type Page } from "@playwright/test";

/**
 * The dev-account password lives in the API's Development settings (Seed:DevPassword).
 * It is read at runtime and never logged. Override with E2E_DEV_PASSWORD if needed.
 */
export function devPassword(): string {
  if (process.env.E2E_DEV_PASSWORD) return process.env.E2E_DEV_PASSWORD;
  const file = path.resolve(
    __dirname,
    "../../../services/api/src/LedCare.Api/appsettings.Development.json",
  );
  const raw = readFileSync(file, "utf8").replace(/^\uFEFF/, "");
  const password = (JSON.parse(raw) as { Seed?: { DevPassword?: string } }).Seed?.DevPassword;
  if (!password) throw new Error("Seed.DevPassword not found in appsettings.Development.json");
  return password;
}

export const accounts = {
  customerA: "musteri.a@ledcare.local",
  customerB: "musteri.b@ledcare.local",
  admin: "admin@ledcare.local",
} as const;

export async function login(page: Page, email: string, expectedPath: RegExp): Promise<void> {
  await page.goto("/giris");
  await page.getByLabel("E-posta").fill(email);
  await page.getByLabel("Şifre").fill(devPassword());
  await page.getByRole("button", { name: "Giriş yap" }).click();
  await expect(page).toHaveURL(expectedPath);
}
