const express = require('express');
const router = express.Router();
const prisma = require('../config/db');
const crypto = require('crypto');
const { scrapeProduct } = require('../services/scraper');
const { globalSearch } = require('../services/searchService');

const { resolveFinalUrl } = require('../services/linkResolver');

// Helper to handle double-encoded strings (e.g. "[{...}]" inside another string)
function safeParseJSON(input) {
    if (!input) return [];
    if (typeof input !== 'string') return input;

    try {
        let parsed = JSON.parse(input);
        // Recursively parse if the result is still a string
        if (typeof parsed === 'string') {
            return safeParseJSON(parsed);
        }
        return parsed;
    } catch (e) {
        return []; // Fail safe to empty array
    }
}

router.get('/search/global', async (req, res) => {
    try {
        const query = req.query.q;
        if (!query) return res.status(400).json({ error: "Query parameter required" });

        console.log(`🌍 Global Search Request: ${query}`);
        const results = await globalSearch(query);

        // Parse JSON strings for Frontend
        // Parse JSON strings for Frontend
        const cleanedResults = results.map(item => {
            // Use Recursive Parser
            let parsedSellers = safeParseJSON(item.sellers);
            let parsedVariants = safeParseJSON(item.variants);

            // Sanitize Sellers (Ensure numeric price)
            if (Array.isArray(parsedSellers)) {
                parsedSellers = parsedSellers.map(s => ({
                    ...s,
                    price: parseFloat(s.price) || 0,
                    merchant: s.merchant || "Mağaza",
                    url: s.url || ""
                }));
            } else {
                parsedSellers = [];
            }

            if (!Array.isArray(parsedVariants)) parsedVariants = [];

            return {
                ...item,
                id: item.id ? String(item.id) : crypto.createHash('md5').update(item.url || item.title).digest('hex'),
                currentPrice: item.price, // Fix: iOS expects 'currentPrice', backend was sending 'price'
                sellers: parsedSellers,
                variants: parsedVariants
            };
        });

        res.json(cleanedResults);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Search failed" });
    }
});

// Deep Link Resolver Endpoint
router.get('/resolve-url', async (req, res) => {
    try {
        const { url } = req.query;
        if (!url) return res.status(400).json({ error: "URL required" });

        const finalUrl = await resolveFinalUrl(url);
        res.json({ finalUrl });
    } catch (error) {
        res.status(500).json({ error: "Resolution failed" });
    }
});

const VIP_EMAILS = [
    "yasin@example.com", // Placeholder
    "gursoyreal@gmail.com", // You
    "keskinezgi26@outlook.com", // manita
];

// Get all products (User Specific)
router.get('/products', async (req, res) => {
    try {
        const userEmail = req.headers['x-user-email'];
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const skip = (page - 1) * limit;

        if (!userEmail) {
            return res.status(400).json({ error: "User email header missing" });
        }

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
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to fetch products' });
    }
});

// Trending Cache
let trendingCache = {
    data: null,
    expiry: 0
};

