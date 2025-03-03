import 'package:flutter/material.dart';

class ContextualAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Widget leading;
  final List<Widget> actions;

  const ContextualAppBar({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.leading,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      leading: leading,
      title: Text(title),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}