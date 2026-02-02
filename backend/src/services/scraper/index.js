const browserService = require('./BrowserService');
const cheerio = require('cheerio');

// ==========================================
// 🌍 EVRENSEL MARKA HARİTASI (BRAND MAP)
// ==========================================
// Tüm markaların CSS seçicileri ve davranış kuralları burada tanımlanır.
// Yeni marka eklemek için sadece bu listeye ekleme yapmak yeterlidir.
const BRAND_CONFIGS = {
    // --- INDITEX GRUBU ---
    'zara.com': { source: 'zara', useCookies: true, selectors: { price: ['.price-current__amount', '.price__amount--current'], originalPrice: ['.price-old__amount', '.price__amount--strikethrough'] } },
    'bershka.com': { source: 'bershka', useCookies: true, selectors: { price: ['.current-price-elem', '.product-price'], originalPrice: ['.old-price-elem', '.price-old'] } },
    'pullandbear.com': { source: 'pullandbear', useCookies: true, selectors: { price: ['.price-current', '.product-price'], originalPrice: ['.price-old', '.old-price'] } },
    'stradivarius.com': { source: 'stradivarius', useCookies: true, selectors: { price: ['.price-current', '.product-price'], originalPrice: ['.price-old'] } },
    'massimodutti.com': { source: 'massimodutti', useCookies: true, selectors: { price: ['.product-price', '.price-current'], originalPrice: ['.price-old'] } },
    'oysho.com': { source: 'oysho', useCookies: true, selectors: { price: ['.price-current', '.product-price'], originalPrice: ['.price-old'] } },
    'zarahome.com': { source: 'zarahome', useCookies: true, selectors: { price: ['.price-current', '.product-price'], originalPrice: ['.price-old'] } },
    'lefties.com': { source: 'lefties', useCookies: true, selectors: { price: ['.price-current', '.product-price'], originalPrice: ['.price-old'] } },

    // --- GLOBAL MODA ---
    'hm.com': { source: 'hm', selectors: { price: ['#product-price .price-value', '.price-value'], originalPrice: ['.price-regular', '.regular-price'] } },
    'mango.com': { source: 'mango', selectors: { price: ["span[data-testid='current-price']", '.text-body-m'], originalPrice: ["span[data-testid='original-price']", '.text-body-s-crossed'] } },
    'jackjones.com': { source: 'jackjones', selectors: { title: ['h1.product-name'], price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },

    // --- TÜRK DEVLERİ & PREMIUM ---
    'lcwaikiki.com': { source: 'lcwaikiki', selectors: { title: ['h1.product-title'], price: ['.product-price', '.price'], originalPrice: ['.raw-price', '.old-price'] } },
    'defacto.com.tr': { source: 'defacto', selectors: { title: ['h1.product-name'], price: ['.product-price', '.sale-price'], originalPrice: ['.product-card-first-price', '.old-price'] } },
    'defacto.com': { source: 'defacto' },
    'koton.com': { source: 'koton', selectors: { title: ['h1.product-name'], price: ['.product-price', '.new-price'], originalPrice: ['.old-price', '.first-price'] } },
    'colins.com.tr': { source: 'colins', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price', '.basket-price-old'] } },
    'mavi.com': { source: 'mavi', selectors: { price: ['.price', '.current-price'], originalPrice: ['.old-price', '.price-strikethrough'] } },
    'loft.com.tr': { source: 'loft', selectors: { price: ['.product-price', '.price', '.current-price'], originalPrice: ['.old-price'] } },
    'twist.com.tr': { source: 'twist', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },
    'ipekyol.com.tr': { source: 'ipekyol', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },

    // NETWORK & BOYNER GRUBU
    'network.com.tr': {
        source: 'network',
        selectors: {
            title: ['h1.product__title', '.product-details__title'],
            price: ['.product__price--sale', '.product__price'],
            originalPrice: ['.product__price--old', '.old-price']
        }
    },
    'fabrika.com.tr': { source: 'fabrika', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },
    'boyner.com.tr': { source: 'boyner', selectors: { title: ['h1.product-name'], price: ['.product-price', '.price'], originalPrice: ['.product-price-old', '.old-price'] } },

    // --- LÜKS & KLASİK ---
    'beymen.com': { source: 'beymen', selectors: { title: ['h1.o-productDetail__title'], price: ['.m-productPrice__salePrice', '.m-productPrice__price'], originalPrice: ['.m-productPrice__retailPrice', '.old-price'] } },
    'beymenclub.com': { source: 'beymenclub', selectors: { title: ['h1.product-name'], price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },
    'vakko.com': { source: 'vakko', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },
    'damattween.com': { source: 'damattween', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },
    'sarar.com': { source: 'sarar', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },
    'ramsey.com.tr': { source: 'ramsey', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },

    // --- SPOR ---
    'nike.com': { source: 'nike', selectors: { title: ['h1#pdp_product_title'], price: ['.product-price', '.is--current-price'], originalPrice: ['.is--striked-out'] } },
    'adidas.com.tr': { source: 'adidas', selectors: { title: ['h1[data-auto-id="product-title"]'], price: ['.gl-price-item--sale', '.gl-price-item'], originalPrice: ['.gl-price-item--crossed'] } },
    'puma.com': { source: 'puma', selectors: { price: ['.price', '.product-price'], originalPrice: ['.old-price'] } },
    'newbalance.com.tr': { source: 'newbalance', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },
    'underarmour.com.tr': { source: 'underarmour', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } },
    'lesbenjamins.com': { source: 'lesbenjamins', selectors: { price: ['.product-price', '.price'], originalPrice: ['.compare-at-price', '.old-price'] } },
    'superstep.com.tr': { source: 'superstep', selectors: { price: ['.product-price', '.price'], originalPrice: ['.old-price'] } }
};

async function scrapeProduct(url) {
    let page = null;
    let isolatedBrowser = null;
    let title = "";
    let price = 0;
    let originalPrice = 0;
    let imageUrl = "";

    try {
        const domain = new URL(url).hostname.replace('www.', '');

        // --- SHARED BROWSER FOR INDITEX & OTHERS ---
        // We reuse the existing browser service instead of launching a new one each time.
        // This saves 5-6 seconds of launch time.
        page = await browserService.createPage();

        // BRAND CONFIG
        let brandConfig = null;
        for (const [key, config] of Object.entries(BRAND_CONFIGS)) {
            if (domain.includes(key)) {
                brandConfig = config;
                break;
            }
        }
        const source = brandConfig ? brandConfig.source : 'unknown';
        console.log(`🌐 Scraper Hedefi: ${domain} -> Marka: ${source.toUpperCase()}`);

        if (url.includes('zara.com')) {
            // FIX: Robust ID Extraction (matches ...-p1234567.html)
            let idMatch = url.match(/-p(\d+)\.html/);
            if (!idMatch) idMatch = url.match(/v1=(\d+)/); // Query param fallback

            if (idMatch && idMatch[1]) {
                const cleanId = idMatch[1];
                url = `https://www.zara.com/tr/tr/product-p${cleanId}.html`;
                console.log(`🇹🇷 Zara TR Link Normalize Edildi: ${url}`);
            }
        }

        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36');

        // GEO-LOCK BYPASS (The Fix for "Select Your Location")
        await page.setExtraHTTPHeaders({
            'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
            'Upgrade-Insecure-Requests': '1',
            'Referer': 'https://www.google.com/'
        });

        // FORCE STORE COOKIES (Inditex Defaults)
        if (domain.includes('zara') || domain.includes('bershka') || domain.includes('pullandbear') || domain.includes('stradivarius')) {
            try {
                // Set "physical" store info to prevent splash screen
                await page.setCookie(
                    { name: 'storeId', value: '11717', domain: `.${domain}` }, // Generic TR Store
                    { name: 'countryCode', value: 'TR', domain: `.${domain}` },
                    { name: 'langCode', value: 'tr', domain: `.${domain}` }
                );
            } catch (e) { console.log("Cookie set error:", e.message); }
        }

        // REQUEST INTERCEPTION (Aggressive Speed Mode)
        await page.setRequestInterception(true);
        page.on('request', (req) => {
            const resourceType = req.resourceType();
            // Block everything not needed for HTML structure (Images, Fonts, CSS, Media)
            // Exception: Zara sometimes needs CSS for layout, but usually raw HTML is enough for extraction
            if (['image', 'media', 'font', 'stylesheet', 'other'].includes(resourceType)) {
                req.abort();
            } else {
                req.continue();
            }
        });

        console.log(`🚀 Gidiliyor: ${url}`);

        try {
            await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 }); // 30s is more reasonable for cloud
        } catch (e) {
            console.log("⚠️ Navigasyon timeout (Devam ediliyor)...");
        }

        // DEBUG: Check where we landed
        let pageTitle = await page.title();
        console.log(`📍 Landed on Page: "${pageTitle}"`);

        // EMERGENCY: "Select Your Location" Handler
        if (pageTitle.toLowerCase().includes('location') || pageTitle.toLowerCase().includes('select') || pageTitle.toLowerCase().includes('konum')) {
            console.log("🚨 'Select Location' screen detected! Attempting auto-fix...");
            try {
                // Try multiple strategies to click "Turkey"
                const trLink = await page.$('a[href*="/tr/tr/"]');
                const trText = await page.$x("//a[contains(text(), 'Turkey') or contains(text(), 'Türkiye')]");

                if (trLink) {
                    console.log("🖱️ Clicking TR Link (Href)...");
                    await Promise.all([page.waitForNavigation({ timeout: 10000 }), trLink.click()]);
                } else if (trText.length > 0) {
                    console.log("🖱️ Clicking TR Link (Text)...");
                    await Promise.all([page.waitForNavigation({ timeout: 10000 }), trText[0].click()]);
                }

                // Update title after click
                pageTitle = await page.title();
                console.log(`📍 New Page Title: "${pageTitle}"`);
            } catch (e) {
                console.log("❌ Auto-fix failed:", e.message);
            }
        }

        // 3.5. SPLASH SCREEN / ACCESSIBILITY KILLER V2
        try {
            await page.evaluate(() => {
                const overlay = document.getElementById('INDblindNotif') || document.getElementById('INDWrap');
                if (overlay) overlay.remove();

                const blindBtn = document.querySelector('button[aria-label*="erişilebilirlik"]');
                if (blindBtn) blindBtn.click();

                // Generic Fixed Overlay Remover
                const fixed = Array.from(document.querySelectorAll('div')).filter(bs => {
                    const style = window.getComputedStyle(bs);
                    return style.position === 'fixed' && style.zIndex > 999;
                });
                fixed.forEach(f => {
                    if (f.innerText.includes('erişilebilirlik')) f.remove();
                });
            });
        } catch (e) { }

        // ROBUST WAIT (Wait for Price or Title)
        try {
            await page.waitForFunction(
                () => document.querySelector('h1') || document.querySelector('[class*="price"]'),
                { timeout: 8000 }
            );
        } catch (e) { }

        // --- DATA EXTRACTION ---
        const content = await page.content();
        const $ = cheerio.load(content);

        // STRATEGY 1: JSON-LD (Gold Standard)
        try {
            $("script[type='application/ld+json']").each((i, el) => {
                let text = $(el).html();
                if (text) {
                    let data = JSON.parse(text);
                    if (Array.isArray(data)) data = data.find(item => item['@type'] === 'Product');
                    if (data && data.name) {
                        title = data.name;
                        if (data.image) imageUrl = Array.isArray(data.image) ? data.image[0] : data.image;
                        if (data.offers) {
                            const offer = Array.isArray(data.offers) ? data.offers[0] : data.offers;
                            price = parseFloat(offer.price || offer.lowPrice || 0);
                            // Some sites put the high/original price in JSON-LD
                            if (offer.highPrice) originalPrice = parseFloat(offer.highPrice);
                        }
                    }
                }
            });
        } catch (e) { }

        // STRATEGY 2: META TAGS
        if (!title) title = $("meta[property='og:title']").attr("content");
        if (!imageUrl) imageUrl = $("meta[property='og:image']").attr("content");
        if (!price) {
            const p = $("meta[property='product:price:amount']").attr("content") || $("meta[property='og:price:amount']").attr("content");
            if (p) price = parseFloat(p);
        }
        if (!originalPrice) {
            const op = $("meta[property='product:original_price:amount']").attr("content") || $("meta[name='twitter:data1']").attr("content");
            if (op && op.match(/\d/)) originalPrice = parsePrice(op);
        }

        // STRATEGY 3: BRAND SELECTORS (Critical for Network/Beymen)
        if (brandConfig && brandConfig.selectors) {
            if (!title && brandConfig.selectors.title) {
                brandConfig.selectors.title.forEach(sel => { if ($(sel).text()) title = $(sel).text().trim() });
            }
            if (!price && brandConfig.selectors.price) {
                brandConfig.selectors.price.forEach(sel => {
                    const t = $(sel).text().trim();
                    if (t) price = parsePrice(t);
                });
            }
            if (brandConfig.selectors.originalPrice) {
                brandConfig.selectors.originalPrice.forEach(sel => {
                    const t = $(sel).text().trim();
                    if (t) originalPrice = parsePrice(t);
                });
            }
        }

        // STRATEGY 4: FALLBACK (Visual Selection)
        if (!title) title = $('h1').first().text().trim();
        if (!price) {
            const raw = $('body').text().match(/(\d{1,3}(?:[.,]\d{3})*)\s*(?:TL|TRY)/);
            if (raw) price = parsePrice(raw[0]);
        }

        // --- FINAL PRICE SANITY CHECK ---
        // Ensure original price is >= current price, else nullify it to avoid confusing the user
        if (originalPrice < price) originalPrice = 0;

        // Clean Results
        const result = {
            title: title || "Ürün Başlığı Bulunamadı",
            currentPrice: price || 0,
            originalPrice: originalPrice || price, // REAL DATA OR FALLBACK
            imageUrl: imageUrl || "",
            source: source,
            url: url,
            inStock: true,
            category: detectCategory(title),
            gender: detectGender(url, title)
        };
        console.log(`✅ Scraper Başarılı: ${JSON.stringify(result)}`);
        return result;

    } catch (error) {
        console.error(`❌ Scrape Hatası (${url}):`, error.message);
        // CRITICAL: Return SAFE object instead of crashing
        return {
            title: "Analiz Edilemedi",
            currentPrice: 0,
            imageUrl: "",
            source: 'unknown',
            url: url,
            error: true
        };
    } finally {
        // Only close the PAGE, not the browser (Keep-Alive)
        if (page) await page.close();
        if (isolatedBrowser) await isolatedBrowser.close(); // Only if we forced isolation
    }
}

