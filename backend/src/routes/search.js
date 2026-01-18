const express = require('express');
const router = express.Router();
const { globalSearch } = require('../services/searchService');
const { resolveFinalUrl } = require('../services/linkResolver');
const { findAlternatives } = require('../services/comparison');
const crypto = require('crypto');

// Helper
function safeParseJSON(input) {
    if (!input) return [];
    if (typeof input !== 'string') return input;
    try {
        let parsed = JSON.parse(input);
        if (typeof parsed === 'string') return safeParseJSON(parsed);
        return parsed;
    } catch (e) { return []; }
}

// Global Search
router.get('/global', async (req, res) => {
    try {
        const query = req.query.q;
        if (!query) return res.status(400).json({ error: "Query required" });

        const results = await globalSearch(query);

        // Clean results
        const cleaned = results.map(item => ({
            ...item,
            id: item.id ? String(item.id) : crypto.createHash('md5').update(item.url || item.title).digest('hex'),
            currentPrice: item.price,
            sellers: safeParseJSON(item.sellers),
            variants: safeParseJSON(item.variants)
        }));

        res.json(cleaned);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Search failed" });
    }
});

// Resolve URL
router.get('/resolve-url', async (req, res) => {
    const { url } = req.query;
    try {
        const finalUrl = await resolveFinalUrl(url);
        res.json({ finalUrl });
    } catch (e) { res.status(500).json({ error: "Resolution failed" }); }
});

// Alternatives
router.get('/alternatives/:productId', async (req, res) => {
    // Logic moved from products/:id/alternatives
    // ... skipping for now or can implement if needed
    res.json([]);
});

module.exports = router;
