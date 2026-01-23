const prisma = require('../config/db');
const { detectGender } = require('./scraper/index');
const browserService = require('./scraper/BrowserService');
console.log(`🔍 DailyMiner: browserService type = ${typeof browserService}`);

// ==========================================
// 🎯 TARGET MAP (30+ BRANDS)
// ==========================================
// Definitive Brand List with specific URLs
const TARGETS = [
    // --- INDITEX ---
    { source: "zara", url: "https://www.zara.com/tr/tr/kadin-dis-giyim-l1184.html?v1=2418848", gender: "woman" },
    { source: "bershka", url: "https://www.bershka.com/tr/kadin/koleksiyon/promosyon-%3D40-c1010193213.html", gender: "woman" },
    { source: "pullandbear", url: "https://www.pullandbear.com/tr/kadin-promosyon-n6548", gender: "woman" },
    { source: "stradivarius", url: "https://www.stradivarius.com/tr/kadin/kategori/ozel-fiyatlar-n1899", gender: "woman" },
    { source: "massimodutti", url: "https://www.massimodutti.com/tr/kadin/ozel-fiyatlar-n2642", gender: "woman" },
    { source: "oysho", url: "https://www.oysho.com/tr/kadin/spors/indirim-c1010327508.html", gender: "woman" },
    { source: "zarahome", url: "https://www.zarahome.com/tr/indirim-n1321", gender: "home" },
    { source: "lefties", url: "https://www.lefties.com/tr/kadin/koleksiyon/indirim-c1030267524.html", gender: "woman" },

    // --- GLOBAL ---
    { source: "hm", url: "https://www2.hm.com/tr_tr/kadin/urune-gore-satin-al/indirim.html", gender: "woman" },
    { source: "mango", url: "https://shop.mango.com/tr/kadin/indirimler_d18712395", gender: "woman" },
    { source: "jackjones", url: "https://jackjones.com.tr/indirim", gender: "man" },

    // --- TR MASS MARKET ---
    { source: "lcwaikiki", url: "https://www.lcwaikiki.com/tr-TR/TR/etiket/indirim-kadin", gender: "woman" },
    { source: "defacto", url: "https://www.defacto.com.tr/kadin-indirim", gender: "woman" },
    { source: "koton", url: "https://www.koton.com/kadin-indirim-giyim/", gender: "woman" },
    { source: "colins", url: "https://www.colins.com.tr/c/indirimdekiler-1284?specs=74", gender: "woman" },
    { source: "mavi", url: "https://www.mavi.com/kadin/indirim/c/1", gender: "woman" },
    { source: "loft", url: "https://www.loft.com.tr/kadin-outlet", gender: "woman" },

    // --- TR PREMIUM / NETWORK GROUP ---
    { source: "twist", url: "https://www.twist.com.tr/koleksiyon/indirim", gender: "woman" },
    { source: "ipekyol", url: "https://www.ipekyol.com.tr/koleksiyon/indirim", gender: "woman" },
    { source: "network", url: "https://www.network.com.tr/kadin-indirim", gender: "woman" },
    { source: "fabrika", url: "https://www.boyner.com.tr/fabrika-kadin-giyim-c-3306001", gender: "woman" },
    { source: "boyner", url: "https://www.boyner.com.tr/kadin-giyim-c-1005", gender: "woman" }, // Generic fallback

    // --- LUXURY ---
    { source: "beymen", url: "https://www.beymen.com/tr/kadin-giyim-10005?siralama=akilli-siralama&fiyat=indirimli", gender: "woman" },
    { source: "beymen", url: "https://www.beymen.com/tr/erkek-giyim-10006?siralama=akilli-siralama&fiyat=indirimli", gender: "man" },
    { source: "beymen", url: "https://www.beymen.com/tr/kadin-canta-10007?siralama=akilli-siralama&fiyat=indirimli", gender: "woman" }, // Bags
    { source: "beymen", url: "https://www.beymen.com/tr/kadin-aksesuar-10008?siralama=akilli-siralama&fiyat=indirimli", gender: "woman" }, // Acc
    { source: "beymen", url: "https://www.beymen.com/tr/erkek-canta-10012?siralama=akilli-siralama&fiyat=indirimli", gender: "man" }, // Men Bags
    { source: "beymen", url: "https://www.beymen.com/tr/erkek-aksesuar-10013?siralama=akilli-siralama&fiyat=indirimli", gender: "man" }, // Men Acc
    { source: "beymenclub", url: "https://www.beymenclub.com/kadin-indirim", gender: "woman" },
    { source: "vakko", url: "https://www.vakko.com/kadin-giyim-c-10/indirimli-urunler", gender: "woman" },
    { source: "damattween", url: "https://www.damattween.com/indirim", gender: "man" },
    { source: "sarar", url: "https://shop.sarar.com/kadin-indirim", gender: "woman" },
    { source: "ramsey", url: "https://www.ramsey.com.tr/indirim", gender: "man" },

    // --- SPORTS ---
    { source: "nike", url: "https://www.nike.com/tr/w/indirim-3yaep", gender: "unisex" },
    { source: "adidas", url: "https://www.adidas.com.tr/tr/outlet", gender: "unisex" },
    { source: "puma", url: "https://tr.puma.com/indirim.html", gender: "unisex" },
    { source: "newbalance", url: "https://www.newbalance.com.tr/indirimli-urunler/", gender: "unisex" },
    { source: "underarmour", url: "https://www.underarmour.com.tr/tr/outlet/", gender: "unisex" },
    { source: "lesbenjamins", url: "https://lesbenjamins.com/collections/sale", gender: "unisex" }
];

