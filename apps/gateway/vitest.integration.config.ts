import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/integration/**/*.test.ts"],
    // Container startup and migration runs dominate the integration budget.
    testTimeout: 120_000,
    hookTimeout: 120_000,
  },
});
