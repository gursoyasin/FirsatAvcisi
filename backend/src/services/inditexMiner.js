const prisma = require('../config/db');
const { detectGender } = require('./scraper/index');
const browserService = require('./scraper/BrowserService');
const logger = require('../utils/logger');
const healthService = require('./monitor/HealthService');
const pLimit = require('p-limit');

console.log(`🔍 InditexMiner: browserService type = ${typeof browserService}`);

// URLs for "Special Prices" / "Sale" sections
const TARGETS = [
    // BERSHKA
    { source: "bershka", url: "https://www.bershka.com/tr/kadin/giyim/yeni-c1010193218.html", gender: "woman" },
    { source: "bershka", url: "https://www.bershka.com/tr/erkek/giyim/yeni-c1010193245.html", gender: "man" },

    // STRADIVARIUS
    { source: "stradivarius", url: "https://www.stradivarius.com/tr/kadin/yeni-koleksiyon/giyim-n1923", gender: "woman" },
    { source: "stradivarius", url: "https://www.stradivarius.com/tr/kadin/akilli-fiyatlar/giyim-n1899", gender: "woman" },

    // PULL&BEAR
    { source: "pullandbear", url: "https://www.pullandbear.com/tr/kadin/giyim/cok-satanlar-n6638", gender: "woman" },
    { source: "pullandbear", url: "https://www.pullandbear.com/tr/erkek/giyim/cok-satanlar-n6612", gender: "man" },

    // OYSHO
    { source: "oysho", url: "https://www.oysho.com/tr/kadin/kategori/cok-satanlar-n1576", gender: "woman" },

    // MASSIMO DUTTI
    { source: "massimodutti", url: "https://www.massimodutti.com/tr/kadin/giyim/yeni-gelenler-n1951", gender: "woman" },

    // ZARA
    { source: "zara", url: "https://www.zara.com/tr/tr/kadin-yeni-gelenler-l1180.html", gender: "woman" },
    { source: "zara", url: "https://www.zara.com/tr/tr/erkek-yeni-gelenler-l616.html", gender: "man" }
];

async function mineInditex(targetFilter = []) {
    console.log("🏭 Inditex Miner Started (Performance V3 - Parallel)...");

    const activeTargets = targetFilter.length > 0
        ? TARGETS.filter(t => targetFilter.includes(t.source))
        : TARGETS;

    // 🔥 1. CONTROLLED PARALLELISM
    const limit = pLimit(2); // Max 2 browsers at the same time to save RAM

    await Promise.all(activeTargets.map(target =>
        limit(() => mineCategory(target))
    ));

    console.log("✅ Inditex Mining Completed.");
}

async function mineCategory(target) {
    try {
        console.log(`⛏️ Mining: ${target.source.toUpperCase()} (${target.gender})`);

        // 🔥 4. SCRAPE vs SAVE SEPARATION
        // Phase A: Scrape Data
        const products = await scrapeCategoryPage(target);

        if (products.length > 0) {
            // Phase B: Save Data (Bullk / Efficient)
            await saveProductsToDB(products, target);
        } else {
            console.log(`⚠️ No products found for ${target.source}. Skipping save.`);
        }

    } catch (error) {
        console.error(`❌ Failed to mine ${target.source}:`, error.message);
        healthService.reportFailure(); // Health Log
        logger.notifyDiscord(`⚠️ **Inditex Miner Error**: Failed to mine ${target.source}. Error: ${error.message}`);
    }
}

