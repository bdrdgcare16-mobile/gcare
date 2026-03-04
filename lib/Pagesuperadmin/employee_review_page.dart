

import 'package:flutter/material.dart';

import 'employee_onboarding_models.dart';
import 'superadmin_dashboard.dart'; // Uses your existing EmployeeRequestVm + RequestStatus

class EmployeeReviewPage extends StatefulWidget {
  final EmployeeRequestVm req;

  const EmployeeReviewPage({super.key, required this.req});

  @override
  State<EmployeeReviewPage> createState() => _EmployeeReviewPageState();
}

class _EmployeeReviewPageState extends State<EmployeeReviewPage> {
  static const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
  static const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
  static const Color kAppBarColor = Color(0xFF8C6EAF);
  static const Color kButtonColor = Color(0xFF655193);
  static const Color kTextColor = Colors.white;
  static const Color kCardBorder = Color(0xFFE3E7EE);
  static const Color kPendingBg = Color(0xFFF2D58A);

  bool _busy = false;

  EmployeeRequestVm get _req => widget.req;

  @override
  Widget build(BuildContext context) {
    final m = _req.details;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _req),
        ),
        title: const Text(
          "Super Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        // ✅ Notification icon REMOVED (as you requested)
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () => _openProfileSheet(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
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
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _breadcrumb(),
                    const SizedBox(height: 10),

                    _employeeHeaderCard(m),
                    const SizedBox(height: 12),

                    _sectionCard(
                      title: "Basic Details",
                      child: _kvTable([
                        ("Full Name", m.fullName),
                        ("Gender", m.gender),
                        ("Date of Birth", _fmtDate(m.dob)),
                        ("Blood Group", m.bloodGroup),
                        ("Marital Status", m.maritalStatus),
                        ("Address",
                            "${m.permanentAddress},\n${m.city}, ${m.state}"),
                        ("Pincode", m.pincode),
                        ("Personal Email", m.personalEmail),
                        ("Phone No", "${m.mobileCountryCode} ${m.mobileNumber}"),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    LayoutBuilder(
                      builder: (context, c) {
                        final isNarrow = c.maxWidth < 420;
                        final left = _sectionCard(
                          title: "Company Details",
                          child: _kvTable([
                            ("Company", m.companyName),
                            ("Branch", m.branchLocation),
                            ("Department", m.department),
                            ("Designation", m.designation),
                            ("Work Mode", m.workMode),
                            ("Shift Timing", m.shiftTiming),
                            ("Emp ID", m.employeeId),
                            ("DOJ", _fmtDate(m.doj)),
                          ]),
                        );

                        final right = _sectionCard(
                          title: "Salary / Bank Details",
                          child: _kvTable([
                            ("Bank", m.bankName),
                            ("Account No", _maskAccount(m.accountNumber)),
                            ("Branch", m.bankBranch),
                            ("IFSC Code", m.ifscCode),
                            ("UPI ID", m.upiId),
                            ("PAN No", m.panNumber),
                            ("Gross Salary", "₹${m.grossSalary}"),
                          ]),
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              left,
                              const SizedBox(height: 12),
                              right,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 12),
                            Expanded(child: right),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _sectionCard(
                      title: "Documents",
                      child: _documentsList(m.documents),
                    ),
                  ],
                ),
              ),

              if (_busy)
                Container(
                  color: Colors.black.withOpacity(0.06),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI Parts ----------------

  Widget _breadcrumb() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kCardBorder),
      ),
      child: const Text(
        "Dashboard / Employee Review",
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _employeeHeaderCard(EmployeeOnboardFormResult m) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(m.fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text("Emp ID: ${m.employeeId}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _statusChip(_req.status),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  text: "APPROVE",
                  onTap: _req.status == RequestStatus.pending
                      ? () => _applyDecision(RequestStatus.approved)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  text: "REJECT",
                  onTap: _req.status == RequestStatus.pending
                      ? () => _applyDecision(RequestStatus.rejected)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _kvTable(List<(String, String)> rows) {
    return Column(
      children: rows.map((r) {
        final key = r.$1;
        final val = r.$2;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  "$key :",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              Expanded(
                child: Text(
                  val,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _documentsList(Map<String, dynamic> docs) {
    if (docs.isEmpty) {
      return const Text(
        "No documents uploaded.",
        style: TextStyle(color: Colors.black54),
      );
    }

    // map key -> label
    final labels = <String, String>{
      "resume": "Resume",
      "offer_letter": "Offer Letter",
      "pan_card": "PAN Card",
      "aadhaar_card": "Aadhaar Card",
      "bank_proof": "Bank Proof",
      "exprience_letter": "Experience Letter",
      "10th_marksheet": "10th Marksheet",
      "12th_marksheet": "12th Marksheet",
      "degree_certificate": "Degree Certificate",
    };

    final items = docs.entries.toList();

    return Column(
      children: items.map((e) {
        final key = e.key;
        final value = e.value;

        final label = labels[key] ?? key;

        String fileName = "";
        String path = "";
        if (value is Map) {
          fileName = (value["fileName"] ?? "").toString();
          path = (value["path"] ?? "").toString();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.description, color: Color(0xFF2D67B2)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              InkWell(
                onTap: () => _showDocDialog(label, fileName, path),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    "[View]",
                    style: TextStyle(
                      color: Color(0xFF2D67B2),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _avatar(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    final initials =
        parts.isEmpty ? "?" : parts.map((e) => e.isNotEmpty ? e[0] : "").take(2).join();

    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFFE9EEF7),
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54),
      ),
    );
  }

  Widget _statusChip(RequestStatus status) {
    String text = status.name.toUpperCase();
    Color bg = kPendingBg;
    Color fg = Colors.brown;

    if (status == RequestStatus.approved) {
      bg = const Color(0xFFCEF2D6);
      fg = const Color(0xFF1B7A33);
    } else if (status == RequestStatus.rejected) {
      bg = const Color(0xFFF6CDCD);
      fg = const Color(0xFFB11E1E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Status: $text",
        style: TextStyle(fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _actionBtn({
    required String text,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap == null ? kButtonColor.withOpacity(0.45) : kButtonColor,
          foregroundColor: kTextColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Actions ----------------

  Future<void> _applyDecision(RequestStatus decision) async {
    final reason = await _showReasonDialog(
      title: decision == RequestStatus.approved
          ? "Reason for Approval"
          : "Reason for Rejection",
      hint: decision == RequestStatus.approved
          ? "Enter approval reason"
          : "Enter rejection reason",
    );
    if (reason == null) return;

    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 200));

    final updated = _req.copyWith(
      status: decision,
      decisionReason: reason,
      decidedAt: DateTime.now(),
    );

    setState(() => _busy = false);

    await _showSuccessDialog(
      decision: decision,
      message: decision == RequestStatus.approved
          ? "Request Approved!"
          : "Request Rejected!",
    );

    Navigator.pop(context, updated);
  }

  Future<String?> _showReasonDialog({
    required String title,
    required String hint,
  }) async {
    final ctrl = TextEditingController();

    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, text);
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
      ),
    );
  }

  Future<void> _showSuccessDialog({
    required RequestStatus decision,
    required String message,
  }) async {
    final bool approved = decision == RequestStatus.approved;

    final String assetPath = approved
        ? "assets/super_admin/approved.png"
        : "assets/super_admin/rejected.png";

    final iconFallback = approved ? Icons.check_circle : Icons.cancel;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 90,
                child: _SafeAsset(
                  path: assetPath,
                  fallback: Icon(
                    iconFallback,
                    size: 72,
                    color: approved ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "The employee request has been ${approved ? "approved" : "rejected"} successfully.",
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    foregroundColor: kTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocDialog(String label, String fileName, String path) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: Text(
          "File: ${fileName.isEmpty ? "-" : fileName}\nPath: ${path.isEmpty ? "-" : path}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _openProfileSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Change Password"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------- Helpers ----------------

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return "$dd-$mm-$yyyy";
  }

  String _maskAccount(String acc) {
    final s = acc.trim();
    if (s.length <= 4) return s;
    final last4 = s.substring(s.length - 4);
    return "**** $last4";
  }
}

class _SafeAsset extends StatelessWidget {
  final String path;
  final Widget fallback;

  const _SafeAsset({required this.path, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Center(child: fallback),
    );
  }
}
