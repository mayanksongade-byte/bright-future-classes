const teacherPasswordService = require('../services/teacherPasswordService');

/**
 * Controller: Handles POST /api/teachers/reset-password
 */
async function resetTeacherPasswordHandler(req, res) {
  try {
    const { teacherId, newPassword } = req.body || {};
    const adminUid = req.adminUser ? req.adminUser.uid : (req.user ? req.user.uid : null);

    if (!teacherId || typeof teacherId !== 'string' || !teacherId.trim()) {
      return res.status(400).json({
        success: false,
        code: 'MISSING_TEACHER_ID',
        message: 'A valid teacherId is required in the request body',
      });
    }

    if (!newPassword || typeof newPassword !== 'string' || !newPassword.trim()) {
      return res.status(400).json({
        success: false,
        code: 'MISSING_PASSWORD',
        message: 'A valid newPassword is required in the request body',
      });
    }

    if (newPassword.trim().length < 8) {
      return res.status(400).json({
        success: false,
        code: 'PASSWORD_TOO_SHORT',
        message: 'Password must be at least 8 characters long',
      });
    }

    const result = await teacherPasswordService.resetTeacherPassword({
      teacherId,
      newPassword,
      adminUid,
    });

    return res.status(200).json(result);
  } catch (error) {
    const statusCode = error.status || 500;
    const errorCode = error.code || 'SERVER_ERROR';

    console.error(`[TeacherController] resetTeacherPassword failed: [${errorCode}] ${error.message}`);

    return res.status(statusCode).json({
      success: false,
      code: errorCode,
      message: error.message || 'An error occurred while resetting the teacher password',
    });
  }
}

module.exports = {
  resetTeacherPasswordHandler,
};
