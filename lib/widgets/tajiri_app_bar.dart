import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

/// TAJIRI AppBar: DESIGN.md §5 — modern, monochrome, 48dp touch targets, Heroicons.
/// Use for all standard and tabbed screens. For SliverAppBar, use same colors/theme below.
class TajiriAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TajiriAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions = const [],
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.surfaceTintColor,
  });

  /// Short title text (uses DESIGN.md titleLarge: 20px, weight 700, #1A1A1A).
  final String? title;

  /// Custom title widget (e.g. search field). If set, [title] is ignored.
  final Widget? titleWidget;

  /// Custom leading widget. If null and [automaticallyImplyLeading] is true, back button with HeroIcons.arrowLeft.
  final Widget? leading;

  /// When true and [leading] is null, shows back arrow (HeroIcons.arrowLeft) that pops route.
  final bool automaticallyImplyLeading;

  /// Action buttons (use [TajiriAppBarAction] for consistent 48dp + Heroicons).
  final List<Widget> actions;

  /// Optional bottom bar (e.g. TabBar).
  final PreferredSizeWidget? bottom;

  /// Default: surface #FFFFFF (DESIGN.md).
  final Color? backgroundColor;

  /// Default: primaryText #1A1A1A (DESIGN.md).
  final Color? foregroundColor;

  /// Default: 0 (flat, modern).
  final double? elevation;

  /// Elevation when content scrolls under. Default: 0.
  final double? scrolledUnderElevation;

  /// Surface tint when scrolling. Default: transparent.
  final Color? surfaceTintColor;

  // DESIGN.md tokens
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF666666);
  static const double actionIconSize = 20.0;
  static const double leadingIconSize = 24.0;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  static const Color _dividerColor = Color(0xFFE0E0E0);

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showLeading = leading != null ||
        (automaticallyImplyLeading && canPop);

    const double titleLeftMargin = 20.0;

    final Widget? titleChild = titleWidget ??
        (title != null
            ? Text(
                _capitalizeFirst(title!),
                style: const TextStyle(
                  color: primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null);

    return AppBar(
      title: titleChild != null
          ? Padding(
              padding: const EdgeInsets.only(left: titleLeftMargin),
              child: titleChild,
            )
          : null,
      centerTitle: false,
      titleSpacing: 0,
      elevation: elevation ?? 0,
      scrolledUnderElevation: scrolledUnderElevation ?? 0,
      surfaceTintColor: surfaceTintColor ?? Colors.transparent,
      backgroundColor: backgroundColor ?? surface,
      foregroundColor: foregroundColor ?? primaryText,
      iconTheme: IconThemeData(
        color: foregroundColor ?? primaryText,
        size: leadingIconSize,
      ),
      leading: showLeading
          ? (leading ??
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: HeroIcon(
                  HeroIcons.arrowLeft,
                  style: HeroIconStyle.outline,
                  size: leadingIconSize,
                  color: foregroundColor ?? primaryText,
                ),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ))
          : null,
      actions: actions,
      bottom: bottom == null
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(
                  bottom!.preferredSize.height + 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  bottom!,
                  const Divider(height: 1, color: _dividerColor, thickness: 1),
                ],
              ),
            ),
    );
  }

  /// Builds an action button with Heroicon, 48dp touch target, DESIGN.md icon size.
  static Widget action({
    required HeroIcons icon,
    VoidCallback? onPressed,
    String? tooltip,
    HeroIconStyle style = HeroIconStyle.outline,
    Color? color,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: HeroIcon(
        icon,
        style: style,
        size: actionIconSize,
        color: color ?? primaryText,
      ),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }

  /// Theme data for use in custom SliverAppBar / AppBar (same colors and icon theme).
  static IconThemeData get iconTheme => const IconThemeData(
        color: primaryText,
        size: actionIconSize,
      );

  static Color get surfaceColor => surface;
  static Color get primaryTextColor => primaryText;
  static Color get secondaryTextColor => secondaryText;
}
