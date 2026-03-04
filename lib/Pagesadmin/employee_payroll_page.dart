



// import 'package:flutter/material.dart';
// import '../models/employee_payroll_model.dart';
// import '../widgets/employee_payroll_card.dart';

// class EmployeePayrollPage extends StatefulWidget {
//   const EmployeePayrollPage({super.key});

//   @override
//   State<EmployeePayrollPage> createState() => _EmployeePayrollPageState();
// }

// class _EmployeePayrollPageState extends State<EmployeePayrollPage> {
//   late EmployeePayrollModel emp;

//   @override
//   void initState() {
//     super.initState();
//     emp = EmployeePayrollModel(
//       employeeId: "EMP001",
//       employeeName: "Sujitha",
//       department: "IT",
//       designation: "Developer",
//       month: 2,
//       year: 2026,
//       baseSalary: 25000,
//       totalDays: 28,
//       workedDays: 26,
//       lopDays: 2,
//     );
//   }

//   // ================= EDIT POPUP =================
//   void _editPayroll(EmployeePayrollModel emp) {
//     final workedCtrl =
//         TextEditingController(text: emp.workedDays.toString());
//     final lopCtrl = TextEditingController(text: emp.lopDays.toString());
//     final bonusCtrl = TextEditingController(text: emp.bonus.toString());
//     final otCtrl = TextEditingController(text: emp.overtime.toString());

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Edit Payroll"),
//         content: SingleChildScrollView(
//           child: Column(
//             children: [
//               _field("Worked Days", workedCtrl),
//               _field("LOP Days", lopCtrl),
//               _field("Bonus", bonusCtrl),
//               _field("Overtime", otCtrl),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel")),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 emp.workedDays = int.parse(workedCtrl.text);
//                 emp.lopDays = int.parse(lopCtrl.text);
//                 emp.bonus = double.parse(bonusCtrl.text);
//                 emp.overtime = double.parse(otCtrl.text);
//               });
//               Navigator.pop(context);
//             },
//             child: const Text("Save"),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _field(String label, TextEditingController ctrl) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         controller: ctrl,
//         keyboardType: TextInputType.number,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }

//   // ================= VIEW =================
//   void _viewPayroll(EmployeePayrollModel emp) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Payroll Full Details"),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("Employee: ${emp.employeeName}"),
//               Text("ID: ${emp.employeeId}"),
//               Text("Department: ${emp.department}"),
//               Text("Designation: ${emp.designation}"),
//               const Divider(),
//               Text("Month: ${emp.month} / ${emp.year}"),
//               Text("Base Salary: ₹${emp.baseSalary}"),
//               Text("Total Days: ${emp.totalDays}"),
//               Text("Worked Days: ${emp.workedDays}"),
//               Text("LOP Days: ${emp.lopDays}"),
//               Text("Per Day Salary: ₹${emp.perDaySalary.toStringAsFixed(0)}"),
//               Text("Bonus: ₹${emp.bonus}"),
//               Text("Overtime: ₹${emp.overtime}"),
//               const Divider(),
//               Text("Net Salary: ₹${emp.netSalary.toStringAsFixed(0)}"),
//               Text("Paid Date: ${emp.formattedPaidDate}"),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Close"))
//         ],
//       ),
//     );
//   }

//   void _confirmPaid(EmployeePayrollModel emp) {
//     setState(() {
//       emp.isPaid = true;
//       emp.paidDate = DateTime.now();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Employee Payroll")),
//       body: EmployeePayrollCard(
//         emp: emp,
//         onView: () => _viewPayroll(emp),
//         onEdit: () => _editPayroll(emp),
//         onConfirmPaid: () => _confirmPaid(emp),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../models/employee_payroll_model.dart';
import '../widgets/employee_payroll_card.dart';

class EmployeePayrollPage extends StatefulWidget {
  const EmployeePayrollPage({super.key});

  @override
  State<EmployeePayrollPage> createState() => _EmployeePayrollPageState();
}

