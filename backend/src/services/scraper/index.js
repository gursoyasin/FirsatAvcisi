const browserService = require('./BrowserService');
const cheerio = require('cheerio');

// ==========================================
// 🌍 EVRENSEL MARKA HARİTASI (BRAND MAP)
// ==========================================
const BRAND_CONFIGS = {
    // --- INDITEX GRUBU ---
    'zara.com': {
        source: 'zara',
        useCookies: true,
        selectors: {
            price: ['.price-current__amount', '.price__amount--current', '.money-amount__main'],
            originalPrice: ['.price-old__amount', '.price__amount--strikethrough', '.money-amount__main--strikethrough'],
            image: ['.media-image__image', '.product-detail-images__image', 'meta[name="twitter:image"]']
        }
    },
    'bershka.com': {
        source: 'bershka',
        useCookies: true,
        selectors: {
            price: ['.current-price-elem', '.product-price', '.price-current'],
            originalPrice: ['.old-price-elem', '.price-old'],
            image: ['.image-item', 'img[class*="product-image"]']
        }
    },
    'pullandbear.com': {
        source: 'pullandbear',
        useCookies: true,
        selectors: {
            price: ['.price-current', '.product-price'],
            originalPrice: ['.price-old', '.old-price'],
            image: ['img[class*="image-item"]']
        }
    },
    'stradivarius.com': { source: 'stradivarius', useCookies: true, selectors: { price: ['.price-current', '.product-price'], originalPrice: ['.price-old'] } },
    'massimodutti.com': { source: 'massimodutti', useCookies: true, selectors: { price: ['.product-price', '.price-current'], originalPrice: ['.price-old'] } },
    'oysho.com': { source: 'oysho', useCookies: true, selectors: { price: ['.price-current', '.product-price'], originalPrice: ['.price-old'] } },

    // --- GLOBAL ---
    'hm.com': { source: 'hm', selectors: { price: ['#product-price .price-value', '.price-value'], originalPrice: ['.price-regular', '.regular-price'] } },
    'mango.com': { source: 'mango', selectors: { price: ["span[data-testid='current-price']", '.text-body-m'], originalPrice: ["span[data-testid='original-price']", '.text-body-s-crossed'] } },

    // --- TÜRK ---
    'lcwaikiki.com': { source: 'lcwaikiki', selectors: { title: ['h1.product-title'], price: ['.product-price', '.price'], originalPrice: ['.raw-price', '.old-price'] } },
    'defacto.com.tr': { source: 'defacto', selectors: { title: ['h1.product-name'], price: ['.product-price', '.sale-price'], originalPrice: ['.product-card-first-price', '.old-price'] } },
    'boyner.com.tr': { source: 'boyner', selectors: { title: ['h1.product-name'], price: ['.product-price', '.price'], originalPrice: ['.product-price-old', '.old-price'] } },
    'beymen.com': { source: 'beymen', selectors: { title: ['h1.o-productDetail__title'], price: ['.m-productPrice__salePrice', '.m-productPrice__price'], originalPrice: ['.m-productPrice__retailPrice', '.old-price'] } },
    'network.com.tr': { source: 'network', selectors: { title: ['h1.product__title'], price: ['.product__price--sale'], originalPrice: ['.product__price--old'] } },
};

