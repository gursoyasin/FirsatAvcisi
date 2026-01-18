const browserService = require('./scraper/BrowserService');
const cheerio = require('cheerio');
const prisma = require('../config/db');

// URLs for "Special Prices" / "Sale" sections
const TARGETS = [
    // BERSHKA (Expanded)
    { source: "bershka", url: "https://www.bershka.com/tr/kadin/koleksiyon/promosyon-%3D40-c1010193213.html", gender: "woman" },
    { source: "bershka", url: "https://www.bershka.com/tr/kadin/koleksiyon/d%C4%B1%C5%9F-giyim-c1010193222.html", gender: "woman" }, // Coats
    { source: "bershka", url: "https://www.bershka.com/tr/kadin/ayakkab%C4%B1-c1010193192.html", gender: "woman" }, // Shoes
    { source: "bershka", url: "https://www.bershka.com/tr/erkek/koleksiyon/promosyon-%3D40-c1010193138.html", gender: "man" },

    // STRADIVARIUS (Expanded)
    { source: "stradivarius", url: "https://www.stradivarius.com/tr/kadin/kategori/ozel-fiyatlar-n1899", gender: "woman" },
    { source: "stradivarius", url: "https://www.stradivarius.com/tr/kadin/kategori/kaban-n1644", gender: "woman" }, // Coats
    { source: "stradivarius", url: "https://www.stradivarius.com/tr/kadin/kategori/ayakkabi-n1465", gender: "woman" }, // Shoes

    // PULL&BEAR (Expanded)
    { source: "pullandbear", url: "https://www.pullandbear.com/tr/kadin-promosyon-n6548", gender: "woman" },
    { source: "pullandbear", url: "https://www.pullandbear.com/tr/kadin/indirim/mont-ve-ceketler-c1030230006.html", gender: "woman" }, // Coats Promo
    { source: "pullandbear", url: "https://www.pullandbear.com/tr/kadin/giyim/ayakkabi-c1030204642.html", gender: "woman" }, // Shoes
    { source: "pullandbear", url: "https://www.pullandbear.com/tr/erkek-promosyon-n6398", gender: "man" },

    // OYSHO (New)
    { source: "oysho", url: "https://www.oysho.com/tr/kadin/spors/indirim-c1010327508.html", gender: "woman" },

    // MASSIMO DUTTI (New)
    { source: "massimodutti", url: "https://www.massimodutti.com/tr/kadin/ozel-fiyatlar-n2642", gender: "woman" },

    // ZARA (Moved to end due to high latency/bot protection)
    { source: "zara", url: "https://www.zara.com/tr/tr/s-kadin-l8631.html", gender: "woman" },
    { source: "zara", url: "https://www.zara.com/tr/tr/kadin-dis-giyim-l1184.html?v1=2418848", gender: "woman" },
    { source: "zara", url: "https://www.zara.com/tr/tr/kadin-ayakkabi-l1251.html?v1=2418960", gender: "woman" },
    { source: "zara", url: "https://www.zara.com/tr/tr/erkek-ceket-l629.html?v1=2420803", gender: "man" }
];

async function mineInditex() {
    console.log("🏭 Inditex Miner Started...");

    for (const target of TARGETS) {
        try {
            console.log(`⛏️ Mining: ${target.source.toUpperCase()} (${target.gender})`);
            await mineCategory(target);
        } catch (error) {
            console.error(`❌ Failed to mine ${target.source}:`, error.message);
        }
    }

    console.log("✅ Inditex Mining Completed.");
}

