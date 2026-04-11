// lib/dawasco/pages/water_tips_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class WaterTipsPage extends StatefulWidget {
  const WaterTipsPage({super.key});
  @override
  State<WaterTipsPage> createState() => _WaterTipsPageState();
}

class _WaterTipsPageState extends State<WaterTipsPage> {
  List<WaterTip> _tips = [];
  bool _loading = true;
  String? _error;
  String _selectedCategory = 'all';

  final _categories = ['all', 'kitchen', 'bathroom', 'garden', 'laundry', 'general'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await DawascoService.getWaterTips();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.success) {
          _tips = result.items;
        } else {
          _error = result.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  String _catLabel(String cat, bool sw) {
    switch (cat) {
      case 'all': return sw ? 'Zote' : 'All';
      case 'kitchen': return sw ? 'Jikoni' : 'Kitchen';
      case 'bathroom': return sw ? 'Bafuni' : 'Bathroom';
      case 'garden': return sw ? 'Bustani' : 'Garden';
      case 'laundry': return sw ? 'Kufulia' : 'Laundry';
      case 'general': return sw ? 'Jumla' : 'General';
      default: return cat;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'kitchen': return Icons.kitchen_rounded;
      case 'bathroom': return Icons.bathtub_rounded;
      case 'garden': return Icons.yard_rounded;
      case 'laundry': return Icons.local_laundry_service_rounded;
      case 'general': return Icons.tips_and_updates_rounded;
      default: return Icons.water_drop_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final filtered = _selectedCategory == 'all'
        ? _tips
        : _tips.where((t) => t.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Vidokezo vya Kuokoa Maji' : 'Water Saving Tips',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: _kSecondary, fontSize: 13),
                      maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: Text(sw ? 'Jaribu tena' : 'Retry',
                      style: const TextStyle(color: _kPrimary))),
                ]))
              : Column(children: [
                  // Category filter
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final selected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? _kPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_catLabel(cat, sw),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                    color: selected ? Colors.white : _kPrimary)),
                          ),
                        );
                      },
                    ),
                  ),

                  // Tips list
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text(sw ? 'Hakuna vidokezo' : 'No tips available',
                            style: const TextStyle(color: _kSecondary, fontSize: 13)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: _kPrimary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final tip = filtered[i];
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: _kPrimary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(_catIcon(tip.category), size: 22, color: _kPrimary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(tip.title,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(tip.description,
                                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                                          maxLines: 4, overflow: TextOverflow.ellipsis),
                                      if (tip.savingsEstimate != null) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${sw ? 'Unaweza kuokoa' : 'Can save'}: ${tip.savingsEstimate}',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF4CAF50)),
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ])),
                                  ]),
                                );
                              },
                            ),
                          ),
                  ),
                ]),
    );
  }
}
