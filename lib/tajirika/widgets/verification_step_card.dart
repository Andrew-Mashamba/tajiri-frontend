import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class VerificationStepCard extends StatelessWidget {
  final VerificationItem item;
  final bool isSwahili;
  final VoidCallback? onAction;

  const VerificationStepCard({
    super.key,
    required this.item,
    this.isSwahili = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(item.statusIcon, color: item.statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili ? item.typeLabelSwahili : item.typeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isSwahili ? item.statusLabelSwahili : item.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.rejectionReason!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFF44336)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (item.needsAction && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(48, 36),
              ),
              child: Text(
                item.isPending
                    ? (isSwahili ? 'Wasilisha' : 'Submit')
                    : (isSwahili ? 'Wasilisha Tena' : 'Resubmit'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
