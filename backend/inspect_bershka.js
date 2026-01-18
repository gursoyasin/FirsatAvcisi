const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const fs = require('fs');

puppeteer.use(StealthPlugin());

(async () => {
    const browser = await puppeteer.launch({
        headless: "new",
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--window-size=1920,1080']
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });

    // Set headers
    await page.setUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");

    const url = "https://www.bershka.com/tr/erkek-oversize-kisa-kollu-ti%C5%9F%C3%B6rt-c0p162626500.html";
    console.log(`Navigating to ${url}...`);

    // Cookie injection similar to index.js
    const domain = new URL(url).hostname.replace('www.', '');
    await page.setCookie(
        { name: 'user_id', value: '123456789', domain: `.${domain}` },
        { name: 'store_id', value: '1', domain: `.${domain}` }
    );

    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });

    // Wait a bit for SPA
    await new Promise(r => setTimeout(r, 4000));

    console.log("Saving HTML snapshot...");
    const content = await page.content();
    fs.writeFileSync('bershka_dump.html', content);

    console.log("Looking for h1...");
    const h1 = await page.$eval('h1', el => el.innerText).catch(e => "NOT FOUND");
    console.log(`H1: ${h1}`);

    console.log("Looking for class names related to price...");
    const priceClasses = await page.evaluate(() => {
        const elements = document.querySelectorAll('*');
        const prices = [];
        elements.forEach(el => {
            if (el.className && typeof el.className === 'string' && (el.className.includes('price') || el.innerText.includes('TL'))) {
                prices.push({ tag: el.tagName, class: el.className, text: el.innerText.slice(0, 50) });
            }
        });
        return prices.slice(0, 20);
    });
    console.log("Potential prices:", priceClasses);

    await browser.close();
})();
