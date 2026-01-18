const prisma = require('./src/config/db');

async function checkDistribution() {
    const products = await prisma.product.findMany({
        where: { isSystem: true, inStock: true }
    });

    const byBrand = {};
    const byCategory = {};

    products.forEach(p => {
        // Brand count
        byBrand[p.source] = (byBrand[p.source] || 0) + 1;

        // Category count
        byCategory[p.category] = (byCategory[p.category] || 0) + 1;
    });

    console.log("📊 Brand Distribution:");
    console.table(byBrand);

    console.log("\n🏷️ Category Distribution:");
    console.table(byCategory);
}

checkDistribution();
