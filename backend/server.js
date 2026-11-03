require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const teacherRoutes = require('./routes/teacherRoutes');

const app = express();

// Trust proxy for Render / Cloud reverse proxies (needed for rate-limiting by real client IP)
app.set('trust proxy', 1);

// JSON body parser with payload limit
app.use(express.json({ limit: '10kb' }));

// CORS configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : null;

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (e.g. mobile apps like Flutter, curl, server-to-server)
      if (!origin) return callback(null, true);
      if (!allowedOrigins || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error(`Origin ${origin} not permitted by CORS policy`));
    },
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Global rate limiting: max 100 requests per 15 minutes per IP
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    code: 'RATE_LIMIT_EXCEEDED',
    message: 'Too many requests from this IP. Please try again after 15 minutes.',
  },
});
app.use(globalLimiter);

// Specific stricter rate limiting for sensitive password-reset endpoints:
// Max 10 attempts per 15 minutes per IP
const resetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    code: 'RESET_RATE_LIMIT_EXCEEDED',
    message: 'Too many password reset requests. Please try again later.',
  },
});

// Health check endpoint (for Render health monitoring & uptime checks)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'bright-future-classes-backend',
    timestamp: new Date().toISOString(),
  });
});

// Mounted Routes
app.use('/api/teachers', resetLimiter, teacherRoutes);

// Catch-all for undefined routes
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    code: 'NOT_FOUND',
    message: `Cannot ${req.method} ${req.originalUrl}`,
  });
});

// Centralized error handler
app.use((err, req, res, next) => {
  console.error('[ServerError]', err);
  const status = err.status || 500;
  res.status(status).json({
    success: false,
    code: err.code || 'INTERNAL_SERVER_ERROR',
    message: err.message || 'An unexpected internal server error occurred',
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`[Server] Bright Future Classes backend running on port ${PORT}`);
  console.log(`[Server] Health check available at http://localhost:${PORT}/health`);
});

module.exports = app;
