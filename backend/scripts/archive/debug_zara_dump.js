const browserService = require('./src/services/scraper/BrowserService');
const fs = require('fs');

async function debugZara() {
    console.log("🐛 Debugging Zara...");
    const url = "https://www.zara.com/tr/tr/woman-special-prices-l1327.html?v1=2418818";
    const page = await browserService.createPage();

    try {
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });

        console.log("Waiting 5s...");
        await new Promise(r => setTimeout(r, 5000));

        const content = await page.content();
        console.log(`Length: ${content.length}`);
        fs.writeFileSync('debug_zara_dump.html', content);
        console.log("Response dumped to debug_zara_dump.html");

    } catch (e) {
        console.error(e);
    } finally {
        await page.close();
        process.exit(0);
    }
}

debugZara();
