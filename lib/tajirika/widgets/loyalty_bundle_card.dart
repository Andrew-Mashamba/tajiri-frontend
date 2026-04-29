import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/loyalty_bundle.dart';
import '../services/loyalty_bundle_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec line 1206 — renders the partner's active loyalty bundles as a
/// horizontal rail on partner_profile_page. Each card shows
/// services-count + validity + savings + Buy CTA.
class LoyaltyBundleRail extends StatefulWidget {
  final int partnerUserId;
  final int? viewerUserId;
  final bool isOwnProfile;
  const LoyaltyBundleRail({
    super.key,
    required this.partnerUserId,
    required this.viewerUserId,
    this.isOwnProfile = false,
  });

  @override
  State<LoyaltyBundleRail> createState() => _LoyaltyBundleRailState();
}

class _LoyaltyBundleRailState extends State<LoyaltyBundleRail> {
  bool _loading = true;
  List<LoyaltyBundle> _bundles = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await LoyaltyBundleService.listForPartner(
      partnerUserId: widget.partnerUserId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _bundles = res.items.where((b) => b.isActive).toList();
    });
  }

  Future<void> _purchase(LoyaltyBundle b) async {
    final viewer = widget.viewerUserId;
    if (viewer == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Nunua paketi?' : 'Purchase bundle?'),
        content: Text(
          _isSwahili
              ? '${b.name}\nUtatumiwa TZS ${NumberFormat('#,##0').format(b.priceTzs)} kutoka mfuko wako.'
              : '${b.name}\nTZS ${NumberFormat('#,##0').format(b.priceTzs)} will be charged to your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Nunua' : 'Buy'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await LoyaltyBundleService.purchase(
      bundleId: b.id,
      customerUserId: viewer,
    );
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(
        ok
            ? (_isSwahili ? 'Paketi imenunuliwa' : 'Bundle purchased')
            : (_isSwahili ? 'Imeshindikana' : 'Purchase failed'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_bundles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.card_giftcard_rounded,
                size: 14, color: _kPrimary),
            const SizedBox(width: 6),
            Text(
              _isSwahili ? 'Paketi za uaminifu' : 'Loyalty bundles',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _bundles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _bundleCard(_bundles[i]),
          ),
        ),
      ],
    );
  }

  Widget _bundleCard(LoyaltyBundle b) {
    final fmt = NumberFormat('#,##0');
    final hasOriginal = b.originalPriceTzs != null && b.savingsTzs > 0;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            b.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _isSwahili
                ? '${b.servicesCount} huduma • ${b.validityDays} siku'
                : '${b.servicesCount} services • ${b.validityDays} days',
            style: const TextStyle(fontSize: 10, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TZS ${fmt.format(b.priceTzs)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kAccent,
                ),
              ),
              if (hasOriginal) ...[
                const SizedBox(width: 4),
                Text(
                  fmt.format(b.originalPriceTzs),
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          if (hasOriginal)
            Text(
              _isSwahili
                  ? 'Punguzo ${b.savingsPct}%'
                  : '-${b.savingsPct}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kAccent,
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: widget.isOwnProfile
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBorder),
                      foregroundColor: _kSecondary,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      _isSwahili ? 'Yako' : 'Yours',
                      style: const TextStyle(fontSize: 11),
                    ),
                  )
                : ElevatedButton(
                    onPressed: widget.viewerUserId == null
                        ? null
                        : () => _purchase(b),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      _isSwahili ? 'Nunua' : 'Buy',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
