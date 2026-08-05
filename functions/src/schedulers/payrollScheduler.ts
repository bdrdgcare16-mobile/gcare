import {
  onSchedule,
} from 'firebase-functions/v2/scheduler';

import {
  generateAllEmployeePayroll,
} from '../services/payrollService';

import {
  getPreviousPayrollMonth,
} from '../utils/payroll';

export const monthlyPayrollScheduler =
  onSchedule(
    {
      schedule: '0 1 1 * *',
      timeZone: 'Asia/Kolkata',
      region: 'us-central1',
      retryCount: 3,
    },
    async () => {
      const period =
        getPreviousPayrollMonth();

      const result =
        await generateAllEmployeePayroll({
          year:
            period.year,

          month:
            period.month,
        });

      console.log(
        'Monthly payroll generation completed',
        {
          period,

          generated:
            result.generated.length,

          failed:
            result.failed,
        },
      );
    },
  );