const express = require('express');
const router = express.Router();
const prisma = require('../config/db');
const browserService = require('../services/scraper/BrowserService');
const fs = require('fs');
const path = require('path');

// LIGHT HEALTH CHECK (For Load Balancers)
router.get('/', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date() });
});

// DEEP HEALTH CHECK (For Debugging Render)
router.get('/deep', async (req, res) => {
    const report = {
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV,
        checks: {}
    };

    // 1. DATABASE CHECK
    try {
        await prisma.$queryRaw`SELECT 1`;
        report.checks.database = { status: 'ok', type: 'postgres/sqlite' };
    } catch (e) {
        report.checks.database = { status: 'failed', error: e.message };
    }

    // 2. BROWSER CHECK (Puppeteer)
    try {
        const browser = await browserService.getBrowser();
        const version = await browser.version();
        report.checks.browser = { status: 'ok', version: version };
    } catch (e) {
        report.checks.browser = { status: 'failed', error: e.message, hint: "Check .puppeteerrc.cjs and render-build.sh" };
    }

    // 3. FILESYSTEM CHECK (Write Permission)
    try {
        const testPath = path.join(__dirname, '../../test_write.txt');
        fs.writeFileSync(testPath, 'write_test');
        fs.unlinkSync(testPath);
        report.checks.filesystem = { status: 'ok', writeable: true };
    } catch (e) {
        report.checks.filesystem = { status: 'warning', error: e.message, note: "Ephemeral FS on Render is expected." };
    }

    // 4. MEMORY USAGE
    const used = process.memoryUsage();
    report.checks.memory = {
        rss: `${Math.round(used.rss / 1024 / 1024)} MB`,
        heapTotal: `${Math.round(used.heapTotal / 1024 / 1024)} MB`,
        heapUsed: `${Math.round(used.heapUsed / 1024 / 1024)} MB`
    };

    // 5. EXTERNAL CONNECTIVITY (Optional)
    // We can try to fetch google.com to see if outgoing is allowed
    try {
        // Simple fetch test if node 18+
        const start = Date.now();
        await fetch('https://www.google.com');
        report.checks.connectivity = { status: 'ok', latency: `${Date.now() - start}ms` };
    } catch (e) {
        report.checks.connectivity = { status: 'failed', error: e.message };
    }

    // Overall Status
    const isCriticalFailure = report.checks.database.status === 'failed';
    const status = isCriticalFailure ? 500 : 200;

    res.status(status).json(report);
});

module.exports = router;
