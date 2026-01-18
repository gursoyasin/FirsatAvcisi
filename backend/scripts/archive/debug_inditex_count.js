const prisma = require('./src/config/db');

async function checkCounts() {
    try {
        const inditexBrands = ['zara', 'bershka', 'pullandbear', 'stradivarius', 'oysho', 'massimodutti'];

        const counts = await prisma.product.groupBy({
            by: ['source'],
            where: {
                source: { in: inditexBrands }
            },
            _count: {
                id: true
            }
        });

        console.log("📊 Inditex Product Counts:");
        let total = 0;
        counts.forEach(c => {
            console.log(`- ${c.source}: ${c._count.id}`);
            total += c._count.id;
        });
        console.log(`Total: ${total}`);

        if (total === 0) {
            console.log("⚠️ No products found. Miner might be failing.");
        }

    } catch (e) {
        console.error(e);
    } finally {
        await prisma.$disconnect();
    }
}

checkCounts();
