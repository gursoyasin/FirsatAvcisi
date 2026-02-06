class HealthService {
    constructor() {
        this.stats = {
            startTime: new Date(),
            totalProductsScraped: 0,
            failedScrapes: 0,
            zeroPriceParams: 0,
            lastScrapeTime: null
        };
        console.log("🩺 HealthService Initialized");
    }

    reportSuccess(count) {
        this.stats.totalProductsScraped += count;
        this.stats.lastScrapeTime = new Date();
    }

    reportFailure() {
        this.stats.failedScrapes += 1;
    }

    reportZeroPrice() {
        this.stats.zeroPriceParams += 1;
    }

    getStats() {
        const uptime = (new Date() - this.stats.startTime) / 1000;
        return {
            status: "OK",
            uptimeSeconds: uptime,
            memoryUsage: process.memoryUsage(),
            scrapers: {
                totalDetails: this.stats.totalProductsScraped,
                failures: this.stats.failedScrapes,
                zeroData: this.stats.zeroPriceParams
            }
        };
    }
}

const healthService = new HealthService();
module.exports = healthService;
