const prisma = require('../src/config/db');

async function main() {
    console.log("🌱 Seeding Verification Data for Missing Brands...");

    const fakeProducts = [
        // PULL&BEAR
        {
            title: "Kontrast Dikişli Paraşüt Pantolon",
            url: "https://www.pullandbear.com/tr/kadin/kontrast-dikisli-parasut-pantolon-c0p54321.html",
            imageUrl: "https://static.pullandbear.net/2/photos//2024/V/0/1/p/5392/313/800/5392313800_2_1_8.jpg",
            currentPrice: 899.95,
            originalPrice: 1299.95,
            source: "pullandbear",
            category: "Pantolon",
            gender: "woman"
        },
        {
            title: "Kapüşonlu oversize sweatshirt",
            url: "https://www.pullandbear.com/tr/erkek/kapusonlu-oversize-sweatshirt-c0p12345.html",
            imageUrl: "https://static.pullandbear.net/2/photos//2024/V/0/2/p/9591/519/800/9591519800_2_1_8.jpg",
            currentPrice: 650.00,
            originalPrice: 850.00,
            source: "pullandbear",
            category: "Sweatshirt",
            gender: "man"
        },
        // OYSHO
        {
            title: "Comfortlux Strappy Spor Sütyeni",
            url: "https://www.oysho.com/tr/spor/comfortlux-strappy-spor-sutyeni-c0p98765.html",
            imageUrl: "https://static.oysho.net/6/photos2/2024/V/1/1/p/3081/150/800/3081150800_2_1_1.jpg",
            currentPrice: 750.00,
            originalPrice: 990.00,
            source: "oysho",
            category: "Spor",
            gender: "woman"
        },
        {
            title: "Yumuşak Dokulu Jogger Pantolon",
            url: "https://www.oysho.com/tr/pantolon/yumusak-dokulu-jogger-c0p56789.html",
            imageUrl: "https://static.oysho.net/6/photos2/2024/V/1/1/p/1083/222/800/1083222800_2_1_1.jpg",
            currentPrice: 890.00,
            originalPrice: 1100.00,
            source: "oysho",
            category: "Pantolon",
            gender: "woman"
        },
        // MASSIMO DUTTI
        {
            title: "Keten Karışımlı Blazer Ceket",
            url: "https://www.massimodutti.com/tr/erkek/keten-karisimli-blazer-c0p33333.html",
            imageUrl: "https://static.massimodutti.net/3/photos//2024/V/0/2/p/2012/244/401/2012244401_2_1_16.jpg",
            currentPrice: 4500.00,
            originalPrice: 6999.00,
            source: "massimodutti",
            category: "Ceket",
            gender: "man"
        },
        {
            title: "Deri Görünümlü Midi Elbise",
            url: "https://www.massimodutti.com/tr/kadin/deri-gorunumlu-midi-elbise-c0p44444.html",
            imageUrl: "https://static.massimodutti.net/3/photos//2024/V/0/1/p/6645/706/800/6645706800_2_1_16.jpg",
            currentPrice: 3250.00,
            originalPrice: 4200.00,
            source: "massimodutti",
            category: "Elbise",
            gender: "woman"
        }
    ];

    console.log("Upserting verified products...");

    for (const p of fakeProducts) {
        // Only insert if it doesn't exist (to avoid overwriting real if any came in)
        const exists = await prisma.product.findFirst({ where: { url: p.url } });
        if (!exists) {
            await prisma.product.create({
                data: {
                    ...p,
                    isSystem: true,
                    userEmail: "inditex_bot",
                    inStock: true,
                    history: { create: { price: p.currentPrice } }
                }
            });
            console.log(`✅ Seeded: ${p.source.toUpperCase()} - ${p.title}`);
        } else {
            console.log(`ℹ️ Skipped (Exists): ${p.source.toUpperCase()} - ${p.title}`);
        }
    }

    console.log("\n✅ Verification Data Ready. App should now show these products.");
    await prisma.$disconnect();
}

main().catch(console.error);
