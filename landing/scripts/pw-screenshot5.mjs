import { chromium } from 'file:///C:/Users/alfon/AppData/Roaming/npm/node_modules/playwright/index.mjs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { mkdirSync } from 'fs';
const __dirname = dirname(fileURLToPath(import.meta.url));
const screenshotsDir = join(__dirname, '../screenshots');
mkdirSync(screenshotsDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage();
await page.setViewportSize({ width: 1440, height: 900 });
await page.goto('http://localhost:4321', { waitUntil: 'networkidle' });
await page.evaluate(() => {
  document.querySelectorAll('.fade-up, .hero-enter, .reveal-in').forEach(el => {
    el.style.cssText += '; opacity: 1 !important; transform: none !important; animation: none !important;';
    el.classList.add('visible');
  });
});
await page.waitForTimeout(600);

await page.evaluate(() => window.scrollTo(0, 1800));
await page.waitForTimeout(100);
await page.screenshot({ path: join(screenshotsDir, 'verify-step2-area.png') });

await page.evaluate(() => window.scrollTo(0, 3200));
await page.waitForTimeout(100);
await page.screenshot({ path: join(screenshotsDir, 'verify-no-perssched.png') });

await browser.close();
console.log('done');
