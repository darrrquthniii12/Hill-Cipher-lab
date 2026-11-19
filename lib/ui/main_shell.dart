import 'package:flutter/material.dart';

import '../state/cipher_controller.dart';
import 'pages/crypto_lab_page.dart';
import 'pages/frequency_chart_page.dart';
import 'pages/history_vault_page.dart';
import 'pages/math_inspector_page.dart';
import 'widgets/common_widgets.dart';

/// Kerangka navigasi adaptif Material 3 untuk Hill Cipher Lab.
///
/// - Lebar >= 800 px (Windows/Desktop/Tablet): menggunakan `NavigationRail` di kiri.
/// - Lebar < 800 px (Android/Mobile): menggunakan `NavigationBar` di bawah.
/// - Mengetuk area kosong otomatis menutup keyboard lunak di Android.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.controller,
  });

  final CipherController controller;

  static const List<_NavDestinationItem> _destinations = <_NavDestinationItem>[
    _NavDestinationItem(
      label: 'Lab',
      icon: Icons.science_outlined,
      selectedIcon: Icons.science_rounded,
    ),
    _NavDestinationItem(
      label: 'Bedah Rumus',
      icon: Icons.functions_outlined,
      selectedIcon: Icons.functions_rounded,
    ),
    _NavDestinationItem(
      label: 'Frekuensi',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    _NavDestinationItem(
      label: 'Riwayat',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final LabColors colors = labColorsOf(context);
        final int activeIndex = controller.activeTabIndex;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isDesktop = constraints.maxWidth >= 800;

              return Scaffold(
                backgroundColor: colors.background,
                appBar: AppBar(
                  backgroundColor: colors.card,
                  foregroundColor: colors.textPrimary,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Divider(height: 1, color: colors.border),
                  ),
                  title: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colors.emerald.withAlpha(32),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.emerald.withAlpha(120),
                          ),
                        ),
                        child: Icon(
                          Icons.enhanced_encryption_rounded,
                          size: 20,
                          color: colors.emerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Hill Cipher Lab',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isDesktop) ...<Widget>[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.cyan.withAlpha(28),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.cyan.withAlpha(100),
                            ),
                          ),
                          child: Text(
                            '100% Offline • RAM Session',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.cyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: OutlinedButton.icon(
                        onPressed: controller.toggleThemeMode,
                        icon: Icon(
                          controller.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 18,
                          color: controller.isDarkMode
                              ? colors.amber
                              : colors.cyan,
                        ),
                        label: Text(
                          controller.isDarkMode ? 'Light' : 'Dark',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: Row(
                  children: <Widget>[
                    if (isDesktop) ...<Widget>[
                      NavigationRail(
                        selectedIndex: activeIndex,
                        backgroundColor: colors.card,
                        indicatorColor: colors.emerald.withAlpha(42),
                        labelType: NavigationRailLabelType.all,
                        selectedIconTheme: IconThemeData(color: colors.emerald),
                        unselectedIconTheme:
                            IconThemeData(color: colors.textSecondary),
                        selectedLabelTextStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.emerald,
                        ),
                        unselectedLabelTextStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                        onDestinationSelected: (int idx) {
                          FocusScope.of(context).unfocus();
                          controller.setTabIndex(idx);
                        },
                        destinations: _destinations
                            .map(
                              (_NavDestinationItem d) =>
                                  NavigationRailDestination(
                                icon: Icon(d.icon),
                                selectedIcon: Icon(d.selectedIcon),
                                label: Text(d.label),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      VerticalDivider(width: 1, color: colors.border),
                    ],
                    Expanded(
                      child: IndexedStack(
                        index: activeIndex,
                        children: <Widget>[
                          CryptoLabPage(controller: controller),
                          MathInspectorPage(controller: controller),
                          FrequencyChartPage(controller: controller),
                          HistoryVaultPage(controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: isDesktop
                    ? null
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: colors.border),
                          ),
                        ),
                        child: NavigationBar(
                          selectedIndex: activeIndex,
                          backgroundColor: colors.card,
                          indicatorColor: colors.emerald.withAlpha(42),
                          onDestinationSelected: (int idx) {
                            FocusScope.of(context).unfocus();
                            controller.setTabIndex(idx);
                          },
                          destinations: _destinations
                              .map(
                                (_NavDestinationItem d) =>
                                    NavigationDestination(
                                  icon: Icon(
                                    d.icon,
                                    color: colors.textSecondary,
                                  ),
                                  selectedIcon: Icon(
                                    d.selectedIcon,
                                    color: colors.emerald,
                                  ),
                                  label: d.label,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NavDestinationItem {
  const _NavDestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
