import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';
import '../../../services/local_storage_service.dart';
import '../models/offer_models.dart';
import '../services/offer_service.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

final _tzsFmt = NumberFormat('#,##0', 'en_US');
String _fmtTzs(double v) => 'TZS ${_tzsFmt.format(v)}';

/// Seller screen: view and respond to incoming offers.
class SellerOffersScreen extends StatefulWidget {
  final int currentUserId;

  const SellerOffersScreen({super.key, required this.currentUserId});

  @override
  State<SellerOffersScreen> createState() => _SellerOffersScreenState();
}

class _SellerOffersScreenState extends State<SellerOffersScreen> {
  List<ProductOffer> _offers = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
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
    final offers = await OfferService.listMyOffers(_token!, type: 'received');
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _loading = false;
    });
  }

  Future<void> _acceptOffer(ProductOffer offer) async {
    if (_token == null) return;
    HapticFeedback.mediumImpact();
    final ok = await OfferService.acceptOffer(offer.id, _token!);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer accepted! Order has been created.'),
          duration: Duration(seconds: 4),
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept offer. Please try again.')),
      );
    }
  }

  Future<void> _declineOffer(ProductOffer offer) async {
    if (_token == null) return;
    final messageCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Optionally add a message to the buyer:'),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'e.g. "Price is firm, sorry!"',
                hintStyle: const TextStyle(color: _kTertiary, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
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
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    messageCtrl.dispose();

    if (confirmed != true) return;
    final ok = await OfferService.declineOffer(
      offer.id,
      _token!,
      message: messageCtrl.text.trim().isNotEmpty ? messageCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer declined.')),
      );
      _load();
    }
  }

  void _showCounterSheet(ProductOffer offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CounterOfferSheet(
        offer: offer,
        onSend: (price, message) async {
          Navigator.pop(ctx);
          if (_token == null) return;
          final ok = await OfferService.counterOffer(
            offer.id,
            price,
            _token!,
            message: message,
          );
          if (!mounted) return;
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Counter offer sent. Buyer has 24 hours to accept.'),
              ),
            );
            _load();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed. Please try again.')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Received Offers',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _kPrimary,
                  strokeWidth: 2,
                ),
              )
            : _offers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: _kPrimary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _offers.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _buildOfferCard(_offers[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_offer_outlined, size: 64, color: _kDivider),
                SizedBox(height: 16),
                Text(
                  'No offers yet',
                  style: TextStyle(
                    color: _kSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Incoming offers from buyers will appear here.',
                  style: TextStyle(color: _kTertiary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(ProductOffer offer) {
    final isPending = offer.status == OfferStatus.pending;
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
            // Buyer info row
            Row(
              children: [
                _buildBuyerAvatar(offer.buyer),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.buyer?.name.isNotEmpty == true
                            ? offer.buyer!.name
                            : 'Buyer #${offer.buyerId}',
                        style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (offer.buyer?.username.isNotEmpty == true)
                        Text(
                          '@${offer.buyer!.username}',
                          style: const TextStyle(
                            color: _kTertiary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                _StatusChip(status: offer.status),
              ],
            ),
            const SizedBox(height: 12),

            // Product title
            Text(
              offer.productTitle,
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Price comparison
            Row(
              children: [
                Expanded(
                  child: _PriceInfo(
                    label: 'Buyer\'s offer',
                    amount: _fmtTzs(offer.offeredPrice),
                    sub: '${offer.savingsPercent.toStringAsFixed(1)}% below list',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceInfo(
                    label: 'Listed price',
                    amount: _fmtTzs(offer.originalPrice),
                    sub: 'Savings: ${_fmtTzs(offer.savingsAmount)}',
                  ),
                ),
              ],
            ),

            // Buyer message
            if (offer.buyerMessage != null &&
                offer.buyerMessage!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 14, color: _kTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offer.buyerMessage!,
                        style: const TextStyle(
                          color: _kSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Expiry
            if (offer.isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: _kTertiary),
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

            // Actions for pending offers
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptOffer(offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCounterSheet(offer),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Counter',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _declineOffer(offer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                    ),
                    child: const Text(
                      'Decline',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerAvatar(OfferBuyer? buyer) {
    final rawImage = buyer?.profileImage;
    final hasImage = rawImage != null && rawImage.isNotEmpty;
    return CircleAvatar(
      radius: 20,
      backgroundColor: _kBg,
      backgroundImage: hasImage
          ? NetworkImage(ApiConfig.sanitizeUrl(rawImage) ?? rawImage)
          : null,
      child: !hasImage
          ? Text(
              buyer?.initials ?? '?',
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

// ─── Counter Offer Bottom Sheet ───────────────────────────────────────────────

class _CounterOfferSheet extends StatefulWidget {
  final ProductOffer offer;
  final void Function(double price, String? message) onSend;

  const _CounterOfferSheet({required this.offer, required this.onSend});

  @override
  State<_CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends State<_CounterOfferSheet> {
  final _priceCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  double get _counterPrice {
    final raw = _priceCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(raw) ?? 0.0;
  }

  bool get _valid =>
      _counterPrice > 0 &&
      _counterPrice < widget.offer.originalPrice &&
      _counterPrice > widget.offer.offeredPrice;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Send a Counter Offer',
            style: TextStyle(
              color: _kPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Buyer offered ${_fmtTzs(widget.offer.offeredPrice)} · Listed at ${_fmtTzs(widget.offer.originalPrice)}',
            style: const TextStyle(color: _kTertiary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Counter price
          const Text(
            'Your Counter Price (TZS)',
            style: TextStyle(
              color: _kPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: 'TZS ',
              prefixStyle: const TextStyle(
                color: _kSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              helperText:
                  'Must be between buyer offer and listing price',
              helperStyle: const TextStyle(color: _kTertiary, fontSize: 11),
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          const Text(
            'Message (optional)',
            style: TextStyle(
              color: _kPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            maxLines: 2,
            maxLength: 300,
            style: const TextStyle(color: _kPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. "Best I can do at this price…"',
              hintStyle: const TextStyle(color: _kTertiary, fontSize: 13),
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),

          // Send button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_valid && !_sending)
                  ? () {
                      setState(() => _sending = true);
                      widget.onSend(
                        _counterPrice,
                        _msgCtrl.text.trim().isNotEmpty
                            ? _msgCtrl.text.trim()
                            : null,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kDivider,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Counter Offer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

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

class _PriceInfo extends StatelessWidget {
  final String label;
  final String amount;
  final String sub;

  const _PriceInfo({
    required this.label,
    required this.amount,
    required this.sub,
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
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          sub,
          style: const TextStyle(color: _kTertiary, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
