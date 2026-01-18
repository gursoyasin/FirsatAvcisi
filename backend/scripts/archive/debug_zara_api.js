const browserService = require('./src/services/scraper/BrowserService');

async function debugZaraApi() {
    console.log("🐛 Debugging Zara API...");
    const url = "https://www.zara.com/tr/tr/category/2418848/products?ajax=true";
    const page = await browserService.createPage();

    try {
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        // Go to JSON URL
        const response = await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
        const content = await response.text();

        console.log(`Response Length: ${content.length}`);
        console.log("Snippet:", content.substring(0, 500));

        try {
            const json = JSON.parse(content);
            console.log("✅ Valid JSON!");
            console.log(`Product count: ${json.products ? json.products.length : 'N/A'}`);
        } catch (e) {
            console.log("❌ Not JSON");
        }

    } catch (e) {
        console.error(e);
    } finally {
        await page.close();
        process.exit(0);
    }
}

debugZaraApi();
