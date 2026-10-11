import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/subscription/presentation/providers/premium_providers.dart';
import '../../features/subscription/presentation/widgets/ad_banner_slot.dart';
import '../../shared/services/ads/ad_backend.dart';
import '../utils/breakpoints.dart';
import '../utils/extensions/context_extensions.dart';

/// Ana sekmeli yapı. Telefonda alt [NavigationBar], tablet ve geniş
/// ekranlarda [NavigationRail] kullanır.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(WidgetRef ref, int index) {
    final changed = index != navigationShell.currentIndex;
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    if (!changed) return;
    unawaited(
      ref
          .read(premiumAdCoordinatorProvider)
          .showInterstitial(AdPlacement.navigation),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final destinations = [
      (Icons.today_outlined, Icons.today, l10n.navHome),
      (Icons.menu_book_outlined, Icons.menu_book, l10n.navDiary),
      (Icons.restaurant_menu_outlined, Icons.restaurant_menu, l10n.navPlans),
      (Icons.insights_outlined, Icons.insights, l10n.navProgress),
      (Icons.person_outline, Icons.person, l10n.navProfile),
    ];

    if (Breakpoints.of(context) == WindowSize.compact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdBannerSlot(),
            NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onSelect(ref, index),
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: label,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onSelect(ref, index),
              extended: Breakpoints.of(context) == WindowSize.expanded,
              labelType: Breakpoints.of(context) == WindowSize.expanded
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: navigationShell),
                  const AdBannerSlot(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
