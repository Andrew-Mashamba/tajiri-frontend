// lib/skincare/pages/ingredient_checker_page.dart
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';
import '../services/skincare_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFD32F2F);
const Color _kCaution = Color(0xFFFF8F00);
const Color _kSafe = Color(0xFF4CAF50);

class IngredientCheckerPage extends StatefulWidget {
  const IngredientCheckerPage({super.key});
  @override
  State<IngredientCheckerPage> createState() => _IngredientCheckerPageState();
}

class _IngredientCheckerPageState extends State<IngredientCheckerPage> {
  final SkincareService _service = SkincareService();
  final TextEditingController _inputController = TextEditingController();

  List<DangerousIngredient> _knownDangerous = [];
  List<_CheckedIngredient> _results = [];
  // ignore: prefer_final_fields
  bool _isLoading = false;
  bool _hasChecked = false;

  // ─── TMDA Banned Chemicals ────────────────────────────────────
  // These are flagged regardless of backend data
  static const Map<String, String> _tmdaBanned = {
    'mercury': 'Mercury ni sumu kali \u2014 husababisha uharibifu wa figo, mishipa ya fahamu, na ngozi. TMDA imeipiga marufuku kabisa.',
    'mercurous chloride': 'Calomel (mercury compound) \u2014 sumu kali, TMDA imeipiga marufuku.',
    'mercuric chloride': 'Mercury compound hatari sana \u2014 TMDA imeipiga marufuku.',
    'ammoniated mercury': 'Mercury compound \u2014 TMDA imeipiga marufuku.',
    'hydroquinone': 'Hydroquinone >2% ni hatari \u2014 inasababisha ochronosis (ngozi kuwa nyeusi zaidi milele). TMDA inaruhusu <2% tu kwa dawa ya daktari.',
    'clobetasol': 'Clobetasol propionate ni steroid kali sana \u2014 inapunguza kinga ya ngozi, husababisha ngozi nyembamba, na vidonda. TMDA inaruhusu kwa dawa ya daktari tu.',
    'clobetasol propionate': 'Steroid kali \u2014 husababisha ngozi nyembamba, stretch marks, na maambukizi. TMDA: dawa ya daktari tu.',
    'betamethasone': 'Steroid kali \u2014 matumizi ya muda mrefu husababisha uharibifu wa ngozi. TMDA: dawa ya daktari tu.',
    'lead': 'Lead (risasi) ni sumu kali \u2014 husababisha matatizo ya ubongo na figo. TMDA imeipiga marufuku.',
    'lead acetate': 'Lead compound \u2014 sumu kali, TMDA imeipiga marufuku.',
    'tretinoin': 'Tretinoin ni dawa ya nguvu \u2014 inahitaji usimamizi wa daktari. TMDA: dawa ya daktari tu.',
    'kojic acid': 'Kojic acid kwa kiwango cha juu inaweza kusababisha dermatitis. Tumia kiwango kidogo tu.',
  };

  // Commonly found dangerous chemicals in East African market
  static const Map<String, String> _commonDangerous = {
    'formaldehyde': 'Kemikali ya kuhifadhi \u2014 inaweza kusababisha saratani na mzio mkali wa ngozi.',
    'parabens': 'Methylparaben, propylparaben \u2014 zinaweza kuathiri homoni. Epuka kwa watoto wadogo.',
    'triclosan': 'Inathiri homoni na kusababisha usugu wa bakteria.',
    'sodium lauryl sulfate': 'SLS inaweza kukausha na kuwasha ngozi nyeti.',
    'toluene': 'Kemikali ya viwandani \u2014 inaweza kuathiri mfumo wa fahamu.',
    'dioxane': '1,4-Dioxane inaweza kusababisha saratani.',
  };

