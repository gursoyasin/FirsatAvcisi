const prisma = require('./src/config/db');

// Helper: Derive Category from Title (Turkish)
function deriveCategory(title) {
    if (!title) return 'Moda';
    const lower = title.toLowerCase();

    if (lower.includes('elbise')) return 'Elbise';
    if (lower.includes('ceket') || lower.includes('blazer')) return 'Ceket';
    if (lower.includes('tişört') || lower.includes('t-shirt') || lower.includes('top')) return 'Tişört';
    if (lower.includes('pantolon') || lower.includes('jean') || lower.includes('tayt')) return 'Pantolon';
    if (lower.includes('kaban') || lower.includes('mont') || lower.includes('pardesü') || lower.includes('trench')) return 'Dış Giyim';
    if (lower.includes('kazak') || lower.includes('hırka') || lower.includes('triko')) return 'Kazak';
    if (lower.includes('gömlek') || lower.includes('bluz')) return 'Gömlek';
    if (lower.includes('şapka') || lower.includes('bere')) return 'Şapka';
    if (lower.includes('ayakkabı') || lower.includes('bot') || lower.includes('çizme') || lower.includes('sneaker')) return 'Ayakkabı';
    if (lower.includes('çanta') || lower.includes('cüzdan')) return 'Çanta';
    if (lower.includes('sweatshirt') || lower.includes('hoodie')) return 'Sweatshirt';
    if (lower.includes('etek') || lower.includes('şort')) return 'Etek/Şort';

    return 'Moda'; // Fallback
}

async function fixCategories() {
    console.log("🛠 Starting Category Migration...");

    const products = await prisma.product.findMany({
        where: { isSystem: true }
    });

    console.log(`Found ${products.length} system products.`);

    let updated = 0;
    for (const p of products) {
        const newCat = deriveCategory(p.title);

        // Only update if generic or different
        if (p.category === 'moda' || p.category !== newCat) {
            await prisma.product.update({
                where: { id: p.id },
                data: { category: newCat }
            });
            updated++;
            if (updated % 10 === 0) process.stdout.write('.');
        }
    }

    console.log(`\n✅ Updated ${updated} products.`);
    process.exit(0);
}

fixCategories();
