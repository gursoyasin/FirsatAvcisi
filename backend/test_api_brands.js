const http = require('http');

function fetchBrand(brandName) {
    return new Promise((resolve, reject) => {
        const url = `http://localhost:3000/api/products/inditex/feed?brand=${encodeURIComponent(brandName)}`;
        console.log(`\n🔍 Requesting: ${brandName}`);
        console.log(`   URL: ${url}`);

        http.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const products = JSON.parse(data);
                    if (Array.isArray(products)) {
                        console.log(`   ✅ Status: ${res.statusCode}`);
                        console.log(`   📦 Found: ${products.length} products`);
                        if (products.length > 0) {
                            console.log(`   📝 First Item: ${products[0].title} (${products[0].source})`);
                        }
                    } else {
                        console.log(`   ❌ Error: Response is not an array`, data);
                    }
                    resolve();
                } catch (e) {
                    console.log(`   ❌ Parse Error:`, e.message);
                    resolve();
                }
            });
        }).on('error', err => {
            console.log(`   ❌ Request Failed:`, err.message);
            resolve();
        });
    });
}

async function run() {
    // 1. Test EXACT names sent by the App
    await fetchBrand("Pull&Bear");
    await fetchBrand("Oysho");
    await fetchBrand("Massimo Dutti");

    // 2. Test Control (Zara)
    await fetchBrand("Zara");
}

run();
