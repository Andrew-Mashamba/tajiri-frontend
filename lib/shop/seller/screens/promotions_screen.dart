import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
// ignore: unused_element
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

enum _PromoType { coupon, flashSale, bundle, freeShipping }

class _Promo {
  final _PromoType type;
  final String title;
  final String detail;
  final String validity;
  final bool active;

  const _Promo({
    required this.type,
    required this.title,
    required this.detail,
    required this.validity,
    required this.active,
  });
}

/// Seller promotions — coupons, flash sales, bundles, free-shipping rules.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  late TabController _tabs;
  final List<_Promo> _promos = [];

  static const _tabLabels = ['All', 'Coupons', 'Flash Sales', 'Bundles'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _promos.addAll([
        const _Promo(
          type: _PromoType.coupon,
          title: 'WELCOME20',
          detail: '20% off on first order',
          validity: 'Expires May 31, 2026',
          active: true,
        ),
        const _Promo(
          type: _PromoType.flashSale,
          title: 'Weekend Flash Sale',
          detail: '15% off all clothing · Sat–Sun',
          validity: 'May 9–10, 2026',
          active: true,
        ),
        const _Promo(
          type: _PromoType.bundle,
          title: '3-for-2 Bundle',
          detail: 'Buy 3 items, pay for 2',
          validity: 'Ongoing',
          active: false,
        ),
        const _Promo(
          type: _PromoType.freeShipping,
          title: 'Free Shipping TZS 2000+',
          detail: 'Orders above TZS 2,000',
          validity: 'Ongoing',
          active: true,
        ),
      ]);
    });
  }

  List<_Promo> _filtered(int tabIndex) {
    if (tabIndex == 0) return _promos;
    final map = {
      1: _PromoType.coupon,
      2: _PromoType.flashSale,
      3: _PromoType.bundle,
    };
    final type = map[tabIndex];
    if (type == null) return _promos;
    return _promos.where((p) => p.type == type).toList();
  }

  HeroIcons _iconFor(_PromoType t) {
    switch (t) {
      case _PromoType.coupon:
        return HeroIcons.ticket;
      case _PromoType.flashSale:
        return HeroIcons.bolt;
      case _PromoType.bundle:
        return HeroIcons.rectangleStack;
      case _PromoType.freeShipping:
        return HeroIcons.truck;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            pinned: true,
            centerTitle: false,
            title: const Text(
              'Promotions',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kText),
            ),
            iconTheme: const IconThemeData(color: _kText),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: _kText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('+ Create', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              labelColor: _kText,
              unselectedLabelColor: _kMuted,
              indicatorColor: _kText,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs:
                  _tabLabels.map((l) => Tab(text: l)).toList(),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabs,
                children: List.generate(_tabLabels.length, (i) {
                  final items = _filtered(i);
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HeroIcon(HeroIcons.ticket,
                              style: HeroIconStyle.outline,
                              color: _kFaint,
                              size: 48),
                          const SizedBox(height: 12),
                          const Text('No promotions yet',
                              style: TextStyle(color: _kMuted)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, idx) =>
                        _PromoCard(promo: items[idx], icon: _iconFor(items[idx].type)),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.icon});
  final _Promo promo;
  final HeroIcons icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F0F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: HeroIcon(icon,
                style: HeroIconStyle.outline, color: _kText, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kText),
                ),
                const SizedBox(height: 2),
                Text(
                  promo.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 13, color: _kMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  promo.validity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: _kFaint),
                ),
              ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: promo.active
                ? const Color(0xFFE8E8E8)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            promo.active ? 'Active' : 'Paused',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: promo.active ? _kText : _kFaint),
          ),
        ),
      ]),
    );
  }
}
