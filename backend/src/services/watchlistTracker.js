const prisma = require('../config/db');
const browserService = require('./scraper/BrowserService');
const cheerio = require('cheerio');

// Hardcoded VIP List (Synced with user.js)
const VIP_EMAILS = [
    "yasin@example.com",
    "gursoyreal@gmail.com",
    "keskinezgi26@outlook.com"
];

// Threshold for notification
const PRICE_DROP_THRESHOLD = 50.0; // More sensitive

// Wrapper for PRO users (Every 15 mins)
async function checkProWatchlist() {
    console.log("💎 [PRO] Starting Watchlist Check...");
    await checkWatchlistPrices(true);
}

// Wrapper for FREE users (Every 3 hours)
async function checkFreeWatchlist() {
    console.log("👤 [FREE] Starting Watchlist Check...");
    await checkWatchlistPrices(false);
}

async function checkWatchlistPrices(forProUsers) {
    try {
        // 1. Fetch products based on user tier
        // We fetch ALL user products first because Prisma SQLite doesn't support basic array filtering easily on string fields without a User model.
        // For MVP efficiency, we'll fetch 'isSystem: false' and filter in JS. 
        // Ideally, we'd have a User model relation.

        const allUserProducts = await prisma.product.findMany({
            where: { isSystem: false }
        });

        // Filter based on VIP emails
        const productsToCheck = allUserProducts.filter(p => {
            const isOwnerVIP = VIP_EMAILS.includes(p.userEmail?.toLowerCase().trim());
            return forProUsers ? isOwnerVIP : !isOwnerVIP;
        });

        if (productsToCheck.length === 0) {
            console.log(`ℹ️ No products found for ${forProUsers ? 'PRO' : 'FREE'} tier.`);
            return;
        }

        console.log(`📋 [${forProUsers ? 'PRO' : 'FREE'}] Checking ${productsToCheck.length} products...`);

        let browser = null;

        for (const product of productsToCheck) {
            try {
                // 2. Scrape current price
                const currentScrapedPrice = await scrapeCurrentPrice(product.url);

                if (!currentScrapedPrice || currentScrapedPrice <= 0) {
                    console.log(`⚠️ Could not scrape price for ${product.id} - ${product.url}`);
                    continue;
                }

                // console.log(`🔎 Product ${product.id}: Old=${product.currentPrice} New=${currentScrapedPrice}`);

                // 3. Compare with DB Price
                const priceDiff = product.currentPrice - currentScrapedPrice;

                // Price Drop Logic
                if (priceDiff >= PRICE_DROP_THRESHOLD) {
                    console.log(`📉 PRICE DROP DETECTED! ${priceDiff} TL drop for ${product.userEmail}`);

                    // 4. Update DB
                    await prisma.product.update({
                        where: { id: product.id },
                        data: {
                            currentPrice: currentScrapedPrice,
                            lastPriceDropAt: new Date(),
                            history: {
                                create: {
                                    price: currentScrapedPrice
                                }
                            }
                        }
                    });

                    // 5. Create Alert Log
                    await prisma.alertLog.create({
                        data: {
                            productId: product.id,
                            message: `Müjde! ${product.title.substring(0, 20)}... fiyatı ${product.currentPrice} TL'den ${currentScrapedPrice} TL'ye düştü!`,
                            type: 'PRICE_DROP'
                        }
                    });

                    console.log(`🔔 Notification logged for ${product.id}`);
                }
                // Price Change (Increase or Small Drop) - Just Update
                else if (currentScrapedPrice !== product.currentPrice) {
                    await prisma.product.update({
                        where: { id: product.id },
                        data: {
                            currentPrice: currentScrapedPrice,
                            updatedAt: new Date()
                        }
                    });
                    console.log(`🔄 Price updated (no alert): ${product.currentPrice} -> ${currentScrapedPrice}`);
                }

            } catch (error) {
                console.error(`❌ Error checking product ${product.id}:`, error.message);
            }
        }

    } catch (error) {
        console.error("❌ Watchlist Tracker Error:", error);
    }
}

// Simple scraper for check
async function scrapeCurrentPrice(url) {
    let page;
    try {
        page = await browserService.createPage();
        // Faster timeout for tracker
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });

        const content = await page.content();
        const $ = cheerio.load(content);

        // Try common price selectors
        const selectors = [
            '.product-price', '.price', '.prc-dsc', '.current-price',
            '[data-testid="price"]', '.product-price-container',
            '.price-current', '.m-productPrice__salePrice', '.product__price--sale'
        ];

        let price = 0;
        for (const sel of selectors) {
            const text = $(sel).first().text().trim();
            if (text) {
                price = parsePrice(text);
                if (price > 0) break;
            }
        }

        // Generic text search fallback
        if (price === 0) {
            const bodyText = $('body').text();
            const cleanText = bodyText.replace(/\s+/g, ' ');
            // Look for Turkish Price Format (1.250,90 TL or 1250 TL) heavily
            const matches = cleanText.match(/(\d{1,3}(?:[.,]\d{3})*)\s*(?:TL|TRY)/ig);
            if (matches && matches.length > 0) {
                // Takes the first logical price found that is reasonable?
                // This is risky, but better than 0 for tracker.
                // Let's filter for prices found near "price" keywords if possible, but for now just parse first.
                price = parsePrice(matches[0]);
            }
        }

        await page.close();
        return price;

    } catch (e) {
        if (page) await page.close();
        return 0;
    }
}

function parsePrice(text) {
    if (!text) return 0;
    let clean = text.replace('TL', '').replace('₺', '').replace('TRY', '').trim();
    if (clean.includes(',') && clean.includes('.')) {
        if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
            clean = clean.replace(/\./g, '').replace(',', '.');
        } else {
            clean = clean.replace(/,/g, '');
        }
    } else if (clean.includes(',')) {
        clean = clean.replace(',', '.');
    }
    const match = clean.match(/(\d+\.?\d*)/);
    return match ? parseFloat(match[0]) : 0;
}

module.exports = { checkProWatchlist, checkFreeWatchlist };
