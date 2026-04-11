// lib/my_pregnancy/pages/nutrition_guide_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class NutritionGuidePage extends StatefulWidget {
  const NutritionGuidePage({super.key});

  @override
  State<NutritionGuidePage> createState() => _NutritionGuidePageState();
}

class _NutritionGuidePageState extends State<NutritionGuidePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili == true;

  // ─── Food Data (Tanzania-specific) ─────────────────────────

  static final _safeFoods = [
    {
      'name_en': 'Ugali (Maize Porridge)',
      'name_sw': 'Ugali',
      'desc_en': 'Good source of carbohydrates and energy. Staple food safe throughout pregnancy.',
      'desc_sw': 'Chanzo kizuri cha wanga na nishati. Chakula salama wakati wote wa ujauzito.',
      'nutrients': 'Carbohydrates, Energy',
      'icon': Icons.rice_bowl_rounded,
    },
    {
      'name_en': 'Beans (Maharage)',
      'name_sw': 'Maharage',
      'desc_en': 'Excellent source of protein, iron, and folic acid. Essential for baby development.',
      'desc_sw': 'Chanzo bora cha protini, chuma, na folic acid. Muhimu kwa ukuaji wa mtoto.',
      'nutrients': 'Protein, Iron, Folic Acid',
      'icon': Icons.eco_rounded,
    },
    {
      'name_en': 'Spinach (Mchicha)',
      'name_sw': 'Mchicha',
      'desc_en': 'Rich in iron, folic acid, and vitamins A and C. Helps prevent anemia.',
      'desc_sw': 'Ina chuma, folic acid, na vitamini A na C. Husaidia kuzuia upungufu wa damu.',
      'nutrients': 'Iron, Folic Acid, Vitamin A, C',
      'icon': Icons.local_florist_rounded,
    },
    {
      'name_en': 'Sweet Potatoes (Viazi Vitamu)',
      'name_sw': 'Viazi Vitamu',
      'desc_en': 'High in beta-carotene (Vitamin A), fiber, and energy. Orange-fleshed varieties are best.',
      'desc_sw': 'Ina beta-carotene (Vitamini A), nyuzi, na nishati. Aina za njano ndani ni bora zaidi.',
      'nutrients': 'Vitamin A, Fiber, Energy',
      'icon': Icons.spa_rounded,
    },
    {
      'name_en': 'Bananas (Ndizi)',
      'name_sw': 'Ndizi',
      'desc_en': 'Rich in potassium, helps with leg cramps and blood pressure. Easy to digest.',
      'desc_sw': 'Ina potasiamu, husaidia maumivu ya miguu na shinikizo la damu. Rahisi kuyeyushwa.',
      'nutrients': 'Potassium, Vitamin B6, Fiber',
      'icon': Icons.lunch_dining_rounded,
    },
    {
      'name_en': 'Fish (Samaki)',
      'name_sw': 'Samaki (wadogo)',
      'desc_en': 'Small fish like dagaa/sardines are rich in calcium, protein, and omega-3.',
      'desc_sw': 'Samaki wadogo kama dagaa wana kalsiamu, protini, na omega-3 kwa wingi.',
      'nutrients': 'Calcium, Protein, Omega-3',
      'icon': Icons.set_meal_rounded,
    },
    {
      'name_en': 'Eggs (Mayai)',
      'name_sw': 'Mayai (yaliyopikwa)',
      'desc_en': 'Complete protein source with choline for baby brain development. Always cook thoroughly.',
      'desc_sw': 'Chanzo kamili cha protini na choline kwa ubongo wa mtoto. Pika vizuri.',
      'nutrients': 'Protein, Choline, Iron',
      'icon': Icons.egg_rounded,
    },
    {
      'name_en': 'Milk & Yogurt (Maziwa)',
      'name_sw': 'Maziwa na Mtindi',
      'desc_en': 'Calcium and protein for strong bones. Pasteurized milk is safe.',
      'desc_sw': 'Kalsiamu na protini kwa mifupa imara. Maziwa yaliyochemshwa ni salama.',
      'nutrients': 'Calcium, Protein, Vitamin D',
      'icon': Icons.local_drink_rounded,
    },
    {
      'name_en': 'Pumpkin (Boga)',
      'name_sw': 'Boga',
      'desc_en': 'Rich in Vitamin A, iron, and fiber. Good for eye health and digestion.',
      'desc_sw': 'Ina Vitamini A, chuma, na nyuzi. Nzuri kwa macho na usagaji.',
      'nutrients': 'Vitamin A, Iron, Fiber',
      'icon': Icons.local_dining_rounded,
    },
    {
      'name_en': 'Groundnuts (Karanga)',
      'name_sw': 'Karanga',
      'desc_en': 'Good source of healthy fats, protein, and energy. Eat in moderation.',
      'desc_sw': 'Chanzo kizuri cha mafuta mazuri, protini, na nishati. Kula kwa kiasi.',
      'nutrients': 'Protein, Healthy Fats, Energy',
      'icon': Icons.grain_rounded,
    },
  ];

  static final _unsafeFoods = [
    {
      'name_en': 'Raw Meat (Nyama Mbichi)',
      'name_sw': 'Nyama Mbichi',
      'desc_en': 'Risk of toxoplasmosis and salmonella infection. Always cook meat thoroughly.',
      'desc_sw': 'Hatari ya toxoplasmosis na salmonella. Pika nyama vizuri kabisa.',
      'nutrients': 'RISK: Toxoplasmosis, Salmonella',
      'icon': Icons.dangerous_rounded,
    },
    {
      'name_en': 'Raw Eggs (Mayai Mabichi)',
      'name_sw': 'Mayai Mabichi',
      'desc_en': 'Risk of salmonella. Avoid raw or undercooked eggs and foods containing them.',
      'desc_sw': 'Hatari ya salmonella. Epuka mayai mabichi au ambayo hayajapikwa vizuri.',
      'nutrients': 'RISK: Salmonella',
      'icon': Icons.dangerous_rounded,
    },
    {
      'name_en': 'Alcohol (Pombe)',
      'name_sw': 'Pombe',
      'desc_en': 'No safe amount during pregnancy. Can cause fetal alcohol syndrome and birth defects.',
      'desc_sw': 'Hakuna kiasi salama wakati wa ujauzito. Inaweza kusababisha kasoro za kuzaliwa.',
      'nutrients': 'RISK: Fetal Alcohol Syndrome',
      'icon': Icons.no_drinks_rounded,
    },
    {
      'name_en': 'Unpasteurized Milk',
      'name_sw': 'Maziwa Yasiyochemshwa',
      'desc_en': 'May contain listeria and other harmful bacteria. Always boil or use pasteurized.',
      'desc_sw': 'Yanaweza kuwa na listeria na bakteria hatari. Chemsha maziwa kila wakati.',
      'nutrients': 'RISK: Listeria',
      'icon': Icons.dangerous_rounded,
    },
    {
      'name_en': 'Raw Cassava (Muhogo Mbichi)',
      'name_sw': 'Muhogo Mbichi',
      'desc_en': 'Contains cyanide compounds when raw. Must be thoroughly cooked or fermented.',
      'desc_sw': 'Una sumu ya cyanide ukiwa mbichi. Lazima upikwe vizuri au uchachiwe.',
      'nutrients': 'RISK: Cyanide',
      'icon': Icons.dangerous_rounded,
    },
    {
      'name_en': 'Certain Herbs (Mitishamba)',
      'name_sw': 'Mitishamba Fulani',
      'desc_en': 'Some traditional herbs can cause contractions or harm the baby. Consult doctor first.',
      'desc_sw': 'Mitishamba mingine inaweza kusababisha uchungu au kumdhuru mtoto. Uliza daktari kwanza.',
      'nutrients': 'RISK: Contractions, Toxicity',
      'icon': Icons.warning_rounded,
    },
  ];

  static final _cautionFoods = [
    {
      'name_en': 'Large Fish (Samaki Wakubwa)',
      'name_sw': 'Samaki Wakubwa',
      'desc_en': 'May contain high mercury levels. Limit large fish like swordfish and king mackerel.',
      'desc_sw': 'Wanaweza kuwa na zebaki nyingi. Punguza samaki wakubwa kama upanga na mackerel.',
      'nutrients': 'CAUTION: Mercury',
      'icon': Icons.warning_amber_rounded,
    },
    {
      'name_en': 'Caffeine (Kahawa/Chai)',
      'name_sw': 'Kahawa na Chai',
      'desc_en': 'Limit to 200mg/day (about 1-2 cups). Excess caffeine may affect baby growth.',
      'desc_sw': 'Punguza hadi 200mg/siku (vikombe 1-2). Kahawa nyingi inaweza kuathiri ukuaji wa mtoto.',
      'nutrients': 'LIMIT: 200mg/day',
      'icon': Icons.coffee_rounded,
    },
    {
      'name_en': 'Spicy Foods (Pilipili)',
      'name_sw': 'Vyakula vya Pilipili',
      'desc_en': 'Safe but may worsen heartburn and nausea, especially in third trimester.',
      'desc_sw': 'Salama lakini vinaweza kuongeza kiungulia na kichefuchefu, hasa trimesta ya tatu.',
      'nutrients': 'May cause heartburn',
      'icon': Icons.whatshot_rounded,
    },
    {
      'name_en': 'Street Food (Chipsi Mayai)',
      'name_sw': 'Vyakula vya Mitaani',
      'desc_en': 'Risk of contamination if not freshly prepared. Choose clean vendors and hot food.',
      'desc_sw': 'Hatari ya uchafuzi kama havijapikwa sasa. Chagua wauza safi na chakula cha moto.',
      'nutrients': 'Risk if not fresh',
      'icon': Icons.storefront_rounded,
    },
    {
      'name_en': 'Pineapple (Nanasi)',
      'name_sw': 'Nanasi',
      'desc_en': 'Safe in moderate amounts. Large quantities may cause heartburn. No evidence it causes miscarriage.',
      'desc_sw': 'Salama kwa kiasi. Nyingi inaweza kusababisha kiungulia. Hakuna ushahidi inasababisha mimba kutoka.',
      'nutrients': 'Vitamin C, Fiber',
      'icon': Icons.lunch_dining_rounded,
    },
  ];

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Mwongozo wa Lishe' : 'Nutrition Guide',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kTertiary,
          indicatorColor: _kPrimary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: sw ? 'Salama' : 'Safe'),
            Tab(text: sw ? 'Hatari' : 'Unsafe'),
            Tab(text: sw ? 'Tahadhari' : 'Caution'),
            Tab(text: sw ? 'Milo' : 'Meals'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFoodList(sw, _safeFoods, _FoodCategory.safe),
            _buildFoodList(sw, _unsafeFoods, _FoodCategory.unsafe),
            _buildFoodList(sw, _cautionFoods, _FoodCategory.caution),
            _buildMealSuggestions(sw),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodList(
      bool sw, List<Map<String, dynamic>> foods, _FoodCategory category) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Hydration card
        _buildHydrationCard(sw),
        const SizedBox(height: 12),

        // Nutrient summary
        _buildNutrientCard(sw),
        const SizedBox(height: 16),

        // Category header
        Text(
          _categoryTitle(sw, category),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 10),

        // Food cards
        ...foods.map((food) => _FoodCard(
              food: food,
              isSwahili: sw,
              category: category,
            )),
        const SizedBox(height: 32),
      ],
    );
  }

  String _categoryTitle(bool sw, _FoodCategory category) {
    switch (category) {
      case _FoodCategory.safe:
        return sw ? 'Vyakula Salama' : 'Safe Foods';
      case _FoodCategory.unsafe:
        return sw ? 'Vyakula vya Hatari' : 'Unsafe Foods';
      case _FoodCategory.caution:
        return sw ? 'Vyakula vya Tahadhari' : 'Foods with Caution';
    }
  }

  Widget _buildHydrationCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop_rounded,
                size: 22, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Kunywa Maji' : 'Stay Hydrated',
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
                  sw
                      ? 'Kunywa glasi 8 za maji kwa siku (lita 2-3).'
                      : 'Drink 8 glasses of water daily (2-3 liters).',
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

  // ─── Meal Suggestions by Trimester ──────────────────────────

  static final _firstTrimesterMeals = [
    {
      'name_sw': 'Uji wa wimbi na maziwa',
      'name_en': 'Millet porridge with milk',
      'desc_sw': 'Rahisi kuyeyushwa, husaidia kichefuchefu. Ina chuma na kalsiamu.',
      'desc_en': 'Easy to digest, helps with nausea. Rich in iron and calcium.',
    },
    {
      'name_sw': 'Ndizi na karanga',
      'name_en': 'Banana with peanuts',
      'desc_sw': 'Nishati ya haraka na protini. Nzuri kwa asubuhi.',
      'desc_en': 'Quick energy and protein. Great for mornings.',
    },
    {
      'name_sw': 'Supu ya kuku na mboga',
      'name_en': 'Chicken soup with vegetables',
      'desc_sw': 'Nyepesi tumboni na yenye protini. Husaidia kichefuchefu.',
      'desc_en': 'Light on the stomach with protein. Helps with nausea.',
    },
    {
      'name_sw': 'Viazi vitamu vya kuchemsha',
      'name_en': 'Boiled sweet potatoes',
      'desc_sw': 'Ina Vitamini A nyingi na wanga rahisi. Nzuri kwa trimesta ya kwanza.',
      'desc_en': 'High in Vitamin A and easy carbs. Great for first trimester.',
    },
    {
      'name_sw': 'Maziwa na biskuti',
      'name_en': 'Milk and crackers',
      'desc_sw': 'Husaidia kichefuchefu na kutoa kalsiamu.',
      'desc_en': 'Helps with nausea and provides calcium.',
    },
    {
      'name_sw': 'Matunda mchanganyiko (papai, embe, chungwa)',
      'name_en': 'Mixed fruits (papaya, mango, orange)',
      'desc_sw': 'Vitamini C na folic acid kwa ukuaji wa mtoto.',
      'desc_en': 'Vitamin C and folic acid for baby development.',
    },
  ];

  static final _secondTrimesterMeals = [
    {
      'name_sw': 'Maharage na mchicha na ugali',
      'name_en': 'Beans, spinach and ugali',
      'desc_sw': 'Protini, chuma, na nishati. Husaidia kuzuia upungufu wa damu.',
      'desc_en': 'Protein, iron, and energy. Helps prevent anemia.',
    },
    {
      'name_sw': 'Dagaa na mboga za majani',
      'name_en': 'Dried fish with green vegetables',
      'desc_sw': 'Kalsiamu na protini kwa mifupa imara ya mtoto.',
      'desc_en': 'Calcium and protein for strong baby bones.',
    },
    {
      'name_sw': 'Wali na mchuzi wa nyama na mchicha',
      'name_en': 'Rice with meat and spinach stew',
      'desc_sw': 'Mchanganyiko bora wa chuma, protini, na nishati.',
      'desc_en': 'Great combination of iron, protein, and energy.',
    },
    {
      'name_sw': 'Mayai ya kuchemsha na mkate',
      'name_en': 'Boiled eggs with bread',
      'desc_sw': 'Protini kamili na choline kwa ubongo wa mtoto.',
      'desc_en': 'Complete protein and choline for baby brain.',
    },
    {
      'name_sw': 'Pilau na kachumbari',
      'name_en': 'Pilau with kachumbari salad',
      'desc_sw': 'Nishati na vitamini kutoka mboga mbichi.',
      'desc_en': 'Energy and vitamins from fresh vegetables.',
    },
    {
      'name_sw': 'Mtindi na matunda',
      'name_en': 'Yogurt with fruits',
      'desc_sw': 'Kalsiamu, probiotics, na vitamini. Nzuri kwa usagaji.',
      'desc_en': 'Calcium, probiotics, and vitamins. Good for digestion.',
    },
    {
      'name_sw': 'Boga la kuchemsha na karanga',
      'name_en': 'Boiled pumpkin with groundnuts',
      'desc_sw': 'Vitamini A na mafuta mazuri kwa ukuaji wa macho ya mtoto.',
      'desc_en': 'Vitamin A and healthy fats for baby eye development.',
    },
  ];

  static final _thirdTrimesterMeals = [
    {
      'name_sw': 'Samaki wa kukaanga na wali',
      'name_en': 'Fried fish with rice',
      'desc_sw': 'Omega-3 na protini kwa ukuaji wa ubongo wa mtoto.',
      'desc_en': 'Omega-3 and protein for baby brain development.',
    },
    {
      'name_sw': 'Maziwa na matunda',
      'name_en': 'Milk and fruits',
      'desc_sw': 'Kalsiamu kwa mifupa na nishati ya kujifungua.',
      'desc_en': 'Calcium for bones and energy for delivery.',
    },
    {
      'name_sw': 'Ugali na maharage na mboga',
      'name_en': 'Ugali with beans and vegetables',
      'desc_sw': 'Nishati kubwa, protini, na vitamini kwa maandalizi ya kuzaa.',
      'desc_en': 'High energy, protein, and vitamins to prepare for delivery.',
    },
    {
      'name_sw': 'Supu ya mifupa na mboga',
      'name_en': 'Bone soup with vegetables',
      'desc_sw': 'Kalsiamu na madini kwa mama na mtoto.',
      'desc_en': 'Calcium and minerals for mother and baby.',
    },
    {
      'name_sw': 'Ndizi za kupika na nyama',
      'name_en': 'Cooking bananas with meat',
      'desc_sw': 'Nishati na protini. Nzuri kwa wiki za mwisho.',
      'desc_en': 'Energy and protein. Great for the final weeks.',
    },
    {
      'name_sw': 'Tambi na maziwa',
      'name_en': 'Vermicelli with milk',
      'desc_sw': 'Kalsiamu na wanga. Rahisi kupika na kula.',
      'desc_en': 'Calcium and carbs. Easy to prepare and eat.',
    },
    {
      'name_sw': 'Tende na karanga',
      'name_en': 'Dates and peanuts',
      'desc_sw': 'Nishati ya haraka na chuma. Husaidia maandalizi ya uchungu.',
      'desc_en': 'Quick energy and iron. Helps prepare for labor.',
    },
    {
      'name_sw': 'Kitimoto na wali wa nazi',
      'name_en': 'Lamb stew with coconut rice',
      'desc_sw': 'Protini na chuma kwa nguvu ya kujifungua.',
      'desc_en': 'Protein and iron for delivery strength.',
    },
  ];

  Widget _buildMealSuggestions(bool sw) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // First trimester
        _buildTrimesterMeals(
          sw,
          trimester: 1,
          title: sw ? 'Trimesta ya Kwanza (Wiki 1-13)' : 'First Trimester (Weeks 1-13)',
          subtitle: sw
              ? 'Milo nyepesi — husaidia kichefuchefu'
              : 'Light meals — helps with nausea',
          meals: _firstTrimesterMeals,
        ),
        const SizedBox(height: 20),
        // Second trimester
        _buildTrimesterMeals(
          sw,
          trimester: 2,
          title: sw ? 'Trimesta ya Pili (Wiki 14-27)' : 'Second Trimester (Weeks 14-27)',
          subtitle: sw
              ? 'Milo yenye chuma na protini — kwa ukuaji wa mtoto'
              : 'Iron & protein-rich meals — for baby growth',
          meals: _secondTrimesterMeals,
        ),
        const SizedBox(height: 20),
        // Third trimester
        _buildTrimesterMeals(
          sw,
          trimester: 3,
          title: sw ? 'Trimesta ya Tatu (Wiki 28-40)' : 'Third Trimester (Weeks 28-40)',
          subtitle: sw
              ? 'Milo yenye nishati na kalsiamu — maandalizi ya kuzaa'
              : 'Energy & calcium meals — preparing for delivery',
          meals: _thirdTrimesterMeals,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTrimesterMeals(
    bool sw, {
    required int trimester,
    required String title,
    required String subtitle,
    required List<Map<String, String>> meals,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: _kSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        ...meals.map((meal) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kPrimary.withValues(alpha: 0.08),
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        size: 20, color: _kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? meal['name_sw']! : meal['name_en']!,
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
                          sw ? meal['desc_sw']! : meal['desc_en']!,
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildNutrientCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Virutubishi vya Kila Siku' : 'Daily Nutrient Needs',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          _NutrientRow(
            label: sw ? 'Chuma (Iron)' : 'Iron',
            value: '27mg',
            description: sw
                ? 'Kuzuia upungufu wa damu'
                : 'Prevents anemia',
          ),
          const SizedBox(height: 6),
          _NutrientRow(
            label: sw ? 'Folic Acid' : 'Folic Acid',
            value: '600mcg',
            description: sw
                ? 'Ukuaji wa ubongo wa mtoto'
                : 'Baby brain development',
          ),
          const SizedBox(height: 6),
          _NutrientRow(
            label: sw ? 'Kalsiamu (Calcium)' : 'Calcium',
            value: '1000mg',
            description: sw
                ? 'Mifupa imara ya mama na mtoto'
                : 'Strong bones for mother and baby',
          ),
        ],
      ),
    );
  }
}

