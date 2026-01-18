const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

// Add stealth plugin and use it as default
puppeteer.use(StealthPlugin());

class BrowserService {
    constructor() {
        this.browser = null;
        this.proxyList = (process.env.PROXY_LIST || "").split(',').filter(p => p.length > 0);
        this.currentProxyIndex = 0;
    }

    async getBrowser() {
        if (this.browser) {
            // Check if browser is still connected
            try {
                await this.browser.version();
                return this.browser;
            } catch (e) {
                console.log("Browser disconnected, restarting...");
                this.browser = null;
            }
        }

        const args = [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
            '--window-size=1920,1080'
        ];

        // If we have proxies, rotate them
        if (this.proxyList.length > 0) {
            const proxy = this.proxyList[this.currentProxyIndex];
            args.push(`--proxy-server=${proxy}`);
            this.currentProxyIndex = (this.currentProxyIndex + 1) % this.proxyList.length;
            console.log(`Using Proxy: ${proxy}`);
        }

        this.browser = await puppeteer.launch({
            headless: "new",
            args: args
        });

        return this.browser;
    }

    async createPage() {
        const browser = await this.getBrowser();
        const page = await browser.newPage();

        // Anti-Detection tweaks
        await page.setViewport({ width: 1920, height: 1080 });

        // Randomize User-Agent for each page
        const userAgents = [
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        ];
        const ua = userAgents[Math.floor(Math.random() * userAgents.length)];
        await page.setUserAgent(ua);

        return page;
    }

    async close() {
        if (this.browser) {
            await this.browser.close();
            this.browser = null;
        }
    }
}

// Singleton instance
const browserService = new BrowserService();

module.exports = browserService;
