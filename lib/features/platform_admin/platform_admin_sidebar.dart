// lib/features/platform_admin/platform_admin_sidebar.dart
//
// Reusable expanding side navigation for the Platform Admin portal.
//
// Collapsed it is a compact icon rail; hovering anywhere on it (or
// focusing any item via keyboard) smoothly expands it to show icon +
// label for every destination. The widget is meant to be placed in a
// Stack/Positioned over the page content — it does not participate in
// layout, so the body keeps a fixed left padding and never shifts.

import 'package:flutter/material.dart';

import 'platform_admin_theme.dart';

/// Model for one sidebar destination.
class AdminNavItem {
  const AdminNavItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

/// Hover/focus-to-expand sidebar. Collapsed width exposes icons only;
/// expanding reveals labels for the brand, every nav item and the
/// footer action. On narrow/touch screens (< 600px) hover expansion is
/// disabled and the brand icon acts as a drawer toggle instead.
class AdminSidebar extends StatefulWidget {
  final IconData brandIcon;
  final String brandLabel;
  final List<AdminNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final IconData footerIcon;
  final String footerLabel;
  final VoidCallback onFooterTap;

  const AdminSidebar({
    super.key,
    required this.brandIcon,
    required this.brandLabel,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.footerIcon,
    required this.footerLabel,
    required this.onFooterTap,
  });

  /// Width the rail occupies in the page layout — the shell reserves
  /// exactly this much left padding regardless of expansion state.
  static const collapsedWidth = 68.0;
  static const expandedWidth = 256.0;
  static const brandExtent = 70.0;

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  bool _hovered = false;
  bool _focused = false;
  bool _toggled = false;

  bool _isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  @override
  Widget build(BuildContext context) {
    final narrow = _isNarrow(context);
    // Touch-width screens have no hover — expansion is toggle-driven.
    final expanded =
        _focused || (narrow ? _toggled : _hovered || _toggled);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // Expands the rail whenever ANY descendant item gains keyboard
      // focus so keyboard users get labels too.
      child: Focus(
        canRequestFocus: false,
        onFocusChange: (f) => setState(() => _focused = f),
        child: AnimatedContainer(
          key: const ValueKey('admin-sidebar'),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: expanded
              ? AdminSidebar.expandedWidth
              : AdminSidebar.collapsedWidth,
          decoration: BoxDecoration(
            color: PlatformAdminColors.sidebarSurface,
            border: const Border(
              right: BorderSide(color: PlatformAdminColors.border),
            ),
            boxShadow: expanded
                ? [
                    BoxShadow(
                      color: PlatformAdminColors.primary
                          .withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(6, 0),
                    ),
                  ]
                : null,
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _brand(narrow, expanded),
                for (var i = 0; i < widget.items.length; i++)
                  PlatformAdminSidebarItem(
                    icon: widget.items[i].icon,
                    label: widget.items[i].label,
                    selected: widget.selectedIndex == i,
                    expanded: expanded,
                    onTap: () {
                      widget.onSelect(i);
                      if (narrow) setState(() => _toggled = false);
                    },
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: PlatformAdminSidebarItem(
                    icon: widget.footerIcon,
                    label: widget.footerLabel,
                    selected: false,
                    expanded: expanded,
                    onTap: widget.onFooterTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(bool narrow, bool expanded) {
    final row = SizedBox(
      height: AdminSidebar.brandExtent,
      child: Padding(
        // The rail's 1px right border shrinks inner width to 67, so
        // 20 + 26 + 21 keeps the brand icon visually centered when
        // collapsed.
        padding: const EdgeInsets.fromLTRB(20, 0, 21, 0),
        child: Row(
          children: [
            Icon(
              widget.brandIcon,
              color: PlatformAdminColors.primary,
              size: 26,
            ),
            Expanded(
              child: ClipRect(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  curve: PlatformAdminMotion.curve,
                  opacity: expanded ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      widget.brandLabel,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PlatformAdminColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // On touch-width screens the brand icon doubles as the drawer toggle.
    if (!narrow) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _toggled = !_toggled),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: row,
      ),
    );
  }
}
