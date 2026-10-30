import path from "node:path";
import { defineConfig, devices } from "@playwright/test";

/**
 * E2E tests run against the REAL API (http://localhost:5080 by default, via the Next.js
 * rewrites) and a real Next.js server. Set E2E_BASE_URL to test an already running server
 * (e.g. `next start`); otherwise `next dev` on port 3000 is started (or reused).
 * Paths are absolute so the config also works when re-exported from ../playwright.config.ts.
 */
const baseURL = process.env.E2E_BASE_URL ?? "http://localhost:3000";

export default defineConfig({
  testDir: __dirname,
  testMatch: "**/*.spec.ts",
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 60_000,
  expect: { timeout: 10_000 },
  reporter: [["list"]],
  outputDir: path.join(__dirname, "..", "test-results"),
  use: {
    baseURL,
    locale: "tr-TR",
    timezoneId: "Europe/Istanbul",
    trace: "retain-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: process.env.E2E_BASE_URL
    ? undefined
    : {
        command: "npm run dev",
        cwd: path.join(__dirname, ".."),
        url: baseURL,
        reuseExistingServer: true,
        timeout: 120_000,
      },
});
