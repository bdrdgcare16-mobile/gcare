const firebase = require('./lib/config/firebase');
const db = firebase.db;

async function run() {
  const empid = 'MR014';
  const queries = [
    db.collection('employee_onboarding_dev').where('empid', '==', empid).limit(5).get(),
    db.collection('employee_onboarding_dev').where('employeeId', '==', empid).limit(5).get(),
    db.collection('employee_onboarding_dev').where('uid', '==', empid).limit(5).get(),
    db.collection('employee_onboarding_dev').where('officialEmail', '==', empid).limit(5).get(),
    db.collection('employee_onboarding_dev').where('companyDetails.employeeId', '==', empid).limit(5).get(),
    db.collection('employee_onboarding_dev').where('companyDetails.officialEmail', '==', empid).limit(5).get(),
  ];

  const results = await Promise.all(queries);
  results.forEach((r, i) => console.log(i + 1, 'count=', r.size));
}

run().catch(e => { console.error(e); process.exit(1); });
