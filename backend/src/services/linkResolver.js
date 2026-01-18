const browserService = require('./scraper/BrowserService');

/**
 * Resolves a redirecting URL (like Cimri's outgoing links) to its final destination
 * without making the user see the intermediary redirects.
 */
async function resolveFinalUrl(initialUrl) {
    if (!initialUrl.includes('cimri.com')) return initialUrl;

    let page = null;
    try {
        page = await browserService.createPage();

        // Block heavy resources for speed
        await page.setRequestInterception(true);
        page.on('request', (request) => {
            if (['image', 'stylesheet', 'font', 'media'].includes(request.resourceType())) {
                request.abort();
            } else {
                request.continue();
            }
        });

        // Set a timeout for the navigation
        console.log(`🛡️ Resolving Deep Link: ${initialUrl}`);

        // We wait until the URL changes to a non-cimri domain
        // or until the first meaningful redirect happens
        await page.goto(initialUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });

        // Wait a small bit for JS redirects if any
        await new Promise(r => setTimeout(r, 1000));

        let currentUrl = page.url();

        // 🚨 IF WE ARE STILL ON CIMRI, IT MIGHT BE A PRODUCT PAGE
        // We need to click the main "Go to Store" button
        if (currentUrl.includes('cimri.com')) {
            console.log("⚠️ Still on Cimri. Attempting to click 'Go to Store'...");

            // Selectors for Cimri's "Go to Store" button
            // Usually: a[href*="/offer/"], button containing "Mağazaya Git"
            try {
                // Wait for potential offer links
                const offerSelector = 'a[href^="https://www.cimri.com/offer/"], a[rel="nofollow sponsored"]';
                await page.waitForSelector(offerSelector, { timeout: 3000 });

                // Get the first offer link
                const offerLink = await page.$eval(offerSelector, el => el.href);

                if (offerLink) {
                    console.log(`⚡️ Found Offer Link: ${offerLink}`);
                    // Navigate to the offer link
                    await page.goto(offerLink, { waitUntil: 'domcontentloaded', timeout: 15000 });
                    await new Promise(r => setTimeout(r, 1000)); // Wait for redirect
                    currentUrl = page.url();
                }
            } catch (e) {
                console.log("⚠️ Could not find auto-redirect button on Cimri page.");
            }
        }

        console.log(`✅ Resolved to: ${currentUrl}`);

        return currentUrl;
    } catch (error) {
        console.error(`❌ Failed to resolve URL: ${error.message}`);
        return initialUrl; // Return original on failure
    } finally {
        if (page) await page.close();
    }
}

module.exports = { resolveFinalUrl };
