import 'package:flutter/material.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/models/company_profile.dart';
import 'package:serv_app/services/hr_company_policy_service.dart';
import 'package:serv_app/services/hr_feature_service.dart';
import 'package:serv_app/features/admin/admin_dashboard_page.dart';
import 'package:serv_app/features/hr/hr_company_policy_page.dart';
import 'package:serv_app/features/hr/hr_feature_selection_page.dart';
import 'package:serv_app/utils/logout.dart';

const Color _kPurple = Color(0xFF8C6EAF);
const Color _kDark = Color(0xFF655193);
const Color _kBg = Color(0xFFF5F0FF);

/// HR landing / request-status gate for role 'hr'.
///
/// Every HR sign-in (fresh or restored) lands here; the page decides what
/// the HR sees based on their feature-request status:
///   none              → call-to-action into the feature-selection flow
///   pending           → status card; NO dashboard access
///   changes_requested → reviewer comment + resubmit action
///   rejected          → status card
///   approved          → the shared Admin dashboard UI, filtered to
///                       approvedFeatures ONLY (never the company-level
///                       enabledFeatures).
class HrLandingPage extends StatefulWidget {
  const HrLandingPage({super.key});

  @override
  State<HrLandingPage> createState() => _HrLandingPageState();
}

class _HrLandingPageState extends State<HrLandingPage> {
  Map<String, dynamic>? _request;
  Map<String, String> _labels = {};
  List<String> _accessibleFeatures = [];
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
      // Policy gate first: without a PUBLISHED company policy the HR must
      // stay in the policy flow — feature selection comes after publish.
      final policyData = await HrCompanyPolicyService.getCompanyPolicy();
      if (!mounted) return;
      if (policyData['hasPublished'] != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HrCompanyPolicyPage()),
          );
        });
        return;
      }

      // Fetch in parallel: the request decides the view, the
      // available-features catalog supplies display labels, and the
      // approved-features endpoint is the authoritative access set the
      // dashboard renders (users/<hrUserId>.approvedFeatures).
      final results = await Future.wait([
        HrFeatureService.getMyRequest(),
        HrFeatureService.getAvailableFeatures(),
        HrFeatureService.getApprovedFeatures(),
      ]);
      if (!mounted) return;
      final reqData = results[0] as Map<String, dynamic>;
      final features = results[1] as List<Map<String, dynamic>>;
      final approved = results[2] as Map<String, dynamic>;
      setState(() {
        _request = reqData['request'] as Map<String, dynamic>?;
        _labels = {
          for (final f in features)
            f['key'].toString(): (f['label'] ?? f['key']).toString(),
        };
        _accessibleFeatures =
            (approved['accessibleFeatures'] as List?)?.cast<String>() ?? [];
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

  Future<void> _openSelection() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HrFeatureSelectionPage()),
    );
    if (submitted == true) _load();
  }

  String _labelOf(String key) =>
      _labels[key] ??
      key
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D1B4E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Colors.black54),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _featureChip(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _labelOf(key),
        style: const TextStyle(
          fontSize: 12.5,
          color: _kDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _featureWrap(List<String> keys) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: keys.map(_featureChip).toList(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _statusCard(
        icon: Icons.cloud_off_outlined,
        color: Colors.grey,
        title: 'Could not load your request',
        body: _error!,
        action: _primaryButton('Retry', Icons.refresh, _load),
      );
    }

    final request = _request;
    if (request == null) {
      return _statusCard(
        icon: Icons.badge_outlined,
        color: _kDark,
        title: 'HR account active',
        body:
            'Signed in as ${CompanyData.email}.\n\n'
            'Request the features you need for your branch/department. '
            'The Platform Admin will review your request before access is enabled.',
        action: _primaryButton(
            'Select Features', Icons.playlist_add_check, _openSelection),
      );
    }

    final status = request['requestStatus']?.toString() ?? 'pending';
    final comment = request['reviewComment']?.toString() ?? '';
    final requested = request['requestedFeatures'] is List
        ? (request['requestedFeatures'] as List).map((e) => e.toString()).toList()
        : <String>[];
    switch (status) {
      case 'pending':
        return _statusCard(
          icon: Icons.hourglass_top,
          color: const Color(0xFFE65100),
          title: 'Request pending review',
          body:
              'Your feature request was sent to the Platform Admin. '
              'Requested features stay inactive until approved.',
          action: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _featureWrap(requested),
          ),
        );

      case 'changes_requested':
        return _statusCard(
          icon: Icons.rate_review_outlined,
          color: const Color(0xFFE65100),
          title: 'Changes requested',
          body: comment.isEmpty
              ? 'The Platform Admin asked you to update your request.'
              : 'Reviewer comment: $comment',
          action:
              _primaryButton('Update & Resubmit', Icons.edit, _openSelection),
        );

      case 'rejected':
        return _statusCard(
          icon: Icons.cancel_outlined,
          color: Colors.red.shade400,
          title: 'Request rejected',
          body: comment.isEmpty
              ? 'Your feature request was rejected. Contact your Platform Admin.'
              : 'Reviewer comment: $comment',
        );

      case 'approved':
        // Handled in build(): the approved state renders the shared
        // Admin dashboard (restrictToFeatures) instead of this scaffold.
        return const SizedBox.shrink();

      default:
        return _statusCard(
          icon: Icons.help_outline,
          color: Colors.grey,
          title: 'Request status: $status',
          body: 'Contact your Platform Admin if this looks wrong.',
        );
    }
  }

  /// The module set the HR dashboard is allowed to show — sourced from
  /// GET /api/hr/features/approved (accessibleFeatures = approved +
  /// dependency closure; falls back to the raw approved list).
  List<String> _hrModuleSet() {
    if (_accessibleFeatures.isNotEmpty) return _accessibleFeatures;
    final approved = _request?['approvedFeatures'];
    return approved is List ? approved.map((e) => e.toString()).toList() : [];
  }

  @override
  Widget build(BuildContext context) {
    final status = _request?['requestStatus']?.toString();
    if (!_loading && _error == null && status == 'approved') {
      // HR Dashboard: the existing Admin dashboard UI filtered to the
      // Platform-Admin-approved feature set. An empty set yields the
      // "No features have been approved yet." empty state — the full
      // admin module list is never shown.
      return AdminDashboard(
        companyProfile: CompanyProfile(
          name: CompanyData.companyName.isNotEmpty
              ? CompanyData.companyName
              : CompanyData.companyId,
          adminName: CompanyData.adminName.isNotEmpty
              ? CompanyData.adminName
              : CompanyData.email,
        ),
        restrictToFeatures: _hrModuleSet().toSet(),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('HR Portal'),
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}
