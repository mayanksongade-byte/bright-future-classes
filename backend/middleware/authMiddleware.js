const { auth } = require('../config/firebase');

/**
 * Authentication Middleware:
 * Extracts Bearer token from Authorization header and verifies it via Firebase Admin SDK.
 * Populates req.user with decoded token data (including uid).
 */
async function verifyAuthToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        code: 'UNAUTHENTICATED',
        message: 'Authorization token is required (Format: Bearer <token>)',
      });
    }

    const idToken = authHeader.split('Bearer ')[1].trim();
    if (!idToken) {
      return res.status(401).json({
        success: false,
        code: 'UNAUTHENTICATED',
        message: 'Bearer token cannot be empty',
      });
    }

    const decodedToken = await auth.verifyIdToken(idToken);
    req.user = decodedToken; // contains uid, email, etc.
    next();
  } catch (error) {
    console.error('[AuthMiddleware] Token verification failed:', error.code || error.message);
    return res.status(401).json({
      success: false,
      code: 'INVALID_TOKEN',
      message: 'Invalid, expired, or malformed authentication token',
    });
  }
}

module.exports = {
  verifyAuthToken,
};
