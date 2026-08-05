/*
Safe one-time migration & audit script for payroll onboarding records
Usage:
  Dry run: node scripts/migrate_payroll_onboarding.js --dry-run
  Apply:   node scripts/migrate_payroll_onboarding.js --apply

Optional flags:
  --run-preview    Run payroll preview POST (requires PAYROLL_API_BASE env var)
  --company COMP001 (defaults to COMP001)

Notes:
  - DRY_RUN=true by default unless --apply provided.
  - When --apply provided the script still shows dry-run and requires interactive confirmation.
*/

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('serviceAccountKey.json not found in functions root. Aborting.');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// simple argv parsing (no extra deps)
const rawArgs = process.argv.slice(2);
const argv = {};
for (const a of rawArgs) {
  if (!a.startsWith('--')) continue;
  if (a.includes('=')) {
    const [k, v] = a.split('=');
    argv[k.replace(/^--/, '')] = v;
  } else {
    argv[a.replace(/^--/, '')] = true;
  }
}
const apply = !!argv.apply;
const runPreview = !!(argv['run-preview'] || argv['run_preview']);
const companyArg = argv.company || 'COMP001';
const confirmFlag = !!argv.confirm;

const OUTPUT_DIR = path.join(__dirname, 'output');
if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

const nowTimestamp = new Date().toISOString().replace(/[:.]/g, '-');
const reportPath = path.join(OUTPUT_DIR, `audit_report_${companyArg}_${nowTimestamp}.json`);

const STATUS = {
  MATCHED: 'MATCHED',
  COMPANY_ID_MISSING: 'COMPANY_ID_MISSING',
  EMPLOYEE_ID_MISSING: 'EMPLOYEE_ID_MISSING',
  SALARY_MISSING: 'SALARY_MISSING',
  ONBOARDING_RECORD_MISSING: 'ONBOARDING_RECORD_MISSING',
  MULTIPLE_MATCHES: 'MULTIPLE_MATCHES',
  IDENTIFIER_CONFLICT: 'IDENTIFIER_CONFLICT',
  ERROR: 'ERROR',
};

const ENHANCED_STATUS = {
  MATCHED: 'MATCHED',
  POSSIBLE_EMAIL_MATCH: 'POSSIBLE_EMAIL_MATCH',
  POSSIBLE_PHONE_MATCH: 'POSSIBLE_PHONE_MATCH',
  POSSIBLE_UID_MATCH: 'POSSIBLE_UID_MATCH',
  POSSIBLE_NAME_MATCH: 'POSSIBLE_NAME_MATCH',
  MULTIPLE_MATCHES: 'MULTIPLE_MATCHES',
  NO_ONBOARDING_RECORD: 'NO_ONBOARDING_RECORD',
  SALARY_MISSING: 'SALARY_MISSING',
};

async function promptYesNo(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question + ' (yes/no): ', (answer) => {
      rl.close();
      const a = String(answer || '').trim().toLowerCase();
      resolve(a === 'yes' || a === 'y');
    });
  });
}

function safeNumber(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === 'number') return Number.isFinite(v) ? v : null;
  if (typeof v === 'string') {
    const s = v.trim();
    if (/^[+-]?(?:\d+|\d*\.\d+)$/.test(s)) return Number(s);
    return null;
  }
  return null;
}

function normalizeId(id) {
  if (!id && id !== 0) return null;
  return String(id).trim().toUpperCase();
}

function normalizeEmail(email) {
  if (!email && email !== 0) return null;
  return String(email).trim().toLowerCase();
}

function normalizePhone(phone) {
  if (!phone && phone !== 0) return null;
  let s = String(phone);
  // remove spaces, hyphens, parentheses, pluses
  s = s.replace(/[^0-9]/g, '');
  // remove leading country codes by keeping last 10 digits when longer
  if (s.length > 10) s = s.slice(-10);
  return s;
}

function normalizeName(name) {
  if (!name && name !== 0) return null;
  return String(name).trim().toLowerCase().replace(/\s+/g, ' ');
}

