import { Request, Response } from 'express';
import { generateMonthlyBilling } from '../services/billingService';

export async function runMonthlyBilling(req: Request, res: Response) {
  try {
    const { month } = req.body;

    if (!month) {
      return res.status(400).json({
        success: false,
        message: 'month is required',
      });
    }

    await generateMonthlyBilling(month);

    return res.status(200).json({
      success: true,
      message: 'Billing generated successfully',
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Billing generation failed',
    });
  }
}