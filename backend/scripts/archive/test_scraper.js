const { scrapeProduct } = require('./src/services/scraper/index');

async function test() {
    const url = "https://www.zara.com/share/kapusonlu-triko-anorak-p06318294.html?v1=480486698";
    console.log(`Testing scraper with URL: ${url}`);

    try {
        const result = await scrapeProduct(url);
        console.log("--------------------------------");
        console.log("Scraping Result:");
        console.log(JSON.stringify(result, null, 2));
        console.log("--------------------------------");
    } catch (error) {
        console.error("Test failed:", error);
    }
}

test();
