const express = require('express');
const { verifyAuthToken } = require('../middleware/authMiddleware');
const { requireActiveAdmin } = require('../middleware/adminMiddleware');
const { resetTeacherPasswordHandler } = require('../controllers/teacherController');

const router = express.Router();

/**
 * POST /api/teachers/reset-password
 *
 * Security:
 * 1. verifyAuthToken: Checks Firebase ID token in Authorization header.
 * 2. requireActiveAdmin: Verifies caller has role === 'admin' and isActive === true.
 * 3. resetTeacherPasswordHandler: Validates teacher, resolves UID, updates existing Auth account.
 */
router.post(
  '/reset-password',
  verifyAuthToken,
  requireActiveAdmin,
  resetTeacherPasswordHandler
);

module.exports = router;
