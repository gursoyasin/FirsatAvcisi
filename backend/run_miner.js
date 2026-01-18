
const { mineInditex } = require('./src/services/inditexMiner');
const prisma = require('./src/config/db');

async function run() {
    console.log("Starting Manual Mining Trigger...");
    try {
        await mineInditex();
    } catch (error) {
        console.error("Mining Failed:", error);
    } finally {
        await prisma.$disconnect();
        process.exit(0);
    }
}

run();
