const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
    // Default error properties
    let statusCode = err.statusCode || 500;
    let message = err.message || 'Internal Server Error';

    // Log the error
    logger.error(`${statusCode} - ${message} - ${req.originalUrl} - ${req.method} - ${req.ip} - Stack: ${err.stack}`);

    // Specific handling for common errors (e.g., Prisma, Validation)
    if (err.name === 'ValidationError') {
        statusCode = 400;
    }

    // Send response
    res.status(statusCode).json({
        success: false,
        error: {
            message: message,
            ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
        }
    });
};

module.exports = errorHandler;
