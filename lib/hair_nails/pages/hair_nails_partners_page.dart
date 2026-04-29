// Tajirika partner discovery for hair / nails professionals.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/services/tajirika_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class HairNailsPartnersPage extends StatefulWidget {
  final int userId;
  const HairNailsPartnersPage({super.key, required this.userId});

  @override
  State<HairNailsPartnersPage> createState() => _HairNailsPartnersPageState();
}

class _HairNailsPartnersPageState extends State<HairNailsPartnersPage> {
  List<TajirikaPartner> _partners = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(initial: true);
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({bool initial = false}) async {
    final token = await AuthService.instance.getValidAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _partners = [];
      });
      return;
    }
    if (initial) setState(() => _loading = true);
    final list = await TajirikaService.searchPartners(
      token,
      skills: const ['hair_nails'],
      page: 1,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _page = 1;
      _partners = list;
      _hasMore = list.length >= 15;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final token = await AuthService.instance.getValidAccessToken();
    if (token == null || token.isEmpty) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    final list = await TajirikaService.searchPartners(
      token,
      skills: const ['hair_nails'],
      page: next,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (list.isNotEmpty) _page = next;
      _partners = [..._partners, ...list];
      _hasMore = list.length >= 15;
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text(
          'Wataalamu wa Tajirika',
          style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: () => _load(initial: true),
                color: _kPrimary,
                child: _partners.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 40),
                          Icon(Icons.handyman_outlined, size: 48, color: _kSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Hakuna wataalamu walioorodheshwa kwa sasa. Jaribu tena baadaye.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _kSecondary, height: 1.4),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _partners.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _partners.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                              ),
                            );
                          }
                          final p = _partners[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: p.photoUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: p.photoUrl,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              memCacheWidth: 200,
                                              placeholder: (_, __) => Container(
                                                width: 56,
                                                height: 56,
                                                color: _kPrimary.withValues(alpha: 0.06),
                                              ),
                                              errorWidget: (_, __, ___) => Container(
                                                width: 56,
                                                height: 56,
                                                color: _kPrimary.withValues(alpha: 0.06),
                                                child: const Icon(Icons.person_rounded, color: _kSecondary),
                                              ),
                                            )
                                          : Container(
                                              width: 56,
                                              height: 56,
                                              color: _kPrimary.withValues(alpha: 0.06),
                                              child: const Icon(Icons.person_rounded, color: _kSecondary),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _kPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            p.tier.labelSwahili,
                                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                                          ),
                                          if (p.bio != null && p.bio!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              p.bio!,
                                              style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.35),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
