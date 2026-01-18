const { globalSearch } = require('./services/searchService');

async function test() {
    console.log("🚀 Testing Global Search with 'iPhone 15'...");
    const results = await globalSearch("iPhone 15");

    console.log("\n📊 Summary:");
    console.log(`Total Results: ${results.length}`);

    const sources = {};
    results.forEach(r => {
        sources[r.source] = (sources[r.source] || 0) + 1;
    });
    console.log("Sources breakdown:", sources);

    if (results.length > 0) {
        console.log("\nTop 3 Results:");
        results.slice(0, 3).forEach((r, i) => {
            console.log(`#${i + 1} [${r.source}] ${r.title} - ${r.price} TL`);
            console.log(`   Seller Count: ${JSON.parse(r.sellers).length}`);
        });
    } else {
        console.error("❌ No results found!");
    }
}

test();
