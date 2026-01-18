const puppeteer = require('puppeteer');

async function debugSelectors() {
    // A known stable Zara product URL (found via search strategy ideally, but direct link is easier for selector debugging)
    // We'll use the search strategy to be consistent with the app flow
    const productId = "06318294"; // From user log
    const url = `https://www.zara.com/tr/tr/search?searchTerm=${productId}`;

    console.log(`Debugging URL: ${url}`);

    const browser = await puppeteer.launch({
        headless: false,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();

    // Desktop UA
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    // Cookie injection
    await page.setCookie(
        { name: 'countryCode', value: 'TR', domain: '.zara.com' },
        { name: 'languageCode', value: 'tr', domain: '.zara.com' }
    );

    try {
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });

        // Wait for search result and click
        try {
            const searchResultSelector = '.product-grid-product-info a, .product-link, li.product a';
            await page.waitForSelector(searchResultSelector, { timeout: 10000 });
            const firstProduct = await page.$(searchResultSelector);
            if (firstProduct) {
                await Promise.all([
                    page.waitForNavigation({ waitUntil: 'domcontentloaded' }),
                    firstProduct.click()
                ]);
                console.log(`Navigated to Product: ${page.url()}`);
            }
        } catch (e) {
            console.log("Search navigation failed or already on product page.");
        }

        // Wait for render
        await new Promise(r => setTimeout(r, 3000));

        // INSPECT DOM
        const data = await page.evaluate(() => {
            const h1 = document.querySelector('h1')?.innerText;
            const h1Classes = document.querySelector('h1')?.className;

            const metaTitle = document.querySelector('meta[property="og:title"]')?.content;
            const metaImage = document.querySelector('meta[property="og:image"]')?.content;

            // Try known zara selectors
            const productTitleClass = document.querySelector('.product-detail-info__header-name')?.innerText;
            const productName = document.querySelector('.product-name')?.innerText;

            // Images
            const firstImage = document.querySelector('img')?.src;
            const mediaImage = document.querySelector('.media-image__image')?.src;
            const pdpImage = document.querySelector('.product-detail-images__image')?.src;

            // JSON-LD
            const jsonLd = Array.from(document.querySelectorAll('script[type="application/ld+json"]')).map(s => s.innerText);

            return {
                h1, h1Classes, metaTitle, metaImage, productTitleClass, productName, firstImage, mediaImage, pdpImage, jsonLdCount: jsonLd.length
            };
        });

        console.log("--- DEBUG DATA ---");
        console.log(JSON.stringify(data, null, 2));

    } catch (e) {
        console.error("Error:", e);
    } finally {
        await browser.close();
    }
}

debugSelectors();
