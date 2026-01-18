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
const notificationsRoutes = require('./routes/notifications'); // If exists
const scraperService = require('./services/scraper');
const trackerService = require('./services/tracker');

const app = express();
const PORT = process.env.PORT || 3000;

// Security & Optimization Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(bodyParser.json());

// Rate Limiting (Basic protection)
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
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

// Health Check
app.get('/', (req, res) => {
    res.send('Fırsat Avcısı Backend Ultra ++ is running 🚀');
});

// Global Error Handler (Must be last)
app.use(errorHandler);

// Start Server
app.listen(PORT, () => {
    logger.info(`Server is running on port ${PORT}`);

    // Start background tasks
    trackerService.startPriceTracker();
});
