// lib/my_children/pages/digital_safety_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class DigitalSafetyPage extends StatelessWidget {
  final Child child;

  const DigitalSafetyPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Usalama wa Mtandao' : 'Digital Safety',
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
            // Screen time guidelines
            _buildSectionTitle(sw ? 'Muda wa Skrini' : 'Screen Time Guidelines'),
            const SizedBox(height: 8),
            _buildScreenTimeCard(sw),
            const SizedBox(height: 24),

            // Safe internet habits
            _buildSectionTitle(sw ? 'Tabia Salama za Mtandao' : 'Safe Internet Habits'),
            const SizedBox(height: 8),
            ..._safeHabits.map((h) => _buildHabitCard(h, sw)),
            const SizedBox(height: 24),

            // Cyberbullying
            _buildSectionTitle(sw ? 'Unyanyasaji wa Mtandaoni' : 'Cyberbullying'),
            const SizedBox(height: 8),
            _buildCyberbullyingSection(sw),
            const SizedBox(height: 24),

            // Parent tips
            _buildSectionTitle(sw ? 'Vidokezo kwa Wazazi' : 'Tips for Parents'),
            const SizedBox(height: 8),
            ..._parentTips.map((t) => _buildTipCard(t, sw)),
            const SizedBox(height: 32),
          ],
        ),
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

  Widget _buildScreenTimeCard(bool sw) {
    final guidelines = [
      _ScreenTimeGuideline(
        ageEn: '2-5 years',
        ageSw: 'Miaka 2-5',
        limitEn: '1 hour/day',
        limitSw: 'Saa 1 kwa siku',
        descEn: 'High-quality programs only. Co-watch when possible.',
        descSw: 'Programu bora tu. Tazama pamoja ikiwezekana.',
        icon: Icons.child_care_rounded,
      ),
      _ScreenTimeGuideline(
        ageEn: '6-12 years',
        ageSw: 'Miaka 6-12',
        limitEn: '1-2 hours/day',
        limitSw: 'Saa 1-2 kwa siku',
        descEn: 'Set consistent limits. Ensure it does not replace sleep or physical activity.',
        descSw: 'Weka mipaka thabiti. Hakikisha haichukui nafasi ya usingizi au mazoezi.',
        icon: Icons.school_rounded,
      ),
      _ScreenTimeGuideline(
        ageEn: '13+ years',
        ageSw: 'Miaka 13+',
        limitEn: 'Set own limits with guidance',
        limitSw: 'Weka mipaka yako na mwongozo',
        descEn: 'Teach self-regulation. Monitor content, not just time.',
        descSw: 'Fundisha kujidhibiti. Fuatilia maudhui, si muda tu.',
        icon: Icons.person_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: guidelines.map((g) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(g.icon, size: 22, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sw ? g.ageSw : g.ageEn,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sw ? g.limitSw : g.limitEn,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sw ? g.descSw : g.descEn,
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
        }).toList(),
      ),
    );
  }

  Widget _buildHabitCard(_SafeHabit habit, bool sw) {
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
          Icon(habit.icon, size: 22, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? habit.titleSw : habit.titleEn,
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
                  sw ? habit.descSw : habit.descEn,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberbullyingSection(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signs
          Text(
            sw ? 'Dalili za Unyanyasaji wa Mtandaoni' : 'Signs of Cyberbullying',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._cyberSigns.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_rounded, size: 16, color: _kSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sw ? s.sw : s.en,
                        style: const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),

          const Divider(height: 24),

          // What to do
          Text(
            sw ? 'Nini cha Kufanya' : 'What to Do',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._cyberActions.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: _kPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sw ? a.sw : a.en,
                        style: const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTipCard(_BilingualText tip, bool sw) {
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
          const Icon(Icons.lightbulb_rounded, size: 18, color: _kPrimary),
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
}

class _ScreenTimeGuideline {
  final String ageEn, ageSw, limitEn, limitSw, descEn, descSw;
  final IconData icon;
  const _ScreenTimeGuideline({
    required this.ageEn, required this.ageSw,
    required this.limitEn, required this.limitSw,
    required this.descEn, required this.descSw,
    required this.icon,
  });
}

class _SafeHabit {
  final IconData icon;
  final String titleEn, titleSw, descEn, descSw;
  const _SafeHabit({
    required this.icon,
    required this.titleEn, required this.titleSw,
    required this.descEn, required this.descSw,
  });
}

const _safeHabits = [
  _SafeHabit(
    icon: Icons.lock_rounded,
    titleEn: 'Don\'t share personal info',
    titleSw: 'Usishiriki taarifa binafsi',
    descEn: 'Never share your name, school, address, or phone number online',
    descSw: 'Usishiriki jina lako, shule, anwani, au nambari ya simu mtandaoni',
  ),
  _SafeHabit(
    icon: Icons.message_rounded,
    titleEn: 'Tell parents about uncomfortable messages',
    titleSw: 'Waambie wazazi kuhusu ujumbe usiofaa',
    descEn: 'If someone sends you something that makes you uncomfortable, tell a parent immediately',
    descSw: 'Mtu akikutumia kitu kinachokusumbua, mwambie mzazi mara moja',
  ),
  _SafeHabit(
    icon: Icons.app_blocking_rounded,
    titleEn: 'Only use age-appropriate apps',
    titleSw: 'Tumia programu za umri wako tu',
    descEn: 'Age ratings exist for a reason - respect them',
    descSw: 'Viwango vya umri vipo kwa sababu - viheshimu',
  ),
  _SafeHabit(
    icon: Icons.photo_camera_rounded,
    titleEn: 'Think before sharing photos',
    titleSw: 'Fikiri kabla ya kushiriki picha',
    descEn: 'Once a photo is online, it can never truly be deleted',
    descSw: 'Picha ikiwa mtandaoni, haiwezi kufutwa kabisa',
  ),
  _SafeHabit(
    icon: Icons.password_rounded,
    titleEn: 'Use strong passwords',
    titleSw: 'Tumia nywila kali',
    descEn: 'Never share passwords with friends. Change them regularly.',
    descSw: 'Usishiriki nywila na marafiki. Zibadilishe mara kwa mara.',
  ),
];

class _BilingualText {
  final String en;
  final String sw;
  const _BilingualText(this.en, this.sw);
}

const _cyberSigns = [
  _BilingualText(
    'Becomes upset or withdrawn after using devices',
    'Anakuwa na huzuni au kujitenga baada ya kutumia vifaa',
  ),
  _BilingualText(
    'Hides screen when parents approach',
    'Anaficha skrini wazazi wanapokaribia',
  ),
  _BilingualText(
    'Suddenly stops using devices or social media',
    'Anaacha ghafla kutumia vifaa au mitandao ya kijamii',
  ),
  _BilingualText(
    'Changes in mood, sleep, or appetite',
    'Mabadiliko ya hisia, usingizi, au hamu ya kula',
  ),
];

const _cyberActions = [
  _BilingualText(
    'Don\'t respond to the bully - save evidence',
    'Usimjibu mnyanysaji - hifadhi ushahidi',
  ),
  _BilingualText(
    'Block the person on all platforms',
    'Mzuie mtu kwenye majukwaa yote',
  ),
  _BilingualText(
    'Report to the platform and school',
    'Ripoti kwa jukwaa na shule',
  ),
  _BilingualText(
    'Talk to a trusted adult immediately',
    'Zungumza na mtu mzima unayemwamini mara moja',
  ),
];

const _parentTips = [
  _BilingualText(
    'Keep devices in common areas, not bedrooms',
    'Weka vifaa kwenye sehemu za pamoja, si vyumba vya kulala',
  ),
  _BilingualText(
    'Have regular conversations about online experiences',
    'Kuwa na mazungumzo ya mara kwa mara kuhusu uzoefu wa mtandaoni',
  ),
  _BilingualText(
    'Use parental controls appropriate for your child\'s age',
    'Tumia udhibiti wa mzazi unaofaa kwa umri wa mtoto wako',
  ),
  _BilingualText(
    'Model healthy screen habits yourself',
    'Onyesha tabia nzuri za skrini wewe mwenyewe',
  ),
  _BilingualText(
    'Create a family media agreement together',
    'Tengeneza makubaliano ya familia kuhusu vyombo vya habari pamoja',
  ),
];
