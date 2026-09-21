// lib/features/onboarding/screens/organization_policies_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:serv_app/features/users/home_screen_page.dart';
import 'package:serv_app/features/users/login_page.dart';
import 'package:serv_app/models/company_data.dart';
import '../models/organization_policy_model.dart';
import '../services/organization_policy_service.dart';

const Color _kPrimary = Color(0xFF8C6EAF);
const Color _kPrimaryDark = Color(0xFF655193);
const Color _kFieldBg = Color(0xFFF7F4FC);

/// Displays the employee's organization HR policies and records acceptance
/// of the exact policy versions shown.
///
/// Acceptance is authoritative on the backend — opening this page or ticking
/// a checkbox never marks a policy as accepted by itself.
class OrganizationPoliciesPage extends StatefulWidget {
  final String userName;
  final String employeeDocId;

  const OrganizationPoliciesPage({
    super.key,
    required this.userName,
    required this.employeeDocId,
  });

  @override
  State<OrganizationPoliciesPage> createState() =>
      _OrganizationPoliciesPageState();
}

class _OrganizationPoliciesPageState extends State<OrganizationPoliciesPage> {
  bool _loading = true;
  bool _submitting = false;
  Object? _loadError;
  List<OrganizationPolicy> _policies = [];

  /// Single acknowledgment covering all outstanding required ordinary HR
  /// policies. Nothing is written until Accept & Continue is tapped.
  bool _generalAgreed = false;

  /// Local UI state only — tracks which *separate-consent* checkboxes are
  /// ticked. Never persisted; the backend record is the source of truth.
  final Set<String> _checked = <String>{};

  /// Tracks explicit declines for *optional* separate-consent policies so the
  /// UI can distinguish "not yet answered" from "declined". Declines are not
  /// recorded on the backend (no endpoint exists yet).
  final Set<String> _declined = <String>{};

  final Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  String _key(OrganizationPolicy p) => '${p.policyId}:${p.version}';

