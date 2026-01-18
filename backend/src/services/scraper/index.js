const browserService = require('./BrowserService');
const cheerio = require('cheerio');

async function scrapeProduct(url) {
    let page;
    try {
        page = await browserService.createPage();

        // Set extra headers to mimic real browser (Chrome 122)
        await page.setExtraHTTPHeaders({
            'Accept-Language': 'en-US,en;q=0.9,tr;q=0.8',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Sec-Ch-Ua': '"Not_A Brand";v="8", "Chromium";v="122", "Google Chrome";v="122"',
            'Sec-Ch-Ua-Mobile': '?0',
            'Sec-Ch-Ua-Platform': '"macOS"',
            'Upgrade-Insecure-Requests': '1'
        });

        // Desktop User-Agent (Chrome 122)
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36');

        // Inditex Cookie Injection to bypass "Select Region" / "Konum Seç"
        if (url.includes('zara.com') || url.includes('bershka.com') || url.includes('stradivarius.com') || url.includes('pullandbear.com') || url.includes('massimodutti.com') || url.includes('oysho.com') || url.includes('zarahome.com') || url.includes('lefties.com')) {
            const domain = url.match(/https?:\/\/(?:www\.)?([^\/]+)/)[1];
            const rootDomain = '.' + domain.split('.').slice(-2).join('.'); // .zara.com

            await page.setCookie(
                { name: 'countryCode', value: 'TR', domain: rootDomain },
                { name: 'languageCode', value: 'tr', domain: rootDomain },
                { name: 'storeId', value: '11728', domain: rootDomain } // Default Inditex store ID works for most
            );
            console.log(`Injected Inditex cookies for ${rootDomain}`);
        }

        // Universal Inditex Share Link Handling
        let isInditexShare = false;
        const inditexDomains = ['zara.com', 'bershka.com', 'stradivarius.com', 'pullandbear.com', 'massimodutti.com', 'oysho.com', 'zarahome.com', 'lefties.com'];
        const matchedInditex = inditexDomains.find(d => url.includes(d));

        if (matchedInditex && url.includes('/share/')) {
            console.log("Detected Inditex Share Link. Visiting directly to allow redirect...");
            // Do NOT convert to search. Let the share link redirect to the real product.
            // But we flag it to ensure we wait effectively.
            isInditexShare = true;
        }
        // H&M / Mango Clean
        if (url.includes('hm.com') || url.includes('mango.com') || url.includes('amazon.')) {
            if (url.includes('?')) url = url.split('?')[0]; // Amazon clean up
        }

        // Optimize Speed: Block Images, Fonts, Stylesheets
        await page.setRequestInterception(true);
        page.on('request', (req) => {
            if (['image', 'stylesheet', 'font', 'media'].includes(req.resourceType())) {
                req.abort();
            } else {
                req.continue();
            }
        });

        console.log(`Navigating to: ${url}`);

        // Optimize wait: 'domcontentloaded' is faster
        try {
            const waitOption = isInditexShare ? 'networkidle0' : 'domcontentloaded';
            await page.goto(url, { waitUntil: waitOption, timeout: 30000 });
        } catch (e) {
            console.log("Navigation timeout (domcontentloaded), scraping whatever loaded...");
        }

        // Universal Inditex Search Grid Click
        if (isInditexShare && url.includes('/search')) {
            try {
                const searchResultSelector = '.product-grid-product-info a, .product-link, li.product a, .product-grid-product, .grid-product-link';
                // Wait briefly to see if we are on a list page
                await page.waitForSelector(searchResultSelector, { timeout: 5000 });
                console.log("Inditex Search Grid detected. Clicking first result...");

                const firstProduct = await page.$(searchResultSelector);
                if (firstProduct) {
                    await Promise.all([
                        page.waitForNavigation({ waitUntil: 'domcontentloaded' }),
                        firstProduct.click()
                    ]);
                    console.log("Clicked product, new URL:", page.url());
                }
            } catch (e) {
                console.log("No search grid detected or timeout (maybe already on product page). Proceeding...");
            }
        }

        // UNIVERSAL WAIT: Ensure Product Page Content is Ready
        // If we came from search click OR direct redirect, we must wait for the H1/Title to appear.
        // UNIVERSAL WAIT: Ensure Product Page Content is Ready
        // For SPAs (Zara, Trendyol, etc.), domcontentloaded is NOT enough.
        console.log("Waiting for page content (h1)...");
        try {
            await page.waitForFunction(
                () => document.querySelector('h1') && document.querySelector('h1').innerText.length > 0,
                { timeout: 10000 } // 10s timeout
            );
        } catch (e) {
            console.log("Warning: Content wait timed out. proceeding...");
        }

        // CHECK FOR FAILED/STUCK REDIRECT (Share Link Trap)
        if (page.url().includes('/share/')) {
            console.log("Still on Share URL. Attempting to extract canonical URL from meta tags...");
            try {
                const canonical = await page.evaluate(() => {
                    return document.querySelector("meta[property='og:url']")?.content ||
                        document.querySelector("link[rel='canonical']")?.href ||
                        document.querySelector("meta[property='al:web:url']")?.content;
                });

                if (canonical && !canonical.includes('/share/')) {
                    console.log(`Found canonical URL in meta: ${canonical}. Manually navigating...`);
                    await page.goto(canonical, { waitUntil: 'domcontentloaded', timeout: 30000 });
                } else {
                    console.log("Could not find better canonical URL. Trying fallback search redirect...");
                    // Last resort: extract ID from URL hash or query if possible
                }
            } catch (e) {
                console.error("Meta redirect failed:", e);
            }
        }

        const finalUrl = page.url();
        console.log(`Final URL: ${finalUrl}`);

        // Sayfa içeriğini al
        const content = await page.content();
        const $ = cheerio.load(content);

        let title = "";
        let price = 0;
        let originalPrice = 0;
        let imageUrl = "";
        let source = "";
        let inStock = true; // Default assumption

        // Global Generic Strategies (JSON-LD & Meta Tags)
        // 1. Try Structured Data (JSON-LD) - Most Reliable
        try {
            const scripts = $("script[type='application/ld+json']");
            scripts.each((i, el) => {
                try {
                    const data = JSON.parse($(el).html());
                    // Check for Product schema
                    if (data['@type'] === 'Product' || data['@context']?.includes('schema.org')) {
                        const offers = data.offers;
                        if (!title && data.name) title = data.name;
                        if (!imageUrl && (data.image || data.image?.[0])) imageUrl = Array.isArray(data.image) ? data.image[0] : data.image;

                        if (offers) {
                            // Helper to check availability schema
                            const checkAvailability = (offer) => {
                                if (offer && offer.availability) {
                                    const avail = offer.availability;
                                    if (avail.includes("OutOfStock") || avail.includes("SoldOut")) return false;
                                    if (avail.includes("InStock")) return true;
                                }
                                return true; // Default if unknown
                            };

                            if (offers.price) {
                                price = parseFloat(offers.price);
                                inStock = checkAvailability(offers);
                                console.log(`Price found in JSON-LD (Single): ${price}, InStock: ${inStock}`);
                                return false; // break loop
                            }
                            if (Array.isArray(offers) || offers.lowPrice) {
                                price = parseFloat(offers.lowPrice || offers[0]?.price);
                                inStock = checkAvailability(Array.isArray(offers) ? offers[0] : offers);
                                console.log(`Price found in JSON-LD (Aggregate): ${price}, InStock: ${inStock}`);
                                return false; // break loop
                            }
                        }
                    }
                } catch (e) { /* ignore parse error */ }
            });
        } catch (e) {
            console.log("JSON-LD parsing failed", e);
        }

        // 2. Try Meta Tags (if JSON-LD failed)
        if (!price || price === 0) {
            const metaPrice = $("meta[property='product:price:amount']").attr("content") ||
                $("meta[property='og:price:amount']").attr("content") ||
                $("meta[itemprop='price']").attr("content");
            if (metaPrice) {
                price = parseFloat(metaPrice);
                console.log(`Price found in Meta Tag: ${price}`);
            }
            // Meta availability
            const metaAvail = $("meta[property='product:availability']").attr("content") ||
                $("meta[itemprop='availability']").attr("content");
            if (metaAvail) {
                if (metaAvail.includes("oos") || metaAvail.includes("out of stock") || metaAvail.includes("OutOfStock")) {
                    inStock = false;
                }
            }
        }

        if (!title) title = $("meta[property='og:title']").attr("content") || $("h1").first().text().trim();
        if (!imageUrl) {
            imageUrl = $("meta[property='og:image']").attr("content") ||
                $(".product-detail-images__image").attr("src") ||
                $(".main-image").attr("src");
        }

        // GENERIC SEARCH RESULT CLICKER (For Barcode Lookup mostly)
        if (title === "Ürün Başlığı Bulunamadı" || !title) {
            console.log("Title not found. Checking if this is a search result page...");
            // Add Zara/Inditex specific grid selectors - Prioritize Anchors
            const genericProductSelector = 'a.product-link, .product-grid-product a, .product-item a, .grid-card a, .p-card-wrppr a, .search-item a';
            const firstItem = await page.$(genericProductSelector);
            if (firstItem) {
                console.log("Found a product link in list. Clicking...");
                await Promise.all([
                    page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 20000 }),
                    firstItem.click()
                ]);
                console.log("Navigated to product link. Scraper should be restarted for full data, but returning URL for now.");
                // For simplicity in this iteration, we return the URL so the frontend can preview/scrape it properly
                // OR we could simple recursively call scrapeProduct here? No, too complex for now.
                // Let's just return the new URL as context so caller knows what happened.
                return {
                    title: "REDIRECT_REQUIRED",
                    currentPrice: 0,
                    imageUrl: "",
                    source: "unknown",
                    url: page.url()
                };
            }
        }


        // Domain Specific Fallbacks & Source Detection
        if (finalUrl.includes("trendyol.com")) {
            source = "trendyol";
            // Wait for selector to ensure content is loaded
            try { await page.waitForSelector('h1', { timeout: 5000 }); } catch (e) { }

            // Trendyol specific Title/Price override if generic failed
            if (!title) title = $("h1").first().text().trim();
            if (!price) {
                let priceText = $(".product-price-container .prc-dsc").text().trim() ||
                    $(".prc-dsc").text().trim() ||
                    $(".product-price-container").text().trim() ||
                    $(".ps-payment-methods .price").text().trim();
                price = parsePrice(priceText);
            }
            const orgPriceText = $(".prc-org").text().trim() || $(".original-price").text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);

            if (!imageUrl) imageUrl = $(".base-product-image > img").attr("src");

        } else if (finalUrl.includes("hepsiburada.com")) {
            source = "hepsiburada";
            title = $("h1#product-name").text().trim();

            const priceText = $("#offering-price").attr("content") || $(".markup").text().trim();
            price = parsePrice(priceText);

            const orgPriceText = $(".price-old").text().trim() || $(".old-price").text().trim();
            originalPrice = parsePrice(orgPriceText);

            imageUrl = $("img.product-image").attr("src");
        } else if (finalUrl.includes("amazon.")) {
            source = "amazon";
            // Amazon specifics
            try { await page.waitForSelector('#productTitle', { timeout: 5000 }); } catch (e) { }

            if (!title) title = $("#productTitle").text().trim();
            if (!price) {
                // Amazon often uses .a-price .a-offscreen
                // e.g. <span class="a-price"><span class="a-offscreen">12.999,00 TL</span></span>
                const priceText = $(".a-price .a-offscreen").first().text().trim() ||
                    $(".a-price").first().text().trim() ||
                    $("#price_inside_buybox").text().trim();
                price = parsePrice(priceText);
            }
            // List Price
            const orgPriceText = $(".a-text-price .a-offscreen").first().text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);

            if (!imageUrl) {
                imageUrl = $("#landingImage").attr("src") || $("#imgBlkFront").attr("src");
            }
        } else if (finalUrl.includes("zara.com")) {
            source = "zara";
            // Zara scraping relies heavily on JSON-LD logic above or specific fallbacks here
            if (!title) title = $("h1.product-detail-info__header-name").text().trim() ||
                $("h1.product-name").text().trim() ||
                $("h1").text().trim();

            if (!price) {
                // Selector strategy: Try strict single elements first
                let priceText = $(".price-current__amount .money-amount__main").first().text().trim() ||
                    $(".price-current__amount").first().text().trim() ||
                    $(".price__amount").first().text().trim();

                // Fallback for concatenated cases (e.g. "2.290 TL")
                if (!priceText) {
                    const stickyPrice = $(".product-detail-info__price-amount").first().text().trim();
                    if (stickyPrice) priceText = stickyPrice;
                }

                price = parsePrice(priceText);
            }

            const orgPriceText = $(".price-old__amount .money-amount__main").first().text().trim() ||
                $(".price-old__amount").first().text().trim() ||
                $(".product-detail-info__price-amount--old").text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);

        } else if (finalUrl.includes("bershka.com")) {
            source = "bershka";
            if (!title) title = $("h1").text().trim() || $(".product-title").text().trim() || $(".product-name").text().trim();
            if (!price) {
                const priceText = $(".current-price-elem").text().trim() ||
                    $(".price-current").text().trim() ||
                    $(".product-price").text().trim() ||
                    $(".current-price").text().trim();
                price = parsePrice(priceText);
            }
            const orgPriceText = $(".old-price-elem").text().trim() ||
                $(".product-price-old").text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);

        } else if (finalUrl.includes("stradivarius.com")) {
            source = "stradivarius";
            if (!title) title = $("div[data-qa-label='product-name']").text().trim() || $("h1").text().trim() || $(".product-name").text().trim();
            if (!price) {
                const priceText = $(".price-current").text().trim() ||
                    $("span[data-qa-label='product-price']").text().trim() ||
                    $(".product-price").text().trim(); // Added
                price = parsePrice(priceText);
            }
            const orgPriceText = $(".price-old").text().trim() ||
                $("span[data-qa-label='product-old-price']").text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);

        } else if (finalUrl.includes("pullandbear.com")) {
            source = "pullandbear";
            if (!title) title = $("h1").text().trim() || $(".product-name").text().trim() || $("#product-name").text().trim();
            if (!price) {
                const priceText = $("span[data-qa-label='product-price']").text().trim() ||
                    $(".current-price").text().trim() ||
                    $(".price-current").text().trim();
                price = parsePrice(priceText);
            }
            const orgPriceText = $("span[data-qa-label='product-old-price']").text().trim() ||
                $(".old-price").text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);

        } else if (finalUrl.includes("oysho.com")) {
            source = "oysho";
            if (!title) title = $("h1").text().trim();
            if (!price) {
                const priceText = $(".price-current").text().trim() ||
                    $(".product-price").text().trim();
                price = parsePrice(priceText);
            }
            const orgPriceText = $(".price-old").text().trim() ||
                $(".product-old-price").text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);

        } else if (finalUrl.includes("massimodutti.com")) {
            source = "massimodutti";
            if (!title) title = $("h1").text().trim();
            if (!price) {
                const priceText = $(".price-current").text().trim() ||
                    $(".product-price-current").text().trim();
                price = parsePrice(priceText);
            }
            const orgPriceText = $(".price-old").text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);

        } else if (finalUrl.includes("zarahome.com")) {
            source = "zarahome";
            if (!title) title = $("h1").text().trim();
            if (!price) {
                const priceText = $(".price-current-elem").text().trim() ||
                    $(".price").text().trim() ||
                    $(".product-price").text().trim();
                price = parsePrice(priceText);
            }

        } else if (finalUrl.includes("lefties.com")) {
            source = "lefties";
            if (!title) title = $(".product-name").text().trim() || $("h1").text().trim();
            if (!price) {
                const priceText = $(".current-price").text().trim() ||
                    $(".product-price").text().trim();
                price = parsePrice(priceText);
            }
            const orgPriceText = $(".old-price").text().trim();
            if (orgPriceText) originalPrice = parsePrice(orgPriceText);
        } else if (finalUrl.includes("mango.com")) {
            source = "mango";
            if (!title) title = $("h1").text().trim();
            if (!price) {
                const priceText = $("span[data-testid='current-price']").text().trim() || $(".product-price").text().trim();
                price = parsePrice(priceText);
            }
        } else if (finalUrl.includes("hm.com")) {
            source = "hm";
            if (!title) title = $("h1").text().trim();
            if (!price) {
                // H&M specific
                const priceText = $("#product-price .price-value").text().trim() || $(".price-value").text().trim();
                price = parsePrice(priceText);
            }
            if (!imageUrl) {
                imageUrl = $("figure.pdp-image img").first().attr("src") || $("img.product-detail-main-image").attr("src");
            }
        } // Generic Fallback for JSON-LD is already handled above in the Trendyol block, wait...
        // The previous code had JSON-LD logic INSIDE the Trendyol block. This is a mistake.
        // I need to pull the generic extraction OUT of the Trendyol specific block so it runs for everyone.


        if (!title) {
            console.log("Visual title not found. Attempting Meta Tag extraction...");
            title = $("meta[property='og:title']").attr("content") ||
                $("meta[name='twitter:title']").attr("content");

            if (!imageUrl) {
                imageUrl = $("meta[property='og:image']").attr("content") ||
                    $("meta[name='twitter:image']").attr("content");
            }

            if (!price) {
                // Try og:price:amount or text in description
                const ogPrice = $("meta[property='og:price:amount']").attr("content") ||
                    $("meta[property='product:price:amount']").attr("content");
                if (ogPrice) price = parsePrice(ogPrice);
            }

            if (title) console.log(`Recovered via Meta Tags: ${title}`);
            else console.error("Scraper Error: Title still not found after Meta Tag fallback.");
        }

        // Categorization Logic
        const detectCategory = (url, title, content) => {
            const lowerTitle = (title || "").toLowerCase();
            const lowerUrl = url.toLowerCase();

            if (lowerUrl.includes("elektronik") || lowerUrl.includes("teknoloji") || lowerUrl.includes("bilgisayar") || lowerUrl.includes("telefon") ||
                lowerTitle.includes("iphone") || lowerTitle.includes("samsung") || lowerTitle.includes("laptop")) return "elektronik";

            if (lowerUrl.includes("giyim") || lowerUrl.includes("ayakkabi") || lowerUrl.includes("elbise") || lowerUrl.includes("kadin") || lowerUrl.includes("erkek") ||
                lowerUrl.includes("zara") || lowerUrl.includes("bershka") || lowerUrl.includes("stradivarius") || lowerUrl.includes("pullandbear") ||
                lowerUrl.includes("lefties") || lowerUrl.includes("mango") || lowerUrl.includes("hm")) return "moda";

            if (lowerUrl.includes("kozmetik") || lowerUrl.includes("bakim") || lowerUrl.includes("parfum") || lowerTitle.includes("parfüm")) return "kozmetik";

            if (lowerUrl.includes("ev-yasam") || lowerUrl.includes("mobilya") || lowerUrl.includes("mutfak") || lowerUrl.includes("zarahome")) return "ev";

            return "diger";
        };

        const category = detectCategory(finalUrl, title, content);

        return {
            title: title || "Ürün Başlığı Bulunamadı",
            currentPrice: price,
            originalPrice: originalPrice,
            imageUrl: imageUrl || "https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg",
            source: source || "unknown",
            url: finalUrl,
            inStock: inStock,
            category: category
        };

    } catch (error) {
        console.error("Scraping error:", error);
        throw new Error(`Ürün bilgileri çekilemedi: ${error.message}`);
    } finally {
        if (page) await page.close();
    }
}

function parsePrice(text) {
    if (!text) return 0;

    // Clean weird characters but keep digits, dots, commas
    let clean = text.replace(/[^\d.,]/g, '').trim();

    // Check format: Turkish/European (1.299,90) vs US (1,299.90)
    // Heuristic: If last punctuation is ',', it's decimal. If last is '.', it's decimal (US).

    const lastComma = clean.lastIndexOf(',');
    const lastDot = clean.lastIndexOf('.');

    if (lastComma > lastDot) {
        // Turkish/Euro format: 1.299,90 -> Remove dots, replace comma with dot
        clean = clean.replace(/\./g, '').replace(',', '.');
    } else if (lastDot > lastComma) {
        // US format: 1,299.90 -> Remove commas
        clean = clean.replace(/,/g, '');
    } else {
        // No separators or just one.
        // If "2290" -> 2290
        // If "2290,00" -> 2290.00 (handled by first case technically if comma exists)
    }

    return parseFloat(clean) || 0;
}

module.exports = { scrapeProduct };
