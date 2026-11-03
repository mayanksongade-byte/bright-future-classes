const { db } = require('../config/firebase');

/**
 * Admin Authorization Middleware:
 * Verifies that the authenticated user (from req.user.uid) has an active admin profile
 * in the Firestore `users` collection.
 */
async function requireActiveAdmin(req, res, next) {
  try {
    const callerUid = req.user && req.user.uid;
    if (!callerUid) {
      return res.status(401).json({
        success: false,
        code: 'UNAUTHENTICATED',
        message: 'No authenticated user identity found',
      });
    }

    const userDocSnap = await db.collection('users').doc(callerUid).get();
    if (!userDocSnap.exists) {
      return res.status(403).json({
        success: false,
        code: 'PROFILE_NOT_FOUND',
        message: 'Caller user profile does not exist in the database',
      });
    }

    const userData = userDocSnap.data() || {};
    const role = (userData.role || '').toLowerCase();
    const isActive = userData.isActive !== false;

    if (role !== 'admin' || !isActive) {
      console.warn(`[AdminMiddleware] Denied non-admin or inactive caller: ${callerUid} (role=${role}, isActive=${isActive})`);
      return res.status(403).json({
        success: false,
        code: 'FORBIDDEN_NOT_ADMIN',
        message: 'Access restricted: Only active administrators are authorized to perform this operation',
      });
    }

    req.adminUser = {
      uid: callerUid,
      name: userData.name || 'Admin',
      email: userData.email || req.user.email || '',
    };

    next();
  } catch (error) {
    console.error('[AdminMiddleware] Error checking admin status:', error.message);
    return res.status(500).json({
      success: false,
      code: 'INTERNAL_AUTH_ERROR',
      message: 'Failed to verify administrator privileges',
    });
  }
}

module.exports = {
  requireActiveAdmin,
};
