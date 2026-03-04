// import 'package:flutter/material.dart';
// import 'employee_onboarding_form_page.dart';
// import 'employee_onboarding_models.dart';


// /* -------------------- Theme (your colors) -------------------- */
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// /* ===================== Model ===================== */
// enum OnboardStatus { pending, approved, completed }

// class OnboardRequest {
//   final String id;
//   final String employeeName;
//   final String department;
//   final DateTime createdAt;
//   OnboardStatus status;

//   final String email;
//   final String phone;
//   final String location; // ✅ Branch/Location stored here
//   final String designation;

//   final EmployeeOnboardFormResult? form;

//   OnboardRequest({
//     required this.id,
//     required this.employeeName,
//     required this.department,
//     required this.createdAt,
//     required this.status,
//     required this.email,
//     required this.phone,
//     required this.location,
//     required this.designation,
//     this.form,
//   });
// }

// /* ===================== Page ===================== */
// class EmployeeOnboardingPage extends StatefulWidget {
//   const EmployeeOnboardingPage({super.key});

//   @override
//   State<EmployeeOnboardingPage> createState() => _EmployeeOnboardingPageState();
// }

// class _EmployeeOnboardingPageState extends State<EmployeeOnboardingPage> {
//   final TextEditingController _searchCtrl = TextEditingController();

//   // ✅ Department "Others" support
//   final TextEditingController _otherDeptCtrl = TextEditingController();
//   bool _showOtherDeptField = false;
//   final List<String> _customDepartments = [];

//   // ✅ Branch/Location "Others" support
//   final TextEditingController _otherBranchCtrl = TextEditingController();
//   bool _showOtherBranchField = false;
//   final List<String> _customBranches = [];

//   static const List<String> _statusItems = [
//     "All",
//     "Pending",
//     "Approved",
//     "Completed",
//   ];

//   String _statusFilter = "All";
//   String _deptFilter = "All Department";
//   String _branchFilter = "All Branch";

//   final List<OnboardRequest> _all = [
//     OnboardRequest(
//       id: "EMP001",
//       employeeName: "Arun Kumar",
//       department: "IT",
//       createdAt: DateTime.now(),
//       status: OnboardStatus.pending,
//       email: "arun@example.com",
//       phone: "+919876543210",
//       location: "Chennai HQ",
//       designation: "Software Engineer",
//     ),
//     OnboardRequest(
//       id: "EMP002",
//       employeeName: "Priya S",
//       department: "Marketing",
//       createdAt: DateTime.now().subtract(const Duration(days: 2)),
//       status: OnboardStatus.approved,
//       email: "priya@example.com",
//       phone: "+919123456780",
//       location: "Tiruvallur Branch",
//       designation: "Executive",
//     ),
//     OnboardRequest(
//       id: "EMP003",
//       employeeName: "Manoj R",
//       department: "HR",
//       createdAt: DateTime.now().subtract(const Duration(days: 10)),
//       status: OnboardStatus.completed,
//       email: "manoj@example.com",
//       phone: "+919000011111",
//       location: "Coimbatore Branch",
//       designation: "HR Associate",
//     ),
//   ];

//   // UI sizes
//   static const double _summaryHeight = 42;
//   static const double _fieldHeight = 42;
//   static const double _gap = 10;

//   double _pageHPadding(double width) => 12;

//   // ✅ Department dropdown list
//   List<String> get _departments {
//     final set = <String>{"All Department"};
//     for (final r in _all) {
//       set.add(r.department);
//     }
//     for (final d in _customDepartments) {
//       set.add(d);
//     }

//     final list = set.toList();
//     list.remove("All Department");
//     list.sort();
//     list.insert(0, "All Department");
//     if (!list.contains("Others")) list.add("Others");
//     return list;
//   }

//   // ✅ Branch/Location dropdown list
//   List<String> get _branches {
//     final set = <String>{"All Branch"};
//     for (final r in _all) {
//       final loc = r.location.trim();
//       if (loc.isNotEmpty) set.add(loc);
//     }
//     for (final b in _customBranches) {
//       set.add(b);
//     }

//     final list = set.toList();
//     list.remove("All Branch");
//     list.sort();
//     list.insert(0, "All Branch");
//     if (!list.contains("Others")) list.add("Others");
//     return list;
//   }

//   OnboardStatus? _statusFromString(String s) {
//     switch (s) {
//       case "Pending":
//         return OnboardStatus.pending;
//       case "Approved":
//         return OnboardStatus.approved;
//       case "Completed":
//         return OnboardStatus.completed;
//       default:
//         return null;
//     }
//   }

//   List<OnboardRequest> get _filtered {
//     final q = _searchCtrl.text.trim().toLowerCase();
//     final status = _statusFromString(_statusFilter);

//     return _all.where((r) {
//       if (status != null && r.status != status) return false;

//       if (_deptFilter != "All Department" &&
//           _deptFilter != "Others" &&
//           r.department != _deptFilter) {
//         return false;
//       }

//       if (_branchFilter != "All Branch" &&
//           _branchFilter != "Others" &&
//           r.location != _branchFilter) {
//         return false;
//       }

//       if (q.isNotEmpty) {
//         final hay =
//             "${r.employeeName} ${r.id} ${r.department} ${r.location}".toLowerCase();
//         if (!hay.contains(q)) return false;
//       }
//       return true;
//     }).toList()
//       ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
//   }

//   int get _requestCount => _all.length;
//   int get _approvedCount =>
//       _all.where((e) => e.status == OnboardStatus.approved).length;
//   int get _completedCount =>
//       _all.where((e) => e.status == OnboardStatus.completed).length;

