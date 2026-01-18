const express = require('express');
const router = express.Router();
const prisma = require('../config/db'); // Ensure this points to correct db instance
const { scrapeProduct } = require('../services/scraper');
const { lookupBarcode } = require('../services/barcode'); // Assuming validation
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
        const userEmail = req.headers['x-user-email'];
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const skip = (page - 1) * limit;

        if (!userEmail) return res.status(400).json({ error: "User email header missing" });

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
        let { url, title, price, imageUrl, source, inStock, originalPrice } = req.body;
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
        const userEmail = req.headers['x-user-email'] || "anonymous";
        const isPremium = VIP_EMAILS.includes(userEmail);

        if (!isPremium) {
            const count = await prisma.product.count({ where: { userEmail: userEmail } });
            if (count >= 3) return res.status(403).json({ error: "LIMIT_REACHED", message: "Ücretsiz plan limiti doldu. Premium'a geçin!" });
        }

        const product = await prisma.product.create({
            data: {
                ...productData,
                currentPrice: numericPrice,
                originalPrice: parseFloat(productData.originalPrice) || 0,
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

// 3. Trending Products
router.get('/trending', async (req, res) => {
    try {
        const { category } = req.query;
        console.log(`🔥 TRENDING REQUEST: Category=${category}`);

        // Logic same as original api.js but cleaner?
        // For brevity, replicating the core logic
        const hotProducts = await prisma.product.findMany({
            where: {
                isSystem: true,
                inStock: true,
                lastPriceDropAt: { not: null },
                // Exclude Inditex & Fashion Brands from Home Page
                source: { notIn: ['zara', 'bershka', 'pullandbear', 'stradivarius', 'oysho', 'massimodutti', 'zarahome', 'lefties', 'hm', 'mango'] },
                // Also exclude TrendyolMilla (if title contains it) - simple heuristic for now
                NOT: { title: { contains: 'TrendyolMilla' } },
                // Advanced Category Filtering
                ...(category && category !== 'Hepsi' ? (() => {
                    const cleanCat = category.toLowerCase();
                    console.log(`🔎 Filtering for: ${cleanCat}`);
                    if (cleanCat === 'telefon') {
                        console.log("✅ Applying TELEFON filter");
                        return {
                            OR: [
                                { category: 'telefon' }, // Specific category
                                // Remove category constraint and add variations
                                { title: { contains: 'telefon' } }, { title: { contains: 'Telefon' } },
                                { title: { contains: 'iphone' } }, { title: { contains: 'iPhone' } },
                                { title: { contains: 'samsung' } }, { title: { contains: 'Samsung' } },
                                { title: { contains: 'android' } }, { title: { contains: 'Android' } },
                                { title: { contains: 'redmi' } }, { title: { contains: 'Redmi' } },
                                { title: { contains: 'xiaomi' } }, { title: { contains: 'Xiaomi' } }
                            ]
                        };
                    }
                    if (cleanCat === 'bilgisayar') {
                        return {
                            OR: [
                                { category: 'bilgisayar' },
                                { title: { contains: 'bilgisayar' } }, { title: { contains: 'Bilgisayar' } },
                                { title: { contains: 'laptop' } }, { title: { contains: 'Laptop' } },
                                { title: { contains: 'macbook' } }, { title: { contains: 'Macbook' } }, { title: { contains: 'MacBook' } },
                                { title: { contains: 'notebook' } }, { title: { contains: 'Notebook' } },
                                { title: { contains: 'dizüstü' } }, { title: { contains: 'Dizüstü' } },
                                { title: { contains: 'tablet' } }, { title: { contains: 'Tablet' } },
                                { title: { contains: 'ipad' } }, { title: { contains: 'iPad' } }
                            ]
                        };
                    }
                    if (cleanCat === 'market') {
                        return {
                            OR: [
                                { category: 'market' },
                                { category: 'ev' },
                                { category: 'gida' },
                                { category: 'süpermarket' }
                            ]
                        };
                    }
                    if (cleanCat === 'spor') {
                        return {
                            OR: [
                                { category: 'spor' },
                                { title: { contains: 'spor' } }, { title: { contains: 'Spor' } },
                                { title: { contains: 'kamp' } }, { title: { contains: 'Kamp' } },
                                { title: { contains: 'outdoor' } }, { title: { contains: 'Outdoor' } },
                                { title: { contains: 'fitness' } }, { title: { contains: 'Fitness' } },
                                { title: { contains: 'eşofman' } }, { title: { contains: 'Eşofman' } }
                            ]
                        };
                    }
                    if (cleanCat === 'moda') {
                        return { category: 'moda' };
                    }
                    if (cleanCat === 'kozmetik') {
                        return { category: 'kozmetik' };
                    }
                    // Fallback for generic categories
                    return { category: cleanCat };
                })() : {})
            },
            take: 10,
            orderBy: { lastPriceDropAt: 'desc' }
        });

        const systemProducts = await prisma.product.findMany({
            where: {
                isSystem: true, inStock: true, id: { notIn: hotProducts.map(p => p.id) },
                ...(category && category !== 'Hepsi' ? (() => {
                    const cleanCat = category.toLowerCase();
                    if (cleanCat === 'telefon') {
                        return {
                            OR: [
                                { category: 'telefon' }, // Specific category
                                // Remove category constraint and add variations
                                { title: { contains: 'telefon' } }, { title: { contains: 'Telefon' } },
                                { title: { contains: 'iphone' } }, { title: { contains: 'iPhone' } },
                                { title: { contains: 'samsung' } }, { title: { contains: 'Samsung' } },
                                { title: { contains: 'android' } }, { title: { contains: 'Android' } },
                                { title: { contains: 'redmi' } }, { title: { contains: 'Redmi' } },
                                { title: { contains: 'xiaomi' } }, { title: { contains: 'Xiaomi' } }
                            ]
                        };
                    }
                    if (cleanCat === 'bilgisayar') {
                        return {
                            OR: [
                                { category: 'bilgisayar' },
                                { title: { contains: 'bilgisayar' } }, { title: { contains: 'Bilgisayar' } },
                                { title: { contains: 'laptop' } }, { title: { contains: 'Laptop' } },
                                { title: { contains: 'macbook' } }, { title: { contains: 'Macbook' } }, { title: { contains: 'MacBook' } },
                                { title: { contains: 'notebook' } }, { title: { contains: 'Notebook' } },
                                { title: { contains: 'dizüstü' } }, { title: { contains: 'Dizüstü' } },
                                { title: { contains: 'tablet' } }, { title: { contains: 'Tablet' } },
                                { title: { contains: 'ipad' } }, { title: { contains: 'iPad' } }
                            ]
                        };
                    }
                    if (cleanCat === 'market') {
                        return {
                            OR: [
                                { category: 'market' },
                                { category: 'ev' },
                                { category: 'gida' },
                                { category: 'süpermarket' }
                            ]
                        };
                    }
                    if (cleanCat === 'spor') {
                        return {
                            OR: [
                                { category: 'spor' },
                                { title: { contains: 'spor' } }, { title: { contains: 'Spor' } },
                                { title: { contains: 'kamp' } }, { title: { contains: 'Kamp' } },
                                { title: { contains: 'outdoor' } }, { title: { contains: 'Outdoor' } },
                                { title: { contains: 'fitness' } }, { title: { contains: 'Fitness' } },
                                { title: { contains: 'eşofman' } }, { title: { contains: 'Eşofman' } }
                            ]
                        };
                    }
                    if (cleanCat === 'moda') {
                        return { category: 'moda' };
                    }
                    if (cleanCat === 'kozmetik') {
                        return { category: 'kozmetik' };
                    }
                    return { category: cleanCat };
                })() : {})
            },
            take: 50
        });

        // Combine
        const combined = [...hotProducts, ...systemProducts];

        // Parse JSONs
        const polished = combined.map(p => ({
            ...p,
            sellers: safeParseJSON(p.sellers),
            variants: safeParseJSON(p.variants)
        }));

        res.json(polished);
    } catch (error) {
        console.error("Trending Error:", error);
        res.status(500).json({ error: "Failed to fetch trending", details: error.message });
    }
});

// 4. Barcode Lookup (ULTRA FEATURE)
router.post('/barcode', async (req, res) => {
    try {
        const { barcode } = req.body;
        if (!barcode) return res.status(400).json({ error: "Barcode is required" });

        // 1. Check DB first
        const existing = await prisma.product.findUnique({ where: { barcode: barcode } });
        if (existing) return res.json(existing);

        // 2. Lookup External API
        const result = await lookupBarcode(barcode);

        // 3. If redirect required (e.g. short link)
        if (result.title === "REDIRECT_REQUIRED") {
            const realData = await scrapeProduct(result.url);
            return res.json({ ...realData, barcode }); // Return with barcode so frontend knows
        }

        res.json(result);
    } catch (error) {
        console.error("Barcode Error:", error);
        res.status(404).json({ error: "Product not found" });
    }
});

// 5. Price Analysis (ULTRA FEATURE)
router.get('/:id/analysis', async (req, res) => {
    try {
        const { id } = req.params;
        const analysis = await analyzePrice(id);
        res.json(analysis);
    } catch (error) {
        res.status(500).json({ error: "Analysis failed" });
    }
});

// 6. Inditex Feed
router.get('/inditex/feed', async (req, res) => {
    try {
        const { brand, category } = req.query;
        const where = {
            isSystem: true,
            inStock: true,
            OR: [
                // 1. Standard Inditex & Fashion Brands
                { source: { in: ['zara', 'bershka', 'pullandbear', 'stradivarius', 'oysho', 'massimodutti', 'zarahome', 'lefties', 'hm', 'mango'] } },
                // 2. TrendyolMilla (specific brand on Trendyol)
                { source: 'trendyol', title: { contains: 'TrendyolMilla' } }
            ]
        };
        if (brand && brand !== 'Hepsi') where.source = brand.toLowerCase();
        if (category && category !== 'Tümü') where.category = category;

        const products = await prisma.product.findMany({
            where,
            orderBy: [{ originalPrice: { sort: 'desc', nulls: 'last' } }, { createdAt: 'desc' }],
            take: 50
        });

        const polished = products.map(p => ({
            ...p,
            sellers: safeParseJSON(p.sellers),
            variants: safeParseJSON(p.variants),
            history: p.history ? p.history.map(h => ({ ...h, checkedAt: h.createdAt })) : [],
            discountPercentage: p.originalPrice > p.currentPrice ? Math.round(((p.originalPrice - p.currentPrice) / p.originalPrice) * 100) : 0
        }));

        res.json(polished);
    } catch (error) {
        res.status(500).json({ error: "Inditex feed failed" });
    }
});

// 7. Preview
router.post('/preview', async (req, res) => {
    try {
        const { url } = req.body;
        const data = await scrapeProduct(url);
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: "Preview failed" });
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

// 1.5 Get Single Product (Moved to bottom)
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
