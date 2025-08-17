


// // import 'package:flutter/material.dart';

// // // Your provided theme color constants
// // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // const Color kAppBarColor = Color(0xFF8C6EAF);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // class MyApp extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Company Profile App',
// //       theme: ThemeData(
// //         primarySwatch: Colors.teal,
// //       ),
// //       home: CompanyDetailsPage(),
// //       debugShowCheckedModeBanner: false,
// //     );
// //   }
// // }

// // class CompanyDetailsPage extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.transparent,
// //       appBar: AppBar(
// //         backgroundColor: kAppBarColor,
// //         elevation: 1,
// //         leading: IconButton(
// //           icon: Icon(Icons.arrow_back, color: kTextColor),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         title: Text(
// //           'Profile',
// //           style: TextStyle(color: kTextColor, fontSize: 16),
// //         ),
// //       ),
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //         ),
// //         child: LayoutBuilder(
// //           builder: (context, constraints) {
// //             double maxWidth = constraints.maxWidth > 800 ? 800 : constraints.maxWidth;
// //             bool isWeb = constraints.maxWidth > 600;

// //             return Center(
// //               child: Container(
// //                 width: maxWidth,
// //                 child: SingleChildScrollView(
// //                   padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20, vertical: 20),
// //                   child: Column(
// //                     children: [
// //                       Column(
// //                         children: [
// //                           ClipRRect(
// //                             borderRadius: BorderRadius.circular(60),
// //                             child: Image.asset(
// //                               'assets/images/companylogo.png.jpeg',
// //                               width: 80,
// //                               height: 80,
// //                               fit: BoxFit.cover,
// //                             ),
// //                           ),
// //                           SizedBox(height: 15),
// //                           Text(
// //                             'Company Details',
// //                             style: TextStyle(
// //                               fontSize: isWeb ? 28 : 24,
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.grey[800],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       SizedBox(height: 30),
// //                       Container(
// //                         width: double.infinity,
// //                         padding: EdgeInsets.all(isWeb ? 30 : 20),
// //                         decoration: BoxDecoration(
// //                           color: Colors.white,
// //                           borderRadius: BorderRadius.circular(12),
// //                           boxShadow: [
// //                             BoxShadow(
// //                               color: Colors.grey.withOpacity(0.1),
// //                               spreadRadius: 2,
// //                               blurRadius: 8,
// //                               offset: Offset(0, 2),
// //                             ),
// //                           ],
// //                         ),
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             _buildDetailField('Company Name', 'Myth Reality Tech Pvt Ltd', isWeb),
// //                             SizedBox(height: 20),
// //                             _buildDetailField('Mobile Number', '9042545259', isWeb),
// //                             SizedBox(height: 20),
// //                             _buildIndustryTypeField(isWeb),
// //                             SizedBox(height: 20),
// //                             _buildDetailField('Company Website', '—', isWeb),
// //                             SizedBox(height: 20),
// //                             _buildDetailField('Alternative Email', '—', isWeb),
// //                           ],
// //                         ),
// //                       ),
// //                       SizedBox(height: 30),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildDetailField(String label, String value, bool isWeb) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           label,
// //           style: TextStyle(
// //             color: Colors.black,
// //             fontSize: isWeb ? 16 : 14,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         SizedBox(height: 6),
// //         Text(
// //           value,
// //           style: TextStyle(
// //             color: Colors.grey[600],
// //             fontSize: isWeb ? 18 : 16,
// //             fontWeight: FontWeight.normal,
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildIndustryTypeField(bool isWeb) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Industry Type',
// //           style: TextStyle(
// //             color: Colors.black,
// //             fontSize: isWeb ? 16 : 14,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         SizedBox(height: 10),
// //         Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             _buildIndustryType('IT', isWeb),
// //             SizedBox(height: 8),
// //             _buildIndustryType('Healthcare', isWeb),
// //             SizedBox(height: 8),
// //             _buildIndustryType('Organization', isWeb),
// //             SizedBox(height: 8),
// //             _buildIndustryType('Production', isWeb),
// //           ],
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildIndustryType(String type, bool isWeb) {
// //     return Row(
// //       children: [
// //         Container(
// //           width: isWeb ? 8 : 6,
// //           height: isWeb ? 8 : 6,
// //           decoration: BoxDecoration(
// //             color: kButtonColor,
// //             shape: BoxShape.circle,
// //           ),
// //         ),
// //         SizedBox(width: 10),
// //         Flexible(
// //           child: Text(
// //             type,
// //             style: TextStyle(
// //               color: Colors.grey[600],
// //               fontSize: isWeb ? 16 : 14,
// //             ),
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }



