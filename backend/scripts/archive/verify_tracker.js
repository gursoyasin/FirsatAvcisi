const prisma = require('./src/config/db');

async function checkHistory() {
    console.log("🔍 Checking Price History Data...");

    const count = await prisma.priceHistory.count();
    console.log(`📊 Total History Records: ${count}`);

    const productsWithHistory = await prisma.product.findMany({
        where: {
            history: {
                some: {} // Check if has at least one history record
            }
        },
        include: {
            history: {
                orderBy: { checkedAt: 'desc' },
                take: 5
            }
        },
        take: 5
    });

    if (productsWithHistory.length === 0) {
        console.log("⚠️ No products have price history yet.");
    } else {
        console.log("✅ Sample Products with History:");
        productsWithHistory.forEach(p => {
            console.log(`\n📦 Product: ${p.title}`);
            console.log(`   Current Price: ${p.currentPrice}`);
            console.log("   📜 History:");
            p.history.forEach(h => {
                console.log(`      - ${h.price} TL (${h.checkedAt.toISOString()})`);
            });
        });
    }
}

checkHistory();
