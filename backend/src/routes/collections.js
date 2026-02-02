const express = require('express');
const router = express.Router();
const prisma = require('../config/db');
const crypto = require('crypto');

// Helper to handle double-encoded strings
function safeParseJSON(input) {
    if (!input) return [];
    if (typeof input !== 'string') return Array.isArray(input) ? input : [];
    try {
        let parsed = JSON.parse(input);
        if (typeof parsed === 'string') return safeParseJSON(parsed);
        return Array.isArray(parsed) ? parsed : [];
    } catch (e) {
        return [];
    }
}

function polishProduct(p) {
    if (!p) return p;
    const currentPrice = parseFloat(p.currentPrice) || 0;
    const originalPrice = parseFloat(p.originalPrice) || currentPrice;

    return {
        ...p,
        id: parseInt(p.id),
        sellers: safeParseJSON(p.sellers),
        variants: safeParseJSON(p.variants),
        currentPrice: currentPrice,
        originalPrice: originalPrice,
        targetPrice: p.targetPrice ? parseFloat(p.targetPrice) : null,
        discountPercentage: originalPrice > currentPrice ? Math.round(((originalPrice - currentPrice) / originalPrice) * 100) : (parseFloat(p.discountPercentage) || 0),
        inStock: p.inStock ?? true,
        isSystem: p.isSystem ?? false
    };
}

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
            smart.products = previews.map(polishProduct);
        }

        const finalCollections = collections.map(c => ({
            ...c,
            products: c.products.map(polishProduct)
        }));

        res.json([...smartDefaults, ...finalCollections]);
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

// Single Collection Detail
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const userEmail = req.headers['x-user-email'] || "anonymous";
        const idInt = parseInt(id);

        if (idInt < 0) {
            // Handle System Smart Collections
            let name = "Akıllı Liste";
            let icon = "bolt";
            let where = { userEmail: userEmail };

            if (idInt === -1) {
                name = "Süper İndirimler";
                icon = "bolt.fill";
                where.discountPercentage = { gte: 30 };
            } else if (idInt === -2) {
                name = "Stokta Kalanlar";
                icon = "shippingbox.fill";
                where.inStock = true;
            }

            const products = await prisma.product.findMany({
                where,
                include: { history: { take: 10, orderBy: { checkedAt: 'desc' } } }
            });

            return res.json({
                id: idInt,
                name: name,
                icon: icon,
                type: "SMART",
                products: products.map(polishProduct),
                userEmail: "system",
                isPublic: false
            });
        }

        const collection = await prisma.collection.findUnique({
            where: { id: idInt },
            include: {
                products: {
                    include: { history: { take: 10, orderBy: { checkedAt: 'desc' } } }
                }
            }
        });

        if (!collection || collection.userEmail !== userEmail) return res.status(403).json({ error: "Unauthorized" });

        // Handle User-defined SMART logic
        if (collection.type === 'SMART' && collection.query) {
            const queryObj = JSON.parse(collection.query);
            if (queryObj.minDiscount) {
                const smartProducts = await prisma.product.findMany({
                    where: {
                        userEmail: userEmail,
                        discountPercentage: { gte: queryObj.minDiscount }
                    },
                    include: { history: { take: 10, orderBy: { checkedAt: 'desc' } } }
                });
                collection.products = smartProducts;
            }
        }

        collection.products = (collection.products || []).map(polishProduct);
        res.json(collection);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch collection" });
    }
});

module.exports = router;
