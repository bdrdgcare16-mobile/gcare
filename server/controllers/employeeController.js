

const { db } = require('../config/firebase');    // ← destructure db here
const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const EMPLOYEES = 'employees'; // Firestore collection name

// 1. Create Employee (Admin only)
async function createEmployee(req, res) {
  try {
    const {
      name,
      empid,
      email,
      phone,
      password,
      location,
      dept,
      designation,
      shiftGroup,
      role
    } = req.body;

    if (!empid || !email || !password || !role) {
      return res.status(400).json({
        message: 'empid, email, password, and role are required.'
      });
    }

    // Unique empid check
    const snap = await db
      .collection(EMPLOYEES)
      .where('empid', '==', empid)
      .get();

    if (!snap.empty) {
      return res.status(409).json({ message: 'Employee ID already exists.' });
    }

    const hashed = await bcrypt.hash(password, 10);
    const id = uuidv4();

    await db.collection(EMPLOYEES).doc(id).set({
      name,
      empid,
      email,
      phone,
      password: hashed,
      location,
      dept,
      designation,
      shiftGroup: shiftGroup || null,
      role,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(201).json({ message: 'Employee created.', id });
  } catch (err) {
    console.error('createEmployee error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
}

// 2. Get Employee by Firestore document ID (for GET /api/employees/:id)
async function getEmployeeById(req, res) {
  try {
    const { id } = req.params;
    const doc = await db.collection(EMPLOYEES).doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ message: 'Employee not found' });
    }

    const employee = doc.data();
    delete employee.password; // never return the hash

    res.json({ id: doc.id, ...employee });
  } catch (err) {
    console.error('getEmployeeById error:', err);
    res.status(500).json({ message: 'Server error' });
  }
}

// 3. Get all Employees (Admin only, for GET /api/employees)
async function getAllEmployees(req, res) {
  try {
    const snapshot = await db
      .collection(EMPLOYEES)
      .orderBy('createdAt', 'desc')
      .get();

    if (snapshot.empty) {
      return res.status(404).json({ message: 'No employees found' });
    }

    const employees = snapshot.docs.map(doc => {
      const data = doc.data();
      delete data.password;
      return { id: doc.id, ...data };
    });

    res.json(employees);
  } catch (err) {
    console.error('getAllEmployees error:', err);
    res.status(500).json({ message: 'Server error' });
  }
}

// 4. Update Employee (Admin only, for PUT /api/employees/:id)
async function updateEmployee(req, res) {
  try {
    const { id } = req.params;
    const updates = { ...req.body };

    if (updates.password) {
      updates.password = await bcrypt.hash(updates.password, 10);
    }

    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await db.collection(EMPLOYEES).doc(id).update(updates);
    res.json({ message: 'Employee updated.' });
  } catch (err) {
    console.error('updateEmployee error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
}

module.exports = {
  createEmployee,
  getEmployeeById,
  getAllEmployees,
  updateEmployee
};
