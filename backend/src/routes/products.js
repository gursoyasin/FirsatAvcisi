const express = require('express');
const router = express.Router();
const prisma = require('../config/db'); // Ensure this points to correct db instance
const { scrapeProduct } = require('../services/scraper');
const { lookupBarcode } = require('../services/barcode');
const { findAlternatives } = require('../services/comparison');
const { analyzePrice } = require('../services/analysisService');

// Helper to handle double-encoded strings
function safeParseJSON(input) {
    if (!input) return [];
    if (typeof input !== 'string') return input;
    try {
        let parsed = JSON.parse(input);
        if (typeof parsed === 'string') return safeParseJSON(parsed);
        return parsed;
    } catch (e) {
        return [];
    }
}

const VIP_EMAILS = [
    "yasin@example.com",
    "gursoyreal@gmail.com",
    "keskinezgi26@outlook.com"
];

// --- TRIGGER MINER (CLOUD) ---
router.post('/inditex/mine', async (req, res) => {
    try {
        const { mineInditex } = require('../services/inditexMiner');
        console.log("🚀 Remote Miner Triggered!");
        // Run in background (fire and forget)
        mineInditex().catch(err => console.error("Mining crashed:", err));
        res.json({ message: "Inditex Miner started in background on server." });
    } catch (error) {
        console.error("Miner start failed:", error);
        res.status(500).json({ error: "Failed to start miner" });
    }
});
// -----------------------------

