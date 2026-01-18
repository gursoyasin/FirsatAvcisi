const { findAlternatives } = require('./src/services/comparison');

async function test() {
    console.log("Searching for iPhone 13 alternatives...");
    const results = await findAlternatives("iPhone 13", "none");
    console.log("Results found:", results.length);
    console.log(JSON.stringify(results, null, 2));
}

test().catch(console.error);
