import 'package:flutter/material.dart';

/// Centralized visual theme for the Admin module.
///
/// AppBar color is the exact color used by the Admin Dashboard AppBar.
const Color kAdminAppBarColor = Color(0xFF6A1B9A);

/// AppBar factory with the uniform Admin Dashboard styling.
/// Pass through any page-specific params (title, actions, leading,
/// bottom, etc.) — only the colors are enforced.
AppBar adminAppBar({
  Key? key,
  Widget? title,
  List<Widget>? actions,
  Widget? leading,
  bool? centerTitle,
  bool automaticallyImplyLeading = true,
  double? elevation,
  PreferredSizeWidget? bottom,
  IconThemeData? iconTheme,
  IconThemeData? actionsIconTheme,
  TextStyle? titleTextStyle,
  TextStyle? toolbarTextStyle,
  Widget? flexibleSpace,
  ShapeBorder? shape,
  double? titleSpacing,
  double? toolbarHeight,
  double? leadingWidth,
}) {
  return AppBar(
    key: key,
    title: title,
    actions: actions,
    leading: leading,
    centerTitle: centerTitle,
    automaticallyImplyLeading: automaticallyImplyLeading,
    elevation: elevation,
    bottom: bottom,
    iconTheme: iconTheme,
    actionsIconTheme: actionsIconTheme,
    titleTextStyle: titleTextStyle,
    toolbarTextStyle: toolbarTextStyle,
    flexibleSpace: flexibleSpace,
    shape: shape,
    titleSpacing: titleSpacing,
    toolbarHeight: toolbarHeight,
    leadingWidth: leadingWidth,
    backgroundColor: kAdminAppBarColor,
    foregroundColor: Colors.white,
  );
}
