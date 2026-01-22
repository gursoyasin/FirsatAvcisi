const { scrapeProduct } = require('./src/services/scraper/index.js');
const browserService = require('./src/services/scraper/BrowserService.js');

async function findFirstProduct(categoryUrl, brand) {
    console.log(`🔎 Finding product in ${brand} category: ${categoryUrl}`);
    const page = await browserService.createPage();
    try {
        await page.goto(categoryUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });

        // Wait for some content
        await new Promise(r => setTimeout(r, 5000));

        let productUrl = null;
        if (brand === 'zara') {
            // Zara Selectors
            productUrl = await page.evaluate(() => {
                const anchors = Array.from(document.querySelectorAll('.product-grid-product-info a, .product-link'));
                return anchors.length > 0 ? anchors[0].href : null;
            });
        } else if (brand === 'network') {
            // Network Selectors
            productUrl = await page.evaluate(() => {
                // Try to find ANY link that looks like a product (contains 'gomlek-' or just is in a product card)
                const anchors = Array.from(document.querySelectorAll('a[href*="-gomlek-"], .productListItem a, .product-item a'));
                return anchors.length > 0 ? anchors[0].href : null;
            });
        }

        return productUrl;
    } catch (e) {
        console.error(`Error finding product for ${brand}:`, e.message);
        return null;
    } finally {
        await page.close();
    }
}

async function runTest() {
    console.log("🚀 Starting LIVE Scraper Test for Zara & Network");
    console.log("-----------------------------------------------");

    // 1. ZARA TEST
    const zaraCategory = "https://www.zara.com/tr/tr/kadin-ceket-l1114.html";
    const zaraProductUrl = await findFirstProduct(zaraCategory, 'zara');

    if (zaraProductUrl) {
        console.log(`🔗 Found Zara Product: ${zaraProductUrl}`);
        try {
            const data = await scrapeProduct(zaraProductUrl);
            console.log("✅ ZARA RESULT:", JSON.stringify(data, null, 2));
        } catch (e) {
            console.error("❌ Zara Scrape Failed:", e.message);
        }
    } else {
        console.error("⚠️ Could not find a Zara product link to test.");
    }

    console.log("\n-----------------------------------------------\n");

    // 2. NETWORK TEST
    const networkCategory = "https://www.network.com.tr/erkek-gomlek-1004";
    const networkProductUrl = await findFirstProduct(networkCategory, 'network');

    if (networkProductUrl) {
        console.log(`🔗 Found Network Product: ${networkProductUrl}`);
        try {
            const data = await scrapeProduct(networkProductUrl);
            console.log("✅ NETWORK RESULT:", JSON.stringify(data, null, 2));
        } catch (e) {
            console.error("❌ Network Scrape Failed:", e.message);
        }
    } else {
        console.error("⚠️ Could not find a Network product link to test.");
    }

    process.exit(0);
}

runTest();