// Trending products (Real Data + Personalization)
router.get('/products/trending', async (req, res) => {
    try {
        const { category } = req.query;
        const userEmail = req.headers['x-user-email'] || "anonymous";
        const now = Date.now();

        // 1. Fetch HOT DEALS (Recently Dropped Prices)
        const hotProducts = await prisma.product.findMany({
            where: {
                isSystem: true,
                inStock: true,
                lastPriceDropAt: { not: null }, // Only products with price drops
                ...(category && category !== 'Hepsi' ? { category: category.toLowerCase() } : {})
            },
            take: 10,
            orderBy: { lastPriceDropAt: 'desc' }
        });

        // 2. Fetch System Products (Filler - Popular or Random)
        // Adjust take count based on hot products found
        const fillCount = 50 - hotProducts.length;

        let systemProducts = await prisma.product.findMany({
            where: {
                isSystem: true,
                inStock: true,
                // Exclude IDs already found in hotProducts
                id: { notIn: hotProducts.map(p => p.id) },
                ...(category && category !== 'Hepsi' ? { category: category.toLowerCase() } : {})
            },
            take: fillCount,
        });

        // Helper: Shuffle Array
        const shuffle = (array) => {
            for (let i = array.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [array[i], array[j]] = [array[j], array[i]];
            }
            return array;
        };

        // Shuffle System Products to ensure "Newness" feeling on refresh
        systemProducts = shuffle(systemProducts);

        // 3. Personalized Recommendations (Based on Search History)
        let personalProducts = [];
        if (userEmail !== "anonymous" && (!category || category === "Hepsi")) {
            const lastSearches = await prisma.searchHistory.findMany({
                where: { userEmail },
                orderBy: { searchedAt: 'desc' },
                take: 3
            });

            if (lastSearches.length > 0) {
                for (const search of lastSearches) {
                    const matches = await prisma.product.findMany({
                        where: {
                            isSystem: true,
                            title: { contains: search.query },
                            id: { notIn: [...hotProducts, ...systemProducts].map(p => p.id) }
                        },
                        take: 5
                    });
                    personalProducts.push(...matches);
                }
            }
        }

        // 4. Combine: Hot Deals FIRST, then Personal, then General
        // This ensures the "Market Feed" starts with the "Action" user sees in terminal
        const combined = [...hotProducts, ...personalProducts, ...systemProducts];

        console.log(`📊 Trending Feed: ${combined.length} items (Hot: ${hotProducts.length}, Sys: ${systemProducts.length}) for Cat: ${category || 'All'}`);

        // Parse JSON strings (Prisma/SQLite limitation)
        // Parse JSON strings (Prisma/SQLite limitation)
        const polished = combined.map(p => {
            // Use Recursive Parser
            let parsedSellers = safeParseJSON(p.sellers);
            let parsedVariants = safeParseJSON(p.variants);

            // Sanitize Sellers (Ensure numeric price)
            if (Array.isArray(parsedSellers)) {
                parsedSellers = parsedSellers.map(s => ({
                    ...s,
                    price: parseFloat(s.price) || 0,
                    merchant: s.merchant || "Mağaza",
                    url: s.url || ""
                }));
            } else {
                parsedSellers = [];
            }

            if (!Array.isArray(parsedVariants)) parsedVariants = [];

            return {
                ...p,
                sellers: parsedSellers,
                variants: parsedVariants
            };
        });

        res.json(polished);
    } catch (error) {
        console.error("Trending Error:", error);
        res.status(500).json({ error: "Failed to fetch trending products" });
    }
});

// Admin Scraper Seeder Endpoint
router.post('/admin/seed-trends', async (req, res) => {
    try {
        const { runSeeder } = require('../services/seeder');

        // Run async to not block response
        runSeeder().catch(err => console.error("Manual seed failed:", err));

        res.json({ message: "Seeding process started in background." });
    } catch (error) {
        console.error("Seeding failed:", error);
        res.status(500).json({ error: error.message });
    }
});

// Add a product
router.post('/products', async (req, res) => {
    try {
        let { url, title, price, imageUrl, source, inStock, originalPrice } = req.body;
        let productData = { url, title, price, imageUrl, source, inStock, originalPrice };

        // If title is missing (e.g. from Share Extension), scrape it first
        if (!title) {
            console.log("Auto-scraping for Quick Add:", url);
            const { scrapeProduct } = require('../services/scraper');
            try {
                const scraped = await scrapeProduct(url);
                productData.title = scraped.title;
                productData.price = scraped.currentPrice;
                productData.imageUrl = scraped.imageUrl;
                productData.source = scraped.source;
                productData.inStock = scraped.inStock ?? true;
                productData.originalPrice = scraped.originalPrice; // Use scraped original price
            } catch (err) {
                console.error("Auto-scrape failed:", err);
                return res.status(400).json({ error: "Link analiz edilemedi." });
            }
        } else {
            if (!url) return res.status(400).json({ error: "URL required" });
        }

        const numericPrice = parseFloat(productData.price) || 0;

        // Get User Email
        const userEmail = req.headers['x-user-email'] || "anonymous";
        const isPremium = VIP_EMAILS.includes(userEmail);

        console.log(`User: ${userEmail}, Premium: ${isPremium}`);

        // CHECK LIMIT (Free Plan: 3 Products)
        if (!isPremium) {
            const count = await prisma.product.count({
                where: { userEmail: userEmail }
            });
            if (count >= 3) {
                return res.status(403).json({ error: "LIMIT_REACHED", message: "Ücretsiz plan limiti (3 ürün) doldu. Premium'a geçin!" });
            }
        }

        const product = await prisma.product.create({
            data: {
                url,
                title: productData.title,
                currentPrice: numericPrice,
                originalPrice: productData.originalPrice ? parseFloat(productData.originalPrice) : 0,
                imageUrl: productData.imageUrl || "",
                source: productData.source || "unknown",
                inStock: productData.inStock,
                userEmail: userEmail,
                category: productData.category || "diger",
                history: {
                    create: {
                        price: numericPrice
                    }
                }
            }
        });
        res.json(product);
    } catch (error) {
        console.error("Database save error:", error);
        res.status(500).json({ error: `Save failed: ${error.message}` });
    }
});

