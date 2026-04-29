import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../services/food_service.dart';
import 'chef_listing_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FoodSearchPage extends StatefulWidget {
  final int userId;
  const FoodSearchPage({super.key, required this.userId});

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  final FoodService _service = FoodService();
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;

  Map<String, List> _results = const {};
  List _trending = const [];

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(v.trim()));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _loading = true);
    final res = await _service.search(query: q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _results = {
          'chefs': (res.data!['chefs'] as List?) ?? const [],
          'restaurants': (res.data!['restaurants'] as List?) ?? const [],
          'dishes': (res.data!['dishes'] as List?) ?? const [],
          'listings': (res.data!['listings'] as List?) ?? const [],
        };
        _trending = (res.data!['trending'] as List?) ?? const [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        titleSpacing: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onQueryChanged,
            style: const TextStyle(color: _kPrimary, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Tafuta chef, chakula, mkahawa...',
              hintStyle: TextStyle(color: _kSecondary, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: _kSecondary, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _ctrl.text.trim().isEmpty
              ? _buildTrending()
              : _buildResults(),
    );
  }

  Widget _buildTrending() {
    if (_trending.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Anza kuandika ili kutafuta', style: TextStyle(color: _kSecondary)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Maarufu sasa', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ..._trending.cast<Map<String, dynamic>>().map(_trendingTile),
      ],
    );
  }

  Widget _trendingTile(Map<String, dynamic> t) {
    final title = t['title']?.toString() ?? '';
    final photo = ApiConfig.sanitizeUrl(t['photo_url']?.toString() ?? '') ?? '';
    final id = (t['id'] as num?)?.toInt() ?? 0;
    final price = (t['price_tzs'] as num?)?.toInt();
    return _listTile(
      photoUrl: photo,
      title: title,
      subtitle: price == null ? 'Mgao' : '${price.toString()} TZS',
      icon: Icons.restaurant_rounded,
      onTap: () => _openListing(id),
    );
  }

  Widget _buildResults() {
    final chefs = _results['chefs'] ?? [];
    final restaurants = _results['restaurants'] ?? [];
    final dishes = _results['dishes'] ?? [];
    final listings = _results['listings'] ?? [];
    final total = chefs.length + restaurants.length + dishes.length + listings.length;
    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Hamna matokeo', style: TextStyle(color: _kSecondary)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (listings.isNotEmpty) ...[
          _sectionHeader('Chakula cha Leo'),
          ...listings.cast<Map<String, dynamic>>().map((l) => _listTile(
                photoUrl: ApiConfig.sanitizeUrl(l['photo_url']?.toString() ?? '') ?? '',
                title: l['title']?.toString() ?? '',
                subtitle: (l['price_tzs'] as num?) != null ? '${l['price_tzs']} TZS' : 'Mgao',
                icon: Icons.restaurant_rounded,
                onTap: () => _openListing((l['id'] as num).toInt()),
              )),
          const SizedBox(height: 10),
        ],
        if (chefs.isNotEmpty) ...[
          _sectionHeader('Wapishi'),
          ...chefs.cast<Map<String, dynamic>>().map((c) => _listTile(
                photoUrl: ApiConfig.sanitizeUrl(c['photo_url']?.toString() ?? '') ?? '',
                title: c['name']?.toString() ?? '',
                subtitle: [c['ward'], c['district']].where((s) => s != null && s.toString().isNotEmpty).join(', '),
                icon: Icons.person_rounded,
              )),
          const SizedBox(height: 10),
        ],
        if (restaurants.isNotEmpty) ...[
          _sectionHeader('Mikahawa'),
          ...restaurants.cast<Map<String, dynamic>>().map((r) => _listTile(
                photoUrl: ApiConfig.sanitizeUrl(r['logo_url']?.toString() ?? r['cover_url']?.toString() ?? '') ?? '',
                title: r['name']?.toString() ?? '',
                subtitle: r['cuisine_type']?.toString() ?? '',
                icon: Icons.storefront_rounded,
              )),
          const SizedBox(height: 10),
        ],
        if (dishes.isNotEmpty) ...[
          _sectionHeader('Vyakula'),
          ...dishes.cast<Map<String, dynamic>>().map((d) => _listTile(
                photoUrl: ApiConfig.sanitizeUrl(d['image_url']?.toString() ?? '') ?? '',
                title: d['name']?.toString() ?? '',
                subtitle: '${d['restaurant_name'] ?? ''} · ${d['price'] ?? ''}',
                icon: Icons.ramen_dining_rounded,
              )),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
        child: Text(label, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _listTile({
    required String photoUrl,
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: _kPrimary.withValues(alpha: 0.05),
                      child: Icon(icon, color: _kSecondary),
                    ),
                  )
                : Container(
                    color: _kPrimary.withValues(alpha: 0.05),
                    child: Icon(icon, color: _kSecondary),
                  ),
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kSecondary, fontSize: 12)),
      ),
    );
  }

  void _openListing(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChefListingDetailPage(listingId: id, userId: widget.userId)),
    );
  }
}
