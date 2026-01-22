const prisma = require('../config/db');
const { detectGender } = require('./scraper/index');
const browserService = require('./scraper/BrowserService');
console.log(`🔍 InditexMiner: browserService type = ${typeof browserService}`);

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
    { source: "oysho", url: "https://www.oysho.com/tr/kadin/pijama-c1010214502.html", gender: "woman" }, // Backup Category

    // MASSIMO DUTTI (New)
    { source: "massimodutti", url: "https://www.massimodutti.com/tr/kadin/ozel-fiyatlar-n2642", gender: "woman" },
    { source: "massimodutti", url: "https://www.massimodutti.com/tr/kadin/giyim/elbise-n1545", gender: "woman" }, // Backup Category

    // ZARA (Moved to end due to high latency/bot protection)
    { source: "zara", url: "https://www.zara.com/tr/tr/s-kadin-l8631.html", gender: "woman" },
    { source: "zara", url: "https://www.zara.com/tr/tr/kadin-dis-giyim-l1184.html?v1=2418848", gender: "woman" },
    { source: "zara", url: "https://www.zara.com/tr/tr/kadin-ayakkabi-l1251.html?v1=2418960", gender: "woman" },
    { source: "zara", url: "https://www.zara.com/tr/tr/erkek-ceket-l629.html?v1=2420803", gender: "man" }
];

