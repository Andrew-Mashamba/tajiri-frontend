// lib/my_children/pages/safety_awareness_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SafetyAwarenessPage extends StatelessWidget {
  final Child child;

  const SafetyAwarenessPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;

    final categories = _buildCategories();

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Usalama' : 'Safety',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...categories.map((cat) => _SafetyCategorySection(category: cat, sw: sw)),

            // ─── Cross-module links ──────────────
            const SizedBox(height: 20),
            Text(
              sw ? 'Viunganishi' : 'Related',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildCrossModuleLink(
              context: context,
              icon: Icons.shopping_bag_rounded,
              label: sw
                  ? 'Nunua vifaa vya usalama wa nyumbani'
                  : 'Shop childproofing supplies',
              onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
            ),
            _buildCrossModuleLink(
              context: context,
              icon: Icons.chat_rounded,
              label: sw
                  ? 'Uliza Shangazi kuhusu sheria za usalama'
                  : 'Ask Shangazi about safety rules',
              onTap: () => Navigator.pushNamed(context, '/chat/0'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossModuleLink({
    required BuildContext context,
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
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  List<_SafetyCategory> _buildCategories() {
    return [
      _SafetyCategory(
        icon: Icons.water_rounded,
        titleEn: 'Water Safety',
        titleSw: 'Usalama wa Maji',
        tips: [
          _SafetyTip(
            titleEn: 'Never leave child alone near water',
            titleSw: 'Usimwache mtoto peke yake karibu na maji',
            descEn: 'Always supervise children near pools, buckets, bathtubs, and rivers',
            descSw: 'Daima simamia watoto karibu na mabwawa, ndoo, bafu, na mito',
            ageRange: '0-12',
          ),
          _SafetyTip(
            titleEn: 'Teach basic swimming early',
            titleSw: 'Fundisha kuogelea mapema',
            descEn: 'Children can start basic water safety lessons from age 4',
            descSw: 'Watoto wanaweza kuanza masomo ya usalama wa maji kuanzia umri wa miaka 4',
            ageRange: '4-12',
          ),
          _SafetyTip(
            titleEn: 'Cover water containers',
            titleSw: 'Funika vyombo vya maji',
            descEn: 'Keep all water containers, wells, and tanks covered',
            descSw: 'Weka mifuniko kwenye vyombo vyote vya maji, visima, na matanki',
            ageRange: '0-5',
          ),
        ],
      ),
      _SafetyCategory(
        icon: Icons.directions_car_rounded,
        titleEn: 'Road Safety',
        titleSw: 'Usalama wa Barabarani',
        tips: [
          _SafetyTip(
            titleEn: 'Hold hand when crossing',
            titleSw: 'Shika mkono unapovuka barabara',
            descEn: 'Always hold a child\'s hand when crossing the road',
            descSw: 'Daima shika mkono wa mtoto unapovuka barabara',
            ageRange: '0-10',
          ),
          _SafetyTip(
            titleEn: 'Teach look left, right, left',
            titleSw: 'Fundisha kutazama kushoto, kulia, kushoto',
            descEn: 'Children should learn to look both ways before crossing',
            descSw: 'Watoto wajifunze kutazama pande zote kabla ya kuvuka',
            ageRange: '5-12',
          ),
          _SafetyTip(
            titleEn: 'Wear bright colors near roads',
            titleSw: 'Vaa rangi zinazoonekana karibu na barabara',
            descEn: 'Bright clothing helps drivers see children better',
            descSw: 'Nguo za rangi husaidia madereva kuwaona watoto vizuri',
            ageRange: '0-12',
          ),
        ],
      ),
      _SafetyCategory(
        icon: Icons.home_rounded,
        titleEn: 'Home Hazards',
        titleSw: 'Hatari Nyumbani',
        tips: [
          _SafetyTip(
            titleEn: 'Lock medicines, cover sockets',
            titleSw: 'Funga dawa, funika soketi',
            descEn: 'Keep medicines in locked cabinets and cover electrical outlets',
            descSw: 'Weka dawa kwenye kabati zilizofungwa na funika soketi za umeme',
            ageRange: '0-5',
          ),
          _SafetyTip(
            titleEn: 'Keep sharp objects out of reach',
            titleSw: 'Weka vitu vikali mbali na watoto',
            descEn: 'Knives, scissors, and tools should be stored safely',
            descSw: 'Visu, mikasi, na zana zinapaswa kuhifadhiwa kwa usalama',
            ageRange: '0-8',
          ),
          _SafetyTip(
            titleEn: 'Secure heavy furniture to walls',
            titleSw: 'Funga fanicha nzito kwenye kuta',
            descEn: 'Bookshelves and TV stands can tip over on children',
            descSw: 'Rafu za vitabu na stendi za TV zinaweza kuanguka juu ya watoto',
            ageRange: '0-5',
          ),
        ],
      ),
      _SafetyCategory(
        icon: Icons.local_fire_department_rounded,
        titleEn: 'Fire Safety',
        titleSw: 'Usalama wa Moto',
        tips: [
          _SafetyTip(
            titleEn: 'Keep matches away',
            titleSw: 'Weka vibiriti mbali na watoto',
            descEn: 'Store matches, lighters, and candles away from children',
            descSw: 'Hifadhi vibiriti, vibatilishi, na mishumaa mbali na watoto',
            ageRange: '0-12',
          ),
          _SafetyTip(
            titleEn: 'Teach stop, drop, and roll',
            titleSw: 'Fundisha simama, lala chini, na viringika',
            descEn: 'If clothes catch fire: stop, drop to the ground, and roll',
            descSw: 'Nguo zikiungua: simama, lala chini, na viringika',
            ageRange: '3-12',
          ),
          _SafetyTip(
            titleEn: 'Practice escape routes',
            titleSw: 'Fanya mazoezi ya njia za kutoroka',
            descEn: 'Family should know two ways out of every room',
            descSw: 'Familia inapaswa kujua njia mbili za kutoka kila chumba',
            ageRange: '5-18',
          ),
        ],
      ),
      _SafetyCategory(
        icon: Icons.person_off_rounded,
        titleEn: 'Stranger Danger',
        titleSw: 'Hatari ya Wageni',
        tips: [
          _SafetyTip(
            titleEn: 'Teach "no" to strangers',
            titleSw: 'Fundisha kusema "hapana" kwa wageni',
            descEn: 'Children should know they can say no to any adult who makes them uncomfortable',
            descSw: 'Watoto wajue wanaweza kusema hapana kwa mtu yeyote anayewafanya wasijisikie vizuri',
            ageRange: '3-12',
          ),
          _SafetyTip(
            titleEn: 'Never go with strangers',
            titleSw: 'Usiende na wageni kamwe',
            descEn: 'Teach children never to go anywhere with someone they don\'t know',
            descSw: 'Fundisha watoto wasiende popote na mtu wasiyemjua',
            ageRange: '3-18',
          ),
          _SafetyTip(
            titleEn: 'Know your safe adults',
            titleSw: 'Jua watu wazima wako salama',
            descEn: 'Identify 3-5 trusted adults the child can go to for help',
            descSw: 'Tambua watu wazima 3-5 wa kuamini ambao mtoto anaweza kwenda kwao kwa msaada',
            ageRange: '3-18',
          ),
        ],
      ),
      _SafetyCategory(
        icon: Icons.pest_control_rounded,
        titleEn: 'Poison Prevention',
        titleSw: 'Kuzuia Sumu',
        tips: [
          _SafetyTip(
            titleEn: 'Store chemicals safely',
            titleSw: 'Hifadhi kemikali kwa usalama',
            descEn: 'Cleaning products, pesticides must be locked away',
            descSw: 'Bidhaa za kusafisha, dawa za wadudu lazima zifungwe',
            ageRange: '0-8',
          ),
          _SafetyTip(
            titleEn: 'Keep medicines in original containers',
            titleSw: 'Weka dawa kwenye vyombo vyake vya asili',
            descEn: 'Never put chemicals in food containers - children may drink them',
            descSw: 'Usiweke kemikali kwenye vyombo vya chakula - watoto wanaweza kunywa',
            ageRange: '0-12',
          ),
        ],
      ),
    ];
  }
}

class _SafetyCategorySection extends StatelessWidget {
  final _SafetyCategory category;
  final bool sw;

  const _SafetyCategorySection({
    required this.category,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, size: 20, color: _kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw ? category.titleSw : category.titleEn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Tips
        ...category.tips.map((tip) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_rounded, size: 20, color: _kPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? tip.titleSw : tip.titleEn,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sw ? tip.descSw : tip.descEn,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sw ? "Umri" : "Age"}: ${tip.ageRange} ${sw ? "miaka" : "years"}',
                            style: const TextStyle(fontSize: 10, color: _kSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SafetyCategory {
  final IconData icon;
  final String titleEn;
  final String titleSw;
  final List<_SafetyTip> tips;

  const _SafetyCategory({
    required this.icon,
    required this.titleEn,
    required this.titleSw,
    required this.tips,
  });
}

class _SafetyTip {
  final String titleEn;
  final String titleSw;
  final String descEn;
  final String descSw;
  final String ageRange;

  const _SafetyTip({
    required this.titleEn,
    required this.titleSw,
    required this.descEn,
    required this.descSw,
    required this.ageRange,
  });
}