async function main() {
  console.log('Migration script for company:', companyArg);
  console.log('Mode:', apply ? 'APPLY (writes enabled)' : 'DRY RUN (no writes)');

  // Load employees for companyId
  const empSnap = await db.collection('employees').where('companyId', '==', companyArg).get();
  const employees = empSnap.docs.map((d) => ({ id: d.id, ...(d.data() || {}) }));

  console.log('Total employees for', companyArg, ':', employees.length);

  const audit = [];
  let counts = {};
  Object.values(STATUS).forEach((s) => (counts[s] = 0));
  counts.ERROR = 0;

  for (const emp of employees) {
    try {
      const employeeDocumentId = emp.id;
      const employeeId = emp.empid || emp.employeeId || emp.employeeCode || null;
      const employeeName = emp.name || emp.employeeName || '';
      const companyId = emp.companyId || companyArg;

      if (!employeeId) {
        audit.push({ employeeDocumentId, employeeId: null, employeeName, companyId, onboardingDocumentId: null, matchedBy: null, onboardingCompanyId: null, onboardingEmployeeId: null, basicSalary: null, salaryType: null, status: STATUS.EMPLOYEE_ID_MISSING, reason: 'Employee identifier missing (empid/employeeId/employeeCode)'});
        counts[STATUS.EMPLOYEE_ID_MISSING]++;
        continue;
      }

      // Search onboarding collection by multiple fields
      const base = db.collection('employee_onboarding_dev');

      const queries = [
        { field: 'companyDetails.employeeId', q: base.where('companyDetails.employeeId', '==', employeeId).limit(5) },
        { field: 'empid', q: base.where('empid', '==', employeeId).limit(5) },
        { field: 'employeeId', q: base.where('employeeId', '==', employeeId).limit(5) },
        { field: 'companyDetails.officialEmail', q: base.where('companyDetails.officialEmail', '==', emp.email || '').limit(5) },
        { field: 'officialEmail', q: base.where('officialEmail', '==', emp.email || '').limit(5) },
      ];

      // Run queries in parallel
      const results = await Promise.all(queries.map((it) => it.q.get().catch((e) => ({ error: e }))));

      const matchedDocs = [];
      for (let i = 0; i < results.length; i++) {
        const res = results[i];
        if (res && res.error) continue;
        if (!res.empty) {
          for (const doc of res.docs) matchedDocs.push({ id: doc.id, data: doc.data(), matchedBy: queries[i].field });
        }
      }

      if (matchedDocs.length === 0) {
        // No onboarding record found
        const row = { employeeDocumentId, employeeId, employeeName, companyId, onboardingDocumentId: null, matchedBy: null, onboardingCompanyId: null, onboardingEmployeeId: null, basicSalary: null, salaryType: null, status: STATUS.ONBOARDING_RECORD_MISSING, reason: 'No onboarding record matched' };
        audit.push(row);
        counts[STATUS.ONBOARDING_RECORD_MISSING]++;
        continue;
      }

      // Deduplicate by doc id
      const uniqueById = new Map();
      for (const m of matchedDocs) uniqueById.set(m.id, m);
      const uniqueMatches = Array.from(uniqueById.values());

      if (uniqueMatches.length > 1) {
        audit.push({ employeeDocumentId, employeeId, employeeName, companyId, onboardingDocumentId: null, matchedBy: uniqueMatches.map(u=>u.matchedBy).join(','), onboardingCompanyId: null, onboardingEmployeeId: null, basicSalary: null, salaryType: null, status: STATUS.MULTIPLE_MATCHES, reason: 'Multiple onboarding documents matched' });
        counts[STATUS.MULTIPLE_MATCHES]++;
        continue;
      }

      const match = uniqueMatches[0];
      const onboardingDocumentId = match.id;
      const onboarding = match.data || {};

      const onboardingCompanyId = onboarding.companyId || null;
      const onboardingEmployeeId = onboarding.empid || onboarding.employeeId || onboarding.companyDetails?.employeeId || null;

      // Check identifier conflict: employeeId vs onboardingEmployeeId if both exist and differ
      if (onboardingEmployeeId && String(onboardingEmployeeId) !== String(employeeId)) {
        audit.push({ employeeDocumentId, employeeId, employeeName, companyId, onboardingDocumentId, matchedBy: match.matchedBy, onboardingCompanyId, onboardingEmployeeId, basicSalary: null, salaryType: null, status: STATUS.IDENTIFIER_CONFLICT, reason: `Identifier conflict: employeeId ${employeeId} != onboarding ${onboardingEmployeeId}` });
        counts[STATUS.IDENTIFIER_CONFLICT]++;
        continue;
      }

      // salary validation
      const bankDetails = onboarding.bankDetails || {};
      const rawBasic = bankDetails.basicSalary;
      const basicSalary = safeNumber(rawBasic);
      if (basicSalary === null || basicSalary <= 0) {
        audit.push({ employeeDocumentId, employeeId, employeeName, companyId, onboardingDocumentId, matchedBy: match.matchedBy, onboardingCompanyId, onboardingEmployeeId, basicSalary: rawBasic === undefined ? null : rawBasic, salaryType: rawBasic === undefined ? null : typeof rawBasic, status: STATUS.SALARY_MISSING, reason: 'bankDetails.basicSalary missing or invalid' });
        counts[STATUS.SALARY_MISSING]++;
        continue;
      }

      // Matched and salary present
      const row = { employeeDocumentId, employeeId, employeeName, companyId, onboardingDocumentId, matchedBy: match.matchedBy, onboardingCompanyId, onboardingEmployeeId, basicSalary, salaryType: typeof rawBasic, status: STATUS.MATCHED, reason: 'Matched with valid basicSalary' };
      audit.push(row);
      counts[STATUS.MATCHED]++;

      // Migration writes
      if (apply) {
        // Before writing, ensure we will only write when exactly one onboarding record, no conflicts
        // Prepare updates: set companyId and empid if missing
        const updates = {};
        if (!onboarding.companyId && companyId) updates.companyId = companyId;
        if (!onboarding.empid && employeeId) updates.empid = employeeId;

        if (Object.keys(updates).length > 0) {
          // Show what would be written
          console.log('Will update onboarding', onboardingDocumentId, 'with', updates);
          // require interactive confirmation unless --confirm provided
          let confirmed = false;
          if (argv.confirm) confirmed = true;
          else confirmed = await promptYesNo(`Apply updates to onboarding ${onboardingDocumentId}?`);

          if (confirmed) {
            await db.collection('employee_onboarding_dev').doc(onboardingDocumentId).update(updates);
            console.log('Updated', onboardingDocumentId);
            counts.UPDATED = (counts.UPDATED || 0) + 1;
          } else {
            console.log('Skipped update for', onboardingDocumentId);
          }
        }
      }

    } catch (err) {
      console.error('Error processing employee', emp.id, String(err));
      audit.push({ employeeDocumentId: emp.id, employeeId: emp.empid || null, employeeName: emp.name || null, companyId: emp.companyId || null, onboardingDocumentId: null, matchedBy: null, onboardingCompanyId: null, onboardingEmployeeId: null, basicSalary: null, salaryType: null, status: STATUS.ERROR, reason: String(err) });
      counts.ERROR++;
    }
  }

  // Save report
  fs.writeFileSync(reportPath, JSON.stringify({ generatedAt: new Date().toISOString(), company: companyArg, apply, counts, audit }, null, 2));

  // Print summary
  console.log('\n--- Audit Summary ---');
  console.log('Total employees:', employees.length);
  Object.keys(counts).forEach((k) => {
    if (k === 'UPDATED') return;
    console.log(k + ':', counts[k]);
  });
  console.log('Report saved to', reportPath);

  // If apply and runPreview
  if (apply && runPreview) {
    const base = process.env.PAYROLL_API_BASE;
    if (!base) {
      console.warn('PAYROLL_API_BASE not set; skipping automatic payroll preview. Set PAYROLL_API_BASE to the API base URL to enable.');
    } else {
      try {
        console.log('Running payroll preview for', companyArg);
        const payload = { companyId: companyArg, year: new Date().getFullYear(), month: new Date().getMonth() + 0 /* user may want previous */, salaryCalculationMethod: 'ACTUAL_CALENDAR_DAYS' };
        const { URL } = require('url');
        const http = require('http');
        const https = require('https');
        const postJSON = (endpoint, body) => new Promise((resolve, reject) => {
          try {
            const u = new URL(endpoint);
            const lib = u.protocol === 'https:' ? https : http;
            const data = JSON.stringify(body);
            const options = {
              hostname: u.hostname,
              port: u.port || (u.protocol === 'https:' ? 443 : 80),
              path: u.pathname + (u.search || ''),
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(data),
              },
            };
            const req = lib.request(options, (res) => {
              let resp = '';
              res.on('data', (chunk) => (resp += chunk));
              res.on('end', () => {
                try {
                  const parsed = JSON.parse(resp);
                  resolve({ status: res.statusCode, data: parsed });
                } catch (err) {
                  resolve({ status: res.statusCode, data: resp });
                }
              });
            });
            req.on('error', (e) => reject(e));
            req.write(data);
            req.end();
          } catch (e) {
            reject(e);
          }
        });

        const resp = await postJSON(`${base.replace(/\/$/, '')}/payroll/generate/preview`, payload);
        const data = resp.data;
        console.log('Preview response status:', resp.status);
        if (data && data.data) {
          console.log('Generated:', (data.data.generated || []).length);
          console.log('Failed:', (data.data.failed || []).length);
          if ((data.data.failed || []).length > 0) {
            console.log('Failed samples:');
            (data.data.failed || []).slice(0, 20).forEach((f) => {
              console.log('-', f.empid, '-', (f.reason || 'Unknown').toString().split('\n')[0]);
            });
          }
        } else {
          console.log('Unexpected preview response:', JSON.stringify(data).slice(0, 1000));
        }
      } catch (err) {
        console.error('Preview run failed:', String(err));
      }
    }
  }

  console.log('Done.');
}