//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     _otherDeptCtrl.dispose();
//     _otherBranchCtrl.dispose();
//     super.dispose();
//   }

//   // ✅ open full form page
//   Future<void> _openCreateEmployeeForm() async {
//     final result = await Navigator.push(
//   context,
//   MaterialPageRoute(builder: (_) => const EmployeeOnboardingFormPage()),
// );


//     if (result == null) return;

//     setState(() {
//       final newId = "EMP${(_all.length + 1).toString().padLeft(3, '0')}";

//       _all.add(
//         OnboardRequest(
//           id: newId,
//           employeeName: result.fullName,
//           department: result.department,
//           createdAt: DateTime.now(),
//           status: OnboardStatus.pending,
//           email: result.personalEmail,
//           phone: "${result.mobileCountryCode}${result.mobileNumber}",

//           // ✅ FIX: Form has branchLocation (NOT location)
//           location: result.branchLocation,

//           designation: result.designation,
//           form: result,
//         ),
//       );
//     });
//   }

//   // ✅ Show details (tap card)
//   void _openDetails(OnboardRequest r) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.78,
//           minChildSize: 0.45,
//           maxChildSize: 0.95,
//           builder: (context, scrollCtrl) {
//             return Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
//               ),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 10),
//                   Container(
//                     width: 44,
//                     height: 5,
//                     decoration: BoxDecoration(
//                       color: Colors.black12,
//                       borderRadius: BorderRadius.circular(999),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 14),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             r.employeeName,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                         ),
//                         _statusChip(r.status),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Expanded(
//                     child: ListView(
//                       controller: scrollCtrl,
//                       padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
//                       children: [
//                         _detailTile("Employee ID", r.id),
//                         _detailTile("Department", r.department),
//                         _detailTile("Designation", r.designation),
//                         _detailTile("Branch / Location", r.location),
//                         _detailTile("Personal Email", r.email),
//                         _detailTile("Phone", r.phone),
//                         _detailTile("Created At", _fmtDate(r.createdAt)),
//                         const SizedBox(height: 10),
//                         if (r.form != null) ...[
//                           _detailSection("Form Details"),
//                           _detailTile("Full Name", r.form!.fullName),
//                           _detailTile("Gender", r.form!.gender),
//                           _detailTile("DOB", _fmtDateYMD(r.form!.dob)),
//                           _detailTile("Blood Group", r.form!.bloodGroup),
//                           _detailTile("Marital Status", r.form!.maritalStatus),
//                           _detailTile(
//                               "Permanent Address", r.form!.permanentAddress),
//                           _detailTile("City", r.form!.city),
//                           _detailTile("State", r.form!.state),
//                           _detailTile("Pincode", r.form!.pincode),
//                           _detailTile(
//                             "Official Email",
//                             r.form!.officialEmail.isEmpty
//                                 ? "-"
//                                 : r.form!.officialEmail,
//                           ),
//                         ] else ...[
//                           _detailSection("Form Details"),
//                           const Padding(
//                             padding: EdgeInsets.only(top: 6),
//                             child: Text(
//                               "No full form data saved for this employee.",
//                               style: TextStyle(color: Colors.black54),
//                             ),
//                           ),
//                         ],
//                         const SizedBox(height: 12),
//                         SizedBox(
//                           height: 44,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: kButtonColor,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             onPressed: () => Navigator.pop(context),
//                             child: const Text("Close"),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _detailSection(String title) {
//     return Container(
//       margin: const EdgeInsets.only(top: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF6F6FA),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0x22000000)),
//       ),
//       child: Text(
//         title,
//         style: const TextStyle(fontWeight: FontWeight.w800),
//       ),
//     );
//   }

