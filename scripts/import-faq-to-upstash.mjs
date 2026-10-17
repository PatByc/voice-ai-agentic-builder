import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const DEFAULT_FILE = "agents/prx02 - OL FB Campaign/KB_OL_lead_FAQ.md";
const BATCH_SIZE = 50;

async function loadEnv(file = ".env") {
  let content;
  try {
    content = await readFile(file, "utf8");
  } catch (error) {
    if (error.code === "ENOENT") return;
    throw error;
  }

  for (const line of content.split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (!match || process.env[match[1]]) continue;
    let value = match[2];
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    process.env[match[1]] = value;
  }
}

function parseFaq(markdown, source) {
  const lines = markdown.split(/\r?\n/);
  const entries = [];
  let category = "Introduction";
  let question = null;
  let body = [];

  const flush = () => {
    if (!question) return;
    const answer = body.join("\n").trim();
    if (!answer) return;
    const data = `Category: ${category}\nQuestion: ${question}\n\n${answer}`;
    const id = createHash("sha256")
      .update(`${source}\n${category}\n${question}`)
      .digest("hex")
      .slice(0, 32);

    entries.push({
      id,
      data,
      metadata: { source, category, question },
    });
  };

  for (const line of lines) {
    if (/^# (?!#)/.test(line)) {
      flush();
      question = null;
      body = [];
      category = line.replace(/^#\s+/, "").trim();
      continue;
    }

    if (/^##\s+/.test(line)) {
      flush();
      question = line.replace(/^##\s+/, "").trim();
      body = [];
      continue;
    }

    if (question) body.push(line);
  }

  flush();
  return entries;
}

async function uploadBatch(endpoint, token, batch) {
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(batch),
  });

  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`Upstash returned ${response.status}: ${detail}`);
  }
}

await loadEnv();

const args = new Set(process.argv.slice(2));
const fileArg = process.argv.slice(2).find((arg) => !arg.startsWith("--"));
const file = fileArg || DEFAULT_FILE;
const source = path.basename(file);
const markdown = await readFile(file, "utf8");
const entries = parseFaq(markdown, source);

if (!entries.length) throw new Error(`No FAQ entries found in ${file}`);

console.log(`Found ${entries.length} FAQ entries in ${file}.`);
console.log(`First entry: ${entries[0].metadata.category} → ${entries[0].metadata.question}`);
console.log(`Last entry: ${entries.at(-1).metadata.category} → ${entries.at(-1).metadata.question}`);

if (!args.has("--confirm")) {
  console.log("Dry run only. Re-run with --confirm to upload.");
  process.exit(0);
}

const url = process.env.UPSTASH_VECTOR_REST_URL?.replace(/\/$/, "");
const token = process.env.UPSTASH_VECTOR_REST_TOKEN;
const namespace = process.env.UPSTASH_VECTOR_NAMESPACE || "ol-faq";

if (!url || !token) {
  throw new Error("Set UPSTASH_VECTOR_REST_URL and UPSTASH_VECTOR_REST_TOKEN in .env before uploading.");
}

const endpoint = `${url}/upsert-data/${encodeURIComponent(namespace)}`;
for (let offset = 0; offset < entries.length; offset += BATCH_SIZE) {
  const batch = entries.slice(offset, offset + BATCH_SIZE);
  await uploadBatch(endpoint, token, batch);
  console.log(`Uploaded ${Math.min(offset + batch.length, entries.length)}/${entries.length}.`);
}

console.log(`Import complete. Namespace: ${namespace}`);
