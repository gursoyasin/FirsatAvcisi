const prisma = require('./src/config/db');

async function checkExpansion() {
    const products = await prisma.product.findMany({
        where: {
            isSystem: true,
            inStock: true
        }
    });

    const categoryCounts = {};
    const brandCounts = {};

    products.forEach(p => {
        categoryCounts[p.category] = (categoryCounts[p.category] || 0) + 1;
        brandCounts[p.source] = (brandCounts[p.source] || 0) + 1;
    });

    console.log("\n📊 Updated Brand Distribution:");
    console.table(brandCounts);

    console.log("\n🏷️ Updated Category Distribution:");
    console.log("--------------------------------");
    Object.entries(categoryCounts)
        .sort((a, b) => b[1] - a[1]) // Sort by count desc
        .forEach(([cat, count]) => {
            console.log(`${cat}: ${count}`);
        });
}

checkExpansion();
