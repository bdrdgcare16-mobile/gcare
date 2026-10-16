import 'package:flutter/material.dart';
import 'package:serv_app/services/hr_company_policy_service.dart';
import 'package:serv_app/features/hr/hr_landing_page.dart';
import 'package:serv_app/utils/logout.dart';

const Color _kPurple = Color(0xFF8C6EAF);
const Color _kDark = Color(0xFF655193);
const Color _kBg = Color(0xFFF5F0FF);

/// HR Company Policy — the HR user drafts and publishes their company's
/// policy before they can request features.
///
/// Backend is the source of truth (companyPolicies collection): a
/// published policy is required before feature selection; drafts can be
/// edited repeatedly without bumping the version, and publishing a
/// revision after an already-published policy creates the next version
/// while preserving the previous published one.
class HrCompanyPolicyPage extends StatefulWidget {
  const HrCompanyPolicyPage({super.key});

  @override
  State<HrCompanyPolicyPage> createState() => _HrCompanyPolicyPageState();
}

class _HrCompanyPolicyPageState extends State<HrCompanyPolicyPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  Map<String, dynamic>? _policy;
  bool _hasPublished = false;
  bool _loading = true;
  bool _saving = false;
  bool _publishing = false;
  bool _justPublished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await HrCompanyPolicyService.getCompanyPolicy();
      if (!mounted) return;
      final policy = data['policy'] as Map<String, dynamic>?;
      setState(() {
        _policy = policy;
        _hasPublished = data['hasPublished'] == true;
        if (policy != null) {
          _titleCtrl.text = policy['title']?.toString() ?? '';
          _contentCtrl.text = policy['content']?.toString() ?? '';
        }
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

  bool get _isDraft => _policy?['status']?.toString() == 'draft';
  int get _version => (_policy?['version'] as num?)?.toInt() ?? 1;

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade700 : _kDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _save({bool quiet = false}) async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _showSnack('Title and content are required', error: true);
      return false;
    }
    setState(() => _saving = true);
    try {
      final res = await HrCompanyPolicyService.saveCompanyPolicy(
        title: title,
        content: content,
      );
      if (!mounted) return false;
      setState(() {
        _policy = res['policy'] is Map
            ? Map<String, dynamic>.from(res['policy'] as Map)
            : _policy;
      });
      if (!quiet) _showSnack('Draft saved (version $_version)');
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    // Ensure the latest edits are persisted before publishing.
    final saved = await _save(quiet: true);
    if (!saved || !mounted) return;

    setState(() => _publishing = true);
    try {
      final res = await HrCompanyPolicyService.publishCompanyPolicy();
      if (!mounted) return;
      setState(() {
        _policy = res['policy'] is Map
            ? Map<String, dynamic>.from(res['policy'] as Map)
            : _policy;
        _hasPublished = true;
        _justPublished = true;
      });
      _showSnack('Policy published — version $_version');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _continueToFeatures() {
    // Back through the landing gate — it routes to the feature-selection /
    // request-status flow now that a published policy exists.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HrLandingPage()),
    );
  }

  Widget _statusBadge() {
    final published = _policy?['status']?.toString() == 'published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: published ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        (published ? 'Published' : 'Draft').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPurple, width: 1.4),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _publishing;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Company Policy'),
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set up your company policy',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D1B4E),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasPublished
                              ? 'A published policy exists. Saving creates a new draft version; publish it to make it effective.'
                              : 'Publish the company policy to continue to feature selection.',
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),

                        // Version / status row
                        Row(
                          children: [
                            _statusBadge(),
                            const SizedBox(width: 10),
                            Text(
                              'Version $_version',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kDark,
                              ),
                            ),
                            if (_hasPublished) ...[
                              const SizedBox(width: 10),
                              Text(
                                '(latest published)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _titleCtrl,
                          enabled: !busy && !_justPublished,
                          decoration: _fieldDeco('Policy Title'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contentCtrl,
                          enabled: !busy && !_justPublished,
                          maxLines: 12,
                          decoration: _fieldDeco(
                            'Policy Content',
                            hint:
                                'Write the company policy your employees will acknowledge…',
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_justPublished)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _continueToFeatures,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Continue to Feature Selection'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy ? null : () => _save(),
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                      _saving ? 'Saving…' : 'Save Draft'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _kDark,
                                    side: const BorderSide(color: _kDark),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: busy ? null : _publish,
                                  icon: _publishing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.publish_outlined),
                                  label: Text(_publishing
                                      ? 'Publishing…'
                                      : 'Publish'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kDark,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        if (_isDraft && _hasPublished) ...[
                          const SizedBox(height: 12),
                          Text(
                            'This draft will become version $_version when published. '
                            'The currently published version stays in effect until then.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}
