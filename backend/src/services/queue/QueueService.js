const EventEmitter = require('events');

class QueueService extends EventEmitter {
    constructor() {
        super();
        this.jobs = [];
        console.log("🚀 QueueService Initialized (Event-Driven Mode)");

        // Setup Event Listeners
        this.on('PRICE_DETECTED', this.handlePriceDetected);
        this.on('JOB_COMPLETED', this.handleJobCompleted);
        this.on('JOB_FAILED', this.handleJobFailed);
    }

    // Add job to the "queue" (In V1, it just emits immediately, but structure is ready for Redis)
    add(jobType, data) {
        console.log(`📥 Job Added: ${jobType}`);
        this.emit(jobType, data);
    }

    async handlePriceDetected(data) {
        // Decoupled logic: Here we import the Notification Service
        // This prevents circular dependencies and allows separating processes later
        const { product, newPrice } = data;

        try {
            console.log(`⚡️ Processing Job: PRICE_DETECTED for ${product.title}`);
            const { handlePriceDrop } = require('../notification');

            // "Worker" logic
            await handlePriceDrop(product, product.currentPrice, newPrice);

            this.emit('JOB_COMPLETED', { jobType: 'PRICE_DETECTED', productId: product.id });
        } catch (error) {
            console.error(`❌ Job Failed: ${error.message}`);
            this.emit('JOB_FAILED', { jobType: 'PRICE_DETECTED', error: error.message });
        }
    }

    handleJobCompleted(info) {
        console.log(`✅ Job Completed: ${info.jobType}`);
    }

    handleJobFailed(info) {
        console.error(`⚠️ Job Error: ${info.error}`);
    }
}

// Singleton Instance
const queueService = new QueueService();
module.exports = queueService;
