const { scrapeProduct } = require('./src/services/scraper');

const TEST_URLS = [
    // Zara (Complex SPA + Redirects)
    "https://www.zara.com/tr/tr/kemerli-kisa-trenckot-p03046027.html?v1=311295988",
    // Trendyol (Bot Detection)
    "https://www.trendyol.com/trendyolmilla/kadin-siyah-yuksek-bel-toparlayici-orme-tayt-twoaw20ta0087-p-31687232",
    // Bershka (Inditex sibling)
    "https://www.bershka.com/tr/erkek-oversize-kisa-kollu-ti%C5%9F%C3%B6rt-c0p162626500.html",
    // H&M (Different structure)
    "https://www2.hm.com/tr_tr/productpage.1228224001.html"
];

async function runTests() {
    console.log("🚀 Starting Comprehensive Scraper Test...");

    for (const url of TEST_URLS) {
        console.log(`\n-----------------------------------`);
        console.log(`🔎 Testing URL: ${url}`);
        try {
            const start = Date.now();
            const result = await scrapeProduct(url);
            const duration = (Date.now() - start) / 1000;

            if (result.title === "Ürün Başlığı Bulunamadı" || result.title === "REDIRECT_REQUIRED") {
                console.warn(`⚠️ WARNING: Scrape incomplete or redirected in ${duration}s`);
                console.log("Result:", result);
            } else {
                console.log(`✅ SUCCESS in ${duration}s`);
                console.log(`   Title: ${result.title}`);
                console.log(`   Price: ${result.currentPrice}`);
                console.log(`   Source: ${result.source}`);
                console.log(`   Category: ${result.category}`);
            }
        } catch (error) {
            console.error(`❌ FAILED: ${error.message}`);
        }
    }
    console.log(`\n-----------------------------------`);
    console.log("🏁 Test Complete");
    process.exit(0);
}

runTests();
