import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/property_listing.dart';
import '../services/property_listing_service.dart';
import '../widgets/property_listing_card.dart';
import 'property_listing_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

/// New unified search page for property listings.
/// Replaces the old `SearchPropertyPage` which used the deprecated `Property` model.
class PropertyListingsSearchPage extends StatefulWidget {
  final int userId;
  final PropertyType? initialType;

  const PropertyListingsSearchPage({
    super.key,
    required this.userId,
    this.initialType,
  });

  @override
  State<PropertyListingsSearchPage> createState() => _PropertyListingsSearchPageState();
}

class _PropertyListingsSearchPageState extends State<PropertyListingsSearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<PropertyListing> _results = [];
  bool _isLoading = false;
  String? _error;

  PropertyType? _selectedType;
  ListingKind? _selectedKind;
  String? _selectedRegion;
  int? _minPrice;
  int? _maxPrice;
  int? _bedrooms;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _search();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await PropertyListingService.list(
      propertyType: _selectedType,
      listingKind: _selectedKind,
      region: _selectedRegion,
      minPriceTzs: _minPrice,
      maxPriceTzs: _maxPrice,
      bedrooms: _bedrooms,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success) {
        _results = res.items;
      } else {
        _error = res.message;
      }
    });
  }

  void _openDetail(PropertyListing listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyListingDetailPage(
          listingId: listing.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Tafuta Mali' : 'Find Property',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(isSw),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: _kSecondary)))
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              isSw ? 'Hakuna matokeo' : 'No results',
                              style: const TextStyle(color: _kSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              return PropertyListingCard(
                                listing: item,
                                onTap: () => _openDetail(item),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isSw) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: isSw ? 'Tafuta kwa eneo...' : 'Search by location...',
              prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _kBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  isSw ? 'Aina' : 'Type',
                  _selectedType != null
                      ? (isSw ? _selectedType!.labelSwahili : _selectedType!.label)
                      : null,
                  () => _showTypePicker(isSw),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  isSw ? 'Kodi/Uzazi' : 'Rent/Sale',
                  _selectedKind != null
                      ? (isSw ? _selectedKind!.labelSwahili : _selectedKind!.label)
                      : null,
                  () => _showKindPicker(isSw),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  isSw ? 'Chumba' : 'Beds',
                  _bedrooms != null ? '$_bedrooms+' : null,
                  () => _showBedroomPicker(isSw),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  isSw ? 'Bei' : 'Price',
                  (_minPrice != null || _maxPrice != null)
                      ? '${_fmt(_minPrice ?? 0)} - ${_fmt(_maxPrice ?? 50000000)}'
                      : null,
                  () => _showPricePicker(isSw),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, VoidCallback onTap) {
    final active = value != null;
    final display = value ?? label;
    return ActionChip(
      label: Text(
        display,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? Colors.white : _kPrimary,
        ),
      ),
      backgroundColor: active ? _kPrimary : _kBackground,
      side: active ? null : BorderSide(color: Colors.grey.shade300),
      onPressed: onTap,
    );
  }

  Future<void> _showTypePicker(bool isSw) async {
    final types = PropertyType.values;
    final selected = await showModalBottomSheet<PropertyType?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(isSw ? 'Chagua aina' : 'Select type'),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            const Divider(),
            ...types.map((t) => ListTile(
              leading: Icon(t.icon),
              title: Text(isSw ? t.labelSwahili : t.label),
              trailing: _selectedType == t ? const Icon(Icons.check_rounded, color: _kPrimary) : null,
              onTap: () => Navigator.pop(ctx, t),
            )),
          ],
        ),
      ),
    );
    if (selected != null || _selectedType != null) {
      setState(() => _selectedType = selected);
      _search();
    }
  }

  Future<void> _showKindPicker(bool isSw) async {
    final kinds = ListingKind.values;
    final selected = await showModalBottomSheet<ListingKind?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(isSw ? 'Chagua aina' : 'Select kind'),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            const Divider(),
            ...kinds.map((k) => ListTile(
              title: Text(isSw ? k.labelSwahili : k.label),
              trailing: _selectedKind == k ? const Icon(Icons.check_rounded, color: _kPrimary) : null,
              onTap: () => Navigator.pop(ctx, k),
            )),
          ],
        ),
      ),
    );
    if (selected != null || _selectedKind != null) {
      setState(() => _selectedKind = selected);
      _search();
    }
  }

  Future<void> _showBedroomPicker(bool isSw) async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(isSw ? 'Chagua vyumba' : 'Select bedrooms')),
            const Divider(),
            ...[1, 2, 3, 4, 5].map((b) => ListTile(
              title: Text('$b+'),
              trailing: _bedrooms == b ? const Icon(Icons.check_rounded, color: _kPrimary) : null,
              onTap: () => Navigator.pop(ctx, b),
            )),
          ],
        ),
      ),
    );
    if (selected != null || _bedrooms != null) {
      setState(() => _bedrooms = selected);
      _search();
    }
  }

  Future<void> _showPricePicker(bool isSw) async {
    final minCtrl = TextEditingController(text: _minPrice?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Bei (TZS)' : 'Price (TZS)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isSw ? 'Chini' : 'Min'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: maxCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isSw ? 'Juu' : 'Max'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isSw ? 'Ghairi' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isSw ? 'Sawa' : 'OK')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _minPrice = int.tryParse(minCtrl.text);
        _maxPrice = int.tryParse(maxCtrl.text);
      });
      _search();
    }
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