// Preview endpoint - Gerçek veri
router.post('/products/preview', async (req, res) => {
    try {
        const { url } = req.body;
        if (!url) return res.status(400).json({ error: "URL gerekli" });

        console.log("Analyzing URL:", url);
        const data = await scrapeProduct(url); // Gerçek scraper çağrısı

        // Fix for iOS Swift Decoder (Expects String, not Array/Object)
        if (data.imageUrl && typeof data.imageUrl === 'object') {
            if (Array.isArray(data.imageUrl)) {
                data.imageUrl = data.imageUrl.length > 0 ? data.imageUrl[0] : "";
            } else if (data.imageUrl.contentUrl) {
                // Handle JSON-LD ImageObject
                const content = data.imageUrl.contentUrl;
                data.imageUrl = Array.isArray(content) ? (content[0] || "") : String(content);
            }
        }

        res.json(data);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Ürün analiz edilemedi: " + error.message });
    }
});

// Update product (Target Price)
router.patch('/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { targetPrice } = req.body;

        const product = await prisma.product.update({
            where: { id: parseInt(id) },
            data: { targetPrice: parseFloat(targetPrice) }
        });

        console.log(`Updated Target Price for Product ${id}: ${targetPrice}`);
        res.json(product);
    } catch (error) {
    }
});

// Delete product
router.delete('/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.product.delete({
            where: { id: parseInt(id) }
        });
        console.log(`Deleted Product ${id}`);
        res.json({ message: "Product deleted" });
    } catch (error) {
        console.error("Delete error:", error);
        res.status(500).json({ error: "Delete failed" });
    }
});

// Barcode Lookup Endpoint
const { lookupBarcode } = require('../services/barcode');
router.post('/products/barcode', async (req, res) => {
    try {
        const { barcode } = req.body;
        if (!barcode) return res.status(400).json({ error: "Barcode is required" });

        const result = await lookupBarcode(barcode);
        // Handle redirect required
        if (result.title === "REDIRECT_REQUIRED") {
            const { scrapeProduct } = require('../services/scraper');
            const realData = await scrapeProduct(result.url);
            return res.json(realData);
        }

        res.json(result);
    } catch (error) {
        console.error("Barcode Error:", error);
        res.status(404).json({ error: "Product not found" });
    }
});

// Register Device Token
router.post('/devices/register', async (req, res) => {
    try {
        const { token } = req.body;
        const userEmail = req.headers['x-user-email'] || "anonymous";

        if (!token) return res.status(400).json({ error: "Token is required" });

        // Upsert device token
        const device = await prisma.device.upsert({
            where: { token: token },
            update: { userEmail: userEmail },
            create: {
                token: token,
                userEmail: userEmail
            }
        });

        res.json({ message: "Device registered", device });
    } catch (error) {
        console.error("Device registration error:", error);
        res.status(500).json({ error: "Failed to register device" });
    }
});

// Batch Delete Products
router.post('/products/batch-delete', async (req, res) => {
    try {
        const { ids } = req.body;
        const userEmail = req.headers['x-user-email'] || "anonymous";

        if (!ids || !Array.isArray(ids)) return res.status(400).json({ error: "IDs array required" });

        await prisma.product.deleteMany({
            where: {
                id: { in: ids.map(id => parseInt(id)) },
                userEmail: userEmail
            }
        });

        console.log(`Batch Deleted Products for ${userEmail}: ${ids}`);
        res.json({ message: "Products deleted successfully" });
    } catch (error) {
        console.error("Batch delete error:", error);
        res.status(500).json({ error: "Batch delete failed" });
    }
});

