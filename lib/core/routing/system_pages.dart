import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/extensions/context_extensions.dart';
import '../widgets/state_views.dart';
import 'app_routes.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: MessageView(
        icon: Icons.explore_off_outlined,
        title: context.l10n.pageNotFound,
        actionLabel: context.l10n.actionContinue,
        onAction: () => context.go(AppRoutes.dashboard),
      ),
    );
  }
}
