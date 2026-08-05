/*
Salary source audit for unmatched payroll employees in COMP001.
Usage:
  node scripts/salary_source_audit.js

This script does not write to Firestore.
It inspects employee docs and searches related collections for salary fields.
*/

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('serviceAccountKey.json not found in functions root. Aborting.');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const unmatchedIds = [
  'MR019','MR017','mrrrr','MR013','MR005','MR015','MR016','MR010','MR004','MR012','mrr01','MR007','MR002','MR018','MR011','MR001','MR008','MR009','MR022','MR021',
];
const companyArg = 'COMP001';
const OUTPUT_DIR = path.join(__dirname, 'output');
if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });
const nowTimestamp = new Date().toISOString().replace(/[:.]/g, '-');
const reportPath = path.join(OUTPUT_DIR, `salary_source_audit_${companyArg}_${nowTimestamp}.json`);

const STATUS = {
  SALARY_FOUND_IN_EMPLOYEE: 'SALARY_FOUND_IN_EMPLOYEE',
  SALARY_FOUND_IN_RELATED_COLLECTION: 'SALARY_FOUND_IN_RELATED_COLLECTION',
  SALARY_NOT_FOUND: 'SALARY_NOT_FOUND',
  INVALID_EMPLOYEE_ID: 'INVALID_EMPLOYEE_ID',
  DUPLICATE_EMPLOYEE: 'DUPLICATE_EMPLOYEE',
  INVALID_SALARY: 'INVALID_SALARY',
};

const salaryFields = [
  'basicSalary',
  'monthlySalary',
  'salary',
  'grossSalary',
  'netSalary',
  'salaryDetails.basicSalary',
  'salaryDetails.monthlySalary',
  'compensation.basicSalary',
  'compensation.monthlySalary',
  'bankDetails.basicSalary',
];

const identifierFields = [
  'empid',
  'employeeId',
  'employeeCode',
  'uid',
  'officialEmail',
  'personalEmail',
  'email',
  'phoneNumber',
  'mobileNumber',
];

const searchCollectionKeywords = ['salary', 'payroll', 'compensation', 'onboarding', 'employee'];
const validSalaryRegex = /^[+-]?(?:\d+|\d*\.\d+)$/;

function getValue(obj, path) {
  return path.split('.').reduce((cur, key) => (cur && Object.prototype.hasOwnProperty.call(cur, key) ? cur[key] : undefined), obj);
}

function normalizePhone(value) {
  if (value === null || value === undefined) return null;
  const s = String(value).replace(/[^0-9]/g, '');
  if (s.length > 10) return s.slice(-10);
  return s;
}

function normalizeEmail(value) {
  if (value === null || value === undefined) return null;
  return String(value).trim().toLowerCase();
}

function normalizeId(value) {
  if (value === null || value === undefined) return null;
  return String(value).trim();
}

function isValidSalaryValue(value) {
  if (value === null || value === undefined) return false;
  if (typeof value === 'number') return Number.isFinite(value) && value > 0;
  if (typeof value === 'string') {
    const s = value.trim();
    return validSalaryRegex.test(s) && Number(s) > 0;
  }
  return false;
}

function formatSalaryValue(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number') return value;
  if (typeof value === 'string') return value.trim();
  return String(value);
}

async function listRelevantCollections() {
  const all = await db.listCollections();
  const relevant = all
    .map((col) => col.id)
    .filter((name) => searchCollectionKeywords.some((keyword) => name.toLowerCase().includes(keyword)));
  const distinct = Array.from(new Set(relevant));
  return distinct.sort();
}

async function findEmployeeDocs() {
  const snap = await db.collection('employees').where('companyId', '==', companyArg).get();
  return snap.docs.map((doc) => ({ id: doc.id, data: doc.data() }));
}

function extractSalaryFields(doc) {
  const values = {};
  for (const field of salaryFields) {
    values[field] = getValue(doc, field);
  }
  return values;
}

function bestSalaryField(values) {
  const ordered = [
    'basicSalary',
    'salaryDetails.basicSalary',
    'compensation.basicSalary',
    'monthlySalary',
    'salaryDetails.monthlySalary',
    'compensation.monthlySalary',
    'salary',
  ];
  for (const field of ordered) {
    const val = values[field];
    if (isValidSalaryValue(val)) {
      return { field, rawSalary: val, salaryType: typeof val };
    }
  }
  return null;
}