//   Widget _detailTile(String k, String v) {
//     return Container(
//       margin: const EdgeInsets.only(top: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0x22000000)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 130,
//             child: Text(
//               k,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               v.isEmpty ? "-" : v,
//               style: const TextStyle(color: Colors.black87),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final data = _filtered;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Employee Onboarding"),
//         backgroundColor: kAppBarColor,
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, c) {
//               final pad = _pageHPadding(c.maxWidth);

//               return Column(
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.fromLTRB(pad, 14, pad, 10),
//                     child: Column(
//                       children: [
//                         _topSummaryResponsive(c.maxWidth),
//                         const SizedBox(height: _gap),
//                         _filtersResponsive(c.maxWidth),
//                         if (_showOtherDeptField) ...[
//                           const SizedBox(height: _gap),
//                           _otherDeptInputRow(),
//                         ],
//                         if (_showOtherBranchField) ...[
//                           const SizedBox(height: _gap),
//                           _otherBranchInputRow(),
//                         ],
//                         const SizedBox(height: _gap),
//                         _listTitle(),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: data.isEmpty
//                         ? const Center(child: Text("No data available"))
//                         : ListView.builder(
//                             padding: EdgeInsets.fromLTRB(pad, 0, pad, 14),
//                             itemCount: data.length,
//                             itemBuilder: (context, i) =>
//                                 _employeeCard(data[i]),
//                           ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   /* ===================== SUMMARY ===================== */

//   Widget _topSummaryResponsive(double width) {
//     if (width < 360) {
//       return Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                   child: _miniSummaryCard(
//                       "Requests", Icons.groups, _requestCount)),
//               const SizedBox(width: _gap),
//               Expanded(
//                   child: _miniSummaryCard(
//                       "Approved", Icons.check_circle, _approvedCount)),
//             ],
//           ),
//           const SizedBox(height: _gap),
//           Row(
//             children: [
//               Expanded(
//                   child: _miniSummaryCard(
//                       "Completed", Icons.done_all, _completedCount)),
//             ],
//           ),
//           const SizedBox(height: _gap),
//           _createEmployeeButtonFullWidthSmall(),
//         ],
//       );
//     }

//     if (width < 720) {
//       return Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                   child: _miniSummaryCard(
//                       "Requests", Icons.groups, _requestCount)),
//               const SizedBox(width: _gap),
//               Expanded(
//                   child: _miniSummaryCard(
//                       "Approved", Icons.check_circle, _approvedCount)),
//               const SizedBox(width: _gap),
//               Expanded(
//                   child: _miniSummaryCard(
//                       "Completed", Icons.done_all, _completedCount)),
//             ],
//           ),
//           const SizedBox(height: _gap),
//           _createEmployeeButtonFullWidthSmall(),
//         ],
//       );
//     }

//     return Row(
//       children: [
//         Expanded(
//             child: _miniSummaryCard("Requests", Icons.groups, _requestCount)),
//         const SizedBox(width: _gap),
//         Expanded(
//             child:
//                 _miniSummaryCard("Approved", Icons.check_circle, _approvedCount)),
//         const SizedBox(width: _gap),
//         Expanded(
//             child:
//                 _miniSummaryCard("Completed", Icons.done_all, _completedCount)),
//         const SizedBox(width: _gap),
//         Expanded(flex: 2, child: _createEmployeeButtonInlineSmall()),
//       ],
//     );
//   }

//   Widget _miniSummaryCard(String label, IconData icon, int count) {
//     return Container(
//       height: _summaryHeight,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0x22000000)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 28,
//             height: 28,
//             decoration: BoxDecoration(
//               color: kButtonColor.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, size: 16, color: kButtonColor),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   maxLines: 1,
//                   overflow: TextOverflow.clip,
//                   softWrap: false,
//                   style: const TextStyle(
//                     fontSize: 11,
//                     height: 1.0,
//                     color: Colors.black54,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Text(
//                   "$count",
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                     height: 1.0,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /* ===================== BUTTON ===================== */

//   Widget _createEmployeeButtonInlineSmall() {
//     return SizedBox(
//       height: _summaryHeight,
//       child: ElevatedButton.icon(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: kButtonColor,
//           foregroundColor: kTextColor,
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         icon: const Icon(Icons.person_add_alt_1, size: 18),
//         label: const Text(
//           "Create Employee",
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(fontSize: 13),
//         ),
//         onPressed: _openCreateEmployeeForm,
//       ),
//     );
//   }

//   Widget _createEmployeeButtonFullWidthSmall() {
//     return SizedBox(
//       height: _summaryHeight,
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: kButtonColor,
//           foregroundColor: kTextColor,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         icon: const Icon(Icons.person_add_alt_1, size: 18),
//         label: const Text("Create Employee", style: TextStyle(fontSize: 13)),
//         onPressed: _openCreateEmployeeForm,
//       ),
//     );
//   }

//   /* ===================== FILTERS ===================== */

//   Widget _filtersResponsive(double width) {
//     if (width < 520) {
//       return Column(
//         children: [
//           _searchField(),
//           const SizedBox(height: _gap),
//           Row(
//             children: [
//               Expanded(child: _statusDropdown()),
//               const SizedBox(width: _gap),
//               Expanded(child: _deptDropdown()),
//             ],
//           ),
//           const SizedBox(height: _gap),
//           _branchDropdown(),
//         ],
//       );
//     }

//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(flex: 5, child: _searchField()),
//             const SizedBox(width: _gap),
//             Expanded(flex: 3, child: _statusDropdown()),
//             const SizedBox(width: _gap),
//             Expanded(flex: 4, child: _deptDropdown()),
//           ],
//         ),
//         const SizedBox(height: _gap),
//         _branchDropdown(),
//       ],
//     );
//   }

//   Widget _searchField() {
//     return SizedBox(
//       height: _fieldHeight,
//       child: TextField(
//         controller: _searchCtrl,
//         onChanged: (_) => setState(() {}),
//         style: const TextStyle(fontSize: 13),
//         decoration: InputDecoration(
//           hintText: "Search",
//           prefixIcon: const Icon(Icons.search, size: 18),
//           filled: true,
//           fillColor: Colors.white,
//           isDense: true,
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Color(0x22000000)),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Color(0x22000000)),
//           ),
//         ),
//       ),
//     );
//   }

//   InputDecoration _ddDeco() {
//     return InputDecoration(
//       filled: true,
//       fillColor: Colors.white,
//       isDense: true,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0x22000000)),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0x22000000)),
//       ),
//     );
//   }

//   Widget _statusDropdown() {
//     return SizedBox(
//       height: _fieldHeight,
//       child: DropdownButtonFormField<String>(
//         value: _statusFilter,
//         isExpanded: true,
//         icon: const Icon(Icons.keyboard_arrow_down, size: 18),
//         decoration: _ddDeco(),
//         items: _statusItems
//             .map((e) => DropdownMenuItem<String>(
//                   value: e,
//                   child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
//                 ))
//             .toList(),
//         onChanged: (v) {
//           if (v == null) return;
//           setState(() => _statusFilter = v);
//         },
//       ),
//     );
//   }

//   Widget _deptDropdown() {
//     return SizedBox(
//       height: _fieldHeight,
//       child: DropdownButtonFormField<String>(
//         value: _deptFilter,
//         isExpanded: true,
//         icon: const Icon(Icons.keyboard_arrow_down, size: 18),
//         decoration: _ddDeco(),
//         items: _departments
//             .map((e) => DropdownMenuItem<String>(
//                   value: e,
//                   child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
//                 ))
//             .toList(),
//         onChanged: (v) {
//           if (v == null) return;
//           setState(() {
//             _deptFilter = v;
//             _showOtherDeptField = v == "Others";
//             if (!_showOtherDeptField) _otherDeptCtrl.clear();
//           });
//         },
//       ),
//     );
//   }

