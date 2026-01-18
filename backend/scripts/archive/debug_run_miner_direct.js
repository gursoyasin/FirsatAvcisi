const { mineInditex } = require('./src/services/inditexMiner');

async function run() {
    try {
        console.log("🚀 Manually launching miner...");
        await mineInditex();
        console.log("🏁 Miner finished.");
    } catch (e) {
        console.error("💥 Fatal Miner Error:", e);
    }
    process.exit(0);
}

run();
