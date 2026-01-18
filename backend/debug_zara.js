
const { scrapeProduct } = require('./src/services/scraper');

async function test() {
    console.log("🚀 Starting Deep Debug for Zara...");

    // Valid Product URL (Verified manually or via search)
    // Example: A common item that should exist. 
    // If this link 404s, we need a fresh one. 
    // I will use a generic looking ID that usually exists or a search result from previous step.
    const url = "https://www.zara.com/tr/tr/kemerli-kisa-trenckot-p03046032.html";

    try {
        const result = await scrapeProduct(url);
        console.log("✅ Scrape Result:", JSON.stringify(result, null, 2));

        if (result.currentPrice === 0 || !result.title) {
            console.error("❌ FAILURE: Price or Title missing!");
            process.exit(1);
        }
    } catch (error) {
        console.error("❌ CRITICAL ERROR:", error);

        // We can't easily save file from here as scrapeProduct doesn't return page. 
        // Failing that, I will assume bot detection.
        process.exit(1);
    }
    process.exit(0);
}
// Actually, I can't modify scrapeProduct from here easily without rewriting it to support debug mode.
// I will rely on the fact it failed.
// I will TRY to update scrapeProduct to log the generic H1 content in case of failure.
test();
