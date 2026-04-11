// lib/buy_car/pages/buy_car_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/buy_car_models.dart';
import '../services/buy_car_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_page.dart';
import 'import_calculator_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class BuyCarHomePage extends StatefulWidget {
  final int userId;
  const BuyCarHomePage({super.key, required this.userId});
  @override
  State<BuyCarHomePage> createState() => _BuyCarHomePageState();
}

class _BuyCarHomePageState extends State<BuyCarHomePage> {
  List<CarListing> _listings = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _lastPage = 1;
  String? _sourceFilter;
  late final bool _isSwahili;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool append = false}) async {
    if (!append) setState(() => _isLoading = true);
    final result = await BuyCarService.getListings(
      page: _currentPage,
      source: _sourceFilter,
      make: _searchCtrl.text.isNotEmpty ? _searchCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        if (append) {
          _listings.addAll(result.items);
        } else {
          _listings = result.items;
        }
        _lastPage = result.lastPage;
      }
    });
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) {
      _currentPage = 1;
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) {
              _currentPage = 1;
              _loadData();
            },
            decoration: InputDecoration(
              hintText: _isSwahili ? 'Tafuta gari...' : 'Search cars...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        // Source filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip(null, _isSwahili ? 'Zote' : 'All'),
              const SizedBox(width: 6),
              _filterChip('local_dealer',
                  _isSwahili ? 'Duka la Hapa' : 'Local Dealer'),
              const SizedBox(width: 6),
              _filterChip('private',
                  _isSwahili ? 'Mtu Binafsi' : 'Private'),
              const SizedBox(width: 6),
              _filterChip('japan_import',
                  _isSwahili ? 'Japani' : 'Japan Import'),
              const SizedBox(width: 6),
              _filterChip('dubai_import', 'Dubai'),
            ]),
          ),
        ),
        // Listings
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary))
              : RefreshIndicator(
                  onRefresh: () async {
                    _currentPage = 1;
                    await _loadData();
                  },
                  color: _kPrimary,
                  child: _listings.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Column(children: [
                              const Icon(Icons.directions_car_rounded,
                                  size: 48, color: _kSecondary),
                              const SizedBox(height: 12),
                              Text(
                                  _isSwahili
                                      ? 'Hakuna magari yaliyopatikana'
                                      : 'No cars found',
                                  style: const TextStyle(
                                      fontSize: 14, color: _kSecondary)),
                            ]),
                          ),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _listings.length + (_currentPage < _lastPage ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _listings.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      _currentPage++;
                                      _loadData(append: true);
                                    },
                                    child: Text(
                                        _isSwahili
                                            ? 'Pakia zaidi'
                                            : 'Load more',
                                        style: const TextStyle(
                                            color: _kPrimary)),
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ListingCard(
                                listing: _listings[i],
                                isSwahili: _isSwahili,
                                onTap: () => _nav(ListingDetailPage(
                                    listing: _listings[i])),
                              ),
                            );
                          },
                        ),
                ),
        ),
    ]);
  }

  Widget _filterChip(String? value, String label) {
    final selected = _sourceFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sourceFilter = value);
        _currentPage = 1;
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : _kSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
