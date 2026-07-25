import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_context.dart';
import '../../../core/utils/local_lang.dart';

class RoleHomeScaffold extends StatelessWidget {
  const RoleHomeScaffold({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.pages,
    required this.destinations,
    this.useTenantBottomBar = false,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<Widget> pages;
  final List<NavigationDestination> destinations;
  final bool useTenantBottomBar;

  MediaQueryData _bottomBarMediaQuery(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return mediaQuery.copyWith(
      textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomBarMediaQuery = _bottomBarMediaQuery(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: pages[currentIndex]),
      bottomNavigationBar: useTenantBottomBar
          ? MediaQuery(
              data: bottomBarMediaQuery,
              child: TenantMarketplaceBottomBar(
                selectedIndex: currentIndex,
                onSelected: onSelected,
              ),
            )
          : MediaQuery(
              data: bottomBarMediaQuery,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: NavigationBar(
                  height: 92,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  selectedIndex: currentIndex,
                  onDestinationSelected: onSelected,
                  destinations: destinations,
                ),
              ),
            ),
    );
  }
}

class TenantMarketplaceBottomBar extends StatelessWidget {
  const TenantMarketplaceBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 10,
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TenantBottomBarItem(
                      index: 0,
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                      icon: Icons.home_rounded,
                      label: context.loc(AppLocalLang.home),
                    ),
                  ),
                  Expanded(
                    child: _TenantBottomBarItem(
                      index: 1,
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                      icon: Icons.search_rounded,
                      label: context.loc(AppLocalLang.search),
                    ),
                  ),
                  const SizedBox(width: 84),
                  Expanded(
                    child: _TenantBottomBarItem(
                      index: 3,
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                      icon: Icons.favorite_border_rounded,
                      selectedIcon: Icons.favorite_rounded,
                      label: context.loc(AppLocalLang.saved),
                    ),
                  ),
                  Expanded(
                    child: _TenantBottomBarItem(
                      index: 4,
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                      icon: Icons.menu_rounded,
                      label: context.loc(AppLocalLang.menu),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => onSelected(2),
              child: Column(
                children: [
                  Container(
                    height: 78,
                    width: 78,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.card,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc(AppLocalLang.post),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selectedIndex == 2
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantBottomBarItem extends StatelessWidget {
  const _TenantBottomBarItem({
    required this.index,
    required this.selectedIndex,
    required this.onSelected,
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final int index;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;

    return InkWell(
      onTap: () => onSelected(index),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 42,
              width: isSelected ? 50 : 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isSelected ? selectedIcon ?? icon : icon,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
