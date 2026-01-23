const { join } = require('path');

/**
 * @type {import("puppeteer").Configuration}
 */
module.exports = {
    // Changes the cache location for Puppeteer to be inside the project folder
    // enabling it to be carried over from build to run time on Render.
    cacheDirectory: join(__dirname, '.cache', 'puppeteer'),
};
