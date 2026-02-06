const prisma = require('../../config/db');

class PriceAnalysisService {

    /**
     * Main entry point: Generates a full strategy report for a product.
     */
    async analyze(product) {
        if (!product.history || product.history.length < 2) {
            return {
                advice: "WAIT_DATA",
                confidence: 0,
                reason: "Yeterli veri toplanıyor..."
            };
        }

        const prices = product.history.map(h => h.price);
        const currentPrice = product.currentPrice;
        const minPrice = Math.min(...prices);
        const maxPrice = Math.max(...prices);
        const avgPrice = prices.reduce((a, b) => a + b, 0) / prices.length;

        // Strategy Logic
        let recommendation = "WAIT";
        let confidence = 50;
        let reason = "";

        // 1. All Time Low Check
        if (currentPrice <= minPrice) {
            recommendation = "BUY";
            confidence = 95;
            reason = "Tarihi dip fiyat! Daha düşme ihtimali çok düşük.";
        }
        // 2. Good Deal Check (Below Average)
        else if (currentPrice < avgPrice) {
            const drop = ((avgPrice - currentPrice) / avgPrice) * 100;
            if (drop > 15) {
                recommendation = "BUY";
                confidence = 80;
                reason = `Ortalamadan %${drop.toFixed(0)} daha ucuz. İyi bir fırsat.`;
            } else {
                recommendation = "WAIT";
                confidence = 60;
                reason = "Fiyat ortalamanın biraz altında ama daha da düşebilir.";
            }
        }
        // 3. Bad Deal Check
        else {
            recommendation = "WAIT";
            confidence = 90;
            reason = `Fiyat şu an yüksek. Genelde ${minPrice} TL seviyesine düşüyor.`;
        }

        return {
            advice: recommendation,
            confidence: confidence,
            reason: reason,
            stats: {
                minPrice,
                maxPrice,
                avgPrice: Math.round(avgPrice),
                totalScans: product.scanCount,
                daysTracked: this.calculateDaysTracked(product.firstTrackedAt)
            }
        };
    }

    calculateDaysTracked(date) {
        if (!date) return 0;
        const diff = new Date() - new Date(date);
        return Math.floor(diff / (1000 * 60 * 60 * 24));
    }

    calculateTimeSaved(scanCount) {
        // Assumption: It takes 2 minutes to manualy check a site
        const minutes = scanCount * 2;
        const hours = (minutes / 60).toFixed(1);
        return {
            minutesSaved: minutes,
            message: `${scanCount} kez tarandı. ${hours} saat kazandın.`
        };
    }
}

module.exports = new PriceAnalysisService();
