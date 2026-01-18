const express = require('express');
const router = express.Router();
const prisma = require('../config/db');

// Get History for a Product
router.get('/:productId', async (req, res) => {
    try {
        const { productId } = req.params;
        const history = await prisma.priceHistory.findMany({
            where: { productId: parseInt(productId) },
            orderBy: { checkedAt: 'asc' }
        });
        res.json(history);
    } catch (e) { res.status(500).json({ error: "Failed" }); }
});

module.exports = router;
