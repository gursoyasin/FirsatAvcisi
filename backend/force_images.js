const fs = require('fs');
const path = require('path');
const https = require('https');
const prisma = require('./src/config/db');
const { createPage } = require('./src/services/scraper/BrowserService');

async function forceDownloadImages() {
    console.log("💪 FORCING REAL IMAGES (Robust Mode)...");

    const products = await prisma.product.findMany({
        where: { isSystem: true },
        select: { id: true, url: true, title: true }
    });

    console.log(`🎯 Found ${products.length} products to brute-force.`);

    const browser = await require('puppeteer').launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--window-size=1920,1080']
    });

    for (const product of products) {
        let page;
        try {
            console.log(`🖼️ Processing: ${product.title}`);
            page = await browser.newPage();
            await page.setViewport({ width: 1920, height: 1080 });
            await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

            await page.goto(product.url, { waitUntil: 'domcontentloaded', timeout: 45000 });

            // 1. Force Scroll & Wait for Lazy Load
            await page.evaluate(() => window.scrollBy(0, 500));
            await new Promise(r => setTimeout(r, 2500));

            // 2. Extract Real Image URL
            const imgUrl = await page.evaluate(() => {
                // A. OG Meta Tag (Best for H&M, Mango, and often Zara)
                const og = document.querySelector('meta[property="og:image"]');
                if (og && og.content) return og.content;

                // B. Specific Brand Selectors
                const selectors = [
                    '.media-image__image', // Zara
                    '.product-detail-images__image', // Zara old
                    '.product-image img', // General
                    'img[itemprop="image"]',
                    '.main-image img',
                    'img.image-item', // Bershka/PB
                    'img[class*="product-image"]',
                    '.image-container img',
                    '.product-detail-main-image-container img', // H&M
                    '.product-image-gallery img',
                    '.product-images__image', // Mango
                    'img[data-testid="product-image"]'
                ];

                for (let s of selectors) {
                    const el = document.querySelector(s);
                    if (el && (el.src || el.getAttribute('data-src'))) {
                        return el.src || el.getAttribute('data-src');
                    }
                }

                // C. Fallback: Largest visible image on screen
                const all = Array.from(document.querySelectorAll('img'));
                // Filter out tiny icons
                const candidates = all.filter(i => i.width > 250 && i.height > 250);
                const sorted = candidates.sort((a, b) => (b.width * b.height) - (a.width * a.height));

                if (sorted.length > 0) return sorted[0].src;
                return null;
            });

            if (!imgUrl) {
                console.log(`⚠️ No image found on page for ${product.id}`);
                continue;
            }

            console.log(`   Found Image: ${imgUrl.substring(0, 50)}...`);

            // 3. Download Image
            const viewSource = await page.goto(imgUrl);
            const buffer = await viewSource.buffer();

            // 4. Save to Local Disk
            const fileName = `product_${product.id}.jpg`;
            const filePath = path.join(__dirname, 'public', 'images', fileName);
            fs.writeFileSync(filePath, buffer);

            // 5. Update DB
            const localUrl = `http://localhost:3000/images/${fileName}`;
            await prisma.product.update({
                where: { id: product.id },
                data: { imageUrl: localUrl }
            });

            console.log(`✅ SAVED & UPDATED: ${localUrl}`);

        } catch (e) {
            console.error(`❌ Failed ${product.id}: ${e.message}`);
        } finally {
            if (page) await page.close();
        }
    }

    await browser.close();
    console.log("🏁 MISSION ACCOMPLISHED.");
}

forceDownloadImages();
