import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class MainNavigationScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScreen({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final bg = isDark ? AppTheme.darkCard : Colors.white;
    const activeColor = AppTheme.primaryColor;
    final inactiveColor = isDark ? Colors.white54 : AppTheme.mutedText;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.borderColor;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 84,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        child: Theme(
          data: theme.copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            currentIndex: navigationShell.currentIndex,
            onTap: _onItemTapped,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              // 1. Feed
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_outlined, size: 22),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_rounded, size: 22),
                ),
                label: loc.translate('feed'),
              ),
              // 2. Explore
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.search_rounded, size: 22),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.search_rounded, size: 22),
                ),
                label: loc.translate('explore'),
              ),
              // 3. You
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_outline_rounded, size: 22),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_rounded, size: 22),
                ),
                label: loc.translate('you'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
