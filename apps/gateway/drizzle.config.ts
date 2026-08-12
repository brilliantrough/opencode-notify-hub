import { defineConfig } from "drizzle-kit";

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  // Only used by drizzle-kit commands that connect to a database
  // (e.g. `drizzle-kit push`, which this project does not use); generation
  // and the explicit db:migrate CLI are all we run.
  dbCredentials: {
    url: process.env.DATABASE_URL ?? "postgres://localhost:5432/notify",
  },
});
