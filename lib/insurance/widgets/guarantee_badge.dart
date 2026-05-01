import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';

/// Green shield badge shown when a partner has an active service guarantee.
class GuaranteeBadge extends StatelessWidget {
  final bool hasGuarantee;
  final int? coverageTzs;

  const GuaranteeBadge({
    super.key,
    required this.hasGuarantee,
    this.coverageTzs,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasGuarantee) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Chip(
      backgroundColor: const Color(0xFFE8F5E9),
      side: const BorderSide(color: Color(0xFF2E7D32)),
      avatar: const Icon(
        Icons.verified_user_rounded,
        size: 16,
        color: Color(0xFF2E7D32),
      ),
      label: Text(
        isSw
            ? 'Bima ya huduma${coverageTzs != null ? ' — ${_fmt(coverageTzs!)}' : ''}'
            : 'Insured${coverageTzs != null ? ' — ${_fmt(coverageTzs!)}' : ''}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TSh ${buf.toString()}';
  }
}
