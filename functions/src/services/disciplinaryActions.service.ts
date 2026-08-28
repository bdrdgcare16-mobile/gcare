// functions/src/services/disciplinaryActions.service.ts
import { db, bucket } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';
import { DISCIPLINARY_STATUS, OTHER_OPTION } from '../constants/disciplinary';
import { DisciplinaryAction, DisciplinaryActionHistory } from '../models/disciplinaryActions.model';
import { createAndSend, getSuperAdmins } from '../services/notification.service';

const collection = db.collection(COLLECTIONS.DISCIPLINARY_ACTIONS);

interface ResolvedEmployee {
  uid: string;
  name: string;
  companyId: string;
  department: string;
  designation: string;
  reportingManager: string;
}

interface ResolvedUser {
  userId: string;
  name: string;
  designation?: string;
}

const normalizeString = (value: any): string =>
  value === undefined || value === null ? '' : String(value).trim();

const toBoolean = (value: any): boolean =>
  value === true ||
  value === 'true' ||
  value === 'yes' ||
  value === 'Yes' ||
  value === 1 ||
  value === '1';

export const resolveEmployeeByEmpid = async (
  empid: string,
  companyId: string
): Promise<ResolvedEmployee | null> => {
  if (!empid || !companyId) return null;

  const normalizedEmpid = String(empid).trim();

  const empSnap = await db
    .collection(COLLECTIONS.EMPLOYEES)
    .where('companyId', '==', companyId)
    .where('empid', '==', normalizedEmpid)
    .limit(1)
    .get();

  if (empSnap.empty) return null;

  const empData = empSnap.docs[0].data();

  const userSnap = await db
    .collection(COLLECTIONS.USERS)
    .where('companyId', '==', companyId)
    .where('empid', '==', normalizedEmpid)
    .limit(1)
    .get();

  const userDoc = userSnap.docs[0];
  const employeeUid = userDoc ? userDoc.id : '';
  const userData = userDoc ? userDoc.data() : {};

  if (!employeeUid) {
    console.warn('[DisciplinaryAction] Employee found but no user record:', empid);
    return null;
  }

  return {
    uid: employeeUid,
    name: normalizeString(empData.name || userData.name),
    companyId: normalizeString(empData.companyId),
    department: normalizeString(empData.dept || userData.dept),
    designation: normalizeString(empData.designation || userData.designation),
    reportingManager: normalizeString(
      empData.reportingManager || userData.reportingManager
    ),
  };
};

export const resolveUserById = async (userId: string): Promise<ResolvedUser | null> => {
  if (!userId) return null;
  const doc = await db.collection(COLLECTIONS.USERS).doc(userId).get();
  if (!doc.exists) return null;
  const data = doc.data() || {};
  return {
    userId: doc.id,
    name: normalizeString(data.name || data.fullName),
    designation: normalizeString(data.designation),
  };
};

const uploadEvidence = async (
  file: Express.Multer.File,
  companyId: string,
  employeeId: string
): Promise<string> => {
  const timestamp = Date.now();
  const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
  const filePath = `disciplinary/${companyId}/${employeeId}/${timestamp}-${safeName}`;
  const fileRef = bucket.file(filePath);

  await fileRef.save(file.buffer, {
    metadata: { contentType: file.mimetype },
  });

  // Keep files private; store path only.
  return filePath;
};

const getSignedUrl = async (filePath: string): Promise<string> => {
  if (!filePath) return '';
  const normalized = filePath
    .split('?')[0]
    .replace(`https://storage.googleapis.com/${bucket.name}/`, '')
    .replace(`${bucket.name}/`, '');

  const [signedUrl] = await bucket.file(normalized).getSignedUrl({
    action: 'read',
    expires: Date.now() + 15 * 60 * 1000,
  });

  return signedUrl;
};

const normalizeFilePath = (value: string): string => {
  if (!value) return value;
  let path = value.split('?')[0];
  if (path.includes('storage.googleapis.com/')) {
    path = path.split('storage.googleapis.com/')[1];
  }
  if (path.startsWith(`${bucket.name}/`)) {
    path = path.replace(`${bucket.name}/`, '');
  }
  return decodeURIComponent(path);
};

const toDateValue = (value: any): Date | null => {
  if (value === undefined || value === null) return null;
  if (value instanceof Date) return value;
  if (typeof value === 'object' && '_seconds' in value) {
    return new Date((value as any)._seconds * 1000);
  }
  const d = new Date(String(value));
  return isNaN(d.getTime()) ? null : d;
};

export const resolveEvidenceUrl = async (
  storagePath: string
): Promise<string> => {
  return getSignedUrl(normalizeFilePath(storagePath));
};

interface CreateParams {
  req: any;
  body: any;
  files?: any;
}

