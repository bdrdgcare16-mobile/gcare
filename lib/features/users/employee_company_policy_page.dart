import 'package:flutter/material.dart';
import 'package:serv_app/features/users/home_screen_page.dart';
import 'package:serv_app/services/employee_policy_service.dart';
import 'package:serv_app/utils/logout.dart';

const Color _kPurple = Color(0xFF8C6EAF);
const Color _kDark = Color(0xFF655193);
const Color _kBg = Color(0xFFF5F0FF);

/// Employee Company Policy — shown when a published policy exists that the
/// employee has not yet acknowledged. The employee reads the policy and
/// taps "I Agree"; the backend acknowledgement record is the source of
/// truth (no local flags). On success the employee continues to the
/// dashboard.
class EmployeeCompanyPolicyPage extends StatefulWidget {
  final String userName;
  final String employeeDocId;

  const EmployeeCompanyPolicyPage({
    super.key,
    required this.userName,
    required this.employeeDocId,
  });

  @override
  State<EmployeeCompanyPolicyPage> createState() =>
      _EmployeeCompanyPolicyPageState();
}

class _EmployeeCompanyPolicyPageState
    extends State<EmployeeCompanyPolicyPage> {
  Map<String, dynamic>? _policy;
  bool _loading = true;
  bool _agreeing = false;
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
      final data = await EmployeePolicyService.getCurrentPolicy();
      if (!mounted) return;
      setState(() {
        _policy = data['policy'] as Map<String, dynamic>?;
        _loading = false;
      });
      // Race: policy may have become acknowledged / unpublished elsewhere —
      // nothing to acknowledge, let the employee through.
      if (_policy == null) _goToDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  int get _version => (_policy?['version'] as num?)?.toInt() ?? 0;

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          userName: widget.userName,
          employeeDocId: widget.employeeDocId,
        ),
      ),
      (route) => false,
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
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

  Future<void> _agree() async {
    if (_agreeing || _policy == null) return;
    setState(() => _agreeing = true);
    try {
      await EmployeePolicyService.acknowledgePolicy(_version);
      if (!mounted) return;
      _showSnack('Policy acknowledged');
      _goToDashboard();
    } on PolicyVersionStaleException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, error: true);
      await _load(); // refresh to the now-current version
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _agreeing = false);
    }
  }

  String _publishedLabel() {
    final raw = _policy?['publishedAt']?.toString();
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return 'Published ${local.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Company Policy'),
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Please review the company policy',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D1B4E),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You must acknowledge the latest policy to continue.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Version / published row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'PUBLISHED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Version $_version',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kDark,
                                    ),
                                  ),
                                  if (_publishedLabel().isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        _publishedLabel(),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Policy card — full content, scrollable page
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _policy?['title']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2D1B4E),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _policy?['content']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Sticky I Agree
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        decoration: BoxDecoration(
                          color: _kBg,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _agreeing ? null : _agree,
                            icon: _agreeing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label:
                                Text(_agreeing ? 'Acknowledging…' : 'I Agree'),
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
