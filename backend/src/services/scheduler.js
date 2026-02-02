const cron = require('node-cron');
const { mineAllBrands } = require('./dailyMiner');
const { checkProWatchlist, checkFreeWatchlist } = require('./watchlistTracker');
const prisma = require('../config/db');

function startScheduler() {
    console.log("⏳ Scheduler Started: Global Mining (6h), PRO Checker (15m), FREE Checker (3h)");

    // 1. Global Mining (Every 6 hours)
    // DISABLED for Eco Mode (User Request)
    // cron.schedule('0 0,6,12,18 * * *', async () => {
    //     console.log("⏰ [GLOBAL] Mining Cycle Started...");
    //     await mineAllBrands();
    // });

    // 2. PRO Watchlist Check (Every 15 minutes)
    cron.schedule('*/15 * * * *', async () => {
        // console.log("⏰ [PRO] Watchlist Check Cycle...");
        await checkProWatchlist();
    });

    // 3. FREE Watchlist Check (Every 3 hours)
    cron.schedule('0 */3 * * *', async () => {
        console.log("⏰ [FREE] Watchlist Check Cycle...");
        await checkFreeWatchlist();
    });

    // Run ONCE on startup (delayed 10s) to fill DB if empty
    // Run ONCE on startup (delayed 10s) to fill DB if empty
    // DISABLED for Eco Mode
    // setTimeout(async () => {
    //     const count = await prisma.product.count({ where: { isSystem: true } });
    //     if (count < 1000) { // Increased threshold to force re-run for population
    //         console.log("📉 DB Fill check: Starting immediate mining to ensure freshness...");
    //         mineAllBrands();
    //     }
    // }, 10000);
}

module.exports = { startScheduler };
