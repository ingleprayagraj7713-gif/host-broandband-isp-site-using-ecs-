require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');
const Razorpay = require('razorpay');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

const plans = [
  {
    id: 1,
    name: 'Fiber 200',
    speed: '200 Mbps',
    price: 699,
    description: 'Ideal for streaming and daily work-from-home needs.',
  },
  {
    id: 2,
    name: 'Fiber 500',
    speed: '500 Mbps',
    price: 999,
    description: 'Best for multi-user homes and 4K entertainment.',
  },
  {
    id: 3,
    name: 'Fiber 1G',
    speed: '1 Gbps',
    price: 1499,
    description: 'Premium high-speed access for smart homes and gamers.',
  },
];

const dbConfig = {
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
};

const dbPool = process.env.DB_HOST ? mysql.createPool(dbConfig) : null;

const razorpay = process.env.RAZORPAY_KEY && process.env.RAZORPAY_SECRET
  ? new Razorpay({
      key_id: process.env.RAZORPAY_KEY,
      key_secret: process.env.RAZORPAY_SECRET,
    })
  : null;

function issueToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET || 'dev-secret', { expiresIn: '7d' });
}

app.get('/api/health', async (req, res) => {
  if (!dbPool) {
    return res.json({ status: 'ok', database: 'not_configured' });
  }

  try {
    const [rows] = await dbPool.execute('SELECT 1 AS ok');
    return res.json({ status: 'ok', database: 'connected', result: rows[0] });
  } catch (error) {
    return res.status(500).json({ status: 'error', database: 'connection_failed', message: error.message });
  }
});

app.get('/api/plans', (req, res) => {
  res.json({ plans });
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }

  const validUsers = {
    'admin@viztel.test': 'password',
    'customer@viztel.test': 'password',
  };

  if (validUsers[email] !== password) {
    return res.status(401).json({ message: 'Invalid credentials.' });
  }

  const token = issueToken({ email, role: email.includes('admin') ? 'admin' : 'customer' });
  return res.json({
    token,
    user: {
      email,
      role: email.includes('admin') ? 'admin' : 'customer',
    },
  });
});

app.post('/api/payments/create-order', async (req, res) => {
  const { planId, amount, currency = 'INR', customerName = 'Viztel Customer' } = req.body || {};

  if (!planId || !amount) {
    return res.status(400).json({ message: 'planId and amount are required.' });
  }

  if (!razorpay) {
    return res.json({
      mock: true,
      orderId: `mock_order_${Date.now()}`,
      amount,
      currency,
      customerName,
      key: 'rzp_test_demo',
    });
  }

  try {
    const order = await razorpay.orders.create({
      amount: Number(amount) * 100,
      currency,
      receipt: `viztel_${Date.now()}`,
      notes: { planId, customerName },
    });

    return res.json(order);
  } catch (error) {
    return res.status(500).json({ message: 'Razorpay order creation failed.', error: error.message });
  }
});

app.get('/api/admin/overview', (req, res) => {
  res.json({
    activeSubscribers: 14250,
    monthlyRevenue: '₹48.2L',
    openTickets: 231,
    networkUptime: '99.98%',
    latestAlerts: ['Fiber cut on MG Road', 'New plan activation pending'],
  });
});

app.use((req, res) => {
  res.status(404).json({ message: 'Not found.' });
});

app.listen(PORT, () => {
  console.log(`Viztel backend listening on port ${PORT}`);
});
