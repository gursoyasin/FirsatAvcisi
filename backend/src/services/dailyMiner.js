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
    { source: "colins", url: "https://www.colins.com.tr/kadin-indirim", gender: "woman" },
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
        try {
            console.log(`⛏️ Mining: ${target.source.toUpperCase()}`);
            await mineCategory(target);
            await new Promise(r => setTimeout(r, 4000)); // Polite delay
        } catch (error) {
            console.error(`❌ Global Miner Error (${target.source}):`, error.message);
        }
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
            'zara': { container: '.product-grid-product, li.product-item, .product-item, .product-grid-item', price: ['.price-current__amount', '.money-amount__main', '.price-current'] },
            'bershka': { container: 'div[data-id], .product-card, .grid-card, .product-item', price: ['.current-price-elem', '.product-price', '.price-current'] },
            'pullandbear': { container: '.product-card, div.grid-product, div[data-id], .product-item', price: ['.price-current', '.product-price', '.current-price'] },
            'stradivarius': { container: '.product-item, div[name="product-item"]', price: ['.price-current', '.product-price'] },
            'massimodutti': { container: '.product-item, .product-card', price: ['.product-price', '.price-current'] },
            'oysho': { container: '.product-item, .grid-element, .product-card', price: ['.price-current', '.product-price'] },
            'zarahome': { container: '.product-item, .grid-item', price: ['.price-current', '.product-price'] },
            'lefties': { container: '.product-item, .product-card', price: ['.price-current', '.product-price'] },

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
                        const match = raw.match(/(\d{1,3}(?:[.,]\d{3})*)\s*(?:TL|TRY|TR)/i) || raw.match(/(?:TL|TRY|TR)\s*(\d{1,3}(?:[.,]\d{3})*)/i);
                        if (match) priceText = match[1] || match[0];
                    }

                    // IMAGE
                    const img = getBestImage(card);

                    if (link && priceText) {
                        // Robust Price Cleaning
                        let cleanPrice = 0;
                        const pClean = priceText.replace(/[^\d.,]/g, '').trim();
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
                console.log("⚠️ Zero items with config. Trying generic fallback...");
                const genericSelector = 'a[href*="/p/"], a[href*="-p"], .product-card, .product-item, .grid-item, li.product-item, div[class*="product"]';
                let elements = Array.from(document.querySelectorAll(genericSelector));

                // Skeleton Filter again
                elements = elements.filter(c => {
                    const cls = c.className || "";
                    return !cls.includes('skeleton') && !cls.includes('loading');
                });

                elements.forEach(el => {
                    let link = el.tagName === 'A' ? el.href : el.querySelector('a')?.href;
                    if (!link) link = el.closest('a')?.href;

                    if (!link) return;

                    // Look for price in the element
                    let rawPrice = el.innerText.match(/(\d{1,3}(?:[.,]\d{3})*)\s*(?:TL|TRY)/i)?.[0];
                    if (!rawPrice) rawPrice = el.innerText.match(/(?:TL|TRY)\s*(\d{1,3}(?:[.,]\d{3})*)/i)?.[0];

                    if (link && rawPrice) {
                        let cleanPrice = parseFloat(rawPrice.replace(/[^\d.,]/g, '').replace(/\./g, '').replace(',', '.')) || 0;
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
        for (const p of products) {
            const existing = await prisma.product.findFirst({ where: { url: p.url } });
            if (existing) {
                await prisma.product.update({
                    where: { id: existing.id },
                    data: { currentPrice: p.price, updatedAt: new Date(), inStock: true }
                });
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
        }
        console.log(`💾 Saved ${count} new.`);

    } catch (e) {
        console.error(`Error processing ${target.source}: ${e.message}`);
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
