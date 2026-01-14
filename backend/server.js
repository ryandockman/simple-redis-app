const express = require('express');
const redis = require('redis');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Redis client configuration
const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.on('connect', () => console.log('Connected to Redis'));

// Connect to Redis
(async () => {
  await redisClient.connect();
})();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Get all data from Redis
app.get('/api/data', async (req, res) => {
  try {
    const keys = await redisClient.keys('*');
    const data = [];
    
    for (const key of keys) {
      const value = await redisClient.get(key);
      data.push({ key, value });
    }
    
    res.json(data);
  } catch (error) {
    console.error('Error fetching data:', error);
    res.status(500).json({ error: 'Failed to fetch data' });
  }
});

// Add sample data to Redis
app.post('/api/add-sample', async (req, res) => {
  try {
    const timestamp = Date.now();
    const key = `sample-${timestamp}`;
    const value = `Sample data created at ${new Date().toISOString()}`;
    
    await redisClient.set(key, value);
    
    res.json({ 
      success: true, 
      message: 'Sample data added',
      key,
      value
    });
  } catch (error) {
    console.error('Error adding sample data:', error);
    res.status(500).json({ error: 'Failed to add sample data' });
  }
});

// Delete a key from Redis
app.delete('/api/data/:key', async (req, res) => {
  try {
    const { key } = req.params;
    await redisClient.del(key);
    res.json({ success: true, message: 'Key deleted' });
  } catch (error) {
    console.error('Error deleting key:', error);
    res.status(500).json({ error: 'Failed to delete key' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

