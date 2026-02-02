const winston = require('winston');
const path = require('path');

// Log format definition
const logFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
);

// Create the logger
const logger = winston.createLogger({
    level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
    format: logFormat,
    defaultMeta: { service: 'firsat-avcisi-backend' },
    transports: [
        // Write all logs with importance level of `error` or less to `error.log`
        new winston.transports.File({
            filename: path.join(__dirname, '../../logs/error.log'),
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
        // Write all logs with importance level of `info` or less to `combined.log`
        new winston.transports.File({
            filename: path.join(__dirname, '../../logs/combined.log'),
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
    ],
});

// If we're not in production then log to the `console` with the format:
// `${info.level}: ${info.message} JSON.stringify({ ...rest }) `
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
        ),
    }));
}

module.exports = logger;

// Discord Webhook Integration
// Usage: logger.notifyDiscord("🚨 ALERT: Scraper Failed!")
logger.notifyDiscord = async (message) => {
    const webhookUrl = process.env.DISCORD_WEBHOOK_URL;
    if (!webhookUrl) return;

    try {
        // Use dynamic import for fetch if needed or simple fetch if Node 18+
        // Assuming Node 18+ which has global fetch, otherwise use axios if available or https
        // Using standard https for zero-dependency
        const https = require('https');
        const url = new URL(webhookUrl);

        const data = JSON.stringify({
            content: message,
            username: "Fırsat Avcısı Bot",
            avatar_url: "https://i.imgur.com/4M34hi2.png"
        });

        const options = {
            hostname: url.hostname,
            path: url.pathname + url.search,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = https.request(options, (res) => {
            // fire and forget
        });

        req.on('error', (error) => {
            console.error('Discord Webhook Error:', error);
        });

        req.write(data);
        req.end();
    } catch (error) {
        console.error('Failed to send Discord notification:', error);
    }
};
