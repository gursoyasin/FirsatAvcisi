const prisma = require('../config/db');
const { scrapeProduct } = require('./scraper/index');

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

        console.log(`📊 Total User Products in DB: ${allUserProducts.length}`);

        const normalizedVips = VIP_EMAILS.map(e => e.toLowerCase().trim());

        // Filter based on VIP emails
        const productsToCheck = allUserProducts.filter(p => {
            if (!p.userEmail) return false;
            const email = p.userEmail.toLowerCase().trim();
            const isOwnerVIP = normalizedVips.includes(email);
            return forProUsers ? isOwnerVIP : !isOwnerVIP;
        });

        if (productsToCheck.length === 0) {
            console.log(`ℹ️ No products found for ${forProUsers ? 'PRO' : 'FREE'} tier. (Checked ${allUserProducts.length} total user products)`);
            if (allUserProducts.length > 0) {
                console.log(`🔍 Sample User Emails in DB: ${allUserProducts.slice(0, 3).map(p => p.userEmail).join(', ')}`);
            }
            return;
        }

        console.log(`📋 [${forProUsers ? 'PRO' : 'FREE'}] Checking ${productsToCheck.length} products...`);

        let browser = null;

        for (const product of productsToCheck) {
            try {
                // 2. Scrape current price using the unified scraper
                const scrapedData = await scrapeProduct(product.url);
                const currentScrapedPrice = scrapedData.currentPrice;

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

module.exports = { checkProWatchlist, checkFreeWatchlist };
