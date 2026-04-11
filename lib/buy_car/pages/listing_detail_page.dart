// lib/buy_car/pages/listing_detail_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/buy_car_models.dart';
import '../services/buy_car_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ListingDetailPage extends StatefulWidget {
  final CarListing listing;
  const ListingDetailPage({super.key, required this.listing});
  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  late CarListing _listing;
  int _photoIndex = 0;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  void _showOfferDialog() {
    final offerCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 20, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_isSwahili ? 'Toa Bei' : 'Make an Offer',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(
              '${_isSwahili ? 'Bei ya sasa' : 'Asking price'}: TZS ${_listing.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: offerCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isSwahili ? 'Bei Yako (TZS)' : 'Your Offer (TZS)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: msgCtrl,
            decoration: InputDecoration(
              labelText: _isSwahili ? 'Ujumbe (hiari)' : 'Message (optional)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final amount = double.tryParse(offerCtrl.text) ?? 0;
                if (amount <= 0) return;
                Navigator.pop(ctx);
                messenger.showSnackBar(SnackBar(
                    content: Text(_isSwahili
                        ? 'Bei yako imetumwa!'
                        : 'Offer sent to seller!')));
              },
              child: Text(_isSwahili ? 'Tuma Bei' : 'Send Offer'),
            ),
          ),
        ]),
      ),
    );
  }

  void _saveListing() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await BuyCarService.saveListing(_listing.id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(result.success
            ? (_isSwahili ? 'Limehifadhiwa!' : 'Saved!')
            : (_isSwahili ? 'Imeshindwa' : 'Failed to save'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // Photo gallery
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _kPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: _saveListing,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _listing.photos.isNotEmpty
                  ? PageView.builder(
                      itemCount: _listing.photos.length,
                      onPageChanged: (i) => setState(() => _photoIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        _listing.photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _kPrimary.withValues(alpha: 0.1),
                          child: const Icon(Icons.directions_car_rounded,
                              size: 64, color: _kSecondary),
                        ),
                      ),
                    )
                  : Container(
                      color: _kPrimary.withValues(alpha: 0.1),
                      child: const Icon(Icons.directions_car_rounded,
                          size: 64, color: _kSecondary),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo indicator
                    if (_listing.photos.length > 1)
                      Center(
                        child: Text(
                            '${_photoIndex + 1} / ${_listing.photos.length}',
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary)),
                      ),
                    const SizedBox(height: 8),

                    // Title and price
                    Text(_listing.displayName,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 4),
                    Text(
                        'TZS ${_listing.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 8),

                    // Tags
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _tag(_listing.sourceLabel),
                      _tag(_listing.condition.toUpperCase()),
                      _tag(_listing.transmission),
                      _tag(_listing.fuelType),
                      if (_listing.auctionGrade != null)
                        _tag('Grade: ${_listing.auctionGrade}'),
                    ]),
                    const SizedBox(height: 16),

                    // Specs grid
                    _specsGrid(),
                    const SizedBox(height: 16),

                    // Seller info
                    _sellerCard(),
                    const SizedBox(height: 16),

                    // Description
                    if (_listing.description != null) ...[
                      Text(_isSwahili ? 'Maelezo' : 'Description',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary)),
                      const SizedBox(height: 6),
                      Text(_listing.description!,
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary, height: 1.5)),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, '/chat/${_listing.sellerId}');
                            },
                            icon: const Icon(Icons.message_rounded, size: 18),
                            label: Text(_isSwahili ? 'Wasiliana' : 'Contact'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _showOfferDialog(),
                            icon: const Icon(Icons.handshake_rounded, size: 18),
                            label: Text(
                                _isSwahili ? 'Toa Bei' : 'Make Offer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kPrimary,
                              side: const BorderSide(color: _kPrimary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specsGrid() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        Row(children: [
          _specItem(Icons.speed_rounded, _isSwahili ? 'Kilomita' : 'Mileage',
              '${_listing.mileage.toStringAsFixed(0)} km'),
          _specItem(Icons.calendar_today_rounded,
              _isSwahili ? 'Mwaka' : 'Year', '${_listing.year}'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _specItem(Icons.local_gas_station_rounded,
              _isSwahili ? 'Mafuta' : 'Fuel', _listing.fuelType),
          _specItem(Icons.settings_rounded,
              _isSwahili ? 'Gia' : 'Transmission', _listing.transmission),
        ]),
        if (_listing.engineSize != null || _listing.color != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            if (_listing.engineSize != null)
              _specItem(Icons.engineering_rounded,
                  _isSwahili ? 'Injini' : 'Engine', _listing.engineSize!),
            if (_listing.color != null)
              _specItem(Icons.palette_rounded,
                  _isSwahili ? 'Rangi' : 'Color', _listing.color!),
          ]),
        ],
      ]),
    );
  }

  Widget _specItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(children: [
        Icon(icon, size: 16, color: _kSecondary),
        const SizedBox(width: 6),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: _kSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  Widget _sellerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _kPrimary.withValues(alpha: 0.08),
          child: Text(_listing.sellerName.isNotEmpty
              ? _listing.sellerName[0].toUpperCase()
              : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _kPrimary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_listing.sellerName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (_listing.sellerVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded,
                    size: 16, color: Color(0xFF4CAF50)),
              ],
            ]),
            if (_listing.location != null)
              Text(_listing.location!,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        Text('${_listing.viewCount} ${_isSwahili ? 'maoni' : 'views'}',
            style: const TextStyle(fontSize: 11, color: _kSecondary)),
      ]),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, color: _kSecondary, fontWeight: FontWeight.w500)),
    );
  }
}