function parsePrice(text) {
    if (!text) return 0;

    // Remove non-numeric chars except . and ,
    let clean = text.replace(/[^\d.,]/g, '').trim();
    if (!clean) return 0;

    // Detect format:
    // 15.000,50 -> TR format (dot is thousand, comma is decimal)
    // 15,000.50 -> US format (comma is thousand, dot is decimal)
    // 15.000 -> TR format (thousand)

    const lastDot = clean.lastIndexOf('.');
    const lastComma = clean.lastIndexOf(',');

    if (lastDot > -1 && lastComma > -1) {
        if (lastDot > lastComma) {
            // US Format or mixed correctly: 1,500.50
            return parseFloat(clean.replace(/,/g, ''));
        } else {
            // TR Format: 1.500,50
            return parseFloat(clean.replace(/\./g, '').replace(',', '.'));
        }
    }

    if (lastComma > -1) {
        // Only comma: 99,50 or 1,500 (Ambiguous)
        // Heuristic: If comma is 3 digits from end, might be thousands, but usually in TR it's decimals for small strings
        const parts = clean.split(',');
        if (parts[parts.length - 1].length === 3 && clean.length > 4) {
            // Likely thousand: 1,000
            return parseFloat(clean.replace(/,/g, ''));
        }
        // Likely decimal: 99,50
        return parseFloat(clean.replace(',', '.'));
    }

    if (lastDot > -1) {
        // Only dot: 15.000 or 15.50 (Ambiguous)
        // Heuristic: If dot is 3 digits from end, it's almost certainly thousand separator in TR Context (Beymen, Zara etc)
        const parts = clean.split('.');
        if (parts[parts.length - 1].length === 3) {
            // 15.000 -> 15000
            return parseFloat(clean.replace(/\./g, ''));
        }
        // 15.50 -> 15.5
        return parseFloat(clean);
    }

    return parseFloat(clean) || 0;
}

