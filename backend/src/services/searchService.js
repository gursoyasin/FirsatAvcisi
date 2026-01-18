const browserService = require('./scraper/BrowserService');
const cheerio = require('cheerio');

/**
 * ULTRA SEARCH ENGINE: Cimri Meta-Search + AI Filtering + Smart Grouping
 */

const NOISE_KEYWORDS = [
    'kılıf', 'kapak', 'kordon', 'cam', 'koruyucu', 'lens', 'askı', 'stand',
    'çanta', 'sticker', 'etiket', 'şarj kablosu', 'adaptör', 'kulaklık ucu',
    'case', 'cover', 'protector', 'strap', 'band', 'pouch',
    'filtre', 'filter', 'yedek parça', 'aksesuar', 'hortum', 'başlık', 'toz torbası'
];

async function globalSearch(query) {
    console.log(`🌍 Global Search Initiated for: "${query}"`);

    // Run providers in parallel for speed
    const [cimriResults, akakceResults] = await Promise.all([
        searchCimri(query),
        searchAkakce(query),
        // searchGoogle(query) // DISABLED FOR SPEED (BETA)
    ]);
    const googleResults = [];

    console.log(`📊 Results - Cimri: ${cimriResults.length}, Akakçe: ${akakceResults.length}, Google: ${googleResults.length}`);

    // Merge and Deduplicate
    const combined = [...cimriResults, ...akakceResults, ...googleResults];
    const productMap = new Map();

    combined.forEach(item => {
        // Normalizing Title for Grouping
        const titleKey = item.title.toLowerCase().trim()
            .replace(/\s+/g, ' ')
            .replace(/['"]/g, '')
            .replace(/\(.*\)/g, '') // remove parens for loose matching? maybe risky. stick to simple.
            .trim();

        if (productMap.has(titleKey)) {
            // MERGE STRATEGY
            const existing = productMap.get(titleKey);

            // 1. Merge Sellers
            const existingSellers = JSON.parse(existing.sellers);
            const newSellers = JSON.parse(item.sellers);

            const mergedSellers = [...existingSellers, ...newSellers];

            // Dedupe sellers inside the merged list based on Merchant + Price
            const uniqueSellers = [];
            const seenSellerKeys = new Set();
            mergedSellers.forEach(s => {
                const key = `${s.merchant}-${s.price}`;
                if (!seenSellerKeys.has(key)) {
                    seenSellerKeys.add(key);
                    uniqueSellers.push(s);
                }
            });

            // Sort sellers cheapest first
            uniqueSellers.sort((a, b) => a.price - b.price);
            existing.sellers = JSON.stringify(uniqueSellers);

            // 2. Update Best Price
            if (item.price < existing.price && item.price > 0) {
                existing.price = item.price;
                existing.shopInfo = item.shopInfo; // Update shop info to cheapest
                existing.url = item.url; // Update main link to cheapest
            }

            // 3. Merge Sources flag (Optional)
            if (!existing.source.includes(item.source)) {
                existing.source += ` & ${item.source}`;
            }

        } else {
            productMap.set(titleKey, item);
        }
    });

    const unique = Array.from(productMap.values());
    console.log(`✅ Total Unique Products (Merged): ${unique.length}`);

    // Sort by price (Cheapest first)
    unique.sort((a, b) => a.price - b.price);

    // AI Noise Reduction & Price Anomaly Fix
    const queryLower = query.toLowerCase();
    const filteredResults = unique.filter(item => {
        const titleLower = item.title.toLowerCase();

        // 1. Title Filter (Garbage)
        if (["ürüne git", "detay", "satın al", "fırsat", "kampanya"].some(t => titleLower.includes(t)) && titleLower.length < 15) return false;

        // 2. Keyword Noise Filter
        const isNoise = NOISE_KEYWORDS.some(kw =>
            titleLower.includes(kw) && !queryLower.includes(kw)
        );
        if (isNoise) return false;

        // 3. Price Anomaly Filter (The "140 TL iPhone" Fix)
        if (item.price < 500) {
            // High value keywords
            if (["iphone", "macbook", "dyson", "ipad", "laptop", "playstation", "televizyon", "samsung s", "xiaomi 1"].some(kw => titleLower.includes(kw) || queryLower.includes(kw))) {
                return false;
            }
        }

        return true;
    });

    return filteredResults.slice(0, 50); // Return top 50 mixed results
}

// --- PROVIDER 1: CIMRI ---
async function searchCimri(query) {
    let page;
    try {
        page = await browserService.createPage();
        const searchUrl = `https://www.cimri.com/arama?q=${encodeURIComponent(query)}`;
        // console.log(`🚀 Cimri Search: ${searchUrl}`);

        await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 10000 }); // 10s Timeout

        try { await page.waitForSelector('#Search-Results, .s1w988-0', { timeout: 5000 }); } catch (e) { }

        const content = await page.content();
        const $ = cheerio.load(content);
        const results = [];

        // Extract from JSON (Primary)
        try {
            const jsonData = $('#__NEXT_DATA__').html();
            if (jsonData) {
                const parsed = JSON.parse(jsonData);
                const items = parsed.props?.pageProps?.initialState?.search?.listing?.items || [];

                items.forEach(item => {
                    const bestOffer = item.topOffers?.[0];
                    if (item.title && bestOffer) {
                        const sellers = [];
                        if (item.topOffers) {
                            item.topOffers.forEach(offer => {
                                sellers.push({
                                    merchant: offer.merchant?.name || "Bilinmiyor",
                                    price: parsePrice(offer.price),
                                    url: offer.uri ? `https://www.cimri.com${offer.uri}` : `https://www.cimri.com${item.uri}`,
                                    badge: null
                                });
                            });
                        }

                        // Fallback seller
                        if (sellers.length === 0) {
                            sellers.push({
                                merchant: bestOffer.merchant?.name || "Mağaza",
                                price: parsePrice(bestOffer.price),
                                url: item.uri ? `https://www.cimri.com${item.uri}` : "",
                                badge: "En İyi Fiyat"
                            });
                        }

                        const variants = (item.variants || []).map(v => ({
                            title: v.name || v.value,
                            url: `https://www.cimri.com${v.uri}`,
                            active: false
                        }));

                        results.push({
                            title: item.title,
                            price: parsePrice(bestOffer.price),
                            imageUrl: item.imageId ? `https://cdn.cimri.io/image/148x148/${item.title.toLowerCase().replace(/\s+/g, '-')}_${item.imageId}.jpg` : "",
                            url: `https://www.cimri.com${item.uri}`,
                            source: 'cimri',
                            sellers: JSON.stringify(sellers),
                            variants: JSON.stringify(variants)
                        });
                    }
                });
            }
        } catch (e) { console.log("Cimri JSON failed"); }

        // Fallback HTML (Secondary)
        if (results.length === 0) {
            $('article, h3').each((i, el) => {
                const title = $(el).find('h3').text().trim();
                const priceText = $(el).text();
                const priceMatch = priceText.match(/(\d+[\.,]?\d*)\s*TL/);
                if (title && priceMatch) {
                    const price = parsePrice(priceMatch[1]);
                    const link = $(el).closest('a').attr('href');
                    if (price > 0) {
                        results.push({
                            title: title,
                            price: price,
                            imageUrl: "",
                            url: link ? `https://www.cimri.com${link}` : "",
                            source: 'cimri',
                            sellers: JSON.stringify([{ merchant: "Piyasa", price, url: link ? `https://www.cimri.com${link}` : "", badge: null }]),
                            variants: "[]"
                        });
                    }
                }
            });
        }

        return results;

    } catch (e) {
        console.error("Cimri Error:", e.message);
        return [];
    } finally {
        if (page) await page.close();
    }
}

