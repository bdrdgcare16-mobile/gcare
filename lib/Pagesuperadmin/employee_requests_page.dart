import 'package:flutter/material.dart';

import 'superadmin_dashboard.dart'; // for RequestStatus + EmployeeRequestVm
import 'employee_onboarding_models.dart';

/// Employee Requests Page
/// - Can show all / pending / approved / rejected
/// - Search + Date filter (date picker near search bar)
class EmployeeRequestsPage extends StatefulWidget {
  final List<EmployeeRequestVm> requests;
  final RequestStatus? initialFilter; // null = all
  final ValueChanged<EmployeeRequestVm> onChanged;

  const EmployeeRequestsPage({
    super.key,
    required this.requests,
    required this.onChanged,
    this.initialFilter,
  });

  @override
  State<EmployeeRequestsPage> createState() => _EmployeeRequestsPageState();
}

class _EmployeeRequestsPageState extends State<EmployeeRequestsPage> {
  static const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
  static const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
  static const Color kAppBarColor = Color(0xFF8C6EAF);
  static const Color kButtonColor = Color(0xFF655193);
  static const Color kTextColor = Colors.white;
  static const Color kCardBorder = Color(0xFFE3E7EE);

  final TextEditingController _searchCtrl = TextEditingController();
  List<EmployeeRequestVm> _filtered = [];

