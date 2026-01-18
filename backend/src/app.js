const express = require('express');
const cors = require('cors');
const apiRoutes = require('./routes/api');
const collectionRoutes = require('./routes/collections');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api', apiRoutes);
app.use('/api/collections', collectionRoutes);

app.get('/', (req, res) => {
    res.send('Firsat Avcısı Backend is Running');
});

module.exports = app;