// Collections Routes
router.get('/collections', async (req, res) => {
    try {
        const userEmail = req.headers['x-user-email'] || "anonymous";
        let collections = await prisma.collection.findMany({
            where: { userEmail: userEmail },
            include: {
                _count: { select: { products: true } },
                products: { take: 4, select: { imageUrl: true, currentPrice: true } }
            }
        });

        // Ensure default Smart Collections exist in the response
        const smartDefaults = [
            { id: -1, name: "Süper İndirimler", icon: "bolt.fill", type: "SMART", query: JSON.stringify({ minDiscount: 30 }), userEmail: "system", isPublic: false, shareToken: null, _count: { products: 0 }, products: [] },
            { id: -2, name: "Stokta Kalanlar", icon: "shippingbox.fill", type: "SMART", query: JSON.stringify({ inStock: true }), userEmail: "system", isPublic: false, shareToken: null, _count: { products: 0 }, products: [] }
        ];

        // For actual counts/previews of smart ones, we'd need to run their queries.
        // For MVP, if we want them to show real counts, we can do it here:
        for (const smart of smartDefaults) {
            const query = JSON.parse(smart.query);
            let where = { userEmail: userEmail };
            if (query.minDiscount) where.discountPercentage = { gte: query.minDiscount };
            if (query.inStock) where.inStock = true;

            const count = await prisma.product.count({ where });
            const previews = await prisma.product.findMany({
                where,
                take: 4,
                select: { imageUrl: true, currentPrice: true }
            });

            smart._count.products = count;
            smart.products = previews;
        }

        // Combine (Smarts first)
        const finalResults = [...smartDefaults, ...collections];
        res.json(finalResults);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to fetch collections" });
    }
});

router.post('/collections', async (req, res) => {
    try {
        const { name, icon, type, query } = req.body;
        const userEmail = req.headers['x-user-email'] || "anonymous";
        const collection = await prisma.collection.create({
            data: {
                name,
                userEmail,
                icon: icon || "folder",
                type: type || "MANUAL",
                query: query || null
            }
        });
        res.json(collection);
    } catch (error) {
        res.status(500).json({ error: "Failed to create collection" });
    }
});

router.patch('/collections/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, icon, isPublic, type, query } = req.body;
        const userEmail = req.headers['x-user-email'] || "anonymous";

        const collection = await prisma.collection.findUnique({ where: { id: parseInt(id) } });
        if (!collection || collection.userEmail !== userEmail) return res.status(403).json({ error: "Unauthorized" });

        let updateData = { name, icon, isPublic, type, query };

        // Generate share token if becoming public for the first time
        if (isPublic && !collection.shareToken) {
            updateData.shareToken = crypto.randomBytes(8).toString('hex');
        }

        const updated = await prisma.collection.update({
            where: { id: parseInt(id) },
            data: updateData
        });
        res.json(updated);
    } catch (error) {
        res.status(500).json({ error: "Failed to update collection" });
    }
});

router.post('/collections/:id/products', async (req, res) => {
    try {
        const { id } = req.params;
        const { productId } = req.body;
        const userEmail = req.headers['x-user-email'] || "anonymous";

        // Verify collection ownership
        const collection = await prisma.collection.findUnique({ where: { id: parseInt(id) } });
        if (!collection || collection.userEmail !== userEmail) return res.status(403).json({ error: "Unauthorized" });

        await prisma.collection.update({
            where: { id: parseInt(id) },
            data: {
                products: { connect: { id: parseInt(productId) } }
            }
        });
        res.json({ message: "Product added to collection" });
    } catch (error) {
        res.status(500).json({ error: "Failed to add product to collection" });
    }
});

router.delete('/collections/:id/products/:productId', async (req, res) => {
    try {
        const { id, productId } = req.params;
        const userEmail = req.headers['x-user-email'] || "anonymous";

        const collection = await prisma.collection.findUnique({ where: { id: parseInt(id) } });
        if (!collection || collection.userEmail !== userEmail) return res.status(403).json({ error: "Unauthorized" });

        await prisma.collection.update({
            where: { id: parseInt(id) },
            data: {
                products: { disconnect: { id: parseInt(productId) } }
            }
        });
        res.json({ message: "Product removed from collection" });
    } catch (error) {
        res.status(500).json({ error: "Failed to remove product" });
    }
});

router.post('/collections/:id/move', async (req, res) => {
    try {
        const { id } = req.params; // target
        const { productIds, sourceCollectionId } = req.body;
        const userEmail = req.headers['x-user-email'] || "anonymous";

        const target = await prisma.collection.findUnique({ where: { id: parseInt(id) } });
        if (!target || target.userEmail !== userEmail) return res.status(403).json({ error: "Unauthorized target" });

        const source = await prisma.collection.findUnique({ where: { id: parseInt(sourceCollectionId) } });
        if (!source || source.userEmail !== userEmail) return res.status(403).json({ error: "Unauthorized source" });

        const ids = productIds.map(pid => ({ id: parseInt(pid) }));

        await prisma.$transaction([
            prisma.collection.update({
                where: { id: parseInt(sourceCollectionId) },
                data: { products: { disconnect: ids } }
            }),
            prisma.collection.update({
                where: { id: parseInt(id) },
                data: { products: { connect: ids } }
            })
        ]);

        res.json({ message: "Products moved" });
    } catch (error) {
        res.status(500).json({ error: "Move failed" });
    }
});

