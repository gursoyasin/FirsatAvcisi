const express = require('express');
const router = express.Router();
const prisma = require('../config/db');

// Register for notifications
router.post('/register', async (req, res) => {
    try {
        const { token, deviceType } = req.body;
        const userEmail = req.headers['x-user-email'];
        if (!userEmail || !token) return res.status(400).json({ error: "Missing data" });

        await prisma.device.upsert({
            where: { token: token },
            update: { lastActiveAt: new Date(), userEmail },
            create: { token, deviceType: deviceType || 'ios', userEmail }
        });
        res.json({ message: "Device registered" });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/', async (req, res) => {
    try {
        const userEmail = req.headers['x-user-email'];
        if (!userEmail) return res.status(400).json({ error: "User email required" });

        const alerts = await prisma.alertLog.findMany({
            where: {
                product: { userEmail: userEmail }
            },
            include: { product: { select: { title: true, imageUrl: true } } },
            orderBy: { createdAt: 'desc' },
            take: 20
        });

        res.json(alerts);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Failed" });
    }
});

module.exports = router;
