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
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final selectedColor = isDark ? Colors.white : AppTheme.darkText;
    const unselectedColor = Color(0xFFA4AAB8);

    return Scaffold(
      backgroundColor: bg,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkCardBorder : const Color(0xFFEEEEF2),
              width: 0.8,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: bg,
          currentIndex: navigationShell.currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            // 1. Feed (Akış)
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.home_outlined, size: 23),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.home_rounded, size: 23),
              ),
              label: loc.translate('feed'),
            ),
            // 2. Explore (Movie Explorer - Dribbble ana kart görünümü)
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.search_rounded, size: 23),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.search_rounded, size: 23),
              ),
              label: loc.translate('explore'),
            ),
            // 3. You (Profil)
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_outline_rounded, size: 23),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_rounded, size: 23),
              ),
              label: loc.translate('you'),
            ),
          ],
        ),
      ),
    );
  }
}
