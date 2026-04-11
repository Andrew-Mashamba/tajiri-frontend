// Institution list tile widget
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class InstitutionTile extends StatelessWidget {
  final Institution institution;
  final VoidCallback? onTap;
  final VoidCallback? onFollowToggle;

  const InstitutionTile({
    super.key,
    required this.institution,
    this.onTap,
    this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: institution.isFollowed
              ? Border.all(color: _kPrimary.withValues(alpha: 0.15), width: 1)
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _initials(institution.name),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      institution.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _buildCategoryBadge(),
                        const SizedBox(width: 8),
                        Text(
                          isSwahili
                              ? 'Zabuni ${institution.activeTenders}'
                              : '${institution.activeTenders} tenders',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Follow button
              GestureDetector(
                onTap: onFollowToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: institution.isFollowed ? _kPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: institution.isFollowed ? _kPrimary : _kSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    institution.isFollowed
                        ? (isSwahili ? 'Unafuatilia' : 'Following')
                        : (isSwahili ? 'Fuatilia' : 'Follow'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: institution.isFollowed ? Colors.white : _kPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        institution.category.label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _kSecondary),
      ),
    );
  }

  String _initials(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}
