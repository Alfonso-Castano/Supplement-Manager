import { chromium } from 'file:///C:/Users/alfon/AppData/Roaming/npm/node_modules/playwright/index.mjs';

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

const positions = await page.evaluate(() => {
  let analysisPos = null;
  document.querySelectorAll('*').forEach(el => {
    if (el.textContent.trim() === 'ANALYSIS RESULTS') {
      const rect = el.getBoundingClientRect();
      analysisPos = rect.top + window.scrollY;
    }
  });

  let persSchedPos = null;
  document.querySelectorAll('*').forEach(el => {
    if (el.textContent.trim() === 'Personalized Schedule') {
      const rect = el.getBoundingClientRect();
      persSchedPos = rect.top + window.scrollY;
    }
  });

  let interactionPos = null;
  document.querySelectorAll('*').forEach(el => {
    if (el.textContent.trim() === 'Interaction Analysis') {
      const rect = el.getBoundingClientRect();
      interactionPos = rect.top + window.scrollY;
    }
  });

  return { analysisPos, persSchedPos, interactionPos };
});

console.log('Positions:', JSON.stringify(positions));

await browser.close();
