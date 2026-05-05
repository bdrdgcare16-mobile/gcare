import 'package:flutter/material.dart';

// ---------- Global tap guard ----------
final Set<String> _guardedKeys = {};

/// Wraps an async action to prevent duplicate execution.
/// Uses a global Set to track in-flight actions by unique key.
Future<T?> guardedAction<T>(
  String key,
  Future<T> Function() action, {
  Duration resetAfter = const Duration(seconds: 5),
}) async {
  if (_guardedKeys.contains(key)) return null;
  _guardedKeys.add(key);
  try {
    return await action();
  } catch (e) {
    _guardedKeys.remove(key);
    rethrow;
  } finally {
    // Auto-reset after a reasonable time to handle edge cases
    Future.delayed(resetAfter, () => _guardedKeys.remove(key));
  }
}

/// Wraps a sync action to prevent duplicate execution.
void guardedSyncAction(
  String key,
  VoidCallback action, {
  Duration resetAfter = const Duration(seconds: 1),
}) {
  if (_guardedKeys.contains(key)) return;
  _guardedKeys.add(key);
  try {
    action();
  } catch (e) {
    _guardedKeys.remove(key);
    rethrow;
  } finally {
    Future.delayed(resetAfter, () => _guardedKeys.remove(key));
  }
}

// ---------- Widget Wrappers ----------

/// InkWell with built-in tap debouncing
class DebouncedInkWell extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color? splashColor;
  final Color? highlightColor;

  const DebouncedInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.splashColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null 
          ? () => guardedSyncAction(key.toString(), onTap!)
          : null,
      splashColor: splashColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// GestureDetector with built-in tap debouncing
class DebouncedGestureDetector extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final HitTestBehavior? behavior;

  const DebouncedGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.behavior,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null 
          ? () => guardedSyncAction(key.toString(), onTap!)
          : null,
      behavior: behavior,
      child: child,
    );
  }
}

/// ElevatedButton with built-in tap guarding
class GuardedElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const GuardedElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed != null 
          ? () => guardedSyncAction(key.toString(), onPressed!)
          : null,
      style: style,
      child: child,
    );
  }
}

/// IconButton with built-in tap guarding
class GuardedIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final double? iconSize;
  final Color? color;

  const GuardedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed != null 
          ? () => guardedSyncAction(key.toString(), onPressed!)
          : null,
      icon: icon,
      iconSize: iconSize,
      color: color,
    );
  }
}
