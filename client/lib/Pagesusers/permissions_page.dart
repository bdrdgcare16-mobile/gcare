// // import 'package:flutter/material.dart';
// // import 'package:permission_handler/permission_handler.dart';

// // class PermissionsPage extends StatefulWidget {
// //   const PermissionsPage({super.key});

// //   @override
// //   State<PermissionsPage> createState() => _PermissionsPageState();
// // }

// // class _PermissionsPageState extends State<PermissionsPage> {
// //   // Permissions list to check dynamically
// //   final List<Map<String, dynamic>> _permissionsToCheck = [
// //     {"label": "Location", "permission": Permission.location},
// //     // {"label": "Physical Activity", "permission": Permission.activityRecognition},
// //     // {"label": "Picture and Activity", "permission": Permission.camera},
// //     // {"label": "Notification", "permission": Permission.notification},
// //   ];

// //   // To store current status
// //   Map<String, bool> _statuses = {};

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkAllPermissions();
// //   }

// //   Future<void> _checkAllPermissions() async {
// //     Map<String, bool> temp = {};
// //     for (var item in _permissionsToCheck) {
// //       Permission permission = item["permission"];
// //       var status = await permission.status;
// //       temp[item["label"]] = status.isGranted;
// //     }
// //     setState(() {
// //       _statuses = temp;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: Colors.cyanAccent,
// //         iconTheme: const IconThemeData(color: Colors.black),
// //         title: const Text(
// //           "Permissions",
// //           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
// //         ),
// //         centerTitle: true,
// //       ),
// //       backgroundColor: Colors.white,
// //       body: _statuses.isEmpty
// //           ? const Center(child: CircularProgressIndicator())
// //           : Column(
// //               children: [
// //                 const SizedBox(height: 20),
// //                 const Padding(
// //                   padding: EdgeInsets.symmetric(horizontal: 16),
// //                   child: Row(
// //                     children: [
// //                       Expanded(
// //                         child: Text("Features",
// //                             style: TextStyle(fontWeight: FontWeight.bold)),
// //                       ),
// //                       Expanded(
// //                         child: Text("Allowed / Not Allowed",
// //                             style: TextStyle(fontWeight: FontWeight.bold)),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 const SizedBox(height: 10),
// //                 Expanded(
// //                   child: ListView.builder(
// //                     itemCount: _permissionsToCheck.length,
// //                     itemBuilder: (context, index) {
// //                       final item = _permissionsToCheck[index];
// //                       final String name = item["label"];
// //                       final bool isAllowed = _statuses[name] ?? false;

// //                       return Padding(
// //                         padding: const EdgeInsets.symmetric(
// //                             horizontal: 16, vertical: 6),
// //                         child: Row(
// //                           children: [
// //                             Expanded(
// //                               child: ElevatedButton(
// //                                 onPressed: () {},
// //                                 style: ElevatedButton.styleFrom(
// //                                   backgroundColor: Colors.grey[300],
// //                                   foregroundColor: Colors.black,
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: BorderRadius.circular(8),
// //                                   ),
// //                                 ),
// //                                 child: Text(name),
// //                               ),
// //                             ),
// //                             Expanded(
// //                               child: Icon(
// //                                 isAllowed
// //                                     ? Icons.check_circle
// //                                     : Icons.cancel_outlined,
// //                                 color: isAllowed ? Colors.green : Colors.red,
// //                                 size: 28,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ),
// //                 Container(
// //                   margin: const EdgeInsets.all(12),
// //                   padding:
// //                       const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
// //                   decoration: BoxDecoration(
// //                     border: Border.all(color: Colors.blueAccent),
// //                     borderRadius: BorderRadius.circular(20),
// //                     color: Colors.blue[50],
// //                   ),
// //                   child: const Text(
// //                     'App Version : 0.4.9',
// //                     style: TextStyle(fontWeight: FontWeight.bold),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';

// class PermissionsPage extends StatefulWidget {
//   const PermissionsPage({Key? key}) : super(key: key);

