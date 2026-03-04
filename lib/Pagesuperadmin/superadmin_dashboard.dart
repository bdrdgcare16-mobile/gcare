import 'package:flutter/material.dart';

import 'employee_onboarding_models.dart';
import 'employee_requests_page.dart';
import 'superadmin_employee_management_page.dart';
import '../Pagesusers/log_out_page.dart';


/// Super Admin Dashboard (Home)
/// - Dashboard cards open bottom sheet preview first
/// - Drawer has: Dashboard, Employee Requests, Employee Management, Change Password, Logout
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  static const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
  static const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
  static const Color kAppBarColor = Color(0xFF8C6EAF);
  static const Color kButtonColor = Color(0xFF655193);
  static const Color kTextColor = Colors.white;
  static const Color kCardBorder = Color(0xFFE3E7EE);

  final List<EmployeeRequestVm> _all = [];

  @override
  void initState() {
    super.initState();
    _seedMock();
  }

  void _seedMock() {
    _all.clear();

    // Pending
    _all.add(
      EmployeeRequestVm(
        id: "REQ001",
        status: RequestStatus.pending,
        requestedDate: DateTime(2026, 2, 12),
        decisionReason: null,
        decidedAt: null,
        details: EmployeeOnboardFormResult(
          fullName: "John Smith",
          gender: "Male",
          dob: DateTime(1999, 1, 1),
          bloodGroup: "O+",
          maritalStatus: "Single",
          personalEmail: "john.personal@mail.com",
          mobileCountryCode: "+91",
          mobileNumber: "9000000000",
          permanentAddress: "Address line 1, Area",
          city: "Chennai",
          state: "Tamil Nadu",
          pincode: "600001",
          companyName: "Your Company",
          branchLocation: "Main Branch",
          employeeId: "EMP001",
          doj: DateTime(2026, 2, 12),
          department: "Engineering",
          designation: "Developer",
          workMode: "Office",
          shiftTiming: "09:00 AM - 06:00 PM",
          workDays: const ["Mon", "Tue", "Wed", "Thu", "Fri"],
          officialEmail: "john.smith@company.com",
          bankName: "ABC Bank",
          accountHolderName: "John Smith",
          accountNumber: "1234567890",
          ifscCode: "ABCD0001234",
          bankBranch: "Chennai",
          upiId: "emp001@upi",
          panNumber: "ABCDE1234F",
          aadhaarNumber: "123412341234",
          basicPay: 20000,
          hra: 8000,
          bonus: 2000,
          allowancesTotal: 1500,
          deductionsAmount: 1000,
          professionalTax: 200,
          pfNumber: "PF12345",
          esiNumber: "ESI12345",
          grossSalary: 31500,
          netSalary: 30300,
          documents: {
            "resume": {"fileName": "Resume.pdf", "path": "uploads/resume.pdf"},
            "panCard": {"fileName": "PAN.pdf", "path": "uploads/pan.pdf"},
            "10thMarkSheet": {"fileName": "10thMarkSheet.pdf", "path": "uploads/10thMarkSheet.pdf"},
            "12thMarkSheet": {"fileName": "12thMarkSheet.pdf", "path": "uploads/12thMarkSheet.pdf"},
            "graduationCertificate": {"fileName": "GraduationCertificate.pdf", "path": "uploads/graduationCertificate.pdf"},
            "experienceLetter": {"fileName": "ExperienceLetter.pdf", "path": "uploads/experienceLetter.pdf"},
            "offerLetter": {"fileName": "OfferLetter.pdf", "path": "uploads/offerLetter.pdf"},
            "AadharCard": {"fileName": "AadharCard.pdf", "path": "uploads/aadharCard.pdf"},
            "provisionalCertificate": {"fileName": "ProvisionalCertificate.pdf", "path": "uploads/provisionalCertificate.pdf"},
            
          },
        ),
      ),
    );

    // Approved
    _all.add(
      EmployeeRequestVm(
        id: "REQ002",
        status: RequestStatus.approved,
        requestedDate: DateTime(2026, 2, 10),
        decisionReason: "Verified documents",
        decidedAt: DateTime(2026, 2, 11),
        details: EmployeeOnboardFormResult(
          fullName: "Alice Johnson",
          gender: "Female",
          dob: DateTime(1998, 5, 20),
          bloodGroup: "B+",
          maritalStatus: "Single",
          personalEmail: "alice.personal@mail.com",
          mobileCountryCode: "+91",
          mobileNumber: "9111111111",
          permanentAddress: "45, Lake Road",
          city: "Chennai",
          state: "Tamil Nadu",
          pincode: "600010",
          companyName: "Your Company",
          branchLocation: "Main Branch",
          employeeId: "EMP101",
          doj: DateTime(2026, 1, 15),
          department: "Engineering",
          designation: "Software Engineer",
          workMode: "Office",
          shiftTiming: "09:00 AM - 06:00 PM",
          workDays: const ["Mon", "Tue", "Wed", "Thu", "Fri"],
          officialEmail: "alice.johnson@company.com",
          bankName: "ABC Bank",
          accountHolderName: "Alice Johnson",
          accountNumber: "222233334444",
          ifscCode: "ABCD0009999",
          bankBranch: "Chennai",
          upiId: "emp101@upi",
          panNumber: "PQRSX1234Z",
          aadhaarNumber: "111122223333",
          basicPay: 22000,
          hra: 7000,
          bonus: 1000,
          allowancesTotal: 2500,
          deductionsAmount: 1800,
          professionalTax: 200,
          pfNumber: "PF222222",
          esiNumber: "ESI222222",
          grossSalary: 35000,
          netSalary: 33000,
          documents: {
            "resume": {"fileName": "Resume.pdf", "path": "uploads/resume.pdf"},
            "offerLetter": {"fileName": "Offer.pdf", "path": "uploads/offer.pdf"},
            "panCard": {"fileName": "PanCard.pdf", "path": "uploads/pancard.pdf"},
            "aadhaarCard": {"fileName": "AadhaarCard.pdf", "path": "uploads/aadhaarcard.pdf"},
            "bankProof": {"fileName": "BankProof.pdf", "path": "uploads/bankproof.pdf"},
            "experienceLetter": {"fileName": "ExperienceLetter.pdf", "path": "uploads/experienceletter.pdf"},
            "10thMarkSheet": {"fileName": "10thMarkSheet.pdf", "path": "uploads/10thmarksheet.pdf"},
            "12thMarkSheet": {"fileName": "12thMarkSheet.pdf", "path": "uploads/12thmarksheet.pdf"},
            "degreeCertificate": {"fileName": "DegreeCertificate.pdf", "path": "uploads/degreecertificate.pdf"},
          },
        ),
      ),
    );

    // Rejected
    _all.add(
      EmployeeRequestVm(
        id: "REQ003",
        status: RequestStatus.rejected,
        requestedDate: DateTime(2026, 2, 9),
        decisionReason: "Documents missing",
        decidedAt: DateTime(2026, 2, 10),
        details: EmployeeOnboardFormResult(
          fullName: "Karthik R",
          gender: "Male",
          dob: DateTime(1997, 7, 7),
          bloodGroup: "A+",
          maritalStatus: "Single",
          personalEmail: "karthik.personal@mail.com",
          mobileCountryCode: "+91",
          mobileNumber: "9222222222",
          permanentAddress: "No.12, Main Street",
          city: "Chennai",
          state: "Tamil Nadu",
          pincode: "600020",
          companyName: "Your Company",
          branchLocation: "Main Branch",
          employeeId: "EMP055",
          doj: DateTime(2026, 1, 20),
          department: "HR",
          designation: "HR Executive",
          workMode: "Office",
          shiftTiming: "09:00 AM - 06:00 PM",
          workDays: const ["Mon", "Tue", "Wed", "Thu", "Fri"],
          officialEmail: "karthik.r@company.com",
          bankName: "SBI",
          accountHolderName: "Karthik R",
          accountNumber: "999988887777",
          ifscCode: "SBIN0000123",
          bankBranch: "Guindy",
          upiId: "emp055@upi",
          panNumber: "AAAAA1111A",
          aadhaarNumber: "444455556666",
          basicPay: 21000,
          hra: 6500,
          bonus: 900,
          allowancesTotal: 1800,
          deductionsAmount: 1500,
          professionalTax: 200,
          pfNumber: "PF555555",
          esiNumber: "ESI555555",
          grossSalary: 32000,
          netSalary: 30300,
          documents: {},
        ),
      ),
    );

    setState(() {});
  }

  int get _totalRequests => _all.length;
  int get _pendingCount => _all.where((e) => e.status == RequestStatus.pending).length;
  int get _approvedCount => _all.where((e) => e.status == RequestStatus.approved).length;
  int get _rejectedCount => _all.where((e) => e.status == RequestStatus.rejected).length;

  int get _totalEmployees => _approvedCount;

  List<EmployeeRequestVm> _filter(RequestStatus status) =>
      _all.where((e) => e.status == status).toList();

  void _openPreviewSheet({
    required String title,
    required List<EmployeeRequestVm> list,
    required VoidCallback onViewAll,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.30,
          maxChildSize: 0.85,
          builder: (context, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onViewAll();
                          },
                          child: const Text("View All"),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: Text("No records found", style: TextStyle(color: Colors.black54)),
                          )
                        : ListView.separated(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.all(12),
                            itemCount: list.length.clamp(0, 6),
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _miniTile(list[i]),
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _miniTile(EmployeeRequestVm r) {
    final m = r.details;
    final icon = r.status == RequestStatus.approved
        ? Icons.check_circle
        : r.status == RequestStatus.rejected
            ? Icons.cancel
            : Icons.pending_actions;

    final iconColor = r.status == RequestStatus.approved
        ? Colors.green
        : r.status == RequestStatus.rejected
            ? Colors.red
            : Colors.orange;

    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        final updated = await Navigator.push<EmployeeRequestVm>(
          context,
          MaterialPageRoute(builder: (_) => EmployeeDetailsPage(request: r)),
        );
        if (updated != null) {
          final idx = _all.indexWhere((e) => e.id == updated.id);
          if (idx != -1) setState(() => _all[idx] = updated);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: kCardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text("Emp ID: ${m.employeeId}", style: const TextStyle(color: Colors.black54)),
                  if ((r.decisionReason ?? "").trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text("Reason: ${r.decisionReason}", style: const TextStyle(color: Colors.black54)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  void _goDashboard() {
    Navigator.pop(context);
  }

  void _goEmployeeRequests() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeRequestsPage(
          requests: _all,
          initialFilter: RequestStatus.pending,
          onChanged: (updated) {
            setState(() {
              final idx = _all.indexWhere((e) => e.id == updated.id);
              if (idx != -1) _all[idx] = updated;
            });
          },
        ),
      ),
    );
  }

  void _goEmployeeManagement() {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuperAdminEmployeeManagementPage(
          employees: [],
          approvedEmployees: _filter(RequestStatus.approved),
        ),
      ),
    );
  }

  // ✅ NEW: Change Password dialog
  Future<void> _openChangePasswordDialog() async {
    Navigator.pop(context); // close drawer first

    final formKey = GlobalKey<FormState>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    bool hideOld = true;
    bool hideNew = true;
    bool hideConfirm = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDState) {
            return AlertDialog(
              title: const Text(
                "Change Password",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldCtrl,
                        obscureText: hideOld,
                        decoration: InputDecoration(
                          labelText: "Old Password",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            onPressed: () => setDState(() => hideOld = !hideOld),
                            icon: Icon(hideOld ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Old password is required";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newCtrl,
                        obscureText: hideNew,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            onPressed: () => setDState(() => hideNew = !hideNew),
                            icon: Icon(hideNew ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                        validator: (v) {
                          final val = (v ?? "").trim();
                          if (val.isEmpty) return "New password is required";
                          if (val.length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmCtrl,
                        obscureText: hideConfirm,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            onPressed: () => setDState(() => hideConfirm = !hideConfirm),
                            icon: Icon(hideConfirm ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                        validator: (v) {
                          final val = (v ?? "").trim();
                          if (val.isEmpty) return "Confirm password is required";
                          if (val != newCtrl.text.trim()) return "Passwords do not match";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    // TODO: Connect to backend/API to update password.
                    // For now: simulate success
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password updated successfully")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    foregroundColor: kTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );

    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

Future<void> _logout() async {
  Navigator.pop(context); // close drawer

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        "Logout",
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: const Text("Are you sure you want to logout?"),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kButtonColor,
            foregroundColor: kTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Logout"),
        ),
      ],
    ),
  );

  if (ok == true) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LogOutPage(),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: _drawer(),
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
        elevation: 0,
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryBackgroundTop,
              kPrimaryBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),

                _overviewCard(
              title: "Total Requests",
              value: _totalRequests.toString(),
              icon: Icons.request_page,
              color: Colors.orange,
              onTap: () {
                _openPreviewSheet(
                  title: "Total Requests",
                  list: _all,
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeRequestsPage(
                          requests: _all,
                          initialFilter: null,
                          onChanged: (updated) {
                            setState(() {
                              final idx = _all.indexWhere((e) => e.id == updated.id);
                              if (idx != -1) _all[idx] = updated;
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            _overviewCard(
              title: "Pending Approvals",
              value: _pendingCount.toString(),
              icon: Icons.pending_actions,
              color: Colors.amber,
              onTap: () {
                _openPreviewSheet(
                  title: "Pending Requests",
                  list: _filter(RequestStatus.pending),
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeRequestsPage(
                          requests: _all,
                          initialFilter: RequestStatus.pending,
                          onChanged: (updated) {
                            setState(() {
                              final idx = _all.indexWhere((e) => e.id == updated.id);
                              if (idx != -1) _all[idx] = updated;
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            _overviewCard(
              title: "Approved",
              value: _approvedCount.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              onTap: () {
                _openPreviewSheet(
                  title: "Approved Requests",
                  list: _filter(RequestStatus.approved),
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeRequestsPage(
                          requests: _all,
                          initialFilter: RequestStatus.approved,
                          onChanged: (updated) {
                            setState(() {
                              final idx = _all.indexWhere((e) => e.id == updated.id);
                              if (idx != -1) _all[idx] = updated;
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            _overviewCard(
              title: "Rejected",
              value: _rejectedCount.toString(),
              icon: Icons.cancel,
              color: Colors.red,
              onTap: () {
                _openPreviewSheet(
                  title: "Rejected Requests",
                  list: _filter(RequestStatus.rejected),
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeRequestsPage(
                          requests: _all,
                          initialFilter: RequestStatus.rejected,
                          onChanged: (updated) {
                            setState(() {
                              final idx = _all.indexWhere((e) => e.id == updated.id);
                              if (idx != -1) _all[idx] = updated;
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SuperAdminEmployeeManagementPage(
                      employees: _all,
                      approvedEmployees: _filter(RequestStatus.approved),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kCardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Total Employees",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                    Text(
                      _totalEmployees.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blue),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _overviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Drawer _drawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: kAppBarColor,
              child: const Text(
                "Super Admin",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text("Dashboard"),
                    onTap: _goDashboard,
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: const Text("Employee Requests"),
                    onTap: _goEmployeeRequests,
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_alt_outlined),
                    title: const Text("Employee Management"),
                    onTap: _goEmployeeManagement,
                  ),

                  const Divider(),

                  // ✅ NEW
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text("Change Password"),
                    onTap: _openChangePasswordDialog,
                  ),

                  // ✅ NEW
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Logout"),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Extra space to ensure gradient extends to bottom
          ],
        ),
      ),
    );
  }
}

/// Status enum
enum RequestStatus { pending, approved, rejected }

/// ViewModel wrapper (uses your EmployeeOnboardFormResult exactly)
class EmployeeRequestVm {
  final String id;
  final RequestStatus status;
  final DateTime requestedDate;
  final String? decisionReason;
  final DateTime? decidedAt;
  final EmployeeOnboardFormResult details;

  const EmployeeRequestVm({
    required this.id,
    required this.status,
    required this.requestedDate,
    required this.details,
    this.decisionReason,
    this.decidedAt,
  });

  EmployeeRequestVm copyWith({
    RequestStatus? status,
    String? decisionReason,
    DateTime? decidedAt,
  }) {
    return EmployeeRequestVm(
      id: id,
      status: status ?? this.status,
      requestedDate: requestedDate,
      details: details,
      decisionReason: decisionReason ?? this.decisionReason,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }
}
