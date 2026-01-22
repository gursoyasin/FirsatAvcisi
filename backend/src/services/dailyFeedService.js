const prisma = require('../config/db');

// Service to curate the "Daily Feed" for the Dashboard
// 1. Heart Feed (3 Boxes): High impact, fresh, diverse brands
// 2. Style Feed (1 Box): "Best Pick" based on category/brand

async function getHeartFeed(gender) {
    // Logic: Get 3 fresh products with high discount from diverse brands
    const today = new Date();
    today.setHours(today.getHours() - 24); // Last 24h

    // 1. Try to find products updated in last 24h
    let candidates = await prisma.product.findMany({
        where: {
            isSystem: true,
            inStock: true,
            updatedAt: { gte: today },
            originalPrice: { not: null },
            OR: [
                { gender: gender },
                { gender: 'unisex' },
                { gender: null }
            ]
        },
        orderBy: [
            { updatedAt: 'desc' }
        ],
        take: 100
    });

    // Sort candidates to put user's specific gender at the TOP
    candidates.sort((a, b) => {
        if (a.gender === gender && b.gender !== gender) return -1;
        if (a.gender !== gender && b.gender === gender) return 1;
        return 0;
    });

    // Fallback: If no fresh data (miner hasn't run yet), get any system product
    if (candidates.length < 3) {
        candidates = await prisma.product.findMany({
            where: {
                isSystem: true,
                inStock: true,
                OR: [
                    { gender: gender },
                    { gender: 'unisex' },
                    { gender: null }
                ]
            },
            orderBy: { createdAt: 'desc' },
            take: 50
        });
    }

    // Filter for unique brands to keep it interesting
    const uniqueMap = new Map();
    for (const p of candidates) {
        if (!uniqueMap.has(p.source)) {
            uniqueMap.set(p.source, p);
        }
        if (uniqueMap.size >= 3) break;
    }

    // If we still don't have 3 unique brands, fill with others
    let result = Array.from(uniqueMap.values());
    if (result.length < 3) {
        const remaining = candidates.filter(p => !result.find(r => r.id === p.id));
        result = [...result, ...remaining].slice(0, 3);
    }

    return result.map(enrichProduct);
}

async function getDailyPick(brandPreference, gender) {
    // Logic: Best "Style" pick. 
    // If brandPreference is provided (e.g. "Zara"), prioritize that.

    // Sort logic: Highest discount percentage
    const products = await prisma.product.findMany({
        where: {
            isSystem: true,
            inStock: true,
            source: brandPreference ? brandPreference.toLowerCase() : undefined,
            OR: [
                { gender: gender },
                { gender: 'unisex' },
                { gender: null }
            ]
        },
        take: 50 // Analyze top 50
    });

    // Calculate discount and sort
    const scored = products.map(p => {
        const discount = p.originalPrice ? ((p.originalPrice - p.currentPrice) / p.originalPrice) : 0;
        // Boost score if gender matches perfectly
        const genderBoost = (p.gender === gender) ? 0.3 : 0;
        return { ...p, score: discount + genderBoost };
    });

    scored.sort((a, b) => b.score - a.score);

    return scored.length > 0 ? enrichProduct(scored[0]) : null;
}

function enrichProduct(p) {
    // Add computed fields if necessary
    return {
        ...p,
        discountPercentage: p.originalPrice ? Math.round(((p.originalPrice - p.currentPrice) / p.originalPrice) * 100) : 0
    };
}

module.exports = { getHeartFeed, getDailyPick };
