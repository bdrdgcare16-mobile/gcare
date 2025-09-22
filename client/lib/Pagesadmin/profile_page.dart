import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// Web-only storage shims (safe on non-web due to conditional import)
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

import 'package:serv_app/models/company_data.dart'; // shared model with static fields

// ===== Theme colors (unchanged) =====
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

// ===== Backend base (same as the rest of the app) =====
const String _apiBase = 'https://api-zmj7dqloiq-el.a.run.app/api';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  bool _isEditing = false;
  bool _loading = false;
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _adminNameCtrl;
  late final TextEditingController _adminRoleCtrl;

  final ImagePicker _picker = ImagePicker();
  XFile? _logoFile; // persisted via CompanyData too
  Uint8List? _logoBytes; // for avatar preview

  @override
  void initState() {
    super.initState();

    // Seed from CompanyData so the UI has something immediately.
    _logoFile = CompanyData.logoFile;
    _nameCtrl = TextEditingController(text: CompanyData.companyName);
    _emailCtrl = TextEditingController(text: CompanyData.email);
    _phoneCtrl = TextEditingController(text: CompanyData.phone);
    _websiteCtrl = TextEditingController(text: CompanyData.website);
    _adminNameCtrl = TextEditingController(text: CompanyData.adminName);
    _adminRoleCtrl = TextEditingController(text: CompanyData.adminRole);

    _loadInitialLogoBytes();

    // Fetch from API (uses token's email as doc id on the server)
    _fetchProfile();
  }

  // ----- STORAGE / TOKEN HELPERS -----
  String? _readToken() {
    final t = (CompanyData.token).toString();
    if (t.isNotEmpty && t != 'null') return t;

    if (kIsWeb) {
      final t1 = html.window.localStorage['token'];
      if (t1 != null && t1.trim().isNotEmpty) return t1;
      final t2 = html.window.sessionStorage['token'];
      if (t2 != null && t2.trim().isNotEmpty) return t2;
    }
    return null;
  }

  Map<String, String> _authHeaders({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    final tok = _readToken();
    if (tok != null && tok.isNotEmpty) h['Authorization'] = 'Bearer $tok';
    return h;
  }

  // ----- LOGO PREVIEW -----
  Future<void> _loadInitialLogoBytes() async {
    try {
      if (_logoFile != null) {
        final bytes = await _logoFile!.readAsBytes();
        if (mounted) setState(() => _logoBytes = bytes);
      }
    } catch (_) {
      // ignore preview errors
    }
  }

  // ----- API: FETCH PROFILE -----
  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/company/profile'),
        headers: _authHeaders(json: true),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = (body['data'] ?? {}) as Map<String, dynamic>;

        // Map server -> UI fields
        final companyName = (data['companyName'] ?? '').toString();
        final email = (data['email'] ?? '').toString();
        final phone = (data['phone'] ?? '').toString();
        final website = (data['website'] ?? '').toString();
        final adminName = (data['adminName'] ?? '').toString();
        final designation = (data['designation'] ?? '').toString();

        // Optional image: server may store logoBase64 OR logoUrl
        Uint8List? logoBytes;
        final String logoBase64 = (data['logoBase64'] ?? '').toString();
        if (logoBase64.isNotEmpty) {
          // strip any "data:image/*;base64," prefix
          final pure = logoBase64.split('base64,').last;
          try {
            logoBytes = base64Decode(pure);
          } catch (_) {}
        }

        // Update controllers and memory model
        _nameCtrl.text = companyName;
        _emailCtrl.text = email;
        _phoneCtrl.text = phone;
        _websiteCtrl.text = website;
        _adminNameCtrl.text = adminName;
        _adminRoleCtrl.text = designation;

        CompanyData.companyName = companyName;
        CompanyData.email = email;
        CompanyData.phone = phone;
        CompanyData.website = website;
        CompanyData.adminName = adminName;
        CompanyData.adminRole = designation;

        if (logoBytes != null) {
          setState(() => _logoBytes = logoBytes);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile loaded')),
          );
        }
      } else if (res.statusCode == 404) {
        // No profile yet — keep existing seed values
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No profile found.')),
          );
        }
      } else if (res.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Unauthorized. Please sign in again.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Load failed: ${res.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ----- API: SAVE PROFILE -----
  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final uri = Uri.parse('$_apiBase/company/profile');
      final req = http.MultipartRequest('POST', uri);

      // Auth header only; MultipartRequest sets its own content-type
      final tok = _readToken();
      if (tok != null && tok.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $tok';
      }

      // Fields expected by backend
      req.fields['companyName'] = _nameCtrl.text.trim();
      req.fields['email'] = _emailCtrl.text.trim();
      req.fields['phone'] = _phoneCtrl.text.trim();
      req.fields['website'] = _websiteCtrl.text.trim();
      req.fields['adminName'] = _adminNameCtrl.text.trim();
      req.fields['designation'] = _adminRoleCtrl.text.trim();

      // Optional logo file — multer looks for 'logo'
      if (_logoFile != null) {
        final bytes = await _logoFile!.readAsBytes();
        final filename = _logoFile!.name; // works on web & mobile
        req.files.add(
          http.MultipartFile.fromBytes('logo', bytes, filename: filename),
        );
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200) {
        // Persist back to CompanyData so the rest of the app can read it
        CompanyData.logoFile = _logoFile;
        CompanyData.companyName = _nameCtrl.text.trim();
        CompanyData.email = _emailCtrl.text.trim();
        CompanyData.phone = _phoneCtrl.text.trim();
        CompanyData.website = _websiteCtrl.text.trim();
        CompanyData.adminName = _adminNameCtrl.text.trim();
        CompanyData.adminRole = _adminRoleCtrl.text.trim();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved')),
          );
        }
      } else {
        // Surface server error message if any
        String msg = 'Save failed: ${res.statusCode}';
        try {
          final b = jsonDecode(res.body);
          msg = (b['message'] ?? b['error'] ?? msg).toString();
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ----- UI actions (unchanged look) -----
  Future<void> _pickLogo() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _logoFile = picked;
        _logoBytes = bytes;
      });
    }
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // On save click (✓): call API first, then persist locally and exit edit mode.
      await _saveProfile();
    } else {
      // entering edit mode — no-op
    }
    if (mounted) setState(() => _isEditing = !_isEditing);
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

  // ----- BUILD (UI preserved) -----
  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;
    final double spacing = isWide ? 24.0 : 16.0;

    ImageProvider<Object>? avatar =
        (_logoBytes != null) ? MemoryImage(_logoBytes!) : null;

    return Scaffold(
      backgroundColor: kPrimaryBackgroundTop,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        title:
            const Text('Company Profile', style: TextStyle(color: kTextColor)),
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          IconButton(
            icon: (_isEditing
                ? (_saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kTextColor,
                        ),
                      )
                    : const Icon(Icons.check, color: kTextColor))
                : const Icon(Icons.edit, color: kTextColor)),
            onPressed: _saving ? null : _toggleEdit,
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
                              ? const Icon(Icons.apartment,
                                  size: 36, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          child: InkWell(
                            onTap: _pickLogo,
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: kButtonColor,
                              child: Icon(Icons.camera_alt,
                                  size: 16, color: kTextColor),
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
                          ? const Icon(Icons.apartment,
                              size: 36, color: Colors.grey)
                          : null,
                    ),
                  ),
                SizedBox(height: spacing),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  (_isEditing
                      ? Column(
                          children: [
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
                            _buildEditField(
                                'Admin Designation', _adminRoleCtrl),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDisplayField(
                                'Company Name', _nameCtrl.text, isWide),
                            SizedBox(height: spacing),
                            _buildDisplayField(
                                'Official Email', _emailCtrl.text, isWide),
                            SizedBox(height: spacing),
                            _buildDisplayField(
                                'Phone Number', _phoneCtrl.text, isWide),
                            SizedBox(height: spacing),
                            _buildDisplayField(
                                'Website',
                                _websiteCtrl.text.isNotEmpty
                                    ? _websiteCtrl.text
                                    : '—',
                                isWide),
                            SizedBox(height: spacing),
                            _buildDisplayField(
                                'Admin Full Name', _adminNameCtrl.text, isWide),
                            SizedBox(height: spacing),
                            _buildDisplayField('Admin Designation',
                                _adminRoleCtrl.text, isWide),
                          ],
                        )),
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
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: isWide ? 16 : 14)),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
