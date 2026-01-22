const prisma = require('../src/config/db');

async function main() {
    console.log("💰 Inspecting Prices...");

    const brands = ["zara", "bershka", "pullandbear", "stradivarius", "massimodutti", "oysho"];

    for (const brand of brands) {
        const product = await prisma.product.findFirst({
            where: { source: brand },
            orderBy: { createdAt: 'desc' } // Get latest
        });

        if (product) {
            console.log(`\n🏷️ ${brand.toUpperCase()}:`);
            console.log(`   Title: ${product.title}`);
            console.log(`   Price: ${product.currentPrice} TL`);
            console.log(`   Original: ${product.originalPrice} TL`);
            console.log(`   Image: ${product.imageUrl ? product.imageUrl.substring(0, 50) + "..." : "NONE"}`);
        } else {
            console.log(`\n❌ ${brand.toUpperCase()}: No products found.`);
        }
    }

    await prisma.$disconnect();
}

main();
