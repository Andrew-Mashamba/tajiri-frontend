// lib/tafuta_kanisa/pages/tafuta_kanisa_home_page.dart
import 'package:flutter/material.dart';
import '../models/tafuta_kanisa_models.dart';
import '../services/tafuta_kanisa_service.dart';
import '../widgets/church_listing_card.dart';
import 'church_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class TafutaKanisaHomePage extends StatefulWidget {
  final int userId;
  const TafutaKanisaHomePage({super.key, required this.userId});
  @override
  State<TafutaKanisaHomePage> createState() => _TafutaKanisaHomePageState();
}

class _TafutaKanisaHomePageState extends State<TafutaKanisaHomePage> {
  final _searchCtrl = TextEditingController();
  List<ChurchListing> _churches = [];
  List<String> _denominations = [];
  String? _selectedDenom;
  bool _isLoading = true;

  // Default Dar es Salaam coordinates
  final double _lat = -6.7924;
  final double _lng = 39.2083;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      TafutaKanisaService.search(
        latitude: _lat,
        longitude: _lng,
        denomination: _selectedDenom,
        query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      ),
      TafutaKanisaService.getDenominations(),
    ]);
    if (mounted) {
      final churchR = results[0] as PaginatedResult<ChurchListing>;
      final denomR = results[1] as PaginatedResult<String>;
      setState(() {
        _isLoading = false;
        if (churchR.success) _churches = churchR.items;
        if (denomR.success) _denominations = denomR.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Tafuta kanisa kwa jina...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: _kPrimary, size: 22),
                  onPressed: _showFilterSheet,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPrimary),
                ),
              ),
            ),
          ),

          // Denomination chips
          if (_denominations.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _DenomChip(
                      label: 'Zote / All',
                      selected: _selectedDenom == null,
                      onTap: () { _selectedDenom = null; _load(); }),
                  ..._denominations.take(8).map((d) => _DenomChip(
                        label: d,
                        selected: _selectedDenom == d,
                        onTap: () { _selectedDenom = d; _load(); },
                      )),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _churches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.church_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Hakuna makanisa yaliyopatikana',
                                style: TextStyle(color: _kSecondary, fontSize: 14)),
                            const Text('No churches found',
                                style: TextStyle(color: _kSecondary, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _churches.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => ChurchListingCard(
                            church: _churches[i],
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => ChurchProfilePage(churchId: _churches[i].id))),
                          ),
                        ),
                      ),
          ),
        ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chuja / Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 16),
              const Text('Dhehebu / Denomination',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _denominations.map((d) {
                  final sel = _selectedDenom == d;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectedDenom = sel ? null : d;
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? _kPrimary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(d,
                          style: TextStyle(
                            fontSize: 13,
                            color: sel ? Colors.white : _kPrimary,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _selectedDenom = null;
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ondoa Vichujio / Clear Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DenomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DenomChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : _kSecondary,
              )),
        ),
      ),
    );
  }
}