async function mineCategory(target) {
    let page;
    try {
        page = await browserService.createPage();

        // 1. Headers & Cookies (Copied from scraper/index.js logic)
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        // Helper to inject cookies
        const domain = target.url.match(/https?:\/\/(?:www\.)?([^\/]+)/)[1];
        const rootDomain = '.' + domain.split('.').slice(-2).join('.');

        await page.setCookie(
            { name: 'countryCode', value: 'TR', domain: rootDomain },
            { name: 'languageCode', value: 'tr', domain: rootDomain },
            { name: 'storeId', value: '11728', domain: rootDomain } // Use generic or previously found ID
        );

        // 2. Navigation
        await page.goto(target.url, { waitUntil: 'domcontentloaded', timeout: 60000 });

        // 3. Scroll to load lazy content (MASS LOAD)
        console.log("Waiting 5s for initial load...");
        await new Promise(r => setTimeout(r, 5000));

        console.log("🔄 Starting mass scroll for more products...");
        for (let s = 0; s < 3; s++) { // Reduced to 3 for stability on Free Tier
            await autoScroll(page);
            console.log(`Scrolling... (${s + 1}/3)`);
            await new Promise(r => setTimeout(r, 2000));
        }

        // 4. Parse content using Browser Evaluation (Access Shadow DOM & Standard DOM)
        const products = await page.evaluate((source) => {
            const items = [];

            // Universal Selectors for Inditex Brands
            // Zara: .product-grid-product, li.product-grid-product
            // Bershka: .category-product-card, .grid-card
            // P&B: legacy-product, .c-tile--product
            // Stradivarius: .product-item
            const productSelector = '.category-product-card, .grid-card, .product-grid-product, li.product-grid-product, legacy-product, .c-tile--product, article.product, .product-item';

            const elements = document.querySelectorAll(productSelector);

            elements.forEach(el => {
                try {
                    // TITLE
                    let title = "";
                    const titleEl = el.querySelector('.product-text, .product-description, .product-grid-product-info__name, .product-name, .product-item__name');
                    if (titleEl) title = titleEl.innerText.trim();

                    // URL
                    let url = "";
                    let linkEl = el.matches('a') ? el : el.querySelector('a');
                    // Zara specific: link might be different
                    if (!linkEl) linkEl = el.querySelector('.product-link');

                    if (linkEl) {
                        url = linkEl.href;
                        // Handle relative URLs if any (though .href usually returns absolute)
                        if (url && !url.startsWith('http')) {
                            url = window.location.origin + (url.startsWith('/') ? '' : '/') + url;
                        }
                    }

                    // PRICE (Shadow DOM Handling & Fallbacks)
                    let priceText = "";
                    let originalPriceText = "";

                    if (targetSource === 'zara') {
                        // Zara Specific Price Extraction
                        const currentPriceElem = el.querySelector('.price__amount--current, .price-current__amount');
                        const oldPriceElem = el.querySelector('.price__amount--old, .price-old__amount, .price__amount--strikethrough');

                        if (currentPriceElem) priceText = currentPriceElem.innerText.trim();
                        if (oldPriceElem) originalPriceText = oldPriceElem.innerText.trim();
                    } else {
                        // A. Try generic price selectors first (Light DOM)
                        const priceEl = el.querySelector('.current-price-elem, .price-current, .price-current__amount, .product-item__price--current, .product-price-current');
                        const oldPriceEl = el.querySelector('.old-price-elem, .price-old, .price-old__amount, .product-item__price--old, .product-price-old');

                        if (priceEl) priceText = priceEl.innerText.trim();
                        if (oldPriceEl) originalPriceText = oldPriceEl.innerText.trim();
                    }

                    // B. Try Shadow DOM <price-element> (Common in P&B, Stradivarius)
                    if (!priceText) {
                        const shadowPrice = el.querySelector('price-element');
                        if (shadowPrice) {
                            if (shadowPrice.shadowRoot) {
                                priceText = shadowPrice.shadowRoot.textContent.trim();
                            } else {
                                priceText = shadowPrice.innerText.trim();
                            }
                        }
                    }

                    // C. Fallback: Regex on container text if still empty
                    if (!priceText) {
                        const raw = el.innerText || "";
                        const match = raw.match(/(\d{1,3}(?:[.,]\d{3})*)\s*TL/);
                        if (match) priceText = match[0];
                    }

                    // IMAGE
                    let img = "";
                    const imgEl = el.querySelector('img');
                    if (imgEl) {
                        img = imgEl.getAttribute('data-original') || imgEl.getAttribute('src') || imgEl.getAttribute('data-src');
                    }

                    if (url && (title || priceText)) {
                        items.push({
                            title: title || "Fırsat Ürünü",
                            url: url,
                            priceRaw: priceText, // Backend will parse
                            originalPriceRaw: originalPriceText,
                            imageUrl: img || "",
                            source: source,
                            category: 'moda'
                        });
                    }
                } catch (e) { }
            });

            return items;
        }, target.source);

        console.log(`✨ Found ${products.length} products for ${target.source}. Saving...`);

        // 5. Save / Upsert to DB
        let savedCount = 0;
        for (const p of products) {
            const price = parsePrice(p.priceRaw);
            const originalPrice = parsePrice(p.originalPriceRaw);

            // Skip invalid prices
            if (price <= 0) continue;

            // Derive detailed category from title
            const detailedCategory = deriveCategory(p.title);

            const productData = {
                url: p.url,
                title: p.title,
                currentPrice: price,
                originalPrice: originalPrice > 0 ? originalPrice : null,
                imageUrl: p.imageUrl,
                source: p.source,
                isSystem: true,
                category: detailedCategory, // Use derived category
                userEmail: "inditex_bot",
                inStock: true
            };

            const existing = await prisma.product.findFirst({ where: { url: p.url } });

            if (existing) {
                await prisma.product.update({
                    where: { id: existing.id },
                    data: {
                        currentPrice: price,
                        updatedAt: new Date(),
                        originalPrice: productData.originalPrice || existing.originalPrice,
                        isSystem: true,
                        inStock: true,
                        category: detailedCategory // Update category if it improved
                    }
                });
            } else {
                await prisma.product.create({ data: { ...productData, views: 0 } });
                savedCount++;
            }
        }

        console.log(`💾 Saved ${savedCount} new products for ${target.source}.`);

    } catch (e) {
        console.error(`Error mining ${target.url}:`, e);
    } finally {
        if (page) await page.close();
    }
}

