import { chromium } from 'file:///C:/Users/alfon/AppData/Roaming/npm/node_modules/playwright/index.mjs';

const browser = await chromium.launch();
const page = await browser.newPage();
await page.setViewportSize({ width: 1440, height: 900 });
await page.goto('http://localhost:4321', { waitUntil: 'networkidle' });

const results = await page.evaluate(() => {
  const allText = document.body.innerText;

  return {
    hasAnalysisResults: allText.includes('ANALYSIS RESULTS'),
    hasPersonalizedSchedule: allText.includes('Personalized Schedule'),
    hasInteractionResults: allText.includes('INTERACTION RESULTS'),
    circleBadges: document.querySelectorAll('.rounded-full.bg-\\[var\\(--color-blue-accent\\)\\]').length,
    oldNumberSpans: document.querySelectorAll('.text-5xl.opacity-30').length,
    blueTintCards: Array.from(document.querySelectorAll('.bg-\\[var\\(--color-blue-tint\\)\\]')).map(el => el.tagName + '.' + el.className.split(' ').slice(0,3).join('.')),
    buttonClasses: Array.from(document.querySelectorAll('button[type="submit"]')).map(b => b.className),
    h1Classes: document.querySelector('h1') ? document.querySelector('h1').className : 'not found',
  };
});

console.log(JSON.stringify(results, null, 2));
await browser.close();
