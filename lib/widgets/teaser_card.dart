import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';

class TeaserCard extends StatelessWidget {
  final String text;
  final int? viewerCount;
  final VoidCallback? onTap;

  const TeaserCard({super.key, required this.text, this.viewerCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3)),
                      if (viewerCount != null) ...[
                        const SizedBox(height: 6),
                        Text('$viewerCount ${AppStringsScope.of(context)?.peopleTalking ?? "people talking"}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
