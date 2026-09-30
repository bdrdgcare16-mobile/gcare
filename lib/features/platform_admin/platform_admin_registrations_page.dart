// lib/features/platform_admin/platform_admin_registrations_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_registration_service.dart';

import 'platform_admin_theme.dart';

/// Platform Admin review list for organization registration
/// applications (Milestones 3D-B/C/D). Tabs map to application statuses:
/// Pending → pending_approval, Approved → approved (not yet activated),
/// Rejected → rejected, Changes Requested → changes_requested,
/// Activated → activated, All Applications → no filter.
/// Decisions and activation are made on the detail page.
class PlatformAdminRegistrationsPage extends StatefulWidget {
  const PlatformAdminRegistrationsPage({super.key});

  @override
  State<PlatformAdminRegistrationsPage> createState() =>
      _PlatformAdminRegistrationsPageState();
}

class _PlatformAdminRegistrationsPageState
    extends State<PlatformAdminRegistrationsPage> {
  static const _tabs = <(String, String?)>[
    ('Pending', 'pending_approval'),
    ('Approved', 'approved'),
    ('Rejected', 'rejected'),
    ('Changes Requested', 'changes_requested'),
    ('Activated', 'activated'),
    ('All Applications', null),
  ];

  static const _sorts = <(String, String)>[
    ('Newest first', 'createdAt'),
    ('Submission date', 'submittedAt'),
  ];

  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _tabIndex = 0;
  int _page = 1;
  bool _hasMore = false;
  String _sort = 'createdAt';
  String _search = '';
  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result =
          await PlatformAdminRegistrationService.instance.listRegistrations(
        status: _tabs[_tabIndex].$2,
        search: _search.isEmpty ? null : _search,
        sort: _sort,
        page: _page,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items = (result['registrations'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _hasMore = result['hasMore'] == true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _fetch();
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try {
      final d = v is String
          ? DateTime.parse(v)
          : (v is Map && v['_seconds'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(
                  (v['_seconds'] as int) * 1000)
              : null;
      if (d == null) return '—';
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  (Color, Color) _statusColors(String status) {
    switch (status) {
      case 'pending_approval':
        return (PlatformAdminColors.amberBg, PlatformAdminColors.amberFg);
      case 'approved':
        return (PlatformAdminColors.greenBg, PlatformAdminColors.greenFg);
      case 'rejected':
        return (PlatformAdminColors.redBg, PlatformAdminColors.redFg);
      case 'changes_requested':
        return (PlatformAdminColors.blueBg, PlatformAdminColors.blueFg);
      case 'pending_verification':
        return (PlatformAdminColors.blueBg, PlatformAdminColors.blueFg);
      case 'activated':
        return (PlatformAdminColors.purpleBg, PlatformAdminColors.purpleFg);
      default:
        return (PlatformAdminColors.grayBg, PlatformAdminColors.grayFg);
    }
  }

  static const _statusLabels = <String, String>{
    'draft': 'Draft',
    'submitted': 'Submitted',
    'pending_verification': 'Pending Verification',
    'pending_approval': 'Pending Approval',
    'changes_requested': 'Changes Requested',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'activated': 'Activated',
  };

  Widget _statusBadge(String status) {
    final (bg, fg) = _statusColors(status);
    return PlatformAdminStatusBadge(
      label: (_statusLabels[status] ?? status).toUpperCase(),
      background: bg,
      foreground: fg,
    );
  }

  /// Purple RESUBMITTED badge + revision — only when the application
  /// has been through at least one changes_requested → resubmit cycle.
  Widget _resubmissionBadge(Map<String, dynamic> item) {
    final count =
        (item['resubmissionCount'] as num?)?.toInt() ?? 0;
    if (count <= 0) return const SizedBox.shrink();
    final changed =
        (item['changedFieldsCount'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlatformAdminStatusBadge(
            label: 'RESUBMITTED • REVISION ${count + 1}',
            background: PlatformAdminColors.purpleBg,
            foreground: PlatformAdminColors.purpleFg,
          ),
          if (changed > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '$changed ${changed == 1 ? 'field' : 'fields'} updated',
                style: const TextStyle(
                  fontSize: 11,
                  color: PlatformAdminColors.purpleFg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> item) {
    final contact = item['adminContact'] as Map? ?? {};
    final features =
        (item['requestedFeatures'] as List? ?? const []).join(', ');
    return PlatformAdminCard(
      hoverable: true,
      margin: const EdgeInsets.only(bottom: 10),
      radius: PlatformAdminRadii.cardSmall,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['organizationName']?.toString() ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PlatformAdminColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ref: ${item['registrationId'] ?? '—'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: PlatformAdminColors.textMuted,
                  ),
                ),
                if (item['status'] == 'activated') ...[
                  const SizedBox(height: 2),
                  Text(
                    'Code: ${item['organizationCode'] ?? '—'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: PlatformAdminColors.purpleFg,
                    ),
                  ),
                  Text(
                    'Activated: ${_fmtDate(item['activatedAt'])}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: PlatformAdminColors.textMuted,
                    ),
                  ),
                ],
                _resubmissionBadge(item),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              contact['fullName']?.toString() ?? '—',
              style: const TextStyle(
                fontSize: 12,
                color: PlatformAdminColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(item['submittedAt']),
              style: const TextStyle(
                fontSize: 12,
                color: PlatformAdminColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              features.isEmpty ? '—' : features,
              style: const TextStyle(
                fontSize: 11,
                color: PlatformAdminColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(item['status']?.toString() ?? ''),
            ),
          ),
          SizedBox(
            width: 140,
            child: OutlinedButton(
              style: PlatformAdminButtonStyles.secondary(),
              onPressed: () {
                final id = item['registrationId']?.toString();
                if (id == null || id.isEmpty) return;
                Navigator.of(context).pushNamed(
                  '/platform-admin/registrations/$id',
                );
              },
              child: const Text('View Application'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(int i) {
    final selected = _tabIndex == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(_tabs[i].$1),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _tabIndex = i;
            _page = 1;
          });
          _fetch();
        },
        showCheckmark: false,
        selectedColor: PlatformAdminColors.primarySoft,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlatformAdminRadii.pill),
          side: BorderSide(
            color: selected
                ? PlatformAdminColors.primary
                : PlatformAdminColors.border,
          ),
        ),
        labelStyle: TextStyle(
          color: selected
              ? PlatformAdminColors.primary
              : PlatformAdminColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + tabs
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlatformAdminSectionHeader(
                title: 'Organization Registrations',
                subtitle: 'Open an application to record a review decision.',
              ),
              const SizedBox(height: 14),
              Wrap(
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _tabs.length; i++) _tabChip(i),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                  // Search
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search organization…',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _search = '';
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              PlatformAdminRadii.control),
                          borderSide: const BorderSide(
                              color: PlatformAdminColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              PlatformAdminRadii.control),
                          borderSide: const BorderSide(
                              color: PlatformAdminColors.primary, width: 1.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (v) {
                        _search = v.trim();
                        _applyFilters();
                      },
                    ),
                  ),
                  // Sort
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sort,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sort by',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              PlatformAdminRadii.control),
                          borderSide: const BorderSide(
                              color: PlatformAdminColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              PlatformAdminRadii.control),
                          borderSide: const BorderSide(
                              color: PlatformAdminColors.primary, width: 1.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      items: _sorts
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s.$2,
                              child: Text(
                                s.$1,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        _sort = v;
                        _applyFilters();
                      },
                    ),
                  ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        const Divider(height: 1, color: PlatformAdminColors.border),

        // Body
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetch,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: PlatformAdminColors.redFg),
                        ),
                      ),
                    )
                  else if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Text(
                          'No registration applications found',
                          style: TextStyle(
                              color: PlatformAdminColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (final item in _items) _buildRow(item),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        style: PlatformAdminButtonStyles.secondary(),
                        onPressed: _page > 1 && !_isLoading
                            ? () {
                                setState(() => _page -= 1);
                                _fetch();
                              }
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Page $_page',
                        style: const TextStyle(
                            color: PlatformAdminColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: PlatformAdminButtonStyles.secondary(),
                        onPressed: _hasMore && !_isLoading
                            ? () {
                                setState(() => _page += 1);
                                _fetch();
                              }
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
