const prisma = require('./src/config/db');

async function cleanup() {
    console.log("🧹 Cleaning up noise products...");

    const noiseTerms = [
        "Ürün Başlığı Bulunamadı", "Ürün özeti", "Ürüne Git",
        "Klavye kısayolu", "Shift", "alt", "opt"
    ];

    let deleted = 0;
    const all = await prisma.product.findMany();

    for (const p of all) {
        if (noiseTerms.some(t => p.title.includes(t)) || p.title.length < 5) {
            await prisma.product.delete({ where: { id: p.id } });
            deleted++;
            console.log(`🗑️ Deleted noise: ${p.title}`);
        }
    }

    console.log(`✅ Deleted ${deleted} noise products.`);
}

cleanup()
    .catch(console.error)
    .finally(async () => await prisma.$disconnect());
