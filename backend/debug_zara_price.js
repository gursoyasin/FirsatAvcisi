const { scrapeProduct } = require('./src/services/scraper/index.js');
const browserService = require('./src/services/scraper/BrowserService.js');
const cheerio = require('cheerio');

async function debugZara(url) {
    console.log(`🔎 Debugging Zara URL: ${url}`);
    const page = await browserService.createPage();
    try {
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
        await new Promise(r => setTimeout(r, 5000)); // Wait for render

        const content = await page.content();
        const $ = cheerio.load(content);

        console.log("--- JSON-LD SCRIPTS ---");
        $("script[type='application/ld+json']").each((i, el) => {
            console.log(`Script ${i}:`, $(el).html().substring(0, 500) + "...");
        });

        console.log("--- PRICE SELECTORS ---");
        console.log("price-current__amount:", $(".price-current__amount").text());
        console.log("money-amount__main:", $(".money-amount__main").text());
        console.log("price__amount:", $(".price__amount").text());

        console.log("--- META TAGS ---");
        console.log("og:price:amount:", $("meta[property='og:price:amount']").attr("content"));
        console.log("product:price:amount:", $("meta[property='product:price:amount']").attr("content"));

    } catch (e) {
        console.error("Debug Error:", e);
    } finally {
        await page.close();
    }
}

debugZara('https://www.zara.com/tr/tr/oversize-bomber-ceket-p08372369.html');
