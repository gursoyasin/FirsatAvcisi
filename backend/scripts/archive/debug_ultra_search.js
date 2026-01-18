const fetch = require('node-fetch');

async function testSearch() {
    const baseURL = "http://localhost:3000/api";

    console.log("----- TESTING ULTRA SEARCH (q=Airfryer) -----");
    try {
        const res = await fetch(`${baseURL}/search/global?q=Airfryer`);
        const json = await res.json();
        console.log("Status:", res.status);
        console.log(`Total Results: ${json.length}`);

        if (json.length > 0) {
            console.log("First Result Type Check:");
            const item = json[0];
            console.log("Title:", item.title);
            console.log("id:", item.id, typeof item.id);
            console.log("currentPrice:", item.currentPrice, typeof item.currentPrice);
            console.log("source:", item.source);

            // Check for Google Results
            const googleCount = json.filter(i => i.source.includes('google')).length;
            console.log(`Google Results Count: ${googleCount}`);
        } else {
            console.log("No results found.");
        }
    } catch (e) {
        console.error("Search Error:", e.message);
    }
}

testSearch();
