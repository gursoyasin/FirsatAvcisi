const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
puppeteer.use(StealthPlugin());

const lookupBarcode = async (barcode) => {
    // Real Implementation: Search Google/Bing for the barcode
    // This is "Ultra" level - we scrape the search engine result to find a valid link!
    // This is "Ultra" level - we scrape the search engine result to find a valid link!
    console.log(`🔍 Searching Web for Barcode: ${barcode}`);

    let browser = null;
    try {
        browser = await puppeteer.launch({
            headless: true,
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });
        const page = await browser.newPage();

        // Search Google for "barcode [CODE] satın al"
        await page.goto(`https://www.google.com/search?q=${barcode}+satın+al`, { waitUntil: 'domcontentloaded' });

        // Extract the first organic result link that is a shopping site
        const links = await page.evaluate(() => {
            const anchors = Array.from(document.querySelectorAll('a'));
            return anchors
                .map(a => a.href)
                .filter(href => href && href.startsWith('http') && !href.includes('google.com'));
        });

        // Filter for known marketplaces
        const knownSources = ['trendyol', 'hepsiburada', 'amazon', 'zara', 'bershka', 'boyner', 'dr.com.tr'];
        const bestLink = links.find(link => knownSources.some(source => link.includes(source)));

        if (bestLink) {
            console.log(`✅ Found Product Link: ${bestLink}`);
            return {
                title: "REDIRECT_REQUIRED", // Frontend/Backend will interpret this to scrape the found URL
                url: bestLink
            };
        }

        throw new Error("No valid shopping link found");

    } catch (error) {
        console.error("Barcode Lookup Failed:", error);
        throw error;
    } finally {
        if (browser) await browser.close();
    }
};

module.exports = { lookupBarcode };