// // lib/pages/company_profile_page.dart

// import 'dart:io' show File;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:serv_app/models/company_data.dart';  // your shared model
// // import 'company_details_page.dart';                  // for the edit form

// // Theme colors
// const Color kPrimaryBackgroundTop    = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor             = Color(0xFF8C6EAF);
// const Color kButtonColor             = Color(0xFF655193);
// const Color kTextColor               = Colors.white;

// class CompanyProfilePage extends StatefulWidget {
//   const CompanyProfilePage({super.key});

//   @override
//   _CompanyProfilePageState createState() => _CompanyProfilePageState();
// }

// class _CompanyProfilePageState extends State<CompanyProfilePage> {
//   bool _isEditing = false;

//   late TextEditingController _nameCtrl;
//   late TextEditingController _emailCtrl;
//   late TextEditingController _phoneCtrl;
//   late TextEditingController _websiteCtrl;
//   late TextEditingController _adminNameCtrl;
//   late TextEditingController _adminRoleCtrl;

//   XFile? _logoFile;
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     // load from CompanyData
//     _logoFile      = CompanyData.logoFile;
//     _nameCtrl      = TextEditingController(text: CompanyData.companyName);
//     _emailCtrl     = TextEditingController(text: CompanyData.email);
//     _phoneCtrl     = TextEditingController(text: CompanyData.phone);
//     _websiteCtrl   = TextEditingController(text: CompanyData.website);
//     _adminNameCtrl = TextEditingController(text: CompanyData.adminName);
//     _adminRoleCtrl = TextEditingController(text: CompanyData.adminRole);
//   }

//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _emailCtrl.dispose();
//     _phoneCtrl.dispose();
//     _websiteCtrl.dispose();
//     _adminNameCtrl.dispose();
//     _adminRoleCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _pickLogo() async {
//     final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         _logoFile = picked;
//       });
//     }
//   }

//   void _toggleEdit() {
//     if (_isEditing) {
//       // save back into CompanyData
//       CompanyData.logoFile      = _logoFile;
//       CompanyData.companyName   = _nameCtrl.text.trim();
//       CompanyData.email         = _emailCtrl.text.trim();
//       CompanyData.phone         = _phoneCtrl.text.trim();
//       CompanyData.website       = _websiteCtrl.text.trim();
//       CompanyData.adminName     = _adminNameCtrl.text.trim();
//       CompanyData.adminRole     = _adminRoleCtrl.text.trim();
//     }
//     setState(() => _isEditing = !_isEditing);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isWide = MediaQuery.of(context).size.width > 600;
//     final double spacing = isWide ? 24.0 : 16.0;

//     ImageProvider? avatar;
//     if (_logoFile != null) {
//       avatar = kIsWeb
//           ? NetworkImage(_logoFile!.path)
//           : FileImage(File(_logoFile!.path));
//     }