// --- PROVIDER 3: GOOGLE SHOPPING (ULTRA) ---
async function searchGoogle(query) {
    let page;
    try {
        page = await browserService.createPage();
        const searchUrl = `https://www.google.com/search?tbm=shop&q=${encodeURIComponent(query)}`;
        // console.log(`🚀 Google Shopping Search: ${searchUrl}`);

        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        // TIMEOUT REDUCED FOR SPEED (3s)
        await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 3000 });

        // Consent Handling
        try {
            const consentBtn = await page.$('button[aria-label="Tümünü kabul et"], button:contains("Accept all")');
            if (consentBtn) {
                await consentBtn.click();
                await page.waitForNavigation({ waitUntil: 'networkidle0', timeout: 5000 }).catch(() => { });
            }
        } catch (e) { }

        // Wait for ANY product card using broader selectors
        try { await page.waitForSelector('.sh-dgr__content, .i0X6df, .sh-dgr__grid-result, .sh-np__click-target', { timeout: 6000 }); } catch (e) { }

        const content = await page.content();
        const $ = cheerio.load(content);
        const results = [];

        // Try multiple selectors for the GRID ITEM
        $('.sh-dgr__content, .i0X6df, .sh-dgr__grid-result').each((i, el) => {
            // Extract Title (h3 or specific classes)
            const title = $(el).find('h3, .tAxDx, .Lq5OHe').text().trim();

            // Extract Price (find the span with currency)
            const priceText = $(el).find('.a8Pemb, .a8Pemb, .HRLxBb, .Off2x, span:contains("TL")').first().text().trim();
            const price = parsePrice(priceText);

            // Extract Link
            let link = $(el).find('a[href^="/url"]').attr('href') || $(el).find('a').attr('href');
            if (link) {
                if (!link.startsWith('http')) link = "https://www.google.com" + link;
                const urlMatch = link.match(/url\?q=(.*?)&/);
                if (urlMatch) link = decodeURIComponent(urlMatch[1]);
            }

            // Extract Image
            const img = $(el).find('img').attr('src');

            // Extract Merchant
            const merchant = $(el).find('.aULzUe, .IuHnof, .dNS8pb').text().trim() || "Google Market";

            if (title && price > 0 && link) {
                results.push({
                    title: title,
                    price: price,
                    imageUrl: img || "",
                    url: link,
                    source: 'google',
                    sellers: JSON.stringify([{
                        merchant: merchant,
                        price: price,
                        url: link,
                        badge: "Google Fırsatı"
                    }]),
                    variants: "[]"
                });
            }
        });

        console.log(`Google Scraper found ${results.length} items`);
        return results;

    } catch (e) {
        console.error("Google Search Error:", e.message);
        return [];
    } finally {
        if (page) await page.close();
    }
}

