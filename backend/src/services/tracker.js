const prisma = require('../config/db');
const { scrapeProduct } = require('./scraper/index');
// Notification logic moved to Queue Worker to decouple
const { runArchiving } = require('./archive');
const queueService = require('./queue/QueueService');

// Improve Performance: Check every 5 minutes instead of 30 for faster updates
const CHECK_INTERVAL_MS = 1000 * 60 * 5;
const ARCHIVE_INTERVAL_MS = 1000 * 60 * 60 * 24; // Once a day

async function startPriceTracker() {
    console.log("🚀 Fiyat takip motoru başlatıldı... (Her 5 dakikada bir)");

    // Initial check
    checkAllProducts();
    runArchiving();

    setInterval(async () => {
        console.log("⏰ Periodik fiyat kontrolü başlıyor...");
        await checkAllProducts();
    }, CHECK_INTERVAL_MS);

    // Schedule Archiving & Hygiene
    setInterval(async () => {
        await runArchiving();
        const { checkZombies } = require('./monitor/HygieneService');
        await checkZombies();
    }, ARCHIVE_INTERVAL_MS);
}

const pLimit = require('p-limit');

async function checkAllProducts() {
    try {
        const products = await prisma.product.findMany();
        console.log(`📦 Toplam ${products.length} ürün kontrol edilecek.`);

        // Limit concurrency to 5 parallel tasks to avoid CPU spikes and IP bans
        const limit = pLimit(5);

        const tasks = products.map((product) => {
            return limit(async () => {
                await checkSingleProduct(product);
            });
        });

        await Promise.all(tasks);
        console.log("✅ Tüm ürünlerin kontrolü tamamlandı.");
    } catch (error) {
        console.error("Genel Tracker Hatası:", error);
    }
}

async function checkSingleProduct(product) {
    try {
        console.log(`🔍 Kontrol ediliyor: ${product.title}`);
        const newData = await scrapeProduct(product.url);

        let priceChanged = newData.currentPrice !== product.currentPrice;

        // Stock logic remains simple, no need for complex queue yet unless requested
        let stockChanged = (!product.inStock && newData.inStock);

        if (priceChanged || stockChanged) {
            console.log(`Update Detected for ${product.title}`);

            // 1. Record History (only if price changed)
            if (priceChanged) {
                await prisma.priceHistory.create({
                    data: {
                        productId: product.id,
                        price: newData.currentPrice
                    }
                });
            }

            // 2. Queue Notification Logic (Event-Driven)
            if (newData.currentPrice < product.currentPrice) {
                // OLD: await handlePriceDrop(product, product.currentPrice, newData.currentPrice);
                // NEW: Queue it!
                queueService.add('PRICE_DETECTED', {
                    product: product,
                    currentPrice: product.currentPrice,
                    newPrice: newData.currentPrice
                });
            } else if (stockChanged) {
                // For now stock alerts can also be queued or kept direct. Queuing is safer.
                // queueService.add('STOCK_DETECTED', ...);
                // Keeping simple for now as per plan focus on Price
                const { handleStockAlert } = require('./notification');
                await handleStockAlert(product, newData.currentPrice);
            }

            // 3. Update Product State
            const updateData = {
                currentPrice: newData.currentPrice,
                inStock: newData.inStock,
                updatedAt: new Date()
            };

            // Calculate Discount Percentage (Real Logic)
            if (product.originalPrice && product.originalPrice > newData.currentPrice) {
                const discount = ((product.originalPrice - newData.currentPrice) / product.originalPrice) * 100;
                updateData.discountPercentage = Math.round(discount);
            } else {
                updateData.discountPercentage = 0;
            }

            if (newData.currentPrice < product.currentPrice) {
                updateData.lastPriceDropAt = new Date();
            }

            // 4. Comparison Check
            updateAlternatives(product, newData.currentPrice);

            await prisma.product.update({
                where: { id: product.id },
                data: {
                    ...updateData,
                    scanCount: { increment: 1 } // 🔥 Metric Update
                }
            });

        } else {
            console.log(`✅ Değişiklik yok: ${product.currentPrice} TL - ${product.title}`);
            // Even if no price change, we scanned it. value++
            await prisma.product.update({
                where: { id: product.id },
                data: {
                    updatedAt: new Date(),
                    scanCount: { increment: 1 }
                }
            });
        }

        // Adaptive delay based on concurrency
        const delay = Math.floor(Math.random() * 2000) + 1000;
        await new Promise(r => setTimeout(r, delay));

    } catch (err) {
        console.error(`❌ Ürün kontrol hatası (${product.id} - ${product.title}):`, err.message);
    }
}

async function updateAlternatives(product, currentPrice) {
    try {
        const { findAlternatives } = require('./comparison');
        const searchQuery = product.title.split(' ').slice(0, 5).join(' ');
        const alternatives = await findAlternatives(searchQuery, product.source);

        if (alternatives && alternatives.length > 0) {
            const best = alternatives.sort((a, b) => a.price - b.price)[0];
            const bestPrice = best.price;
            const bestSource = best.market;

            await prisma.product.update({
                where: { id: product.id },
                data: {
                    bestAlternativePrice: bestPrice < currentPrice ? bestPrice : null,
                    bestAlternativeSource: bestPrice < currentPrice ? bestSource : null
                }
            });
        }
    } catch (e) {
        console.error("Alternative update failed:", e.message);
    }
}

module.exports = { startPriceTracker };
