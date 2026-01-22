const browserService = require('./src/services/scraper/BrowserService');
const fs = require('fs');

async function test() {
    console.log("Testing Zara TR Warm-up...");
    const page = await browserService.createPage();
    try {
        await page.goto('https://www.zara.com/tr/tr/', { waitUntil: 'domcontentloaded', timeout: 30000 });
        console.log("Navigated to TR Home.");

        const content = await page.content();
        fs.writeFileSync('zara_warmup_dump.html', content);
        console.log("Dumped HTML.");

        // Check for specific home page elements vs location selector
        const title = await page.title();
        console.log("Title:", title);

    } catch (e) {
        console.error("Error:", e);
    } finally {
        await page.close();
        await browserService.close();
    }
}

test();
