const { mineInditex } = require('./backend/src/services/inditexMiner');
const prisma = require('./backend/src/config/db');

async function testZara() {
    console.log("🚀 Starting Targeted Zara Mining Test...");

    // We can't easily filter TARGETS inside inditexMiner from here without modifying it more, 
    // but I'll just run the whole thing once for this test or I'll modify the loop temporarily.

    try {
        await mineInditex();

        const count = await prisma.product.count({ where: { source: 'zara', isSystem: true } });
        console.log(`📊 Total Zara System Products now: ${count}`);

        const samples = await prisma.product.findMany({
            where: { source: 'zara', isSystem: true },
            take: 5
        });

        console.log("🔍 Sample Data:");
        samples.forEach(s => {
            console.log(`- ${s.title}: ${s.imageUrl} (${s.url})`);
        });

    } catch (e) {
        console.error("❌ Test failed:", e);
    } finally {
        await prisma.$disconnect();
    }
}

testZara();
