// lib/housing/pages/search_property_page.dart
import 'package:flutter/material.dart';
import '../models/housing_models.dart';
import '../services/housing_service.dart';
import '../widgets/property_card.dart';
import 'property_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SearchPropertyPage extends StatefulWidget {
  final int userId;
  final PropertyType? initialType;
  const SearchPropertyPage(
      {super.key, required this.userId, this.initialType});
  @override
  State<SearchPropertyPage> createState() => _SearchPropertyPageState();
}

class _SearchPropertyPageState extends State<SearchPropertyPage> {
  final HousingService _service = HousingService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Property> _results = [];
  bool _isLoading = false;

  // Filters
  PropertyType? _selectedType;
  String? _selectedRegion;
  PriceFrequency? _selectedFrequency;
  final RangeValues _priceRange = const RangeValues(0, 50000000);
  int? _selectedBedrooms;

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
    setState(() => _isLoading = true);
    final result = await _service.getProperties(
      type: _selectedType?.name,
      location: _selectedRegion,
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 50000000 ? _priceRange.end : null,
      bedrooms: _selectedBedrooms,
      priceFrequency: _selectedFrequency?.name,
      search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _results = result.items;
      });
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chuja Matokeo',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                  const SizedBox(height: 16),

                  // Type
                  const Text('Aina',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                          label: 'Zote',
                          selected: _selectedType == null,
                          onTap: () {
                            setSheetState(() => _selectedType = null);
                            setState(() {});
                          }),
                      ...PropertyType.values.map((t) => _FilterChip(
                            label: t.displayName,
                            selected: _selectedType == t,
                            onTap: () {
                              setSheetState(() => _selectedType = t);
                              setState(() {});
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Region
                  const Text('Mkoa',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                            label: 'Wote',
                            selected: _selectedRegion == null,
                            onTap: () {
                              setSheetState(() => _selectedRegion = null);
                              setState(() {});
                            }),
                        const SizedBox(width: 8),
                        ...TzRegion.regions.take(10).map((r) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                  label: r,
                                  selected: _selectedRegion == r,
                                  onTap: () {
                                    setSheetState(
                                        () => _selectedRegion = r);
                                    setState(() {});
                                  }),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Frequency
                  const Text('Malipo',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                          label: 'Yote',
                          selected: _selectedFrequency == null,
                          onTap: () {
                            setSheetState(
                                () => _selectedFrequency = null);
                            setState(() {});
                          }),
                      ...PriceFrequency.values.map((f) => _FilterChip(
                            label: f.displayName,
                            selected: _selectedFrequency == f,
                            onTap: () {
                              setSheetState(
                                  () => _selectedFrequency = f);
                              setState(() {});
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _search();
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary),
                      child: const Text('Tafuta'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Tafuta Nyumba',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kPrimary)),
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.tune_rounded, color: _kPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tafuta eneo, jina...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kSecondary),
                filled: true,
                fillColor: _kCardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 48, color: _kSecondary),
                            const SizedBox(height: 12),
                            const Text('Hakuna matokeo',
                                style: TextStyle(
                                    fontSize: 15, color: _kSecondary)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showFilters,
                              child: const Text('Badilisha chujio',
                                  style: TextStyle(color: _kPrimary)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _search,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final p = _results[i];
                            return PropertyCard(
                              property: p,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PropertyDetailPage(
                                        property: p,
                                        userId: widget.userId)),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kPrimary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _kPrimary,
          ),
        ),
      ),
    );
  }
}