//     return Scaffold(
//       backgroundColor: kPrimaryBackgroundTop,
//       appBar: AppBar(
//         backgroundColor: kAppBarColor,
//         title: const Text('Company Profile', style: TextStyle(color: kTextColor)),
//         iconTheme: const IconThemeData(color: kTextColor),
//         actions: [
//           IconButton(
//             icon: Icon(_isEditing ? Icons.check : Icons.edit, color: kTextColor),
//             onPressed: _toggleEdit,
//             tooltip: _isEditing ? 'Save' : 'Edit',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(spacing),
//         child: Center(
//           child: Container(
//             width: isWide ? 600 : double.infinity,
//             padding: EdgeInsets.all(spacing),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Avatar + camera button in edit mode
//                 if (_isEditing)
//                   Center(
//                     child: Stack(
//                       alignment: Alignment.bottomRight,
//                       children: [
//                         CircleAvatar(
//                           radius: 48,
//                           backgroundImage: avatar,
//                           backgroundColor: Colors.grey[200],
//                         ),
//                         Positioned(
//                           child: InkWell(
//                             onTap: _pickLogo,
//                             child: CircleAvatar(
//                               radius: 16,
//                               backgroundColor: kButtonColor,
//                               child: const Icon(Icons.camera_alt, size: 16, color: kTextColor),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 else if (avatar != null)
//                   Center(
//                     child: CircleAvatar(
//                       radius: 48,
//                       backgroundImage: avatar,
//                     ),
//                   ),
//                 SizedBox(height: spacing),

//                 // Fields
//                 if (_isEditing) ...[
//                   _buildEditField('Company Name', _nameCtrl),
//                   SizedBox(height: spacing),
//                   _buildEditField('Official Email', _emailCtrl, keyboard: TextInputType.emailAddress),
//                   SizedBox(height: spacing),
//                   _buildEditField('Phone Number', _phoneCtrl, keyboard: TextInputType.phone),
//                   SizedBox(height: spacing),
//                   _buildEditField('Website', _websiteCtrl, keyboard: TextInputType.url),
//                   SizedBox(height: spacing),
//                   _buildEditField('Admin Full Name', _adminNameCtrl),
//                   SizedBox(height: spacing),
//                   _buildEditField('Admin Designation', _adminRoleCtrl),
//                 ] else ...[
//                   _buildDisplayField('Company Name',   CompanyData.companyName,  isWide),
//                   SizedBox(height: spacing),
//                   _buildDisplayField('Official Email', CompanyData.email,        isWide),
//                   SizedBox(height: spacing),
//                   _buildDisplayField('Phone Number',   CompanyData.phone,        isWide),
//                   SizedBox(height: spacing),
//                   _buildDisplayField('Website',        CompanyData.website.isNotEmpty ? CompanyData.website : '—', isWide),
//                   SizedBox(height: spacing),
//                   _buildDisplayField('Admin Full Name',CompanyData.adminName,    isWide),
//                   SizedBox(height: spacing),
//                   _buildDisplayField('Admin Designation',CompanyData.adminRole, isWide),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDisplayField(String label, String value, bool isWide) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isWide ? 16 : 14)),
//         const SizedBox(height: 4),
//         Text(value, style: TextStyle(fontSize: isWide ? 18 : 16)),
//       ],
//     );
//   }

//   Widget _buildEditField(String label, TextEditingController ctrl,
//       {TextInputType keyboard = TextInputType.text}) {
//     return TextFormField(
//       controller: ctrl,
//       keyboardType: keyboard,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }
// }
// lib/Pagesadmin/profile_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:serv_app/models/company_data.dart'; // shared model with static fields

