/* Optional geofencing verification — Mode A / Mode B / legacy / rules matrix. */
const bcrypt = require('./functions/node_modules/bcryptjs');
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
const admin = require('./functions/node_modules/firebase-admin');

const FS =
  'http://127.0.0.1:8080/v1/projects/serv-dev-f2557/databases/(default)/documents';
const API = 'http://127.0.0.1:5002/serv-dev-f2557/us-central1/api';
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const OWNER = { Authorization: 'Bearer owner', 'Content-Type': 'application/json' };
const JSON_H = { 'Content-Type': 'application/json' };

const S = (v) => ({ stringValue: v });
const A = (arr) => ({ arrayValue: { values: arr.map(S) } });
const I = (v) => ({ integerValue: String(v) });
const D = (v) => ({ doubleValue: v });
const put = (p, fields) =>
  fetch(`${FS}/${p}`, { method: 'PATCH', headers: OWNER, body: JSON.stringify({ fields }) });
const del = (p) => fetch(`${FS}/${p}`, { method: 'DELETE', headers: OWNER });

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
const putApi = (url, t, body) =>
  fetch(url, { method: 'PUT', headers: authed(t), body: JSON.stringify(body ?? {}) });
const getApi = (url, t) => fetch(url, { headers: authed(t) });

let pass = 0, fail = 0;
const check = (name, cond, extra = '') => {
  if (cond) { pass++; console.log(`  PASS ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${extra}`); }
};

const PW = 'Test@123';
const hash = bcrypt.hashSync(PW, 10);
const OFFICE = { lat: 12.9716, lng: 77.5946, radius: 200 };
const OUTSIDE = { lat: 13.05, lng: 77.65 }; // ~10km away

async function seedUser(id, email, role, companyId, empid, approved) {
  const f = {
    name: S(id), email: S(email), emailLower: S(email),
    password: S(hash), role: S(role), status: S('active'),
  };
  if (companyId) f.companyId = S(companyId);
  if (empid) { f.empid = S(empid); f.empId = S(empid); }
  if (approved) f.approvedFeatures = A(approved);
  await put(`users/${id}`, f);
}
async function seedEmp(companyId, empid, name, location) {
  const f = {
    empid: S(empid), empId: S(empid), name: S(name),
    companyId: S(companyId), status: S('active'),
    email: S(`${empid.toLowerCase()}@geo.test`),
    emailLower: S(`${empid.toLowerCase()}@geo.test`),
  };
  if (location) f.location = S(location);
  await put(`employees/${companyId}-${empid}`, f);
}
async function seedCompany(id, features /* null => legacy */) {
  const f = {
    name: S(id), companyName: S(id), status: S('active'), maxUsers: I(50),
  };
  if (features) f.enabledFeatures = A(features);
  await put(`companies/${id}`, f);
}
async function seedOffice(id, companyId, branch) {
  await put(`officeLocations/${id}`, {
    companyId: S(companyId), branchName: S(branch), name: S(`${branch} Office`),
    address: S('1 Test St'), latitude: D(OFFICE.lat), longitude: D(OFFICE.lng),
    radius: D(OFFICE.radius), timestamp: S('2025-01-01T00:00:00Z'),
  });
}

const checkInBody = (name, extra = {}) => ({ name, ...extra });

