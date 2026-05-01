import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';

/// Gold crown badge shown when a partner has an active Tajirika+ subscription.
class TajirikaPlusBadge extends StatelessWidget {
  final bool isPro;

  const TajirikaPlusBadge({super.key, this.isPro = false});

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Chip(
      backgroundColor: const Color(0xFFFFF8E1),
      side: const BorderSide(color: Color(0xFFFFA000)),
      avatar: const Icon(
        Icons.workspace_premium_rounded,
        size: 16,
        color: Color(0xFFFFA000),
      ),
      label: Text(
        isPro
            ? (isSw ? 'Tajirika+ Pro' : 'Tajirika+ Pro')
            : (isSw ? 'Tajirika+' : 'Tajirika+'),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFA000),
        ),
      ),
    );
  }
}
