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

async function scrollShot(scrollY, filename) {
  await page.evaluate((y) => window.scrollTo(0, y), scrollY);
  await page.waitForTimeout(100);
  await page.screenshot({ path: join(screenshotsDir, filename) });
}

await scrollShot(0, 'verify-1-hero.png');
await scrollShot(720, 'verify-2-step1.png');
await scrollShot(1500, 'verify-3-step2.png');
await scrollShot(3100, 'verify-4-features.png');

await browser.close();
console.log('done');
