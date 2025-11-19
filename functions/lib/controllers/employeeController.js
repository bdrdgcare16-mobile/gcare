"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteEmployee = exports.updateEmployee = exports.getEmployeeById = exports.getEmployees = exports.createEmployee = void 0;
const admin = __importStar(require("firebase-admin"));
const bcrypt = __importStar(require("bcryptjs"));
const db = admin.firestore();
const EMPLOYEES = 'employees';
const stripPassword = (data) => {
    const { password, ...rest } = data || {};
    return rest;
};
const buildSearchKeywords = (e) => {
    const bag = new Set();
    const push = (v) => {
        if (!v)
            return;
        const s = String(v).toLowerCase();
        bag.add(s);
        // split on space and add tokens
        s.split(/[^\w]+/).forEach(t => t && bag.add(t));
    };
    push(e.empid);
    push(e.name);
    push(e.email);
    push(e.phone);
    push(e.dept);
    push(e.designation);
    return Array.from(bag);
};
// Create a new employee (Admin only)
const createEmployee = async (req, res) => {
    try {
        const { empid, name, email, phone, location, dept, designation, shiftGroup, role, status = 'active', password, // optional – if provided, will be hashed and stored
         } = req.body;
        if (!empid || !email || !name) {
            return res.status(400).json({ error: 'Missing required fields: empid, name, email' });
        }
        // Uniqueness checks
        const byEmp = await db.collection(EMPLOYEES).where('empid', '==', empid).limit(1).get();
        if (!byEmp.empty) {
            return res.status(409).json({ error: 'Employee with this ID already exists' });
        }
        const emailLower = String(email).toLowerCase();
        const byEmail = await db.collection(EMPLOYEES).where('emailLower', '==', emailLower).limit(1).get();
        if (!byEmail.empty) {
            return res.status(409).json({ error: 'Employee with this email already exists' });
        }
        const currentUserId = req.user?.userId;
        if (!currentUserId) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        const now = admin.firestore.Timestamp.now();
        const employeeData = {
            empid,
            name,
            email: emailLower,
            emailLower,
            phone,
            location,
            dept,
            designation,
            shiftGroup: shiftGroup ?? null,
            role,
            status: status,
            createdAt: now,
            updatedAt: now,
            createdBy: currentUserId,
            updatedBy: currentUserId,
            searchKeywords: buildSearchKeywords({ empid, name, email, phone, dept, designation }),
        };
        if (password) {
            employeeData.password = await bcrypt.hash(String(password), 10);
        }
        const ref = await db.collection(EMPLOYEES).add(employeeData);
        const created = await ref.get();
        return res.status(201).json({ id: ref.id, ...(stripPassword(created.data() || {})) });
    }
    catch (error) {
        console.error('Error creating employee:', error);
        return res.status(500).json({ error: 'Failed to create employee' });
    }
};
exports.createEmployee = createEmployee;
// Get all employees (Admin; supports filters & pagination)
const getEmployees = async (req, res) => {
    try {
        const { status, search, page = '1', limit = '10000' } = req.query;
        const pageNum = Math.max(parseInt(page, 10) || 1, 1);
        const limitNum = Math.min(Math.max(parseInt(limit, 10) || 10, 1), 100);
        const offset = (pageNum - 1) * limitNum;
        let q = db.collection(EMPLOYEES);
        if (status === 'active' || status === 'inactive') {
            q = q.where('status', '==', status);
        }
        if (search && String(search).trim()) {
            q = q.where('searchKeywords', 'array-contains', String(search).toLowerCase().trim());
        }
        // total count (inefficient but simple; for large sets, switch to cursors)
        const totalSnap = await q.get();
        const total = totalSnap.size;
        const listSnap = await q.orderBy('createdAt', 'desc').offset(offset).limit(limitNum).get();
        const data = listSnap.docs.map(d => ({ id: d.id, ...(stripPassword(d.data())) }));
        return res.status(200).json({
            data,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total,
                pages: Math.ceil(total / limitNum),
            },
        });
    }
    catch (error) {
        console.error('Error fetching employees:', error);
        return res.status(500).json({ error: 'Failed to fetch employees' });
    }
};
exports.getEmployees = getEmployees;
// Get employee by document ID
const getEmployeeById = async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await db.collection(EMPLOYEES).doc(id).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Employee not found' });
        }
        return res.status(200).json({ id: doc.id, ...(stripPassword(doc.data() || {})) });
    }
    catch (error) {
        console.error('Error fetching employee:', error);
        return res.status(500).json({ error: 'Failed to fetch employee' });
    }
};
exports.getEmployeeById = getEmployeeById;
// Update employee (Admin only)
const updateEmployee = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = { ...(req.body || {}) };
        const currentUserId = req.user?.userId;
        if (!currentUserId) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        const ref = db.collection(EMPLOYEES).doc(id);
        const doc = await ref.get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Employee not found' });
        }
        if (updates.email) {
            updates.emailLower = String(updates.email).toLowerCase();
        }
        if (updates.password) {
            updates.password = await bcrypt.hash(String(updates.password), 10);
        }
        // refresh search keywords if core fields change
        const recomputeKeywords = updates.empid || updates.name || updates.email || updates.phone || updates.dept || updates.designation;
        const patch = {
            ...updates,
            ...(recomputeKeywords
                ? {
                    searchKeywords: buildSearchKeywords({
                        empid: updates.empid ?? doc.get('empid'),
                        name: updates.name ?? doc.get('name'),
                        email: (updates.email ?? doc.get('email')),
                        phone: updates.phone ?? doc.get('phone'),
                        dept: updates.dept ?? doc.get('dept'),
                        designation: updates.designation ?? doc.get('designation'),
                    }),
                }
                : {}),
            updatedAt: admin.firestore.Timestamp.now(),
            updatedBy: currentUserId,
        };
        await ref.update(patch);
        const updated = await ref.get();
        return res.status(200).json({ id: updated.id, ...(stripPassword(updated.data() || {})) });
    }
    catch (error) {
        console.error('Error updating employee:', error);
        return res.status(500).json({ error: 'Failed to update employee' });
    }
};
exports.updateEmployee = updateEmployee;
// Delete employee (Admin only) — hard delete; switch to soft delete if needed
const deleteEmployee = async (req, res) => {
    try {
        const { id } = req.params;
        await db.collection(EMPLOYEES).doc(id).delete();
        return res.status(200).json({ message: 'Employee deleted successfully' });
    }
    catch (error) {
        console.error('Error deleting employee:', error);
        return res.status(500).json({ error: 'Failed to delete employee' });
    }
};
exports.deleteEmployee = deleteEmployee;
//# sourceMappingURL=employeeController.js.map