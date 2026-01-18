const puppeteer = require('puppeteer');

async function testShareLink() {
    const shareUrl = "https://www.zara.com/share/kadin-ceket-p04432724.html?v1=311234567&utm_campaign=productShare&utm_medium=mobile_sharing_iOS&utm_source=red_social_movil";
    console.log(`Testing Share URL: ${shareUrl}`);

    const browser = await puppeteer.launch({
        headless: false,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();

    // Set Desktop UA
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    // Cookie injection
    const cookies = [
        { name: 'countryCode', value: 'TR', domain: '.zara.com' },
        { name: 'languageCode', value: 'tr', domain: '.zara.com' }
    ];
    await page.setCookie(...cookies);

    // Clean Share Link (Remove Query Params)
    const cleanUrl = shareUrl.split('?')[0];
    console.log(`Cleaned Share URL: ${cleanUrl}`);

    let targetUrl = cleanUrl;

    try {
        await page.goto(targetUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
        console.log("Initial load complete.");

        // Wait a bit for redirects
        await new Promise(r => setTimeout(r, 5000));

        console.log(`Final URL: ${page.url()}`);

        const title = await page.$eval('h1', el => el.innerText).catch(() => "No H1");
        console.log(`Title: ${title}`);

    } catch (e) {
        console.error("Error:", e);
    } finally {
        await browser.close();
    }
}

testShareLink();
