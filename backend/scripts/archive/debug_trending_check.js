const prisma = require('./src/config/db');

async function checkTrendingCandidates() {
    try {
        const total = await prisma.product.count();
        const system = await prisma.product.count({ where: { isSystem: true, inStock: true } });
        const hotDeals = await prisma.product.count({ where: { isSystem: true, inStock: true, lastPriceDropAt: { not: null } } });

        console.log(`Total Products: ${total}`);
        console.log(`System & InStock (Candidates): ${system}`);
        console.log(`Hot Deals (Price Drop): ${hotDeals}`);

        // Peek at some candidates
        const candidates = await prisma.product.findMany({
            where: { isSystem: true, inStock: true },
            take: 5,
            select: { id: true, title: true, source: true, category: true }
        });
        console.log("Sample Candidates:", candidates);

    } catch (e) {
        console.error(e);
    } finally {
        await prisma.$disconnect();
    }
}

checkTrendingCandidates();