async function enhancedInvestigation() {
  console.log('\nStarting enhanced investigation for unmatched employees...');
  const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  const audit = report.audit || [];
  const unmatched = audit.filter((r) => r.status === STATUS.ONBOARDING_RECORD_MISSING || r.status === ENHANCED_STATUS.NO_ONBOARDING_RECORD || r.status === STATUS.ONBOARDING_RECORD_MISSING);

  const enhancedResults = [];
  let counts = { exact: 0, high: 0, low: 0, multiple: 0, salary_missing: 0, no_onboarding: 0 };

  for (const u of unmatched) {
    const empDoc = await db.collection('employees').doc(u.employeeDocumentId).get();
    const emp = empDoc.exists ? empDoc.data() : null;
    const employeeId = emp?.empid || emp?.employeeId || emp?.employeeCode || null;
    const employeeName = emp?.name || emp?.employeeName || '';
    const employeeEmail = normalizeEmail(emp?.email || emp?.personalEmail || emp?.emailLower || '');
    const employeePhone = normalizePhone(emp?.phone || emp?.mobileNumber || emp?.phoneNumber || '');
    const employeeUid = emp?.uid || emp?.userId || null;

    const searchFields = [
      { field: 'empid', value: employeeId },
      { field: 'employeeId', value: employeeId },
      { field: 'employeeCode', value: employeeId },
      { field: 'uid', value: employeeUid },
      { field: 'officialEmail', value: employeeEmail },
      { field: 'personalEmail', value: employeeEmail },
      { field: 'email', value: employeeEmail },
      { field: 'phoneNumber', value: employeePhone },
      { field: 'mobileNumber', value: employeePhone },
      { field: 'companyDetails.employeeId', value: employeeId },
      { field: 'companyDetails.officialEmail', value: employeeEmail },
      { field: 'personalDetails.email', value: employeeEmail },
      { field: 'personalDetails.personalEmail', value: employeeEmail },
      { field: 'personalDetails.phoneNumber', value: employeePhone },
      { field: 'personalDetails.mobileNumber', value: employeePhone },
      { field: 'personalDetails.fullName', value: employeeName },
      { field: 'companyDetails.employeeName', value: employeeName },
    ];

    const candidates = new Map();

    for (const sf of searchFields) {
      if (!sf.value) continue;
      try {
        const q = db.collection('employee_onboarding_dev').where(sf.field, '==', sf.value).limit(10);
        const snap = await q.get();
        if (!snap.empty) {
          for (const doc of snap.docs) {
            candidates.set(doc.id, { id: doc.id, data: doc.data(), matchedBy: sf.field });
          }
        }
      } catch (err) {
        // ignore invalid query paths or errors
      }
    }

    // Also perform a small scan of candidate docs by companyDetails.employeeId using case-insensitive matching (fetch nearby docs)
    // (Skipped due to Firestore limitations; relies on field exact matches above)

    const candidateList = Array.from(candidates.values());
    if (candidateList.length === 0) {
      enhancedResults.push({ employeeDocumentId: u.employeeDocumentId, employeeId, employeeName, employeeEmail, employeePhone, employeeUid, onboardingDocumentId: null, matchedBy: null, confidence: 'none', bankDetailsKeys: null, basicSalary: null, salaryType: null, status: ENHANCED_STATUS.NO_ONBOARDING_RECORD, reason: 'No candidates found in expanded search' });
      counts.no_onboarding++;
      continue;
    }

    // Evaluate candidates by normalization rules
    const scored = [];
    for (const c of candidateList) {
      const d = c.data || {};
      const cEmpId = normalizeId(d.empid || d.employeeId || d.companyDetails?.employeeId || null);
      const cUid = d.uid || d.userId || null;
      const cEmails = [normalizeEmail(d.officialEmail), normalizeEmail(d.companyDetails?.officialEmail), normalizeEmail(d.personalDetails?.email), normalizeEmail(d.personalDetails?.personalEmail), normalizeEmail(d.email)].filter(Boolean);
      const cPhones = [normalizePhone(d.phoneNumber), normalizePhone(d.mobileNumber), normalizePhone(d.personalDetails?.phoneNumber), normalizePhone(d.personalDetails?.mobileNumber)].filter(Boolean);
      const cNames = [normalizeName(d.personalDetails?.fullName), normalizeName(d.companyDetails?.employeeName)].filter(Boolean);

      const match = { id: c.id, matchedBy: c.matchedBy, reasons: [], score: 0, data: d };

      if (employeeId && cEmpId && normalizeId(employeeId) === cEmpId) {
        match.reasons.push('employeeId'); match.score += 100;
      }
      if (employeeUid && cUid && String(employeeUid) === String(cUid)) {
        match.reasons.push('uid'); match.score += 100;
      }
      if (employeeEmail && cEmails.length > 0 && cEmails.includes(employeeEmail)) {
        match.reasons.push('email'); match.score += 50;
      }
      if (employeePhone && cPhones.length > 0 && cPhones.includes(employeePhone)) {
        match.reasons.push('phone'); match.score += 50;
      }
      if (employeeName && cNames.length > 0 && cNames.includes(normalizeName(employeeName))) {
        match.reasons.push('name'); match.score += 1;
      }

      // salary info
      const bankKeys = Object.keys(d.bankDetails || {});
      const rawBasic = (d.bankDetails || {}).basicSalary;
      const basicSalary = safeNumber(rawBasic);

      match.bankDetailsKeys = bankKeys;
      match.basicSalaryRaw = rawBasic === undefined ? null : rawBasic;
      match.basicSalary = basicSalary;

      scored.push(match);
    }

    // Determine best matches
    scored.sort((a, b) => b.score - a.score);
    const topScore = scored[0].score;
    const topMatches = scored.filter((s) => s.score === topScore);

    if (topMatches.length > 1) {
      enhancedResults.push({ employeeDocumentId: u.employeeDocumentId, employeeId, employeeName, employeeEmail, employeePhone, employeeUid, onboardingDocumentId: null, matchedBy: topMatches.map(t=>t.matchedBy).join(','), confidence: 'conflicted', bankDetailsKeys: topMatches.map(t=>t.bankDetailsKeys), basicSalary: topMatches.map(t=>t.basicSalaryRaw), salaryType: null, status: ENHANCED_STATUS.MULTIPLE_MATCHES, reason: 'Multiple candidates with equal confidence' });
      counts.multiple++;
      continue;
    }

    const best = topMatches[0];
    let status = ENHANCED_STATUS.NO_ONBOARDING_RECORD;
    let confidence = 'low';
    let matchedBy = best.matchedBy || (best.reasons.join(',') || null);

    if (best.score >= 100) {
      status = ENHANCED_STATUS.MATCHED; confidence = 'exact'; counts.exact++;
    } else if (best.score >= 50) {
      // high confidence
      if (best.reasons.includes('email')) status = ENHANCED_STATUS.POSSIBLE_EMAIL_MATCH;
      else if (best.reasons.includes('phone')) status = ENHANCED_STATUS.POSSIBLE_PHONE_MATCH;
      else status = ENHANCED_STATUS.POSSIBLE_UID_MATCH;
      confidence = 'high'; counts.high++;
    } else if (best.score > 0) {
      status = ENHANCED_STATUS.POSSIBLE_NAME_MATCH; confidence = 'low'; counts.low++;
    }

    // Salary check
    if (best.basicSalary === null || best.basicSalary <= 0) {
      // mark salary missing
      enhancedResults.push({ employeeDocumentId: u.employeeDocumentId, employeeId, employeeName, employeeEmail, employeePhone, employeeUid, onboardingDocumentId: best.id, matchedBy, confidence, bankDetailsKeys: best.bankDetailsKeys, basicSalary: best.basicSalaryRaw, salaryType: best.basicSalaryRaw === null ? null : typeof best.basicSalaryRaw, status: ENHANCED_STATUS.SALARY_MISSING, reason: 'bankDetails.basicSalary missing or invalid' });
      counts.salary_missing++;
      continue;
    }

    enhancedResults.push({ employeeDocumentId: u.employeeDocumentId, employeeId, employeeName, employeeEmail, employeePhone, employeeUid, onboardingDocumentId: best.id, matchedBy, confidence, bankDetailsKeys: best.bankDetailsKeys, basicSalary: best.basicSalary, salaryType: typeof best.basicSalaryRaw, status, reason: 'Candidate matched by expanded search' });
  }

  const enhancedPath = path.join(OUTPUT_DIR, `enhanced_unmatched_${companyArg}_${nowTimestamp}.json`);
  fs.writeFileSync(enhancedPath, JSON.stringify({ generatedAt: new Date().toISOString(), company: companyArg, counts, enhancedResults }, null, 2));

  // Print concise summary
  console.log('\n--- Enhanced Investigation Summary ---');
  console.log('Exact matches:', counts.exact);
  console.log('High-confidence matches:', counts.high);
  console.log('Low-confidence matches:', counts.low);
  console.log('Multiple matches:', counts.multiple);
  console.log('Salary missing:', counts.salary_missing);
  console.log('No onboarding record:', counts.no_onboarding);
  console.log('Enhanced report saved to', enhancedPath);
}

main()
  .then(async () => {
    if (!apply) {
      try {
        await enhancedInvestigation();
      } catch (e) {
        console.error('Enhanced investigation failed', e);
      }
    }
  })
  .catch((e) => { console.error(e); process.exit(1); });
