import { Router } from 'express';
import { PrismaClient } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

// Get all payrolls
router.get('/', async (req, res) => {
  const payrolls = await prisma.payroll.findMany({ include: { user: true } });
  res.json(payrolls);
});

// Get payrolls by user
router.get('/user/:userId', async (req, res) => {
  const { userId } = req.params;
  const payrolls = await prisma.payroll.findMany({
    where: { userId: Number(userId) },
    orderBy: [{ year: 'desc' }, { month: 'desc' }],
  });
  res.json(payrolls);
});

// Create payroll
router.post('/', async (req, res) => {
  const { userId, month, year, amount, details } = req.body;
  if (!userId || !month || !year || !amount) return res.status(400).json({ error: 'Missing fields' });
  try {
    const payroll = await prisma.payroll.create({
      data: { userId, month, year, amount, details },
    });
    res.status(201).json(payroll);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create payroll' });
  }
});

export default router; 