// lib/hair_nails/pages/salon_browse_page.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';
import '../services/hair_nails_service.dart';
import '../widgets/salon_card.dart';
import 'salon_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SalonBrowsePage extends StatefulWidget {
  final int userId;
  const SalonBrowsePage({super.key, required this.userId});
  @override
  State<SalonBrowsePage> createState() => _SalonBrowsePageState();
}

class _SalonBrowsePageState extends State<SalonBrowsePage> {
  final HairNailsService _service = HairNailsService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<Salon> _salons = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  bool _hasMore = true;

  // Filters
  String? _categoryFilter;
  bool _homeBasedOnly = false;
  bool _mobileOnly = false;
  bool _walkInOnly = false;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _loadSalons();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSalons() async {
    setState(() {
      _isLoading = true;
      _page = 1;
    });
    final result = await _service.findSalons(
      search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      serviceCategory: _categoryFilter,
      homeBased: _homeBasedOnly ? true : null,
      mobile: _mobileOnly ? true : null,
      walkIn: _walkInOnly ? true : null,
      minRating: _minRating,
      page: 1,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _salons = result.success ? result.items : [];
        _hasMore = result.items.length >= 15;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _page++;
    final result = await _service.findSalons(
      search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      serviceCategory: _categoryFilter,
      homeBased: _homeBasedOnly ? true : null,
      mobile: _mobileOnly ? true : null,
      walkIn: _walkInOnly ? true : null,
      minRating: _minRating,
      page: _page,
    );
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _salons.addAll(result.items);
          _hasMore = result.items.length >= 15;
        } else {
          _hasMore = false;
        }
      });
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Chuja Matokeo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 16),

              // Category
              const Text('Huduma', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [null, ...ServiceCategory.values].map((c) {
                  final label = c == null ? 'Zote' : c.displayName;
                  final isSelected = _categoryFilter == c?.name;
                  return ChoiceChip(
                    label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : _kPrimary)),
                    selected: isSelected,
                    selectedColor: _kPrimary,
                    backgroundColor: _kCardBg,
                    onSelected: (_) => setSheetState(() => _categoryFilter = c?.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Type toggles
              const Text('Aina ya Saluni', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              _filterToggle('Mama Salon (Nyumbani)', _homeBasedOnly, (v) => setSheetState(() => _homeBasedOnly = v)),
              _filterToggle('Mtaalamu Anakuja (Mobile)', _mobileOnly, (v) => setSheetState(() => _mobileOnly = v)),
              _filterToggle('Walk-in', _walkInOnly, (v) => setSheetState(() => _walkInOnly = v)),
              const SizedBox(height: 14),

              // Rating
              const Text('Rating ya chini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [null, 3.0, 4.0, 4.5].map((r) {
                  final label = r == null ? 'Yoyote' : '${r.toStringAsFixed(1)}+';
                  final isSelected = _minRating == r;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : _kPrimary)),
                      selected: isSelected,
                      selectedColor: _kPrimary,
                      backgroundColor: _kCardBg,
                      onSelected: (_) => setSheetState(() => _minRating = r),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadSalons();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Tafuta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kPrimary)),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: _kPrimary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Tafuta Saluni', style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _loadSalons(),
                decoration: InputDecoration(
                  hintText: 'Tafuta saluni, huduma...',
                  hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _loadSalons(); })
                      : null,
                  filled: true,
                  fillColor: _kCardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Active filters
            if (_homeBasedOnly || _mobileOnly || _walkInOnly || _categoryFilter != null || _minRating != null)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_categoryFilter != null) _activeFilterChip(ServiceCategory.fromString(_categoryFilter).displayName, () { setState(() => _categoryFilter = null); _loadSalons(); }),
                    if (_homeBasedOnly) _activeFilterChip('Mama Salon', () { setState(() => _homeBasedOnly = false); _loadSalons(); }),
                    if (_mobileOnly) _activeFilterChip('Mobile', () { setState(() => _mobileOnly = false); _loadSalons(); }),
                    if (_walkInOnly) _activeFilterChip('Walk-in', () { setState(() => _walkInOnly = false); _loadSalons(); }),
                    if (_minRating != null) _activeFilterChip('${_minRating!.toStringAsFixed(1)}+', () { setState(() => _minRating = null); _loadSalons(); }),
                  ],
                ),
              ),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                  : _salons.isEmpty
                      ? const Center(child: Text('Hakuna saluni zilizopatikana', style: TextStyle(color: _kSecondary)))
                      : RefreshIndicator(
                          onRefresh: _loadSalons,
                          color: _kPrimary,
                          child: ListView.separated(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _salons.length + (_isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              if (i >= _salons.length) {
                                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)));
                              }
                              final salon = _salons[i];
                              return SalonCard(
                                salon: salon,
                                onTap: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => SalonDetailPage(userId: widget.userId, salon: salon)));
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
        backgroundColor: _kPrimary,
        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
