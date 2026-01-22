
const prisma = require('./src/config/db');
const { scrapeProduct } = require('./src/services/scraper');

async function repair() {
    console.log("🚀 Starting Price Repair Script...");

    // Identify products with likely corrupted prices
    // 1. currentPrice < 300 AND source is Beymen or luxury brand
    // 2. originalPrice / currentPrice > 10 (unlikely 90% discount on many items)
    const products = await prisma.product.findMany({
        where: {
            OR: [
                { source: 'beymen', currentPrice: { lt: 1000 } },
                { source: 'zara', currentPrice: { lt: 50 } },
                { currentPrice: 0 }
            ]
        }
    });

    console.log(`Found ${products.length} suspicious products to re-scrape.`);

    let successCount = 0;
    for (const product of products) {
        try {
            console.log(`🔍 Re-scraping: ${product.title} (${product.url})`);
            const newData = await scrapeProduct(product.url);

            if (newData && newData.currentPrice > 0) {
                await prisma.product.update({
                    where: { id: product.id },
                    data: {
                        currentPrice: newData.currentPrice,
                        originalPrice: newData.originalPrice || newData.currentPrice,
                        gender: product.gender || newData.gender // Keep gender if already set
                    }
                });
                console.log(`✅ Fixed: ${product.currentPrice} -> ${newData.currentPrice}`);
                successCount++;
            } else {
                console.warn(`⚠️  Scrape returned 0 for ${product.url}`);
            }
        } catch (err) {
            console.error(`❌ Error scraping ${product.url}:`, err.message);
        }
        // Small delay to prevent rate limit
        await new Promise(r => setTimeout(r, 1000));
    }

    console.log(`\n🎉 Repair finished. Successfully updated ${successCount} products.`);
    process.exit();
}

repair();