  Future<void> _loadPolicies() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _generalAgreed = false;
      _checked.clear();
      _declined.clear();
    });
    try {
      final policies =
          await OrganizationPolicyService.instance.getCurrentPolicies();
      if (!mounted) return;
      setState(() {
        _policies = policies;
        _loading = false;
      });
    } on PolicyAuthException {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  /// Outstanding (required, unaccepted) ordinary HR policies covered by the
  /// single general acknowledgment checkbox.
  bool get _hasPendingOrdinary => _policies
      .any((p) => p.required && !p.accepted && !p.requiresSeparateConsent);

  /// Whether the submit button may be enabled:
  ///  - the general checkbox is ticked if any ordinary required policy is
  ///    outstanding, and
  ///  - every required separate-consent policy is explicitly checked.
  bool get _readyToSubmit {
    if (_hasPendingOrdinary && !_generalAgreed) return false;
    for (final p in _policies) {
      if (p.required && !p.accepted && p.requiresSeparateConsent) {
        if (!_checked.contains(_key(p))) return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_readyToSubmit || _submitting) return;
    setState(() => _submitting = true);

    try {
      for (final p in _policies) {
        if (p.accepted) continue;
        if (p.requiresSeparateConsent) {
          // Consent policies: submit only when explicitly checked.
          if (!_checked.contains(_key(p))) continue;
        } else {
          // Ordinary HR policies: required ones are covered by the single
          // general checkbox; optional ones are never auto-accepted.
          if (!p.required || !_generalAgreed) continue;
        }
        await OrganizationPolicyService.instance.acceptPolicy(
          policyId: p.policyId,
          policyVersion: p.version,
        );
      }

      // Re-verify against the backend — never trust local state.
      final status =
          await OrganizationPolicyService.instance.getAcceptanceStatus();
      if (!mounted) return;

      if (status.allAccepted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: widget.userName,
              employeeDocId: widget.employeeDocId,
            ),
          ),
          (route) => false,
        );
      } else {
        setState(() => _submitting = false);
        _showSnack(
          'Some required policies are still pending. Please review and accept.',
        );
        await _loadPolicies();
      }
    } on PolicyVersionConflictException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(e.message.isEmpty
          ? 'A newer version of a policy was published. Reloading.'
          : e.message);
      await _loadPolicies();
    } on PolicyAuthException {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(e.toString());
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _kPrimaryDark,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _typeLabel(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack('Unable to open document.');
    }
  }

  Widget _buildPolicyCard(OrganizationPolicy p) {
    final key = _key(p);
    final isConsent = p.requiresSeparateConsent;
    final isChecked = _checked.contains(key);
    final isDeclined = _declined.contains(key);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    p.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _badge(
                  p.required ? 'REQUIRED' : 'OPTIONAL',
                  p.required ? _kPrimaryDark : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _badge(_typeLabel(p.type), _kPrimary),
                _badge('v${p.version}', Colors.blueGrey),
                if (p.publishedAt != null)
                  _badge('Published ${_formatDate(p.publishedAt)}',
                      Colors.black45),
                if (p.accepted) _badge('ACCEPTED', Colors.green),
              ],
            ),
            if (p.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                p.description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 8),
            // Read/expand full content
            if (p.content.isNotEmpty)
              InkWell(
                onTap: () => setState(() {
                  _expanded.contains(key)
                      ? _expanded.remove(key)
                      : _expanded.add(key);
                }),
                child: Row(
                  children: [
                    Text(
                      _expanded.contains(key)
                          ? 'Hide policy'
                          : 'Read policy',
                      style: const TextStyle(
                        color: _kPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _expanded.contains(key)
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: _kPrimaryDark,
                    ),
                  ],
                ),
              ),
            if (_expanded.contains(key) && p.content.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kFieldBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.content,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            if (p.documentUrl != null && p.documentUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _openDocument(p.documentUrl!),
                icon: const Icon(Icons.open_in_new,
                    size: 18, color: _kPrimaryDark),
                label: const Text(
                  'Open document',
                  style: TextStyle(color: _kPrimaryDark),
                ),
              ),
            ],
            const Divider(height: 24),
            if (p.accepted)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'You have accepted this version.',
                    style: TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ],
              )
            else if (isConsent)
              _buildConsentControls(p, key, isChecked, isDeclined),
          ],
        ),
      ),
    );
  }

  /// Separate explicit acknowledgment for location/biometric consent.
  /// The checkbox is never preselected, and optional consents may be
  /// explicitly declined (decline is a local answer — the backend has no
  /// decline endpoint yet, so nothing is recorded for a decline).
  Widget _buildConsentControls(
      OrganizationPolicy p, String key, bool isChecked, bool isDeclined) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'This is a separate consent. It is not covered by accepting '
            'other policies.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _kPrimaryDark,
          value: isChecked,
          onChanged: _submitting
              ? null
              : (v) => setState(() {
                    if (v == true) {
                      _checked.add(key);
                      _declined.remove(key);
                    } else {
                      _checked.remove(key);
                    }
                  }),
          title: Text(
            'I explicitly consent to ${p.title} (v${p.version})',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if (!p.required)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.grey,
            value: isDeclined,
            onChanged: _submitting
                ? null
                : (v) => setState(() {
                      if (v == true) {
                        _declined.add(key);
                        _checked.remove(key);
                      } else {
                        _declined.remove(key);
                      }
                    }),
            title: const Text(
              'I decline this consent',
              style: TextStyle(fontSize: 14),
            ),
          ),
        if (p.required && !isChecked)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'This consent is required to continue.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgName = CompanyData.companyName.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEF9),
      appBar: AppBar(
        title: const Text('Organization HR Policies'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildError()
                : _buildContent(orgName),
      ),
      bottomNavigationBar: (_loading || _loadError != null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        (_readyToSubmit && !_submitting) ? _submit : null,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accept & Continue'),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(String orgName) {
    final pending =
        _policies.where((p) => !p.accepted && p.required).length;
    final ordinary =
        _policies.where((p) => !p.requiresSeparateConsent).toList();
    final consents =
        _policies.where((p) => p.requiresSeparateConsent).toList();

    return RefreshIndicator(
      onRefresh: _loadPolicies,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (orgName.isNotEmpty) ...[
            Text(
              orgName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
          ],
          const Text(
            'Please review and accept the policies below before continuing.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            '$pending required pending',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 12),
          ...ordinary.map(_buildPolicyCard),
          // Single acknowledgment for all outstanding required ordinary
          // HR policies — individual cards no longer carry checkboxes.
          if (_hasPendingOrdinary)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: CheckboxListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _kPrimaryDark,
                value: _generalAgreed,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _generalAgreed = v == true),
                title: const Text(
                  'I have read and agree to the required Organization HR Policies.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (consents.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Separate Consents',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'The consents below are not covered by the general agreement above.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            ...consents.map(_buildPolicyCard),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: _kPrimaryDark),
            const SizedBox(height: 16),
            const Text(
              'Unable to load policies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError?.toString() ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPolicies,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