async function scrapeProduct(url) {
    let page = null;
    try {
        const domain = new URL(url).hostname.replace('www.', '');

        // --- SHARED BROWSER ---
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
        console.log(`🌐 Scraper Target: ${domain} -> Brand: ${source.toUpperCase()}`);

        if (url.includes('zara.com')) {
            let idMatch = url.match(/-p(\d+)\.html/);
            if (!idMatch) idMatch = url.match(/v1=(\d+)/);
            if (idMatch && idMatch[1]) {
                const cleanId = idMatch[1];
                url = `https://www.zara.com/tr/tr/product-p${cleanId}.html`;
                console.log(`🇹🇷 Zara Link Normalized: ${url}`);
            }
        }

        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36');

        // Bypassing Geo/Language popups
        await page.setExtraHTTPHeaders({
            'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7'
        });

        if (domain.includes('zara') || domain.includes('bershka') || domain.includes('pullandbear') || domain.includes('stradivarius')) {
            try {
                await page.setCookie(
                    { name: 'storeId', value: '11717', domain: `.${domain}` },
                    { name: 'countryCode', value: 'TR', domain: `.${domain}` },
                    { name: 'langCode', value: 'tr', domain: `.${domain}` }
                );
            } catch (e) { }
        }

        // Optimized Request Interception
        await page.setRequestInterception(true);
        page.on('request', (req) => {
            const resourceType = req.resourceType();
            if (['image', 'media', 'font'].includes(resourceType)) {
                req.abort();
            } else {
                req.continue();
            }
        });

        console.log(`🚀 Navigating to: ${url}`);
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 35000 });

        // Wait for essential content
        try {
            await page.waitForFunction(
                () => document.querySelector('h1') || document.querySelector('[class*="price"]'),
                { timeout: 8000 }
            );
        } catch (e) { }

        const content = await page.content();
        const $ = cheerio.load(content);

        let title = "";
        let price = 0;
        let originalPrice = 0;
        let imageUrl = "";

        // ===============================================
        // 🦁 BEAST MODE EXTRACTION LOGIC
        // ===============================================

        // 1. JSON-LD (Highest Priority)
        try {
            $("script[type='application/ld+json']").each((i, el) => {
                const text = $(el).html();
                if (text) {
                    let data = JSON.parse(text);
                    if (Array.isArray(data)) data = data.find(item => item['@type'] === 'Product');
                    if (data && data.name) {
                        title = data.name;
                        if (data.image) {
                            imageUrl = Array.isArray(data.image) ? data.image[0] : (data.image.url || data.image);
                        }
                        if (data.offers) {
                            const offer = Array.isArray(data.offers) ? data.offers[0] : data.offers;
                            price = parseFloat(offer.price || offer.lowPrice || 0);
                            if (offer.highPrice) originalPrice = parseFloat(offer.highPrice);
                        }
                    }
                }
            });
        } catch (e) { }

        // 2. META TAGS (Backup)
        if (!title) title = $("meta[property='og:title']").attr("content");
        if (!imageUrl) imageUrl = $("meta[property='og:image']").attr("content");

        // 3. BRAND SPECIFIC SELECTORS (High Res & Precision)
        if (brandConfig && brandConfig.selectors) {
            // Price Extraction
            if (!price && brandConfig.selectors.price) {
                for (const sel of brandConfig.selectors.price) {
                    const t = $(sel).first().text().trim();
                    if (t) {
                        price = parsePrice(t);
                        if (price > 0) break;
                    }
                }
            }
            // Image Extraction (Look for high-res attributes)
            if (brandConfig.selectors.image) {
                for (const sel of brandConfig.selectors.image) {
                    const el = $(sel).first();
                    const candidate = el.attr('data-original') || el.attr('data-src') || el.attr('src') || el.attr('content');
                    if (candidate) {
                        imageUrl = candidate;
                        // Try to find high-res version via query param manipulation or heuristics if needed
                        break;
                    }
                }
            }
        }

        // 4. FALLBACKS
        if (!title) title = $('h1').first().text().trim();
        if (!title) title = $('title').text().split('|')[0].trim();

        // Clean Title
        if (title) {
            title = title.replace(/\s+/g, ' ').trim();
            // Remove common junk prefixes/suffixes
            const junk = [" | ZARA Türkiye", " | Zara Home", " - Bershka", " - Pull&Bear", " - Stradivarius"];
            junk.forEach(j => title = title.replace(j, ""));
        }

        if (!imageUrl) {
            const imgSelectors = ['#main-image', '#product-image', '.product-image', 'img[property="og:image"]'];
            for (const sel of imgSelectors) {
                const src = $(sel).attr('src');
                if (src && src.startsWith('http')) {
                    imageUrl = src;
                    break;
                }
            }
        }

        // Final Price Parsing if still zero (Body search)
        if (price <= 0) {
            const rawBody = $('body').text().substring(0, 10000); // Limit search scope
            const match = rawBody.match(/(\d{1,3}(?:[.,]\d{3})*)\s*(?:TL|TRY)/);
            if (match) price = parsePrice(match[0]);
        }

        // INTEGRITY CHECK
        if (originalPrice < price) originalPrice = 0; // Invalid
        if (price <= 0) {
            console.warn(`⚠️ Warning: Zero price detected for ${url}`);
        }

        const result = {
            title: title || "Ürün Başlığı Bulunamadı",
            currentPrice: price || 0,
            originalPrice: originalPrice || price,
            imageUrl: imageUrl || "",
            source: source,
            url: url,
            inStock: true,
            category: detectCategory(title),
            gender: detectGender(url, title)
        };
        console.log(`✅ Scrape Success: ${result.title} (${result.currentPrice} TL)`);
        return result;

    } catch (error) {
        console.error(`❌ Scrape Error (${url}):`, error.message);
        return {
            title: "Analiz Edilemedi",
            currentPrice: 0,
            imageUrl: "",
            source: 'unknown',
            url: url,
            error: true
        };
    } finally {
        if (page) await page.close();
    }
}