export const createDisciplinaryAction = async (params: CreateParams): Promise<string> => {
  const { req, body, files } = params;
  const adminUser = req.user as {
    userId: string;
    companyId: string;
    role: string;
    email?: string;
  };

  const companyId = String(adminUser.companyId).trim();
  const employeeId = normalizeString(body.employeeId);

  if (!employeeId) {
    throw new Error('Employee ID is required');
  }

  const employee = await resolveEmployeeByEmpid(employeeId, companyId);
  if (!employee) {
    throw new Error('Employee not found in this company');
  }

  if (employee.companyId !== companyId) {
    throw new Error('Employee does not belong to this company');
  }

  const admin = await resolveUserById(adminUser.userId);
  if (!admin) {
    throw new Error('Admin user not found');
  }

  let attachmentUrl: string | null = null;
  const evidenceFiles = files?.evidence;
  if (evidenceFiles && evidenceFiles.length > 0) {
    attachmentUrl = await uploadEvidence(
      evidenceFiles[0] as Express.Multer.File,
      companyId,
      employeeId
    );
  }

  const now = new Date();

  const data: DisciplinaryAction = {
    companyId,
    employeeId,
    employeeUid: employee.uid,
    employeeName: employee.name,
    department: employee.department,
    designation: employee.designation,
    reportingManager: body.reportingManager
      ? normalizeString(body.reportingManager)
      : employee.reportingManager,
    issuedBy: body.issuedBy ? normalizeString(body.issuedBy) : null,

    violationCategory: body.violationCategory,
    otherViolationCategory:
      body.violationCategory === OTHER_OPTION
        ? normalizeString(body.otherViolationCategory)
        : null,

    incidentDate: body.incidentDate,
    incidentTime: normalizeString(body.incidentTime) || null,
    incidentLocation: normalizeString(body.incidentLocation) || null,
    incidentDescription: normalizeString(body.incidentDescription),

    noticeType: body.noticeType,
    otherNoticeType:
      body.noticeType === OTHER_OPTION
        ? normalizeString(body.otherNoticeType)
        : null,

    severity: body.severity,
    subject: normalizeString(body.subject),
    reason: normalizeString(body.reason),

    responseRequired: toBoolean(body.responseRequired),
    responseDueDate:
      toBoolean(body.responseRequired) && body.responseDueDate
        ? normalizeString(body.responseDueDate)
        : null,

    proposedAction: body.proposedAction,
    otherProposedAction:
      body.proposedAction === OTHER_OPTION
        ? normalizeString(body.otherProposedAction)
        : null,

    finalAction: null,
    finalRemarks: null,

    effectiveFrom: body.effectiveFrom ? normalizeString(body.effectiveFrom) : null,
    effectiveUntil: body.effectiveUntil ? normalizeString(body.effectiveUntil) : null,

    attachmentUrl,

    status: DISCIPLINARY_STATUS.PENDING,

    createdBy: adminUser.userId,
    createdByName: admin.name,
    createdByRole: 'admin',
    createdByDesignation: admin.designation || '',
    createdAt: now,

    updatedBy: null,
    updatedAt: null,

    submittedBy: adminUser.userId,
    submittedAt: now,

    approvedBy: null,
    approvedByName: null,
    approvedAt: null,

    rejectedBy: null,
    rejectedByName: null,
    rejectedAt: null,
    rejectionReason: null,

    history: [],
  };

  const docRef = await collection.add(data);

  // Notify super admins (best-effort; never block main flow)
  try {
    const superAdmins = await getSuperAdmins();
    await Promise.all(
      superAdmins.map((admin) =>
        createAndSend({
          companyId: data.companyId,
          recipientUserId: admin.userId,
          actorUserId: data.createdBy,
          type: 'DISCIPLINARY_ACTION_SUBMITTED',
          title: 'New disciplinary action awaiting approval',
          body: 'A new disciplinary action has been submitted for your review.',
          entityType: 'disciplinary',
          entityId: docRef.id,
          data: {
            disciplinaryId: docRef.id,
            companyId: data.companyId,
          },
        })
      )
    );
  } catch (notifErr: any) {
    console.error(
      '[DisciplinaryAction] Submit notification error:',
      notifErr?.message || String(notifErr)
    );
  }

  return docRef.id;
};

interface GetListFilters {
  companyId?: string;
  employeeUid?: string;
  status?: string;
}

const mapDoc = (doc: any): DisciplinaryAction & { id: string } => {
  const data = doc.data() as DisciplinaryAction;
  return { id: doc.id, ...data };
};

