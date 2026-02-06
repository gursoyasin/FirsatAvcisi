const prisma = require('../../config/db');

class HygieneService {
    async checkZombies() {
        // Definition of a "Zombie":
        // 1. Not updated in 10 days (Tracker failed continuously)
        // 2. Out of stock for > 90 days
        // 3. Price unchanged for > 180 days (Dead deal)

        const tenDaysAgo = new Date();
        tenDaysAgo.setDate(tenDaysAgo.getDate() - 10);

        const zombies = await prisma.product.findMany({
            where: {
                updatedAt: { lt: tenDaysAgo },
                status: 'ACTIVE'
            }
        });

        console.log(`🧟 Found ${zombies.length} potential zombie products.`);

        // Auto-tag them for review
        if (zombies.length > 0) {
            await prisma.product.updateMany({
                where: { id: { in: zombies.map(z => z.id) } },
                data: { status: 'ZOMBIE' }
            });
        }

        return zombies.length;
    }
}

module.exports = new HygieneService();
