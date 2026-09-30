// lib/features/platform_admin/platform_admin_audit_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_registration_service.dart';

import 'platform_admin_theme.dart';

/// Audit / Review History tab for the Platform Admin portal (Milestone
/// 3D-E). Aggregates the lifecycle/reviewer events already recorded on
/// each organization registration's auditTrail/reviewHistory — this page
/// reuses that data through `PlatformAdminRegistrationService
/// .getAuditHistory`, it never invents a second audit system.
class PlatformAdminAuditPage extends StatefulWidget {
  const PlatformAdminAuditPage({super.key});

  @override
  State<PlatformAdminAuditPage> createState() =>
      _PlatformAdminAuditPageState();
}

class _PlatformAdminAuditPageState extends State<PlatformAdminAuditPage> {
  static const _filters = <(String, String?)>[
    ('All', null),
    ('Submitted', 'submitted'),
    ('Changes Requested', 'changes_requested'),
    ('Resubmitted', 'application_resubmitted'),
    ('Approved', 'application_approved'),
    ('Rejected', 'application_rejected'),
    ('Activated', 'organization_activated'),
  ];

  static const _eventLabels = <String, String>{
    'submitted': 'Application Submitted',
    'changes_requested': 'Changes Requested',
    'application_resubmitted': 'Application Resubmitted',
    'application_approved': 'Application Approved',
    'application_rejected': 'Application Rejected',
    'organization_activated': 'Organization Activated',
  };

  static const _statusLabels = <String, String>{
    'pending_approval': 'Pending Approval',
    'changes_requested': 'Changes Requested',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'activated': 'Activated',
  };

  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _filterIndex = 0;
  int _page = 1;
  bool _hasMore = false;
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
          await PlatformAdminRegistrationService.instance.getAuditHistory(
        action: _filters[_filterIndex].$2,
        search: _search.isEmpty ? null : _search,
        page: _page,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _events = (result['events'] as List? ?? [])
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

  String _fmtDateTime(dynamic v) {
    if (v == null) return '—';
    try {
      final d = v is String
          ? DateTime.parse(v)
          : (v is Map && v['_seconds'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(
                  (v['_seconds'] as int) * 1000)
              : null;
      if (d == null) return '—';
      final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      final time = '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
      return '$date  $time';
    } catch (_) {
      return '—';
    }
  }

  (Color, Color) _eventColors(String action) {
    switch (action) {
      case 'submitted':
        return (PlatformAdminColors.grayBg, PlatformAdminColors.grayFg);
      case 'changes_requested':
        return (PlatformAdminColors.blueBg, PlatformAdminColors.blueFg);
      case 'application_resubmitted':
        return (PlatformAdminColors.purpleBg, PlatformAdminColors.purpleFg);
      case 'application_approved':
        return (PlatformAdminColors.greenBg, PlatformAdminColors.greenFg);
      case 'application_rejected':
        return (PlatformAdminColors.redBg, PlatformAdminColors.redFg);
      case 'organization_activated':
        return (PlatformAdminColors.purpleBg, PlatformAdminColors.purpleFg);
      default:
        return (PlatformAdminColors.grayBg, PlatformAdminColors.grayFg);
    }
  }

  Widget _eventBadge(String action) {
    final (bg, fg) = _eventColors(action);
    return PlatformAdminStatusBadge(
      label: (_eventLabels[action] ?? action).toUpperCase(),
      background: bg,
      foreground: fg,
    );
  }

  String _statusLabel(dynamic status) {
    if (status == null) return '';
    return _statusLabels[status.toString()] ?? status.toString();
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final action = event['action']?.toString() ?? '';
    final previousStatus = event['previousStatus'];
    final newStatus = event['newStatus'];
    final actorEmail = event['actorEmail']?.toString();
    final actorRole = event['actorRole']?.toString();
    final note = event['note']?.toString();
    final revision = event['revision'];
    final changedFieldsCount = event['changedFieldsCount'];
    final organizationCode = event['organizationCode']?.toString();

    final (_, dotColor) = _eventColors(action);

    return PlatformAdminCard(
      hoverable: true,
      margin: const EdgeInsets.only(bottom: 10),
      radius: PlatformAdminRadii.cardSmall,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small timeline indicator dot.
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 12),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _eventBadge(action),
                          const SizedBox(height: 6),
                          Text(
                            event['organizationName']?.toString() ?? '—',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: PlatformAdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ref: ${event['registrationId'] ?? '—'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: PlatformAdminColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: PlatformAdminButtonStyles.secondary(),
                      onPressed: () {
                        final id = event['registrationId']?.toString();
                        if (id == null || id.isEmpty) return;
                        Navigator.of(context).pushNamed(
                          '/platform-admin/registrations/$id',
                        );
                      },
                      child: const Text('View Application'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (previousStatus != null || newStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${previousStatus != null ? _statusLabel(previousStatus) : 'New'}'
                      ' → ${_statusLabel(newStatus)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PlatformAdminColors.textPrimary,
                      ),
                    ),
                  ),
                if (revision != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Revision $revision'
                      '${changedFieldsCount != null ? ' • $changedFieldsCount ${changedFieldsCount == 1 ? 'field' : 'fields'} updated' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PlatformAdminColors.purpleFg,
                      ),
                    ),
                  ),
                if (organizationCode != null && organizationCode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Organization Code: $organizationCode',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PlatformAdminColors.purpleFg,
                      ),
                    ),
                  ),
                if (actorEmail != null && actorEmail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${actorRole ?? 'Actor'}: $actorEmail',
                      style: const TextStyle(
                        fontSize: 12,
                        color: PlatformAdminColors.textPrimary,
                      ),
                    ),
                  ),
                if (note != null && note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PlatformAdminColors.textSecondary,
                      ),
                    ),
                  ),
                Text(
                  _fmtDateTime(event['at']),
                  style: const TextStyle(
                    fontSize: 11,
                    color: PlatformAdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int i) {
    final selected = _filterIndex == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(_filters[i].$1),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filterIndex = i;
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
        // Header + filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlatformAdminSectionHeader(
                title: 'Audit / Review History',
                subtitle:
                    'Lifecycle and review events across organization applications.',
              ),
              const SizedBox(height: 14),
              Wrap(
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _filters.length; i++) _filterChip(i),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    SizedBox(
                      width: 280,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search organization, reference, or org code…',
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
                  else if (_events.isEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: PlatformAdminCard(
                        padding: const EdgeInsets.all(24),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 40,
                              color: PlatformAdminColors.primary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No review history yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: PlatformAdminColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Review decisions and lifecycle events for '
                              'organization applications will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: PlatformAdminColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final event in _events) _eventCard(event),
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
