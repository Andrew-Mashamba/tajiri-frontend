// lib/my_children/pages/toddler_nutrition_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ToddlerNutritionPage extends StatefulWidget {
  final Child child;

  const ToddlerNutritionPage({super.key, required this.child});

  @override
  State<ToddlerNutritionPage> createState() => _ToddlerNutritionPageState();
}

class _ToddlerNutritionPageState extends State<ToddlerNutritionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Meal plan: day -> mealType -> value
  // Days: 0=Mon..6=Sun, mealTypes: breakfast, lunch, dinner, snacks
  Map<int, Map<String, String>> _mealPlan = {};
  bool _mealPlanLoaded = false;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  List<String> get _childAllergies => widget.child.allergies;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMealPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _mealPlanKey => 'meal_plan_${widget.child.id}';

  Future<void> _loadMealPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_mealPlanKey);
      if (json != null && mounted) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final plan = <int, Map<String, String>>{};
        decoded.forEach((dayKey, meals) {
          final dayIdx = int.tryParse(dayKey) ?? 0;
          plan[dayIdx] = (meals as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString()));
        });
        setState(() {
          _mealPlan = plan;
          _mealPlanLoaded = true;
        });
      } else {
        if (mounted) setState(() => _mealPlanLoaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _mealPlanLoaded = true);
    }
  }

  Future<void> _saveMealPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, dynamic>{};
      _mealPlan.forEach((day, meals) {
        encoded[day.toString()] = meals;
      });
      await prefs.setString(_mealPlanKey, jsonEncode(encoded));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_sw ? 'Mpango umehifadhiwa' : 'Meal plan saved'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindikana kuhifadhi' : 'Failed to save')),
      );
    }
  }

  // ─── Allergy matching ──────────────────────────────────────

  /// Check if a meal contains any known allergen.
  /// Returns the list of matching allergens.
  List<String> _matchAllergens(_Meal meal) {
    if (_childAllergies.isEmpty) return [];
    final matched = <String>[];
    for (final allergen in _childAllergies) {
      final lower = allergen.toLowerCase();
      // Check both English and Swahili names
      if (meal.en.toLowerCase().contains(lower) ||
          meal.sw.toLowerCase().contains(lower) ||
          _allergenFoodMap.entries.any((e) =>
              e.key.toLowerCase() == lower &&
              e.value.any((food) =>
                  meal.en.toLowerCase().contains(food.toLowerCase()) ||
                  meal.sw.toLowerCase().contains(food.toLowerCase())))) {
        matched.add(allergen);
      }
    }
    return matched;
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Lishe' : 'Nutrition',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kTertiary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: sw ? 'Mapendekezo' : 'Suggestions'),
            Tab(text: sw ? 'Mpango wa Mlo' : 'Meal Plan'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSuggestionsTab(sw),
            _buildMealPlanTab(sw),
          ],
        ),
      ),
    );
  }

  // ─── Suggestions Tab ──────────────────────────────────────

  Widget _buildSuggestionsTab(bool sw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Allergy notice
        if (_childAllergies.isNotEmpty)
          _buildAllergyNotice(sw)
        else
          _buildAddAllergyPrompt(sw),
        const SizedBox(height: 16),

        _buildSectionTitle(sw ? 'Kifungua Kinywa' : 'Breakfast'),
        const SizedBox(height: 8),
        _buildMealCard(Icons.wb_sunny_rounded, _breakfastMeals, sw),
        const SizedBox(height: 16),

        _buildSectionTitle(sw ? 'Chakula cha Mchana' : 'Lunch'),
        const SizedBox(height: 8),
        _buildMealCard(Icons.restaurant_rounded, _lunchMeals, sw),
        const SizedBox(height: 16),

        _buildSectionTitle(sw ? 'Chakula cha Jioni' : 'Dinner'),
        const SizedBox(height: 8),
        _buildMealCard(Icons.nightlight_rounded, _dinnerMeals, sw),
        const SizedBox(height: 16),

        _buildSectionTitle(sw ? 'Vitafunio' : 'Snacks'),
        const SizedBox(height: 8),
        _buildMealCard(Icons.cookie_rounded, _snackMeals, sw),
        const SizedBox(height: 24),

        // Hydration reminder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.water_drop_rounded, size: 28, color: _kPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw ? 'Kumbuka Maji!' : 'Hydration Reminder!',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sw
                          ? 'Watoto wa miaka 2-5 wanahitaji vikombe 4-5 vya maji kwa siku'
                          : 'Children aged 2-5 need 4-5 cups of water per day',
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Picky eater tips
        _buildSectionTitle(
            sw ? 'Vidokezo kwa Mtoto Anayechagua Chakula' : 'Picky Eater Tips'),
        const SizedBox(height: 8),
        ..._pickyEaterTips.map((tip) => _buildTipCard(tip, sw)),
        const SizedBox(height: 24),

        // Allergy awareness
        _buildSectionTitle(sw ? 'Ufahamu wa Mzio' : 'Allergy Awareness'),
        const SizedBox(height: 8),
        ..._allergyCards.map((a) => _buildAllergyCard(a, sw)),
        const SizedBox(height: 24),

        // ─── Cross-module links ──────────────────
        _buildSectionTitle(sw ? 'Viunganishi' : 'Related'),
        const SizedBox(height: 8),

        // Child allergy flag
        if (_childAllergies.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sw
                        ? '${widget.child.name} ana mzio wa: ${_childAllergies.join(", ")}. Imetajwa kwenye mapendekezo.'
                        : '${widget.child.name} is allergic to: ${_childAllergies.join(", ")}. Flagged in meal suggestions.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        _buildCrossModuleLink(
          icon: Icons.shopping_cart_rounded,
          label: sw
              ? 'Nunua vyakula vya watoto na vitafunio'
              : 'Shop toddler food and snacks',
          onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
        ),
        _buildCrossModuleLink(
          icon: Icons.chat_rounded,
          label: sw
              ? 'Uliza Shangazi kuhusu milo bora kwa miaka ${widget.child.ageInYears}'
              : 'Ask Shangazi about healthy meals for age ${widget.child.ageInYears}',
          onTap: () => Navigator.pushNamed(context, '/chat/0'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAllergyNotice(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 22, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Mzio wa ${widget.child.name}' : '${widget.child.name}\'s Allergies',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _childAllergies
                      .map((a) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(
                                  fontSize: 12, color: _kPrimary),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                Text(
                  sw
                      ? 'Vyakula vyenye mzio vimeonyeshwa hapa chini'
                      : 'Meals containing allergens are flagged below',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAllergyPrompt(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: _kSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sw
                  ? 'Ongeza mzio wa ${widget.child.name} kwenye wasifu ili tupendekeze chakula salama'
                  : 'Add ${widget.child.name}\'s allergies to their profile for safe meal suggestions',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _kPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMealCard(IconData icon, List<_Meal> meals, bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: meals.map((meal) {
          final allergens = _matchAllergens(meal);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: _kSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sw ? meal.sw : meal.en,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sw ? meal.en : meal.sw,
                        style:
                            const TextStyle(fontSize: 11, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (allergens.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_rounded,
                                  size: 14, color: _kPrimary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${sw ? 'Ina' : 'Contains'}: ${allergens.join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (allergens.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 18, color: _kPrimary),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTipCard(_PickyTip tip, bool sw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, size: 20, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sw ? tip.sw : tip.en,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyCard(_AllergyInfo info, bool sw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded, size: 20, color: _kSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? info.nameSw : info.nameEn,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sw ? info.descSw : info.descEn,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Meal Plan Tab ──────────────────────────────────────────

  Widget _buildMealPlanTab(bool sw) {
    if (!_mealPlanLoaded) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    final days = sw
        ? ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili']
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final mealTypes = [
      _MealType('breakfast', sw ? 'Kifungua Kinywa' : 'Breakfast', Icons.wb_sunny_rounded),
      _MealType('lunch', sw ? 'Mchana' : 'Lunch', Icons.restaurant_rounded),
      _MealType('dinner', sw ? 'Jioni' : 'Dinner', Icons.nightlight_rounded),
      _MealType('snacks', sw ? 'Vitafunio' : 'Snacks', Icons.cookie_rounded),
    ];

    return Column(
      children: [
        // Save button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saveMealPlan,
              icon: const Icon(Icons.save_rounded, size: 20),
              label: Text(
                sw ? 'Hifadhi Mpango' : 'Save Plan',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7,
            itemBuilder: (ctx, dayIdx) {
              final dayMeals = _mealPlan[dayIdx] ?? {};
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kTertiary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                      ),
                      child: Text(
                        days[dayIdx],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    // Meal rows
                    ...mealTypes.map((mt) {
                      final value = dayMeals[mt.key] ?? '';
                      return InkWell(
                        onTap: () => _showMealPicker(dayIdx, mt.key, sw),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(mt.icon, size: 18, color: _kSecondary),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  mt.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  value.isEmpty
                                      ? (sw ? 'Gusa kuchagua' : 'Tap to set')
                                      : value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        value.isEmpty ? _kTertiary : _kPrimary,
                                    fontWeight: value.isEmpty
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 18, color: _kTertiary),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMealPicker(int dayIdx, String mealType, bool sw) {
    final suggestions = _suggestionsForMealType(mealType);
    final customCtrl = TextEditingController(
      text: _mealPlan[dayIdx]?[mealType] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Chagua Mlo' : 'Choose Meal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Custom input
                TextField(
                  controller: customCtrl,
                  decoration: InputDecoration(
                    labelText: sw ? 'Andika mlo' : 'Type a meal',
                    labelStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _kTertiary.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _kTertiary.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  sw ? 'Au chagua:' : 'Or choose:',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(height: 8),
                // Suggestion chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: suggestions.map((meal) {
                    final allergens = _matchAllergens(meal);
                    final hasAllergen = allergens.isNotEmpty;
                    return InkWell(
                      onTap: () {
                        customCtrl.text = sw ? meal.sw : meal.en;
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: hasAllergen
                              ? _kPrimary.withValues(alpha: 0.08)
                              : _kPrimary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: hasAllergen
                              ? Border.all(color: _kPrimary.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasAllergen) ...[
                              const Icon(Icons.warning_rounded,
                                  size: 14, color: _kPrimary),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              sw ? meal.sw : meal.en,
                              style: const TextStyle(
                                  fontSize: 13, color: _kPrimary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final val = customCtrl.text.trim();
                      Navigator.pop(ctx);
                      if (val.isNotEmpty) {
                        setState(() {
                          _mealPlan[dayIdx] ??= {};
                          _mealPlan[dayIdx]![mealType] = val;
                        });
                      }
                    },
                    child: Text(
                      sw ? 'Weka' : 'Set',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => customCtrl.dispose());
  }

  List<_Meal> _suggestionsForMealType(String type) {
    switch (type) {
      case 'breakfast':
        return _breakfastMeals;
      case 'lunch':
        return _lunchMeals;
      case 'dinner':
        return _dinnerMeals;
      case 'snacks':
        return _snackMeals;
      default:
        return _breakfastMeals;
    }
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}

// ─── Data Classes ──────────────────────────────────────────────

class _Meal {
  final String sw;
  final String en;
  const _Meal(this.sw, this.en);
}

class _MealType {
  final String key;
  final String label;
  final IconData icon;
  const _MealType(this.key, this.label, this.icon);
}

class _PickyTip {
  final String en;
  final String sw;
  const _PickyTip(this.en, this.sw);
}

class _AllergyInfo {
  final String nameEn;
  final String nameSw;
  final String descEn;
  final String descSw;
  const _AllergyInfo(this.nameEn, this.nameSw, this.descEn, this.descSw);
}

// ─── Static Data ──────────────────────────────────────────────

const _breakfastMeals = [
  _Meal('Uji wa wimbi', 'Millet porridge'),
  _Meal('Mayai na mkate', 'Eggs and bread'),
  _Meal('Ndizi na maziwa', 'Banana and milk'),
];

const _lunchMeals = [
  _Meal('Wali na maharage', 'Rice and beans'),
  _Meal('Ugali na mboga', 'Ugali and vegetables'),
  _Meal('Viazi na samaki', 'Potatoes and fish'),
];

const _dinnerMeals = [
  _Meal('Supu ya mboga', 'Vegetable soup'),
  _Meal('Ugali na nyama', 'Ugali and meat'),
  _Meal('Ndizi za kupika', 'Cooked bananas'),
];

const _snackMeals = [
  _Meal('Matunda', 'Fruits'),
  _Meal('Karanga', 'Peanuts'),
  _Meal('Maziwa', 'Milk'),
];

const _pickyEaterTips = [
  _PickyTip(
    'Offer new foods alongside familiar ones - don\'t force',
    'Toa vyakula vipya pamoja na vinavyofahamika - usilazimishe',
  ),
  _PickyTip(
    'Let children help prepare meals - they eat what they make',
    'Waache watoto wasaidie kupika - wanakula walichotengeneza',
  ),
  _PickyTip(
    'Be patient: children may need 10-15 tries before accepting new food',
    'Kuwa na subira: watoto wanaweza kuhitaji majaribio 10-15 kabla ya kukubali chakula kipya',
  ),
  _PickyTip(
    'Avoid using sweets as rewards for eating',
    'Epuka kutumia pipi kama zawadi ya kula',
  ),
  _PickyTip(
    'Eat together as a family - children copy adults',
    'Kuleni pamoja kama familia - watoto wanaiga watu wazima',
  ),
];

const _allergyCards = [
  _AllergyInfo(
    'Milk/Dairy', 'Maziwa',
    'Rashes, stomach pain, vomiting after dairy',
    'Vipele, maumivu ya tumbo, kutapika baada ya maziwa',
  ),
  _AllergyInfo(
    'Eggs', 'Mayai',
    'Hives, swelling around mouth after eggs',
    'Upele, kuvimba karibu na mdomo baada ya mayai',
  ),
  _AllergyInfo(
    'Peanuts/Tree Nuts', 'Karanga',
    'Severe reactions possible - watch for swelling, breathing difficulty',
    'Athari kali zinawezekana - angalia kuvimba, ugumu wa kupumua',
  ),
  _AllergyInfo(
    'Wheat/Gluten', 'Ngano',
    'Bloating, diarrhea, rash after wheat products',
    'Kuvimba tumbo, kuharisha, vipele baada ya bidhaa za ngano',
  ),
  _AllergyInfo(
    'Fish/Shellfish', 'Samaki/Dagaa',
    'Hives, vomiting, breathing issues after fish',
    'Upele, kutapika, matatizo ya kupumua baada ya samaki',
  ),
];

/// Map common allergen names to food keywords for cross-referencing.
const Map<String, List<String>> _allergenFoodMap = {
  'milk': ['milk', 'maziwa', 'dairy', 'cheese', 'yogurt'],
  'maziwa': ['milk', 'maziwa', 'dairy', 'porridge', 'uji'],
  'eggs': ['eggs', 'mayai', 'egg'],
  'mayai': ['eggs', 'mayai', 'egg'],
  'peanuts': ['peanuts', 'karanga', 'nuts', 'nut'],
  'karanga': ['peanuts', 'karanga', 'nuts', 'nut'],
  'wheat': ['wheat', 'bread', 'mkate', 'ugali', 'gluten', 'ngano'],
  'ngano': ['wheat', 'bread', 'mkate', 'gluten', 'ngano'],
  'fish': ['fish', 'samaki', 'dagaa', 'shellfish'],
  'samaki': ['fish', 'samaki', 'dagaa', 'shellfish'],
  'gluten': ['wheat', 'bread', 'mkate', 'ugali', 'gluten'],
  'soy': ['soy', 'soya'],
};