async function mineAllBrands() {
    console.log("🚀 STARTING CHRONO MINER: Final V3.0");
    console.log(`🎯 Targets: ${TARGETS.length} URLs defined.`);

    const shuffled = TARGETS.sort(() => Math.random() - 0.5);

    for (const target of shuffled) {
        let attempts = 0;
        let success = false;
        while (attempts < 2 && !success) {
            try {
                attempts++;
                if (attempts > 1) console.log(`🔄 Retrying ${target.source.toUpperCase()} (Attempt ${attempts})...`);

                console.log(`⛏️ Mining: ${target.source.toUpperCase()}`);
                const count = await mineCategory(target);

                if (count > 0 || count === -1) success = true; // -1 means no error but maybe authentic 0 items

                if (!success) await new Promise(r => setTimeout(r, 5000)); // Wait before retry
            } catch (error) {
                console.error(`❌ Global Miner Error (${target.source}):`, error.message);
                if (attempts === 2) console.error(`💀 Gave up on ${target.source} after 2 attempts.`);
            }
        }
        await new Promise(r => setTimeout(r, 4000)); // Polite delay between brands
    }
    console.log("🏁 CHRONO MINER: Cycle Completed.");
}

async function mineCategory(target) {
    let page;
    try {
        page = await browserService.createPage();

        // --- 1. CONFIGURATION INJECTION ---
        // We pass this into the browser context so the evaluator knows exactly what to look for
        const MINER_CONFIGS = {
            // Inditex (Zara requires .product-grid-product, but sometimes it is just li)
            'zara': { container: '.product-grid-product, li.product-item, .product-item, .product-grid-item, .product-grid-product-info', price: ['.price__amount--current', '.price-current__amount', '.money-amount__main', '.price-current'] },
            'bershka': { container: 'div[data-id], .product-card, .grid-card, .product-item, .grid-product, .category-product-card', price: ['.current-price-elem', '.product-price', '.price-current', '.price-elem'] },
            'pullandbear': { container: '.product-card, div.grid-product, div[data-id], .product-item, .grid-product-info', price: ['.price-current', '.product-price', '.current-price', '.price-elem'] },
            'stradivarius': { container: '.product-item, div[name="product-item"], .grid-product', price: ['.price-current', '.product-price', '.price-elem'] },
            'massimodutti': { container: '.product-item, .product-card, .grid-product', price: ['.product-price', '.price-current', '.price-elem'] },
            'oysho': { container: '.product-item, .grid-element, .product-card', price: ['.price-current', '.product-price', '.price-elem'] },
            'zarahome': { container: '.product-item, .grid-item', price: ['.price-current', '.product-price', '.price-elem'] },
            'lefties': { container: '.product-item, .product-card', price: ['.price-current', '.product-price', '.price-elem'] },

            // Global
            'hm': { container: 'article.hm-product-item, .product-item, li.product-item, .hm-product-item', price: ['.price-value', '.item-price'] },
            'mango': { container: 'li.product-card, div[class*="product-card"], .product-card, .product-list-item', price: ["span[data-testid='current-price']", '.text-body-m', '.product-price', '.price', 'span[class*="price"]'] },
            'jackjones': { container: 'article.product-item, .product-tile, .product-card', price: ['.product-price', '.price', '.sales-price'] },

            // TR Mass
            'lcwaikiki': { container: '.product-card, .create-product-card, .product-item-wrapper', price: ['.product-price', '.price', '.current-price'] },
            'defacto': { container: '.product-card, .catalog-product-item, div.product-card', price: ['.product-price', '.sale-price', '.product-card-price'] },
            'koton': { container: '.product-item, .product-card, div.product', price: ['.product-price', '.new-price', '.price'] },
            'colins': { container: '.product-box, .product-item, .colins-product-card', price: ['.product-price', '.price'] },
            'mavi': { container: '.product-card, .card, .product-item', price: ['.price', '.current-price', '.product-price'] },
            'loft': { container: '.product-item, .product-card', price: ['.price', '.current-price', '.product-price'] },

            // Premium/Network Groups
            'network': { container: '.product__card, .product-item, .product-card, div.product', price: ['.product__price--sale', '.product__price', '.price', '.product-price'] },
            'fabrika': { container: '.product-item, .product-card', price: ['.product-price', '.price'] },
            'boyner': { container: '.product-item, .product-card', price: ['.product-price', '.price'] },
            'twist': { container: '.product-item, .product-card, div.product', price: ['.product-price', '.price'] },
            'ipekyol': { container: '.product-item, .product-card, div.product', price: ['.product-price', '.price'] },

            // Luxury
            'beymen': { container: '.m-productCard, .product-item, .o-productListComponent', price: ['.m-productPrice__salePrice', '.m-productPrice__price', '.m-productPrice', '.price'] },
            'beymenclub': { container: '.product-item, .product-card', price: ['.product-price', '.price'] },
            'vakko': { container: '.product-item, .product-card, .pl-item', price: ['.product-price', '.price'] },
            'damattween': { container: '.product-item, .product-card', price: ['.product-price', '.price'] },
            'sarar': { container: '.product-item, .product-card', price: ['.product-price', '.price'] },
            'ramsey': { container: '.product-item, .product-card', price: ['.product-price', '.price'] },

            // Sport
            'nike': { container: '.product-card, .product-item, div.product-card', price: ['.product-price', '.is--current-price', '.css-11s12ax'] },
            'adidas': { container: '.grid-item, .glass-product-card, .product-card', price: ['.gl-price-item--sale', '.gl-price-item', '.price'] },
            'puma': { container: '.product-item, .product-card, .grid-tile', price: ['.price', '.product-price'] },
            'newbalance': { container: '.product-item, .product-card', price: ['.product-price', '.price'] },
            'underarmour': { container: '.product-item, .product-card', price: ['.product-price', '.price'] },
            'lesbenjamins': { container: '.product-item, .product-card', price: ['.product-price', '.price'] }
        };

        // 2. Navigation
        console.log(`🌐 [${target.source.toUpperCase()}] Navigating...`);
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36');
        await page.goto(target.url, { waitUntil: 'domcontentloaded', timeout: 60000 });

        // 3. Scroll to load lazy items
        console.log("Waiting 3s for initial DOM...");
        try {
            // Inditex/Bershka specific wait for real price or non-skeleton product
            await page.waitForSelector('.product-grid-product, .grid-card, .price-current, .product-price, .product-item:not(.skeleton)', { timeout: 8000 });
            console.log("✅ Grid content detected.");
        } catch (e) {
            console.log("⚠️ Timeout waiting for specific grid selector (could be skeleton or slow), proceeding...");
        }

        await autoScroll(page);

        // 4. EXTRACTION (In-Browser)
        const products = await page.evaluate((source, config) => {
            const items = [];
            const results = [];

            // --- BEAST MODE IMAGE EXTRACTOR ---
            function getBestImage(container) {
                if (!container) return "";
                const imgs = container.querySelectorAll('img');
                let bestUrl = "";
                const check = (url) => {
                    if (!url || url.includes('base64') || url.includes('spacer') || url.includes('transparent')) return;
                    if (url.startsWith('//')) url = 'https:' + url;
                    if (url.length > bestUrl.length) bestUrl = url;
                };
                for (const img of imgs) {
                    check(img.getAttribute('srcset')?.split(',').pop()?.split(' ')[0]);
                    check(img.getAttribute('data-original'));
                    check(img.getAttribute('data-src'));
                    check(img.getAttribute('data-lazy'));
                    check(img.src);
                }
                if (!bestUrl) {
                    const bg = window.getComputedStyle(container).backgroundImage;
                    if (bg && bg.startsWith('url')) bestUrl = bg.slice(5, -2);
                }
                return bestUrl;
            }

            // Determine selectors
            let containerSel = config ? config.container : '.product-card, .product-item, .grid-item, .product-grid-product';
            let priceSels = config ? config.price : ['.price', '.current-price', '.product-price'];

            // Find all potential product cards
            let cards = Array.from(document.querySelectorAll(containerSel));

            // --- SKELETON FILTER ---
            // Remove any card that looks like a skeleton/loader
            cards = cards.filter(c => {
                const cls = c.className || "";
                return !cls.includes('skeleton') && !cls.includes('loading') && !cls.includes('placeholder');
            });

            console.log(`🔎 Found ${cards.length} potential cards (after filtering skeletons).`);

            cards.forEach(card => {
                try {
                    // LINK
                    let link = card.querySelector('a')?.href;
                    if (!link && card.tagName === 'A') link = card.href;

                    // Fallback: Check parent if card is inside an A
                    if (!link) link = card.closest('a')?.href;

                    if (!link) return;
                    if (link.includes('javascript:') || link.includes('#')) return;

                    // TITLE
                    let title = card.querySelector('.product-title, .product-name, .name, h2, h3, .info, .product-description')?.innerText || "";
                    if (!title) title = card.innerText.split('\n')[0];

                    // PRICE
                    let priceText = "";
                    for (const sel of priceSels) {
                        const el = card.querySelector(sel);
                        if (el && el.innerText.match(/\d/)) {
                            priceText = el.innerText;
                            break;
                        }
                    }
                    // Fallback: Check raw text for price pattern
                    if (!priceText) {
                        const raw = card.innerText;
                        const match = raw.match(/(\d{1,3}(?:\s?\d{3})*(?:[.,]\d+)?)\s*(?:TL|TRY|TR)/i) || raw.match(/(?:TL|TRY|TR)\s*(\d{1,3}(?:\s?\d{3})*(?:[.,]\d+)?)/i);
                        if (match) priceText = match[1] || match[0];
                    }

                    // IMAGE
                    const img = getBestImage(card);

                    if (link && priceText) {
                        // Robust Price Cleaning
                        let cleanPrice = 0;
                        const pClean = priceText.replace(/[^\d.,]/g, '').replace(/\s/g, '').trim();
                        if (pClean.includes(',') && pClean.includes('.')) {
                            // TR Format: 1.250,90
                            if (pClean.lastIndexOf(',') > pClean.lastIndexOf('.')) {
                                cleanPrice = parseFloat(pClean.replace(/\./g, '').replace(',', '.'));
                            } else {
                                // US Format: 1,250.90
                                cleanPrice = parseFloat(pClean.replace(/,/g, ''));
                            }
                        } else if (pClean.includes(',')) {
                            cleanPrice = parseFloat(pClean.replace(',', '.'));
                        } else {
                            cleanPrice = parseFloat(pClean);
                        }

                        if (cleanPrice > 10) {
                            results.push({
                                title: title || source.toUpperCase() + " Ürünü",
                                url: link,
                                price: cleanPrice,
                                imageUrl: img,
                                source: source
                            });
                        }
                    }

                } catch (e) { }
            });

            // --- GENERIC FALLBACK (IF 0 ITEMS) ---
            if (results.length === 0) {
                console.log("⚠️ Zero items with config. Trying generic fallback + heuristics...");

                // 1. SHADOW DOM SCAN (P&B / Stradivarius often hide content here)
                try {
                    const allCustomElements = Array.from(document.querySelectorAll('*')).filter(el => el.shadowRoot);
                    allCustomElements.forEach(host => {
                        const shadowCards = host.shadowRoot.querySelectorAll('.product-card, .product-item, .grid-product, [class*="product-card"]');
                        shadowCards.forEach(sCard => {
                            const sLink = sCard.querySelector('a')?.href || sCard.closest('a')?.href;
                            const sPrice = sCard.innerText.match(/(\d{1,3}(?:\s?\d{3})*(?:[.,]\d+)?)\s*(?:TL|TRY|TR)/i)?.[0];
                            if (sLink && sPrice) {
                                results.push({
                                    title: sCard.innerText.split('\n')[0] || "Shadow Ürünü",
                                    url: sLink,
                                    price: parseFloat(sPrice.replace(/[^\d.,]/g, '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')) || 0,
                                    imageUrl: getBestImage(sCard),
                                    source: source
                                });
                            }
                        });
                    });
                } catch (e) { console.log("Shadow DOM Scan Error:", e.message); }

                // 2. TEXT-BASED HEURISTIC SCAN
                const genericSelector = 'a[href*="/p/"], a[href*="-p"], .product-card, .product-item, .grid-item, li.product-item, div[class*="product"], .grid-product';
                let elements = Array.from(document.querySelectorAll(genericSelector));

                elements = elements.filter(c => {
                    const cls = c.className || "";
                    return !cls.includes('skeleton') && !cls.includes('loading');
                });

                elements.forEach(el => {
                    let link = el.tagName === 'A' ? el.href : (el.querySelector('a')?.href || el.closest('a')?.href);
                    if (!link || link.includes('javascript:')) return;

                    let rawPrice = el.innerText.match(/(\d{1,3}(?:\s?\d{3})*(?:[.,]\d+)?)\s*(?:TL|TRY|TR)/i)?.[0];
                    if (!rawPrice) rawPrice = el.innerText.match(/(?:TL|TRY|TR)\s*(\d{1,3}(?:\s?\d{3})*(?:[.,]\d+)?)/i)?.[0];

                    if (link && rawPrice) {
                        let cleanPrice = parseFloat(rawPrice.replace(/[^\d.,]/g, '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')) || 0;
                        if (cleanPrice > 10) {
                            results.push({
                                title: el.innerText.split('\n')[0] || "Fırsat Ürünü",
                                url: link,
                                price: cleanPrice,
                                imageUrl: getBestImage(el),
                                source: source
                            });
                        }
                    }
                });
            }

            // Deduplicate by URL
            const unique = [];
            const urls = new Set();
            for (const r of results) {
                if (!urls.has(r.url)) {
                    urls.add(r.url);
                    unique.push(r);
                }
            }
            return unique.slice(0, 30);

        }, target.source, MINER_CONFIGS[target.source]); // PASS CONFIG HERE

        console.log(`✨ Found ${products.length} items for ${target.source}`);

        // DEBUG SNAPSHOT
        if (products.length === 0) {
            const bodyPreview = await page.evaluate(() => {
                return document.body.innerText.substring(0, 1000).replace(/\n/g, ' ') + ' || HTML: ' + document.body.innerHTML.substring(0, 500);
            });
            console.log(`⚠️ ZERO PRODUCTS DEBUG (Snapshot): ${bodyPreview}`);
        }

        // 5. DB Upsert
        let count = 0;
        let updatedCount = 0;
        for (const p of products) {
            try {
                const existing = await prisma.product.findFirst({ where: { url: p.url } });
                if (existing) {
                    await prisma.product.update({
                        where: { id: existing.id },
                        data: { currentPrice: p.price, updatedAt: new Date(), inStock: true }
                    });
                    updatedCount++;
                } else {
                    await prisma.product.create({
                        data: {
                            title: p.title,
                            url: p.url,
                            currentPrice: p.price,
                            originalPrice: p.price * 1.25, // Mock OG price
                            imageUrl: p.imageUrl,
                            source: p.source,
                            gender: detectGender(p.url, p.title),
                            userEmail: 'bot',
                            isSystem: true,
                            history: { create: { price: p.price } }
                        }
                    });
                    count++;
                }
            } catch (err) {
                console.error(`❌ Failed to save item: ${p.title} - ${err.message}`);
            }
        }
        console.log(`💾 Saved ${count} new, Updated ${updatedCount} existing.`);
        return products.length;

    } catch (e) {
        console.error(`Error processing ${target.source}: ${e.message}`);
        return 0; // Return 0 to trigger retry
    } finally {
        if (page) await page.close();
    }
}

async function autoScroll(page) {
    await page.evaluate(async () => {
        await new Promise((resolve) => {
            let totalHeight = 0;
            const distance = 300;
            const timer = setInterval(() => {
                window.scrollBy(0, distance);
                totalHeight += distance;
                if (totalHeight >= 3000) {
                    clearInterval(timer);
                    resolve();
                }
            }, 100);
        });
    });
}

function deriveCategory(title) {
    if (!title) return 'Moda';
    const t = title.toLowerCase();
    if (t.includes('elbise')) return 'Elbise';
    if (t.includes('ceket') || t.includes('mont')) return 'Dış Giyim';
    if (t.includes('pantolon') || t.includes('jean')) return 'Alt Giyim';
    if (t.includes('ayakkabı') || t.includes('sneaker')) return 'Ayakkabı';
    return 'Moda';
}

module.exports = { mineAllBrands };
