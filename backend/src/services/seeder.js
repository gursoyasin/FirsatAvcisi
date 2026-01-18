const { globalSearch } = require('./searchService');
const prisma = require('../config/db');

// MASSIVE KEYWORD LIST (Generic Terms for Volume)
const SEED_KEYWORDS = [
    // ELEKTRONİK
    "Cep Telefonu", "Akıllı Saat", "Tablet", "Laptop", "Oyuncu Bilgisayarı", "Bluetooth Kulaklık",
    "Televizyon", "Robot Süpürge", "Dikey Süpürge", "Airfryer", "Klavye", "Mouse", "Yazıcı",
    "Powerbank", "Şarj Aleti", "Ütü", "Saç Kurutma Makinesi", "Tıraş Makinesi", "Epilasyon Aleti",
    "Akıllı Bileklik", "Oyun Konsolu", "Fotoğraf Makinesi", "Drone", "Projeksiyon", "Ses Sistemi",

    // MODA (Kadın & Erkek)
    "Kadın Elbise", "Kadın Tişört", "Kadın Gömlek", "Kadın Pantolon", "Kadın Jean", "Kadın Etek",
    "Kadın Ceket", "Kadın Mont", "Kadın Kaban", "Kadın Ayakkabı", "Kadın Spor Ayakkabı", "Kadın Bot",
    "Kadın Çizme", "Kadın Terlik", "Kadın Çanta", "Kadın Cüzdan", "Kadın Saat", "Kadın Kolye",
    "Erkek Tişört", "Erkek Gömlek", "Erkek Sweatshirt", "Erkek Kazak", "Erkek Pantolon", "Erkek Jean",
    "Erkek Ceket", "Erkek Mont", "Erkek Kaban", "Erkek Takım Elbise", "Erkek Ayakkabı", "Erkek Spor Ayakkabı",
    "Erkek Bot", "Erkek Saat", "Erkek Güneş Gözlüğü", "Spor Çantası", "Valiz",

    // EV & YAŞAM
    "Yemek Takımı", "Çatal Kaşık Bıçak", "Tencere Seti", "Tava", "Düdüklü Tencere", "Çaydanlık",
    "Kahve Fincanı", "Bardak Seti", "Saklama Kabı", "Baharatlık", "Masa Örtüsü", "Runner",
    "Nevresim Takımı", "Yastık", "Yorgan", "Battaniye", "Pike", "Havlu", "Bornoz", "Banyo Paspası",
    "Halı", "Kilim", "Tül Perde", "Fon Perde", "Zebra Perde", "Avize", "Lambader", "Masa Lambası",
    "Koltuk Takımı", "Kanepe", "Sandalye", "Çalışma Masası", "Kitaplık", "TV Ünitesi", "Gardırop",

    // ANNE & BEBEK
    "Bebek Bezi", "Islak Mendil", "Bebek Şampuanı", "Bebek Arabası", "Oto Koltuğu", "Mama Sandalyesi",
    "Bebek Yatağı", "Beşik", "Biberon", "Emzik", "Göğüs Pompası", "Bebek Telsizi", "Bebek Kamerası",
    "Lego", "Barbie", "Hot Wheels", "Fisher Price", "Play-Doh", "Kutu Oyunu", "Peluş Oyuncak",
    "Akülü Araba", "Bisiklet", "Scooter",

    // KOZMETİK
    "Parfüm", "Deodorant", "Ruj", "Rimel", "Eyeliner", "Fondöten", "Kapatıcı", "Allık", "Pudra",
    "Yüz Yıkama Jeli", "Tonik", "Nemlendirici Krem", "Güneş Kremi", "Yüz Maskesi", "Serum",
    "Şampuan", "Saç Kremi", "Saç Maskesi", "Saç Boyası", "Duş Jeli", "Vücut Losyonu",
    "Diş Macunu", "Elektrikli Diş Fırçası",

    // SPOR & OUTDOOR
    "Kamp Çadırı", "Uyku Tulumu", "Mat", "Termos", "Kamp Sandalyesi", "Kamp Masası", "Fener",
    "Futbol Topu", "Basketbol Topu", "Voleybol Topu", "Tenis Raketi", "Dumbell", "Ağırlık Seti",
    "Koşu Bandı", "Kondisyon Bisikleti", "Pilates Topu", "Yoga Matı", "Spor Eldiveni",

    // HOBİ
    "Roman Kitap", "Hikaye Kitabı", "Tarih Kitabı", "Kişisel Gelişim Kitabı", "Çizgi Roman",
    "Soru Bankası", "Yapboz", "Puzzle", "Maket", "Kutu Oyunu", "Satranç", "Tavla", "Okey Takımı",
    "Gitar", "Keman", "Piyano", "Ukulele", "Melodika", "Resim Defteri", "Boya Seti",

    // OFİS & KIRTASİYE
    "Defter", "Ajanda", "Tükenmez Kalem", "Dolma Kalem", "Kurşun Kalem", "Boya Kalemi",
    "Dosya", "Klasör", "Zımba", "Delgeç", "Hesap Makinesi", "Mantar Pano", "Beyaz Tahta",
    "Ofis Koltuğu", "Ofis Masası",

    // YAPI MARKET & OTO
    "Matkap", "Vidalama", "Spiral", "Testere", "Takım Çantası", "Boya", "Fırça", "Musluk", "Batarya",
    "Duş Seti", "Oto Lastik", "Motor Yağı", "Oto Paspas", "Oto Kılıfı", "Silecek", "Cam Suyu",
    "Oto Şampuanı", "Cila",

    // PETSHOP
    "Kedi Maması", "Köpek Maması", "Kuş Yemi", "Balık Yemi", "Kedi Kumu", "Kedi Tuvaleti",
    "Tırmalama Tahtası", "Taşıma Çantası", "Kedi Yatağı", "Köpek Yatağı", "Tasma", "Mama Kabı", "Akvaryum"
];