// Theme colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  bool _isEditing = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _adminNameCtrl;
  late final TextEditingController _adminRoleCtrl;

  final ImagePicker _picker =  ImagePicker();
  XFile? _logoFile;          // for persistence back to CompanyData if you already use it
  Uint8List? _logoBytes;     // used to render avatar cross-platform

  @override
  void initState() {
    super.initState();

    // Seed UI from CompanyData (your existing shared model)
    _logoFile      = CompanyData.logoFile;
    _nameCtrl      = TextEditingController(text: CompanyData.companyName);
    _emailCtrl     = TextEditingController(text: CompanyData.email);
    _phoneCtrl     = TextEditingController(text: CompanyData.phone);
    _websiteCtrl   = TextEditingController(text: CompanyData.website);
    _adminNameCtrl = TextEditingController(text: CompanyData.adminName);
    _adminRoleCtrl = TextEditingController(text: CompanyData.adminRole);

    // If a logo was already chosen earlier, load its bytes so we can show it
    _loadInitialLogoBytes();
  }

  Future<void> _loadInitialLogoBytes() async {
    try {
      if (_logoFile != null) {
        final bytes = await _logoFile!.readAsBytes(); // works on Web & Mobile
        if (mounted) {
          setState(() => _logoBytes = bytes);
        }
      }
    } catch (_) {
      // Ignore preview errors; UI will simply show empty avatar
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminRoleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes(); // cross-platform
      setState(() {
        _logoFile = picked;
        _logoBytes = bytes;
      });
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Save back into CompanyData (keeps your existing pattern)
      CompanyData.logoFile    = _logoFile;
      CompanyData.companyName = _nameCtrl.text.trim();
      CompanyData.email       = _emailCtrl.text.trim();
      CompanyData.phone       = _phoneCtrl.text.trim();
      CompanyData.website     = _websiteCtrl.text.trim();
      CompanyData.adminName   = _adminNameCtrl.text.trim();
      CompanyData.adminRole   = _adminRoleCtrl.text.trim();
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;
    final double spacing = isWide ? 24.0 : 16.0;

    // Single provider that works on all platforms
    ImageProvider<Object>? avatar =
        (_logoBytes != null) ? MemoryImage(_logoBytes!) : null;

    return Scaffold(
      backgroundColor: kPrimaryBackgroundTop,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        title: const Text('Company Profile', style: TextStyle(color: kTextColor)),
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: kTextColor),
            onPressed: _toggleEdit,
            tooltip: _isEditing ? 'Save' : 'Edit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing),
        child: Center(
          child: Container(
            width: isWide ? 600 : double.infinity,
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar + camera button in edit mode
                if (_isEditing)
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: avatar,
                          backgroundColor: Colors.grey[200],
                          child: avatar == null
                              ? const Icon(Icons.apartment, size: 36, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          child: InkWell(
                            onTap: _pickLogo,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: kButtonColor,
                              child: const Icon(Icons.camera_alt, size: 16, color: kTextColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: avatar,
                      backgroundColor: Colors.grey[200],
                      child: avatar == null
                          ? const Icon(Icons.apartment, size: 36, color: Colors.grey)
                          : null,
                    ),
                  ),

                SizedBox(height: spacing),

                // Fields
                if (_isEditing) ...[
                  _buildEditField('Company Name', _nameCtrl),
                  SizedBox(height: spacing),
                  _buildEditField('Official Email', _emailCtrl,
                      keyboard: TextInputType.emailAddress),
                  SizedBox(height: spacing),
                  _buildEditField('Phone Number', _phoneCtrl,
                      keyboard: TextInputType.phone),
                  SizedBox(height: spacing),
                  _buildEditField('Website', _websiteCtrl,
                      keyboard: TextInputType.url),
                  SizedBox(height: spacing),
                  _buildEditField('Admin Full Name', _adminNameCtrl),
                  SizedBox(height: spacing),
                  _buildEditField('Admin Designation', _adminRoleCtrl),
                ] else ...[
                  _buildDisplayField('Company Name', CompanyData.companyName, isWide),
                  SizedBox(height: spacing),
                  _buildDisplayField('Official Email', CompanyData.email, isWide),
                  SizedBox(height: spacing),
                  _buildDisplayField('Phone Number', CompanyData.phone, isWide),
                  SizedBox(height: spacing),
                  _buildDisplayField('Website',
                      CompanyData.website.isNotEmpty ? CompanyData.website : '—', isWide),
                  SizedBox(height: spacing),
                  _buildDisplayField('Admin Full Name', CompanyData.adminName, isWide),
                  SizedBox(height: spacing),
                  _buildDisplayField('Admin Designation', CompanyData.adminRole, isWide),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayField(String label, String value, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isWide ? 16 : 14)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: isWide ? 18 : 16)),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