export const getDisciplinaryActions = async (
  filters: GetListFilters
): Promise<(DisciplinaryAction & { id: string })[]> => {
  let query: any = collection;

  if (filters.companyId) {
    query = query.where('companyId', '==', filters.companyId);
  }

  if (filters.employeeUid) {
    query = query.where('employeeUid', '==', filters.employeeUid);
  }

  if (filters.status) {
    query = query.where('status', '==', filters.status);
  }

  // Order by createdAt desc (requires composite indexes defined in
  // firestore.indexes.json when combined with where clauses).
  query = query.orderBy('createdAt', 'desc');

  const snapshot = await query.get();
  const records = snapshot.docs.map(mapDoc);
  return records;
};

export const getDisciplinaryActionById = async (
  id: string
): Promise<(DisciplinaryAction & { id: string }) | null> => {
  const doc = await collection.doc(id).get();
  if (!doc.exists) return null;
  return mapDoc(doc);
};

interface UpdateParams {
  req: any;
  id: string;
  body: any;
  files?: any;
}

const buildUpdatePayload = (
  body: any,
  existing: DisciplinaryAction
): Partial<DisciplinaryAction> => {
  const payload: Partial<DisciplinaryAction> = {};

  const fieldsToUpdate = [
    'violationCategory',
    'incidentDate',
    'incidentTime',
    'incidentLocation',
    'incidentDescription',
    'noticeType',
    'severity',
    'subject',
    'reason',
    'responseRequired',
    'responseDueDate',
    'proposedAction',
    'effectiveFrom',
    'effectiveUntil',
  ];

  for (const field of fieldsToUpdate) {
    if (body[field] !== undefined) {
      (payload as any)[field] = body[field];
    }
  }

  if (body.reportingManager !== undefined) {
    payload.reportingManager = normalizeString(body.reportingManager) || '';
  }

  if (body.issuedBy !== undefined) {
    payload.issuedBy = normalizeString(body.issuedBy) || null;
  }

  if (body.adminRemarks !== undefined) {
    payload.finalRemarks = normalizeString(body.adminRemarks) || null;
  }

  payload.otherViolationCategory =
    payload.violationCategory === OTHER_OPTION ||
    (payload.violationCategory === undefined &&
      existing.violationCategory === OTHER_OPTION)
      ? normalizeString(body.otherViolationCategory) || null
      : null;

  payload.otherNoticeType =
    payload.noticeType === OTHER_OPTION ||
    (payload.noticeType === undefined && existing.noticeType === OTHER_OPTION)
      ? normalizeString(body.otherNoticeType) || null
      : null;

  payload.otherProposedAction =
    payload.proposedAction === OTHER_OPTION ||
    (payload.proposedAction === undefined &&
      existing.proposedAction === OTHER_OPTION)
      ? normalizeString(body.otherProposedAction) || null
      : null;

  payload.responseRequired =
    body.responseRequired !== undefined
      ? toBoolean(body.responseRequired)
      : existing.responseRequired;

  if (payload.responseRequired) {
    payload.responseDueDate = body.responseDueDate
      ? normalizeString(body.responseDueDate)
      : existing.responseDueDate;
  } else {
    payload.responseDueDate = null;
  }

  return payload;
};

export const updateDisciplinaryAction = async (
  params: UpdateParams
): Promise<void> => {
  const { req, id, body, files } = params;
  const adminUser = req.user as { userId: string; companyId: string };

  const existing = await getDisciplinaryActionById(id);
  if (!existing) {
    throw new Error('Disciplinary action not found');
  }

  if (existing.companyId !== String(adminUser.companyId)) {
    throw new Error('Access denied');
  }

  if (
    existing.status !== DISCIPLINARY_STATUS.PENDING &&
    existing.status !== DISCIPLINARY_STATUS.REJECTED
  ) {
    throw new Error('Only pending or rejected disciplinary actions can be edited');
  }

  const admin = await resolveUserById(adminUser.userId);
  if (!admin) {
    throw new Error('Admin user not found');
  }

  const updates = buildUpdatePayload(body, existing);

  let attachmentUrl = existing.attachmentUrl;
  const evidenceFiles = files?.evidence;
  if (evidenceFiles && evidenceFiles.length > 0) {
    attachmentUrl = await uploadEvidence(
      evidenceFiles[0] as Express.Multer.File,
      existing.companyId,
      existing.employeeId
    );
  }

  await collection.doc(id).update({
    ...updates,
    attachmentUrl,
    updatedBy: adminUser.userId,
    updatedAt: new Date(),
  });
};