async function searchRelatedCollection(collectionName, employee) {
  const candidates = [];
  const idCandidates = [employee.employeeId, employee.employeeCode, employee.empid].filter(Boolean);
  const emailCandidates = [employee.officialEmail, employee.personalEmail, employee.email].filter(Boolean).map(normalizeEmail);
  const phoneCandidates = [employee.phoneNumber, employee.mobileNumber].filter(Boolean).map(normalizePhone);
  const uidCandidate = employee.uid || employee.userId || null;
  const searchMap = {
    empid: idCandidates,
    employeeId: idCandidates,
    employeeCode: idCandidates,
    uid: uidCandidate ? [uidCandidate] : [],
    officialEmail: emailCandidates,
    personalEmail: emailCandidates,
    email: emailCandidates,
    phoneNumber: phoneCandidates,
    mobileNumber: phoneCandidates,
  };

  for (const field of Object.keys(searchMap)) {
    for (const value of searchMap[field]) {
      if (!value) continue;
      try {
        const snap = await db.collection(collectionName).where(field, '==', value).limit(20).get();
        if (!snap.empty) {
          for (const doc of snap.docs) {
            const data = doc.data();
            const salaryValues = extractSalaryFields(data);
            const best = bestSalaryField(salaryValues);
            candidates.push({ collectionName, documentId: doc.id, field, value, salaryValues, best });
          }
        }
      } catch (err) {
        // ignore invalid queries or missing indexes
      }
    }
  }
  return candidates;
}