// 1. Get All Products (User Specific)
router.get('/', async (req, res) => {
    try {
        let userEmail = req.headers['x-user-email'];
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const skip = (page - 1) * limit;

        if (!userEmail) return res.status(400).json({ error: "User email header missing" });

        userEmail = userEmail.toLowerCase().trim();
        console.log(`🔍 Fetching products for: ${userEmail}`);

        const [products, total] = await Promise.all([
            prisma.product.findMany({
                where: { userEmail: userEmail },
                include: { history: true },
                orderBy: { createdAt: 'desc' },
                skip: skip,
                take: limit
            }),
            prisma.product.count({ where: { userEmail: userEmail } })
        ]);

        res.json({
            products,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to fetch products' });
    }
});

// 1.5 Get Single Product (Moved to bottom)

// 2. Add Product
router.post('/', async (req, res) => {
    try {
        let { url, title, price, imageUrl, source, inStock, originalPrice, targetPrice } = req.body;
        let productData = { url, title, price, imageUrl, source, inStock, originalPrice };

        if (!title && url) {
            console.log("Auto-scraping for Quick Add:", url);
            try {
                let scraped = await scrapeProduct(url);

                // Handle Redirect (e.g. from Search Page)
                if (scraped.title === "REDIRECT_REQUIRED" && scraped.url) {
                    console.log("Validation Redirect detected. Re-scraping proper product URL:", scraped.url);
                    // Update URL to the real product URL
                    url = scraped.url;
                    scraped = await scrapeProduct(url);
                }

                productData = { ...productData, ...scraped };
            } catch (err) {
                console.error("Auto-scrape failed:", err);
                return res.status(400).json({ error: "Link analiz edilemedi." });
            }
        } else if (!url) {
            return res.status(400).json({ error: "URL required" });
        }

        const numericPrice = parseFloat(productData.price) || 0;
        const rawEmail = req.headers['x-user-email'] || "anonymous";
        const userEmail = rawEmail.toLowerCase().trim();
        const isPremium = VIP_EMAILS.includes(userEmail);

        if (!isPremium) {
            const count = await prisma.product.count({ where: { userEmail: userEmail } });
            if (count >= 3) return res.status(403).json({ error: "LIMIT_REACHED", message: "Ücretsiz plan limiti doldu. Premium'a geçin!" });
        }

        // SANITIZE: Remove 'price' field which conflicts with Prisma schema ('currentPrice' is used)
        delete productData.price;

        const product = await prisma.product.create({
            data: {
                ...productData,
                currentPrice: numericPrice,
                originalPrice: parseFloat(productData.originalPrice) || 0,
                targetPrice: targetPrice ? parseFloat(targetPrice) : null,
                userEmail: userEmail,
                category: productData.category || "diger",
                history: { create: { price: numericPrice } }
            }
        });
        res.json(product);
    } catch (error) {
        console.error("Save error:", error);
        res.status(500).json({ error: error.message });
    }
});

const { getHeartFeed, getDailyPick } = require('../services/dailyFeedService');

router.get('/trending', async (req, res) => {
    try {
        const userEmail = req.headers['x-user-email'];
        let gender = null;
        if (userEmail) {
            const user = await prisma.user.findUnique({ where: { email: userEmail.toLowerCase() } });
            gender = user ? user.gender : null;
        }

        const heartFeed = await getHeartFeed(gender);
        res.json(heartFeed);
    } catch (error) {
        console.error("Trending Error:", error);
        res.status(500).json({ error: "Failed to fetch trending" });
    }
});

// ...

// 6. Inditex Feed (Used for "Senin Tarzın" Daily Pick)
router.get('/inditex/feed', async (req, res) => {
    try {
        const { brand } = req.query;
        const userEmail = req.headers['x-user-email'];
        let gender = null;
        if (userEmail) {
            const user = await prisma.user.findUnique({ where: { email: userEmail.toLowerCase() } });
            gender = user ? user.gender : null;
        }

        const normalizedSource = brand && brand !== 'Hepsi' ? brand.toLowerCase().replace(/&/g, 'and').replace(/\s+/g, '') : undefined;

        const whereClause = {
            isSystem: true,
            inStock: true,
            source: normalizedSource
        };

        // Only apply gender filter if NO specific brand is selected (General Feed)
        if (!normalizedSource) {
            whereClause.OR = [
                { gender: gender },
                { gender: 'unisex' },
                { gender: null }
            ];
        }

        const products = await prisma.product.findMany({
            where: whereClause,
            orderBy: [{ originalPrice: { sort: 'desc', nulls: 'last' } }, { createdAt: 'desc' }],
            take: 100
        });

        // Sort to put user's gender at the TOP
        if (gender) {
            products.sort((a, b) => {
                if (a.gender === gender && b.gender !== gender) return -1;
                if (a.gender !== gender && b.gender === gender) return 1;
                return 0;
            });
        }

        const polished = products.slice(0, 50).map(p => ({
            ...p,
            discountPercentage: p.originalPrice > p.currentPrice ? Math.round(((p.originalPrice - p.currentPrice) / p.originalPrice) * 100) : 0
        }));

        res.json(polished);
    } catch (error) {
        res.status(500).json({ error: "Feed failed" });
    }
});

// 7. Preview & Barcode
router.post('/barcode', async (req, res) => {
    try {
        const { barcode } = req.body;
        if (!barcode) return res.status(400).json({ error: "Barcode required" });

        const result = await lookupBarcode(barcode);

        // Return as a preview-compatible object
        res.json({
            title: result.title,
            currentPrice: 0,
            imageUrl: "",
            source: 'search',
            url: result.url
        });
    } catch (error) {
        console.error("Barcode route failed:", error);
        res.status(500).json({ error: "Barkod sorgulama başarısız." });
    }
});

router.post('/preview', async (req, res) => {
    try {
        const { url } = req.body;
        const data = await scrapeProduct(url);
        res.json(data);
    } catch (error) {
        console.error("Preview Crash Prevented:", error);
        // CRITICAL: Send valid JSON instead of 500 to prevent app crash
        res.json({
            title: "Bağlantı Sorunu",
            currentPrice: 0,
            imageUrl: "",
            source: 'unknown',
            url: req.body.url,
            error: true
        });
    }
});

// 8. Delete & Batch Delete
router.delete('/:id', async (req, res) => {
    try {
        await prisma.product.delete({ where: { id: parseInt(req.params.id) } });
        res.json({ message: "Deleted" });
    } catch (e) { res.status(500).json({ error: "Failed" }); }
});

router.post('/batch-delete', async (req, res) => {
    try {
        const { ids } = req.body;
        const userEmail = req.headers['x-user-email'];
        await prisma.product.deleteMany({
            where: { id: { in: ids.map(i => parseInt(i)) }, userEmail }
        });
        res.json({ message: "Batch deleted" });
    } catch (e) { res.status(500).json({ error: "Failed" }); }
});

// 9. Set Target Price
router.post('/:id/target', async (req, res) => {
    try {
        const { targetPrice } = req.body;
        const id = parseInt(req.params.id);

        await prisma.product.update({
            where: { id: id },
            data: { targetPrice: parseFloat(targetPrice) }
        });

        console.log(`🎯 Target Price Set: ID ${id} -> ${targetPrice} TL`);
        res.json({ message: "Target price set" });
    } catch (e) {
        console.error("Target Price set failed:", e);
        res.status(500).json({ error: "Failed to set target price" });
    }
});

// 1.5 Get Single Product (Moved to bottom)
// 10. Analysis
router.get('/:id/analysis', async (req, res) => {
    try {
        const analysis = await analyzePrice(req.params.id);
        res.json(analysis);
    } catch (e) {
        res.status(500).json({ error: "Analysis failed" });
    }
});

// 11. Alternatives
router.get('/:id/alternatives', async (req, res) => {
    try {
        const product = await prisma.product.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!product) return res.status(404).json({ error: "Product not found" });

        const alternatives = await findAlternatives(product.title, product.source);
        res.json(alternatives);
    } catch (e) {
        res.status(500).json({ error: "Alternatives failed" });
    }
});

router.get('/:id', async (req, res) => {
    try {
        const product = await prisma.product.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { history: true }
        });
        if (!product) return res.status(404).json({ error: "Not found" });
        res.json(product);
    } catch (e) { res.status(500).json({ error: "Failed" }); }
});

module.exports = router;