class _EmployeePayrollPageState extends State<EmployeePayrollPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<EmployeePayrollModel> allEmployees = [];
  List<EmployeePayrollModel> filteredEmployees = [];

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    allEmployees = [
      EmployeePayrollModel(
        employeeId: "EMP001",
        employeeName: "Sujitha",
        department: "IT",
        designation: "Developer",
        month: 2,
        year: 2026,
        baseSalary: 25000,
        totalDays: 28,
        workedDays: 26,
        lopDays: 2,
      ),
      EmployeePayrollModel(
        employeeId: "EMP002",
        employeeName: "Rahul",
        department: "HR",
        designation: "Manager",
        month: 2,
        year: 2026,
        baseSalary: 30000,
        totalDays: 28,
        workedDays: 28,
        lopDays: 0,
      ),
    ];

    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();

    setState(() {
      filteredEmployees = allEmployees.where((emp) {
        final matchesSearch =
            emp.employeeName.toLowerCase().contains(query) ||
                emp.designation.toLowerCase().contains(query);

        final matchesDate =
            emp.month == selectedMonth && emp.year == selectedYear;

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  void _pickMonthYear() async {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    int tempMonth = selectedMonth;
    int tempYear = selectedYear;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Month & Year"),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Year Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              tempYear--;
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          tempYear.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              tempYear++;
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Month Selection
                    SizedBox(
                      height: 200,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = month == tempMonth;
                          return ElevatedButton(
                            onPressed: () {
                              setState(() {
                                tempMonth = month;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey[200],
                              foregroundColor: isSelected 
                                  ? Colors.white 
                                  : Colors.black,
                            ),
                            child: Text(
                              months[index].substring(0, 3),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedMonth = tempMonth;
                      selectedYear = tempYear;
                    });
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= VIEW =================
  void _viewPayroll(EmployeePayrollModel emp) {
    showDialog(
      context: context,
      builder: (_) => SizedBox(
        width: 360,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE6E0F0), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          title: const Center(
            child: Text(
              "Payroll Full Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  
                  // Section A: Employee Info
                  _buildInfoRow("Employee", emp.employeeName),
                  _buildInfoRow("ID", emp.employeeId),
                  _buildInfoRow("Department", emp.department),
                  _buildInfoRow("Designation", emp.designation),
                  
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE6E0F0)),
                  const SizedBox(height: 12),
                  
                  // Section B: Payroll Info
                  _buildInfoRow("Month/Year", "${emp.month}/${emp.year}"),
                  _buildInfoRow("Base Salary", "₹${emp.baseSalary.toStringAsFixed(0)}"),
                  _buildInfoRow("PF", "₹${emp.pf.toStringAsFixed(0)}"),
                  _buildInfoRow("ESI", "₹${emp.esi.toStringAsFixed(0)}"),
                  _buildInfoRow("Tax", "₹${emp.tax.toStringAsFixed(0)}"),
                  _buildInfoRow("HRA", "₹${emp.hra.toStringAsFixed(0)}"),
                  _buildInfoRow("Allowances", "₹${emp.allowances.toStringAsFixed(0)}"),
                  _buildInfoRow("Gross Salary", "₹${emp.grossSalary.toStringAsFixed(0)}"),
                  _buildInfoRow("Total Days", emp.totalDays.toString()),
                  _buildInfoRow("Worked Days", emp.workedDays.toString()),
                  _buildInfoRow("LOP Days", emp.lopDays.toString()),
                  _buildInfoRow("Per Day Salary", "₹${emp.perDaySalary.toStringAsFixed(0)}"),
                  _buildInfoRow("Bonus", "₹${emp.bonus.toStringAsFixed(0)}"),
                  _buildInfoRow("Overtime", "₹${emp.overtime.toStringAsFixed(0)}"),
                  
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE6E0F0)),
                  const SizedBox(height: 12),
                  
                  // Section C: Summary
                  _buildInfoRow(
                    "Net Salary", 
                    "₹${emp.netSalary.toStringAsFixed(0)}",
                    isHighlighted: true,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          "Status",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: emp.isPaid ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          emp.isPaid ? 'PAID' : 'UNPAID',
                          style: TextStyle(
                            color: emp.isPaid ? Colors.green[700] : Colors.orange[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow("Paid Date", emp.formattedPaidDate),
                ],
              ),
            ),
          ),
          actions: [
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
                fontSize: fontSize ?? (isHighlighted ? 18 : 14),
                color: isHighlighted ? Colors.black87 : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPaid(EmployeePayrollModel emp) {
    setState(() {
      emp.isPaid = true;
      emp.paidDate = DateTime.now();
    });
  }

  void _editPayroll(EmployeePayrollModel emp) {
    final workedCtrl = TextEditingController(text: emp.workedDays.toString());
    final lopCtrl = TextEditingController(text: emp.lopDays.toString());
    final bonusCtrl = TextEditingController(text: emp.bonus.toString());
    final otCtrl = TextEditingController(text: emp.overtime.toString());
    final pfCtrl = TextEditingController(text: (emp.baseSalary * 0.12).toStringAsFixed(0));
    final esiCtrl = TextEditingController(text: (emp.baseSalary * 0.0175).toStringAsFixed(0));
    final taxCtrl = TextEditingController(text: (emp.baseSalary * 0.10).toStringAsFixed(0));
    final hraCtrl = TextEditingController(text: (emp.baseSalary * 0.40).toStringAsFixed(0));
    final allowancesCtrl = TextEditingController(text: (emp.baseSalary * 0.15).toStringAsFixed(0));
    final grossCtrl = TextEditingController(text: (emp.baseSalary * 1.15).toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Payroll"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("Worked Days", workedCtrl),
              _field("LOP Days", lopCtrl),
              _field("PF", pfCtrl),
              _field("ESI", esiCtrl),
              _field("Tax", taxCtrl),
              _field("HRA", hraCtrl),
              _field("Allowances", allowancesCtrl),
              _field("Gross Salary", grossCtrl),
              _field("Bonus", bonusCtrl),
              _field("Overtime", otCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                emp.workedDays = int.parse(workedCtrl.text);
                emp.lopDays = int.parse(lopCtrl.text);
                emp.bonus = double.parse(bonusCtrl.text);
                emp.overtime = double.parse(otCtrl.text);
                emp.pf = double.parse(pfCtrl.text);
                emp.esi = double.parse(esiCtrl.text);
                emp.tax = double.parse(taxCtrl.text);
                emp.hra = double.parse(hraCtrl.text);
                emp.allowances = double.parse(allowancesCtrl.text);
                emp.grossSalary = double.parse(grossCtrl.text);
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Column(
        children: [

          // ================= SEARCH + MONTH =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [

                // Search Field
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _applyFilters(),
                    decoration: const InputDecoration(
                      hintText: "Search by name / role",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Month Picker
                ElevatedButton.icon(
                  onPressed: _pickMonthYear,
                  icon: const Icon(Icons.calendar_month),
                  label: Text("$selectedMonth/$selectedYear"),
                )
              ],
            ),
          ),

          // ================= LIST =================
          Expanded(
            child: filteredEmployees.isEmpty
                ? const Center(child: Text("No payroll records found"))
                : ListView.builder(
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final emp = filteredEmployees[index];
                return EmployeePayrollCard(
                  emp: emp,
                  onView: () => _viewPayroll(emp),
                  onEdit: emp.isPaid ? null : () => _editPayroll(emp),
                  onConfirmPaid: emp.isPaid ? null : () => _confirmPaid(emp),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}