async function main() {
  console.log('Salary source audit for unmatched employees in company', companyArg);

  const employees = await findEmployeeDocs();
  const employeeIndex = new Map();
  for (const emp of employees) {
    const doc = emp.data || {};
    const identifiers = [
      normalizeId(doc.empid),
      normalizeId(doc.employeeId),
      normalizeId(doc.employeeCode),
    ].filter(Boolean);
    for (const id of identifiers) {
      if (!employeeIndex.has(id)) employeeIndex.set(id, []);
      employeeIndex.get(id).push(emp);
    }
  }

  const relevantCollections = await listRelevantCollections();
  console.log('Relevant backend collections with salary/payroll/compensation/onboarding/employee keywords:');
  relevantCollections.forEach((name) => console.log(' -', name));
  console.log('Also inspecting employees and employee_onboarding_dev collections explicitly.');

  const audit = [];
  let counts = {
    salary_found_employee: 0,
    salary_found_related: 0,
    salary_missing: 0,
    invalid_employee_id: 0,
    duplicate_employee: 0,
    invalid_salary: 0,
  };

  for (const unmatchedId of unmatchedIds) {
    const normalizedId = normalizeId(unmatchedId);
    const matches = employeeIndex.get(normalizedId) || [];
    if (matches.length === 0) {
      audit.push({
        employeeId: unmatchedId,
        employeeName: null,
        employeeDocumentId: null,
        companyId: companyArg,
        employeeSalaryFields: null,
        relatedSalaryDocumentId: null,
        salarySource: null,
        rawSalary: null,
        salaryType: null,
        status: STATUS.INVALID_EMPLOYEE_ID,
        reason: 'No employee document found for this employee ID',
      });
      counts.invalid_employee_id++;
      continue;
    }
    if (matches.length > 1) {
      const docIds = matches.map((m) => m.id).join(', ');
      audit.push({
        employeeId: unmatchedId,
        employeeName: matches[0].data.name || matches[0].data.employeeName || null,
        employeeDocumentId: null,
        companyId: companyArg,
        employeeSalaryFields: null,
        relatedSalaryDocumentId: null,
        salarySource: null,
        rawSalary: null,
        salaryType: null,
        status: STATUS.DUPLICATE_EMPLOYEE,
        reason: `Multiple employee documents found for this ID: ${docIds}`,
      });
      counts.duplicate_employee++;
      continue;
    }

    const emp = matches[0];
    const empData = emp.data || {};
    const employeeName = empData.name || empData.employeeName || null;
    const employeeEmail = normalizeEmail(empData.email || empData.personalEmail || '');
    const employeePhone = normalizePhone(empData.phoneNumber || empData.mobileNumber || empData.phone || '');
    const employeeUid = empData.uid || empData.userId || null;

    const employeeSalaryFields = extractSalaryFields(empData);
    const salaryFieldEntries = Object.entries(employeeSalaryFields).map(([key, value]) => ({ key, value }));
    const validFields = salaryFieldEntries.filter(({ value }) => isValidSalaryValue(value));
    const invalidFields = salaryFieldEntries.filter(({ value }) => value !== null && value !== undefined && !isValidSalaryValue(value));

    if (validFields.length > 0) {
      const best = bestSalaryField(employeeSalaryFields);
      audit.push({
        employeeId: unmatchedId,
        employeeName,
        employeeDocumentId: emp.id,
        companyId: companyArg,
        employeeSalaryFields: employeeSalaryFields,
        relatedSalaryDocumentId: emp.id,
        salarySource: best ? `employees.${best.field}` : 'employees',
        rawSalary: best ? formatSalaryValue(best.rawSalary) : null,
        salaryType: best ? typeof best.rawSalary : null,
        status: STATUS.SALARY_FOUND_IN_EMPLOYEE,
        reason: `Valid salary found in employee document field ${best.field}`,
      });
      counts.salary_found_employee++;
      continue;
    }

    if (invalidFields.length > 0) {
      audit.push({
        employeeId: unmatchedId,
        employeeName,
        employeeDocumentId: emp.id,
        companyId: companyArg,
        employeeSalaryFields: employeeSalaryFields,
        relatedSalaryDocumentId: emp.id,
        salarySource: 'employees',
        rawSalary: invalidFields[0].value,
        salaryType: typeof invalidFields[0].value,
        status: STATUS.INVALID_SALARY,
        reason: `Invalid salary format in employee document field ${invalidFields[0].key}`,
      });
      counts.invalid_salary++;
      continue;
    }

    // search related collections
    let relatedFound = false;
    for (const collectionName of relevantCollections) {
      const employeeIdentifiers = {
        empid: [normalizeId(empData.empid), normalizeId(empData.employeeId), normalizeId(empData.employeeCode)].filter(Boolean),
        employeeId: [normalizeId(empData.empid), normalizeId(empData.employeeId), normalizeId(empData.employeeCode)].filter(Boolean),
        employeeCode: [normalizeId(empData.empid), normalizeId(empData.employeeId), normalizeId(empData.employeeCode)].filter(Boolean),
        uid: employeeUid ? [employeeUid] : [],
        officialEmail: employeeEmail ? [employeeEmail] : [],
        personalEmail: employeeEmail ? [employeeEmail] : [],
        email: employeeEmail ? [employeeEmail] : [],
        phoneNumber: employeePhone ? [employeePhone] : [],
        mobileNumber: employeePhone ? [employeePhone] : [],
      };

      for (const field of Object.keys(employeeIdentifiers)) {
        for (const value of employeeIdentifiers[field]) {
          try {
            const snap = await db.collection(collectionName).where(field, '==', value).limit(20).get();
            if (snap.empty) continue;
            for (const doc of snap.docs) {
              const data = doc.data();
              const relatedSalaryFields = extractSalaryFields(data);
              const bestRelated = bestSalaryField(relatedSalaryFields);
              if (bestRelated) {
                audit.push({
                  employeeId: unmatchedId,
                  employeeName,
                  employeeDocumentId: emp.id,
                  companyId: companyArg,
                  employeeSalaryFields,
                  relatedSalaryDocumentId: doc.id,
                  salarySource: `${collectionName}.${bestRelated.field}`,
                  rawSalary: formatSalaryValue(bestRelated.rawSalary),
                  salaryType: typeof bestRelated.rawSalary,
                  status: STATUS.SALARY_FOUND_IN_RELATED_COLLECTION,
                  reason: `Valid salary found in related collection ${collectionName} by field ${field}`,
                });
                counts.salary_found_related++;
                relatedFound = true;
                break;
              }
            }
          } catch (err) {
            // ignore invalid query paths or missing indexes
          }
          if (relatedFound) break;
        }
        if (relatedFound) break;
      }
      if (relatedFound) break;
    }

    if (relatedFound) continue;

    audit.push({
      employeeId: unmatchedId,
      employeeName,
      employeeDocumentId: emp.id,
      companyId: companyArg,
      employeeSalaryFields,
      relatedSalaryDocumentId: null,
      salarySource: null,
      rawSalary: null,
      salaryType: null,
      status: STATUS.SALARY_NOT_FOUND,
      reason: 'No valid salary found in employee document or related collections',
    });
    counts.salary_missing++;
  }

  fs.writeFileSync(reportPath, JSON.stringify({ generatedAt: new Date().toISOString(), company: companyArg, statuses: STATUS, counts, audit }, null, 2));

  console.log('\n--- Salary Source Audit Summary ---');
  console.log('Salary found in employees:', counts.salary_found_employee);
  console.log('Salary found elsewhere:', counts.salary_found_related);
  console.log('Salary missing:', counts.salary_missing);
  console.log('Invalid employee IDs:', counts.invalid_employee_id);
  console.log('Duplicate employee records:', counts.duplicate_employee);
  console.log('Invalid salary values:', counts.invalid_salary);
  console.log('Audit saved to', reportPath);
}

main().catch((err) => {
  console.error('Audit failed:', err);
  process.exit(1);
});
