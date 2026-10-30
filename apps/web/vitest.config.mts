import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    // Resolves "@/..." and "@contracts/..." from tsconfig.json paths.
    tsconfigPaths: true,
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./src/test/setup.ts"],
    include: ["src/**/*.test.{ts,tsx}"],
    css: false,
  },
});