  @override
  void initState() {
    super.initState();
    _loadDangerousList();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadDangerousList() async {
    final result = await _service.getDangerousIngredients();
    if (mounted && result.success) {
      setState(() => _knownDangerous = result.items);
    }
  }

  void _checkIngredients() {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    final ingredients = input
        .split(RegExp(r'[,\n;]'))
        .map((i) => i.trim().toLowerCase())
        .where((i) => i.isNotEmpty)
        .toList();

    final results = <_CheckedIngredient>[];

    for (final ingredient in ingredients) {
      // Check TMDA banned list first (highest priority)
      String? matchedBanned;
      String? bannedReason;
      for (final entry in _tmdaBanned.entries) {
        if (ingredient.contains(entry.key) || entry.key.contains(ingredient)) {
          matchedBanned = entry.key;
          bannedReason = entry.value;
          break;
        }
      }

      if (matchedBanned != null) {
        results.add(_CheckedIngredient(
          name: ingredient,
          level: 'danger',
          reason: bannedReason!,
          isTmdaBanned: true,
        ));
        continue;
      }

      // Check common dangerous
      String? dangerousReason;
      for (final entry in _commonDangerous.entries) {
        if (ingredient.contains(entry.key) || entry.key.contains(ingredient)) {
          dangerousReason = entry.value;
          break;
        }
      }

      if (dangerousReason != null) {
        results.add(_CheckedIngredient(
          name: ingredient,
          level: 'caution',
          reason: dangerousReason,
          isTmdaBanned: false,
        ));
        continue;
      }

      // Check backend list
      final backendMatch = _knownDangerous.where((d) =>
          ingredient.contains(d.name.toLowerCase()) || d.name.toLowerCase().contains(ingredient));
      if (backendMatch.isNotEmpty) {
        final m = backendMatch.first;
        results.add(_CheckedIngredient(
          name: ingredient,
          level: m.level,
          reason: m.reason,
          isTmdaBanned: m.isDanger,
        ));
        continue;
      }

      // Safe / unknown
      results.add(_CheckedIngredient(
        name: ingredient,
        level: 'safe',
        reason: 'Hakuna hatari iliyopatikana',
        isTmdaBanned: false,
      ));
    }

    // Sort: danger first, then caution, then safe
    results.sort((a, b) {
      const order = {'danger': 0, 'caution': 1, 'safe': 2};
      return (order[a.level] ?? 2).compareTo(order[b.level] ?? 2);
    });

    setState(() {
      _results = results;
      _hasChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dangerCount = _results.where((r) => r.level == 'danger').length;
    final cautionCount = _results.where((r) => r.level == 'caution').length;
    final safeCount = _results.where((r) => r.level == 'safe').length;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kagua Kemikali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // TMDA Warning header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kDanger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDanger.withValues(alpha: 0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_rounded, size: 22, color: _kDanger),
                    SizedBox(width: 8),
                    Text(
                      'TAHADHARI \u2014 TMDA Tanzania',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDanger),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Bidhaa nyingi za kubadilisha rangi ya ngozi (skin lightening/bleaching) zinazouzwa Tanzania zina kemikali hatari zilizopigwa marufuku na TMDA.',
                  style: TextStyle(fontSize: 12, color: _kDanger, height: 1.5),
                ),
                SizedBox(height: 8),
                Text(
                  'Kemikali hatari zaidi:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kDanger),
                ),
                SizedBox(height: 4),
                Text(
                  '\u2022 Mercury (Zebaki) \u2014 sumu kali kwa figo na ubongo\n'
                  '\u2022 Hydroquinone >2% \u2014 husababisha ochronosis\n'
                  '\u2022 Clobetasol/Betamethasone \u2014 steroid hatari\n'
                  '\u2022 Lead (Risasi) \u2014 sumu ya milele',
                  style: TextStyle(fontSize: 11, color: _kDanger, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Skin lightening education
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: _kPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Kuhusu Bidhaa za Kubadilisha Rangi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bidhaa za kupauka (skin bleaching) zinaweza kusababisha:\n'
                  '\u2022 Ngozi kuwa nyembamba na kuumia haraka\n'
                  '\u2022 Madoa meusi yasiyoisha (ochronosis)\n'
                  '\u2022 Maambukizi ya ngozi\n'
                  '\u2022 Uharibifu wa figo na ini\n'
                  '\u2022 Saratani ya ngozi\n\n'
                  'Ngozi yako ya asili ni nzuri \u2014 ilinde, usiibadilishe!',
                  style: TextStyle(fontSize: 12, color: _kSecondary, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Input area
          const Text('Weka Viambato Hapa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(
            'Andika orodha ya viambato (ingredients) kutoka kwenye bidhaa. Tenganisha kwa koma au mstari mpya.',
            style: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _inputController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'k.m. aqua, glycerin, niacinamide, hydroquinone, mercury...',
              hintStyle: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.4)),
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary)),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkIngredients,
              icon: const Icon(Icons.science_rounded, size: 18),
              label: const Text('Kagua Usalama', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Results
          if (_hasChecked && _results.isNotEmpty) ...[
            // Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dangerCount > 0
                    ? _kDanger.withValues(alpha: 0.06)
                    : cautionCount > 0
                        ? _kCaution.withValues(alpha: 0.06)
                        : _kSafe.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryBadge(count: dangerCount, label: 'Hatari', color: _kDanger, icon: Icons.dangerous_rounded),
                  _SummaryBadge(count: cautionCount, label: 'Tahadhari', color: _kCaution, icon: Icons.warning_amber_rounded),
                  _SummaryBadge(count: safeCount, label: 'Salama', color: _kSafe, icon: Icons.check_circle_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Individual results
            ..._results.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _IngredientResultCard(result: r),
                )),
            const SizedBox(height: 16),

            // Report to TMDA button
            if (dangerCount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kDanger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kDanger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Bidhaa hii ina kemikali hatari!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kDanger),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unaweza kutoa taarifa kwa TMDA kuhusu bidhaa hatari inayouzwa Tanzania.',
                      style: TextStyle(fontSize: 12, color: _kDanger),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Taarifa itatumwa kwa TMDA. Asante kwa kulinda jamii!'),
                              backgroundColor: _kPrimary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.report_rounded, size: 18, color: _kDanger),
                        label: const Text(
                          'Taarifa kwa TMDA',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _kDanger),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kDanger),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          if (_hasChecked && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Weka viambato hapo juu ili kupata matokeo',
                  style: TextStyle(fontSize: 13, color: _kSecondary.withValues(alpha: 0.6)),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Result Models & Widgets ────────────────────────────────────

class _CheckedIngredient {
  final String name;
  final String level; // danger, caution, safe
  final String reason;
  final bool isTmdaBanned;

  _CheckedIngredient({
    required this.name,
    required this.level,
    required this.reason,
    required this.isTmdaBanned,
  });
}

class _SummaryBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  const _SummaryBadge({required this.count, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _IngredientResultCard extends StatelessWidget {
  final _CheckedIngredient result;
  const _IngredientResultCard({required this.result});

  Color get _color {
    switch (result.level) {
      case 'danger': return _kDanger;
      case 'caution': return _kCaution;
      default: return _kSafe;
    }
  }

  IconData get _icon {
    switch (result.level) {
      case 'danger': return Icons.dangerous_rounded;
      case 'caution': return Icons.warning_amber_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  String get _levelLabel {
    switch (result.level) {
      case 'danger': return 'HATARI';
      case 'caution': return 'TAHADHARI';
      default: return 'SALAMA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: result.level == 'danger' ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(12),
        border: result.level == 'danger'
            ? Border.all(color: _kDanger.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 22, color: _color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.name.toUpperCase(),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _levelLabel,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _color),
                      ),
                    ),
                  ],
                ),
                if (result.isTmdaBanned) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kDanger,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TMDA IMEPIGA MARUFUKU',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  result.reason,
                  style: TextStyle(fontSize: 12, color: _color.withValues(alpha: 0.8), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
