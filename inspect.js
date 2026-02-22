const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  await page.goto('http://localhost:3000/cristo', { waitUntil: 'networkidle' });
  const html = await page.content();
  console.log(html.substring(0, 1500));
  await browser.close();
})();
