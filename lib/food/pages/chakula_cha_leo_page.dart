// lib/food/pages/chakula_cha_leo_page.dart
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/chef_listing.dart';
import '../services/food_service.dart';
import 'chef_listing_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kWarn = Color(0xFFE65100);
const Color _kDanger = Color(0xFFD32F2F);

class ChakulaChaLeoPage extends StatefulWidget {
  final int userId;
  const ChakulaChaLeoPage({super.key, required this.userId});

  @override
  State<ChakulaChaLeoPage> createState() => _ChakulaChaLeoPageState();
}

class _ChakulaChaLeoPageState extends State<ChakulaChaLeoPage> {
  final FoodService _service = FoodService();
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  Timer? _tick;

  List<ChefListing> _all = [];
  bool _loading = true;
  String? _loadError;

  final Set<String> _activeDietary = {};
  String? _wardFilter;
  _PriceFilter _priceFilter = _PriceFilter.all;
  _SortOrder _sort = _SortOrder.endingSoonest;
  bool _prefsApplied = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPreferences();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadPreferences() async {
    final result = await _service.getFoodPreferences(userId: widget.userId);
    if (!mounted || _prefsApplied) return;
    final prefs = result.data;
    if (prefs == null) return;
    setState(() {
      _prefsApplied = true;
      if (_activeDietary.isEmpty && prefs.dietaryTags.isNotEmpty) {
        _activeDietary.addAll(prefs.dietaryTags);
      }
      if (_wardFilter == null && prefs.defaultWard != null && prefs.defaultWard!.isNotEmpty) {
        _wardFilter = prefs.defaultWard;
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tick?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await _service.getChefListings(mode: ChefListingMode.todayExtra);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _all = result.items;
      } else {
        _loadError = result.message;
      }
    });
  }

  List<ChefListing> get _filtered {
    final now = DateTime.now();
    final q = _search.text.trim().toLowerCase();
    final out = _all.where((l) {
      if (!l.isActive) return false;
      if (l.pickupWindowEnd.isBefore(now)) return false;
      if (!l.hasPortionsLeft) return false;
      if (q.isNotEmpty) {
        final bag = '${l.title} ${l.description ?? ''} ${l.partnerName ?? ''} ${l.partnerLocationText}'.toLowerCase();
        if (!bag.contains(q)) return false;
      }
      if (_activeDietary.isNotEmpty) {
        for (final tag in _activeDietary) {
          if (!l.dietaryTags.contains(tag)) return false;
        }
      }
      if (_wardFilter != null && _wardFilter!.isNotEmpty) {
        if ((l.partnerWard ?? '').toLowerCase() != _wardFilter!.toLowerCase()) return false;
      }
      switch (_priceFilter) {
        case _PriceFilter.all:
          break;
        case _PriceFilter.free:
          if (!l.isGiveaway) return false;
          break;
        case _PriceFilter.paid:
          if (l.isGiveaway) return false;
          break;
        case _PriceFilter.under3k:
          if (l.isGiveaway || (l.priceTzs ?? 0) >= 3000) return false;
          break;
      }
      return true;
    }).toList();

    switch (_sort) {
      case _SortOrder.endingSoonest:
        out.sort((a, b) => a.pickupWindowEnd.compareTo(b.pickupWindowEnd));
        break;
      case _SortOrder.portionsFewest:
        out.sort((a, b) => a.portionsRemaining.compareTo(b.portionsRemaining));
        break;
      case _SortOrder.priceLowest:
        out.sort((a, b) {
          final ap = a.isGiveaway ? 0 : (a.priceTzs ?? 0);
          final bp = b.isGiveaway ? 0 : (b.priceTzs ?? 0);
          return ap.compareTo(bp);
        });
        break;
    }
    return out;
  }

