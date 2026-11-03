const test = require('node:test');
const assert = require('node:assert/strict');

// Mock Firebase config before requiring service
const mockAuthUsers = new Map();
const mockFirestoreData = {
  login_ids: new Map(),
  users: new Map(),
  teachers: new Map(),
  password_resets_audit: [],
};

// Seed baseline test state
mockAuthUsers.set('teacher_uid_123', {
  uid: 'teacher_uid_123',
  email: 'tch001@brightfutureclasses.app',
  disabled: false,
  password: 'OriginalPassword123',
});

mockFirestoreData.login_ids.set('TCH001', {
  userId: 'TCH001',
  authEmail: 'tch001@brightfutureclasses.app',
  role: 'teacher',
  isActive: true,
  uid: 'teacher_uid_123',
});

mockFirestoreData.users.set('teacher_uid_123', {
  uid: 'teacher_uid_123',
  userId: 'TCH001',
  role: 'teacher',
  name: 'Jane Doe',
  isActive: true,
});

mockFirestoreData.teachers.set('teacher_uid_123', {
  teacherId: 'teacher_uid_123',
  userId: 'TCH001',
  name: 'Jane Doe',
  classIds: ['cls_10a'],
  subjects: ['Mathematics'],
});

mockFirestoreData.users.set('admin_uid_777', {
  uid: 'admin_uid_777',
  userId: 'ADM001',
  role: 'admin',
  isActive: true,
});

mockFirestoreData.users.set('student_uid_888', {
  uid: 'student_uid_888',
  userId: 'STU001',
  role: 'student',
  isActive: true,
});

mockFirestoreData.users.set('inactive_admin_999', {
  uid: 'inactive_admin_999',
  userId: 'ADM002',
  role: 'admin',
  isActive: false,
});

// Setup mock firebase module
const mockFirebase = {
  auth: {
    getUser: async (uid) => {
      if (mockAuthUsers.has(uid)) return mockAuthUsers.get(uid);
      const err = new Error(`User not found: ${uid}`);
      err.code = 'auth/user-not-found';
      throw err;
    },
    updateUser: async (uid, updateData) => {
      if (!mockAuthUsers.has(uid)) {
        const err = new Error(`User not found: ${uid}`);
        err.code = 'auth/user-not-found';
        throw err;
      }
      const existing = mockAuthUsers.get(uid);
      // Strictly update password on existing user
      existing.password = updateData.password;
      return existing;
    },
    verifyIdToken: async (token) => {
      if (token === 'VALID_ADMIN_TOKEN') return { uid: 'admin_uid_777', role: 'admin' };
      if (token === 'STUDENT_TOKEN') return { uid: 'student_uid_888', role: 'student' };
      if (token === 'INACTIVE_ADMIN_TOKEN') return { uid: 'inactive_admin_999', role: 'admin' };
      const err = new Error('Invalid token');
      err.code = 'auth/argument-error';
      throw err;
    },
  },
  db: {
    collection: (collName) => ({
      doc: (docId) => ({
        get: async () => {
          const map = mockFirestoreData[collName];
          if (map && map.has(docId)) {
            return { exists: true, data: () => map.get(docId), id: docId };
          }
          return { exists: false, data: () => null, id: docId };
        },
        set: async (data, options) => {
          if (!mockFirestoreData[collName]) mockFirestoreData[collName] = new Map();
          mockFirestoreData[collName].set(docId, data);
        },
      }),
      where: (field, op, val) => ({
        limit: () => ({
          get: async () => {
            const map = mockFirestoreData[collName];
            const matching = [];
            if (map) {
              for (const [k, v] of map.entries()) {
                if (v[field] === val) matching.push({ id: k, data: () => v });
              }
            }
            return { empty: matching.length === 0, docs: matching };
          },
        }),
      }),
      add: async (data) => {
        if (!mockFirestoreData[collName]) mockFirestoreData[collName] = [];
        mockFirestoreData[collName].push(data);
        return { id: `doc_${Date.now()}` };
      },
    }),
  },
  admin: {
    firestore: {
      FieldValue: {
        serverTimestamp: () => new Date(),
      },
    },
  },
};

// Override require cache for ../config/firebase
const path = require('path');
const configFirebasePath = path.resolve(__dirname, '../config/firebase.js');
require.cache[configFirebasePath] = {
  id: configFirebasePath,
  filename: configFirebasePath,
  loaded: true,
  exports: mockFirebase,
};

const { resetTeacherPassword } = require('../services/teacherPasswordService');
const { verifyAuthToken } = require('../middleware/authMiddleware');
const { requireActiveAdmin } = require('../middleware/adminMiddleware');

