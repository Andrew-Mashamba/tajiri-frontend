import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../tajirika/pages/partner_profile_page.dart';
import '../models/beneficiary_org.dart';
import '../services/food_service.dart';
import 'beneficiary_profile_page.dart';
import 'restaurant_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFD32F2F);

class FavouritesPage extends StatefulWidget {
  final int userId;
  const FavouritesPage({super.key, required this.userId});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> with SingleTickerProviderStateMixin {
  final FoodService _service = FoodService();
  late TabController _tabs;

  List<Map<String, dynamic>> _chefs = const [];
  List<Map<String, dynamic>> _restaurants = const [];
  List<BeneficiaryOrg> _orgs = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final favRes = await _service.listFavourites(widget.userId);
    final orgRes = await _service.listFollowedBeneficiaryOrgs(widget.userId);
    if (!mounted) return;
    if (!favRes.success) {
      setState(() {
        _loading = false;
        _error = favRes.message ?? 'Imeshindwa';
      });
      return;
    }
    final chefs = <Map<String, dynamic>>[];
    final rests = <Map<String, dynamic>>[];
    for (final row in favRes.items) {
      final t = row['target_type']?.toString();
      final target = row['target'];
      if (target is! Map) continue;
      final merged = <String, dynamic>{
        'favourite_id': (row['id'] as num?)?.toInt(),
        'target_type': t,
        ...target.cast<String, dynamic>(),
      };
      if (t == 'chef') {
        chefs.add(merged);
      } else if (t == 'restaurant') {
        rests.add(merged);
      }
    }
    final orgs = <BeneficiaryOrg>[];
    if (orgRes.success) {
      for (final r in orgRes.items) {
        try {
          orgs.add(BeneficiaryOrg.fromJson(r));
        } catch (_) {}
      }
    }
    setState(() {
      _loading = false;
      _chefs = chefs;
      _restaurants = rests;
      _orgs = orgs;
    });
  }

  Future<void> _unfavourite(int favouriteId) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.removeFavourite(userId: widget.userId, favouriteId: favouriteId);
    if (!mounted) return;
    if (res.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Imeondolewa')));
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  Future<void> _unfollowOrg(int orgId) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.unfollowBeneficiaryOrg(orgId: orgId, userId: widget.userId);
    if (!mounted) return;
    if (res.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Umeacha kufuata')));
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text('Zilizopendekezwa',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Wapishi (${_chefs.length})'),
            Tab(text: 'Mikahawa (${_restaurants.length})'),
            Tab(text: 'Mashirika (${_orgs.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? _errorState(_error!)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _chefsTab(),
                    _restaurantsTab(),
                    _orgsTab(),
                  ],
                ),
    );
  }

