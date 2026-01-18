async function testMiner() {
    try {
        console.log("🚀 Triggering Miner (REAL MODE)...");
        const { mineInditex } = require('./src/services/inditexMiner');

        // We will just run for 20 seconds to give it time to process Bershka
        const miningPromise = mineInditex();

        console.log("Miner started. Waiting 30s...");
        await new Promise(r => setTimeout(r, 30000));

        console.log("✅ Done waiting. Check logs above.");
        process.exit(0);

    } catch (error) {
        console.error("❌ Miner Failed:", error);
    }
}

testMiner();
