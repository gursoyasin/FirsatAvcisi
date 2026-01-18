
const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
puppeteer.use(StealthPlugin());

async function run() {
    const browser = await puppeteer.launch({
        headless: "new",
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    });
    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    // Inject cookies to avoid region selector
    await page.setCookie(
        { name: 'countryCode', value: 'TR', domain: '.zara.com' },
        { name: 'languageCode', value: 'tr', domain: '.zara.com' }
    );

    console.log("Navigating to Zara Search...");
    await page.goto("https://www.zara.com/tr/tr/search?searchTerm=elbise", { waitUntil: 'domcontentloaded' });

    // Wait for grid
    try {
        await page.waitForSelector('ul, div.product-grid', { timeout: 10000 });
    } catch (e) { console.log("Wait timeout"); }

    const content = await page.content();
    console.log("Page Title:", await page.title());

    // Analyze Grid Classes
    const classes = await page.evaluate(() => {
        const potential = document.querySelectorAll('li, div, a');
        const list = [];
        potential.forEach(el => {
            if (el.className && typeof el.className === 'string' &&
                (el.className.includes('product') || el.className.includes('card') || el.className.includes('grid'))) {
                list.push(el.className);
            }
        });
        return [...new Set(list)].slice(0, 50); // Get top 50 unique classes
    });

    console.log("Found Classes:", classes);

    await browser.close();
}

run();