  Widget _errorState(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              Text(msg, style: const TextStyle(fontSize: 13, color: _kSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Jaribu tena')),
            ],
          ),
        ),
      );

  Widget _emptyState(IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(text, style: const TextStyle(fontSize: 13, color: _kSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _chefsTab() {
    if (_chefs.isEmpty) {
      return _emptyState(Icons.soup_kitchen_rounded, 'Bado hujahifadhi mpishi yeyote. Fungua mpishi na bonyeza moyo.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _chefs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _chefCard(_chefs[i]),
      ),
    );
  }

  Widget _restaurantsTab() {
    if (_restaurants.isEmpty) {
      return _emptyState(Icons.restaurant_rounded, 'Bado hujahifadhi mkahawa. Fungua mkahawa na bonyeza moyo.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _restaurants.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _restaurantCard(_restaurants[i]),
      ),
    );
  }

  Widget _orgsTab() {
    if (_orgs.isEmpty) {
      return _emptyState(Icons.volunteer_activism_rounded, 'Bado hujafuata shirika. Fungua shirika na bonyeza "Fuatilia".');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _orgs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _orgCard(_orgs[i]),
      ),
    );
  }

  Widget _chefCard(Map<String, dynamic> row) {
    final id = (row['id'] as num?)?.toInt() ?? 0;
    final name = row['name']?.toString() ?? 'Mpishi';
    final photoRaw = row['photo_url']?.toString() ?? '';
    final rating = (row['rating'] as num?)?.toDouble() ?? 0.0;
    final jobs = (row['jobs_completed'] as num?)?.toInt() ?? 0;
    final ward = row['ward']?.toString() ?? '';
    final district = row['district']?.toString() ?? '';
    final loc = [ward, district].where((s) => s.trim().isNotEmpty).join(', ');
    final photoUrl = photoRaw.isEmpty
        ? ''
        : (photoRaw.startsWith('http')
            ? (ApiConfig.sanitizeUrl(photoRaw) ?? '')
            : (ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$photoRaw') ?? ''));
    return _tile(
      favouriteId: (row['favourite_id'] as num?)?.toInt(),
      photoUrl: photoUrl,
      fallbackIcon: Icons.soup_kitchen_rounded,
      title: name,
      subtitle: [
        if (rating > 0) '⭐ ${rating.toStringAsFixed(1)}',
        if (jobs > 0) '$jobs kazi',
        if (loc.isNotEmpty) loc,
      ].join(' · '),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartnerProfilePage(partnerId: id)),
      ),
      onRemove: () {
        final fid = (row['favourite_id'] as num?)?.toInt();
        if (fid != null) _unfavourite(fid);
      },
    );
  }

  Widget _restaurantCard(Map<String, dynamic> row) {
    final id = (row['id'] as num?)?.toInt() ?? 0;
    final name = row['name']?.toString() ?? 'Mkahawa';
    final logoRaw = row['logo_url']?.toString() ?? '';
    final rating = (row['rating'] as num?)?.toDouble() ?? 0.0;
    final cuisine = row['cuisine_type']?.toString() ?? '';
    final photoUrl = logoRaw.isEmpty
        ? ''
        : (logoRaw.startsWith('http')
            ? (ApiConfig.sanitizeUrl(logoRaw) ?? '')
            : (ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$logoRaw') ?? ''));
    return _tile(
      favouriteId: (row['favourite_id'] as num?)?.toInt(),
      photoUrl: photoUrl,
      fallbackIcon: Icons.restaurant_rounded,
      title: name,
      subtitle: [
        if (rating > 0) '⭐ ${rating.toStringAsFixed(1)}',
        if (cuisine.isNotEmpty) cuisine,
      ].join(' · '),
      onTap: () => _openRestaurantById(id),
      onRemove: () {
        final fid = (row['favourite_id'] as num?)?.toInt();
        if (fid != null) _unfavourite(fid);
      },
    );
  }

  Future<void> _openRestaurantById(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final res = await _service.getRestaurant(id);
    if (!mounted) return;
    if (!res.success || res.data == null) {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
      return;
    }
    navigator.push(
      MaterialPageRoute(
        builder: (_) => RestaurantPage(
          userId: widget.userId,
          restaurant: res.data!,
          cart: const [],
          onCartUpdated: (_, _, _) {},
        ),
      ),
    );
  }

  Widget _orgCard(BeneficiaryOrg org) {
    final photoUrl = org.resolvedPhotoUrl;
    final loc = [org.ward, org.district]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    final pop = org.populationServed ?? 0;
    return _tile(
      favouriteId: null,
      photoUrl: photoUrl,
      fallbackIcon: Icons.volunteer_activism_rounded,
      title: org.name,
      subtitle: [
        org.type.labelSwahili,
        if (loc.isNotEmpty) loc,
        if (pop > 0) '$pop waliohudumiwa',
      ].join(' · '),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BeneficiaryProfilePage(orgId: org.id, userId: widget.userId)),
      ),
      onRemove: () => _unfollowOrg(org.id),
    );
  }

  Widget _tile({
    required int? favouriteId,
    required String photoUrl,
    required IconData fallbackIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: photoUrl.isEmpty
                      ? Container(
                          color: _kPrimary.withValues(alpha: 0.06),
                          child: Icon(fallbackIcon, color: _kPrimary, size: 26),
                        )
                      : CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(
                            color: _kPrimary.withValues(alpha: 0.06),
                            child: Icon(fallbackIcon, color: _kPrimary, size: 26),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ondoa',
                icon: const Icon(Icons.favorite_rounded, color: _kDanger, size: 20),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

