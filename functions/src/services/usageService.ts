import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase';

function getCurrentMonth(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  return `${year}-${month}`;
}

export async function trackUsage(params: {
  companyId: string;
  companyName: string;
  plan: string;
  updates: Record<string, number>;
}) {
  const { companyId, companyName, plan, updates } = params;

  const month = getCurrentMonth();
  const docId = `${companyId}_${month}`;
  const docRef = db.collection('usage').doc(docId);

  const payload: Record<string, any> = {
    companyId,
    companyName,
    month,
    plan,
    lastUpdatedAt: new Date(),
  };

  const docSnap = await docRef.get();

  if (!docSnap.exists) {
    payload.createdAt = new Date();
    payload.readCount = 0;
    payload.writeCount = 0;
    payload.deleteCount = 0;
    payload.apiCalls = 0;
    payload.storageUsedMb = 0;
    payload.fileUploadCount = 0;
    payload.attendanceCount = 0;
    payload.taskUploadCount = 0;
    payload.eventUploadCount = 0;
  }

  // Calculate fresh employee counts each time
  try {
    // Count total employees for this company
    const totalEmployeesSnap = await db
      .collection('employees')
      .where('companyId', '==', companyId)
      .get();
    
    // Count active employees (status = "active", case-insensitive)
    const activeEmployeesSnap = await db
      .collection('employees')
      .where('companyId', '==', companyId)
      .where('status', '==', 'active')
      .get();
    
    payload.employeeCount = totalEmployeesSnap.size;
    payload.activeEmployeeCount = activeEmployeesSnap.size;
  } catch (error) {
    console.error('Error calculating employee counts:', error);
    // Fallback to existing values or 0 if calculation fails
    if (docSnap.exists) {
      payload.employeeCount = docSnap.data()?.employeeCount || 0;
      payload.activeEmployeeCount = docSnap.data()?.activeEmployeeCount || 0;
    } else {
      payload.employeeCount = 0;
      payload.activeEmployeeCount = 0;
    }
  }

  for (const [key, value] of Object.entries(updates)) {
    payload[key] = FieldValue.increment(value);
  }

  await docRef.set(payload, { merge: true });
}