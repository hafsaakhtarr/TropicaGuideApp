import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TColors.surface,
        border: Border(top: BorderSide(color: TColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.grid_view_rounded,     index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.show_chart_rounded,    index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.check_box_outlined,    index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded,index: 3, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: active ? TColors.lime : TColors.textMuted),
          const SizedBox(height: 3),
          if (active)
            Container(
              width: 5, height: 5,
              decoration: const BoxDecoration(color: TColors.lime, shape: BoxShape.circle),
            )
          else
            const SizedBox(height: 5),
        ],
      ),
    );
  }
}