const puppeteer = require('puppeteer');
const { scrapeProduct } = require('./src/services/scraper/index');

async function findAndTestZara() {
    console.log("🔍 Finding a valid Zara product URL...");
    const browser = await puppeteer.launch({
        headless: "new",
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    try {
        await page.goto('https://www.zara.com/tr/tr/kadin-yeni-koleksiyon-l1180.html', { waitUntil: 'domcontentloaded' });

        // Wait for product grid
        await page.waitForSelector('.product-grid-product__link', { timeout: 10000 });

        // Click the first product
        console.log("🖱️ Clicking first product...");
        await Promise.all([
            page.waitForNavigation({ waitUntil: 'networkidle0' }),
            page.click('.product-grid-product__link')
        ]);

        const productLink = page.url();
        console.log(`✅ Found Product URL: ${productLink}`);
        await browser.close();

        console.log("🚀 Testing Scraper on this URL...");
        const result = await scrapeProduct(productLink);

        console.log("--------------------------------");
        console.log("Scraping Result:");
        console.log(JSON.stringify(result, null, 2));
        console.log("--------------------------------");

    } catch (error) {
        console.error("Test Error:", error);
        if (browser) await browser.close();
    }
}

findAndTestZara();