  DateTime? _selectedDate; // date filter

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_apply);
    _apply();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final q = _searchCtrl.text.trim().toLowerCase();

    // 1) status filter
    final base = widget.initialFilter == null
        ? widget.requests
        : widget.requests.where((e) => e.status == widget.initialFilter).toList();

    // 2) date filter
    final dateFiltered = _selectedDate == null
        ? base
        : base.where((e) {
            // date filter
            final DateTime? reqDate = e.requestedDate; // adjust if needed
            if (reqDate == null) return false;
            return _isSameDay(reqDate, _selectedDate!);
          }).toList();

    // 3) search filter
    if (q.isEmpty) {
      setState(() => _filtered = List<EmployeeRequestVm>.from(dateFiltered));
      return;
    }

    setState(() {
      _filtered = dateFiltered.where((e) {
        final m = e.details;
        return m.fullName.toLowerCase().contains(q) ||
            m.employeeId.toLowerCase().contains(q) ||
            m.department.toLowerCase().contains(q) ||
            m.officialEmail.toLowerCase().contains(q);
      }).toList();
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _title() {
    if (widget.initialFilter == null) return "Employee Requests";
    switch (widget.initialFilter!) {
      case RequestStatus.pending:
        return "Pending Requests";
      case RequestStatus.approved:
        return "Approved Employees";
      case RequestStatus.rejected:
        return "Rejected Requests";
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _apply();
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    _apply();
  }

  String _dateLabel() {
    if (_selectedDate == null) return "Select date";
    final d = _selectedDate!;
    return "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
  }

  Future<void> _approve(EmployeeRequestVm req) async {
    final reason =
        await _reasonDialog(title: "Approval Reason", hint: "Enter approval reason");
    if (reason == null) return;

    final updated = req.copyWith(
      status: RequestStatus.approved,
      decisionReason: reason,
      decidedAt: DateTime.now(),
    );
    widget.onChanged(updated);
    setState(() {});
    _apply();
  }

  Future<void> _reject(EmployeeRequestVm req) async {
    final reason =
        await _reasonDialog(title: "Rejection Reason", hint: "Enter rejection reason");
    if (reason == null) return;

    final updated = req.copyWith(
      status: RequestStatus.rejected,
      decisionReason: reason,
      decidedAt: DateTime.now(),
    );
    widget.onChanged(updated);
    setState(() {});
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title()),
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
        elevation: 0,
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: "Search by name / ID / department / email",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kCardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kCardBorder),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Date picker beside search bar
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: kCardBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 18),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                _dateLabel(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (_selectedDate != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _clearDate,
                                child: const Icon(Icons.close, size: 18),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          "No records found",
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _card(_filtered[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(EmployeeRequestVm req) {
    final m = req.details;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE9EEF7),
                child: Text(
                  _initials(m.fullName),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text("Emp ID: ${m.employeeId}",
                        style: const TextStyle(color: Colors.black54)),
                    Text("Department: ${m.department}",
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              _statusChip(req.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final updated = await Navigator.push<EmployeeRequestVm>(
                      context,
                      MaterialPageRoute(builder: (_) => EmployeeDetailsPage(request: req)),
                    );
                    if (updated != null) widget.onChanged(updated);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("View",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: req.status == RequestStatus.pending ? () => _approve(req) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: req.status == RequestStatus.pending
                        ? kButtonColor
                        : kButtonColor.withOpacity(0.45),
                    foregroundColor: kTextColor,
                    disabledBackgroundColor: kButtonColor.withOpacity(0.45),
                    disabledForegroundColor: kTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Approve",
                      style: TextStyle(
                        color: req.status == RequestStatus.pending
                            ? kTextColor
                            : kTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: req.status == RequestStatus.pending ? () => _reject(req) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: req.status == RequestStatus.pending
                        ? kButtonColor
                        : kButtonColor.withOpacity(0.45),
                    foregroundColor: kTextColor,
                    disabledBackgroundColor: kButtonColor.withOpacity(0.45),
                    disabledForegroundColor: kTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Reject",
                      style: TextStyle(
                        color: req.status == RequestStatus.pending
                            ? kTextColor
                            : kTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(RequestStatus status) {
    late final String text;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case RequestStatus.pending:
        text = "PENDING";
        bg = const Color(0xFFF2D58A);
        fg = Colors.brown;
        break;
      case RequestStatus.approved:
        text = "APPROVED";
        bg = const Color(0xFFCEF2D6);
        fg = const Color(0xFF1B7A33);
        break;
      case RequestStatus.rejected:
        text = "REJECTED";
        bg = const Color(0xFFF6CDCD);
        fg = const Color(0xFFB11E1E);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "?";
    return parts.map((e) => e.isNotEmpty ? e[0] : "").take(2).join().toUpperCase();
  }

  Future<String?> _reasonDialog({required String title, required String hint}) async {
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
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(context, t);
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
}

class EmployeeDetailsPage extends StatelessWidget {
  final EmployeeRequestVm request;
  const EmployeeDetailsPage({super.key, required this.request});

  // Theme constants
  static const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
  static const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
  static const Color kAppBarColor = Color(0xFF8C6EAF);
  static const Color kTextColor = Colors.white;

  static const List<String> _docOrder = [
    'resume',
    'offerLetter',
    'aadhaarCard',
    'panCard',
    'experienceCertificate',
    'bankBook',
    'tenthMarksheet',
    'twelfthMarksheet',
    'provisionalCertificate',
  ];

  static const Map<String, String> _docLabels = {
    'resume': 'Resume',
    'offerLetter': 'Offer Letter',
    'aadhaarCard': 'Aadhaar Card',
    'panCard': 'PAN Card',
    'experienceCertificate': 'Experience Certificate',
    'bankBook': 'Bank Book',
    'tenthMarksheet': '10th Marksheet',
    'twelfthMarksheet': '12th Marksheet',
    'provisionalCertificate': 'Degree / Provisional Certificate',
  };

  @override
  Widget build(BuildContext context) {
    final m = request.details;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Details"),
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
        elevation: 0,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section("Profile", [
                  _kv("Full Name", m.fullName),
                  _kv("Employee ID", m.employeeId),
                  _kv("Gender", m.gender),
                  _kv("DOB", _fmtDate(m.dob)),
                  _kv("Blood Group", m.bloodGroup),
                  _kv("Marital Status", m.maritalStatus),
                ]),
                _section("Contact", [
                  _kv("Official Email", m.officialEmail),
                  _kv("Personal Email", m.personalEmail),
                  _kv("Mobile", "${m.mobileCountryCode} ${m.mobileNumber}"),
                ]),
                _section("Address", [
                  _kv("Permanent Address", m.permanentAddress),
                  _kv("City", m.city),
                  _kv("State", m.state),
                  _kv("Pincode", m.pincode),
                ]),
                _section("Company", [
                  _kv("Company Name", m.companyName),
                  _kv("Branch Location", m.branchLocation),
                  _kv("Date of Joining", _fmtDate(m.doj)),
                  _kv("Department", m.department),
                  _kv("Designation", m.designation),
                  _kv("Work Mode", m.workMode),
                  _kv("Shift Timing", m.shiftTiming),
                  _kv("Work Days", m.workDays.join(", ")),
                ]),
                _section("Bank", [
                  _kv("Bank Name", m.bankName),
                  _kv("Account Holder", m.accountHolderName),
                  _kv("Account Number", m.accountNumber),
                  _kv("IFSC Code", m.ifscCode),
                  _kv("Bank Branch", m.bankBranch),
                  _kv("UPI ID", m.upiId),
                ]),
                _section("Identity", [
                  _kv("PAN Number", m.panNumber),
                  _kv("Aadhaar Number", m.aadhaarNumber),
                ]),
                _section("Salary", [
                  _kv("Basic Pay", m.basicPay.toString()),
                  _kv("HRA", m.hra.toString()),
                  _kv("Bonus", m.bonus.toString()),
                  _kv("Allowances Total", m.allowancesTotal.toString()),
                  _kv("Deductions Amount", m.deductionsAmount.toString()),
                  _kv("Professional Tax", m.professionalTax.toString()),
                  _kv("PF Number", m.pfNumber),
                  _kv("ESI Number", m.esiNumber),
                  _kv("Gross Salary", m.grossSalary.toString()),
                  _kv("Net Salary", m.netSalary.toString()),
                ]),
                _section("Documents", _docWidgets(m.documents)),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _docWidgets(Map<String, dynamic> docs) {
    if (docs.isEmpty) return [_kv("Total Documents", "0"), _kv("Uploads", "-")];

    final out = <Widget>[];
    out.add(_kv("Total Documents", docs.length.toString()));
    out.add(const SizedBox(height: 6));

    for (final k in _docOrder) {
      if (docs.containsKey(k) && docs[k] != null) {
        out.add(_kv(_docLabels[k] ?? k, _docToText(docs[k])));
      }
    }

    final extra = docs.keys.where((k) => !_docOrder.contains(k)).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final k in extra) {
      out.add(_kv(_beautifyKey(k), _docToText(docs[k])));
    }
    return out;
  }

  String _docToText(dynamic v) {
    if (v == null) return "-";
    if (v is Map) {
      final map = Map<String, dynamic>.from(v as Map);
      final fn = (map["fileName"] ?? map["name"] ?? map["filename"])?.toString();
      final path = map["path"]?.toString();
      final parts = <String>[];
      if (fn != null && fn.trim().isNotEmpty) parts.add(fn);
      if (path != null && path.trim().isNotEmpty) parts.add(path);
      return parts.isEmpty ? v.toString() : parts.join(" • ");
    }
    return v.toString();
  }

  String _beautifyKey(String k) {
    final s = k.trim();
    final snake = s.replaceAll(RegExp(r'[_\-]+'), ' ');
    final spaced = snake.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return spaced
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
          ),
          Expanded(
            child: Text(v.trim().isEmpty ? "-" : v),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
}