async function scrapeCategoryPage(target) {
    let page;
    try {
        page = await browserService.createPage();

        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36');

        const domain = target.url.match(/https?:\/\/(?:www\.)?([^\/]+)/)[1];
        const rootDomain = '.' + domain.split('.').slice(-2).join('.');

        await page.setRequestInterception(true);
        page.on('request', (req) => {
            if (['image', 'media', 'font'].includes(req.resourceType())) req.abort();
            else req.continue();
        });

        await page.setCookie(
            { name: 'countryCode', value: 'TR', domain: rootDomain },
            { name: 'languageCode', value: 'tr', domain: rootDomain },
            { name: 'storeId', value: '11728', domain: rootDomain }
        );

        await page.goto(target.url, { waitUntil: 'domcontentloaded', timeout: 60000 });

        // 🔥 3. SMART SCROLL
        console.log("🔄 Smart scrolling...");
        await smartScroll(page);

        // Parse content (Beast Mode Logic)
        const products = await page.evaluate((source) => {
            const items = [];

            // Helper: Clean Price
            const parsePriceRaw = (text) => { // Kept for browser context if needed, but we do parsing in Node
                return text;
            };

            const productSelector = '.grid-product, .product-card-figure, .grid-card, .product-grid-product, li.product-grid-product:not(.skeleton-product-card), .product-item';
            let elements = Array.from(document.querySelectorAll(productSelector));

            if (elements.length === 0) {
                elements = Array.from(document.querySelectorAll('a')).filter(a => {
                    return (a.href.includes('-p') || a.href.includes('/p/') || a.href.includes('.html')) && a.querySelector('img');
                });
            }

            elements.forEach((el, index) => {
                try {
                    let title = "";
                    const titleEl = el.querySelector('.product-text, .product-description, .product-grid-product-info__name, .product-name, .product-item__name, h2, h3, .name');
                    if (titleEl) title = titleEl.innerText.trim();
                    if (!title) title = el.getAttribute('aria-label');
                    if (!title) title = el.innerText.split('\n')[0];

                    let url = "";
                    let linkEl = el.matches('a') ? el : el.querySelector('a');
                    if (!linkEl) linkEl = el.querySelector('.product-link');
                    if (linkEl) url = linkEl.href;

                    let priceText = "";
                    let originalPriceText = "";

                    const shadowPrice = el.querySelector('price-element');
                    if (shadowPrice && shadowPrice.shadowRoot) {
                        priceText = shadowPrice.shadowRoot.textContent.trim();
                    }

                    if (!priceText) {
                        const pEl = el.querySelector('.current-price-elem, .price-current, .price__amount--current, .product-price');
                        if (pEl) priceText = pEl.innerText.trim();
                    }

                    let img = "";
                    const imgEl = el.querySelector('img');
                    if (imgEl) {
                        if (imgEl.srcset) {
                            const sources = imgEl.srcset.split(',').map(s => s.trim().split(' '));
                            const best = sources[sources.length - 1][0];
                            if (best) img = best;
                        }
                        if (!img) img = imgEl.getAttribute('data-original') || imgEl.getAttribute('data-src') || imgEl.src;
                    }

                    if (url && (title || priceText)) {
                        if (title && (title.includes("Menü") || title.includes("Sepet"))) return;

                        if (url && !url.startsWith('http')) {
                            url = window.location.origin + (url.startsWith('/') ? '' : '/') + url;
                        }

                        items.push({
                            title: title || "Fırsat Ürünü",
                            url: url,
                            priceRaw: priceText,
                            originalPriceRaw: originalPriceText,
                            imageUrl: img,
                            source: source
                        });
                    }
                } catch (e) { }
            });
            return items;
        }, target.source);

        console.log(`✨ Found ${products.length} products on ${target.source}.`);
        return products;

    } catch (e) {
        console.error(`Error scraping ${target.url}:`, e.message);
        return [];
    } finally {
        if (page) await page.close();
    }
}

