// lib/sell_car/pages/sell_car_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/sell_car_models.dart';
import '../services/sell_car_service.dart';
import '../widgets/sell_listing_card.dart';
import 'create_listing_page.dart';
import 'listing_offers_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class SellCarHomePage extends StatefulWidget {
  final int userId;
  const SellCarHomePage({super.key, required this.userId});
  @override
  State<SellCarHomePage> createState() => _SellCarHomePageState();
}

class _SellCarHomePageState extends State<SellCarHomePage> {
  List<SellListing> _listings = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await SellCarService.getMyListings();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _listings = result.items;
    });
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: _kPrimary,
            child: _listings.isEmpty ? _buildEmpty() : _buildList(),
          );
  }

  Widget _buildEmpty() {
    return ListView(children: [
      const SizedBox(height: 120),
      Center(
        child: Column(children: [
          const Icon(Icons.sell_rounded, size: 56, color: _kSecondary),
          const SizedBox(height: 14),
          Text(
              _isSwahili
                  ? 'Huna matangazo bado'
                  : 'No listings yet',
              style: const TextStyle(fontSize: 16, color: _kSecondary)),
          const SizedBox(height: 6),
          Text(
              _isSwahili
                  ? 'Tangaza gari lako kwa wanunuzi wa TAJIRI'
                  : 'List your car for TAJIRI buyers',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _nav(const CreateListingPage()),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
                _isSwahili ? 'Unda Tangazo' : 'Create Listing'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildList() {
    final active = _listings.where((l) => l.isActive).length;
    final totalViews = _listings.fold(0, (s, l) => s + l.viewCount);
    final totalInquiries = _listings.fold(0, (s, l) => s + l.inquiryCount);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(16)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.sell_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(_isSwahili ? 'Matangazo Yangu' : 'My Listings',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _stat('$active',
                      _isSwahili ? 'Hai' : 'Active'),
                  const SizedBox(width: 20),
                  _stat('$totalViews',
                      _isSwahili ? 'Maoni' : 'Views'),
                  const SizedBox(width: 20),
                  _stat('$totalInquiries',
                      _isSwahili ? 'Mawasiliano' : 'Inquiries'),
                ]),
              ]),
        ),
        const SizedBox(height: 16),

        // Active listings
        Text(_isSwahili ? 'Matangazo' : 'Listings',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary)),
        const SizedBox(height: 8),
        ..._listings.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SellListingCard(
                listing: l,
                isSwahili: _isSwahili,
                onTap: () => _nav(ListingOffersPage(listing: l)),
              ),
            )),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _stat(String val, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(val,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700)),
      Text(label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
    ]);
  }
}
