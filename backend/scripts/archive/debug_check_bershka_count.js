const prisma = require('./src/config/db');

async function check() {
    const count = await prisma.product.count({
        where: { source: 'bershka' }
    });
    console.log(`Bershka Count: ${count}`);
    process.exit(0);
}

check();
