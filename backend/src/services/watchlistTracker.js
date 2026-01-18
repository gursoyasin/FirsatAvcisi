const prisma = require('../config/db');
const browserService = require('./scraper/BrowserService');
const cheerio = require('cheerio');

// Threshold for notification (as requested by user)
const PRICE_DROP_THRESHOLD = 100.0;

async function checkWatchlistPrices() {
    console.log("🕵️‍♂️ Starting Watchlist Price Check...");

    try {
        // 1. Fetch products that need checking
        // Exclude system products if they are managed by miners, or include them if users track them?
        // For now, let's check ALL products that are in someone's watchlist (implied by existence in Product table for MVP)
        // Optimization: In real app, check only products linked to Users via Collections or Watchlist tables.
        // Current Schema: Product has 'userEmail'.

        const productsToCheck = await prisma.product.findMany({
            where: {
                isSystem: false // Only check user-added products for now to save resources
            }
        });

        console.log(`📋 Found ${productsToCheck.length} user products to check.`);

        let browser = null;

        for (const product of productsToCheck) {
            try {
                // 2. Scrape current price
                const currentScrapedPrice = await scrapeCurrentPrice(product.url, browser);

                if (!currentScrapedPrice || currentScrapedPrice <= 0) {
                    console.log(`⚠️ Could not scrape price for ${product.id} - ${product.url}`);
                    continue;
                }

                console.log(`🔎 Product ${product.id}: Old=${product.currentPrice} New=${currentScrapedPrice}`);

                // 3. Compare with DB Price
                const priceDiff = product.currentPrice - currentScrapedPrice;

                if (priceDiff >= PRICE_DROP_THRESHOLD) {
                    console.log(`📉 PRICE DROP DETECTED! ${priceDiff} TL drop.`);

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

                    // 5. Create Alert Log (Notification)
                    await prisma.alertLog.create({
                        data: {
                            productId: product.id,
                            message: `Müjde! ${product.title.substring(0, 20)}... fiyatı ${product.currentPrice} TL'den ${currentScrapedPrice} TL'ye düştü! (${priceDiff.toFixed(2)} TL indirim)`,
                            type: 'PRICE_DROP'
                        }
                    });

                    console.log(`🔔 Notification logged for ${product.id}`);
                } else if (currentScrapedPrice !== product.currentPrice) {
                    // Update price even if drop is small or price increased, to keep data fresh
                    await prisma.product.update({
                        where: { id: product.id },
                        data: {
                            currentPrice: currentScrapedPrice,
                            updatedAt: new Date()
                        }
                    });
                    console.log(`Price updated (no alert): ${product.currentPrice} -> ${currentScrapedPrice}`);
                }

            } catch (error) {
                console.error(`❌ Error checking product ${product.id}:`, error.message);
            }
        }

    } catch (error) {
        console.error("❌ Watchlist Tracker Error:", error);
    } finally {
        console.log("🏁 Watchlist Check Completed.");
    }
}

// Simple scraper for check (can reuse Scraper service logic but simplified for speed)
async function scrapeCurrentPrice(url, browserInstance) {
    // Determine method based on URL (PttAVM, Trendyol, Hepsiburada need Puppeteer)
    // For MVP, we use the BrowserService for everything to be safe against blocking
    let page;
    try {
        page = await browserService.createPage();
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });

        // Generic selector logic (simplified from main scraper)
        // We can inject a script to find the price or use common selectors
        const content = await page.content();
        const $ = cheerio.load(content);

        // Try common price selectors
        const selectors = [
            '.product-price', '.price', '.prc-dsc', '.current-price',
            '[data-testid="price"]', '.product-price-container',
            '.price-current'
        ];

        let price = 0;
        for (const sel of selectors) {
            const text = $(sel).first().text().trim();
            if (text) {
                price = parsePrice(text);
                if (price > 0) break;
            }
        }

        await page.close();
        return price;

    } catch (e) {
        if (page) await page.close();
        console.error(`Scrape failed for ${url}: ${e.message}`);
        return 0;
    }
}

function parsePrice(text) {
    if (!text) return 0;
    // Remove default currency symbols
    let clean = text.replace('TL', '').replace('₺', '').replace('TRY', '').trim();
    // Handle European style 1.200,50
    clean = clean.replace(/\./g, '').replace(',', '.');
    // Extract first valid number
    const match = clean.match(/(\d+\.?\d*)/);
    return match ? parseFloat(match[0]) : 0;
}

module.exports = { checkWatchlistPrices };
