/* Shift-assignment verification — onboarding → approval → attendance. */
const bcrypt = require('./functions/node_modules/bcryptjs');
const fs = require('fs');
const path = require('path');

// Load JWT_SECRET so encryptCredential() derives the same key the emulator
// functions use (.env.local) — the secret never enters this output.
const envLocal = fs.readFileSync(
  path.join(__dirname, 'functions', '.env.local'), 'utf8');
for (const line of envLocal.split(/\r?\n/)) {
  const m = line.match(/^([A-Z_]+)=(.*)$/);
  if (m && process.env[m[1]] === undefined) process.env[m[1]] = m[2];
}
const { encryptCredential } =
  require('./functions/lib/services/onboardingCredential.service');

const FS =
  'http://127.0.0.1:8080/v1/projects/serv-dev-f2557/databases/(default)/documents';
const API = 'http://127.0.0.1:5002/serv-dev-f2557/us-central1/api';
const OWNER = { Authorization: 'Bearer owner', 'Content-Type': 'application/json' };
const JSON_H = { 'Content-Type': 'application/json' };

const S = (v) => ({ stringValue: v });
const A = (arr) => ({ arrayValue: { values: arr.map(S) } });
const I = (v) => ({ integerValue: String(v) });
const put = (p, fields) =>
  fetch(`${FS}/${p}`, { method: 'PATCH', headers: OWNER, body: JSON.stringify({ fields }) });
const del = (p) => fetch(`${FS}/${p}`, { method: 'DELETE', headers: OWNER });
const get = (p) => fetch(`${FS}/${p}`, { headers: OWNER });

async function queryAll(coll, field, value) {
  const q = await fetch(`${FS}:runQuery`, {
    method: 'POST', headers: OWNER,
    body: JSON.stringify({ structuredQuery: {
      from: [{ collectionId: coll }],
      where: { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: { stringValue: value } } },
    } }),
  });
  const rows = await q.json();
  return rows.filter((r) => r.document).map((r) => r.document);
}

async function login(email, password) {
  const res = await fetch(`${API}/auth/login`, {
    method: 'POST', headers: JSON_H,
    body: JSON.stringify({ email, password }),
  });
  return { status: res.status, body: await res.json() };
}
const authed = (t) => ({ ...JSON_H, Authorization: `Bearer ${t}` });
const post = (url, t, body) =>
  fetch(url, { method: 'POST', headers: authed(t), body: JSON.stringify(body ?? {}) });
const patch = (url, t, body) =>
  fetch(url, { method: 'PATCH', headers: authed(t), body: JSON.stringify(body ?? {}) });
const getApi = (url, t) => fetch(url, { headers: authed(t) });

let pass = 0, fail = 0;
const check = (name, cond, extra = '') => {
  if (cond) { pass++; console.log(`  PASS ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${extra}`); }
};

const PW = 'Test@123';
const EMP_PW = 'Emp@1234';

