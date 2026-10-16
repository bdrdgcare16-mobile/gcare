import 'package:flutter/material.dart';
import 'package:serv_app/services/platform_admin_service.dart';
import 'package:serv_app/features/platform_admin/pa_ui.dart';

import 'platform_admin_shell.dart';

/// Platform Admin dashboard: compact stat cards + quick-action shortcuts.
/// Employee onboarding review moved to Company Admin — no /api/onboarding
/// calls are made here.
class PlatformAdminDashboardPage extends StatefulWidget {
  const PlatformAdminDashboardPage({super.key});

  @override
  State<PlatformAdminDashboardPage> createState() =>
      _PlatformAdminDashboardPageState();
}

class _PlatformAdminDashboardPageState
    extends State<PlatformAdminDashboardPage> {
  bool _loading = true;
  String? _error;
  int _companyCount = 0;
  int _activeCompanies = 0;

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
      final companies = await PlatformAdminService.listCompanies();
      if (!mounted) return;
      setState(() {
        _companyCount = companies.length;
        _activeCompanies = companies
            .where(
              (c) =>
                  (c['status'] ?? 'active').toString().toLowerCase() ==
                  'active',
            )
            .length;
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

  Widget _quickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required PlatformAdminSection section,
  }) {
    return PaHoverCard(
      onTap: () => PlatformAdminShell.navigate(context, section),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PaColors.soft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: PaColors.primary, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PaColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: PaColors.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: PaColors.accent),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminShell(
      selected: PlatformAdminSection.dashboard,
      title: 'Dashboard',
      body: RefreshIndicator(
        onRefresh: _load,
        color: PaColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: kPaPagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PaPageHeader(
                title: 'Platform Overview',
                subtitle: 'Tenant health and administration shortcuts',
              ),
              const SizedBox(height: 22),
              if (_loading)
                const PaLoading()
              else if (_error != null)
                PaErrorState(message: _error!, onRetry: _load)
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Two real backend metrics — compact cards that wrap
                    // to a single column on narrow widths.
                    final wide = constraints.maxWidth >= 700;
                    final stats = [
                      PaStatCard(
                        label: 'Total Companies',
                        value: '$_companyCount',
                        icon: Icons.business_rounded,
                      ),
                      PaStatCard(
                        label: 'Active Companies',
                        value: '$_activeCompanies',
                        icon: Icons.check_circle_outline_rounded,
                        color: PaColors.success,
                      ),
                    ];
                    if (!wide) {
                      return Column(
                        children: [
                          stats[0],
                          const SizedBox(height: 12),
                          stats[1],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: stats[0]),
                        const SizedBox(width: 14),
                        Expanded(child: stats[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PaColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final actions = [
                      _quickAction(
                        title: 'Companies',
                        subtitle:
                            'Create companies, set max users and enabled features',
                        icon: Icons.business_outlined,
                        section: PlatformAdminSection.companies,
                      ),
                      _quickAction(
                        title: 'Organization Registrations',
                        subtitle:
                            'Review organization registration applications',
                        icon: Icons.domain_verification_outlined,
                        section: PlatformAdminSection.registrations,
                      ),
                      _quickAction(
                        title: 'HR Feature Requests',
                        subtitle: 'Review and approve HR feature requests',
                        icon: Icons.playlist_add_check_circle_outlined,
                        section: PlatformAdminSection.hrRequests,
                      ),
                    ];
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < actions.length; i++) ...[
                            if (i > 0) const SizedBox(width: 14),
                            Expanded(child: actions[i]),
                          ],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (final a in actions) ...[
                          a,
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