test('Teacher Password Reset Tests Suite', async (t) => {
  await t.test('Test 1: Successfully resets password on EXISTING UID without modifying UID', async () => {
    const initialUid = 'teacher_uid_123';
    assert.equal(mockAuthUsers.get(initialUid).uid, initialUid);

    const result = await resetTeacherPassword({
      teacherId: 'TCH001',
      newPassword: 'BrandNewSecurePassword2026!',
      adminUid: 'admin_uid_777',
    });

    assert.equal(result.success, true);
    assert.equal(result.targetUid, initialUid);
    assert.equal(result.teacherId, 'TCH001');

    // Confirm UID remains identical in Auth
    const updatedUser = mockAuthUsers.get(initialUid);
    assert.equal(updatedUser.uid, initialUid);
    assert.equal(updatedUser.password, 'BrandNewSecurePassword2026!');

    // Confirm Firestore mappings remain completely untouched
    assert.equal(mockFirestoreData.login_ids.get('TCH001').uid, initialUid);
    assert.equal(mockFirestoreData.users.get(initialUid).uid, initialUid);
    assert.equal(mockFirestoreData.teachers.get(initialUid).teacherId, initialUid);
    assert.deepEqual(mockFirestoreData.teachers.get(initialUid).classIds, ['cls_10a']);
    assert.deepEqual(mockFirestoreData.teachers.get(initialUid).subjects, ['Mathematics']);
  });

  await t.test('Test 2: Rejects password shorter than 8 characters', async () => {
    await assert.rejects(
      async () => {
        await resetTeacherPassword({
          teacherId: 'TCH001',
          newPassword: 'short',
          adminUid: 'admin_uid_777',
        });
      },
      (err) => {
        assert.equal(err.code, 'PASSWORD_TOO_SHORT');
        assert.equal(err.status, 400);
        return true;
      }
    );
  });

  await t.test('Test 3: Rejects unknown / unmapped teacher ID', async () => {
    await assert.rejects(
      async () => {
        await resetTeacherPassword({
          teacherId: 'TCH_UNKNOWN_999',
          newPassword: 'ValidPassword123!',
          adminUid: 'admin_uid_777',
        });
      },
      (err) => {
        assert.equal(err.code, 'TEACHER_NOT_FOUND');
        assert.equal(err.status, 404);
        return true;
      }
    );
  });

  await t.test('Test 4: Security: Non-admin (Student) blocked by adminMiddleware', async () => {
    const req = { user: { uid: 'student_uid_888' } };
    let statusSent = null;
    let jsonSent = null;
    const res = {
      status: (s) => {
        statusSent = s;
        return {
          json: (j) => { jsonSent = j; },
        };
      },
    };
    let nextCalled = false;

    await requireActiveAdmin(req, res, () => { nextCalled = true; });

    assert.equal(nextCalled, false);
    assert.equal(statusSent, 403);
    assert.equal(jsonSent.code, 'FORBIDDEN_NOT_ADMIN');
  });

  await t.test('Test 5: Security: Inactive Admin blocked by adminMiddleware', async () => {
    const req = { user: { uid: 'inactive_admin_999' } };
    let statusSent = null;
    let jsonSent = null;
    const res = {
      status: (s) => {
        statusSent = s;
        return {
          json: (j) => { jsonSent = j; },
        };
      },
    };
    let nextCalled = false;

    await requireActiveAdmin(req, res, () => { nextCalled = true; });

    assert.equal(nextCalled, false);
    assert.equal(statusSent, 403);
    assert.equal(jsonSent.code, 'FORBIDDEN_NOT_ADMIN');
  });

  await t.test('Test 6: Security: Unauthenticated request rejected by authMiddleware', async () => {
    const req = { headers: {} };
    let statusSent = null;
    let jsonSent = null;
    const res = {
      status: (s) => {
        statusSent = s;
        return {
          json: (j) => { jsonSent = j; },
        };
      },
    };
    let nextCalled = false;

    await verifyAuthToken(req, res, () => { nextCalled = true; });

    assert.equal(nextCalled, false);
    assert.equal(statusSent, 401);
    assert.equal(jsonSent.code, 'UNAUTHENTICATED');
  });

  await t.test('Test 7: Security: Active Admin passes adminMiddleware successfully', async () => {
    const req = { user: { uid: 'admin_uid_777' } };
    const res = {};
    let nextCalled = false;

    await requireActiveAdmin(req, res, () => { nextCalled = true; });

    assert.equal(nextCalled, true);
    assert.equal(req.adminUser.uid, 'admin_uid_777');
  });

  await t.test('Test 8: Audit log was created with correct metadata and no password', () => {
    const audits = mockFirestoreData.password_resets_audit;
    assert.ok(audits.length > 0);
    const lastAudit = audits[audits.length - 1];
    assert.equal(lastAudit.adminUid, 'admin_uid_777');
    assert.equal(lastAudit.targetId, 'TCH001');
    assert.equal(lastAudit.targetUid, 'teacher_uid_123');
    assert.equal(lastAudit.targetRole, 'teacher');
    assert.equal(lastAudit.result, 'success');
    assert.equal(lastAudit.password, undefined); // Never records password!
  });
});