export const resubmitDisciplinaryAction = async (
  params: UpdateParams
): Promise<void> => {
  const { req, id, body, files } = params;
  const adminUser = req.user as { userId: string; companyId: string };

  const existing = await getDisciplinaryActionById(id);
  if (!existing) {
    throw new Error('Disciplinary action not found');
  }

  if (existing.companyId !== String(adminUser.companyId)) {
    throw new Error('Access denied');
  }

  if (existing.status !== DISCIPLINARY_STATUS.REJECTED) {
    throw new Error('Only rejected disciplinary actions can be resubmitted');
  }

  const historyEntry: DisciplinaryActionHistory = {
    status: existing.status,
    changedBy: existing.rejectedBy || '',
    changedByName: existing.rejectedByName || '',
    changedAt: toDateValue(existing.rejectedAt) || new Date(),
    reason: existing.rejectionReason,
    remarks: null,
  };

  const currentHistory = Array.isArray(existing.history) ? existing.history : [];

  await updateDisciplinaryAction({
    req,
    id,
    body,
    files,
  });

  await collection.doc(id).update({
    status: DISCIPLINARY_STATUS.PENDING,
    submittedBy: adminUser.userId,
    submittedAt: new Date(),
    rejectedBy: null,
    rejectedByName: null,
    rejectedAt: null,
    rejectionReason: null,
    history: [...currentHistory, historyEntry],
  });
};

export const approveDisciplinaryAction = async (params: {
  req: any;
  id: string;
}): Promise<void> => {
  const { req, id } = params;
  const superAdmin = req.user as { userId: string; role: string };

  const existing = await getDisciplinaryActionById(id);
  if (!existing) {
    throw new Error('Disciplinary action not found');
  }

  if (existing.status !== DISCIPLINARY_STATUS.PENDING) {
    throw new Error('Only pending disciplinary actions can be approved');
  }

  const admin = await resolveUserById(superAdmin.userId);
  if (!admin) {
    throw new Error('Super admin user not found');
  }

  await collection.doc(id).update({
    status: DISCIPLINARY_STATUS.APPROVED,
    approvedBy: superAdmin.userId,
    approvedByName: admin.name,
    approvedAt: new Date(),
    updatedAt: new Date(),
  });

  // Notify the creating admin and the concerned employee (best-effort)
  try {
    await Promise.all([
      existing.createdBy
        ? createAndSend({
            companyId: existing.companyId,
            recipientUserId: existing.createdBy,
            actorUserId: superAdmin.userId,
            type: 'DISCIPLINARY_ACTION_APPROVED',
            title: 'Disciplinary action approved',
            body: 'A disciplinary action you submitted has been approved.',
            entityType: 'disciplinary',
            entityId: id,
            data: {
              disciplinaryId: id,
              employeeId: existing.employeeId,
            },
          })
        : Promise.resolve(),
      existing.employeeUid
        ? createAndSend({
            companyId: existing.companyId,
            recipientUserId: existing.employeeUid,
            actorUserId: superAdmin.userId,
            type: 'DISCIPLINARY_ACTION_APPROVED',
            title: 'A new disciplinary action is available for your review',
            body: 'A disciplinary action concerning you has been approved. Open the app to view details.',
            entityType: 'disciplinary',
            entityId: id,
            data: {
              disciplinaryId: id,
            },
          })
        : Promise.resolve(),
    ]);
  } catch (notifErr: any) {
    console.error(
      '[DisciplinaryAction] Approve notification error:',
      notifErr?.message || String(notifErr)
    );
  }
};

export const rejectDisciplinaryAction = async (params: {
  req: any;
  id: string;
  rejectionReason: string;
}): Promise<void> => {
  const { req, id, rejectionReason } = params;
  const superAdmin = req.user as { userId: string };

  const existing = await getDisciplinaryActionById(id);
  if (!existing) {
    throw new Error('Disciplinary action not found');
  }

  if (existing.status !== DISCIPLINARY_STATUS.PENDING) {
    throw new Error('Only pending disciplinary actions can be rejected');
  }

  const admin = await resolveUserById(superAdmin.userId);
  if (!admin) {
    throw new Error('Super admin user not found');
  }

  if (!rejectionReason || !rejectionReason.trim()) {
    throw new Error('Rejection reason is required');
  }

  await collection.doc(id).update({
    status: DISCIPLINARY_STATUS.REJECTED,
    rejectedBy: superAdmin.userId,
    rejectedByName: admin.name,
    rejectedAt: new Date(),
    rejectionReason: rejectionReason.trim(),
    updatedAt: new Date(),
  });

  // Notify the creating admin (best-effort)
  try {
    if (existing.createdBy) {
      await createAndSend({
        companyId: existing.companyId,
        recipientUserId: existing.createdBy,
        actorUserId: superAdmin.userId,
        type: 'DISCIPLINARY_ACTION_REJECTED',
        title: 'Disciplinary action rejected',
        body: 'A disciplinary action you submitted has been rejected. Open the app to see the reason.',
        entityType: 'disciplinary',
        entityId: id,
        data: {
          disciplinaryId: id,
          rejectionReason: rejectionReason.trim(),
        },
      });
    }
  } catch (notifErr: any) {
    console.error(
      '[DisciplinaryAction] Reject notification error:',
      notifErr?.message || String(notifErr)
    );
  }
};
