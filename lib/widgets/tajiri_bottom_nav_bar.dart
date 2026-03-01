import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

/// TAJIRI bottom navigation bar: DESIGN.md §5.3, §6 — 5 tabs, Heroicons, 48dp touch targets.
/// Order: Feed (home), Messages (chat), People (users), Shop (bag), Profile (user).
class TajiriBottomNavBar extends StatelessWidget {
  const TajiriBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.labels,
    this.unreadMessagesCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  /// [postsTab, messagesTab, peopleTab, shopTab, profileTab] (e.g. from AppStringsScope).
  final List<String> labels;
  /// Badge count on Messages tab (index 1). Shows "99+" when > 99.
  final int unreadMessagesCount;

  static const int _itemCount = 5;

  // DESIGN.md
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1A1A1A);
  static const Color secondary = Color(0xFF666666);
  static const Color divider = Color(0xFFE0E0E0);
  static const double iconSize = 24.0;
  static const double labelFontSize = 12.0;
  static const double barHeight = 64.0;

  String get _badgeLabel {
    if (unreadMessagesCount <= 0) return '0';
    if (unreadMessagesCount > 99) return '99+';
    return '$unreadMessagesCount';
  }

  @override
  Widget build(BuildContext context) {
    assert(labels.length >= _itemCount, 'labels must have at least $_itemCount items');
    return Container(
      height: barHeight + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: barHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_itemCount, (index) {
              final selected = currentIndex == index;
              final color = selected ? primary : secondary;
              return Expanded(
                child: _NavItem(
                  label: labels[index],
                  selected: selected,
                  color: color,
                  icon: _buildIcon(index, selected, color),
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, bool selected, Color color) {
    final style = selected ? HeroIconStyle.solid : HeroIconStyle.outline;
    Widget icon;
    switch (index) {
      case 0:
        // Feed — home (Instagram/Facebook style)
        icon = HeroIcon(HeroIcons.home, style: style, size: iconSize, color: color);
        break;
      case 1:
        // Messages — oval chat bubble (WhatsApp/Telegram style)
        icon = HeroIcon(HeroIcons.chatBubbleOvalLeft, style: style, size: iconSize, color: color);
        if (unreadMessagesCount > 0) {
          icon = Badge(
            isLabelVisible: true,
            label: Text(
              _badgeLabel,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: primary,
            child: icon,
          );
        }
        break;
      case 2:
        // People — multiple users (Facebook/Instagram people style)
        icon = HeroIcon(HeroIcons.users, style: style, size: iconSize, color: color);
        break;
      case 3:
        // Shop — shopping bag (Instagram Shop / commerce)
        icon = HeroIcon(HeroIcons.shoppingBag, style: style, size: iconSize, color: color);
        break;
      case 4:
        // Profile — user (Instagram/Facebook style)
        icon = HeroIcon(HeroIcons.user, style: style, size: iconSize, color: color);
        break;
      default:
        icon = const SizedBox.shrink();
    }
    return icon;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: TajiriBottomNavBar.labelFontSize,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