async function saveProductsToDB(products, target) {
    if (products.length === 0) return;

    // 🔥 2. DB PRELOAD (Batch Optimization)
    // Avoid N+1 query. Fetch existing URLs once.
    const urls = products.map(p => p.url);

    // Fetch only necessary fields
    const existingProducts = await prisma.product.findMany({
        where: { url: { in: urls } },
        select: { id: true, url: true, originalPrice: true }
    });

    // Create a Map for O(1) lookup
    const existingMap = new Map();
    existingProducts.forEach(p => existingMap.set(p.url, p));

    let savedCount = 0;

    // Use transaction for better integrity if possible, or just sequential loop with map check
    for (const p of products) {
        const price = parsePrice(p.priceRaw);
        const originalPrice = parsePrice(p.originalPriceRaw);

        if (price <= 5) continue;
        if (!p.imageUrl || p.imageUrl.includes('base64') || p.imageUrl.length < 10) continue;

        const detailedCategory = deriveCategory(p.title);
        const existing = existingMap.get(p.url);

        if (existing) {
            // Update
            await prisma.product.update({
                where: { id: existing.id },
                data: {
                    currentPrice: price,
                    updatedAt: new Date(),
                    originalPrice: originalPrice > price ? originalPrice : existing.originalPrice,
                    imageUrl: p.imageUrl,
                    isSystem: true,
                    inStock: true
                }
            });
        } else {
            // Create
            await prisma.product.create({
                data: {
                    url: p.url,
                    title: p.title || "Ürün",
                    currentPrice: price,
                    originalPrice: originalPrice > price ? originalPrice : null,
                    imageUrl: p.imageUrl,
                    source: p.source,
                    isSystem: true,
                    category: detailedCategory,
                    gender: detectGender(p.url, p.title), // Detect gender here or pass from target
                    userEmail: "inditex_bot",
                    inStock: true,
                    views: 0,
                    history: { create: { price: price } }
                }
            });
            savedCount++;
        }
    }
    console.log(`💾 Saved/Updated ${savedCount} new items for ${target.source}.`);
    healthService.reportSuccess(savedCount);
}

// 🔥 3. SMART SCROLL IMPLEMENTATION
async function smartScroll(page) {
    await page.evaluate(async () => {
        await new Promise((resolve) => {
            let totalHeight = 0;
            const distance = 100;
            let noChangeCount = 0;
            let lastProductCount = 0;

            const countProducts = () => document.querySelectorAll('.grid-product, .product-card-figure, .grid-card, .product-grid-product, li.product-grid-product').length;

            const timer = setInterval(() => {
                const scrollHeight = document.body.scrollHeight;
                window.scrollBy(0, distance);
                totalHeight += distance;

                const currentCount = countProducts();

                if (currentCount === lastProductCount) {
                    noChangeCount++;
                } else {
                    noChangeCount = 0; // Reset if new products founded
                    lastProductCount = currentCount;
                }

                // Stop conditions:
                // 1. Reached bottom
                // 2. Limit reached (4000px)
                // 3. No new products for 20 scroll ticks (approx 2 sec)
                if (totalHeight >= scrollHeight - window.innerHeight || totalHeight > 20000 || noChangeCount > 30) {
                    clearInterval(timer);
                    resolve();
                }
            }, 100);
        });
    });
}

function parsePrice(text) {
    if (!text) return 0;
    let clean = text.replace(/[^\d.,]/g, '').trim();
    if (!clean) return 0;

    const lastPoint = clean.lastIndexOf('.');
    const lastComma = clean.lastIndexOf(',');

    if (lastPoint > lastComma) {
        clean = clean.replace(/,/g, '');
    } else {
        clean = clean.replace(/\./g, '').replace(',', '.');
    }

    const val = parseFloat(clean);
    return isNaN(val) ? 0 : val;
}

function deriveCategory(title) {
    if (!title) return 'Moda';
    const lower = title.toLowerCase();
    if (lower.includes('elbise')) return 'Elbise';
    if (lower.includes('ceket') || lower.includes('blazer')) return 'Ceket';
    if (lower.includes('pantolon') || lower.includes('jean')) return 'Pantolon';
    if (lower.includes('ayakkabı') || lower.includes('bot') || lower.includes('sneaker')) return 'Ayakkabı';
    if (lower.includes('çanta')) return 'Çanta';
    return 'Moda';
}

module.exports = { mineInditex };