// ─── Food card ────────────────────────────────────────────────

class _FoodCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final bool isSwahili;
  final _FoodCategory category;

  const _FoodCard({
    required this.food,
    required this.isSwahili,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        isSwahili ? food['name_sw'] as String : food['name_en'] as String;
    final desc =
        isSwahili ? food['desc_sw'] as String : food['desc_en'] as String;
    final nutrients = food['nutrients'] as String;
    final icon = food['icon'] as IconData;

    Color accentColor;
    switch (category) {
      case _FoodCategory.safe:
        accentColor = _kPrimary;
        break;
      case _FoodCategory.unsafe:
        accentColor = const Color(0xFF666666);
        break;
      case _FoodCategory.caution:
        accentColor = const Color(0xFF666666);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: category == _FoodCategory.unsafe
            ? Border.all(color: Colors.grey.shade300)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
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
                  desc,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  nutrients,
                  style: TextStyle(
                    fontSize: 11,
                    color: category == _FoodCategory.unsafe
                        ? _kSecondary
                        : _kTertiary,
                    fontWeight: category == _FoodCategory.unsafe
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nutrient row ─────────────────────────────────────────────

class _NutrientRow extends StatelessWidget {
  final String label;
  final String value;
  final String description;

  const _NutrientRow({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(fontSize: 11, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Internal types ───────────────────────────────────────────

enum _FoodCategory { safe, unsafe, caution }
