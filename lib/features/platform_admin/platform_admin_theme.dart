// lib/features/platform_admin/platform_admin_theme.dart
//
// Centralized visual design system for the Platform Admin portal.
// Every Platform Admin screen should source its colors, spacing and
// shared building blocks from here instead of hardcoding values, so the
// portal keeps one consistent look (clean SaaS style: pale lavender
// ambience, white cards, soft shadows, restrained purple accent).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Color tokens for the Platform Admin portal.
class PlatformAdminColors {
  PlatformAdminColors._();

  // Ambient page background — very pale lavender, not a flat white.
  static const background = Color(0xFFF7F5FC);
  static const backgroundGradientTop = Color(0xFFF3EFFC);
  static const backgroundGradientBottom = Color(0xFFF9F7FD);

  // Surfaces
  static const surface = Colors.white;
  static const sidebarSurface = Colors.white;

  // Purple / lavender accent family
  static const primary = Color(0xFF6C4FD1);
  static const primaryDark = Color(0xFF5A3FC0);
  static const primarySoft = Color(0xFFEFEAFB);
  static const primarySofter = Color(0xFFF5F2FC);

  // Text
  static const textPrimary = Color(0xFF241F33);
  static const textSecondary = Color(0xFF6F6A85);
  static const textMuted = Color(0xFF9994AC);

  // Borders / dividers
  static const border = Color(0xFFEAE5F5);
  static const borderStrong = Color(0xFFDCD4EF);

  // Status — soft pastel fills with a matching darker foreground.
  static const amberBg = Color(0xFFFFF3DC);
  static const amberFg = Color(0xFFB7791F);

  static const greenBg = Color(0xFFE3F6E9);
  static const greenFg = Color(0xFF1E8A4C);

  static const redBg = Color(0xFFFCE8EA);
  static const redFg = Color(0xFFC53850);

  static const blueBg = Color(0xFFE8EEFC);
  static const blueFg = Color(0xFF3A5FCB);

  static const purpleBg = Color(0xFFEDE7FB);
  static const purpleFg = Color(0xFF6741C9);

  static const grayBg = Color(0xFFF0EEF5);
  static const grayFg = Color(0xFF6F6A85);
}

/// Standard motion durations/curves used across the portal — smooth and
/// restrained, never bouncy.
class PlatformAdminMotion {
  PlatformAdminMotion._();

  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);
  static const curve = Curves.easeOut;
}

/// Shared spacing/radius scale.
class PlatformAdminRadii {
  PlatformAdminRadii._();

  static const card = 16.0;
  static const cardSmall = 12.0;
  static const pill = 999.0;
  static const control = 10.0;
}

/// A soft-elevation, rounded white card — the base surface for all
/// Platform Admin panels. Optionally hoverable (slight lift) when it is
/// interactive (e.g. wrapped in an InkWell by the caller, or given
/// [onTap] directly).
class PlatformAdminCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool hoverable;
  final double radius;

  const PlatformAdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.hoverable = false,
    this.radius = PlatformAdminRadii.card,
  });

  @override
  State<PlatformAdminCard> createState() => _PlatformAdminCardState();
}

class _PlatformAdminCardState extends State<PlatformAdminCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.hoverable && _hovering;
    final content = AnimatedContainer(
      duration: PlatformAdminMotion.normal,
      curve: PlatformAdminMotion.curve,
      margin: widget.margin,
      padding: widget.padding,
      transform: active
          ? (Matrix4.identity()..translateByDouble(0.0, -2.0, 0.0, 1.0))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: PlatformAdminColors.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: active
              ? PlatformAdminColors.borderStrong
              : PlatformAdminColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: PlatformAdminColors.primary
                .withValues(alpha: active ? 0.10 : 0.05),
            blurRadius: active ? 20 : 10,
            offset: Offset(0, active ? 8 : 4),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap == null && !widget.hoverable) return content;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}

