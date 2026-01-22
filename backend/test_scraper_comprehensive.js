const { scrapeProduct } = require('./src/services/scraper/index.js');
const browserService = require('./src/services/scraper/BrowserService.js');

async function findFirstProduct(categoryUrl, brand) {
    console.log(`🔎 Finding product in ${brand} category: ${categoryUrl}`);
    const page = await browserService.createPage();
    try {
        await page.goto(categoryUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
        await new Promise(r => setTimeout(r, 5000));

        let productUrl = null;

        // Dynamic Selector Logic based on Brand
        productUrl = await page.evaluate((brand) => {
            const getHref = (selector) => {
                const el = document.querySelector(selector);
                return el ? el.href : null;
            };

            if (brand === 'lcwaikiki') return getHref('a.product-card') || getHref('.product-card a') || getHref('.product-image a') || getHref('a[href*="-p-"]');
            if (brand === 'beymen') return getHref('.o-productList__item a') || getHref('.m-productCard__link');
            if (brand === 'adidas') return getHref('div[data-auto-id="product-card-col"] a') || getHref('.glass-product-card__assets-link') || getHref('a[href*="/tr/"]');
            if (brand === 'mavi') return getHref('.product-item a') || getHref('.product-card a');
            if (brand === 'bershka') return getHref('.category-product-card a') || getHref('.grid-card a');
            if (brand === 'boyner') return getHref('.product-item a') || getHref('.product-list-item a');

            // Generic Fallback
            const anyLink = document.querySelector('a[href*="/p/"]'); // Generic 'p' or 'product'
            return anyLink ? anyLink.href : null;
        }, brand);

        return productUrl;
    } catch (e) {
        console.error(`Error finding product for ${brand}:`, e.message);
        return null;
    } finally {
        await page.close();
    }
}

async function runTest() {
    console.log("🚀 Starting COMPREHENSIVE Scraper Test");
    console.log("-----------------------------------------------");

    const TEST_CASES = [
        { brand: 'lcwaikiki', category: 'https://www.lcw.com/kadin-elbise-t-19' }, // Turkish Generic
        { brand: 'beymen', category: 'https://www.beymen.com/tr/kadin-canta-10020' }, // Luxury
        { brand: 'adidas', category: 'https://www.adidas.com.tr/tr/erkek-futbol-formalar' }, // Global SPA
        { brand: 'mavi', category: 'https://www.mavi.com/erkek/jean-pantolon/c/2' }, // Turkish Brand
        { brand: 'bershka', category: 'https://www.bershka.com/tr/kadin/koleksiyon/korse-c1010193216.html' }, // Inditex
        // { brand: 'boyner', category: 'https://www.boyner.com.tr/erkek-gomlek-c-300103' } // Multi-brand (Optional)
    ];

    for (const test of TEST_CASES) {
        console.log(`\n🔹 Testing Brand: ${test.brand.toUpperCase()}`);
        const productUrl = await findFirstProduct(test.category, test.brand);

        if (productUrl) {
            console.log(`   🔗 Found URL: ${productUrl}`);
            try {
                const data = await scrapeProduct(productUrl);

                // Validation
                const success = data.currentPrice > 0 && data.title.length > 5;
                const statusIcon = success ? '✅' : '❌';

                console.log(`   ${statusIcon} Result: ${data.title.substring(0, 30)}... | ${data.currentPrice} TL | Img: ${data.imageUrl ? 'YES' : 'NO'}`);
                if (!success) console.log("      (Debug) Full Data:", JSON.stringify(data));

            } catch (e) {
                console.error(`   ❌ Scrape Failed:`, e.message);
            }
        } else {
            console.error(`   ⚠️ No product link found in category.`);
        }
    }

    console.log("\n-----------------------------------------------");
    console.log("🏁 Test Completed.");
    process.exit(0);
}

runTest();
