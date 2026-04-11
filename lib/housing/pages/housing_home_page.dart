// lib/housing/pages/housing_home_page.dart
import 'package:flutter/material.dart';
import '../models/housing_models.dart';
import '../services/housing_service.dart';
import '../widgets/property_card.dart';
import 'property_detail_page.dart';
import 'search_property_page.dart';
import 'my_rentals_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class HousingHomePage extends StatefulWidget {
  final int userId;
  const HousingHomePage({super.key, required this.userId});
  @override
  State<HousingHomePage> createState() => _HousingHomePageState();
}

class _HousingHomePageState extends State<HousingHomePage> {
  final HousingService _service = HousingService();

  List<Property> _featured = [];
  List<Property> _recent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getFeaturedProperties(),
      _service.getProperties(),
    ]);
    if (mounted) {
      final featuredResult = results[0];
      final recentResult = results[1];
      setState(() {
        _isLoading = false;
        if (featuredResult.success) _featured = featuredResult.items;
        if (recentResult.success) _recent = recentResult.items;
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.home_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Nyumba Tajiri',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Panga, nunua, au pata nyumba yako inayofuata.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                  child: _QuickAction(
                      icon: Icons.search_rounded,
                      label: 'Tafuta',
                      onTap: () => _nav(
                          SearchPropertyPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(
                  child: _QuickAction(
                      icon: Icons.home_work_rounded,
                      label: 'Kodi Zangu',
                      onTap: () =>
                          _nav(MyRentalsPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(
                  child: _QuickAction(
                      icon: Icons.apartment_rounded,
                      label: 'Fleti',
                      onTap: () => _nav(SearchPropertyPage(
                          userId: widget.userId,
                          initialType: PropertyType.apartment)))),
              const SizedBox(width: 10),
              Expanded(
                  child: _QuickAction(
                      icon: Icons.landscape_rounded,
                      label: 'Viwanja',
                      onTap: () => _nav(SearchPropertyPage(
                          userId: widget.userId,
                          initialType: PropertyType.land)))),
            ],
          ),
          const SizedBox(height: 20),

          // Categories
          const Text('Aina za Mali',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: PropertyType.values.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _nav(SearchPropertyPage(
                        userId: widget.userId, initialType: t)),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(t.icon, color: _kPrimary, size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(t.displayName,
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Featured
          if (_featured.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pendekezo',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
                TextButton(
                  onPressed: () =>
                      _nav(SearchPropertyPage(userId: widget.userId)),
                  child: const Text('Zote',
                      style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._featured.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PropertyCard(
                    property: p,
                    onTap: () => _nav(PropertyDetailPage(
                        property: p, userId: widget.userId)),
                  ),
                )),
          ],

          // Recent
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Mpya',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            ..._recent.take(5).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PropertyCard(
                    property: p,
                    onTap: () => _nav(PropertyDetailPage(
                        property: p, userId: widget.userId)),
                  ),
                )),
          ],

          // Empty state
          if (_featured.isEmpty && _recent.isEmpty)
            _EmptyState(
              icon: Icons.home_rounded,
              title: 'Hakuna mali kwa sasa',
              subtitle: 'Tafuta nyumba, fleti, au viwanja vinavyopatikana.',
              actionLabel: 'Tafuta Sasa',
              onAction: () =>
                  _nav(SearchPropertyPage(userId: widget.userId)),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: _kSecondary),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
