// lib/tanesco/pages/energy_tips_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EnergyTipsPage extends StatefulWidget {
  const EnergyTipsPage({super.key});
  @override
  State<EnergyTipsPage> createState() => _EnergyTipsPageState();
}

class _EnergyTipsPageState extends State<EnergyTipsPage> {
  static const _categories = ['all', 'kitchen', 'lighting', 'cooling', 'laundry', 'general'];
  static const _categoryLabelsSw = ['Zote', 'Jikoni', 'Taa', 'Baridi', 'Kufulia', 'Jumla'];
  static const _categoryLabelsEn = ['All', 'Kitchen', 'Lighting', 'Cooling', 'Laundry', 'General'];
  static const _categoryIcons = [
    Icons.tips_and_updates_rounded,
    Icons.kitchen_rounded,
    Icons.lightbulb_rounded,
    Icons.ac_unit_rounded,
    Icons.local_laundry_service_rounded,
    Icons.eco_rounded,
  ];

  int _categoryIndex = 0;
  List<EnergyTip> _tips = [];
  bool _loading = true;

  // Offline/fallback tips
  static final _fallbackTips = [
    EnergyTip(title: 'Tumia taa za LED', description: 'Taa za LED zinatumia umeme kidogo kwa 80% kuliko taa za kawaida. LED bulbs use 80% less energy than incandescent bulbs.',
        savingsEstimate: '75-80%', category: 'lighting'),
    EnergyTip(title: 'Zima vifaa visivyotumika', description: 'Zima TV, kompyuta na vifaa vingine visipokuwa vinatumika. Turn off devices when not in use - standby mode still uses power.',
        savingsEstimate: '5-10%', category: 'general'),
    EnergyTip(title: 'Jokofu - weka mbali na joto', description: 'Weka jokofu mbali na jiko na jua. Keep fridge away from heat sources and ensure air circulation at the back.',
        savingsEstimate: '10-15%', category: 'kitchen'),
    EnergyTip(title: 'Pika kwa kifuniko', description: 'Tumia kifuniko wakati wa kupika ili kupunguza muda wa kupika. Use lids when cooking to reduce cooking time and energy.',
        savingsEstimate: '10-20%', category: 'kitchen'),
    EnergyTip(title: 'Feni badala ya AC', description: 'Tumia feni ya dari badala ya AC inayowezekana. Ceiling fans use 10% of the energy an AC uses.',
        savingsEstimate: '60-70%', category: 'cooling'),
    EnergyTip(title: 'AC: set 24-25 degrees', description: 'Usiseti AC chini ya 24. Kila degree chini inaongeza matumizi 6%. Each degree below 24 increases consumption by 6%.',
        savingsEstimate: '6% per degree', category: 'cooling'),
    EnergyTip(title: 'Fulua kwa maji baridi', description: 'Tumia maji baridi kufulia nguo. Washing with cold water saves the energy of heating water.',
        savingsEstimate: '40-50%', category: 'laundry'),
    EnergyTip(title: 'Anika nguo nje', description: 'Anika nguo kwenye jua badala ya tumia dryer. Air drying saves 100% of dryer energy.',
        savingsEstimate: '100%', category: 'laundry'),
    EnergyTip(title: 'Tumia natural light', description: 'Fungua madirisha wakati wa mchana. Use daylight instead of artificial lighting during the day.',
        savingsEstimate: '20-30%', category: 'lighting'),
    EnergyTip(title: 'Angalia rating ya vifaa', description: 'Nunua vifaa vyenye energy rating nzuri. Buy appliances with good energy efficiency ratings.',
        savingsEstimate: '15-30%', category: 'general'),
    EnergyTip(title: 'Pasi nguo nyingi kwa wakati mmoja', description: 'Jikusanyie nguo nyingi kisha pasi zote kwa wakati mmoja. Iron multiple items at once to avoid reheating.',
        savingsEstimate: '10-20%', category: 'laundry'),
    EnergyTip(title: 'Ondoa barafu kwenye jokofu', description: 'Jokofu yenye barafu nyingi inatumia umeme zaidi. Defrost your fridge regularly for better efficiency.',
        savingsEstimate: '10-15%', category: 'kitchen'),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await TanescoService.getEnergyTips();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.items.isNotEmpty) {
        _tips = result.items;
      } else {
        _tips = _fallbackTips;
      }
    });
  }

  List<EnergyTip> get _filtered {
    if (_categoryIndex == 0) return _tips;
    return _tips.where((t) => t.category == _categories[_categoryIndex]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Vidokezo vya Nishati' : 'Energy Tips',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : Column(
              children: [
                // Category tabs
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setState(() => _categoryIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _categoryIndex == i ? _kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _categoryIndex == i ? _kPrimary : Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_categoryIcons[i], size: 14,
                              color: _categoryIndex == i ? Colors.white : _kSecondary),
                          const SizedBox(width: 4),
                          Text(((AppStringsScope.of(context)?.isSwahili ?? false) ? _categoryLabelsSw : _categoryLabelsEn)[i], style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _categoryIndex == i ? Colors.white : _kSecondary)),
                        ]),
                      ),
                    ),
                  ),
                ),

                // Tips list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(
                          (AppStringsScope.of(context)?.isSwahili ?? false) ? 'Hakuna vidokezo' : 'No tips available',
                          style: const TextStyle(fontSize: 13, color: _kSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final tip = filtered[i];
                            return _TipCard(tip: tip);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final EnergyTip tip;
  const _TipCard({required this.tip});

  IconData _categoryIcon() {
    switch (tip.category) {
      case 'kitchen': return Icons.kitchen_rounded;
      case 'lighting': return Icons.lightbulb_rounded;
      case 'cooling': return Icons.ac_unit_rounded;
      case 'laundry': return Icons.local_laundry_service_rounded;
      default: return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_categoryIcon(), size: 20, color: const Color(0xFF4CAF50)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(tip.description,
                    style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.4),
                    maxLines: 4, overflow: TextOverflow.ellipsis),
                if (tip.savingsEstimate != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Okoa / Save: ${tip.savingsEstimate}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50))),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
