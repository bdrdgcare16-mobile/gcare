// lib/features/platform_admin/platform_admin_registrations_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_registration_service.dart';

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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_approval':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'changes_requested':
        return Colors.blue;
      case 'pending_verification':
        return Colors.teal;
      default:
        return Colors.grey;
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

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        (_statusLabels[status] ?? status).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: const Color(0xFF7E57C2), width: 1),
            ),
            child: Text(
              'RESUBMITTED • REVISION ${count + 1}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5E35B1),
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
                  color: Color(0xFF5E35B1),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ref: ${item['registrationId'] ?? '—'}',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                _resubmissionBadge(item),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              contact['fullName']?.toString() ?? '—',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(item['submittedAt']),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              features.isEmpty ? '—' : features,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
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
            width: 130,
            child: OutlinedButton(
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
              const Text(
                'Organization Registrations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E2450),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Open an application to record a review decision.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++) ...[
                    ChoiceChip(
                      label: Text(_tabs[i].$1),
                      selected: _tabIndex == i,
                      onSelected: (_) {
                        setState(() {
                          _tabIndex = i;
                          _page = 1;
                        });
                        _fetch();
                      },
                      selectedColor: const Color(0xFF4B3B73),
                      labelStyle: TextStyle(
                        color: _tabIndex == i
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Search
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search organization…',
                        isDense: true,
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
                          borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(width: 12),
                  // Sort
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sort,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sort by',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
              const SizedBox(height: 14),
            ],
          ),
        ),
        const Divider(height: 1),

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
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  else if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Text(
                          'No registration applications found',
                          style: TextStyle(color: Colors.black54),
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
                        onPressed: _page > 1 && !_isLoading
                            ? () {
                                setState(() => _page -= 1);
                                _fetch();
                              }
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 12),
                      Text('Page $_page'),
                      const SizedBox(width: 12),
                      OutlinedButton(
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