async function main() {
  // ---------- Seed ----------
  console.log('[seed] company/shift/admin/onboarding docs…');
  await put('companies/geo-e', {
    name: S('geo-e'), companyName: S('geo-e'), status: S('active'), maxUsers: I(50),
    enabledFeatures: A(['dashboard', 'employees', 'attendance', 'onboarding']),
  });
  // Overnight shift too, to cover the overnight case.
  await put('shifts/shift-e-general', {
    id: S('shift-e-general'), name: S('General'), shiftname: S('GEN'),
    startTime: S('09:00'), endTime: S('17:30'), companyId: S('geo-e'),
  });
  await put('shifts/shift-e-night', {
    id: S('shift-e-night'), name: S('Night'), shiftname: S('NGT'),
    startTime: S('21:00'), endTime: S('06:00'), companyId: S('geo-e'),
  });
  await put('users/u-cae', {
    name: S('CA E'), email: S('ca.e@geo.test'), emailLower: S('ca.e@geo.test'),
    password: S(bcrypt.hashSync(PW, 10)), role: S('company_admin'),
    status: S('active'), companyId: S('geo-e'),
  });
  // Employee with NO assigned shift (direct record, no onboarding)
  await put('users/u-noshift', {
    name: S('No Shift'), email: S('noshift@geo.test'), emailLower: S('noshift@geo.test'),
    password: S(bcrypt.hashSync(PW, 10)), role: S('employee'),
    status: S('active'), companyId: S('geo-e'), empid: S('NOS1'), empId: S('NOS1'),
  });
  await put('employees/geo-e-NOS1', {
    empid: S('NOS1'), empId: S('NOS1'), name: S('No Shift'),
    companyId: S('geo-e'), status: S('active'),
    emailLower: S('noshift@geo.test'),
  });
  // Legacy-style employee: shiftGroup name only, no shiftId
  await put('users/u-legacyshift', {
    name: S('Legacy Shift'), email: S('legacyshift@geo.test'),
    emailLower: S('legacyshift@geo.test'),
    password: S(bcrypt.hashSync(PW, 10)), role: S('employee'),
    status: S('active'), companyId: S('geo-e'), empid: S('LEG1'), empId: S('LEG1'),
  });
  await put('employees/geo-e-LEG1', {
    empid: S('LEG1'), empId: S('LEG1'), name: S('Legacy Shift'),
    companyId: S('geo-e'), status: S('active'),
    emailLower: S('legacyshift@geo.test'), shiftGroup: S('Night'),
  });
  // Employee whose assigned shift was deleted (dangling name)
  await put('users/u-goneshift', {
    name: S('Gone Shift'), email: S('goneshift@geo.test'),
    emailLower: S('goneshift@geo.test'),
    password: S(bcrypt.hashSync(PW, 10)), role: S('employee'),
    status: S('active'), companyId: S('geo-e'), empid: S('GON1'), empId: S('GON1'),
  });
  await put('employees/geo-e-GON1', {
    empid: S('GON1'), empId: S('GON1'), name: S('Gone Shift'),
    companyId: S('geo-e'), status: S('active'),
    emailLower: S('goneshift@geo.test'), shiftGroup: S('Deleted Shift'),
  });

  const onboardingDoc = (id, empid, email, extra = {}) => put(`employee_onboarding_dev/${id}`, {
    companyDetails: { mapValue: { fields: {
      companyId: S('geo-e'), companyName: S('geo-e'), employeeId: S(empid),
      officialEmail: S(email), department: S('IT'), designation: S('Dev'),
      branchLocation: S('HQ'), dateOfJoining: S('01-01-2026'),
      reportingManager: S('Mgr'), workMode: S('Work From Office'),
      employeeType: S('Full Time'), experienceLevel: S('Fresher'),
      ...extra,
    } } },
    personalDetails: { mapValue: { fields: {
      fullName: S(empid + ' Name'), mobileCountryCode: S('+91'),
      mobileNumber: S('9000000001'), personalEmail: S(email),
    } } },
    initialPasswordEnc: S(encryptCredential(EMP_PW)),
    status: S('pending'),
  });

  // shift via display name (new submissions also send shiftId — cover both)
  await onboardingDoc('onb-e1', 'SE1', 'emp.se1@geo.test',
    { shiftTime: S('General'), shiftId: S('shift-e-general') });
  // name-only, as older pending docs would have
  await onboardingDoc('onb-e2', 'SE2', 'emp.se2@geo.test',
    { shiftTime: S('Night') });
  // invalid shift reference
  await onboardingDoc('onb-e3', 'SE3', 'emp.se3@geo.test',
    { shiftTime: S('Does Not Exist') });

  // Clean prior artifacts for idempotency
  for (const coll of ['attendance', 'otherLocation', 'tracking']) {
    for (const d of await queryAll(coll, 'companyId', 'geo-e')) {
      await del(d.name.split('/documents/')[1]);
    }
  }
  for (const [coll, field, val] of [
    ['employees', 'empid', 'SE1'], ['employees', 'empid', 'SE2'], ['employees', 'empid', 'SE3'],
    ['users', 'empid', 'SE1'], ['users', 'empid', 'SE2'], ['users', 'empid', 'SE3'],
  ]) {
    for (const d of await queryAll(coll, field, val)) {
      await del(d.name.split('/documents/')[1]);
    }
  }
  await del('employee_onboarding_dev/onb-e1');
  await del('employee_onboarding_dev/onb-e2');
  await del('employee_onboarding_dev/onb-e3');
  await onboardingDoc('onb-e1', 'SE1', 'emp.se1@geo.test',
    { shiftTime: S('General'), shiftId: S('shift-e-general') });
  await onboardingDoc('onb-e2', 'SE2', 'emp.se2@geo.test',
    { shiftTime: S('Night') });
  await onboardingDoc('onb-e3', 'SE3', 'emp.se3@geo.test',
    { shiftTime: S('Does Not Exist') });

  // ---------- Logins ----------
  const ca = await login('ca.e@geo.test', PW);
  check('setup: company_admin login', ca.status === 200, `got ${ca.status}`);
  const CA = ca.body.token;
  const noShift = await login('noshift@geo.test', PW);
  const legShift = await login('legacyshift@geo.test', PW);
  const goneShift = await login('goneshift@geo.test', PW);
  check('setup: employee logins',
    noShift.status === 200 && legShift.status === 200 && goneShift.status === 200);

  // ---------- Approval flow ----------
  console.log('\n[approval] company admin approves onboarding');
  let r = await patch(`${API}/onboarding/onb-e1/status`, CA, { status: 'approved' });
  let b = await r.json();
  check('A1: approve with shiftId+name succeeds', r.status === 200 && b.success === true,
    `got ${r.status} ${b?.message || ''}`);

  const empDocs = await queryAll('employees', 'empid', 'SE1');
  const empF = empDocs[0]?.fields;
  check('A2: employee doc shiftId stored', empF?.shiftId?.stringValue === 'shift-e-general',
    `got ${JSON.stringify(empF?.shiftId)}`);
  check('A3: employee doc shiftGroup = display name', empF?.shiftGroup?.stringValue === 'General',
    `got ${JSON.stringify(empF?.shiftGroup)}`);

  r = await patch(`${API}/onboarding/onb-e2/status`, CA, { status: 'approved' });
  b = await r.json();
  check('A4: approve with name-only shift succeeds', r.status === 200 && b.success === true,
    `got ${r.status} ${b?.message || ''}`);
  const empDocs2 = await queryAll('employees', 'empid', 'SE2');
  check('A5: name-only resolves to shift doc id',
    empDocs2[0]?.fields?.shiftId?.stringValue === 'shift-e-night');

  r = await patch(`${API}/onboarding/onb-e3/status`, CA, { status: 'approved' });
  b = await r.json();
  check('A6: invalid shift → 400 SHIFT_NOT_FOUND, stays pending',
    r.status === 400 && b.code === 'SHIFT_NOT_FOUND',
    `got ${r.status} ${b?.code || b?.message || ''}`);
  const onb3 = await get('employee_onboarding_dev/onb-e3');
  const onb3f = (await onb3.json()).fields;
  check('A7: failed approval leaves status pending',
    onb3f?.status?.stringValue === 'pending', `got ${onb3f?.status?.stringValue}`);

  // ---------- Employee assigned-shift endpoint ----------
  console.log('\n[/shifts/assigned]');
  const e1 = await login('emp.se1@geo.test', EMP_PW);
  check('L1: approved employee logs in with onboarding password', e1.status === 200,
    `got ${e1.status} ${e1.body?.error || ''}`);
  const E1 = e1.body.token;

  r = await getApi(`${API}/shifts/assigned`, E1);
  b = await r.json();
  check('L2: assigned shift resolves with times',
    r.status === 200 && b.shift?.startTime === '09:00' && b.shift?.endTime === '17:30',
    `got ${r.status} ${JSON.stringify(b).slice(0, 140)}`);

  r = await getApi(`${API}/shifts/assigned`, noShift.body.token);
  b = await r.json();
  check('L3: employee without shift → NO_SHIFT_ASSIGNED',
    r.status === 200 && b.shift === null && b.reason === 'NO_SHIFT_ASSIGNED',
    `got ${JSON.stringify(b).slice(0, 140)}`);

  r = await getApi(`${API}/shifts/assigned`, legShift.body.token);
  b = await r.json();
  check('L4: legacy shiftGroup name resolves (overnight shift)',
    r.status === 200 && b.shift?.startTime === '21:00' && b.shift?.endTime === '06:00',
    `got ${JSON.stringify(b).slice(0, 140)}`);

  r = await getApi(`${API}/shifts/assigned`, goneShift.body.token);
  b = await r.json();
  check('L5: deleted shift → SHIFT_NOT_FOUND',
    r.status === 200 && b.shift === null && b.reason === 'SHIFT_NOT_FOUND');

  // employee cannot read another company's shift by id
  const foreign = await login('gb1@geo.test', 'Test@123'); // geo-b employee
  if (foreign.status === 200) {
    r = await getApi(`${API}/shifts/shift-e-general`, foreign.body.token);
    check('L6: cross-company shift read → denied', r.status === 403,
      `got ${r.status}`);
  } else {
    check('L6: cross-company shift read → denied', false, 'foreign login failed');
  }

  // ---------- Attendance ----------
  console.log('\n[attendance] Mode A check-in/out for onboarded employee');
  r = await post(`${API}/attendance/check-in`, E1, { name: 'SE1 Name' });
  b = await r.json();
  check('C1: check-in succeeds (Mode A, no GPS)', r.status === 200,
    `got ${r.status} ${b?.error || b?.code || ''}`);
  r = await post(`${API}/attendance/check-out`, E1, {});
  b = await r.json();
  check('C2: check-out succeeds', r.status === 200,
    `got ${r.status} ${b?.error || b?.code || ''}`);

  console.log(`\n=== ${pass} passed, ${fail} failed ===`);
  process.exit(fail ? 1 : 0);
}

main().catch((e) => { console.error('verify failed:', e); process.exit(1); });
