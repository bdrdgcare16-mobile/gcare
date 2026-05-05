import { db } from '../config/firebase';

export async function generateMonthlyBilling(month: string) {
  const usageSnap = await db.collection('usage').where('month', '==', month).get();

  for (const doc of usageSnap.docs) {
    const data = doc.data();

    const baseAmount = data.plan === 'Premium' ? 5000 : 2000;

    const extraAmount =
      (data.readCount || 0) * 0.05 +
      (data.writeCount || 0) * 0.10 +
      (data.deleteCount || 0) * 0.05 +
      (data.storageUsedMb || 0) * 0.02 +
      (data.fileUploadCount || 0) * 0.50;

    const totalAmount = baseAmount + extraAmount;

    await db.collection('billing').doc(`${data.companyId}_${month}`).set({
      companyId: data.companyId,
      companyName: data.companyName,
      month,
      plan: data.plan,
      baseAmount,
      extraAmount,
      totalAmount,
      billingStatus: 'pending',
      generatedAt: new Date(),
    });
  }
}