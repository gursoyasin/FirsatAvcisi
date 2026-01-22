const prisma = require('./src/config/db');

const PRODUCTS = [
    // --- ZARA ---
    {
        title: "KEMERLİ KISA TRENÇKOT",
        url: "https://www.zara.com/tr/tr/kemerli-kisa-trenckot-p03046032.html",
        imageUrl: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=800&auto=format&fit=crop",
        category: "Dış Giyim",
        source: "zara",
        currentPrice: 1299.95,
        originalPrice: 1999.95,
    },
    {
        title: "YÜKSEK BEL PANTOLON",
        url: "https://www.zara.com/tr/tr/yuksek-bel-pantolon-p07385223.html",
        imageUrl: "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?q=80&w=800&auto=format&fit=crop",
        category: "Pantolon",
        source: "zara",
        currentPrice: 899.95,
        originalPrice: 1199.95,
    },
    {
        title: "BASIC KAZAK",
        url: "https://www.zara.com/tr/tr/basic-kazak-p05536134.html",
        imageUrl: "https://images.unsplash.com/photo-1576566588028-4147f3842f27?q=80&w=800&auto=format&fit=crop",
        category: "Kazak",
        source: "zara",
        currentPrice: 499.95,
        originalPrice: 699.95,
    },
    {
        title: "Keten Gömlek",
        url: "https://www.zara.com/tr/tr/keten-gomlek-p08574123.html",
        imageUrl: "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?q=80&w=800&auto=format&fit=crop",
        category: "Gömlek",
        source: "zara",
        currentPrice: 699.95,
        originalPrice: 999.95,
    },
    {
        title: "Crop Blazer",
        url: "https://www.zara.com/tr/tr/crop-blazer-p02145345.html",
        imageUrl: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=800&auto=format&fit=crop",
        category: "Ceket",
        source: "zara",
        currentPrice: 1199.95,
        originalPrice: 1499.95,
    },
    {
        title: "Desenli Midi Elbise",
        url: "https://www.zara.com/tr/tr/desenli-midi-elbise-p09999999.html",
        imageUrl: "https://images.unsplash.com/photo-1612336307429-8a898d10e223?q=80&w=800&auto=format&fit=crop",
        category: "Elbise",
        source: "zara",
        currentPrice: 899.95,
        originalPrice: 1299.95,
    },
    {
        title: "Deri Görünümlü Ceket",
        url: "https://www.zara.com/tr/tr/deri-ceket-p08888888.html",
        imageUrl: "https://images.unsplash.com/photo-1551028919-ac66e6a39d44?q=80&w=800&auto=format&fit=crop",
        category: "Ceket",
        source: "zara",
        currentPrice: 1599.95,
        originalPrice: 1999.95,
    },

    // --- BERSHKA ---
    {
        title: "Paraşüt pantolon",
        url: "https://www.bershka.com/tr/parasut-pantolon-c0p150777583.html",
        imageUrl: "https://images.unsplash.com/photo-1511556820780-d912e42b4980?q=80&w=800&auto=format&fit=crop",
        category: "Pantolon",
        source: "bershka",
        currentPrice: 699.95,
        originalPrice: 999.95,
    },
    {
        title: "Oversize kolej ceketi",
        url: "https://www.bershka.com/tr/oversize-kolej-ceketi-c0p136587004.html",
        imageUrl: "https://images.unsplash.com/photo-1551028919-ac66e6a39d44?q=80&w=800&auto=format&fit=crop",
        category: "Ceket",
        source: "bershka",
        currentPrice: 999.95,
        originalPrice: 1499.95,
    },
    {
        title: "Baskılı T-Shirt",
        url: "https://www.bershka.com/tr/baskili-tshirt-c0p123456.html",
        imageUrl: "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?q=80&w=800&auto=format&fit=crop",
        category: "Tişört",
        source: "bershka",
        currentPrice: 299.95,
        originalPrice: 459.95,
    },
    {
        title: "Kargo Pantolon",
        url: "https://www.bershka.com/tr/kargo-pantolon-c0p987654.html",
        imageUrl: "https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?q=80&w=800&auto=format&fit=crop",
        category: "Pantolon",
        source: "bershka",
        currentPrice: 759.95,
        originalPrice: 999.95,
    },
    {
        title: "Platform Spor Ayakkabı",
        url: "https://www.bershka.com/tr/platform-ayakkabi-c0p112233.html",
        imageUrl: "https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=800&auto=format&fit=crop",
        category: "Ayakkabı",
        source: "bershka",
        currentPrice: 899.95,
        originalPrice: 1299.95,
    },

    // --- PULL & BEAR ---
    {
        title: "Basic kapüşonlu sweatshirt",
        url: "https://www.pullandbear.com/tr/basic-kapusonlu-sweatshirt-l04591321",
        imageUrl: "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?q=80&w=800&auto=format&fit=crop",
        category: "Sweatshirt",
        source: "pullandbear",
        currentPrice: 459.95,
        originalPrice: 699.95,
    },
    {
        title: "Straight fit jeans",
        url: "https://www.pullandbear.com/tr/straight-fit-jeans-l09683515",
        imageUrl: "https://images.unsplash.com/photo-1542272454315-4c01d7abdf4a?q=80&w=800&auto=format&fit=crop",
        category: "Pantolon",
        source: "pullandbear",
        currentPrice: 599.95,
        originalPrice: 899.95,
    },
    {
        title: "Kanguru Cepli Hoodie",
        url: "https://www.pullandbear.com/tr/kanguru-hoodie-l0123456",
        imageUrl: "https://images.unsplash.com/photo-1618221639890-413d74c8ec6b?q=80&w=800&auto=format&fit=crop",
        category: "Sweatshirt",
        source: "pullandbear",
        currentPrice: 559.95,
        originalPrice: 799.95,
    },
    {
        title: "Bomber Ceket",
        url: "https://www.pullandbear.com/tr/bomber-ceket-l0654321",
        imageUrl: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=800&auto=format&fit=crop",
        category: "Ceket",
        source: "pullandbear",
        currentPrice: 899.95,
        originalPrice: 1199.95,
    },

    // --- STRADIVARIUS ---
    {
        title: "Suni deri trençkot",
        url: "https://www.stradivarius.com/tr/suni-deri-trenckot-l01844327",
        imageUrl: "https://images.unsplash.com/photo-1550614000-4b9519e090e7?q=80&w=800&auto=format&fit=crop",
        category: "Dış Giyim",
        source: "stradivarius",
        currentPrice: 1599.95,
        originalPrice: 2299.95,
    },
    {
        title: "Mini Pileli Etek",
        url: "https://www.stradivarius.com/tr/mini-etek-l0998877",
        imageUrl: "https://images.unsplash.com/photo-1582142327529-e8544e3da7a9?q=80&w=800&auto=format&fit=crop",
        category: "Etek/Şort",
        source: "stradivarius",
        currentPrice: 459.95,
        originalPrice: 699.95,
    },
    {
        title: "Kovboy Botu",
        url: "https://www.stradivarius.com/tr/kovboy-botu-l0444555",
        imageUrl: "https://images.unsplash.com/photo-1542280756-74fc290234a4?q=80&w=800&auto=format&fit=crop",
        category: "Ayakkabı",
        source: "stradivarius",
        currentPrice: 1199.95,
        originalPrice: 1599.95,
    },

    // --- OYSHO ---
    {
        title: "Comfortlux tayt",
        url: "https://www.oysho.com/tr/comfortlux-tayt-l03099900",
        imageUrl: "https://images.unsplash.com/photo-1506619216599-9d16d0903dfd?q=80&w=800&auto=format&fit=crop",
        category: "Spor",
        source: "oysho",
        currentPrice: 799.95,
        originalPrice: 999.95,
    },
    {
        title: "Spor Sütyeni",
        url: "https://www.oysho.com/tr/spor-sutyeni-l0223344",
        imageUrl: "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=800&auto=format&fit=crop",
        category: "Spor",
        source: "oysho",
        currentPrice: 599.95,
        originalPrice: 799.95,
    },

    // --- MASSIMO DUTTI ---
    {
        title: "Yün karışımlı kaban",
        url: "https://www.massimodutti.com/tr/yun-karisimli-kaban-l06403640",
        imageUrl: "https://images.unsplash.com/photo-1539533113208-f6df8cc8b543?q=80&w=800&auto=format&fit=crop",
        category: "Dış Giyim",
        source: "massimodutti",
        currentPrice: 4999.95,
        originalPrice: 6999.95,
    },
    {
        title: "İpek Gömlek",
        url: "https://www.massimodutti.com/tr/ipek-gomlek-l0777777",
        imageUrl: "https://images.unsplash.com/photo-1598532163257-ae3c6b2524b6?q=80&w=800&auto=format&fit=crop",
        category: "Gömlek",
        source: "massimodutti",
        currentPrice: 2499.95,
        originalPrice: 3299.95,
    },

    // --- H&M (Bonus) ---
    {
        title: "Regular Fit Hoodie",
        url: "https://www2.hm.com/tr_tr/productpage.12345678.html",
        imageUrl: "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?q=80&w=800&auto=format&fit=crop",
        category: "Sweatshirt",
        source: "hm",
        currentPrice: 399.99,
        originalPrice: 599.99,
    },
    {
        title: "Kargo Jean",
        url: "https://www2.hm.com/tr_tr/productpage.87654321.html",
        imageUrl: "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?q=80&w=800&auto=format&fit=crop",
        category: "Pantolon",
        source: "hm",
        currentPrice: 799.99,
        originalPrice: 1099.99,
    },

    // --- MANGO (Bonus) ---
    {
        title: "Kruvaze Yaka Ceket",
        url: "https://shop.mango.com/tr/kadin/ceket-kruvaze_1234.html",
        imageUrl: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=800&auto=format&fit=crop",
        category: "Ceket",
        source: "mango",
        currentPrice: 1499.99,
        originalPrice: 2499.99,
    },
    {
        title: "Desenli Şifon Elbise",
        url: "https://shop.mango.com/tr/kadin/elbise-sifon_5678.html",
        imageUrl: "https://images.unsplash.com/photo-1612336307429-8a898d10e223?q=80&w=800&auto=format&fit=crop",
        category: "Elbise",
        source: "mango",
        currentPrice: 899.99,
        originalPrice: 1299.99,
    }
];

async function seed() {
    console.log("🌱 Seeding MASSIVE Amount of Data...");

    for (const p of PRODUCTS) {
        try {
            // Upsert based on URL to avoid duplicates but update content
            const existing = await prisma.product.findFirst({ where: { url: p.url } });
            if (existing) {
                await prisma.product.update({
                    where: { id: existing.id },
                    data: { ...p, isSystem: true, inStock: true, lastPriceDropAt: new Date(), views: Math.floor(Math.random() * 5000) }
                });
                console.log(`🔄 Updated: ${p.title}`);
            } else {
                await prisma.product.create({
                    data: {
                        ...p,
                        userEmail: "system",
                        isSystem: true,
                        inStock: true,
                        lastPriceDropAt: new Date(),
                        views: Math.floor(Math.random() * 5000)
                    }
                });
                console.log(`✅ Added: ${p.title}`);
            }
        } catch (e) {
            console.error("Failed:", e.message);
        }
    }
    console.log("DONE. Database populated with diverse brands.");
}

seed();
