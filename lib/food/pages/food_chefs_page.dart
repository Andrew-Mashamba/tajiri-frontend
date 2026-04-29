import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/pages/partner_profile_page.dart';
import '../../tajirika/services/tajirika_service.dart';
import '../widgets/chef_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

const List<String> _kFoodSkillKeys = ['cooking', 'catering', 'baking'];

class FoodChefsPage extends StatefulWidget {
  const FoodChefsPage({super.key});

  @override
  State<FoodChefsPage> createState() => _FoodChefsPageState();
}

class _FoodChefsPageState extends State<FoodChefsPage> {
  List<TajirikaPartner> _chefs = [];
  bool _loading = true;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final chefs = await fetchFoodChefs();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _chefs = chefs;
    });
  }

  List<TajirikaPartner> get _filtered {
    if (_search.isEmpty) return _chefs;
    final q = _search.toLowerCase();
    return _chefs.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if ((c.bio ?? '').toLowerCase().contains(q)) return true;
      if (c.serviceArea.displayText.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  void _openChef(TajirikaPartner chef) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartnerProfilePage(partnerId: chef.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          'Wapishi wa Nyumbani',
          style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Tafuta mpishi, mahali...',
                  hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary, size: 20),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kPrimary),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }
    final chefs = _filtered;
    if (chefs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.restaurant_outlined, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _search.isEmpty
                  ? 'Hakuna wapishi walioorodheshwa kwa sasa. Jaribu tena baadaye.'
                  : 'Hakuna matokeo kwa "$_search".',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, height: 1.4),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: chefs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => ChefCard(
          chef: chefs[i],
          onTap: () => _openChef(chefs[i]),
        ),
      ),
    );
  }
}

/// Loads active partners whose skills include any food category (cooking,
/// catering, or baking). Three parallel queries are merged and deduped so
/// partners who only list one of the three still show up.
Future<List<TajirikaPartner>> fetchFoodChefs() async {
  final token = await AuthService.instance.getValidAccessToken();
  if (token == null || token.isEmpty) return const [];
  final lists = await Future.wait(
    _kFoodSkillKeys.map((s) => TajirikaService.searchPartners(
          token,
          skills: [s],
          available: true,
        )),
  );
  final seen = <int>{};
  final merged = <TajirikaPartner>[];
  for (final list in lists) {
    for (final p in list) {
      if (seen.add(p.id)) merged.add(p);
    }
  }
  merged.sort((a, b) => b.aggregateRating.compareTo(a.aggregateRating));
  return merged;
}