  List<String> get _availableWards {
    final set = <String>{};
    for (final l in _all) {
      final w = l.partnerWard;
      if (w != null && w.trim().isNotEmpty) set.add(w);
    }
    final list = set.toList()..sort();
    return list;
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  void _toggleDietary(String tag) {
    setState(() {
      if (_activeDietary.contains(tag)) {
        _activeDietary.remove(tag);
      } else {
        _activeDietary.add(tag);
      }
    });
  }

  void _openWardPicker() async {
    final wards = _availableWards;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chagua Kata',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.public_rounded, color: _kSecondary),
                title: const Text('Kata zote', style: TextStyle(color: _kPrimary)),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              ...wards.map((w) => ListTile(
                    leading: const Icon(Icons.place_outlined, color: _kSecondary),
                    title: Text(w, style: const TextStyle(color: _kPrimary)),
                    onTap: () => Navigator.pop(ctx, w),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _wardFilter = picked.isEmpty ? null : picked);
    }
  }

  void _openSortSheet() async {
    final picked = await showModalBottomSheet<_SortOrder>(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Panga Kwa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              for (final s in _SortOrder.values)
                ListTile(
                  leading: Icon(
                    _sort == s ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: _kPrimary,
                  ),
                  title: Text(s.label, style: const TextStyle(color: _kPrimary)),
                  onTap: () => Navigator.pop(ctx, s),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _sort = picked);
  }

  void _openListing(ChefListing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChefListingDetailPage(
          listingId: listing.id,
          userId: widget.userId,
        ),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeFilterCount = _activeDietary.length +
        (_wardFilter != null ? 1 : 0) +
        (_priceFilter != _PriceFilter.all ? 1 : 0);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          'Chakula cha Leo',
          style: TextStyle(color: _kPrimary, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Panga',
            icon: const Icon(Icons.sort_rounded, color: _kPrimary),
            onPressed: _openSortSheet,
          ),
          IconButton(
            tooltip: 'Pakia upya',
            icon: const Icon(Icons.refresh_rounded, color: _kPrimary),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: _search, onChanged: _onSearchChanged),
          _FilterStrip(
            activeDietary: _activeDietary,
            wardFilter: _wardFilter,
            priceFilter: _priceFilter,
            availableWardCount: _availableWards.length,
            onDietaryTap: _toggleDietary,
            onWardTap: _openWardPicker,
            onPriceTap: (f) => setState(() => _priceFilter = f),
            onClear: activeFilterCount == 0
                ? null
                : () => setState(() {
                      _activeDietary.clear();
                      _wardFilter = null;
                      _priceFilter = _PriceFilter.all;
                    }),
          ),
          Expanded(
            child: _buildBody(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<ChefListing> listings) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 56, color: _kSecondary),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: _kSecondary)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, side: const BorderSide(color: _kPrimary)),
                child: const Text('Jaribu tena'),
              ),
            ],
          ),
        ),
      );
    }
    if (listings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _all.isEmpty
                  ? 'Hakuna chakula leo.\nRudi baadaye au fuata wapishi unaowapenda.'
                  : 'Hakuna chakula kinacholingana na vichungi vyako.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: listings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ListingTile(
          listing: listings[i],
          onTap: () => _openListing(listings[i]),
        ),
      ),
    );
  }
}

enum _PriceFilter { all, free, paid, under3k }

enum _SortOrder { endingSoonest, portionsFewest, priceLowest }

extension on _SortOrder {
  String get label {
    switch (this) {
      case _SortOrder.endingSoonest: return 'Inakaribia kuisha';
      case _SortOrder.portionsFewest: return 'Sehemu chache zaidi';
      case _SortOrder.priceLowest: return 'Bei ya chini zaidi';
    }
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: _kPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tafuta chakula, mpishi, kata...',
            hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, color: _kSecondary),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

const List<_DietaryChipDef> _dietaryDefs = [
  _DietaryChipDef('halal', 'Halal'),
  _DietaryChipDef('vegetarian', 'Mboga'),
  _DietaryChipDef('vegan', 'Vegan'),
  _DietaryChipDef('no_pork', 'Bila nguruwe'),
  _DietaryChipDef('gluten_free', 'Bila ngano'),
  _DietaryChipDef('spicy', 'Pilipili'),
];

class _DietaryChipDef {
  final String key;
  final String label;
  const _DietaryChipDef(this.key, this.label);
}

class _FilterStrip extends StatelessWidget {
  final Set<String> activeDietary;
  final String? wardFilter;
  final _PriceFilter priceFilter;
  final int availableWardCount;
  final ValueChanged<String> onDietaryTap;
  final VoidCallback onWardTap;
  final ValueChanged<_PriceFilter> onPriceTap;
  final VoidCallback? onClear;

