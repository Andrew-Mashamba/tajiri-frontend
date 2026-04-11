// lib/sell_car/pages/listing_offers_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/sell_car_models.dart';
import '../services/sell_car_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ListingOffersPage extends StatefulWidget {
  final SellListing listing;
  const ListingOffersPage({super.key, required this.listing});
  @override
  State<ListingOffersPage> createState() => _ListingOffersPageState();
}

class _ListingOffersPageState extends State<ListingOffersPage> {
  List<SellOffer> _offers = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    final r = await SellCarService.getOffersForListing(widget.listing.id);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _offers = r.items;
    });
  }

  Future<void> _respond(SellOffer offer, String action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await SellCarService.respondToOffer(offer.id, action);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(r.success
              ? (_isSwahili ? 'Imefanikiwa!' : 'Done!')
              : (_isSwahili ? 'Imeshindwa' : 'Failed'))));
      if (r.success) _loadOffers();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(_isSwahili ? 'Imeshindwa' : 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(l.displayName,
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _kPrimary),
            onSelected: (v) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                if (v == 'pause') {
                  final r = await SellCarService.pauseListing(l.id);
                  if (!mounted) return;
                  if (r.success) {
                    messenger.showSnackBar(SnackBar(
                        content: Text(_isSwahili ? 'Tangazo limesitishwa' : 'Listing paused')));
                    Navigator.pop(context, true);
                  }
                } else if (v == 'sold') {
                  final r = await SellCarService.markAsSold(l.id);
                  if (!mounted) return;
                  if (r.success) {
                    messenger.showSnackBar(SnackBar(
                        content: Text(_isSwahili ? 'Gari limeuzwa!' : 'Marked as sold!')));
                    Navigator.pop(context, true);
                  }
                }
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                    content: Text(_isSwahili ? 'Imeshindwa' : 'Failed')));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'pause',
                  child: Text(_isSwahili ? 'Sitisha' : 'Pause')),
              PopupMenuItem(
                  value: 'sold',
                  child: Text(
                      _isSwahili ? 'Weka Kuuzwa' : 'Mark as Sold')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              _statsItem(Icons.visibility_rounded, '${l.viewCount}',
                  _isSwahili ? 'Maoni' : 'Views'),
              _divider(),
              _statsItem(Icons.chat_bubble_rounded, '${l.inquiryCount}',
                  _isSwahili ? 'Maswali' : 'Inquiries'),
              _divider(),
              _statsItem(Icons.bookmark_rounded, '${l.saveCount}',
                  _isSwahili ? 'Wahifadhi' : 'Saves'),
            ]),
          ),
          const SizedBox(height: 12),

          // Price
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isSwahili ? 'Bei' : 'Price',
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary)),
                        Text('TZS ${l.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary)),
                      ]),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(l.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(l.status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(l.status))),
                  ),
                ]),
          ),
          const SizedBox(height: 20),

          // Offers
          Text(
              '${_isSwahili ? 'Bei Zilizopokelewa' : 'Offers Received'} (${_offers.length})',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary)),
          const SizedBox(height: 8),

          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
          else if (_offers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(children: [
                  const Icon(Icons.inbox_rounded,
                      size: 48, color: _kSecondary),
                  const SizedBox(height: 12),
                  Text(
                      _isSwahili
                          ? 'Hakuna bei bado'
                          : 'No offers yet',
                      style: const TextStyle(
                          fontSize: 14, color: _kSecondary)),
                ]),
              ),
            )
          else
            ..._offers.map(_offerTile),
        ],
      ),
    );
  }

  Widget _offerTile(SellOffer offer) {
    final statusColor = offer.status == 'accepted'
        ? const Color(0xFF4CAF50)
        : offer.status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            child: Text(
                offer.buyerName.isNotEmpty ? offer.buyerName[0] : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: _kPrimary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(offer.buyerName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (offer.buyerVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: Color(0xFF4CAF50)),
                    ],
                  ]),
                  Text(
                      '${offer.createdAt.day}/${offer.createdAt.month}/${offer.createdAt.year}',
                      style: const TextStyle(
                          fontSize: 10, color: _kSecondary)),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('TZS ${offer.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(offer.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ),
          ]),
        ]),
        if (offer.message != null) ...[
          const SizedBox(height: 8),
          Text(offer.message!,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
        if (offer.status == 'pending') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () => _respond(offer, 'reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_isSwahili ? 'Kataa' : 'Decline',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: () => _respond(offer, 'accept'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_isSwahili ? 'Kubali' : 'Accept',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _statsItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 20, color: _kPrimary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: _kSecondary)),
      ]),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: Colors.grey.shade200);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'sold':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return _kSecondary;
    }
  }
}
