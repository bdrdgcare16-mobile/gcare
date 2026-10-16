/* Company Admin role fix verification — company_admin routing + isolation. */
const bcrypt = require('./functions/node_modules/bcryptjs');

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
const get = (p) => fetch(`${FS}/${p}`, { headers: OWNER });
const fl = (f, k) => f?.[k]?.stringValue ?? f?.[k]?.integerValue ?? null;

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
const getApi = (url, t) => fetch(url, { headers: authed(t) });

let pass = 0, fail = 0;
const check = (name, cond, extra = '') => {
  if (cond) { pass++; console.log(`  PASS ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${extra}`); }
};

async function main() {
  // ---- Reseed: emulator data was lost on restart — recreate the fixtures
  // this verification needs (platform admin, legacy admin, employee).
  await put('users/pa-p3', {
    name: S('PA Test'), email: S('pa.p3@test.local'),
    emailLower: S('pa.p3@test.local'),
    password: S(bcrypt.hashSync('Pa@123', 10)),
    role: S('platform_admin'), status: S('active'),
  });
  await put('companies/testco-phase1', {
    name: S('Phase1 Co'), companyName: S('Phase1 Co'),
    status: S('active'), maxUsers: I(50),
    enabledFeatures: A(['dashboard']),
  });
  await put('companies/testco-c', {
    name: S('Company C'), companyName: S('Company C'),
    status: S('active'), maxUsers: I(10),
    enabledFeatures: A(['dashboard']),
  });
  await put('users/admin-p1', {
    name: S('Admin P1'), email: S('admin.p1@test.local'),
    emailLower: S('admin.p1@test.local'),
    password: S(bcrypt.hashSync('Admin@123', 10)),
    role: S('admin'), status: S('active'), companyId: S('testco-phase1'),
  });
  await put('users/emp-c', {
    name: S('Emp C'), email: S('emp.c@test.local'),
    emailLower: S('emp.c@test.local'),
    password: S(bcrypt.hashSync('EmpC@123', 10)),
    role: S('employee'), status: S('active'), companyId: S('testco-c'),
  });

  // Clean previous run's artifacts so the script is idempotent.
  const delIfExists = async (p) =>
    fetch(`${FS}/${p}`, { method: 'DELETE', headers: OWNER });
  console.log('[cleanup] deleting stale fixtures…');
  console.log('[cleanup] TESTCO-CA:', (await delIfExists('companies/TESTCO-CA')).status);
  console.log('[cleanup] TESTCO-CB:', (await delIfExists('companies/TESTCO-CB')).status);
  const staleEmails = [
    'ca.a@test.local', 'ca.b@test.local', 'hr.alpha@test.local',
    'hr.beta@test.local', 'hr.sneaky@test.local',
  ];
  for (const em of staleEmails) {
    const q = await fetch(`${FS}:runQuery`, {
      method: 'POST', headers: OWNER,
      body: JSON.stringify({ structuredQuery: { from: [{ collectionId: 'users' }], where: { fieldFilter: { field: { fieldPath: 'emailLower' }, op: 'EQUAL', value: { stringValue: em } } } } }),
    });
    for (const d of await q.json()) {
      if (d.document) {
        const id = d.document.name.split('/').pop();
        const dr = await fetch(`${FS}/users/${id}`,
          { method: 'DELETE', headers: OWNER });
        console.log('[cleanup] deleted user', id, dr.status);
      }
    }
  }

  const pa = await login('pa.p3@test.local', 'Pa@123');
  const PA = pa.body.token;
  check('setup: platform_admin login', pa.status === 200 && pa.body.role === 'platform_admin', `got ${pa.status} ${pa.body?.error || pa.body?.message || ''}`);

  // ---- TEST 1: PA creates company + company_admin ----
  let r = await post(`${API}/platform/companies`, PA, {
    companyId: 'testco-ca',
    companyName: 'Company Admin Test A',
    adminName: 'CA Alice',
    adminEmail: 'ca.a@test.local',
    adminPassword: 'CompA@123',
    maxUsers: 10,
    enabledFeatures: ['dashboard'],
  });
  let b = await r.json();
  check('1a: company created', r.status === 201, `got ${r.status} ${b?.error || ''}`);
  check('1b: admin role = company_admin in response', b.admin?.role === 'company_admin', `got ${b.admin?.role}`);

  // Firestore doc check — find the new user by email
  const q = await fetch(`${FS}:runQuery`, {
    method: 'POST', headers: OWNER,
    body: JSON.stringify({ structuredQuery: { from: [{ collectionId: 'users' }], where: { fieldFilter: { field: { fieldPath: 'emailLower' }, op: 'EQUAL', value: { stringValue: 'ca.a@test.local' } } } } }),
  });
  const qRows = await q.json();
  const caDoc = qRows.find((d) => d.document)?.document;
  const caF = caDoc?.fields || {};
  check('1c: users doc role = company_admin', fl(caF, 'role') === 'company_admin');
  check('1d: users doc companyId = testco-ca', fl(caF, 'companyId') === 'testco-ca');
  check('1e: status active', fl(caF, 'status') === 'active');

  // Company B for isolation tests
  r = await post(`${API}/platform/companies`, PA, {
    companyId: 'testco-cb',
    companyName: 'Company Admin Test B',
    adminName: 'CA Bob',
    adminEmail: 'ca.b@test.local',
    adminPassword: 'CompB@123',
    maxUsers: 10,
    enabledFeatures: ['dashboard'],
  });
  check('setup: company B created', r.status === 201);

  // ---- TEST 2: company_admin login ----
  const caA = await login('ca.a@test.local', 'CompA@123');
  check('2: company_admin login ok', caA.status === 200 && caA.body.role === 'company_admin', `got ${caA.status} ${caA.body?.error || caA.body?.message || ''}`);
  check('2b: companyId on token response', caA.body.companyId === 'testco-ca' || caA.body.user?.companyId === 'testco-ca');
  const CA_A = caA.body.token;
  const caB = await login('ca.b@test.local', 'CompB@123');
  const CA_B = caB.body.token;

  // ---- TEST 4: create HR ----
  r = await post(`${API}/admin/hr-users`, CA_A, {
    name: 'HR Alpha', email: 'hr.alpha@test.local',
    branch: 'Chennai', department: 'Ops',
  });
  b = await r.json();
  check('4a: company_admin creates HR', r.status === 201 && b.hrUser?.role === 'hr', `got ${r.status} ${b?.error || ''}`);
  check('4b: HR companyId = testco-ca', b.hrUser?.companyId === 'testco-ca');

  // create a second HR
  r = await post(`${API}/admin/hr-users`, CA_A, {
    name: 'HR Beta', email: 'hr.beta@test.local',
    branch: 'Mumbai', department: 'Finance', password: 'HrBeta@123',
  });
  check('4c: second HR created', r.status === 201);

  // ---- TEST 3: list existing HRs ----
  r = await getApi(`${API}/admin/hr-users`, CA_A);
  b = await r.json();
  const hrList = b.hrUsers || [];
  check('3a: list returns HR users', r.status === 200 && hrList.length === 2, `got ${hrList.length}`);
  check('3b: details present', hrList.every((u) => u.email && u.branch && u.department && u.role === 'hr'));

  // ---- TEST 5: isolation — B sees own (empty) list; can't reach A's ----
  r = await getApi(`${API}/admin/hr-users`, CA_B);
  b = await r.json();
  check('5a: company B admin sees only own HRs (none)', r.status === 200 && (b.hrUsers || []).length === 0);
  r = await getApi(`${API}/admin/hr-users?companyId=testco-ca`, CA_B);
  b = await r.json();
  check('5b: ?companyId=other ignored', r.status === 200 && (b.hrUsers || []).length === 0);
  r = await post(`${API}/admin/hr-users`, CA_B, {
    name: 'HR Sneaky', email: 'hr.sneaky@test.local',
    branch: 'X', department: 'Y', companyId: 'testco-ca',
  });
  b = await r.json();
  check('5c: body companyId ignored — HR lands in own company', r.status === 201 && b.hrUser?.companyId === 'testco-cb');

  // ---- TEST 8: unrelated admin/hr/platform/employee APIs → 403 ----
  r = await post(`${API}/admin/create`, CA_A, { email: 'x@x.local', password: 'Xx@12345' });
  check('8a: /admin/create → 403', r.status === 403);
  r = await getApi(`${API}/employees`, CA_A);
  check('8b: /employees (admin CRUD) → 403', r.status === 403);
  r = await getApi(`${API}/hr/company-policy`, CA_A);
  check('8c: /hr/company-policy → 403', r.status === 403);
  r = await getApi(`${API}/hr/feature-request`, CA_A);
  check('8d: /hr/feature-request → 403', r.status === 403);
  r = await getApi(`${API}/platform/companies`, CA_A);
  check('8e: /platform/companies → 403', r.status === 403);
  r = await getApi(`${API}/employee/company-policy`, CA_A);
  check('8f: /employee/company-policy → 403', r.status === 403);
  r = await post(`${API}/auth/admin/create-employee-login`, CA_A, { empid: 'E1' });
  check('8g: create-employee-login → 403', r.status === 403);

  // company_admin without companyId → rejected (tenant role)
  await put('users/ca-noco', {
    name: S('CA NoCompany'), email: S('ca.noco@test.local'),
    emailLower: S('ca.noco@test.local'),
    password: S(bcrypt.hashSync('NoCo@123', 10)),
    role: S('company_admin'), status: S('active'),
  });
  const noCo = await login('ca.noco@test.local', 'NoCo@123');
  check('company_admin w/o companyId → 403', noCo.status === 403, `got ${noCo.status}`);

  // invalid role still rejected
  await put('users/badrole', {
    name: S('Bad'), email: S('bad.role@test.local'),
    emailLower: S('bad.role@test.local'),
    password: S(bcrypt.hashSync('Bad@123', 10)),
    role: S('wizard'), status: S('active'), companyId: S('testco-ca'),
  });
  const bad = await login('bad.role@test.local', 'Bad@123');
  check('invalid role → 403', bad.status === 403, `got ${bad.status}`);

  // inactive company_admin → rejected
  await put('users/ca-inactive', {
    name: S('CA Inactive'), email: S('ca.inactive@test.local'),
    emailLower: S('ca.inactive@test.local'),
    password: S(bcrypt.hashSync('Inact@123', 10)),
    role: S('company_admin'), status: S('inactive'), companyId: S('testco-ca'),
  });
  const inact = await login('ca.inactive@test.local', 'Inact@123');
  check('inactive company_admin → 403', inact.status === 403, `got ${inact.status}`);

  // ---- Backward compat: legacy 'admin' still manages hr-users ----
  const admin = await login('admin.p1@test.local', 'Admin@123');
  r = await getApi(`${API}/admin/hr-users`, admin.body.token);
  check('legacy admin still lists hr-users', r.status === 200, `got ${r.status}`);

  // ---- TEST 6/9/10: other roles unaffected ----
  const hr = await login('hr.alpha@test.local', '' ); // auto-gen password; use beta's known one
  const hrBeta = await login('hr.beta@test.local', 'HrBeta@123');
  check('6: hr login → role hr', hrBeta.status === 200 && hrBeta.body.role === 'hr');
  const emp = await login('emp.c@test.local', 'EmpC@123');
  check('9: employee login → role employee', emp.status === 200 && emp.body.role === 'employee');
  check('10: platform_admin unchanged', pa.body.role === 'platform_admin');

  // HR created by company_admin enters the existing HR flow (policy gate)
  r = await getApi(`${API}/hr/company-policy`, hrBeta.body.token);
  b = await r.json();
  check('6b: hr sees own policy gate', r.status === 200, `got ${r.status}`);

  // feature-request flow intact
  r = await getApi(`${API}/hr/feature-request`, hrBeta.body.token);
  check('regression: hr feature-request', r.status === 200);

  console.log(`\n=== ${pass} passed, ${fail} failed ===`);
  process.exit(fail ? 1 : 0);
}

main().catch((e) => { console.error('verify failed:', e); process.exit(1); });
