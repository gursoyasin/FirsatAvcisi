const prisma = require('../src/config/db');

async function main() {
    console.log("🧹 Starting Deep Warning Cleanup & Verification...");

    // 1. Cleanup Invalid Images
    const badImages = await prisma.product.deleteMany({
        where: { OR: [{ imageUrl: null }, { imageUrl: "" }] }
    });
    if (badImages.count > 0) console.log(`✅ Deleted ${badImages.count} products without images.`);

    // 2. Cleanup Invalid Prices
    const badPrices = await prisma.product.deleteMany({
        where: { currentPrice: { lte: 1 } }
    });
    if (badPrices.count > 0) console.log(`✅ Deleted ${badPrices.count} products with invalid prices (<= 1 TL).`);

    // 3. Cleanup Duplicate URLs (Keep latest)
    // This is hard in Prisma without raw SQL, skipping for now.

    // 4. Verify Brand Counts
    console.log("\n📊 Brand Inventory Status:");
    const brands = [
        "zara", "bershka", "pullandbear", "stradivarius", "massimodutti", "oysho"
    ];

    for (const brand of brands) {
        const count = await prisma.product.count({
            where: { source: brand }
        });

        const status = count > 0 ? "✅ OK" : "⚠️ EMPTY";
        // Check image quality stats
        const withImage = await prisma.product.count({
            where: { source: brand, imageUrl: { not: "" } }
        });

        console.log(`${brand.padEnd(15)}: ${count} products (${withImage} valid images) ${status}`);
    }

    const total = await prisma.product.count();
    console.log(`\n📦 Total Products: ${total}`);

    await prisma.$disconnect();
}

main().catch(e => {
    console.error(e);
    process.exit(1);
});
