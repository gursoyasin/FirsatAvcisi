const browserService = require('./src/services/scraper/BrowserService');
const cheerio = require('cheerio');
const fs = require('fs');

async function debugAkakce() {
    console.log("🚀 Debugging Akakçe...");
    let page;
    try {
        page = await browserService.createPage();
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        await page.goto('https://www.akakce.com/arama/?q=iphone+15', { waitUntil: 'domcontentloaded', timeout: 30000 });

        // Wait a bit
        await new Promise(r => setTimeout(r, 5000));

        const content = await page.content();
        console.log(`Length: ${content.length}`);

        const $ = cheerio.load(content);
        const title = $('title').text();
        console.log(`Page Title: ${title}`);

        const listItems = $('.p-v8 > li, .m-p-v8 > li, #CList > li').length;
        console.log(`List Items found: ${listItems}`);

        fs.writeFileSync('akakce_dump.html', content);
        console.log("Dumped HTML to akakce_dump.html");

    } catch (e) {
        console.error(e);
    } finally {
        if (page) await page.close();
    }
}

debugAkakce();
