const { auth, db, admin } = require('../config/firebase');

/**
 * Service to reset a teacher's password on their EXISTING Firebase Auth account.
 *
 * Steps:
 * 1. Validate inputs (teacherId, newPassword).
 * 2. Resolve teacher's existing UID from Firestore (login_ids, users, teachers).
 * 3. Verify teacher's status (role === 'teacher', isActive === true).
 * 4. Verify existing Auth user exists in Firebase Authentication.
 * 5. Call auth.updateUser(existingUid, { password: newPassword }).
 * 6. Record audit entry in `password_resets_audit`.
 *
 * STRICT GUARANTEES:
 * - NEVER creates a new Firebase Auth account.
 * - NEVER deletes or alters the existing UID.
 * - NEVER modifies existing teacher assignments, classes, attendance, or profile records.
 */
async function resetTeacherPassword({ teacherId, newPassword, adminUid }) {
  // 1. Input sanitization & validation
  if (!teacherId || typeof teacherId !== 'string' || !teacherId.trim()) {
    const err = new Error('A valid Teacher ID is required');
    err.status = 400;
    err.code = 'INVALID_TEACHER_ID';
    throw err;
  }

  const cleanTeacherId = teacherId.trim().toUpperCase();

  if (!newPassword || typeof newPassword !== 'string') {
    const err = new Error('New password is required');
    err.status = 400;
    err.code = 'INVALID_PASSWORD';
    throw err;
  }

  const cleanPassword = newPassword.trim();
  if (cleanPassword.length < 8) {
    const err = new Error('Password must be at least 8 characters long');
    err.status = 400;
    err.code = 'PASSWORD_TOO_SHORT';
    throw err;
  }

  // 2. Resolve existing teacher UID from trusted Firestore mappings
  // First check login_ids/{cleanTeacherId}
  const loginDocSnap = await db.collection('login_ids').doc(cleanTeacherId).get();
  let resolvedUid = '';
  let loginData = null;

  if (loginDocSnap.exists) {
    loginData = loginDocSnap.data() || {};
    resolvedUid = (loginData.uid || '').trim();

    // Verify role in login_ids if present
    const loginRole = (loginData.role || '').toLowerCase();
    if (loginRole && loginRole !== 'teacher') {
      const err = new Error(`Identity ${cleanTeacherId} belongs to role '${loginRole}', not 'teacher'`);
      err.status = 400;
      err.code = 'ROLE_MISMATCH';
      throw err;
    }
  }

  // Fallback 1: Query users collection by userId == cleanTeacherId
  if (!resolvedUid) {
    const userQuery = await db.collection('users')
      .where('userId', '==', cleanTeacherId)
      .limit(1)
      .get();

    if (!userQuery.empty) {
      const uDoc = userQuery.docs[0];
      resolvedUid = (uDoc.data().uid || uDoc.id).trim();
    }
  }

  // Fallback 2: Check if teacherId is already the UID in users collection
  if (!resolvedUid) {
    const userDocDirect = await db.collection('users').doc(teacherId.trim()).get();
    if (userDocDirect.exists) {
      resolvedUid = (userDocDirect.data().uid || teacherId.trim()).trim();
    }
  }

  // Fallback 3: Check teachers/{cleanTeacherId} document
  if (!resolvedUid) {
    const teacherDocDirect = await db.collection('teachers').doc(cleanTeacherId).get();
    if (teacherDocDirect.exists) {
      const tData = teacherDocDirect.data() || {};
      resolvedUid = (tData.userId || tData.uid || cleanTeacherId).trim();
    }
  }

  if (!resolvedUid) {
    const err = new Error(`Could not resolve teacher UID for Teacher ID "${cleanTeacherId}". Teacher profile not found.`);
    err.status = 404;
    err.code = 'TEACHER_NOT_FOUND';
    throw err;
  }

  // 3. Verify user and teacher documents in Firestore
  const targetUserDoc = await db.collection('users').doc(resolvedUid).get();
  if (targetUserDoc.exists) {
    const uData = targetUserDoc.data() || {};
    const uRole = (uData.role || '').toLowerCase();
    if (uRole && uRole !== 'teacher') {
      const err = new Error(`User account for UID "${resolvedUid}" has role "${uRole}". Only teachers can be reset via this endpoint.`);
      err.status = 400;
      err.code = 'ROLE_MISMATCH';
      throw err;
    }
    if (uData.isActive === false) {
      const err = new Error(`Teacher account "${cleanTeacherId}" is marked inactive.`);
      err.status = 403;
      err.code = 'ACCOUNT_INACTIVE';
      throw err;
    }
  }

  // 4. Confirm the user exists in Firebase Authentication
  let existingAuthUser;
  try {
    existingAuthUser = await auth.getUser(resolvedUid);
  } catch (authError) {
    if (authError.code === 'auth/user-not-found') {
      const err = new Error(`No Firebase Authentication account found for teacher UID "${resolvedUid}".`);
      err.status = 404;
      err.code = 'AUTH_USER_NOT_FOUND';
      throw err;
    }
    throw authError;
  }

  if (existingAuthUser.disabled) {
    const err = new Error(`Firebase Authentication account for teacher "${cleanTeacherId}" is disabled.`);
    err.status = 403;
    err.code = 'ACCOUNT_DISABLED';
    throw err;
  }

  // 5. Update password on the EXISTING Firebase Auth account
  // This NEVER changes the UID or deletes the account.
  try {
    await auth.updateUser(resolvedUid, {
      password: cleanPassword,
    });
    console.log(`[TeacherPasswordService] Successfully updated password for existing UID=${resolvedUid} (teacherId=${cleanTeacherId}) by Admin=${adminUid}`);
  } catch (updateError) {
    console.error(`[TeacherPasswordService] Firebase auth.updateUser failed for UID=${resolvedUid}:`, updateError.message);
    const err = new Error(`Failed to update password: ${updateError.message}`);
    err.status = 500;
    err.code = 'AUTH_UPDATE_FAILED';
    throw err;
  }

  // Ensure login_ids mapping is healthy with the verified UID
  try {
    if (loginDocSnap.exists && (!loginData || !loginData.uid)) {
      await db.collection('login_ids').doc(cleanTeacherId).set({
        uid: resolvedUid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  } catch (healError) {
    console.warn(`[TeacherPasswordService] Could not update login_ids with UID:`, healError.message);
  }

  // 6. Record safe audit log
  try {
    await db.collection('password_resets_audit').add({
      adminUid: adminUid || 'unknown_admin',
      targetId: cleanTeacherId,
      targetUserId: cleanTeacherId,
      targetRole: 'teacher',
      targetUid: resolvedUid,
      method: 'external_node_admin_sdk',
      result: 'success',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (auditError) {
    // Non-fatal, do not fail successful reset if audit write fails
    console.warn(`[TeacherPasswordService] Audit log write failed:`, auditError.message);
  }

  return {
    success: true,
    message: 'Teacher password updated successfully.',
    teacherId: cleanTeacherId,
    targetUid: resolvedUid,
  };
}

module.exports = {
  resetTeacherPassword,
};
