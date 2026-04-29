// lib/my_children/pages/puberty_health_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PubertyHealthPage extends StatefulWidget {
  final Child child;

  const PubertyHealthPage({super.key, required this.child});

  @override
  State<PubertyHealthPage> createState() => _PubertyHealthPageState();
}

class _PubertyHealthPageState extends State<PubertyHealthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    // Default tab based on child gender
    final isBoy = widget.child.gender == 'male';
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: isBoy ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          sw ? 'Afya na Ukuaji' : 'Health & Growth',
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
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: sw ? 'Wavulana' : 'Boys'),
            Tab(text: sw ? 'Wasichana' : 'Girls'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBoysContent(sw),
            _buildGirlsContent(sw),
          ],
        ),
      ),
    );
  }

  Widget _buildBoysContent(bool sw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(sw ? 'Ratiba ya Ukuaji' : 'Puberty Timeline'),
        const SizedBox(height: 8),
        ..._boysTimeline.map((t) => _buildTimelineCard(t, sw)),
        const SizedBox(height: 24),

        _buildSectionTitle(sw ? 'Mabadiliko ya Mwili' : 'Physical Changes'),
        const SizedBox(height: 8),
        ..._boysPhysical.map((p) => _buildInfoCard(p, sw)),
        const SizedBox(height: 24),

        _buildMentalHealthSection(sw),
        const SizedBox(height: 24),

        _buildSubstanceSection(sw),
        const SizedBox(height: 24),

        _buildDoctorCard(sw),
        const SizedBox(height: 12),
        _buildParentCard(sw),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGirlsContent(bool sw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(sw ? 'Ratiba ya Ukuaji' : 'Puberty Timeline'),
        const SizedBox(height: 8),
        ..._girlsTimeline.map((t) => _buildTimelineCard(t, sw)),
        const SizedBox(height: 24),

        _buildSectionTitle(sw ? 'Mabadiliko ya Mwili' : 'Physical Changes'),
        const SizedBox(height: 8),
        ..._girlsPhysical.map((p) => _buildInfoCard(p, sw)),
        const SizedBox(height: 24),

        _buildMentalHealthSection(sw),
        const SizedBox(height: 24),

        _buildSubstanceSection(sw),
        const SizedBox(height: 24),

        _buildDoctorCard(sw),
        const SizedBox(height: 12),
        _buildParentCard(sw),
        const SizedBox(height: 32),
      ],
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

  Widget _buildTimelineCard(_TimelineItem item, bool sw) {
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
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                item.ageRange,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? item.titleSw : item.titleEn,
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
                  sw ? item.descSw : item.descEn,
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

  Widget _buildInfoCard(_BilingualInfo info, bool sw) {
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
          const Icon(Icons.info_outline_rounded, size: 20, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? info.titleSw : info.titleEn,
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
                  sw ? info.descSw : info.descEn,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalHealthSection(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(sw ? 'Afya ya Akili' : 'Mental Health'),
        const SizedBox(height: 8),
        ..._mentalHealthTips.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t.icon, size: 20, color: _kPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? t.titleSw : t.titleEn,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sw ? t.descSw : t.descEn,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 3,
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

  Widget _buildSubstanceSection(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(sw ? 'Ufahamu wa Madawa' : 'Substance Awareness'),
        const SizedBox(height: 8),
        ..._substanceTips.map((t) => Container(
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
                          sw ? t.titleSw : t.titleEn,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sw ? t.descSw : t.descEn,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 3,
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

  Widget _buildDoctorCard(bool sw) {
    return Material(
      color: _kPrimary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                _sw
                    ? 'Moduli ya Daktari inakuja hivi karibuni'
                    : 'Doctor consultation module coming soon',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.medical_services_rounded, size: 28, color: _kPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw ? 'Zungumza na Daktari' : 'Talk to a Doctor',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sw
                          ? 'Pata msaada wa kitaalamu kuhusu afya na ukuaji'
                          : 'Get professional guidance about health and growth',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, size: 28, color: _kPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Zungumza na Mzazi' : 'Talk to a Parent',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sw
                      ? 'Mabadiliko haya ni ya kawaida. Wazazi wako wanapenda kukusaidia.'
                      : 'These changes are normal. Your parents are here to help.',
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
}

// ─── Data ──────────────────────────────────────────────────────────

class _TimelineItem {
  final String ageRange;
  final String titleEn, titleSw, descEn, descSw;
  const _TimelineItem({
    required this.ageRange,
    required this.titleEn, required this.titleSw,
    required this.descEn, required this.descSw,
  });
}

class _BilingualInfo {
  final String titleEn, titleSw, descEn, descSw;
  const _BilingualInfo({
    required this.titleEn, required this.titleSw,
    required this.descEn, required this.descSw,
  });
}

class _MentalTip {
  final IconData icon;
  final String titleEn, titleSw, descEn, descSw;
  const _MentalTip({
    required this.icon,
    required this.titleEn, required this.titleSw,
    required this.descEn, required this.descSw,
  });
}

const _boysTimeline = [
  _TimelineItem(
    ageRange: '10-11',
    titleEn: 'Early changes begin',
    titleSw: 'Mabadiliko ya awali yanaanza',
    descEn: 'Growth spurt may start. Testicles begin to enlarge.',
    descSw: 'Ukuaji wa haraka unaweza kuanza. Korodani zinaanza kukua.',
  ),
  _TimelineItem(
    ageRange: '11-13',
    titleEn: 'Voice changes and body hair',
    titleSw: 'Mabadiliko ya sauti na nywele za mwili',
    descEn: 'Voice starts to deepen. Pubic and underarm hair appears.',
    descSw: 'Sauti inaanza kuwa nzito. Nywele za sehemu za siri na kwapa zinaonekana.',
  ),
  _TimelineItem(
    ageRange: '13-15',
    titleEn: 'Major growth spurt',
    titleSw: 'Ukuaji mkubwa wa haraka',
    descEn: 'Rapid height increase. Muscles develop. Facial hair starts.',
    descSw: 'Urefu unaongezeka haraka. Misuli inakua. Nywele za usoni zinaanza.',
  ),
  _TimelineItem(
    ageRange: '15-16',
    titleEn: 'Maturation continues',
    titleSw: 'Ukuaji unaendelea',
    descEn: 'Adult body shape forms. Emotional maturity develops.',
    descSw: 'Umbo la mwili wa mtu mzima linaundwa. Ukomavu wa kihisia unakua.',
  ),
];

const _girlsTimeline = [
  _TimelineItem(
    ageRange: '8-10',
    titleEn: 'Early changes begin',
    titleSw: 'Mabadiliko ya awali yanaanza',
    descEn: 'Breast buds may start to develop. Growth spurt begins.',
    descSw: 'Matiti yanaweza kuanza kukua. Ukuaji wa haraka unaanza.',
  ),
  _TimelineItem(
    ageRange: '10-12',
    titleEn: 'Body shape changes',
    titleSw: 'Mabadiliko ya umbo la mwili',
    descEn: 'Hips widen. Pubic hair appears. Skin changes may occur.',
    descSw: 'Nyonga zinapanuka. Nywele za sehemu za siri zinaonekana. Mabadiliko ya ngozi yanaweza kutokea.',
  ),
  _TimelineItem(
    ageRange: '12-14',
    titleEn: 'Menstruation begins',
    titleSw: 'Hedhi inaanza',
    descEn: 'First period usually occurs. This is normal and healthy.',
    descSw: 'Hedhi ya kwanza kawaida hutokea. Hii ni kawaida na ni afya.',
  ),
  _TimelineItem(
    ageRange: '14-16',
    titleEn: 'Maturation continues',
    titleSw: 'Ukuaji unaendelea',
    descEn: 'Periods become more regular. Adult body shape develops.',
    descSw: 'Hedhi inakuwa ya kawaida zaidi. Umbo la mwili wa mtu mzima linakua.',
  ),
];

const _boysPhysical = [
  _BilingualInfo(
    titleEn: 'Growth spurts',
    titleSw: 'Ukuaji wa haraka',
    descEn: 'Boys may grow 4-5 inches per year during peak growth. Good nutrition and sleep are essential.',
    descSw: 'Wavulana wanaweza kukua sm 10-12 kwa mwaka wakati wa kilele cha ukuaji. Lishe bora na usingizi ni muhimu.',
  ),
  _BilingualInfo(
    titleEn: 'Skin changes',
    titleSw: 'Mabadiliko ya ngozi',
    descEn: 'Acne is common due to hormonal changes. Regular washing helps. See a doctor if severe.',
    descSw: 'Chunusi ni kawaida kwa sababu ya mabadiliko ya homoni. Kuosha mara kwa mara husaidia. Muone daktari ikiwa ni kali.',
  ),
  _BilingualInfo(
    titleEn: 'Body odor',
    titleSw: 'Harufu ya mwili',
    descEn: 'Sweat glands become more active. Daily bathing and deodorant become important.',
    descSw: 'Tezi za jasho zinakuwa hai zaidi. Kuoga kila siku na dawa ya harufu inakuwa muhimu.',
  ),
];

const _girlsPhysical = [
  _BilingualInfo(
    titleEn: 'Understanding menstruation',
    titleSw: 'Kuelewa hedhi',
    descEn: 'Periods are a normal, healthy part of growing up. They may be irregular at first. Keeping a calendar helps track cycles.',
    descSw: 'Hedhi ni sehemu ya kawaida na ya kiafya ya kukua. Zinaweza kuwa za kawaida mwanzoni. Kutumia kalenda husaidia kufuatilia mizunguko.',
  ),
  _BilingualInfo(
    titleEn: 'Skin and body care',
    titleSw: 'Utunzaji wa ngozi na mwili',
    descEn: 'Hormonal changes may cause acne. A simple skincare routine with gentle cleanser helps.',
    descSw: 'Mabadiliko ya homoni yanaweza kusababisha chunusi. Utaratibu rahisi wa utunzaji wa ngozi na sabuni laini husaidia.',
  ),
  _BilingualInfo(
    titleEn: 'Nutrition needs increase',
    titleSw: 'Mahitaji ya lishe yanaongezeka',
    descEn: 'Growing bodies need more iron, calcium, and protein. Encourage a balanced diet.',
    descSw: 'Miili inayokua inahitaji chuma, kalsiamu, na protini zaidi. Himiza lishe bora.',
  ),
];

const _mentalHealthTips = [
  _MentalTip(
    icon: Icons.mood_rounded,
    titleEn: 'Mood swings are normal',
    titleSw: 'Mabadiliko ya hisia ni ya kawaida',
    descEn: 'Hormones cause emotional ups and downs. Be patient and supportive.',
    descSw: 'Homoni husababisha kupanda na kushuka kwa hisia. Kuwa na subira na msaada.',
  ),
  _MentalTip(
    icon: Icons.self_improvement_rounded,
    titleEn: 'Stress management',
    titleSw: 'Kudhibiti msongo wa mawazo',
    descEn: 'Teach breathing exercises, journaling, and physical activity as stress relievers.',
    descSw: 'Fundisha mazoezi ya kupumua, kuandika shajara, na shughuli za kimwili kupunguza msongo.',
  ),
  _MentalTip(
    icon: Icons.bedtime_rounded,
    titleEn: 'Sleep is crucial',
    titleSw: 'Usingizi ni muhimu sana',
    descEn: 'Teens need 8-10 hours of sleep. Limit screens before bedtime.',
    descSw: 'Vijana wanahitaji saa 8-10 za usingizi. Punguza skrini kabla ya kulala.',
  ),
];

const _substanceTips = [
  _BilingualInfo(
    titleEn: 'Alcohol awareness',
    titleSw: 'Ufahamu wa pombe',
    descEn: 'Young bodies are more affected by alcohol. It damages developing brains and organs.',
    descSw: 'Miili michanga inathiriwa zaidi na pombe. Inaharibu ubongo na viungo vinavyokua.',
  ),
  _BilingualInfo(
    titleEn: 'Peer pressure',
    titleSw: 'Shinikizo la marafiki',
    descEn: 'Practice saying "no" in different scenarios. True friends respect your choices.',
    descSw: 'Fanya mazoezi ya kusema "hapana" katika hali tofauti. Marafiki wa kweli wanaheshimu maamuzi yako.',
  ),
  _BilingualInfo(
    titleEn: 'Drug risks',
    titleSw: 'Hatari za madawa ya kulevya',
    descEn: 'Even "trying once" can be dangerous. Open conversations about risks are important.',
    descSw: 'Hata "kujaribu mara moja" kunaweza kuwa hatari. Mazungumzo wazi kuhusu hatari ni muhimu.',
  ),
];

