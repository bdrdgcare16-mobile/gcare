const fs = require('fs');
const path = require('path');

const firebase = require('./lib/config/firebase');
const db = firebase.db;

const { calculateEmployeePayroll } = require('./lib/services/payrollService');

async function findOnboardingMatch(empid, empEmail) {
  const queries = [
    { field: 'empid', q: db.collection('employee_onboarding_dev').where('empid', '==', empid).limit(1).get() },
    { field: 'employeeId', q: db.collection('employee_onboarding_dev').where('employeeId', '==', empid).limit(1).get() },
    { field: 'uid', q: db.collection('employee_onboarding_dev').where('uid', '==', empid).limit(1).get() },
    { field: 'officialEmail', q: db.collection('employee_onboarding_dev').where('officialEmail', '==', empid).limit(1).get() },
    { field: 'companyDetails.employeeId', q: db.collection('employee_onboarding_dev').where('companyDetails.employeeId', '==', empid).limit(1).get() },
    { field: 'companyDetails.officialEmail', q: db.collection('employee_onboarding_dev').where('companyDetails.officialEmail', '==', empid).limit(1).get() },
    { field: 'companyDetails.officialEmail_byEmail', q: db.collection('employee_onboarding_dev').where('companyDetails.officialEmail', '==', empEmail || '').limit(1).get() },
  ];

  for (const item of queries) {
    try {
      const snap = await item.q;
      if (!snap.empty) {
        return { field: item.field, doc: snap.docs[0].data() };
      }
    } catch (e) {
      // ignore
    }
  }

  return null;
}

function isSundayYMD(ymd) {
  const [y, m, d] = ymd.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay() === 0;
}

async function run() {
  const outPath = path.join(__dirname, 'latest_full_payroll_salary_validation.json');
  const employeesSnap = await db.collection('employees').get();

  const employees = employeesSnap.docs
    .map(d => ({ id: d.id, ...(d.data() || {}) }))
    .filter(e => String(e.status || '').toLowerCase() === 'active' && e.empid && e.companyId);

  const results = [];

  for (const emp of employees) {
    const rec = {
      empid: emp.empid,
      employeeName: emp.employeeName || emp.name || null,
      onboardingFound: false,
      onboardingLookupField: null,
      basicSalary: null,
      eligibleDays: null,
      payableDays: null,
      earnedBasic: null,
      earnedAllowance: null,
      grossSalary: null,
      totalDeductions: null,
      netSalary: null,
      error: null,
      checks: [],
    };

    try {
      const onboardingMatch = await findOnboardingMatch(emp.empid, emp.email || emp.emailLower);
      if (onboardingMatch) {
        rec.onboardingFound = true;
        rec.onboardingLookupField = onboardingMatch.field;
        rec.basicSalary = Number(onboardingMatch.doc.bankDetails?.basicSalary ?? 0);
      }

      let payroll = null;
      try {
        payroll = await calculateEmployeePayroll({ companyId: emp.companyId, empid: emp.empid, year: 2026, month: 6 });
      } catch (err) {
        rec.error = String(err.message || err);
        // write partial rec
        results.push(rec);
        continue;
      }

      rec.eligibleDays = payroll.eligibleDays;
      rec.payableDays = payroll.payableDays;
      rec.earnedBasic = payroll.earnedBasic;
      rec.earnedAllowance = payroll.earnedAllowance;
      rec.grossSalary = payroll.grossSalary;
      rec.totalDeductions = payroll.totalDeductions;
      rec.netSalary = payroll.netSalary;

      // validations
      const failures = [];

      if (!(payroll.basicSalary > 0)) failures.push('basicSalary<=0');
      if (!(payroll.grossSalary > 0)) failures.push('grossSalary<=0');
      if (typeof payroll.netSalary === 'number' && payroll.netSalary < 0) failures.push('netSalaryNegative');
      if (payroll.payableDays > payroll.eligibleDays) failures.push('payableExceedsEligible');

      // Sunday checks
      const sundays = payroll.dailyBreakdown.filter(d => isSundayYMD(d.date));
      for (const s of sundays) {
        if (s.resolvedStatus === 'present') {
          // good: present
        } else if (s.resolvedStatus === 'week-off') {
          if (s.absentValue > 0 || s.lopValue > 0) failures.push(`weekOffHasAbsentOrLOP:${s.date}`);
        } else {
          failures.push(`sundayUnexpectedStatus:${s.date}:${s.resolvedStatus}`);
        }
      }

      // Week-off not counted as absent/LOP and no duplicate present/week-off
      const weekOffProblems = payroll.dailyBreakdown.filter(d => d.resolvedStatus === 'week-off' && (d.absentValue > 0 || d.lopValue > 0));
      if (weekOffProblems.length) failures.push('weekOffCountedAsAbsentOrLOP');

      // no duplicate present and week-off counting: ensured by single resolvedStatus per day

      // lop double deduction: lopDeduction should be 0 (our implementation) and lopDays equals payroll.lopDays
      if (typeof payroll.lopDeduction === 'number' && payroll.lopDeduction !== 0) failures.push('lopDeductionNonZero');

      rec.checks = failures;
      if (failures.length) rec.error = 'validation_failed';

    } catch (err) {
      rec.error = String(err.message || err);
    }

    results.push(rec);
  }

  const summary = {
    totalTested: results.length,
    passed: results.filter(r => !r.error).length,
    failed: results.filter(r => r.error).length,
    missingSalaryConfig: results.filter(r => r.error && String(r.error).toLowerCase().includes('basic salary missing')).map(r=>r.empid),
    salaryMismatches: results.filter(r => r.checks && r.checks.length > 0).map(r=>({ empid: r.empid, checks: r.checks })),
  };

  fs.writeFileSync(outPath, JSON.stringify({ summary, results }, null, 2));
  console.log('Wrote full payroll salary validation to', outPath);
}

run().catch(e => { console.error(e); process.exit(1); });