function parsePrice(text) {
    if (!text) return 0;
    // Remove all non-numeric except . and ,
    let clean = text.replace(/[^\d.,]/g, '').trim();
    if (!clean) return 0;

    const lastPoint = clean.lastIndexOf('.');
    const lastComma = clean.lastIndexOf(',');

    // TR/EU Standard: 1.200,50
    if (lastPoint > -1 && lastComma > -1 && lastPoint < lastComma) {
        clean = clean.replace(/\./g, '').replace(',', '.');
    }
    // US/Global Standard: 1,200.50
    else if (lastPoint > -1 && lastComma > -1 && lastComma < lastPoint) {
        clean = clean.replace(/,/g, '');
    }
    // Single Separator: "1.299" (Usually TR thousand) or "1,299" (US thousand) or "12.99" (Price)
    // Heuristic: Inditex TR uses dot for thousands (1.299 TL) and comma for decimals (499,99 TL)
    else if (lastPoint > -1) {
        // If "1.299" -> It's likely 1299 TL, not 1.299 TL (too cheap)
        // If "12.99" -> It's likely 12.99 TL
        const parts = clean.split('.');
        if (parts[parts.length - 1].length === 3) {
            // Assume Thousand separator (1.299)
            clean = clean.replace(/\./g, '');
        }
    }
    else if (lastComma > -1) {
        // "499,99" -> Decimal
        clean = clean.replace(',', '.');
    }

    const val = parseFloat(clean);
    return isNaN(val) ? 0 : val;
}

function detectCategory(title) {
    if (!title) return "Genel";
    const t = title.toLowerCase();
    if (t.includes("elbise")) return "Elbise";
    if (t.includes("pantolon") || t.includes("jean")) return "Alt Giyim";
    if (t.includes("ceket") || t.includes("mont") || t.includes("kaban")) return "Dış Giyim";
    if (t.includes("ayakkabi") || t.includes("sneaker") || t.includes("bot")) return "Ayakkabı";
    if (t.includes("çanta")) return "Çanta";
    return "Moda";
}

function detectGender(url, title) {
    const text = (url + " " + title).toLowerCase();
    const femaleKeywords = ["kadin", "woman", "elbise", "etek", "bluz", "topuklu", "sütyen", "büstiyer", "çanta"];
    const maleKeywords = ["erkek", "man", "damatlık", "boxer", "ceket takımı"];

    if (femaleKeywords.some(k => text.includes(k))) return "female";
    if (maleKeywords.some(k => text.includes(k))) return "male";

    // Breadcrumb URL check
    if (url.includes("/tr/kadin") || url.includes("/woman")) return "female";
    if (url.includes("/tr/erkek") || url.includes("/man")) return "male";

    return "unisex";
}

module.exports = { scrapeProduct, detectGender, parsePrice };
