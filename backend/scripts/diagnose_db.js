const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
    try {
        const systemCount = await prisma.product.count({ where: { isSystem: true } });
        const userCount = await prisma.product.count({ where: { isSystem: false } });

        console.log('--- DB DIAGNOSTIC ---');
        console.log('System Products:', systemCount);
        console.log('User Products:', userCount);

        if (userCount > 0) {
            const sample = await prisma.product.findMany({
                where: { isSystem: false },
                take: 5,
                select: { userEmail: true, title: true }
            });
            console.log('Sample User Emails:', sample.map(p => p.userEmail));
        }
    } catch (e) {
        console.error('Check failed:', e.message);
    } finally {
        await prisma.$disconnect();
    }
}

check();
