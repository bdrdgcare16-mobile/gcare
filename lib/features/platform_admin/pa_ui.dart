// lib/features/platform_admin/pa_ui.dart
//
// Shared Platform Admin design system: purple-and-white SaaS tokens and
// reusable widgets (cards, badges, buttons, states, hover helpers) so
// every portal page shares one visual language instead of hardcoding
// styles per page. UI only — no business logic lives here.

import 'package:flutter/material.dart';

abstract final class PaColors {
  static const primary = Color(0xFF6F42C1);
  static const deep = Color(0xFF4B287C);
  static const accent = Color(0xFF9254DE);
  static const bg = Color(0xFFF7F3FC);
  static const soft = Color(0xFFEEE5FA);
  static const card = Colors.white;
  static const text = Color(0xFF24213D);
  static const muted = Color(0xFF817B91);
  static const border = Color(0xFFEAE3F3);

  static const success = Color(0xFF2E9E6B);
  static const warning = Color(0xFFD98E04);
  static const danger = Color(0xFFD64545);
  static const info = Color(0xFF3D7BD9);
}

const kPaAnim = Duration(milliseconds: 180);
const kPaRadius = 16.0;

/// Standard page padding used by every Platform Admin body.
const kPaPagePadding = EdgeInsets.fromLTRB(28, 24, 28, 32);

/// Uniform input decoration (search fields, form fields).
InputDecoration paInputDecoration(
  String hint, {
  IconData? prefixIcon,
  Widget? suffixIcon,
  String? label,
}) {
  return InputDecoration(
    hintText: label == null ? hint : null,
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, size: 18, color: PaColors.muted)
        : null,
    suffixIcon: suffixIcon,
    hintStyle: const TextStyle(fontSize: 13, color: PaColors.muted),
    labelStyle: const TextStyle(fontSize: 13, color: PaColors.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PaColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PaColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PaColors.primary, width: 1.4),
    ),
  );
}

/// Tracks hover state and forwards it to a builder — the lightweight
/// primitive behind every hover animation in the portal.
class PaHover extends StatefulWidget {
  final Widget Function(BuildContext context, bool hovering) builder;
  final VoidCallback? onTap;
  final MouseCursor cursor;

  const PaHover({
    super.key,
    required this.builder,
    this.onTap,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<PaHover> createState() => _PaHoverState();
}

class _PaHoverState extends State<PaHover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? widget.cursor : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.builder(context, _hovering),
      ),
    );
  }
}

/// White rounded card with the shared soft shadow + border.
class PaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const PaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: PaColors.card,
        borderRadius: BorderRadius.circular(kPaRadius),
        border: Border.all(color: PaColors.border),
        boxShadow: [
          BoxShadow(
            color: PaColors.deep.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Card that gently lifts + tints its border on hover. Wraps [PaCard]
/// visuals in [PaHover]; tap is optional.
class PaHoverCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const PaHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return PaHover(
      onTap: onTap,
      builder: (context, hovering) => AnimatedContainer(
        duration: kPaAnim,
        curve: Curves.easeOut,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: PaColors.card,
          borderRadius: BorderRadius.circular(kPaRadius),
          border: Border.all(
            color: hovering
                ? PaColors.primary.withValues(alpha: 0.45)
                : PaColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: PaColors.deep.withValues(alpha: hovering ? 0.10 : 0.05),
              blurRadius: hovering ? 18 : 12,
              offset: Offset(0, hovering ? 7 : 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Compact stat card: purple icon tile, large number, small label.
/// ~118px tall at normal density.
class PaStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const PaStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = PaColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return PaHoverCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: PaColors.text,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PaColors.muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.trending_up,
              size: 16, color: color.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

/// Soft status pill — tinted background, colored text, small dot.
class PaBadge extends StatelessWidget {
  final String text;
  final Color color;

  const PaBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent status → color mapping shared by all PA pages.
Color paStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
    case 'approved':
      return PaColors.success;
    case 'pending':
    case 'pending_approval':
    case 'pending_verification':
    case 'suspended':
      return PaColors.warning;
    case 'changes_requested':
      return PaColors.info;
    case 'rejected':
    case 'inactive':
      return PaColors.danger;
    default:
      return PaColors.muted;
  }
}

/// Primary filled action button.
class PaPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  const PaPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : (icon != null ? Icon(icon, size: 17) : null);
    return ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: child ?? const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: PaColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: PaColors.primary.withValues(alpha: 0.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Secondary outline action button.
class PaOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const PaOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? PaColors.primary;
    final btn = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.chevron_right, size: 17, color: c),
      label: Text(label, style: TextStyle(color: c)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        side: BorderSide(color: c.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    return btn;
  }
}

/// Page heading (title + muted subtitle) used at the top of every body.
class PaPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PaPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: PaColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: PaColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Centered loading state.
class PaLoading extends StatelessWidget {
  const PaLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: CircularProgressIndicator(color: PaColors.primary),
      ),
    );
  }
}

/// Centered error state with optional retry.
class PaErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const PaErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: PaColors.danger),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PaColors.danger,
                fontSize: 13,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              PaOutlineButton(
                  label: 'Retry', onPressed: onRetry, icon: Icons.refresh),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered empty state.
class PaEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const PaEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: PaColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PaColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list row that tints on hover (for companies/registrations/requests).
class PaListRow extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PaListRow({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PaHover(
      onTap: onTap,
      builder: (context, hovering) => AnimatedContainer(
        duration: kPaAnim,
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color:
              hovering ? PaColors.soft.withValues(alpha: 0.45) : PaColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hovering
                ? PaColors.primary.withValues(alpha: 0.35)
                : PaColors.border,
          ),
          boxShadow: [
            if (hovering)
              BoxShadow(
                color: PaColors.deep.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Segmented tab chip (matches ChoiceChip behaviour, PA styling).
class PaTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const PaTabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PaHover(
      onTap: onSelected,
      builder: (context, hovering) => AnimatedContainer(
        duration: kPaAnim,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? PaColors.primary
              : hovering
                  ? PaColors.soft
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? PaColors.primary : PaColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : hovering
                    ? PaColors.deep
                    : PaColors.muted,
          ),
        ),
      ),
    );
  }
}
