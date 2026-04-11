// Tender list item card widget
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kUrgent = Color(0xFFD32F2F);
const Color _kWarning = Color(0xFFE65100);

class TenderCard extends StatelessWidget {
  final Tender tender;
  final VoidCallback? onTap;

  const TenderCard({super.key, required this.tender, this.onTap});

  @override
  Widget build(BuildContext context) {
    final days = tender.daysRemaining;
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: tender.isUrgent
              ? Border.all(color: _kUrgent.withValues(alpha: 0.3), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: category + deadline
              Row(
                children: [
                  _buildCategoryBadge(),
                  const Spacer(),
                  if (tender.status == TenderStatus.active && days >= 0)
                    _buildCountdown(days, isSwahili)
                  else if (tender.isClosed)
                    _buildClosedBadge(isSwahili),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                tender.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Institution
              Text(
                tender.institutionDisplay,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Bottom row: reference + documents
              Row(
                children: [
                  if (tender.referenceNumber != null) ...[
                    Icon(Icons.tag_rounded, size: 14, color: _kSecondary.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        tender.referenceNumber!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _kSecondary.withValues(alpha: 0.8),
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (tender.documents.isNotEmpty) ...[
                    Icon(Icons.attach_file_rounded, size: 14, color: _kSecondary.withValues(alpha: 0.6)),
                    const SizedBox(width: 2),
                    Text(
                      '${tender.documents.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  if (tender.closingDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today_rounded, size: 13, color: _kSecondary.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(tender.closingDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _kSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tender.category.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _kPrimary,
        ),
      ),
    );
  }

  Widget _buildCountdown(int days, bool isSwahili) {
    final isUrgent = days <= 3;
    final isWarning = days <= 7;
    final color = isUrgent ? _kUrgent : isWarning ? _kWarning : _kSecondary;

    String label;
    if (isSwahili) {
      label = days == 0
          ? 'Leo!'
          : days == 1
              ? 'Siku 1 imebaki'
              : 'Siku $days zimebaki';
    } else {
      label = days == 0
          ? 'Today!'
          : days == 1
              ? '1 day left'
              : '$days days left';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUrgent) ...[
            Icon(Icons.warning_amber_rounded, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedBadge(bool isSwahili) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isSwahili ? 'Imefungwa' : 'Closed',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF999999),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Use standard English abbreviations (language-neutral for dates)
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
