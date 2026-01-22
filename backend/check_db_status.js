const prisma = require('./src/config/db');

async function checkDatabase() {
    console.log("📊 Database Inspection...");

    // Count products by source
    const counts = await prisma.product.groupBy({
        by: ['source'],
        _count: { id: true }
    });
    console.log("Product counts by source:", counts);

    // Check Zara products specifically
    const zaraProducts = await prisma.product.findMany({
        where: { source: 'zara' },
        take: 20,
        orderBy: { updatedAt: 'desc' }
    });

    console.log("\n--- Latest 20 Zara Products ---");
    zaraProducts.forEach(p => {
        console.log(`[${p.id}] ${p.title} | Price: ${p.currentPrice} | Image: ${p.imageUrl ? 'YES' : 'MISSING'} | URL: ${p.url}`);
    });

    // Count missing images for Zara
    const missingImages = await prisma.product.count({
        where: { source: 'zara', imageUrl: '' }
    });
    console.log(`\nZara products with missing images: ${missingImages}`);

    // Count junk titles for Zara
    const noiseTerms = ["Ürün Başlığı Bulunamadı", "Ürün özeti", "Ürüne Git", "Klavye kısayolu"];
    const junkCount = await prisma.product.count({
        where: {
            source: 'zara',
            OR: noiseTerms.map(t => ({ title: { contains: t } }))
        }
    });
    console.log(`Zara products with junk titles: ${junkCount}`);
}

checkDatabase()
    .catch(console.error)
    .finally(async () => await prisma.$disconnect());
