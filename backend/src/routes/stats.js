const express = require('express');
const router = express.Router();
const { calculateAverageWaitingTime } = require('../services/statsService');

router.get('/summary', async (req, res) => {
    try {
        const avgWait = await calculateAverageWaitingTime();
        res.json({
            averageWaitingTime: avgWait
        });
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch stats" });
    }
});

module.exports = router;
