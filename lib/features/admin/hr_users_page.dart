import 'package:flutter/material.dart';
import 'package:serv_app/services/hr_user_service.dart';

const Color _kPurple = Color(0xFF8C6EAF);
const Color _kDark = Color(0xFF655193);
const Color _kBg = Color(0xFFF5F0FF);

/// Company Admin — HR user management.
///
/// Lists the HR-labelled users created for this company and creates new
/// ones. Accounts created here are stored with authorization role 'admin'
/// plus a non-authoritative displayRole 'hr' marker (legacy 'hr' accounts
/// remain listed); each is bound to a branch and department. Creation is
/// enforced server-side by roleMiddleware(['admin', 'company_admin']) and
/// the company's maxUsers entitlement.
class HrUsersPage extends StatefulWidget {
  const HrUsersPage({super.key});

  @override
  State<HrUsersPage> createState() => _HrUsersPageState();
}

class _HrUsersPageState extends State<HrUsersPage> {
  List<Map<String, dynamic>> _hrUsers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await HrUserService.listHrUsers();
      if (!mounted) return;
      setState(() {
        _hrUsers = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HrUserFormPage()),
    );
    if (created == true) _load();
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final name = u['name']?.toString() ?? '-';
    final email = u['email']?.toString() ?? '-';
    final branch = u['branch']?.toString() ?? '-';
    final department = u['department']?.toString() ?? '-';
    final status = u['status']?.toString() ?? 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEDE7F6),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'H',
              style: const TextStyle(
                color: _kDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _chip(Icons.location_on_outlined, branch),
                    _chip(Icons.work_outline, department),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'active' ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _kDark),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New HR User'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'HR Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D1B4E),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Create branch/department HR logins for your company.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _hrUsers.isEmpty
                            ? ListView(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(48),
                                    child: Center(
                                      child: Text(
                                        'No HR users yet.\nTap "New HR User" to create one.',
                                        textAlign: TextAlign.center,
                                        style:
                                            TextStyle(color: Colors.black54),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                itemCount: _hrUsers.length,
                                itemBuilder: (_, i) =>
                                    _buildUserCard(_hrUsers[i]),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create a single HR user (Company Admin only).
class HrUserFormPage extends StatefulWidget {
  const HrUserFormPage({super.key});

  @override
  State<HrUserFormPage> createState() => _HrUserFormPageState();
}

class _HrUserFormPageState extends State<HrUserFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _branchCtrl.dispose();
    _departmentCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kDark),
      ),
    );
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    final re = RegExp(r"^[\w._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$",
        caseSensitive: false);
    return re.hasMatch(s) ? null : 'Enter a valid email';
  }

  Future<void> _showCredentials(
    String email,
    String tempPassword,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HR User Created'),
        content: SelectableText(
          'Share these credentials with the HR user.\n\n'
          'Email: $email\n'
          'Temporary password: $tempPassword\n\n'
          'They will be asked to change it on first login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final res = await HrUserService.createHrUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        branch: _branchCtrl.text.trim(),
        department: _departmentCtrl.text.trim(),
        password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
      );
      if (!mounted) return;

      final tempPassword = res['tempPassword']?.toString();
      if (tempPassword != null && tempPassword.isNotEmpty) {
        await _showCredentials(_emailCtrl.text.trim(), tempPassword);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HR user created'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: const Text(
          'New HR User',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6F52A3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HR Account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    _decoration('Full Name', icon: Icons.person_outline),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    _decoration('Email', icon: Icons.mail_outline),
                validator: _validateEmail,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    _decoration('Phone (optional)', icon: Icons.phone_outlined),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assignment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _branchCtrl,
                decoration: _decoration('Branch',
                    icon: Icons.location_on_outlined,
                    hint: 'e.g. Chennai'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _departmentCtrl,
                decoration: _decoration('Department',
                    icon: Icons.work_outline, hint: 'e.g. Operations'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Credentials',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: _decoration(
                  'Password (optional)',
                  icon: Icons.lock_outline,
                  hint: 'Leave empty to auto-generate',
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: _kPurple,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  final s = (v ?? '');
                  if (s.isEmpty) return null; // server generates one
                  if (s.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create HR User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
