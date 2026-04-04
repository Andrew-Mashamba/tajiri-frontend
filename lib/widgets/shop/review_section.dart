// lib/widgets/shop/review_section.dart
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/shop_models.dart';
import '../../widgets/shop/product_card.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSurface = Color(0xFFFFFFFF);

class ReviewSection extends StatelessWidget {
  final List<Review> reviews;
  final ReviewStats? stats;
  final bool isLoading;
  final VoidCallback? onWriteReview;
  final VoidCallback? onSeeAll;

  const ReviewSection({
    super.key,
    required this.reviews,
    this.stats,
    this.isLoading = false,
    this.onWriteReview,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s?.customerReviews ?? 'Customer Reviews',
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onWriteReview != null)
                GestureDetector(
                  onTap: onWriteReview,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kPrimaryText,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HeroIcon(HeroIcons.plus, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          s?.writeReview ?? 'Write a review',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (reviews.isNotEmpty && onSeeAll != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    s?.viewAll ?? 'View All',
                    style: const TextStyle(
                      color: _kSecondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: _kPrimaryText,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const HeroIcon(
                      HeroIcons.chatBubbleBottomCenterText,
                      size: 40,
                      color: _kTertiaryText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s?.noReviewsYet ?? 'No reviews yet',
                      style: const TextStyle(
                        color: _kSecondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (stats != null) _buildRatingSummary(context),
            const SizedBox(height: 16),
            ...reviews.take(3).map((review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReviewCard(review: review),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSummary(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Row(
      children: [
        Column(
          children: [
            Text(
              stats!.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                return HeroIcon(
                  HeroIcons.star,
                  style: index < stats!.averageRating.round()
                      ? HeroIconStyle.solid
                      : HeroIconStyle.outline,
                  size: 16,
                  color: const Color(0xFFF59E0B),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '${stats!.totalReviews} ${s?.reviews ?? 'reviews'}',
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final rating = 5 - index;
              final percent = stats!.getPercentForRating(rating);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '$rating',
                      style: const TextStyle(
                        color: _kSecondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor: _kDivider,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFF59E0B),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