  const _FilterStrip({
    required this.activeDietary,
    required this.wardFilter,
    required this.priceFilter,
    required this.availableWardCount,
    required this.onDietaryTap,
    required this.onWardTap,
    required this.onPriceTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (onClear != null) ...[
              _Chip(
                label: 'Futa (${_activeCount()})',
                icon: Icons.close_rounded,
                selected: true,
                onTap: onClear!,
              ),
              const SizedBox(width: 8),
            ],
            if (availableWardCount > 0) ...[
              _Chip(
                label: wardFilter ?? 'Kata',
                icon: Icons.place_outlined,
                selected: wardFilter != null,
                onTap: onWardTap,
              ),
              const SizedBox(width: 8),
            ],
            _Chip(
              label: 'Bei zote',
              selected: priceFilter == _PriceFilter.all,
              onTap: () => onPriceTap(_PriceFilter.all),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Bure',
              selected: priceFilter == _PriceFilter.free,
              onTap: () => onPriceTap(_PriceFilter.free),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Chini ya 3,000',
              selected: priceFilter == _PriceFilter.under3k,
              onTap: () => onPriceTap(_PriceFilter.under3k),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Inauzwa',
              selected: priceFilter == _PriceFilter.paid,
              onTap: () => onPriceTap(_PriceFilter.paid),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 20, color: const Color(0xFFE0E0E0)),
            const SizedBox(width: 16),
            for (final d in _dietaryDefs) ...[
              _Chip(
                label: d.label,
                selected: activeDietary.contains(d.key),
                onTap: () => onDietaryTap(d.key),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  int _activeCount() =>
      activeDietary.length + (wardFilter != null ? 1 : 0) + (priceFilter != _PriceFilter.all ? 1 : 0);
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _kPrimary : _kCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? _kPrimary : const Color(0xFFE0E0E0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? Colors.white : _kPrimary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _kPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final ChefListing listing;
  final VoidCallback onTap;
  const _ListingTile({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = listing.pickupWindowEnd.difference(now);
    final minsLeft = remaining.inMinutes;
    final goingFast = listing.portionsRemaining <= 2;

    Color timeColor;
    String timeLabel;
    if (minsLeft <= 0) {
      timeColor = _kDanger;
      timeLabel = 'Imefungwa';
    } else if (minsLeft < 15) {
      timeColor = _kDanger;
      timeLabel = '${minsLeft}min';
    } else if (minsLeft < 60) {
      timeColor = _kWarn;
      timeLabel = '${minsLeft}min';
    } else {
      timeColor = _kSecondary;
      final h = remaining.inHours;
      final m = minsLeft % 60;
      timeLabel = m == 0 ? '${h}h' : '${h}h ${m}min';
    }

    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _photo(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (goingFast)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kWarn.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Zinaisha',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kWarn),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.partnerName ?? 'Mpishi',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listing.partnerLocationText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 11, color: _kSecondary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              listing.partnerLocationText,
                              style: const TextStyle(fontSize: 11, color: _kSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (listing.dietaryTags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: listing.dietaryTags.take(4).map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                _labelForTag(t),
                                style: const TextStyle(fontSize: 9, color: _kPrimary, fontWeight: FontWeight.w600),
                              ),
                            )).toList(),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (listing.isGiveaway)
                          const Text(
                            'Bure',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kAccent),
                          )
                        else
                          Text(
                            'TZS ${_fmt(listing.priceTzs ?? 0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          '${listing.portionsRemaining} sehemu',
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                        ),
                        const Spacer(),
                        Icon(Icons.schedule_rounded, size: 12, color: timeColor),
                        const SizedBox(width: 3),
                        Text(
                          timeLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: timeColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo() {
    final url = listing.resolvedPhotoUrl;
    const double size = 84;
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant_rounded, color: _kSecondary),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(width: size, height: size, color: Colors.grey.shade200),
        errorWidget: (_, _, _) => Container(
          width: size,
          height: size,
          color: _kPrimary.withValues(alpha: 0.06),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, color: _kSecondary),
        ),
      ),
    );
  }

  static String _labelForTag(String key) {
    switch (key) {
      case 'halal': return 'Halal';
      case 'vegetarian': return 'Mboga';
      case 'vegan': return 'Vegan';
      case 'no_pork': return 'Bila nguruwe';
      case 'gluten_free': return 'Bila ngano';
      case 'spicy': return 'Pilipili';
      default: return key;
    }
  }

  static String _fmt(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
