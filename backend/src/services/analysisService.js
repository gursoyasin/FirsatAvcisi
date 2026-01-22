const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const analyzePrice = async (productId) => {
    const product = await prisma.product.findUnique({
        where: { id: parseInt(productId) },
        include: { history: { orderBy: { checkedAt: 'desc' }, take: 30 } } // Last 30 checks
    });

    if (!product || !product.history || product.history.length === 0) {
        return {
            recommendation: "NEW",
            confidence: 0.1,
            reason: "Bu ürünü yeni takip etmeye başladık. Analiz için biraz daha zamana ihtiyacımız var.",
            badge: "new"
        };
    }

    const history = product.history.map(h => h.price);
    const currentPrice = product.currentPrice;

    if (history.length < 2) {
        return {
            recommendation: "NEW",
            confidence: 0.2,
            reason: "Fiyat takibi başladı. Değişimleri izliyoruz.",
            badge: "new",
            stats: {
                min: product.currentPrice,
                max: product.currentPrice,
                avg: product.currentPrice
            }
        };
    }
    const minPrice = Math.min(...history);
    const maxPrice = Math.max(...history);
    const avgPrice = history.reduce((a, b) => a + b, 0) / history.length;

    let recommendation = "WAIT";
    let confidence = 0.5;
    let reason = "Fiyat dengeli görünüyor.";
    let badge = "neutral";

    if (currentPrice <= minPrice) {
        recommendation = "BUY";
        confidence = 0.95;
        reason = "Son 30 günün en düşük fiyatı! Kesinlikle kaçırma.";
        badge = "best_price";
    } else if (currentPrice < avgPrice) {
        recommendation = "BUY";
        confidence = 0.8;
        reason = "Ortalamanın altında, iyi bir fırsat.";
        badge = "good_deal";
    } else if (currentPrice > avgPrice * 1.1) {
        recommendation = "DON'T BUY";
        confidence = 0.8;
        reason = "Fiyat ortalamanın üzerinde, düşmesini bekle.";
        badge = "high_price";
    }

    return {
        recommendation,
        confidence,
        reason,
        badge,
        stats: {
            min: minPrice,
            max: maxPrice,
            avg: avgPrice
        }
    };
};

module.exports = {
    analyzePrice
};
