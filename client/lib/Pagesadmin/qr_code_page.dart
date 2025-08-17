import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';

const Color kPrimaryBackgroundTop    = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor             = Color(0xFF8C6EAF);
const Color kButtonColor             = Color(0xFF655193);
const Color kTextColor               = Colors.white;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SERV QR Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const OrganizationQrPage(),
    );
  }
}

class OrganizationQrPage extends StatefulWidget {
  const OrganizationQrPage({super.key});

  @override
  State<OrganizationQrPage> createState() => _OrganizationQrPageState();
}

class _OrganizationQrPageState extends State<OrganizationQrPage> {
  final List<String> _locations = ['Pudur', 'Anna Nagar', 'MG Road'];
  final List<String> _qrTypes = ['Check-in', 'Check-out'];

  String _selectedLocation = '';
  String _selectedType = '';
  final int _qrId = 0;
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey _globalKey = GlobalKey();

  String get _qrPayload =>
      '{"location":"$_selectedLocation","type":"$_selectedType","name":"${_nameController.text}","id":$_qrId}';

  Future<void> _downloadQrCode() async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }

      // Capture QR code as image
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery using Gal package
      await Gal.putImageBytes(pngBytes);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code saved to gallery successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('QR Code'),
        backgroundColor: kAppBarColor,
        foregroundColor: kTextColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Organization QR Code',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF323E42),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _downloadQrCode,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("Download", overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: kButtonColor,
                      foregroundColor: kTextColor,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Employee Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      value: _selectedLocation.isNotEmpty ? _selectedLocation : null,
                      items: _locations
                          .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'QR Type',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      value: _selectedType.isNotEmpty ? _selectedType : null,
                      items: _qrTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildQrCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard() => Card(
    clipBehavior: Clip.antiAlias,
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SERV',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: const Color(0xFF323E42),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Welcome to SERV'),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _globalKey,
            child: QrImageView(
              data: _qrPayload,
              version: QrVersions.auto,
              size: 200,
              gapless: false,
            ),
          ),
          const SizedBox(height: 16),
          Text('QR Type : ${_selectedType.isNotEmpty ? _selectedType : 'Not selected'}'),
          Text('QR ID : $_qrId'),
          Text('Location : ${_selectedLocation.isNotEmpty ? _selectedLocation : 'Not selected'}'),
          Text(
            'Name : ${_nameController.text.isNotEmpty ? _nameController.text : 'Not entered'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF323E42),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}