async function main() {
  admin.initializeApp({ projectId: 'serv-dev-f2557' });

  // ---------- Seed ----------
  console.log('[seed] companies/users/employees…');
  await seedCompany('geo-a', ['dashboard', 'employees', 'attendance']);               // Mode A
  await seedCompany('geo-b', ['dashboard', 'employees', 'attendance', 'geofencing']); // Mode B
  await seedCompany('geo-c', ['dashboard', 'employees', 'attendance', 'geofencing']); // Mode B, no office
  await seedCompany('geo-d', ['dashboard', 'employees']);                             // attendance off
  await seedCompany('geo-legacy', null);                                              // legacy tenant
  await seedOffice('geo-b-hq', 'geo-b', 'HQ');
  await seedOffice('geo-leg-hq', 'geo-legacy', 'LegacyBranch');

  const users = [
    ['u-ga1', 'ga1@geo.test', 'employee', 'geo-a', 'GA1', null],
    ['u-gb1', 'gb1@geo.test', 'employee', 'geo-b', 'GB1', null],
    ['u-gb2', 'gb2@geo.test', 'employee', 'geo-b', 'GB2', null],
    ['u-gb3', 'gb3@geo.test', 'employee', 'geo-b', 'GB3', null],
    ['u-gb4', 'gb4@geo.test', 'employee', 'geo-b', 'GB4', null],
    ['u-gc1', 'gc1@geo.test', 'employee', 'geo-c', 'GC1', null],
    ['u-gd1', 'gd1@geo.test', 'employee', 'geo-d', 'GD1', null],
    ['u-gl1', 'gl1@geo.test', 'employee', 'geo-legacy', 'GL1', null],
    ['u-gl2', 'gl2@geo.test', 'employee', 'geo-legacy', 'GL2', null],
    ['u-hrok', 'hrok@geo.test', 'hr', 'geo-b', 'HB1', ['attendance']],
    ['u-hrno', 'hrno@geo.test', 'hr', 'geo-b', 'HB2', null],
    ['u-adb', 'adb@geo.test', 'admin', 'geo-b', null, null],
  ];
  for (const u of users) await seedUser(...u);

  await seedEmp('geo-b', 'GB1', 'GB One', 'HQ');
  await seedEmp('geo-b', 'GB2', 'GB Two', 'HQ');
  await seedEmp('geo-b', 'GB3', 'GB Three', 'HQ');
  await seedEmp('geo-b', 'GB4', 'GB Four', 'HQ');
  await seedEmp('geo-c', 'GC1', 'GC One', 'HQ');
  await seedEmp('geo-legacy', 'GL1', 'GL One', 'LegacyBranch');
  await seedEmp('geo-legacy', 'GL2', 'GL Two', 'Nowhere');

  // Idempotency: purge prior runs' attendance/otherLocation/tracking for geo-*
  for (const coll of ['attendance', 'otherLocation', 'tracking']) {
    for (const cid of ['geo-a', 'geo-b', 'geo-c', 'geo-d', 'geo-legacy']) {
      for (const d of await queryAll(coll, 'companyId', cid)) {
        await del(d.name.split('/documents/')[1]);
      }
    }
  }
  // …and the office docs the HR test adds (address-dedupe would 400 on re-run)
  for (const d of await queryAll('officeLocations', 'companyId', 'geo-b')) {
    const addr = d.fields?.address?.stringValue;
    if (addr === '2 Test Ave') await del(d.name.split('/documents/')[1]);
  }

  const T = {};
  for (const [id, email] of users) {
    const r = await login(email, PW);
    if (r.status === 200) T[id] = r.body.token;
    else console.log(`  [login fail] ${email}: ${r.status} ${r.body?.error || ''}`);
  }
  check('setup: all logins succeed', Object.keys(T).length === users.length);

  // ---------- Phase 5: assigned-office endpoint ----------
  console.log('\n[Phase 5] /office/assigned');
  let r = await getApi(`${API}/office/assigned`, T['u-gb1']);
  let b = await r.json();
  check('5a: Mode B employee gets policy+office',
    r.status === 200 && b.geofencingEnabled === true && b.office?.branchName === 'HQ',
    `got ${r.status} ${JSON.stringify(b).slice(0, 160)}`);
  r = await getApi(`${API}/office/assigned`, T['u-ga1']);
  b = await r.json();
  check('5b: Mode A employee gets policy, office null',
    r.status === 200 && b.geofencingEnabled === false && b.office === null);
  r = await getApi(`${API}/office/locations`, T['u-gb1']);
  check('5c: employee still denied /office/locations', r.status === 403);

  // ---------- Scenario A: Mode A, no office ----------
  console.log('\n[A] attendance ON, geofencing OFF, no office');
  r = await post(`${API}/attendance/check-in`, T['u-ga1'], checkInBody('GA One'));
  b = await r.json();
  check('A1: check-in without GPS succeeds', r.status === 200, `got ${r.status} ${b?.error || b?.code || ''}`);
  r = await post(`${API}/attendance/check-out`, T['u-ga1'], checkInBody('GA One'));
  b = await r.json();
  check('A2: check-out without GPS succeeds', r.status === 200, `got ${r.status} ${b?.error || b?.code || ''}`);
  const attA = await queryAll('attendance', 'empid', 'GA1');
  check('A3: attendance doc saved', attA.length === 1 && attA[0].fields?.checkIn, `docs=${attA.length}`);
  const olA = await queryAll('otherLocation', 'empid', 'GA1');
  check('A4: no phantom otherLocation event', olA.length === 0, `docs=${olA.length}`);

  // ---------- Scenario B: Mode B inside ----------
  console.log('\n[B] geofencing ON, valid office, inside radius');
  r = await getApi(`${API}/office/assigned`, T['u-gb1']);
  r = await post(`${API}/attendance/check-in`, T['u-gb1'], checkInBody('GB One', {
    location: 'HQ', latitude: OFFICE.lat, longitude: OFFICE.lng, accuracy: 10,
  }));
  b = await r.json();
  check('B1: inside-radius check-in accepted', r.status === 200 && b.withinRadius === true,
    `got ${r.status} ${b?.error || b?.code || ''}`);
  r = await post(`${API}/attendance/check-out`, T['u-gb1'], checkInBody('GB One', {
    latitude: OFFICE.lat, longitude: OFFICE.lng, accuracy: 10,
  }));
  b = await r.json();
  check('B2: inside-radius check-out accepted', r.status === 200, `got ${r.status} ${b?.error || b?.code || ''}`);

  // ---------- Scenario C: Mode B outside ----------
  console.log('\n[C] geofencing ON, outside radius → approval workflow');
  r = await post(`${API}/attendance/check-in`, T['u-gb2'], checkInBody('GB Two', {
    location: 'HQ', latitude: OUTSIDE.lat, longitude: OUTSIDE.lng, accuracy: 10,
  }));
  b = await r.json();
  check('C1: outside-radius check-in recorded + flagged',
    r.status === 200 && b.withinRadius === false && b.pendingLocationApproval === true,
    `got ${r.status} ${JSON.stringify(b).slice(0, 160)}`);
  const olB = await queryAll('otherLocation', 'empid', 'GB2');
  check('C2: pending otherLocation approval event created',
    olB.length === 1 && olB[0].fields?.approvalStatus?.stringValue === 'Pending');

  // ---------- Scenario D: Mode B, no office ----------
  console.log('\n[D] geofencing ON, no office configured');
  r = await post(`${API}/attendance/check-in`, T['u-gc1'], checkInBody('GC One', {
    location: 'HQ', latitude: OFFICE.lat, longitude: OFFICE.lng, accuracy: 10,
  }));
  b = await r.json();
  check('D1: missing office → GEO_FENCE_NOT_CONFIGURED',
    r.status === 422 && b.code === 'GEO_FENCE_NOT_CONFIGURED',
    `got ${r.status} ${b?.code || b?.error || ''}`);
  r = await post(`${API}/attendance/check-in`, T['u-gc1'], checkInBody('GC One', {
    location: 'HQ', // coords omitted — config error must still win
  }));
  b = await r.json();
  check('D2: omitted coords cannot bypass config error',
    r.status === 422 && b.code === 'GEO_FENCE_NOT_CONFIGURED',
    `got ${r.status} ${b?.code || ''}`);

  // ---------- Scenario E/F: GPS requirements ----------
  console.log('\n[E/F] geofencing ON, GPS validation');
  r = await post(`${API}/attendance/check-in`, T['u-gb3'], checkInBody('GB Three', { location: 'HQ' }));
  b = await r.json();
  check('E: missing GPS → LOCATION_REQUIRED',
    r.status === 422 && b.code === 'LOCATION_REQUIRED', `got ${r.status} ${b?.code || b?.error || ''}`);
  r = await post(`${API}/attendance/check-in`, T['u-gb4'], checkInBody('GB Four', {
    location: 'HQ', latitude: OFFICE.lat, longitude: OFFICE.lng, accuracy: 500,
  }));
  b = await r.json();
  check('F: accuracy 500m → POOR_GPS',
    r.status === 422 && b.code === 'POOR_GPS', `got ${r.status} ${b?.code || b?.error || ''}`);

  // ---------- Scenario G: attendance off ----------
  console.log('\n[G] attendance feature OFF');
  r = await post(`${API}/attendance/check-in`, T['u-gd1'], checkInBody('GD One'));
  b = await r.json();
  check('G: check-in denied', r.status === 403, `got ${r.status} ${b?.error || b?.code || ''}`);

  // ---------- Legacy compat ----------
  console.log('\n[P] legacy tenant (no enabledFeatures) — implicit behaviour preserved');
  r = await post(`${API}/attendance/check-in`, T['u-gl2'], checkInBody('GL Two', { location: 'Nowhere' }));
  b = await r.json();
  check('P1: legacy + no matching office → succeeds, legacy pending event',
    r.status === 200, `got ${r.status} ${b?.error || b?.code || ''}`);
  const olL = await queryAll('otherLocation', 'empid', 'GL2');
  check('P2: legacy "No matching branch" event preserved',
    olB && olL.length === 1 && /No matching branch/.test(olL[0].fields?.otherLocation?.stringValue || ''),
    `docs=${olL.length}`);
  r = await post(`${API}/attendance/check-in`, T['u-gl1'], checkInBody('GL One', { location: 'LegacyBranch' }));
  b = await r.json();
  check('P3: legacy + office exists + no GPS → LOCATION_REQUIRED (implicit enforcement)',
    r.status === 422 && b.code === 'LOCATION_REQUIRED', `got ${r.status} ${b?.code || b?.error || ''}`);
  r = await post(`${API}/attendance/check-in`, T['u-gl1'], checkInBody('GL One', {
    location: 'LegacyBranch', latitude: OFFICE.lat, longitude: OFFICE.lng, accuracy: 10,
  }));
  b = await r.json();
  check('P4: legacy inside-radius check-in succeeds', r.status === 200, `got ${r.status} ${b?.error || ''}`);

  // ---------- HR access ----------
  console.log('\n[I/J] HR office configuration');
  r = await post(`${API}/office/add`, T['u-hrok'], {
    branchName: 'Annex', name: 'Annex Office', address: '2 Test Ave',
    latitude: OFFICE.lat, longitude: OFFICE.lng, radius: 150,
  });
  check('I: HR with attendance approval → office add ok', r.status === 200 || r.status === 201,
    `got ${r.status}`);
  r = await post(`${API}/office/add`, T['u-hrno'], {
    branchName: 'X', name: 'X', address: 'X', latitude: 1, longitude: 1, radius: 10,
  });
  check('J: HR without approval → denied', r.status === 403, `got ${r.status}`);
  r = await post(`${API}/office/add`, T['u-gb1'], {
    branchName: 'Y', name: 'Y', address: 'Y', latitude: 1, longitude: 1, radius: 10,
  });
  check('J2: employee office add → denied', r.status === 403, `got ${r.status}`);

  // ---------- Cross-company ----------
  console.log('\n[H/M] isolation');
  r = await putApi(`${API}/office/update/geo-leg-hq`, T['u-hrok'], {
    branchName: 'Hijack', name: 'Hijack', address: 'X',
    latitude: 1, longitude: 1, radius: 999,
  });
  check('M: HR of geo-b cannot update geo-legacy office doc', r.status === 403, `got ${r.status}`);
  r = await getApi(`${API}/office/assigned`, T['u-gc1']);
  b = await r.json();
  check('H: geo-c employee sees own policy only (no office)', r.status === 200 && b.office === null && b.companyId === 'geo-c');

  // ---------- Firestore rules (client SDK path) ----------
  console.log('\n[K] firestore.rules — direct client writes denied');
  try {
    await admin.auth().createUser({ uid: 'rules-emp-b', email: 'rulesemp@geo.test' }).catch(() => {});
    await admin.auth().setCustomUserClaims('rules-emp-b',
      { companyId: 'geo-b', role: 'employee', empid: 'GB1' });
    const custom = await admin.auth().createCustomToken('rules-emp-b');
    const signIn = await fetch(`${AUTH}/accounts:signInWithCustomToken?key=fake`, {
      method: 'POST', headers: JSON_H,
      body: JSON.stringify({ token: custom, returnSecureToken: true }),
    });
    const { idToken } = await signIn.json();
    const H = { Authorization: `Bearer ${idToken}`, 'Content-Type': 'application/json' };

    let rr = await fetch(`${FS}/officeLocations/hack1`, {
      method: 'PATCH', headers: H,
      body: JSON.stringify({ fields: { companyId: S('geo-b'), branchName: S('Hack'), latitude: D(1), longitude: D(1), radius: D(1) } }),
    });
    check('K1: employee direct office write → denied', rr.status === 403, `got ${rr.status}`);
    rr = await fetch(`${FS}/attendance/hack2`, {
      method: 'PATCH', headers: H,
      body: JSON.stringify({ fields: { companyId: S('geo-b'), empid: S('GB1'), date: S('2099-01-01'), checkIn: S('09:00:00') } }),
    });
    check('K2: employee direct attendance write → denied', rr.status === 403, `got ${rr.status}`);
    rr = await fetch(`${FS}/otherLocation/hack3`, {
      method: 'PATCH', headers: H,
      body: JSON.stringify({ fields: { companyId: S('geo-b'), empid: S('GB1'), approvalStatus: S('Approved') } }),
    });
    check('K3: employee direct otherLocation write → denied', rr.status === 403, `got ${rr.status}`);
    rr = await fetch(`${FS}/officeLocations/geo-b-hq`, { headers: H });
    check('K4: same-company read still allowed', rr.status === 200, `got ${rr.status}`);
    rr = await fetch(`${FS}/officeLocations/geo-leg-hq`, { headers: H });
    check('K5: cross-company read → denied', rr.status === 403, `got ${rr.status}`);
  } catch (e) {
    check('K: rules test harness', false, String(e).slice(0, 200));
  }

  console.log(`\n=== ${pass} passed, ${fail} failed ===`);
  process.exit(fail ? 1 : 0);
}

main().catch((e) => { console.error('verify failed:', e); process.exit(1); });
