// lib/revenue/pages/revenue_index_page.dart
//
// Index of non-creator revenue sources (taxonomy doc §3):
//   1. My Shop                — marketplace product sales
//   2. Other Businesses       — registered business revenue
//   3. Contributions          — Michango campaign disbursements
//   4. Tajirika Partnership   — Tajirika+ partner earnings
//
// Each card opens a category-specific surface — either an existing
// screen (where one fits) or a "coming soon" placeholder.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../business/business_notifier.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import 'revenue_overview_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);

/// Canonical non-creator revenue categories (taxonomy doc §3).
enum NonCreatorRevenueCategory {
  shop,
  otherBusinesses,
  contributions,
  tajirikaPartnership,
}

class RevenueIndexPage extends StatelessWidget {
  const RevenueIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: isSw ? 'Mapato Mengine' : 'Other Revenue'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              isSw
                  ? 'Mapato yasiyo ya creator: duka, biashara, michango, na ushirikiano wa Tajirika.'
                  : 'Non-creator revenue: shop, businesses, contributions, and Tajirika partnership.',
              style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.45),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            for (final cat in NonCreatorRevenueCategory.values) ...[
              _CategoryCard(
                category: cat,
                isSw: isSw,
                onTap: () => _openCategory(context, cat),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openCategory(BuildContext context, NonCreatorRevenueCategory cat) async {
    HapticFeedback.selectionClick();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;

    switch (cat) {
      case NonCreatorRevenueCategory.shop:
        if (context.mounted) {
          Navigator.pushNamed(context, '/seller/analytics');
        }
        break;

      case NonCreatorRevenueCategory.otherBusinesses:
        final storage = await LocalStorageService.getInstance();
        final userId = storage.getUser()?.userId ?? 0;
        final notifier = BusinessNotifier.instance;
        final businesses = notifier.businesses;
        if (!context.mounted) return;
        if (businesses.isEmpty) {
          _showComingSoon(context, cat, isSw,
              extra: isSw
                  ? 'Bado hujasajili biashara yoyote.'
                  : "You haven't registered any businesses yet.");
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RevenueOverviewPage(
              userId: userId,
              businesses: businesses,
            ),
          ),
        );
        break;

      case NonCreatorRevenueCategory.contributions:
        Navigator.pushNamed(context, '/campaigns/mine');
        break;

      case NonCreatorRevenueCategory.tajirikaPartnership:
        Navigator.pushNamed(context, '/tajirika/partner-revenue');
        break;
    }
  }

  void _showComingSoon(
    BuildContext context,
    NonCreatorRevenueCategory cat,
    bool isSw, {
    String? extra,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_categoryLabel(cat, isSw)),
        content: Text(
          extra ??
              (isSw
                  ? 'Aina hii ya mapato itafunguliwa hivi karibuni.'
                  : 'This revenue category will unlock soon.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSw ? 'Sawa' : 'OK'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final NonCreatorRevenueCategory category;
  final bool isSw;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.isSw, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon(category), size: 22, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryLabel(category, isSw),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _categoryBlurb(category, isSw),
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _kTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

String _categoryLabel(NonCreatorRevenueCategory c, bool isSw) {
  switch (c) {
    case NonCreatorRevenueCategory.shop:
      return isSw ? 'Duka Langu' : 'My Shop';
    case NonCreatorRevenueCategory.otherBusinesses:
      return isSw ? 'Biashara Zingine' : 'Other Businesses';
    case NonCreatorRevenueCategory.contributions:
      return isSw ? 'Michango' : 'Contributions';
    case NonCreatorRevenueCategory.tajirikaPartnership:
      return isSw ? 'Ushirika wa Tajirika' : 'Tajirika Partnership';
  }
}

String _categoryBlurb(NonCreatorRevenueCategory c, bool isSw) {
  switch (c) {
    case NonCreatorRevenueCategory.shop:
      return isSw
          ? 'Mapato kutoka mauzo ya bidhaa za duka lako'
          : 'Revenue from product sales in your storefront';
    case NonCreatorRevenueCategory.otherBusinesses:
      return isSw
          ? 'Mapato kutoka biashara zako uliyozisajili'
          : 'Revenue across all the businesses you have registered';
    case NonCreatorRevenueCategory.contributions:
      return isSw
          ? 'Pesa zilizotolewa kwa kampeni zako za Michango'
          : 'Funds disbursed from your Michango campaigns';
    case NonCreatorRevenueCategory.tajirikaPartnership:
      return isSw
          ? 'Mapato ya ushirikiano wa Tajirika+ na huduma za 1:1'
          : 'Tajirika+ partner earnings + 1:1 service bookings';
  }
}

IconData _categoryIcon(NonCreatorRevenueCategory c) {
  switch (c) {
    case NonCreatorRevenueCategory.shop:
      return Icons.storefront_rounded;
    case NonCreatorRevenueCategory.otherBusinesses:
      return Icons.business_rounded;
    case NonCreatorRevenueCategory.contributions:
      return Icons.volunteer_activism_rounded;
    case NonCreatorRevenueCategory.tajirikaPartnership:
      return Icons.handshake_rounded;
  }
}