//   Widget _branchDropdown() {
//     return SizedBox(
//       height: _fieldHeight,
//       child: DropdownButtonFormField<String>(
//         value: _branchFilter,
//         isExpanded: true,
//         icon: const Icon(Icons.keyboard_arrow_down, size: 18),
//         decoration: _ddDeco(),
//         items: _branches
//             .map((e) => DropdownMenuItem<String>(
//                   value: e,
//                   child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
//                 ))
//             .toList(),
//         onChanged: (v) {
//           if (v == null) return;
//           setState(() {
//             _branchFilter = v;
//             _showOtherBranchField = v == "Others";
//             if (!_showOtherBranchField) _otherBranchCtrl.clear();
//           });
//         },
//       ),
//     );
//   }

//   InputDecoration _txtDeco(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       filled: true,
//       fillColor: Colors.white,
//       isDense: true,
//       contentPadding:
//           const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0x22000000)),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0x22000000)),
//       ),
//     );
//   }

//   Widget _otherDeptInputRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: SizedBox(
//             height: _fieldHeight,
//             child: TextField(
//               controller: _otherDeptCtrl,
//               style: const TextStyle(fontSize: 13),
//               decoration: _txtDeco("Enter new department"),
//             ),
//           ),
//         ),
//         const SizedBox(width: _gap),
//         SizedBox(
//           height: _fieldHeight,
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: kButtonColor,
//               foregroundColor: kTextColor,
//               shape:
//                   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             onPressed: () {
//               final txt = _otherDeptCtrl.text.trim();
//               if (txt.isEmpty) return;

//               setState(() {
//                 if (!_customDepartments.contains(txt) &&
//                     txt != "All Department" &&
//                     txt != "Others") {
//                   _customDepartments.add(txt);
//                 }
//                 _deptFilter = txt;
//                 _showOtherDeptField = false;
//                 _otherDeptCtrl.clear();
//               });
//             },
//             child: const Text("Add", style: TextStyle(fontSize: 13)),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _otherBranchInputRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: SizedBox(
//             height: _fieldHeight,
//             child: TextField(
//               controller: _otherBranchCtrl,
//               style: const TextStyle(fontSize: 13),
//               decoration: _txtDeco("Enter new branch / location"),
//             ),
//           ),
//         ),
//         const SizedBox(width: _gap),
//         SizedBox(
//           height: _fieldHeight,
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: kButtonColor,
//               foregroundColor: kTextColor,
//               shape:
//                   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             onPressed: () {
//               final txt = _otherBranchCtrl.text.trim();
//               if (txt.isEmpty) return;

//               setState(() {
//                 if (!_customBranches.contains(txt) &&
//                     txt != "All Branch" &&
//                     txt != "Others") {
//                   _customBranches.add(txt);
//                 }
//                 _branchFilter = txt;
//                 _showOtherBranchField = false;
//                 _otherBranchCtrl.clear();
//               });
//             },
//             child: const Text("Add", style: TextStyle(fontSize: 13)),
//           ),
//         ),
//       ],
//     );
//   }

//   /* ===================== LIST UI ===================== */

//   Widget _listTitle() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.92),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0x22000000)),
//       ),
//       child: const Text(
//         "Employee Onboarding",
//         style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _employeeCard(OnboardRequest r) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: () => _openDetails(r),
//       child: Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(top: 10),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.95),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: const Color(0x22000000)),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     r.employeeName,
//                     style: const TextStyle(
//                         fontWeight: FontWeight.w700, fontSize: 14),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     "${r.id} • ${r.department}",
//                     style: const TextStyle(fontSize: 12, color: Colors.black54),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     r.location,
//                     style: const TextStyle(fontSize: 12, color: Colors.black54),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10),
//             _statusChip(r.status),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _statusChip(OnboardStatus s) {
//     final String text;
//     final Color bg;
//     final Color fg;

//     switch (s) {
//       case OnboardStatus.pending:
//         text = "Pending";
//         bg = const Color(0xFFFFF3CD);
//         fg = const Color(0xFF8A6D3B);
//         break;
//       case OnboardStatus.approved:
//         text = "Approved";
//         bg = const Color(0xFFD1E7DD);
//         fg = const Color(0xFF0F5132);
//         break;
//       case OnboardStatus.completed:
//         text = "Completed";
//         bg = const Color(0xFFE2E3FF);
//         fg = const Color(0xFF2B2D6E);
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//             fontSize: 12, fontWeight: FontWeight.w600, color: fg),
//       ),
//     );
//   }

//   String _fmtDate(DateTime d) {
//     final dd = d.day.toString().padLeft(2, '0');
//     final mm = d.month.toString().padLeft(2, '0');
//     final yy = d.year.toString();
//     return "$dd-$mm-$yy";
//   }

//   String _fmtDateYMD(DateTime d) {
//     final dd = d.day.toString().padLeft(2, '0');
//     final mm = d.month.toString().padLeft(2, '0');
//     final yy = d.year.toString();
//     return "$yy-$mm-$dd";
//   }
// }

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import 'employee_onboarding_form_page.dart';
import 'employee_onboarding_models.dart';

/* -------------------- Theme (your colors) -------------------- */
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

/* ===================== Model ===================== */
enum OnboardStatus { pending, approved, rejected, completed }

class OnboardRequest {
  final String id;
  final String employeeName;
  final String department;
  final DateTime createdAt;
  OnboardStatus status;

  final String email;
  final String phone;
  final String location;
  final String designation;

