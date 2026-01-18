const { scrapeProduct } = require('./scraper/index');
const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const cheerio = require('cheerio');

puppeteer.use(StealthPlugin());

async function searchMarket(market, query) {
    let browser;
    try {
        browser = await puppeteer.launch({
            headless: "new",
            args: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-blink-features=AutomationControlled',
                '--window-size=1920,1080'
            ]
        });
        const page = await browser.newPage();
        await page.setViewport({ width: 1920, height: 1080 });
        await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        let searchUrl = "";
        let selectors = {};

        if (market === "trendyol") {
            searchUrl = `https://www.trendyol.com/sr?q=${encodeURIComponent(query)}`;
            selectors = {
                item: '.p-card-wrppr, .product-card, [data-id], article',
                link: 'a',
                price: '.prc-dsc, .prc-box-dscntd, .price, [class*="price"]',
                title: '.prdct-desc-cntnr-ttl, .product-card-title, h3, [class*="title"]'
            };
        } else if (market === "amazon") {
            searchUrl = `https://www.amazon.com.tr/s?k=${encodeURIComponent(query)}`;
            selectors = {
                item: '.s-result-item[data-component-type="s-search-result"], .s-card-container',
                link: 'h2 a, .a-link-normal',
                price: '.a-price-whole, .a-offscreen',
                title: 'h2 span, .a-size-base-plus'
            };
        } else if (market === "hepsiburada") {
            searchUrl = `https://www.hepsiburada.com/ara?q=${encodeURIComponent(query)}`;
            selectors = {
                item: '[class*="productListContent-item"], [data-test-id="product-card-container"], .product-item',
                link: 'a',
                price: '[data-test-id="price-current-price"], .price-current-price, [class*="current-price"]',
                title: '[data-test-id="product-card-name"], .product-name, h3'
            };
        }

        console.log(`Searching ${market}: ${searchUrl}`);
        await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });

        // Wait a bit for dynamic content
        await new Promise(r => setTimeout(r, 5000)); // Increase wait

        const content = await page.content();
        if (market === "hepsiburada") console.log(`[DEBUG] Hepsiburada First 500 chars: ${content?.slice(0, 500)}`);
        const $ = cheerio.load(content);
        console.log(`[DEBUG] ${market} Content Length: ${content.length}`);
        console.log(`[DEBUG] ${market} Items found with ${selectors.item}: ${$(selectors.item).length}`);

        const results = [];

        $(selectors.item).slice(0, 8).each((i, el) => {
            let title = $(el).find(selectors.title).first().text().trim();
            let priceText = $(el).find(selectors.price).first().text().trim();
            let relLink = $(el).find(selectors.link).first().attr('href');

            // Fallbacks
            if (!title) title = $(el).find('h3').text().trim() || $(el).find('h2').text().trim();
            if (!priceText) priceText = $(el).find('.a-price .a-offscreen').first().text().trim() || $(el).find('.prc-box-dscntd').text().trim();
            if (!relLink) relLink = $(el).find('a').first().attr('href');

            if (relLink && priceText) {
                let fullLink = relLink;
                if (!relLink.startsWith('http')) {
                    if (market === "amazon") fullLink = "https://www.amazon.com.tr" + relLink;
                    else if (market === "trendyol") fullLink = "https://www.trendyol.com" + relLink;
                    else if (market === "hepsiburada") fullLink = "https://www.hepsiburada.com" + relLink;
                }

                results.push({
                    market,
                    title: title || "Ürün",
                    price: parsePrice(priceText),
                    url: fullLink
                });
            } else {
                // log only first 3 failures
                if (i < 3) console.log(`[DEBUG] ${market} Item ${i} missing data: link=${!!relLink}, price=${!!priceText}`);
            }
        });

        console.log(`[DEBUG] ${market} Final results: ${results.length}`);
        return results;
    } catch (error) {
        console.error(`Search error on ${market}:`, error.message);
        return [];
    } finally {
        if (browser) await browser.close();
    }
}

function parsePrice(text) {
    if (!text) return 0;
    const clean = text.replace(/[^\d,]/g, '').replace(',', '.');
    return parseFloat(clean) || 0;
}

async function findAlternatives(title, excludeMarket) {
    const markets = ["trendyol", "amazon", "hepsiburada"].filter(m => m !== excludeMarket);
    const allResults = [];

    // Run in parallel
    const searches = markets.map(m => searchMarket(m, title));
    const rawResults = await Promise.all(searches);

    rawResults.forEach(res => allResults.push(...res));

    // Sort by price
    return allResults.sort((a, b) => a.price - b.price);
}

module.exports = { findAlternatives };
