#!/usr/bin/env node
// Phase 0 acceptance scenarios: real Flutter app on an emulator + real browser + real API + real PostgreSQL.
//
//   Scenario A: Flutter customer creates → web admin changes status → open Flutter screen updates by itself.
//   Scenario B: web customer creates → Flutter admin changes status → open web page updates by itself.
//   Afterwards: rows are checked directly in PostgreSQL and isolation is checked through the API.
//
// Prerequisites: postgres + API on :5080, `next start`/`next dev` on :3000, emulator running.
// Env: FLUTTER_BIN, ANDROID_DEVICE (default emulator-5554), WEB_URL, API_URL, POSTGRES_CONTAINER.
import { execFileSync, spawn } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const API = process.env.API_URL ?? 'http://localhost:5080';
const WEB = process.env.WEB_URL ?? 'http://localhost:3000';
const DEVICE = process.env.ANDROID_DEVICE ?? 'emulator-5554';
const FLUTTER = process.env.FLUTTER_BIN ?? 'flutter';
const PG = process.env.POSTGRES_CONTAINER ?? 'ledcare-postgres-1';
const READY = 'LEDCARE_READY';

const settings = readFileSync(path.join(root, 'services/api/src/LedCare.Api/appsettings.Development.json'), 'utf8');
const password = JSON.parse(settings.replace(/^﻿/, '')).Seed.DevPassword;

const results = [];
const record = (name, ok, detail = '') => {
  results.push({ name, ok });
  console.log(`[${ok ? 'PASS' : 'FAIL'}] ${name}${detail ? ` — ${detail}` : ''}`);
};

function run(label, command, args, { cwd, env } = {}) {
  let output = '';
  let onReady;
  const ready = new Promise((resolve) => { onReady = resolve; });
  const child = spawn(command, args, { cwd, env: { ...process.env, ...env }, shell: true });
  const onData = (chunk) => {
    const text = chunk.toString();
    output += text;
    if (output.includes(READY)) onReady();
  };
  child.stdout.on('data', onData);
  child.stderr.on('data', onData);
  const done = new Promise((resolve) => {
    child.on('close', (code) => {
      onReady();
      console.log(`  ${label}: exit ${code}`);
      if (code !== 0) console.log(output.split('\n').slice(-25).join('\n'));
      resolve({ code, output });
    });
  });
  return { ready, done };
}

const tmp = mkdtempSync(path.join(os.tmpdir(), 'ledcare-cross-'));
function flutterTest(file, defines = {}) {
  // Defines go through a temp file: the password stays off the command line and titles need no quoting.
  const definesFile = path.join(tmp, `defines-${Date.now()}.json`);
  writeFileSync(definesFile, JSON.stringify({ LEDCARE_TEST_PASSWORD: password, ...defines }));
  return run(`flutter ${file}`, FLUTTER, ['test', `integration_test/${file}`, '-d', DEVICE, `--dart-define-from-file="${definesFile}"`],
    { cwd: path.join(root, 'apps/mobile') });
}

const playwright = (env) => run(`playwright ${Object.keys(env)[0]}`, 'npx',
  ['playwright', 'test', 'e2e/cross-platform.spec.ts', '--reporter=line'],
  { cwd: path.join(root, 'apps/web'), env: { E2E_BASE_URL: WEB, ...env } });

async function login(email) {
  const r = await fetch(`${API}/api/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!r.ok) throw new Error(`login ${email}: ${r.status}`);
  return (await r.json()).accessToken;
}
const get = (token, url) => fetch(`${API}${url}`, { headers: token ? { authorization: `Bearer ${token}` } : {} });

function sql(query) {
  return execFileSync('docker', ['exec', PG, 'psql', '-U', 'ledcare', '-d', 'ledcare', '-At', '-c', query], { encoding: 'utf8' }).trim();
}

async function checkPersistedAndIsolated(scenario, title) {
  const row = sql(`SELECT "Id", "Status" FROM "ServiceRequests" WHERE "Title" = '${title}'`);
  const [id, status] = row.split('|');
  record(`${scenario}: row in PostgreSQL has status InReview`, status === 'InReview', row);

  const history = sql(`SELECT count(*) FROM "ServiceRequestStatusHistory" WHERE "ServiceRequestId" = '${id}'`);
  record(`${scenario}: status history has 2 entries in PostgreSQL`, history === '2', history);

  const audit = sql(`SELECT count(*) FROM "AuditEvents" WHERE "EntityId" = '${id}'`);
  record(`${scenario}: audit trail has 2 events in PostgreSQL`, audit === '2', audit);

  const [customerB, otherOrg, technician] = await Promise.all([
    login('musteri.b@ledcare.local'), login('yonetici@diger-servis.local'), login('saha.teknisyen@ledcare.local'),
  ]);
  for (const [who, token, expected] of [
    ['other customer', customerB, 404], ['other organization', otherOrg, 404], ['unassigned technician', technician, 404], ['anonymous', null, 401],
  ]) {
    const { status: got } = await get(token, `/api/service-requests/${id}`);
    record(`${scenario}: ${who} gets ${expected}`, got === expected, String(got));
  }
}

async function scenarioA() {
  console.log('\n=== Scenario A: Flutter → Web → Flutter ===');
  const created = await flutterTest('customer_create_request_test.dart').done;
  const title = created.output.match(/LEDCARE_CREATED_TITLE=(.+)/)?.[1]?.trim();
  record('A1: customer creates a request in the Flutter app', created.code === 0 && !!title, title);
  if (!title) return;

  const waiting = flutterTest('cross_platform_customer_wait_test.dart', { LEDCARE_TARGET_TITLE: title });
  await waiting.ready;
  const admin = await playwright({ CROSS_ADMIN_TITLE: title }).done;
  record('A2: web admin sees the request and changes its status', admin.code === 0);
  const seen = await waiting.done;
  record('A3: open Flutter screen shows the new status without interaction', seen.code === 0);
  await checkPersistedAndIsolated('A', title);
}

async function scenarioB() {
  console.log('\n=== Scenario B: Web → Flutter → Web ===');
  const title = `Web E2E ${Date.now()}`;
  const customer = playwright({ CROSS_CUSTOMER_TITLE: title });
  await customer.ready;
  record('B1: customer creates a request on the web', true, title);
  const admin = await flutterTest('admin_change_status_test.dart', { LEDCARE_TARGET_TITLE: title }).done;
  record('B2: Flutter admin sees the request and changes its status', admin.code === 0);
  const seen = await customer.done;
  record('B3: open web page shows the new status without reloading', seen.code === 0);
  await checkPersistedAndIsolated('B', title);
}

try {
  await scenarioA();
  await scenarioB();
} finally {
  rmSync(tmp, { recursive: true, force: true });
}

const failed = results.filter((r) => !r.ok);
console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
process.exit(failed.length ? 1 : 0);
