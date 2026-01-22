const express = require('express');
const router = express.Router();

const VIP_EMAILS = [
    "yasin@example.com",
    "gursoyreal@gmail.com",
    "keskinezgi26@outlook.com" // manitam
];

const prisma = require('../config/db');

// Check User Status (Manual VIP) - Mounts at /api/user/status
router.get('/status', async (req, res) => {
    try {
        let userEmail = req.headers['x-user-email'];
        if (!userEmail) {
            return res.json({ isPremium: false, gender: null, type: 'FREE' });
        }

        userEmail = userEmail.trim().toLowerCase();

        // Get user from DB
        const user = await prisma.user.findUnique({ where: { email: userEmail } });

        const isManualVIP = VIP_EMAILS.map(e => e.toLowerCase()).includes(userEmail);

        res.json({
            isPremium: isManualVIP || false,
            type: isManualVIP ? 'MANUAL_VIP' : 'FREE',
            gender: user ? user.gender : null,
            brands: user ? (user.brands ? JSON.parse(user.brands) : []) : []
        });
    } catch (error) {
        console.error("Status check error:", error);
        res.status(500).json({ error: "Status check failed" });
    }
});

// Update Profile (Gender) - Mounts at /api/user/profile
router.post('/profile', async (req, res) => {
    try {
        let userEmail = req.headers['x-user-email'];
        const { gender, brands } = req.body;

        if (!userEmail) return res.status(401).json({ error: "Email required" });

        userEmail = userEmail.trim().toLowerCase();

        const updateData = {};
        if (gender) updateData.gender = gender.toLowerCase();
        if (brands) updateData.brands = JSON.stringify(brands);

        const user = await prisma.user.upsert({
            where: { email: userEmail },
            update: updateData,
            create: { email: userEmail, ...updateData }
        });

        res.json(user);
    } catch (error) {
        console.error("Profile update error:", error);
        res.status(500).json({ error: "Profile update failed" });
    }
});

module.exports = router;
