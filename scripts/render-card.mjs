// Render an HTML "card" to a PNG using headless Chromium — no visible browser window.
// Used for Telegram status cards so screenshots are produced silently.
//
// Usage:  node scripts/render-card.mjs <htmlPath> <outPng> [width] [height]
//
// @playwright/test is resolved from ../frontend/node_modules via createRequire (ESM
// ignores NODE_PATH and resolves bare imports from this file's dir, so we can't rely
// on cwd). The Playwright MCP opens a headed browser and blocks file://; this doesn't.
import { createRequire } from 'node:module';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { resolve, dirname, join } from 'node:path';

const [, , htmlArg, outArg, wArg, hArg] = process.argv;
if (!htmlArg || !outArg) {
  console.error('usage: node render-card.mjs <htmlPath> <outPng> [width] [height]');
  process.exit(2);
}

const scriptDir = dirname(fileURLToPath(import.meta.url));
const frontendDir = resolve(scriptDir, '..', 'frontend');
const require = createRequire(join(frontendDir, 'package.json'));
const { chromium } = require('@playwright/test');

const width = Number(wArg) || 800;
const height = Number(hArg) || 600;
const url = pathToFileURL(resolve(htmlArg)).href;
const out = resolve(outArg);

const browser = await chromium.launch({ headless: true });
try {
  const page = await browser.newPage({ viewport: { width, height } });
  await page.goto(url, { waitUntil: 'networkidle' });
  const card = page.locator('.card');
  await ((await card.count()) ? card : page).screenshot({ path: out });
  console.log(`rendered ${out}`);
} finally {
  await browser.close();
}
