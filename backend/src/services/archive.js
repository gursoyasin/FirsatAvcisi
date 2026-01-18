const prisma = require('../config/db');

/**
 * PriceHistory tablosunu seyreltir ve optimize eder.
 * Binlerce kontrol kaydı yerine zamanla sadece kritik verileri saklar.
 */
async function runArchiving() {
    console.log("📂 Veri arşivleme süreci başlatıldı...");

    try {
        const now = new Date();
        const sevenDaysAgo = new Date(now.getTime() - (7 * 24 * 60 * 60 * 1000));
        const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000));

        // 1. 30 Günden eski kayıtları günlük tek bir kayda (en düşük fiyat) indirge
        await aggregateOldHistory(thirtyDaysAgo);

        // 2. 7-30 gün arası kayıtları seyrelt
        // (Bu kısım opsiyoneldir, ihtiyaca göre daha karmaşık seyreltme eklenebilir)

        console.log("✅ Arşivleme başarıyla tamamlandı.");
    } catch (error) {
        console.error("❌ Arşivleme hatası:", error);
    }
}

async function aggregateOldHistory(olderThanDate) {
    // SQL bazlı operasyon Prisma ile zor olduğu için ham sorgu kullanabiliriz 
    // Veya JS tarafında işleyebiliriz. Performans için ham sorgu (raw query) daha iyidir.

    // SQLite kullandığımız için ona uygun ham sorgu:
    // Her gün için en düşük fiyatlı kaydı bulup diğerlerini siliyoruz.

    try {
        // Bu örnek bir mantıktır; prodüksiyonda daha güvenli bir partition yapısı önerilir.
        console.log(`${olderThanDate.toISOString()} tarihinden eski veriler optimize ediliyor...`);

        // Önce silinecek ID'leri belirleyelim (günlük minimum olmayanlar)
        // Not: SQLite'da karmaşık analitik fonksiyonlar kısıtlı olabilir.

        const histories = await prisma.priceHistory.findMany({
            where: {
                createdAt: { lt: olderThanDate }
            },
            orderBy: { createdAt: 'asc' }
        });

        if (histories.length === 0) return;

        // Ürün ve Gün bazlı gruplandırma
        const groups = {};
        histories.forEach(h => {
            const dateStr = h.createdAt.toISOString().split('T')[0];
            const key = `${h.productId}_${dateStr}`;
            if (!groups[key] || h.price < groups[key].price) {
                groups[key] = h;
            }
        });

        const keptIds = Object.values(groups).map(h => h.id);
        const allOldIds = histories.map(h => h.id);
        const toDeleteIds = allOldIds.filter(id => !keptIds.includes(id));

        if (toDeleteIds.length > 0) {
            // Büyük silme işlemlerini parçalara bölmek iyi bir pratiktir
            const batchSize = 100;
            for (let i = 0; i < toDeleteIds.length; i += batchSize) {
                const batch = toDeleteIds.slice(i, i + batchSize);
                await prisma.priceHistory.deleteMany({
                    where: { id: { in: batch } }
                });
            }
            console.log(`🗑️ ${toDeleteIds.length} eski geçmiş kaydı silindi.`);
        }

    } catch (e) {
        console.error("Aggregation failed:", e);
    }
}

module.exports = { runArchiving };