// Shuffle array
function shuffle(array) {
    let currentIndex = array.length, randomIndex;
    while (currentIndex != 0) {
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex--;
        [array[currentIndex], array[randomIndex]] = [array[randomIndex], array[currentIndex]];
    }
    return array;
}

const runSeeder = async () => {
    console.log(`🔄 Auto-Seeder: Starting MASSIVE SCALE Job (Pool: ${SEED_KEYWORDS.length} generic terms)...`);
    const shuffledKeywords = shuffle([...SEED_KEYWORDS]);

    // Process a LARGE batch (e.g., 50 keywords at a time)
    const batch = shuffledKeywords.slice(0, 50);

    console.log(`🎯 Targeted Batch: ${batch.slice(0, 5).join(", ")}... and ${batch.length - 5} more.`);

    let addedCount = 0;

    for (const keyword of batch) {
        try {
            // Artificial delay (2s is good balance)
            await new Promise(r => setTimeout(r, 2000));

            // Search returns top 50 by default in searchService
            const results = await globalSearch(keyword);

            // TAKE ALL 50 RESULTS! (Volume mode)
            const bestResults = results; // No slicing, take all.

            for (const item of bestResults) {
                // Determine category dynamically (COPY FROM FIX SCRIPT or use simplified here)
                // We'll use the robust logic from fix_categories inside here for consistency
                let category = "diger";
                const lowerTitle = item.title.toLowerCase();
                const lowerKw = keyword.toLowerCase();

                if (matches(lowerTitle, lowerKw, ["bebek", "mama", "oyuncak", "lego", "barbie", "fisher", "biberon", "puset", "bez", "prima", "sleepy", "chicco", "çocuk", "hot wheels"])) category = "anne & bebek";
                else if (matches(lowerTitle, lowerKw, ["kedi", "köpek", "mama", "kum", "akvaryum", "tasma", "kuş", "petshop", "proplan", "royal", "whiskas", "reflex"])) category = "petshop";
                else if (matches(lowerTitle, lowerKw, ["krem", "diş", "tıraş", "maskara", "ruj", "deodorant", "parfüm", "serum", "kozmetik", "loreal", "nivea", "bakım", "şampuan", "duş", "saç", "dyson airwrap"])) category = "kozmetik";
                else if (matches(lowerTitle, lowerKw, ["nike", "adidas", "zara", "mavi", "mont", "new balance", "skechers", "rayban", "saat", "çanta", "gömlek", "sweatshirt", "pantolon", "ayakkabı", "giyim", "jean", "ceket", "kaban", "t-shirt", "bavul", "valiz", "terlik", "bot", "elbise", "etek", "kazak", "takım", "cüzdan", "kolye"])) category = "moda";
                else if (matches(lowerTitle, lowerKw, ["termos", "yemek", "nespresso", "kahve", "masa", "yastık", "nevresim", "bardak", "tava", "çay", "tost", "lamba", "halı", "mobilya", "dekor", "koltuk", "sandalye", "mutfak", "banyo", "stanley", "karaca", "paşabahçe", "tefal", "philips", "tencere", "ütü", "süpürge", "dyson", "airfryer", "fritöz", "pike", "havlu", "bornoz", "perde", "avize", "dolap", "kitaplık", "ünite"])) category = "ev"; // Dyson generic -> Ev (vacuum) unless airwrap
                else if (matches(lowerTitle, lowerKw, ["kamp", "çadır", "futbol", "spor", "koşu", "dumbell", "yoga", "bisiklet", "outdoor", "mat", "fener", "raket", "pilates"])) category = "spor & outdoor";
                else if (matches(lowerTitle, lowerKw, ["kitap", "gitar", "piyano", "puzzle", "plak", "tuval", "hobi", "roman", "müzik", "fotoğraf", "oyun", "satranç", "tavla"])) category = "hobi";
                else if (matches(lowerTitle, lowerKw, ["defter", "kalem", "boya", "kağıt", "ofis", "kırtasiye", "ajanda", "dosya", "klasör", "zımba", "pano"])) category = "ofis & kırtasiye";
                else if (matches(lowerTitle, lowerKw, ["matkap", "vidalama", "lastik", "yağ", "paspas", "musluk", "batarya", "yapı market", "oto", "bosch", "einhell", "silecek", "cam suyu"])) category = "yapı market";
                else category = "elektronik"; // Default fallback (Phones, PCs etc usually end here if not caught)

                // Refinements similar to fix script
                if (matches(lowerTitle, "", ["dyson airwrap", "dyson airstrait"])) category = "kozmetik";
                if (matches(lowerTitle, "", ["nike", "adidas"])) category = "moda";

                const existing = await prisma.product.findFirst({ where: { url: item.url } });

                if (existing) {
                    await prisma.product.update({
                        where: { id: existing.id },
                        data: {
                            currentPrice: parseFloat(item.price) || existing.currentPrice,
                            updatedAt: new Date(),
                            views: { increment: 1 },
                            sellers: typeof item.sellers === 'string' ? item.sellers : JSON.stringify(item.sellers || []),
                            variants: typeof item.variants === 'string' ? item.variants : JSON.stringify(item.variants || []),
                            category: category.toLowerCase()
                        }
                    });
                } else {
                    await prisma.product.create({
                        data: {
                            url: item.url,
                            title: item.title,
                            currentPrice: parseFloat(item.price) || 0,
                            imageUrl: item.imageUrl,
                            source: item.source,
                            isSystem: true,
                            userEmail: "system",
                            category: category.toLowerCase(),
                            inStock: true,
                            views: Math.floor(Math.random() * 50) + 10,
                            sellers: typeof item.sellers === 'string' ? item.sellers : JSON.stringify(item.sellers || []),
                            variants: typeof item.variants === 'string' ? item.variants : JSON.stringify(item.variants || [])
                        }
                    });
                    addedCount++;
                }
            }
        } catch (error) {
            console.error(`❌ Failed: ${keyword} - ${error.message}`);
        }
    }

    console.log(`✅ Auto-Seeder: MASSIVE Job finished. Added ${addedCount} new products.`);
};

// Helper
function matches(title, kw, terms) {
    return terms.some(term => title.includes(term) || kw.includes(term));
}

// 4 Hours Interval
const INTERVAL_MS = 4 * 60 * 60 * 1000;

const startAutoSeeder = () => {
    console.log("🕰️ Auto-Seeder: Online (Pool: 100+ keywords)");
    // setTimeout(runSeeder, 5000); // Optional auto-start
    setInterval(runSeeder, INTERVAL_MS);
};

module.exports = { startAutoSeeder, runSeeder };