//   @override
//   State<PermissionsPage> createState() => _PermissionsPageState();
// }

// class _PermissionsPageState extends State<PermissionsPage> {
//   Map<Permission, bool> _permissionsStatus = {
//     Permission.location: false,
//     Permission.camera: false,
//     Permission.activityRecognition: false,
//     Permission.notification: false,
//   };

//   @override
//   void initState() {
//     super.initState();
//     _checkAllPermissions();
//   }

//   Future<void> _checkAllPermissions() async {
//     for (var permission in _permissionsStatus.keys) {
//       final status = await permission.status;
//       setState(() {
//         _permissionsStatus[permission] = status.isGranted;
//       });
//     }
//   }

//   Future<void> _requestPermission(Permission permission) async {
//     final result = await permission.request();
//     setState(() {
//       _permissionsStatus[permission] = result.isGranted;
//     });
//   }

//   Widget _buildPermissionTile(Permission permission, String name) {
//     final granted = _permissionsStatus[permission] ?? false;
//     return ListTile(
//       title: Text(name),
//       trailing: Icon(
//         granted ? Icons.check_circle : Icons.cancel,
//         color: granted ? Colors.green : Colors.red,
//       ),
//       onTap: () => _requestPermission(permission),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Permissions"),
//         centerTitle: true,
//       ),
//       body: ListView(
//         children: [
//           const SizedBox(height: 16),
//           _buildPermissionTile(Permission.location, "Location Permission"),
//           _buildPermissionTile(Permission.camera, "Camera Permission"),
//           _buildPermissionTile(Permission.activityRecognition, "Activity Recognition"),
//           _buildPermissionTile(Permission.notification, "Notification Permission"),
//           const SizedBox(height: 24),
//           Center(
//             child: ElevatedButton(
//               onPressed: _checkAllPermissions,
//               child: const Text("Check Again"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Theme Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> with WidgetsBindingObserver {
  final Map<Permission, bool> _permissionsStatus = {
    Permission.location: false,
    Permission.camera: false,
    Permission.activityRecognition: false,
    Permission.notification: false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    for (var permission in _permissionsStatus.keys) {
      final status = await permission.status;
      setState(() {
        _permissionsStatus[permission] = status.isGranted;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final result = await permission.request();
    setState(() {
      _permissionsStatus[permission] = result.isGranted;
    });
    if (result.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Permission permanently denied. Please enable from settings."),
          action: SnackBarAction(
            label: "Open Settings",
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  IconData _getIcon(Permission permission) {
    switch (permission) {
      case Permission.location:
        return Icons.location_on;
      case Permission.camera:
        return Icons.camera_alt;
      case Permission.activityRecognition:
        return Icons.directions_run;
      case Permission.notification:
        return Icons.notifications_active;
      default:
        return Icons.security;
    }
  }

  Widget _buildPermissionTile(Permission permission, String label) {
    final granted = _permissionsStatus[permission] ?? false;
    return ListTile(
      leading: Icon(_getIcon(permission), color: granted ? Colors.green : Colors.grey),
      title: Text(label),
      trailing: Icon(
        granted ? Icons.check_circle : Icons.cancel,
        color: granted ? Colors.green : Colors.red,
      ),
      onTap: () => _requestPermission(permission),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Permissions"),
        centerTitle: true,
        backgroundColor: kAppBarColor,
      ),
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
        child: ListView(
          children: [
            const SizedBox(height: 16),
            _buildPermissionTile(Permission.location, "Location Permission"),
            _buildPermissionTile(Permission.camera, "Camera Permission"),
            _buildPermissionTile(Permission.activityRecognition, "Activity Recognition"),
            _buildPermissionTile(Permission.notification, "Notification Permission"),
            const SizedBox(height: 24),
          //   Center(
          //     child: ElevatedButton(
          //       onPressed: _checkAllPermissions,
          //       child: const Text("Check Again"),
          //     ),
          //   ),
          ],
         ),
      ),
    );
  }
}
