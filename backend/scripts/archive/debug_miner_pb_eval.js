const browserService = require('./src/services/scraper/BrowserService');

async function debugPB() {
    console.log("🐛 Debugging Pull&Bear (Eval Mode)...");
    const url = "https://www.pullandbear.com/tr/kadin-promosyon-n6548";
    const page = await browserService.createPage();

    try {
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });

        console.log("Waiting 5s...");
        await new Promise(r => setTimeout(r, 5000));

        // Extract using Browser Context
        const data = await page.evaluate(() => {
            const items = [];
            const elements = document.querySelectorAll('div.c-tile--product, legacy-product');

            // Debug: Check Global Objects
            const globalKeys = Object.keys(window).filter(k => k.includes('INDITEX') || k.includes('ITX') || k.includes('STATE'));
            console.log("Global Keys:", globalKeys);

            elements.forEach(el => {
                const titleEl = el.querySelector('.product-name');
                const priceEl = el.querySelector('price-element');
                const linkEl = el.querySelector('a');

                let priceText = "";

                // 1. Try Shadow Root
                if (priceEl && priceEl.shadowRoot) {
                    priceText = priceEl.shadowRoot.textContent;
                } else if (priceEl) {
                    // 2. Try to find a custom property or internal state
                    priceText = priceEl.innerText || priceEl.textContent;
                }

                // 3. Fallback: Search for any price-like text in the entire tile
                if (!priceText) {
                    const raw = el.innerText;
                    const match = raw.match(/(\d{1,3}(?:[.,]\d{3})*)\s*TL/);
                    if (match) priceText = match[0];
                }

                if (titleEl && linkEl) {
                    items.push({
                        title: titleEl.innerText,
                        price: priceText,
                        shadow: priceEl ? !!priceEl.shadowRoot : false,
                        url: linkEl.href
                    });
                }
            });
            return { items, globalKeys };
        });

        console.log(`Globals: ${JSON.stringify(data.globalKeys)}`);
        console.log(`Found ${data.items.length} items.`);
        console.log(data.items.slice(0, 5));

    } catch (e) {
        console.error(e);
    } finally {
        await page.close();
        process.exit(0);
    }
}

debugPB();
