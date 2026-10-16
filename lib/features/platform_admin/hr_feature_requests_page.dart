// lib/features/platform_admin/hr_feature_requests_page.dart

import 'package:flutter/material.dart';

import 'package:serv_app/features/supderadmin/platform_admin_shell.dart';
import 'package:serv_app/services/platform_admin_hr_requests_service.dart';
import 'package:serv_app/services/platform_admin_service.dart';

import 'pa_ui.dart';

/// Platform Admin review queue for HR feature-access requests
/// (hrFeatureRequests collection).
///
/// HR users pick a subset of their company's Platform Admin-enabled
/// features and submit; the Platform Admin approves / requests changes /
/// rejects here. Approving writes approvedFeatures on the request + the
/// HR user doc — the company's enabledFeatures are never modified.
class PlatformAdminHrRequestsPage extends StatefulWidget {
  const PlatformAdminHrRequestsPage({super.key});

  @override
  State<PlatformAdminHrRequestsPage> createState() =>
      _PlatformAdminHrRequestsPageState();
}

class _PlatformAdminHrRequestsPageState
    extends State<PlatformAdminHrRequestsPage> {
  static const _tabs = <(String, String?)>[
    ('Pending', 'pending'),
    ('Changes Requested', 'changes_requested'),
    ('Approved', 'approved'),
    ('Rejected', 'rejected'),
    ('All', null),
  ];

  static const _statusLabels = <String, String>{
    'pending': 'Pending',
    'changes_requested': 'Changes Requested',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  List<Map<String, dynamic>> _items = [];
  Map<String, String> _labels = {};
  bool _loading = true;
  String? _error;
  int _tabIndex = 0;

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
      final results = await Future.wait([
        PlatformAdminHrRequestsService.instance
            .listRequests(status: _tabs[_tabIndex].$2),
        PlatformAdminService.getFeatureCatalog(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0];
        _labels = {
          for (final f in results[1])
            f['key'].toString(): (f['label'] ?? f['key']).toString(),
        };
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

  String _labelOf(String key) =>
      _labels[key] ??
      key
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try {
      final d = v is String
          ? DateTime.tryParse(v)
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

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? PaColors.danger : PaColors.deep,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------- Review dialogs ----------

  List<String> _requestedOf(Map<String, dynamic> r) =>
      (r['requestedFeatures'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();

  Future<void> _confirmApprove(Map<String, dynamic> request) async {
    final features = _requestedOf(request);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Approve feature request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request['hrName'] ?? ''} (${request['hrEmail'] ?? ''}) '
              'will get access to:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: PaColors.success),
                    const SizedBox(width: 6),
                    Text(_labelOf(f), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This only affects this HR user — company feature settings are unchanged.',
              style: TextStyle(fontSize: 11.5, color: PaColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PaColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await PlatformAdminHrRequestsService.instance
          .approve(request['id'].toString());
      if (!mounted) return;
      _showSnack('Request approved');
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _commentDialog(
    Map<String, dynamic> request, {
    required bool isReject,
  }) async {
    final ctrl = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(isReject ? 'Reject request' : 'Request changes'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: paInputDecoration('', label: 'Review comment (required)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isReject ? PaColors.danger : PaColors.primary,
            ),
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              Navigator.pop(ctx, v);
            },
            child: Text(isReject ? 'Reject' : 'Send'),
          ),
        ],
      ),
    );
    if (submitted == null || submitted.isEmpty) return;
    try {
      final id = request['id'].toString();
      if (isReject) {
        await PlatformAdminHrRequestsService.instance.reject(id, submitted);
      } else {
        await PlatformAdminHrRequestsService.instance
            .requestChanges(id, submitted);
      }
      if (!mounted) return;
      _showSnack(isReject ? 'Request rejected' : 'Changes requested');
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> request) async {
    Map<String, dynamic>? detail;
    String? loadError;
    try {
      detail = await PlatformAdminHrRequestsService.instance
          .getRequest(request['id'].toString());
    } catch (e) {
      loadError = e.toString();
    }
    if (!mounted) return;
    if (detail == null) {
      _showSnack(loadError ?? 'Failed to load request', error: true);
      return;
    }

    final r = Map<String, dynamic>.from(detail['request'] as Map? ?? request);
    final company = Map<String, dynamic>.from(detail['company'] as Map? ?? {});
    final companyFeatures = (company['enabledFeatures'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final status = r['requestStatus']?.toString() ?? 'pending';
    final isPending = status == 'pending';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('HR Feature Request'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(
                    'HR', '${r['hrName'] ?? '—'} (${r['hrEmail'] ?? '—'})'),
                _detailRow('Company',
                    '${r['companyName'] ?? company['name'] ?? '—'} (${r['companyId'] ?? '—'})'),
                _detailRow('Branch', '${r['branch'] ?? '—'}'),
                _detailRow('Department', '${r['department'] ?? '—'}'),
                _detailRow('Requested', _fmtDate(r['requestedAt'])),
                _detailRow('Status', _statusLabels[status] ?? status),
                if ((r['reviewComment']?.toString() ?? '').isNotEmpty)
                  _detailRow('Review comment', r['reviewComment'].toString()),
                if ((r['reviewedByEmail']?.toString() ?? '').isNotEmpty)
                  _detailRow('Reviewed by', r['reviewedByEmail'].toString()),
                const SizedBox(height: 12),
                const Text('Requested Features',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ..._requestedOf(r).map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outlined,
                            size: 15, color: PaColors.primary),
                        const SizedBox(width: 6),
                        Text(_labelOf(f), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Company Available Features',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ...companyFeatures.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.circle_outlined,
                            size: 13, color: PaColors.muted),
                        const SizedBox(width: 6),
                        Text(_labelOf(f), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (isPending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _commentDialog(r, isReject: true);
              },
              child: const Text('Reject',
                  style: TextStyle(color: PaColors.danger)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _commentDialog(r, isReject: false);
              },
              child: const Text('Request Changes'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: PaColors.primary),
              onPressed: () {
                Navigator.pop(ctx);
                _confirmApprove(r);
              },
              child: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: PaColors.muted),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ---------- List ----------

  Widget _buildRow(Map<String, dynamic> item) {
    final requested = _requestedOf(item).map(_labelOf).join(', ');
    final status = item['requestStatus']?.toString() ?? '';
    return PaListRow(
      onTap: () => _openDetail(item),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['hrName']?.toString() ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PaColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item['hrEmail']?.toString() ?? '—',
                  style: const TextStyle(fontSize: 11, color: PaColors.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item['companyName']?.toString() ??
                  item['companyId']?.toString() ??
                  '—',
              style: const TextStyle(fontSize: 12, color: PaColors.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item['branch'] ?? '—'} / ${item['department'] ?? '—'}',
              style: const TextStyle(fontSize: 12, color: PaColors.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              requested.isEmpty ? '—' : requested,
              style: const TextStyle(fontSize: 11, color: PaColors.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              _fmtDate(item['requestedAt'] ?? item['createdAt']),
              style: const TextStyle(fontSize: 12, color: PaColors.text),
            ),
          ),
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: PaBadge(
                text: _statusLabels[status] ?? status,
                color: paStatusColor(status),
              ),
            ),
          ),
          const SizedBox(
            width: 60,
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
    return PlatformAdminShell(
      selected: PlatformAdminSection.hrRequests,
      title: 'HR Feature Requests',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PaPageHeader(
                  title: 'HR Feature Requests',
                  subtitle:
                      'Review the features HR users requested for their branch or department.',
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
                          setState(() => _tabIndex = i);
                          _load();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: PaColors.border),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: PaColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: _loading
                    ? const PaLoading()
                    : _error != null
                        ? PaErrorState(message: _error!, onRetry: _load)
                        : _items.isEmpty
                            ? const PaEmptyState(
                                message: 'No HR feature requests found',
                                icon: Icons.playlist_add_check_circle_outlined,
                              )
                            : Column(
                                children: [
                                  for (final item in _items) _buildRow(item),
                                ],
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