router.get('/collections/:id', async (req, res) => {
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
                products: products,
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
            // Example: {"minDiscount": 30}
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

        res.json(collection);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch collection" });
    }
});

router.get('/collections/share/:token', async (req, res) => {
    try {
        const { token } = req.params;
        const collection = await prisma.collection.findUnique({
            where: { shareToken: token },
            include: { products: true }
        });

        if (!collection || !collection.isPublic) return res.status(404).json({ error: "No public collection found" });
        res.json(collection);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch share" });
    }
});

router.delete('/collections/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const userEmail = req.headers['x-user-email'] || "anonymous";

        const collection = await prisma.collection.findUnique({ where: { id: parseInt(id) } });
        if (!collection || collection.userEmail !== userEmail) return res.status(403).json({ error: "Unauthorized" });

        await prisma.collection.delete({ where: { id: parseInt(id) } });
        res.json({ message: "Collection deleted" });
    } catch (error) {
        res.status(500).json({ error: "Delete failed" });
    }
});

const { findAlternatives } = require('../services/comparison');
router.get('/products/:id/alternatives', async (req, res) => {
    try {
        const { id } = req.params;
        const product = await prisma.product.findUnique({ where: { id: parseInt(id) } });

        if (!product) return res.status(404).json({ error: "Product not found" });

        console.log(`Finding alternatives for: ${product.title}`);
        // Use a cleaned title for better search results (first 4 words)
        const searchQuery = product.title.split(' ').slice(0, 5).join(' ');
        const alternatives = await findAlternatives(searchQuery, product.source);

        res.json(alternatives);
    } catch (error) {
        console.error("Comparison error:", error);
        res.status(500).json({ error: "Failed to find alternatives" });
    }
});

// --- INDITEX TRACKER ENDPOINTS ---

router.get('/inditex/feed', async (req, res) => {
    try {
        const { brand, category } = req.query; // optional filters
        const page = parseInt(req.query.page) || 1;
        const limit = 50;
        const skip = (page - 1) * limit;

        const where = {
            isSystem: true,
            source: { in: ['zara', 'bershka', 'pullandbear', 'stradivarius', 'oysho', 'massimodutti'] },
            inStock: true
        };

        if (brand && brand !== 'Hepsi') {
            where.source = brand.toLowerCase();
        }

        if (category && category !== 'Tümü') {
            where.category = category;
        }

        const products = await prisma.product.findMany({
            where: where,
            orderBy: [
                { originalPrice: { sort: 'desc', nulls: 'last' } }, // Show high discounts first if we could calc %, but creation date is safer for "new"
                { createdAt: 'desc' }
            ],
            take: limit,
            skip: skip
        });

        // Calculate Discount Percentage on the fly if needed, or stick to simple
        const polished = products.map(p => {
            // Use our safe parser helper from earlier in this file!
            // Assuming safeParseJSON is in scope (it is declared at top)
            let parsedSellers = safeParseJSON(p.sellers);
            let parsedVariants = safeParseJSON(p.variants);

            return {
                ...p,
                sellers: parsedSellers,
                variants: parsedVariants,
                // Add computed discount
                discountPercentage: p.originalPrice > p.currentPrice
                    ? Math.round(((p.originalPrice - p.currentPrice) / p.originalPrice) * 100)
                    : 0
            };
        });

        res.json(polished);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Inditex feed failed" });
    }
});

router.post('/inditex/mine', async (req, res) => {
    try {
        const { mineInditex } = require('../services/inditexMiner');
        // Run in background
        mineInditex().catch(err => console.error("Mining crashed:", err));
        res.json({ message: "Inditex Miner started in background." });
    } catch (error) {
        res.status(500).json({ error: "Failed to start miner" });
    }
});

router.post('/watchlist/check', async (req, res) => {
    try {
        const { checkWatchlistPrices } = require('../services/watchlistTracker');
        // Run in background to avoid timeout
        checkWatchlistPrices().catch(err => console.error("Watchlist check crashed:", err));
        res.json({ message: "Watchlist price check started in background." });
    } catch (error) {
        res.status(500).json({ error: "Failed to start tracker" });
    }
});

module.exports = router;
