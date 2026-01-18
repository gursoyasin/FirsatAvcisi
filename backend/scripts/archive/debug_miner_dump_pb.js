const browserService = require('./src/services/scraper/BrowserService');
const fs = require('fs');

async function debugPB() {
    console.log("🐛 Debugging Pull&Bear...");
    const url = "https://www.pullandbear.com/tr/kadin-promosyon-n6548";
    const page = await browserService.createPage();

    try {
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });

        console.log("Waiting 5s...");
        await new Promise(r => setTimeout(r, 5000));

        // Scroll a bit
        await page.evaluate(() => window.scrollBy(0, 500));
        await new Promise(r => setTimeout(r, 2000));

        const content = await page.content();
        console.log(`Length: ${content.length}`);
        fs.writeFileSync('debug_pb_dump.html', content);
        console.log("Response dumped to debug_pb_dump.html");

    } catch (e) {
        console.error(e);
    } finally {
        await page.close();
        process.exit(0);
    }
}

debugPB();
