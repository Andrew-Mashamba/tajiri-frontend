// Phase 1.4 — one-time dismissible banner shown on the creator dashboard
// the moment Tajirika auto-provisioning has stamped
// `user_profiles.tajirika_auto_provisioned_at`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';

class TajirikaWelcomeBanner extends StatelessWidget {
  final VoidCallback onOpenTajirika;
  final VoidCallback onDismiss;

  const TajirikaWelcomeBanner({
    super.key,
    required this.onOpenTajirika,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw
                      ? 'Sasa wewe ni biashara ya Tajirika'
                      : 'You are now a Tajirika business',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isSw
                      ? 'Ankara, RFQ na mahitaji ya wateja vimekuwa tayari kutumika.'
                      : 'Invoices, RFQs and booking flows are ready to use.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onOpenTajirika();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 32),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(
                              isSw ? 'Fungua Tajirika' : 'Open Tajirika',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: isSw ? 'Funga' : 'Dismiss',
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onDismiss();
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 18),
              tooltip: isSw ? 'Funga' : 'Dismiss',
            ),
          ),
        ],
      ),
    );
  }
}