  final EmployeeOnboardFormResult? form;

  OnboardRequest({
    required this.id,
    required this.employeeName,
    required this.department,
    required this.createdAt,
    required this.status,
    required this.email,
    required this.phone,
    required this.location,
    required this.designation,
    this.form,
  });

  OnboardRequest copyWith({
    String? employeeName,
    String? department,
    DateTime? createdAt,
    OnboardStatus? status,
    String? email,
    String? phone,
    String? location,
    String? designation,
    EmployeeOnboardFormResult? form,
  }) {
    return OnboardRequest(
      id: id,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      designation: designation ?? this.designation,
      form: form ?? this.form,
    );
  }
}

/* ===================== Page ===================== */
class EmployeeOnboardingPage extends StatefulWidget {
  const EmployeeOnboardingPage({super.key});

  @override
  State<EmployeeOnboardingPage> createState() => _EmployeeOnboardingPageState();
}

class _EmployeeOnboardingPageState extends State<EmployeeOnboardingPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  final TextEditingController _otherDeptCtrl = TextEditingController();
  bool _showOtherDeptField = false;
  final List<String> _customDepartments = [];

  final TextEditingController _otherBranchCtrl = TextEditingController();
  bool _showOtherBranchField = false;
  final List<String> _customBranches = [];

  static const List<String> _statusItems = [
    "All",
    "Pending",
    "Approved",
    "Rejected",
    "Completed",
  ];

  String _statusFilter = "All";
  String _deptFilter = "All Department";
  String _branchFilter = "All Branch";

  final List<OnboardRequest> _all = [
    OnboardRequest(
      id: "EMP001",
      employeeName: "Arun Kumar",
      department: "IT",
      createdAt: DateTime.now(),
      status: OnboardStatus.pending,
      email: "arun@example.com",
      phone: "+919876543210",
      location: "Chennai HQ",
      designation: "Software Engineer",
    ),
  ];

  static const double _summaryHeight = 42;
  static const double _fieldHeight = 42;
  static const double _gap = 10;

  double _pageHPadding(double width) => 12;

  List<String> get _departments {
    final set = <String>{"All Department"};
    for (final r in _all) {
      set.add(r.department);
    }
    for (final d in _customDepartments) {
      set.add(d);
    }

    final list = set.toList();
    list.remove("All Department");
    list.sort();
    list.insert(0, "All Department");
    if (!list.contains("Others")) list.add("Others");
    return list;
  }

  List<String> get _branches {
    final set = <String>{"All Branch"};
    for (final r in _all) {
      final loc = r.location.trim();
      if (loc.isNotEmpty) set.add(loc);
    }
    for (final b in _customBranches) {
      set.add(b);
    }

    final list = set.toList();
    list.remove("All Branch");
    list.sort();
    list.insert(0, "All Branch");
    if (!list.contains("Others")) list.add("Others");
    return list;
  }

  OnboardStatus? _statusFromString(String s) {
    switch (s) {
      case "Pending":
        return OnboardStatus.pending;
      case "Approved":
        return OnboardStatus.approved;
      case "Rejected":
        return OnboardStatus.rejected;
      case "Completed":
        return OnboardStatus.completed;
      default:
        return null;
    }
  }

  List<OnboardRequest> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final status = _statusFromString(_statusFilter);

    return _all.where((r) {
      if (status != null && r.status != status) return false;

      if (_deptFilter != "All Department" &&
          _deptFilter != "Others" &&
          r.department != _deptFilter) {
        return false;
      }

      if (_branchFilter != "All Branch" &&
          _branchFilter != "Others" &&
          r.location != _branchFilter) {
        return false;
      }

      if (q.isNotEmpty) {
        final hay =
            "${r.employeeName} ${r.id} ${r.department} ${r.location}".toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get _requestCount => _all.length;
  int get _approvedCount =>
      _all.where((e) => e.status == OnboardStatus.approved).length;

  int get _rejectedCount =>
      _all.where((e) => e.status == OnboardStatus.rejected).length;

  int get _completedCount =>
      _all.where((e) => e.status == OnboardStatus.completed).length;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _otherDeptCtrl.dispose();
    _otherBranchCtrl.dispose();
    super.dispose();
  }

  EmployeeOnboardFormResult _createDefaultFormData() {
    return EmployeeOnboardFormResult(
      fullName: '',
      gender: '',
      dob: DateTime.now(),
      bloodGroup: '',
      maritalStatus: '',
      personalEmail: '',
      mobileCountryCode: '+91',
      mobileNumber: '',
      permanentAddress: '',
      city: '',
      state: '',
      pincode: '',
      companyName: 'GCARE Pvt Ltd',
      branchLocation: 'Chennai HQ',
      employeeId: '',
      doj: DateTime.now(),
      department: 'IT',
      designation: 'Software Engineer',
      workMode: 'Office',
      shiftTiming: '9 AM - 6 PM',
      workDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      officialEmail: '',
      bankName: '',
      accountHolderName: '',
      accountNumber: '',
      ifscCode: '',
      bankBranch: '',
      upiId: '',
      panNumber: '',
      aadhaarNumber: '',
      basicPay: 0,
      hra: 0,
      bonus: 0,
      allowancesTotal: 0,
      deductionsAmount: 0,
      professionalTax: 0,
      pfNumber: '',
      esiNumber: '',
      grossSalary: 0,
      netSalary: 0,
      documents: {},
    );
  }

  Future<void> _openCreateEmployeeForm() async {
    final EmployeeOnboardFormResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeOnboardingFormPage(
          initialData: _createDefaultFormData(),
          title: 'New Employee',
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final newId = "EMP${(_all.length + 1).toString().padLeft(3, '0')}";

      _all.add(
        OnboardRequest(
          id: newId,
          employeeName: result.fullName,
          department: result.department,
          createdAt: DateTime.now(),
          status: OnboardStatus.pending,
          email: result.personalEmail,
          phone: "${result.mobileCountryCode}${result.mobileNumber}",
          location: result.branchLocation,
          designation: result.designation,
          form: result,
        ),
      );
    });
  }

  EmployeeOnboardFormResult _fallbackFormFromRequest(OnboardRequest r) {
    return EmployeeOnboardFormResult(
      fullName: r.employeeName,
      gender: "",
      dob: DateTime(2000, 1, 1),
      bloodGroup: "",
      maritalStatus: "",
      personalEmail: r.email,
      mobileCountryCode: "",
      mobileNumber: r.phone,
      permanentAddress: "",
      city: "",
      state: "",
      pincode: "",
      companyName: "",
      branchLocation: r.location,
      employeeId: r.id,
      doj: r.createdAt,
      department: r.department,
      designation: r.designation,
      workMode: "",
      shiftTiming: "",
      workDays: const [],
      officialEmail: "",
      bankName: "",
      accountHolderName: "",
      accountNumber: "",
      ifscCode: "",
      bankBranch: "",
      upiId: "",
      panNumber: "",
      aadhaarNumber: "",
      basicPay: 0,
      hra: 0,
      bonus: 0,
      allowancesTotal: 0,
      deductionsAmount: 0,
      professionalTax: 0,
      pfNumber: "",
      esiNumber: "",
      grossSalary: 0,
      netSalary: 0,
      documents: const {},
    );
  }

  Future<void> _editEmployee(OnboardRequest r) async {
    final initial = r.form ?? _fallbackFormFromRequest(r);

    final EmployeeOnboardFormResult? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeOnboardingFormPage(
          initialData: initial,
          title: "Edit Employee",
        ),
      ),
    );

    if (updated == null) return;

    setState(() {
      final idx = _all.indexWhere((e) => e.id == r.id);
      if (idx == -1) return;

      _all[idx] = _all[idx].copyWith(
        employeeName: updated.fullName,
        department: updated.department,
        email: updated.personalEmail,
        phone: "${updated.mobileCountryCode}${updated.mobileNumber}",
        location: updated.branchLocation,
        designation: updated.designation,
        form: updated,
      );
    });
  }

  Future<void> _deleteEmployee(OnboardRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Employee"),
          content: Text("Do you want to delete ${r.employeeName} (${r.id})?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() {
      _all.removeWhere((e) => e.id == r.id);
    });
  }

  // -----------------------
  // VIEW DETAILS helpers
  // -----------------------
  Map<String, dynamic> _safeFormToJson(EmployeeOnboardFormResult f) {
    return f.toJson();
  }

  bool _looksLikeDocumentKey(String key) {
    final k = key.toLowerCase();
    return k.contains("doc") ||
        k.contains("document") ||
        k.contains("file") ||
        k.contains("upload") ||
        k.contains("proof");
  }

  List<Map<String, dynamic>> _extractDocuments(Map<String, dynamic> json) {
    final docs = <Map<String, dynamic>>[];

    final raw = json["documents"];
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      m.forEach((k, v) {
        if (v is Map) {
          docs.add({"label": k, "value": Map<String, dynamic>.from(v)});
        }
      });
    }
    return docs;
  }

  String _prettyKey(String key) {
    final k = key.replaceAll('_', ' ');
    final spaced =
        k.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  // ✅ Open doc when clicking eye icon
  Future<void> _openDocumentFromDocMap(Map<String, dynamic> doc) async {
    final v = doc["value"];
    if (v is! Map) return;

    final m = Map<String, dynamic>.from(v);

    // These keys come from UploadedDoc.toJson() in your form page
    final String? path = (m["path"] ?? "").toString().trim().isEmpty
        ? null
        : m["path"].toString().trim();

    final String ext = (m["ext"] ?? "").toString().toLowerCase();
    final Uint8List? bytes = m["bytes"] is Uint8List ? m["bytes"] as Uint8List : null;

    // WEB: open bytes (data URL)
    if (kIsWeb) {
      // In most cases bytes will NOT be present in details page JSON,
      // so we try base64String if you store it later.
      Uint8List? fileBytes = bytes;

      // If you stored base64 in json, support it:
      final dynamic b64 = m["base64"];
      if (fileBytes == null && b64 is String && b64.trim().isNotEmpty) {
        try {
          fileBytes = base64Decode(b64);
        } catch (_) {}
      }

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot open on Web: file bytes not available.")),
        );
        return;
      }

      String mime = "application/octet-stream";
      if (ext == "pdf") mime = "application/pdf";
      if (ext == "png") mime = "image/png";
      if (ext == "jpg" || ext == "jpeg") mime = "image/jpeg";

      final uri = Uri.parse("data:$mime;base64,${base64Encode(fileBytes)}");
      await launchUrl(uri, webOnlyWindowName: "_blank");
      return;
    }

    // MOBILE/DESKTOP: open local file path
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File path not available to open.")),
      );
      return;
    }

    await OpenFilex.open(path);
  }

  void _openDetails(OnboardRequest r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollCtrl) {
            final formJson =
                r.form == null ? <String, dynamic>{} : _safeFormToJson(r.form!);
            final docs =
                r.form == null ? <Map<String, dynamic>>[] : _extractDocuments(formJson);

            final formFields = Map<String, dynamic>.from(formJson)
              ..remove("documents")
              ..removeWhere((k, v) => _looksLikeDocumentKey(k));

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        _statusChip(r.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      children: [
                        _detailSection("Employee Details"),
                        _detailTile("Employee ID", r.id),
                        _detailTile("Department", r.department),
                        _detailTile("Designation", r.designation),
                        _detailTile("Branch / Location", r.location),
                        _detailTile("Personal Email", r.email),
                        _detailTile("Phone", r.phone),
                        _detailTile("Created At", _fmtDate(r.createdAt)),
                        const SizedBox(height: 10),
                        if (r.form != null) ...[
                          _detailSection("Form Details (All Fields)"),
                          ...formFields.entries.map((e) {
                            final val = e.value;
                            final text =
                                (val == null || val.toString().trim().isEmpty)
                                    ? "-"
                                    : val.toString();
                            return _detailTile(_prettyKey(e.key), text);
                          }).toList(),
                          const SizedBox(height: 10),
                          _detailSection("Documents"),
                          if (docs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text("No documents found in the form data.",
                                  style: TextStyle(color: Colors.black54)),
                            )
                          else
                            ...docs.map((d) => _docTile(d)).toList(),
                        ] else ...[
                          _detailSection("Form Details"),
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text("No full form data saved for this employee.",
                                style: TextStyle(color: Colors.black54)),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kButtonColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ UPDATED: remove attachment icon + add eye icon to open file
  Widget _docTile(Map<String, dynamic> doc) {
    final label = _prettyKey((doc["label"] ?? "Document").toString());
    final value = doc["value"];

    String display;
    bool canOpen = false;

    if (value is Map) {
      final m = Map<String, dynamic>.from(value);
      display = (m["fileName"] ?? m["name"] ?? m["path"] ?? "-").toString();

      // open possible if we have path (mobile/desktop) or bytes/base64 (web)
      final p = (m["path"] ?? "").toString().trim();
      final b64 = (m["base64"] ?? "").toString().trim();
      canOpen = p.isNotEmpty || b64.isNotEmpty || m["bytes"] is Uint8List;
    } else if (value is Uint8List) {
      display = "Binary file (bytes: ${value.length})";
      canOpen = true;
    } else {
      display = value.toString();
      canOpen = false;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label: $display",
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // ✅ Eye icon (instead of attachment)
          IconButton(
            tooltip: "View",
            onPressed: canOpen ? () => _openDocumentFromDocMap(doc) : null,
            icon: Icon(
              Icons.visibility_outlined,
              size: 20,
              color: canOpen ? kButtonColor : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _detailTile(String k, String v) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(v.isEmpty ? "-" : v,
                style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // ✅ MAIN BUILD: Whole page scrolls from TOP now
  @override
  Widget build(BuildContext context) {
    final data = _filtered;

    return Scaffold(
     
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final pad = _pageHPadding(c.maxWidth);

              return CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 14, pad, 10),
                      child: Column(
                        children: [
                          _topSummaryResponsive(c.maxWidth),
                          const SizedBox(height: _gap),
                          _filtersResponsive(c.maxWidth),
                          if (_showOtherDeptField) ...[
                            const SizedBox(height: _gap),
                            _otherDeptInputRow(),
                          ],
                          if (_showOtherBranchField) ...[
                            const SizedBox(height: _gap),
                            _otherBranchInputRow(),
                          ],
                          const SizedBox(height: _gap),
                          _listTitle(),
                        ],
                      ),
                    ),
                  ),
                  if (data.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text("No data available")),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, 14),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _employeeCard(data[i]),
                          childCount: data.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ✅ Summary section
  Widget _topSummaryResponsive(double width) {
    if (width < 360) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _miniSummaryCard(
                      "Requests", Icons.groups, _requestCount)),
              const SizedBox(width: _gap),
              Expanded(
                  child: _miniSummaryCard(
                      "Approved", Icons.check_circle, _approvedCount)),
            ],
          ),
          const SizedBox(height: _gap),
          Row(
            children: [
              Expanded(
                  child: _miniSummaryCard(
                      "Rejected", Icons.cancel, _rejectedCount)),
              const SizedBox(width: _gap),
              Expanded(
                  child: _miniSummaryCard(
                      "Completed", Icons.done_all, _completedCount)),
            ],
          ),
          const SizedBox(height: _gap),
          _createEmployeeButtonFullWidthSmall(),
        ],
      );
    }

    if (width < 720) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _miniSummaryCard(
                      "Requests", Icons.groups, _requestCount)),
              const SizedBox(width: _gap),
              Expanded(
                  child: _miniSummaryCard(
                      "Approved", Icons.check_circle, _approvedCount)),
              const SizedBox(width: _gap),
              Expanded(
                  child: _miniSummaryCard(
                      "Rejected", Icons.cancel, _rejectedCount)),
              const SizedBox(width: _gap),
              Expanded(
                  child: _miniSummaryCard(
                      "Completed", Icons.done_all, _completedCount)),
            ],
          ),
          const SizedBox(height: _gap),
          _createEmployeeButtonFullWidthSmall(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _miniSummaryCard("Requests", Icons.groups, _requestCount)),
        const SizedBox(width: _gap),
        Expanded(child: _miniSummaryCard("Approved", Icons.check_circle, _approvedCount)),
        const SizedBox(width: _gap),
        Expanded(child: _miniSummaryCard("Rejected", Icons.cancel, _rejectedCount)),
        const SizedBox(width: _gap),
        Expanded(child: _miniSummaryCard("Completed", Icons.done_all, _completedCount)),
        const SizedBox(width: _gap),
        Expanded(flex: 2, child: _createEmployeeButtonInlineSmall()),
      ],
    );
  }

  Widget _miniSummaryCard(String label, IconData icon, int count) {
    return Container(
      height: _summaryHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kButtonColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: kButtonColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.0,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "$count",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createEmployeeButtonInlineSmall() {
    return SizedBox(
      height: _summaryHeight,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          foregroundColor: kTextColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.person_add_alt_1, size: 18),
        label: const Text(
          "Create Employee",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13),
        ),
        onPressed: _openCreateEmployeeForm,
      ),
    );
  }

  Widget _createEmployeeButtonFullWidthSmall() {
    return SizedBox(
      height: _summaryHeight,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          foregroundColor: kTextColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.person_add_alt_1, size: 18),
        label: const Text("Create Employee", style: TextStyle(fontSize: 13)),
        onPressed: _openCreateEmployeeForm,
      ),
    );
  }

  Widget _filtersResponsive(double width) {
    if (width < 520) {
      return Column(
        children: [
          _searchField(),
          const SizedBox(height: _gap),
          Row(
            children: [
              Expanded(child: _statusDropdown()),
              const SizedBox(width: _gap),
              Expanded(child: _deptDropdown()),
            ],
          ),
          const SizedBox(height: _gap),
          _branchDropdown(),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 5, child: _searchField()),
            const SizedBox(width: _gap),
            Expanded(flex: 3, child: _statusDropdown()),
            const SizedBox(width: _gap),
            Expanded(flex: 4, child: _deptDropdown()),
          ],
        ),
        const SizedBox(height: _gap),
        _branchDropdown(),
      ],
    );
  }

  Widget _searchField() {
    return SizedBox(
      height: _fieldHeight,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: "Search",
          prefixIcon: const Icon(Icons.search, size: 18),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x22000000)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x22000000)),
          ),
        ),
      ),
    );
  }

  InputDecoration _ddDeco() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
    );
  }

  Widget _statusDropdown() {
    return SizedBox(
      height: _fieldHeight,
      child: DropdownButtonFormField<String>(
        value: _statusFilter,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        decoration: _ddDeco(),
        items: _statusItems
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _statusFilter = v);
        },
      ),
    );
  }

  Widget _deptDropdown() {
    return SizedBox(
      height: _fieldHeight,
      child: DropdownButtonFormField<String>(
        value: _deptFilter,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        decoration: _ddDeco(),
        items: _departments
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _deptFilter = v;
            _showOtherDeptField = v == "Others";
            if (!_showOtherDeptField) _otherDeptCtrl.clear();
          });
        },
      ),
    );
  }

  Widget _branchDropdown() {
    return SizedBox(
      height: _fieldHeight,
      child: DropdownButtonFormField<String>(
        value: _branchFilter,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        decoration: _ddDeco(),
        items: _branches
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _branchFilter = v;
            _showOtherBranchField = v == "Others";
            if (!_showOtherBranchField) _otherBranchCtrl.clear();
          });
        },
      ),
    );
  }

  InputDecoration _txtDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
    );
  }

  Widget _otherDeptInputRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _fieldHeight,
            child: TextField(
              controller: _otherDeptCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: _txtDeco("Enter new department"),
            ),
          ),
        ),
        const SizedBox(width: _gap),
        SizedBox(
          height: _fieldHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kButtonColor,
              foregroundColor: kTextColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final txt = _otherDeptCtrl.text.trim();
              if (txt.isEmpty) return;

              setState(() {
                if (!_customDepartments.contains(txt) &&
                    txt != "All Department" &&
                    txt != "Others") {
                  _customDepartments.add(txt);
                }
                _deptFilter = txt;
                _showOtherDeptField = false;
                _otherDeptCtrl.clear();
              });
            },
            child: const Text("Add", style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _otherBranchInputRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _fieldHeight,
            child: TextField(
              controller: _otherBranchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: _txtDeco("Enter new branch / location"),
            ),
          ),
        ),
        const SizedBox(width: _gap),
        SizedBox(
          height: _fieldHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kButtonColor,
              foregroundColor: kTextColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final txt = _otherBranchCtrl.text.trim();
              if (txt.isEmpty) return;

              setState(() {
                if (!_customBranches.contains(txt) &&
                    txt != "All Branch" &&
                    txt != "Others") {
                  _customBranches.add(txt);
                }
                _branchFilter = txt;
                _showOtherBranchField = false;
                _otherBranchCtrl.clear();
              });
            },
            child: const Text("Add", style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _listTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: const Text(
        "Employee Onboarding",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _employeeCard(OnboardRequest r) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openDetails(r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.employeeName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${r.id} • ${r.department}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.location,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusChip(r.status),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: "More",
                onSelected: (v) async {
                  if (v == "view") {
                    _openDetails(r);
                  } else if (v == "edit") {
                    await _editEmployee(r);
                  } else if (v == "delete") {
                    await _deleteEmployee(r);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: "view", child: Text("View")),
                  PopupMenuItem(value: "edit", child: Text("Edit")),
                  PopupMenuItem(value: "delete", child: Text("Delete")),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Icon(Icons.more_vert, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(OnboardStatus s) {
    final String text;
    final Color bg;
    final Color fg;

    switch (s) {
      case OnboardStatus.pending:
        text = "Pending";
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF8A6D3B);
        break;
      case OnboardStatus.approved:
        text = "Approved";
        bg = const Color(0xFFD1E7DD);
        fg = const Color(0xFF0F5132);
        break;
      case OnboardStatus.rejected:
        text = "Rejected";
        bg = const Color(0xFFF8D7DA);
        fg = const Color(0xFF842029);
        break;
      case OnboardStatus.completed:
        text = "Completed";
        bg = const Color(0xFFE2E3FF);
        fg = const Color(0xFF2B2D6E);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return "$dd-$mm-$yy";
  }
}