/// Section title + optional subtitle, used at the top of every page and
/// above grouped detail cards.
class PlatformAdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double titleSize;

  const PlatformAdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: PlatformAdminColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12.5,
              color: PlatformAdminColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Soft pastel status badge — colored text on a tinted background,
/// rounded pill shape, matching the reference's restrained badge style.
class PlatformAdminStatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const PlatformAdminStatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(PlatformAdminRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Shared button styling — kept as ButtonStyle factories (rather than
/// bespoke widgets) so call sites still use plain ElevatedButton /
/// OutlinedButton, which preserves widget-type-based test lookups while
/// centralizing the visual language.
class PlatformAdminButtonStyles {
  PlatformAdminButtonStyles._();

  static ButtonStyle primary({Color? background}) => ElevatedButton.styleFrom(
        backgroundColor: background ?? PlatformAdminColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlatformAdminRadii.pill),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed)
              ? Colors.white.withValues(alpha: 0.08)
              : null,
        ),
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      );

  static ButtonStyle secondary() => OutlinedButton.styleFrom(
        foregroundColor: PlatformAdminColors.textPrimary,
        backgroundColor: Colors.white,
        side: const BorderSide(color: PlatformAdminColors.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlatformAdminRadii.pill),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? PlatformAdminColors.primarySoft
              : null,
        ),
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      );

  static ButtonStyle danger() => OutlinedButton.styleFrom(
        foregroundColor: PlatformAdminColors.redFg,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFF2C6CE)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlatformAdminRadii.pill),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? PlatformAdminColors.redBg
              : null,
        ),
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      );
}

/// Full-bleed ambient background used behind the login page and the
/// portal shell — a pale lavender wash with a very subtle gradient, no
/// heavy saturated blocks.
class PlatformAdminBackground extends StatelessWidget {
  final Widget child;

  const PlatformAdminBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PlatformAdminColors.backgroundGradientTop,
            PlatformAdminColors.backgroundGradientBottom,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// A single rail navigation entry used by [AdminSidebar]. Renders as an
/// icon button when collapsed and as an icon+label row when the rail is
/// expanded — the label fades/clips in via [expanded] so the width
/// transition never produces text overflow.
class PlatformAdminSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const PlatformAdminSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  /// Total vertical slot the item occupies inside the rail (icon box +
  /// vertical margin).
  static const extent = 52.0;

  @override
  State<PlatformAdminSidebarItem> createState() =>
      _PlatformAdminSidebarItemState();
}

class _PlatformAdminSidebarItemState extends State<PlatformAdminSidebarItem> {
  bool _hovering = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final highlighted = _hovering || _focused;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (f) => setState(() => _focused = f),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() {
            _hovering = false;
            _pressed = false;
          }),
          child: GestureDetector(
            // Opaque so the full slot (margin included) is a tap target.
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
          // Press visuals track the raw pointer — independent of the
          // gesture arena.
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => setState(() => _pressed = true),
            onPointerUp: (_) => setState(() => _pressed = false),
            onPointerCancel: (_) => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: PlatformAdminMotion.fast,
              curve: PlatformAdminMotion.curve,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: selected || _pressed
                    ? PlatformAdminColors.primarySoft
                    : (highlighted
                        ? PlatformAdminColors.primarySofter
                        : Colors.transparent),
                borderRadius:
                    BorderRadius.circular(PlatformAdminRadii.control),
                border: Border.all(
                  color: _focused
                      ? PlatformAdminColors.borderStrong
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: selected
                        ? PlatformAdminColors.primary
                        : PlatformAdminColors.textSecondary,
                  ),
                  // The label gap lives inside the flexed region so the
                  // collapsed row never overflows (icon fills the slot).
                  Expanded(
                    child: ClipRect(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        curve: PlatformAdminMotion.curve,
                        opacity: widget.expanded ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? PlatformAdminColors.textPrimary
                                  : PlatformAdminColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          ),
      ),
    );
  }
}
