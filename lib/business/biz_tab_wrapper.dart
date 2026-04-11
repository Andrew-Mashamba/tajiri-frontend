// lib/business/biz_tab_wrapper.dart
// Wrapper that provides ALL user businesses to feature pages.
// No switching — features show content from all businesses,
// grouped with dividers (business name as section header).
import 'package:flutter/material.dart';
import 'business_notifier.dart';
import 'models/business_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

/// Provides all businesses to a feature page.
/// The [builder] receives the full list — the feature page groups content
/// by business with section headers/dividers.
class BizTabWrapper extends StatelessWidget {
  final int userId;

  /// Receives: userId, all businesses, first business (convenience), first businessId.
  final Widget Function(int userId, List<Business> businesses, Business? first, int? firstId) builder;

  const BizTabWrapper({super.key, required this.userId, required this.builder});

  @override
  Widget build(BuildContext context) {
    final notifier = BusinessNotifier.instance;

    if (!notifier.loaded) {
      notifier.load(userId);
    }

    return ValueListenableBuilder<List<Business>>(
      valueListenable: notifier,
      builder: (context, _, __) {
        if (!notifier.loaded) {
          return const Scaffold(
            backgroundColor: _kBackground,
            body: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
          );
        }

        final businesses = notifier.businesses;

        if (businesses.isEmpty) {
          return Scaffold(
            backgroundColor: _kBackground,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_center_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No business registered yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a business from "My Businesses" to use this feature.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final first = businesses.first;
        return builder(userId, businesses, first, first.id);
      },
    );
  }
}

/// Helper widget: section header showing business name as a divider.
/// Use this inside feature pages to separate content per business.
class BusinessSectionHeader extends StatelessWidget {
  final Business business;
  final bool showDivider;

  const BusinessSectionHeader({super.key, required this.business, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          const Divider(height: 32, thickness: 0.5, color: Color(0xFFE0E0E0)),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    business.name.isNotEmpty ? business.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  business.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (business.tinNumber != null)
                Text(
                  'TIN: ${business.tinNumber}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
