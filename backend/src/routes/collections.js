const express = require('express');
const router = express.Router();
const prisma = require('../config/db');
const crypto = require('crypto');

// Get Collections (with Smart logic)
router.get('/', async (req, res) => {
    try {
        const userEmail = req.headers['x-user-email'] || "anonymous";
        let collections = await prisma.collection.findMany({
            where: { userEmail: userEmail },
            include: {
                _count: { select: { products: true } },
                products: { take: 4, select: { imageUrl: true, currentPrice: true } }
            }
        });

        // Default Smart Collections
        const smartDefaults = [
            { id: -1, name: "Süper İndirimler", icon: "bolt.fill", type: "SMART", query: JSON.stringify({ minDiscount: 30 }), userEmail: "system", isPublic: false, shareToken: null, _count: { products: 0 }, products: [] },
            { id: -2, name: "Stokta Kalanlar", icon: "shippingbox.fill", type: "SMART", query: JSON.stringify({ inStock: true }), userEmail: "system", isPublic: false, shareToken: null, _count: { products: 0 }, products: [] }
        ];

        // Populate Smart Counts (Simplified for MVP)
        for (const smart of smartDefaults) {
            const query = JSON.parse(smart.query);
            let where = { userEmail: userEmail };
            if (query.minDiscount) where.discountPercentage = { gte: query.minDiscount };
            if (query.inStock) where.inStock = true;

            const count = await prisma.product.count({ where });
            const previews = await prisma.product.findMany({ where, take: 4, select: { imageUrl: true, currentPrice: true } });

            smart._count.products = count;
            smart.products = previews;
        }

        res.json([...smartDefaults, ...collections]);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch collections" });
    }
});

// Create Collection
router.post('/', async (req, res) => {
    try {
        const { name, icon, type, query } = req.body;
        const userEmail = req.headers['x-user-email'] || "anonymous";
        const collection = await prisma.collection.create({
            data: { name, userEmail, icon: icon || "folder", type: type || "MANUAL", query: query || null }
        });
        res.json(collection);
    } catch (error) {
        res.status(500).json({ error: "Failed to create collection" });
    }
});

// Update Collection
router.patch('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, icon, isPublic, type, query } = req.body;
        let updateData = { name, icon, isPublic, type, query };

        if (isPublic) {
            const current = await prisma.collection.findUnique({ where: { id: parseInt(id) } });
            if (current && !current.shareToken) updateData.shareToken = crypto.randomBytes(8).toString('hex');
        }

        const updated = await prisma.collection.update({ where: { id: parseInt(id) }, data: updateData });
        res.json(updated);
    } catch (error) {
        res.status(500).json({ error: "Failed to update" });
    }
});

// Add/Remove Products
router.post('/:id/products', async (req, res) => {
    try {
        await prisma.collection.update({
            where: { id: parseInt(req.params.id) },
            data: { products: { connect: { id: parseInt(req.body.productId) } } }
        });
        res.json({ message: "Added" });
    } catch (e) { res.status(500).json({ error: "Failed" }); }
});

router.delete('/:id/products/:productId', async (req, res) => {
    try {
        await prisma.collection.update({
            where: { id: parseInt(req.params.id) },
            data: { products: { disconnect: { id: parseInt(req.params.productId) } } }
        });
        res.json({ message: "Removed" });
    } catch (e) { res.status(500).json({ error: "Failed" }); }
});

module.exports = router;
