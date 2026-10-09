import 'package:flutter/material.dart';

import '../utils/extensions/context_extensions.dart';
import 'state_views.dart';

/// Henüz geliştirilmemiş özellik ekranları için geçici sayfa.
class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    this.showAppBar = true,
    this.actions,
  });

  final String title;
  final IconData icon;
  final bool showAppBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title), actions: actions) : null,
      body: SafeArea(
        child: MessageView(
          icon: icon,
          title: context.l10n.comingSoonTitle,
          message: context.l10n.comingSoonMessage(title),
        ),
      ),
    );
  }
}
