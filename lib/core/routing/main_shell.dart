import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/breakpoints.dart';
import '../utils/extensions/context_extensions.dart';

/// Ana sekmeli yapı. Telefonda alt [NavigationBar], tablet ve geniş
/// ekranlarda [NavigationRail] kullanır.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          destinations: [
            for (final (icon, selected, label) in destinations)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected),
                label: label,
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
              onDestinationSelected: _onSelect,
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
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}
