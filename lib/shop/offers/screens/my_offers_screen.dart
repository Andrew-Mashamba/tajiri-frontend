import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/local_storage_service.dart';
import '../models/offer_models.dart';
import '../services/offer_service.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

/// Buyer screen: view all sent offers (active + history).
class MyOffersScreen extends StatefulWidget {
  final int currentUserId;

  const MyOffersScreen({super.key, required this.currentUserId});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductOffer> _offers = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_token == null) {
      setState(() => _loading = false);
      return;
    }
    final offers = await OfferService.listMyOffers(_token!, type: 'sent');
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _loading = false;
    });
  }

  List<ProductOffer> get _activeOffers => _offers
      .where((o) =>
          o.status == OfferStatus.pending || o.status == OfferStatus.countered)
      .toList();

  List<ProductOffer> get _historyOffers => _offers
      .where((o) =>
          o.status == OfferStatus.accepted ||
          o.status == OfferStatus.declined ||
          o.status == OfferStatus.expired ||
          o.status == OfferStatus.withdrawn)
      .toList();

  Future<void> _acceptCounter(ProductOffer offer) async {
    if (_token == null) return;
    HapticFeedback.mediumImpact();
    final ok = await OfferService.acceptCounter(offer.id, _token!);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Counter offer accepted! Order created.')),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed. Please try again.')),
      );
    }
  }

  Future<void> _declineCounter(ProductOffer offer) async {
    if (_token == null) return;
    final ok = await OfferService.declineOffer(offer.id, _token!);
    if (!mounted) return;
    if (ok) _load();
  }

  Future<void> _withdraw(ProductOffer offer) async {
    if (_token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Offer'),
        content: const Text('Are you sure you want to withdraw this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await OfferService.withdrawOffer(offer.id, _token!);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer withdrawn.')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'My Offers',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kTertiary,
          indicatorColor: _kPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _kPrimary,
                  strokeWidth: 2,
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOfferList(_activeOffers, isActive: true),
                  _buildOfferList(_historyOffers, isActive: false),
                ],
              ),
      ),
    );
  }

  Widget _buildOfferList(List<ProductOffer> offers, {required bool isActive}) {
    if (offers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.local_offer_outlined : Icons.history,
                    size: 64,
                    color: _kDivider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isActive ? 'No active offers' : 'No offer history',
                    style: const TextStyle(
                      color: _kSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isActive
                        ? 'Browse products and make offers!'
                        : 'Completed offers will appear here.',
                    style: const TextStyle(color: _kTertiary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: offers.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _buildOfferCard(offers[i]),
      ),
    );
  }

  Widget _buildOfferCard(ProductOffer offer) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product title + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    offer.productTitle,
                    style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: offer.status),
              ],
            ),
            const SizedBox(height: 10),

            // Price row
            Row(
              children: [
                Expanded(
                  child: _PriceTag(
                    label: 'Your offer',
                    amount: offer.formattedOfferedPrice,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceTag(
                    label: 'Listed at',
                    amount: offer.formattedOriginalPrice,
                    highlight: false,
                  ),
                ),
              ],
            ),

            // Counter offer section
            if (offer.status == OfferStatus.countered &&
                offer.counterPrice != null) ...[
              const SizedBox(height: 12),
              _buildCounterBanner(offer),
            ],

            // Expiry countdown for active offers
            if ((offer.status == OfferStatus.pending ||
                    offer.status == OfferStatus.countered) &&
                offer.isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: _kTertiary),
                  const SizedBox(width: 5),
                  Text(
                    'Expires in ${offer.hoursUntilExpiry}h',
                    style: const TextStyle(fontSize: 12, color: _kTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],

            // Action row
            const SizedBox(height: 12),
            _buildActionRow(offer),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterBanner(ProductOffer offer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seller\'s Counter Offer',
            style: TextStyle(
              color: Color(0xFFD97706),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            offer.formattedCounterPrice,
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (offer.sellerMessage != null &&
              offer.sellerMessage!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${offer.sellerMessage}"',
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(ProductOffer offer) {
    switch (offer.status) {
      case OfferStatus.countered:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _acceptCounter(offer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Accept Counter',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => _declineCounter(offer),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kDivider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

      case OfferStatus.pending:
        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _withdraw(offer),
            style: TextButton.styleFrom(
              foregroundColor: _kSecondary,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Withdraw Offer',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        );

      case OfferStatus.accepted:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: offer.orderId != null
                ? () => Navigator.pushNamed(
                      context,
                      '/shop/order',
                      arguments: {
                        'orderId': offer.orderId,
                        'isSeller': false,
                      },
                    )
                : null,
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text(
              'View Order',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final OfferStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  (Color, Color) _colors() {
    switch (status) {
      case OfferStatus.pending:
        return (const Color(0xFFFEF3C7), const Color(0xFFD97706));
      case OfferStatus.countered:
        return (const Color(0xFFE0E7FF), const Color(0xFF4F46E5));
      case OfferStatus.accepted:
        return (const Color(0xFFD1FAE5), const Color(0xFF059669));
      case OfferStatus.declined:
        return (const Color(0xFFFEE2E2), const Color(0xFFDC2626));
      case OfferStatus.expired:
      case OfferStatus.withdrawn:
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    }
  }
}

class _PriceTag extends StatelessWidget {
  final String label;
  final String amount;
  final bool highlight;

  const _PriceTag({
    required this.label,
    required this.amount,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _kTertiary, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            color: highlight ? _kPrimary : _kSecondary,
            fontSize: highlight ? 16 : 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            decoration: highlight ? null : TextDecoration.lineThrough,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
