const prisma = require('./src/config/db');

async function checkCounts() {
    const brands = ['zara', 'bershka', 'stradivarius', 'pullandbear'];
    console.log("📊 Product Counts by Brand:");
    for (const brand of brands) {
        const count = await prisma.product.count({ where: { source: brand } });
        console.log(`${brand.toUpperCase()}: ${count}`);
    }
    process.exit(0);
}

checkCounts();