// --- PROVIDER 2: AKAKÇE ---
// --- PROVIDER 2: AKAKÇE (STRICT SELECTORS) ---
async function searchAkakce(query) {
    let page;
    try {
        page = await browserService.createPage();
        const searchUrl = `https://www.akakce.com/arama/?q=${encodeURIComponent(query)}`;

        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 15000 }); // 15s timeout

        try { await page.waitForSelector('.p-v8, .m-p-v8, #CList', { timeout: 3000 }); } catch (e) { }

        const content = await page.content();
        const $ = cheerio.load(content);
        const results = [];

        // Akakce List Items
        $('li[data-pr]').each((i, el) => {
            const linkEl = $(el).find('a').first();
            const title = $(el).find('b').first().text().trim() || linkEl.attr('title');

            // PRIORITY SELECTORS to prevent concatenation
            let priceText = "";
            const p1 = $(el).find('.pt_v8').first().text().trim();
            const p2 = $(el).find('.price').first().text().trim();

            if (p1 && p1.includes('TL')) priceText = p1;
            else if (p2 && p2.includes('TL')) priceText = p2;
            else priceText = $(el).text();

            const price = parsePrice(priceText);

            let img = $(el).find('img').attr('src') || $(el).find('img').attr('data-src');
            const link = linkEl.attr('href');

            if (title && price > 0 && link) {
                const fullLink = link.startsWith('http') ? link : `https://www.akakce.com${link}`;
                if (img && !img.startsWith('http')) img = `https:${img}`;

                results.push({
                    title: title,
                    price: price,
                    imageUrl: img || "",
                    url: fullLink,
                    source: 'akakce',
                    sellers: JSON.stringify([{
                        merchant: "Akakçe Satıcıları",
                        price: price,
                        url: fullLink,
                        badge: "Fiyat Karşılaştır"
                    }]),
                    variants: "[]"
                });
            }
        });

        return results;

    } catch (e) {
        console.error("Akakçe Error:", e.message);
        return [];
    } finally {
        if (page) await page.close();
    }
}

function parsePrice(text) {
    if (typeof text === 'number') return text;
    if (!text) return 0;
    // Extract first valid number pattern: d.ddd,dd OR ddd,dd or ddd
    const match = text.match(/[\d\.]+,(\d{2})/); // matches 1.250,90

    let clean = "";
    if (match) {
        clean = match[0].replace(/\./g, '').replace(',', '.');
    } else {
        clean = text.replace(/[^\d,]/g, '').replace(',', '.');
    }

    return parseFloat(clean) || 0;
}

module.exports = { globalSearch };
