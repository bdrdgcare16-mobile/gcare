// lib/features/platform_admin/platform_admin_registrations_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_registration_service.dart';

import 'pa_ui.dart';

/// Platform Admin review list for organization registration
/// applications (Milestones 3D-B/C). Tabs map to application statuses:
/// Pending → pending_approval, Approved → approved, Rejected → rejected,
/// Changes Requested → changes_requested, All Applications → no filter.
/// Decisions are made on the detail page (3D-C).
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

  static const _statusLabels = <String, String>{
    'draft': 'Draft',
    'submitted': 'Submitted',
    'pending_verification': 'Pending Verification',
    'pending_approval': 'Pending Approval',
    'changes_requested': 'Changes Requested',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  /// Purple RESUBMITTED badge + revision — only when the application
  /// has been through at least one changes_requested → resubmit cycle.
  Widget _resubmissionBadge(Map<String, dynamic> item) {
    final count = (item['resubmissionCount'] as num?)?.toInt() ?? 0;
    if (count <= 0) return const SizedBox.shrink();
    final changed = (item['changedFieldsCount'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PaColors.soft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: PaColors.accent, width: 1),
            ),
            child: Text(
              'RESUBMITTED • REVISION ${count + 1}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: PaColors.deep,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (changed > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '$changed ${changed == 1 ? 'field' : 'fields'} updated',
                style: const TextStyle(
                  fontSize: 11,
                  color: PaColors.accent,
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
    final status = item['status']?.toString() ?? '';
    return PaListRow(
      onTap: () {
        final id = item['registrationId']?.toString();
        if (id == null || id.isEmpty) return;
        Navigator.of(context).pushNamed(
          '/platform-admin/registrations/$id',
        );
      },
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
                    color: PaColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ref: ${item['registrationId'] ?? '—'}',
                  style: const TextStyle(fontSize: 11, color: PaColors.muted),
                ),
                _resubmissionBadge(item),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              contact['fullName']?.toString() ?? '—',
              style: const TextStyle(fontSize: 12, color: PaColors.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(item['submittedAt']),
              style: const TextStyle(fontSize: 12, color: PaColors.text),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              features.isEmpty ? '—' : features,
              style: const TextStyle(fontSize: 11, color: PaColors.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerLeft,
              child: PaBadge(
                text: _statusLabels[status] ?? status,
                color: paStatusColor(status),
              ),
            ),
          ),
          const SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.chevron_right, size: 18, color: PaColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PaPageHeader(
                title: 'Organization Registrations',
                subtitle: 'Open an application to record a review decision.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    PaTabChip(
                      label: _tabs[i].$1,
                      selected: _tabIndex == i,
                      onSelected: () {
                        setState(() {
                          _tabIndex = i;
                          _page = 1;
                        });
                        _fetch();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _searchController,
                      decoration: paInputDecoration(
                        'Search organization…',
                        prefixIcon: Icons.search,
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 16, color: PaColors.muted),
                                onPressed: () {
                                  _searchController.clear();
                                  _search = '';
                                  _applyFilters();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (v) {
                        _search = v.trim();
                        _applyFilters();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sort,
                      isExpanded: true,
                      decoration: paInputDecoration('', label: 'Sort by'),
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
            ],
          ),
        ),
        const Divider(height: 1, color: PaColors.border),

        // Body
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetch,
            color: PaColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const PaLoading()
                  else if (_errorMessage != null)
                    PaErrorState(message: _errorMessage!, onRetry: _fetch)
                  else if (_items.isEmpty)
                    const PaEmptyState(
                      message: 'No registration applications found',
                      icon: Icons.domain_verification_outlined,
                    )
                  else
                    for (final item in _items) _buildRow(item),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PaOutlineButton(
                        label: 'Previous',
                        icon: Icons.chevron_left,
                        onPressed: _page > 1 && !_isLoading
                            ? () {
                                setState(() => _page -= 1);
                                _fetch();
                              }
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Page $_page',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PaColors.text,
                        ),
                      ),
                      const SizedBox(width: 14),
                      PaOutlineButton(
                        label: 'Next',
                        icon: Icons.chevron_right,
                        onPressed: _hasMore && !_isLoading
                            ? () {
                                setState(() => _page += 1);
                                _fetch();
                              }
                            : null,
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
