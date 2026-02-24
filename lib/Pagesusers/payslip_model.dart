class LeaveEntry {
  final String type; // "Sick Leave", "Casual Leave", "LOP", "Absent"
  final String reason;
  final DateTime fromDate;
  final DateTime toDate;
  final double days;

  LeaveEntry({
    required this.type,
    required this.reason,
    required this.fromDate,
    required this.toDate,
    required this.days,
  });
}

class Payslip {
  final int month;
  final int year;

  final String companyName;
  final String companySubTitle;

  final String employeeName;
  final String designation;
  final String employeeId;
  final String department;
  final DateTime dateOfJoining;

  // Earnings
  final double basic;
  final double hra;
  final double allowance;
  final double bonus;

  // Deductions
  final double deductions;
  final double professionalTax;

  // Attendance / Leave
  final int paidDays;     // ✅ paid days (your requirement)
  final int absentDays;
  final int leaveDays;
  final int lopDays;      // ✅ LOP days (your requirement)

  final List<LeaveEntry> leaveEntries;

  final DateTime generatedOn;

  Payslip({
    required this.month,
    required this.year,
    required this.companyName,
    required this.companySubTitle,
    required this.employeeName,
    required this.designation,
    required this.employeeId,
    required this.department,
    required this.dateOfJoining,
    required this.basic,
    required this.hra,
    required this.allowance,
    required this.bonus,
    required this.deductions,
    required this.professionalTax,
    required this.paidDays,
    required this.absentDays,
    required this.leaveDays,
    required this.lopDays,
    required this.leaveEntries,
    required this.generatedOn,
  });

  String get monthName => PayslipDataSource.monthName(month);

  double get grossEarnings => basic + hra + allowance + bonus;

  double get totalDeductions => deductions + professionalTax;

  double get netPay => grossEarnings - totalDeductions;

  int get totalLeaveTaken => absentDays + leaveDays + lopDays;
}

class PayslipDataSource {
  static List<Payslip> samplePayslips() {
    return [
      Payslip(
        month: 1,
        year: 2026,
        companyName: "MR TECH",
        companySubTitle: "Myth Reality Technologies Pvt. Ltd",
        employeeName: "gffg",
        designation: "Software Engineer",
        employeeId: "GC8304",
        department: "Development",
        dateOfJoining: DateTime(2026, 1, 5),

        basic: 123455,
        hra: 0,
        allowance: 0,
        bonus: 0,

        deductions: 0,
        professionalTax: 0,

        paidDays: 21,
        absentDays: 2,
        leaveDays: 1,
        lopDays: 0,

        leaveEntries: [
          LeaveEntry(
            type: "Casual Leave",
            reason: "Family function",
            fromDate: DateTime(2026, 1, 12),
            toDate: DateTime(2026, 1, 12),
            days: 1,
          ),
          LeaveEntry(
            type: "Absent",
            reason: "No check-in",
            fromDate: DateTime(2026, 1, 20),
            toDate: DateTime(2026, 1, 21),
            days: 2,
          ),
        ],

        generatedOn: DateTime(2026, 1, 31),
      ),
    ];
  }

  static List<int> months() => List.generate(12, (i) => i + 1);

  static String monthName(int m) {
    const names = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return names[m - 1];
  }

  static List<int> yearsRange({required int start, required int end}) {
    final years = <int>[];
    for (int y = start; y <= end; y++) years.add(y);
    return years;
  }
}
