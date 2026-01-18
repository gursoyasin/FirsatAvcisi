const express = require('express');
const router = express.Router();
const prisma = require('../config/db');

// Register for notifications
router.post('/register', async (req, res) => {
    // Logic moved from api.js or new logic
    res.json({ message: "Registered" });
});

module.exports = router;