function detectCategory(title) {
    if (!title) return "Genel";
    const t = title.toLowerCase();
    if (t.includes("elbise")) return "Elbise";
    if (t.includes("pantolon")) return "Alt Giyim";
    if (t.includes("ceket") || t.includes("mont")) return "Dış Giyim";
    if (t.includes("ayakkabi") || t.includes("sneaker")) return "Ayakkabı";
    return "Moda";
}

function detectGender(url, title) {
    const text = (url + " " + title).toLowerCase();

    // 1. Female Keywords (Turkish & English)
    const femaleKeywords = [
        "kadun", "kadin", "woman", "female", "elbise", "etek", "bluz", "tunik", "tayt", "sütyen", "sutyen",
        "bra", "topuklu", "mini", "midi", "pudra", "floral", "şifon", "dantel", "fisto", "vual", "volan",
        "crop", "bustiyer", "büstiyer", "askılı", "gecelik", "sabahlık", "küpe", "earring", "çanta", "bag",
        "makyaj", "makeup", "ruj", "cilt bakımı", "eşarp", "şal", "fular", "lady", "jane", "cindy", "linda"
    ];

    // 2. Male Keywords (Turkish & English)
    const maleKeywords = [
        "erkek", "man", "male", "damatlik", "damatlık", "smokin", "sakalli", "sakallı", "jilet", "traş", "tras",
        "berber", "beard", "boxer", "sliper", "tesbih", "nargile", "gentleman", "boy", "oğlan", "yakışıklı",
        "james", "marcus", "martin", "jake", "jason", "serra", "adriano", "hunter"
    ];

    // 3. Logic: Check for direct mentions first
    if (femaleKeywords.some(k => text.includes(k))) return "female";
    if (maleKeywords.some(k => text.includes(k))) return "male";

    // 4. Special Breadcrumb logic (especially for Zara/Beymen)
    if (url.includes("/tr/kadin") || url.includes("/tr/woman") || url.includes("-kadin-")) return "female";
    if (url.includes("/tr/erkek") || url.includes("/tr/man") || url.includes("-erkek-")) return "male";

    return "unisex";
}

module.exports = { scrapeProduct, detectGender, parsePrice };
