const fetch = require('node-fetch');

async function testSearch() {
    const baseURL = "http://localhost:3000/api";
    const query = "iPhone 13";

    console.log(`----- TESTING OPTIMIZED SEARCH (q=${query}) -----`);
    const start = Date.now();
    try {
        const res = await fetch(`${baseURL}/search/global?q=${encodeURIComponent(query)}`);
        const json = await res.json();
        const duration = (Date.now() - start) / 1000;

        console.log(`Status: ${res.status}`);
        console.log(`Duration: ${duration}s`);
        console.log(`Total Results: ${json.length}`);

        if (json.length > 0) {
            console.log("Top 3 Results:");
            json.slice(0, 3).forEach((item, i) => {
                console.log(`${i + 1}. ${item.title} | ${item.currentPrice} TL | ${item.source}`);
            });

            // Check for low price anomaly
            const lowPrice = json.find(i => i.currentPrice < 5000 && i.title.toLowerCase().includes('iphone 13'));
            if (lowPrice) {
                console.log("⚠️ WARNING: Found suspicious low price item:");
                console.log(`${lowPrice.title} | ${lowPrice.currentPrice} TL`);
            } else {
                console.log("✅ Price check pass: No suspiciously cheap iPhone 13s found.");
            }
        } else {
            console.log("No results found.");
        }
    } catch (e) {
        console.error("Search Error:", e.message);
    }
}

testSearch();
