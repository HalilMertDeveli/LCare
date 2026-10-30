// Exports the OpenAPI document from the running API (Development only).
// Usage: npm run export [-- --out <file>]   (env LEDCARE_API_URL overrides http://localhost:5080)
import { writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const base = process.env.LEDCARE_API_URL ?? "http://localhost:5080";
const url = `${base.replace(/\/$/, "")}/openapi/v1.json`;
const outIndex = process.argv.indexOf("--out");
const target =
  outIndex > -1 && process.argv[outIndex + 1]
    ? process.argv[outIndex + 1]
    : fileURLToPath(new URL("../openapi.json", import.meta.url));

const res = await fetch(url);
if (!res.ok) {
  console.error(`OpenAPI export failed: ${res.status} ${res.statusText} (${url})`);
  process.exit(1);
}
const doc = await res.json();
await writeFile(target, JSON.stringify(doc, null, 2) + "\n", "utf8");
console.log(`Wrote ${target} from ${url}`);