// Helper: Auto Scroll
async function autoScroll(page) {
    await page.evaluate(async () => {
        await new Promise((resolve) => {
            let totalHeight = 0;
            const distance = 100;
            const timer = setInterval(() => {
                const scrollHeight = document.body.scrollHeight;
                window.scrollBy(0, distance);
                totalHeight += distance;

                if (totalHeight >= scrollHeight - window.innerHeight || totalHeight > 5000) { // Limit scroll
                    clearInterval(timer);
                    resolve();
                }
            }, 100);
        });
    });
}

function parsePrice(text) {
    if (!text) return 0;

    // Clean weird characters but keep digits, dots, commas
    let clean = text.replace(/[^\d.,]/g, '').trim();

    // Check format: Turkish/European (1.299,90) vs US (1,299.90)
    // Heuristic: If last punctuation is ',', it's decimal. If last is '.', it's decimal (US).

    const lastComma = clean.lastIndexOf(',');
    const lastDot = clean.lastIndexOf('.');

    if (lastComma > lastDot) {
        // Turkish/Euro format: 1.299,90 -> Remove dots, replace comma with dot
        clean = clean.replace(/\./g, '').replace(',', '.');
    } else if (lastDot > lastComma) {
        // US format: 1,299.90 -> Remove commas
        clean = clean.replace(/,/g, '');
    }

    return parseFloat(clean) || 0;
}

// Helper: Derive Category from Title (Turkish)
function deriveCategory(title) {
    if (!title) return 'Moda';
    const lower = title.toLowerCase();

    if (lower.includes('elbise')) return 'Elbise';
    if (lower.includes('ceket') || lower.includes('blazer')) return 'Ceket';
    if (lower.includes('tişört') || lower.includes('t-shirt') || lower.includes('top')) return 'Tişört';
    if (lower.includes('pantolon') || lower.includes('jean') || lower.includes('tayt')) return 'Pantolon';
    if (lower.includes('kaban') || lower.includes('mont') || lower.includes('pardesü') || lower.includes('trench')) return 'Dış Giyim';
    if (lower.includes('kazak') || lower.includes('hırka') || lower.includes('triko')) return 'Kazak';
    if (lower.includes('gömlek') || lower.includes('bluz')) return 'Gömlek';
    if (lower.includes('şapka') || lower.includes('bere')) return 'Şapka';
    if (lower.includes('ayakkabı') || lower.includes('bot') || lower.includes('çizme') || lower.includes('sneaker')) return 'Ayakkabı';
    if (lower.includes('çanta') || lower.includes('cüzdan')) return 'Çanta';
    if (lower.includes('sweatshirt') || lower.includes('hoodie')) return 'Sweatshirt';
    if (lower.includes('etek') || lower.includes('şort')) return 'Etek/Şort';

    return 'Moda'; // Fallback
}

module.exports = { mineInditex };