async function mineInditex(targetFilter = []) {
    console.log("🏭 Inditex Miner Started...");

    // Filter targets if provided
    const activeTargets = targetFilter.length > 0
        ? TARGETS.filter(t => targetFilter.includes(t.source))
        : TARGETS;

    for (const target of activeTargets) {
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
        console.log("⚡️⚡️ INDITEX MINER V3.1 (SKELETON FIX) LOADED ⚡️⚡️");

        // 1. Headers & Cookies (Copied from scraper/index.js logic)
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        // Helper to inject cookies
        const domain = target.url.match(/https?:\/\/(?:www\.)?([^\/]+)/)[1];
        const rootDomain = '.' + domain.split('.').slice(-2).join('.');

        // DEBUG: Relay browser console to node console
        page.on('console', msg => console.log('🌐 BROWSER LOG:', msg.text()));

        await page.setCookie(
            { name: 'countryCode', value: 'TR', domain: rootDomain },
            { name: 'languageCode', value: 'tr', domain: rootDomain },
            { name: 'storeId', value: '11728', domain: rootDomain } // Use generic or previously found ID
        );

        // 2. Navigation
        await page.goto(target.url, { waitUntil: 'domcontentloaded', timeout: 60000 });

        const pageTitle = await page.title();
        console.log(`📄 Page Title: ${pageTitle}`);

        // 3. Scroll to load lazy content (MASS LOAD)
        console.log("Waiting 3s for initial DOM...");

        // Wait for real content to appear (Inditex specific: price element usually means hydration is done)
        try {
            await page.waitForSelector('.product-grid-product, .grid-card, .price-elem, .product-price, .product-item', { timeout: 10000 });
            console.log("✅ Grid content detected.");
        } catch (e) {
            console.log("⚠️ Timeout waiting for specific grid selector, proceeding anyway...");
        }

        console.log("🔄 Starting mass scroll for more products...");
        for (let s = 0; s < 3; s++) {
            await autoScroll(page);
            console.log(`Scrolling... (${s + 1}/3)`);
            await new Promise(r => setTimeout(r, 2000));
        }

        // 4. Parse content using Browser Evaluation (Access Shadow DOM & Standard DOM)
        const products = await page.evaluate((source) => {
            const items = [];

            // Universal Selectors for Inditex Brands
            // UPDATED: Exclude 'skeleton' logic
            const productSelector = '.grid-product, .product-card-figure, .category-product-card, .grid-card, .product-grid-product, li.product-grid-product:not(.skeleton-product-card), legacy-product, .c-tile--product, article.product, .product-item, a[class*="product-link"]';

            let elements = Array.from(document.querySelectorAll(productSelector));

            // Filter out skeletons or loading states aggressively
            elements = elements.filter(el => {
                const cls = el.className || "";
                return !cls.includes('skeleton') && !cls.includes('loading') && !cls.includes('placeholder');
            });

            console.log(`🔎 Found ${elements.length} primary elements (after skeleton filtering).`);

            // FALLBACK: If specific selectors fail, try generic "Link > Image" pattern
            if (elements.length === 0) {
                console.log("⚠️ No products found with primary selectors. Trying fallback 'a > img'...");
                // Look for anchors that contain an image and have a link that looks like a product
                const potentialLinks = Array.from(document.querySelectorAll('a')).filter(a => {
                    return (a.href.includes('-c') || a.href.includes('-p') || a.href.includes('/p/') || a.href.includes('.html')) && a.querySelector('img');
                });
                elements = potentialLinks;
                console.log(`🔎 Found ${elements.length} fallback elements via Link+Image heuristic.`);
            }

            elements.forEach((el, index) => {
                try {
                    // TITLE
                    let title = "";
                    // Try to find any text inside that is not a price
                    const titleEl = el.querySelector('.product-text, .product-description, .product-grid-product-info__name, .product-name, .product-item__name, h2, h3, .name, .description');
                    if (titleEl) title = titleEl.innerText.trim();
                    if (!title) title = el.innerText.split('\n')[0]; // Simple fallback

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

                    if (source === 'zara') {
                        // Zara Specific Price Extraction
                        const currentPriceElem = el.querySelector('.price__amount--current, .price-current__amount, .money-amount__main');
                        const oldPriceElem = el.querySelector('.price__amount--old, .price-old__amount, .price__amount--strikethrough, .money-amount__main--strikethrough');

                        if (currentPriceElem) priceText = currentPriceElem.innerText.trim();
                        if (oldPriceElem) originalPriceText = oldPriceElem.innerText.trim();

                        // Zara Specific Title Extraction
                        if (!title) {
                            const zaraTitle = el.querySelector('.product-grid-product-info__name, .product-item__name, .name');
                            if (zaraTitle) title = zaraTitle.innerText.trim();
                        }
                    } else {
                        // A. Try generic price selectors first (Light DOM)
                        const priceEl = el.querySelector('.current-price-elem, .price-current, .price-current__amount, .product-item__price--current, .product-price-current, .price__amount--current');
                        const oldPriceEl = el.querySelector('.old-price-elem, .price-old, .price-old__amount, .product-item__price--old, .product-price-old, .price__amount--old, .price__amount--strikethrough');

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

                    // IMAGE (ROBUST)
                    let img = "";
                    const selectors = [
                        '.media-image',
                        '.media-image__image', // Zara
                        '.product-detail-images__image', // Zara old
                        '.product-image img', // General
                        'img[itemprop="image"]',
                        '.main-image img',
                        'img.image-item', // Bershka/PB
                        'img[class*="product-image"]',
                        '.image-container img',
                        '.product-detail-main-image-container img', // H&M
                        '.product-image-gallery img',
                        '.product-images__image', // Mango
                        'img[data-testid="product-image"]'
                    ];

                    // Try selectors inside the element first
                    for (let s of selectors) {
                        const iEl = el.querySelector(s);
                        if (iEl) {
                            if (iEl.tagName === 'IMG') {
                                img = iEl.getAttribute('data-original') || iEl.getAttribute('src') || iEl.getAttribute('data-src');
                            } else {
                                const inner = iEl.querySelector('img');
                                if (inner) img = inner.getAttribute('data-original') || inner.getAttribute('src') || inner.getAttribute('data-src');
                            }
                            if (img) break;
                        }
                    }

                    // Fallback: Direct img tag
                    if (!img) {
                        const imgEl = el.querySelector('img');
                        if (imgEl) {
                            img = imgEl.getAttribute('data-original') || imgEl.getAttribute('src') || imgEl.getAttribute('data-src');
                        }
                    }

                    // Downgrade quality hack (optional, to avoid huge downloads if needed, but we want high res)
                    if (img && img.includes('?')) {
                        // Keep query params mostly, maybe adjust width if supported
                    }

                    console.log(`🔎 Item ${index}: Title="${title}", Price="${priceText}", URL="${url}"`);

                    const junkTitles = ["ana içeriğe atla", "skip to main content", "hesabım", "sepetim", "yardım", "keşfet", "menü"];
                    const isJunk = junkTitles.some(jt => (title || "").toLowerCase().includes(jt));

                    // Improved URL check for products (ID usually follows p)
                    const isProductUrl = url && (url.includes('-p') || url.includes('p/') || url.match(/[cp]\d+/i));

                    if (url && (title || priceText) && !isJunk && isProductUrl) {
                        // STRICT IMAGE CHECK
                        if (!img || img.trim() === "") {
                            console.log(`⚠️ Skipping Item ${index}: Missing Image. URL: ${url}`);
                            return;
                        }

                        items.push({
                            title: title || "Fırsat Ürünü",
                            url: url,
                            priceRaw: priceText, // Backend will parse
                            originalPriceRaw: originalPriceText,
                            imageUrl: img,
                            source: source,
                            category: 'moda'
                        });
                    } else {
                        console.log(`⚠️ Skipping Item ${index}: Missing Title/Price/URL. HTML Preview: ${el.outerHTML ? el.outerHTML.substring(0, 150) : 'N/A'}...`);
                    }
                } catch (e) { console.log(`❌ Error processing item ${index}:`, e.message); }
            });

            return items;
        }, target.source);

        console.log(`✨ Found ${products.length} products for ${target.source}. Saving...`);

        // DEBUG: If 0 products, snapshot the HTML to see what's wrong
        if (products.length === 0) {
            const bodyPreview = await page.evaluate(() => {
                return document.body.innerText.substring(0, 1000).replace(/\n/g, ' ') + ' || HTML: ' + document.body.innerHTML.substring(0, 500);
            });
            console.log(`⚠️ ZERO PRODUCTS DEBUG (Snapshot): ${bodyPreview}`);
        }


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
                category: detailedCategory,
                gender: detectGender(p.url, p.title),
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
                        category: detailedCategory,
                        gender: productData.gender,
                        history: { create: { price: price } }
                    }
                });
            } else {
                await prisma.product.create({ data: { ...productData, views: 0, history: { create: { price: price } } } });
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
