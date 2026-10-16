import 'package:flutter/material.dart';
import 'package:serv_app/services/hr_feature_service.dart';

const Color _kPurple = Color(0xFF8C6EAF);
const Color _kDark = Color(0xFF655193);
const Color _kBg = Color(0xFFF5F0FF);

/// HR feature selection — the HR user picks a subset of the features the
/// Platform Admin enabled for their company and submits it for review.
///
/// Only company-enabled features are rendered here; unavailable features
/// are hidden entirely (per the feature-selection rule). Dependency rules
/// from the catalog are enforced client-side (a feature's `requires` are
/// auto-selected / its dependents auto-removed) and re-checked server-side.
class HrFeatureSelectionPage extends StatefulWidget {
  const HrFeatureSelectionPage({super.key});

  @override
  State<HrFeatureSelectionPage> createState() => _HrFeatureSelectionPageState();
}

class _HrFeatureSelectionPageState extends State<HrFeatureSelectionPage> {
  final _branchCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();

  List<Map<String, dynamic>> _features = [];
  final Set<String> _selected = {};
  Map<String, dynamic>? _existingRequest;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _branchCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        HrFeatureService.getAvailableFeatures(),
        HrFeatureService.getMyRequest(),
      ]);
      if (!mounted) return;

      final features = results[0] as List<Map<String, dynamic>>;
      final reqData = results[1] as Map<String, dynamic>;
      final request = reqData['request'] as Map<String, dynamic>?;
      final hr = reqData['hr'] as Map<String, dynamic>? ?? {};

      setState(() {
        _features = features;
        _existingRequest = request;
        // Prefill branch/department from the existing request, else the
        // HR profile the Company Admin set at creation.
        _branchCtrl.text = (request?['branch'] ?? hr['branch'] ?? '')
            .toString();
        _deptCtrl.text = (request?['department'] ?? hr['department'] ?? '')
            .toString();
        // Resubmit flow: prefill the previously requested features.
        if (request != null && request['requestedFeatures'] is List) {
          _selected.addAll(
            (request['requestedFeatures'] as List)
                .map((e) => e.toString())
                .where((k) => features.any((f) => f['key'] == k)),
          );
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

  List<String> _requiresOf(String key) {
    final f = _features.firstWhere(
      (e) => e['key'] == key,
      orElse: () => const {},
    );
    final req = f['requires'];
    return req is List ? req.map((e) => e.toString()).toList() : const [];
  }

  void _toggle(String key, bool checked) {
    setState(() {
      if (checked) {
        // Auto-select the dependency chain.
        final queue = [key];
        while (queue.isNotEmpty) {
          final k = queue.removeLast();
          if (_selected.add(k)) queue.addAll(_requiresOf(k));
        }
      } else {
        _selected.remove(key);
        // Remove selected dependents whose requires chain is broken.
        var changed = true;
        while (changed) {
          changed = false;
          for (final k in _selected.toList()) {
            if (_requiresOf(k).any((dep) => !_selected.contains(dep))) {
              _selected.remove(k);
              changed = true;
            }
          }
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      _showSnack('Select at least one feature');
      return;
    }
    if (_branchCtrl.text.trim().isEmpty || _deptCtrl.text.trim().isEmpty) {
      _showSnack('Branch and department are required');
      return;
    }

    setState(() => _submitting = true);
    try {
      await HrFeatureService.submitRequest(
        requestedFeatures: _selected.toList(),
        branch: _branchCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildChangesRequestedBanner() {
    final comment = _existingRequest?['reviewComment']?.toString() ?? '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rate_review_outlined,
              size: 18, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              comment.isEmpty
                  ? 'Changes were requested on your submission. Update and resubmit.'
                  : 'Reviewer: $comment',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6D4C00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(Map<String, dynamic> f) {
    final key = f['key'].toString();
    final label = f['label']?.toString() ?? key;
    final requires = _requiresOf(key);
    final requiresLabel = requires.isEmpty
        ? null
        : 'Requires ${requires.map((r) {
            final dep = _features.firstWhere((e) => e['key'] == r,
                orElse: () => {'label': r});
            return dep['label'];
          }).join(', ')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selected.contains(key) ? _kPurple : Colors.grey.shade200,
          width: _selected.contains(key) ? 1.4 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: _selected.contains(key),
        onChanged: (v) => _toggle(key, v == true),
        activeColor: _kDark,
        title: Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
        subtitle: requiresLabel == null
            ? null
            : Text(
                requiresLabel,
                style: const TextStyle(fontSize: 11.5, color: Colors.black45),
              ),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  InputDecoration _fieldDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kDark, size: 20),
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
    final isResubmit =
        _existingRequest?['requestStatus']?.toString() == 'changes_requested';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Feature Request'),
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
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
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 12),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isResubmit) _buildChangesRequestedBanner(),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          'Choose the features you need',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D1B4E),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(
                          'Only features enabled for your company are shown. '
                          'Your request goes to the Platform Admin for approval.',
                          style:
                              TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _branchCtrl,
                                decoration: _fieldDeco(
                                    'Branch', Icons.location_on_outlined),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _deptCtrl,
                                decoration: _fieldDeco(
                                    'Department', Icons.work_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _features.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'No features are enabled for your company yet. '
                                    'Contact your Platform Admin.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _features.length,
                                itemBuilder: (_, i) =>
                                    _buildFeatureTile(_features[i]),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: Text(
                              _submitting
                                  ? 'Submitting…'
                                  : isResubmit
                                      ? 'Resubmit Request'
                                      : 'Submit for Approval',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kDark,
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
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
