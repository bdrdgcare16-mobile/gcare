import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_service.dart';
import 'package:serv_app/features/platform_admin/pa_ui.dart';

import 'platform_admin_shell.dart';

/// Platform Admin (platform_admin) — tenant management.
/// Lists companies, and creates/edits tenant entitlement:
/// maxUsers + enabledFeatures + status.
class SuperAdminCompaniesPage extends StatefulWidget {
  const SuperAdminCompaniesPage({super.key});

  @override
  State<SuperAdminCompaniesPage> createState() =>
      _SuperAdminCompaniesPageState();
}

class _SuperAdminCompaniesPageState extends State<SuperAdminCompaniesPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _catalog = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCompanies {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _companies;
    bool hit(dynamic v) => (v ?? '').toString().toLowerCase().contains(q);
    return _companies
        .where(
          (c) =>
              hit(c['companyName']) ||
              hit(c['name']) ||
              hit(c['companyId']) ||
              hit(c['adminName']) ||
              hit(c['adminEmail']),
        )
        .toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PlatformAdminService.listCompanies(),
        PlatformAdminService.getFeatureCatalog(),
      ]);
      if (!mounted) return;
      setState(() {
        _companies = results[0];
        _catalog = results[1];
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

  String _labelFor(String key) {
    for (final f in _catalog) {
      if (f['key'] == key) return f['label']?.toString() ?? key;
    }
    return key;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyFormPage(catalog: _catalog),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> company) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyFormPage(catalog: _catalog, company: company),
      ),
    );
    if (updated == true) _load();
  }

  Widget _buildCompanyRow(Map<String, dynamic> c) {
    final features = c['enabledFeatures'];
    final isLegacy = c['isLegacy'] == true;
    final maxUsers = c['maxUsers'];
    final currentUsers = c['currentUsers'] ?? 0;
    final status = c['status']?.toString() ?? 'active';

    return PaListRow(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PaColors.soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business_outlined,
                    size: 19, color: PaColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['companyName']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: PaColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ID: ${c['companyId'] ?? '-'}'
                      '${(c['adminEmail'] ?? '').toString().isNotEmpty ? '  ·  ${c['adminName'] ?? ''} <${c['adminEmail']}>' : ''}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: PaColors.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PaBadge(text: status, color: paStatusColor(status)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 15, color: PaColors.muted),
              const SizedBox(width: 5),
              Text(
                maxUsers == null
                    ? '$currentUsers users · unlimited'
                    : '$currentUsers / $maxUsers users',
                style: const TextStyle(
                  fontSize: 12,
                  color: PaColors.text,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: isLegacy
                    ? const Text(
                        'All features (not yet configured)',
                        style: TextStyle(
                          fontSize: 11,
                          color: PaColors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : features is List && features.isNotEmpty
                        ? Text(
                            '${features.length} feature${features.length == 1 ? '' : 's'} enabled',
                            style: const TextStyle(
                              fontSize: 11,
                              color: PaColors.muted,
                            ),
                          )
                        : const Text(
                            'No features enabled',
                            style: TextStyle(
                              fontSize: 11,
                              color: PaColors.danger,
                            ),
                          ),
              ),
              PaOutlineButton(
                label: 'View / Edit',
                icon: Icons.edit_outlined,
                onPressed: () => _openEdit(c),
              ),
            ],
          ),
          if (!isLegacy && features is List && features.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: features
                  .take(8)
                  .map<Widget>(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PaColors.soft,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _labelFor(f.toString()),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: PaColors.deep,
                        ),
                      ),
                    ),
                  )
                  .toList()
                ..addAll(features.length > 8
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '+${features.length - 8} more',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: PaColors.muted,
                            ),
                          ),
                        ),
                      ]
                    : const []),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminShell(
      selected: PlatformAdminSection.companies,
      title: 'Companies',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: PaColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('New Company',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: paInputDecoration(
                'Search companies, IDs or admins…',
                prefixIcon: Icons.search,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 16, color: PaColors.muted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: PaColors.primary,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: PaColors.primary))
                  : _error != null
                      ? ListView(children: [
                          PaErrorState(message: _error!, onRetry: _load)
                        ])
                      : _filteredCompanies.isEmpty
                          ? ListView(
                              children: [
                                PaEmptyState(
                                  message: _companies.isEmpty
                                      ? 'No companies yet'
                                      : 'No companies match "$_query"',
                                  icon: Icons.business_outlined,
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(28, 12, 28, 80),
                              itemCount: _filteredCompanies.length,
                              itemBuilder: (_, i) =>
                                  _buildCompanyRow(_filteredCompanies[i]),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Create / edit a company tenant (Platform Admin only).
class CompanyFormPage extends StatefulWidget {
  final List<Map<String, dynamic>> catalog;
  final Map<String, dynamic>? company; // null => create mode

  const CompanyFormPage({super.key, required this.catalog, this.company});

  @override
  State<CompanyFormPage> createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends State<CompanyFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyIdCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPhoneCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();
  final _maxUsersCtrl = TextEditingController();

  String _status = 'active';
  final Set<String> _selected = {};
  bool _saving = false;
  bool _obscurePassword = true;

  bool get _isEdit => widget.company != null;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    if (c != null) {
      _companyIdCtrl.text = c['companyId']?.toString() ?? '';
      _companyNameCtrl.text = c['companyName']?.toString() ?? '';
      _adminNameCtrl.text = c['adminName']?.toString() ?? '';
      _adminEmailCtrl.text = c['adminEmail']?.toString() ?? '';
      _adminPhoneCtrl.text = c['adminPhone']?.toString() ?? '';
      _maxUsersCtrl.text = c['maxUsers']?.toString() ?? '';
      _status = c['status']?.toString() ?? 'active';
      final feats = c['enabledFeatures'];
      if (feats is List) {
        _selected.addAll(feats.map((e) => e.toString()));
      } else {
        // Legacy tenant (no enabledFeatures stored): every feature is
        // effectively enabled, so pre-check the whole catalog. Otherwise a
        // simple name edit would persist [] and strip all access.
        _selected.addAll(
          widget.catalog
              .map((f) => f['key']?.toString() ?? '')
              .where((k) => k.isNotEmpty),
        );
      }
    }
  }

  @override
  void dispose() {
    _companyIdCtrl.dispose();
    _companyNameCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPhoneCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _maxUsersCtrl.dispose();
    super.dispose();
  }

  List<String> _requiresOf(String key) {
    for (final f in widget.catalog) {
      if (f['key'] == key) {
        final r = f['requires'];
        return r is List ? r.map((e) => e.toString()).toList() : [];
      }
    }
    return [];
  }

  String _labelFor(String key) {
    for (final f in widget.catalog) {
      if (f['key'] == key) return f['label']?.toString() ?? key;
    }
    return key;
  }

  void _onToggle(String key, bool enable) {
    if (enable) {
      // Auto-enable the whole dependency chain, so selecting e.g.
      // Location Tracking also grants Employee Management + Attendance.
      // The backend re-validates the selection (requireFeature /
      // validateFeatureSelection) — this is UX convenience only.
      final autoAdded = <String>[];
      final queue = <String>[key];
      while (queue.isNotEmpty) {
        final k = queue.removeLast();
        if (k.isEmpty || _selected.contains(k)) continue;
        _selected.add(k);
        if (k != key) autoAdded.add(k);
        queue.addAll(_requiresOf(k));
      }
      setState(() {});
      if (autoAdded.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Also enabled: ${autoAdded.map(_labelFor).join(', ')}',
            ),
          ),
        );
      }
    } else {
      // Block disabling a feature that other selected features depend on.
      final dependents = widget.catalog
          .where((f) =>
              _selected.contains(f['key']) &&
              (f['requires'] as List?)
                      ?.map((e) => e.toString())
                      .contains(key) ==
                  true)
          .map((f) => f['label']?.toString() ?? f['key'].toString())
          .toList();
      if (dependents.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot disable ${_labelFor(key)} — required by ${dependents.join(', ')}.',
            ),
          ),
        );
        return;
      }
      setState(() => _selected.remove(key));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final maxUsersText = _maxUsersCtrl.text.trim();
    final maxUsers = maxUsersText.isEmpty ? null : int.tryParse(maxUsersText);
    if (maxUsersText.isNotEmpty && (maxUsers == null || maxUsers <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Maximum Users must be a positive number')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await PlatformAdminService.updateCompany(_companyIdCtrl.text.trim(), {
          'companyName': _companyNameCtrl.text.trim(),
          'adminName': _adminNameCtrl.text.trim(),
          'adminPhone': _adminPhoneCtrl.text.trim(),
          'maxUsers': maxUsers,
          'status': _status,
          // Only send enabledFeatures when the catalog loaded — otherwise an
          // empty list would strip a legacy tenant's access.
          if (widget.catalog.isNotEmpty) 'enabledFeatures': _selected.toList(),
        });
      } else {
        await PlatformAdminService.createCompany(
          companyId: _companyIdCtrl.text.trim(),
          companyName: _companyNameCtrl.text.trim(),
          adminName: _adminNameCtrl.text.trim(),
          adminEmail: _adminEmailCtrl.text.trim(),
          adminPhone: _adminPhoneCtrl.text.trim(),
          adminPassword: _adminPasswordCtrl.text,
          maxUsers: maxUsers,
          enabledFeatures: _selected.toList(),
          status: _status,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Company updated' : 'Company created',
          ),
          backgroundColor: Colors.green,
        ),
      );
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

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: PaColors.deep,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: PaColors.muted),
            ),
          ),
      ],
    );
  }

  Widget _featureTile(Map<String, dynamic> f) {
    final key = f['key']?.toString() ?? '';
    final requires = _requiresOf(key);
    final checked = _selected.contains(key);
    return PaHover(
      onTap: () => _onToggle(key, !checked),
      builder: (context, hovering) => AnimatedContainer(
        duration: kPaAnim,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: checked
              ? PaColors.soft.withValues(alpha: 0.6)
              : hovering
                  ? PaColors.bg
                  : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checked
                ? PaColors.primary.withValues(alpha: 0.45)
                : PaColors.border,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: kPaAnim,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? PaColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? PaColors.primary : PaColors.muted,
                  width: 1.4,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelFor(key),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: PaColors.text,
                    ),
                  ),
                  if (requires.isNotEmpty)
                    Text(
                      'Requires: ${requires.map(_labelFor).join(', ')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: PaColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaColors.bg,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Company' : 'New Company',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: PaColors.text,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: PaColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: PaColors.border),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Company Details'),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _companyIdCtrl,
                          enabled: !_isEdit,
                          decoration: paInputDecoration('',
                              label: 'Company ID', prefixIcon: Icons.tag),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (!_isEdit && s.isEmpty) return 'Required';
                            if (!_isEdit &&
                                !RegExp(r'^[A-Za-z0-9_-]{2,32}$').hasMatch(s)) {
                              return '2-32 chars: letters, digits, - or _';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _companyNameCtrl,
                          decoration: paInputDecoration('',
                              label: 'Company Name',
                              prefixIcon: Icons.business),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _adminNameCtrl,
                          decoration: paInputDecoration('',
                              label: 'Admin Name',
                              prefixIcon: Icons.person_outline),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _adminEmailCtrl,
                          enabled: !_isEdit,
                          keyboardType: TextInputType.emailAddress,
                          decoration: paInputDecoration('',
                              label: 'Admin Email',
                              prefixIcon: Icons.mail_outline),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (!_isEdit && s.isEmpty) return 'Required';
                            if (!_isEdit &&
                                !RegExp(r"^[\w._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$",
                                        caseSensitive: false)
                                    .hasMatch(s)) {
                              return 'Enter valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _adminPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: paInputDecoration('',
                              label: 'Admin Phone',
                              prefixIcon: Icons.phone_outlined),
                        ),
                        if (!_isEdit) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _adminPasswordCtrl,
                            obscureText: _obscurePassword,
                            decoration: paInputDecoration('',
                                    label: 'Admin Password',
                                    prefixIcon: Icons.lock_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  size: 20,
                                  color: PaColors.muted,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if ((v ?? '').length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Subscription / Feature Access'),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _maxUsersCtrl,
                          keyboardType: TextInputType.number,
                          decoration: paInputDecoration('',
                              label: 'Maximum Users (blank = unlimited)',
                              prefixIcon: Icons.people_outline),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: paInputDecoration('',
                              label: 'Status',
                              prefixIcon: Icons.toggle_on_outlined),
                          items: const [
                            DropdownMenuItem(
                                value: 'active', child: Text('Active')),
                            DropdownMenuItem(
                                value: 'suspended', child: Text('Suspended')),
                            DropdownMenuItem(
                                value: 'inactive', child: Text('Inactive')),
                          ],
                          onChanged: (v) =>
                              setState(() => _status = v ?? 'active'),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle(
                          'Enabled Features',
                          subtitle:
                              'Dependencies are auto-enabled; required features cannot be removed.',
                        ),
                        const SizedBox(height: 10),
                        for (final f in widget.catalog) _featureTile(f),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PaColors.muted,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: PaColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PaColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Save Changes' : 'Create Company',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
