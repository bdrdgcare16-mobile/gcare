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

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
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
          content: const Text(
              "Permission permanently denied. Please enable from settings."),
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
      leading: Icon(_getIcon(permission),
          color: granted ? Colors.green : Colors.grey),
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
        centerTitle: false,
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
            _buildPermissionTile(
                Permission.activityRecognition, "Activity Recognition"),
            _buildPermissionTile(
                Permission.notification, "Notification Permission"),
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
