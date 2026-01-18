const { checkWatchlistPrices } = require('./src/services/watchlistTracker');

async function testTracker() {
    console.log("🧪 Testing Watchlist Tracker...");
    await checkWatchlistPrices();
    console.log("✅ Test Complete");
    process.exit(0);
}

testTracker();
