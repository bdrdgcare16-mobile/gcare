const fs = require('fs');
const path = require('path');

// Ensure firebase admin is initialized via existing config
const firebase = require('./lib/config/firebase');
const db = firebase.db;

const { calculateEmployeePayroll } = require('./lib/services/payrollService');

async function findOnboarding(empid) {
  const queries = [
    db.collection('employee_onboarding_dev').where('empid', '==', empid).limit(1).get(),
    db.collection('employee_onboarding_dev').where('employeeId', '==', empid).limit(1).get(),
    db.collection('employee_onboarding_dev').where('uid', '==', empid).limit(1).get(),
    db.collection('employee_onboarding_dev').where('officialEmail', '==', empid).limit(1).get(),
    db.collection('employee_onboarding_dev').where('companyDetails.employeeId', '==', empid).limit(1).get(),
    db.collection('employee_onboarding_dev').where('companyDetails.officialEmail', '==', empid).limit(1).get(),
  ];

  const snaps = await Promise.all(queries);
  for (const s of snaps) {
    if (!s.empty) return s.docs[0].data();
  }

  return null;
}

async function run() {
  const empid = 'MR014';
  try {
    const empSnap = await db.collection('employees').where('empid', '==', empid).limit(1).get();

    if (empSnap.empty) {
      console.error('MR014 not found in employees collection');
      // still attempt onboarding lookup
    }

    const empDoc = empSnap.empty ? null : empSnap.docs[0].data();
    const companyId = empDoc?.companyId || 'COMP001';

    const onboarding = await findOnboarding(empid);

    const result = {
      employeeFoundInEmployees: !empSnap.empty,
      employeeDoc: empDoc || null,
      onboardingFound: !!onboarding,
      onboardingDoc: onboarding || null,
    };

    if (!onboarding) {
      // gather diagnostics
      const diagnostics = {};
      diagnostics.by_empid = (await db.collection('employee_onboarding_dev').where('empid', '==', empid).limit(5).get()).docs.map(d=>d.data());
      diagnostics.by_employeeId = (await db.collection('employee_onboarding_dev').where('employeeId', '==', empid).limit(5).get()).docs.map(d=>d.data());
      diagnostics.by_uid = (await db.collection('employee_onboarding_dev').where('uid', '==', empid).limit(5).get()).docs.map(d=>d.data());
      diagnostics.by_officialEmail = (await db.collection('employee_onboarding_dev').where('officialEmail', '==', (empDoc?.email ?? '')).limit(5).get()).docs.map(d=>d.data());
      diagnostics.by_emailLower = (await db.collection('employee_onboarding_dev').where('officialEmail', '==', (empDoc?.emailLower ?? '')).limit(5).get()).docs.map(d=>d.data());

      const out = { ...result, diagnostics };
      const outPath = path.join(__dirname, 'latest_payroll_salary_test_mr014.json');
      fs.writeFileSync(outPath, JSON.stringify(out, null, 2));
      console.log('Onboarding record not found. Wrote diagnostic file to', outPath);
      return;
    }

    // Run payroll for June 2026
    const payroll = await calculateEmployeePayroll({ companyId, empid, year: 2026, month: 6 });

    // Validate checks
    const checks = {};

    checks.basicSalary = Number(onboarding.bankDetails?.basicSalary ?? 0);
    checks.hra = Number(onboarding.bankDetails?.hra ?? 0);
    checks.allowances = Number(onboarding.bankDetails?.allowances ?? 0);
    checks.eligibleDays = payroll.eligibleDays;
    checks.payableDays = payroll.payableDays;
    checks.perDaySalary = payroll.perDaySalary;
    checks.earnedBasic = payroll.earnedBasic;
    checks.earnedAllowance = payroll.earnedAllowance;
    checks.grossSalary = payroll.grossSalary;
    checks.totalDeductions = payroll.totalDeductions;
    checks.netSalary = payroll.netSalary;

    // Sunday checks
    const sundays = payroll.dailyBreakdown.filter(d => {
      const dt = d.date.split('-').map(Number);
      const wd = new Date(Date.UTC(dt[0], dt[1]-1, dt[2])).getUTCDay();
      return wd === 0;
    });

    checks.sundays = sundays.map(d => ({ date: d.date, status: d.resolvedStatus, attendanceStatus: d.attendanceStatus, lopValue: d.lopValue, absentValue: d.absentValue }));

    // week-off not included in absent/LOP
    const weekOffProblems = payroll.dailyBreakdown.filter(d => d.resolvedStatus === 'week-off' && (d.absentValue > 0 || d.lopValue > 0));
    checks.weekOffProblems = weekOffProblems;

    // Salary double deduction check: lopDeduction should be 0 and earnedBasic equals perDay*payableDays
    checks.lopDeduction = payroll.lopDeduction;
    checks.earnedBasicDoubleCheck = Math.abs((payroll.perDaySalary * payroll.payableDays) - payroll.earnedBasic) < 0.0001;

    const out = { payroll, checks };

    const outPath = path.join(__dirname, 'latest_payroll_salary_test_mr014.json');
    fs.writeFileSync(outPath, JSON.stringify(out, null, 2));

    console.log('Payroll test complete. Wrote output to', outPath);
  } catch (err) {
    console.error('Error running MR014 payroll test:', err);
    const outPath = path.join(__dirname, 'latest_payroll_salary_test_mr014.json');
    fs.writeFileSync(outPath, JSON.stringify({ error: String(err) }, null, 2));
  }
}

run();
