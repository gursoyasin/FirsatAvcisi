const prisma = require('./src/config/db');

async function verify() {
    console.log("📊 Verifying Database Content...");

    // Total Count
    const total = await prisma.product.count();
    console.log(`✅ Total Products: ${total}`);

    const electronics = await prisma.product.findMany({
        where: { category: 'elektronik' },
        take: 50,
        select: { title: true }
    });

    console.log("\n⚡ Elektronik Category Analysis:");
    electronics.forEach(p => console.log(`   - ${p.title}`));

    // Category Breakdown
    const categories = await prisma.product.groupBy({
        by: ['category'],
        _count: {
            id: true
        }
    });

    console.log("\n📂 Category Breakdown:");
    categories.forEach(c => {
        console.log(`   - ${c.category}: ${c._count.id}`);
    });

    const digerProducts = await prisma.product.findMany({
        where: { category: 'diger' },
        take: 20,
        select: { title: true }
    });

    console.log("\n🕵️‍♀️ Analyzing 'diger' (potential missed categories):");
    digerProducts.forEach(p => console.log(`   - ${p.title}`));
}

verify()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
