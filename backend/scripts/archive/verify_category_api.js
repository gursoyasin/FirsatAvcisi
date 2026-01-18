const fetch = require('node-fetch');

async function testCategoryFilter() {
    console.log("🧪 Testing Category Filter API...");

    const categories = ['Elbise', 'Tişört', 'Ceket'];

    for (const cat of categories) {
        try {
            const url = `http://localhost:3000/api/inditex/feed?category=${cat}`;
            const res = await fetch(url);
            const products = await res.json();

            console.log(`\n📂 Category: ${cat}`);
            console.log(`Matching Products: ${products.length}`);

            if (products.length > 0) {
                const sample = products[0];
                console.log(`   Sample: ${sample.title} (${sample.category})`);

                if (sample.category !== cat) {
                    console.error("❌ Mismatch! Expected " + cat + " but got " + sample.category);
                } else {
                    console.log("✅ Match verified.");
                }
            } else {
                console.log("   (No products found for this category yet, which might be normal if mining isn't complete)");
            }

        } catch (e) {
            console.error("Test failed:", e.message);
        }
    }
}

testCategoryFilter();
