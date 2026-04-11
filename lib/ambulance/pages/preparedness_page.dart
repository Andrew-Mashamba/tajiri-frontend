// lib/ambulance/pages/preparedness_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);

class _Tip {
  final String title;
  final String titleSw;
  final String category;
  final List<String> items;
  final List<String> itemsSw;

  const _Tip({
    required this.title,
    required this.titleSw,
    required this.category,
    required this.items,
    required this.itemsSw,
  });
}

const _categories = [
  ('all', 'All', 'Zote', Icons.grid_view_rounded),
  ('earthquake', 'Earthquake', 'Tetemeko', Icons.public_rounded),
  ('flood', 'Flood', 'Mafuriko', Icons.water_rounded),
  ('fire', 'Fire', 'Moto', Icons.local_fire_department_rounded),
  ('first_aid', 'First Aid Kit', 'Vifaa vya Msaada', Icons.medical_services_rounded),
];

const _tips = [
  _Tip(
    title: 'Earthquake Safety',
    titleSw: 'Usalama wa Tetemeko la Ardhi',
    category: 'earthquake',
    items: [
      'Drop, Cover, and Hold On during shaking',
      'Stay away from windows and heavy furniture',
      'If outdoors, move to an open area away from buildings',
      'After shaking stops, check for injuries and damage',
      'Keep emergency supplies: water, food, flashlight, radio',
      'Know your building\'s evacuation routes',
      'Secure heavy items (bookshelves, water heaters) to walls',
    ],
    itemsSw: [
      'Inama, Jifunike, na Shika wakati wa mtikisiko',
      'Kaa mbali na madirisha na samani nzito',
      'Ukiwa nje, nenda eneo wazi mbali na majengo',
      'Baada ya mtikisiko kusimama, angalia majeraha na uharibifu',
      'Weka vifaa vya dharura: maji, chakula, tochi, redio',
      'Jua njia za kuondoka kwenye jengo lako',
      'Funga vitu vizito (rafu za vitabu, vipasha maji) ukutani',
    ],
  ),
  _Tip(
    title: 'Flood Preparedness',
    titleSw: 'Maandalizi ya Mafuriko',
    category: 'flood',
    items: [
      'Know your area\'s flood risk and evacuation routes',
      'Never walk or drive through flood waters',
      'Move important documents to waterproof containers',
      'Store drinking water in sealed containers',
      'Keep emergency phone numbers accessible',
      'Elevate electrical appliances above potential flood levels',
      'Have a "go bag" ready with essentials for 72 hours',
    ],
    itemsSw: [
      'Jua hatari ya mafuriko katika eneo lako na njia za kuondoka',
      'Kamwe usitembee au kuendesha gari kupitia maji ya mafuriko',
      'Hamisha nyaraka muhimu kwenye vyombo visivyopitisha maji',
      'Hifadhi maji ya kunywa kwenye vyombo vilivyofungwa',
      'Weka nambari za simu za dharura mahali pa kufikika',
      'Inua vifaa vya umeme juu ya kiwango cha mafuriko',
      'Kuwa na begi la dharura lililoandaliwa na vitu vya lazima kwa saa 72',
    ],
  ),
  _Tip(
    title: 'Fire Safety',
    titleSw: 'Usalama wa Moto',
    category: 'fire',
    items: [
      'Install and test smoke alarms monthly',
      'Plan and practice two escape routes from every room',
      'Crawl low under smoke to escape',
      'Close doors behind you as you escape',
      'Never go back inside a burning building',
      'Keep fire extinguishers in kitchen and each floor',
      'Teach children: stop, drop, and roll',
      'Store flammable materials away from heat sources',
    ],
    itemsSw: [
      'Weka na jaribu kengele za moshi kila mwezi',
      'Panga na fanya mazoezi ya njia mbili za kutoka kila chumba',
      'Tambaa chini chini ya moshi wakati wa kutoka',
      'Funga milango nyuma yako wakati wa kutoka',
      'Kamwe usirudi ndani ya jengo linalowaka',
      'Weka vizima moto jikoni na kila ghorofa',
      'Fundisha watoto: simama, lala chini, na viringika',
      'Hifadhi vitu vinavyowaka mbali na vyanzo vya joto',
    ],
  ),
  _Tip(
    title: 'First Aid Kit Essentials',
    titleSw: 'Vitu vya Lazima vya Msaada wa Kwanza',
    category: 'first_aid',
    items: [
      'Adhesive bandages (various sizes)',
      'Sterile gauze pads and tape',
      'Antiseptic wipes and antibiotic ointment',
      'Scissors, tweezers, and safety pins',
      'Disposable gloves (at least 2 pairs)',
      'Pain relievers (Paracetamol, Ibuprofen)',
      'Oral rehydration salts (ORS)',
      'Emergency blanket',
      'Triangular bandage for slings',
      'First aid manual or instruction card',
    ],
    itemsSw: [
      'Plasta za bandeji (ukubwa mbalimbali)',
      'Pedi za gauze safi na tepu',
      'Vitambaa vya antiseptiki na mafuta ya antibiotic',
      'Mkasi, koleo, na pini za usalama',
      'Glavu za kutumia na kutupa (angalau jozi 2)',
      'Dawa za maumivu (Paracetamol, Ibuprofeni)',
      'Chumvi za kurejesha maji mwilini (ORS)',
      'Blanketi ya dharura',
      'Bandeji ya pembetatu kwa slingi',
      'Kitabu cha msaada wa kwanza au kadi ya maelekezo',
    ],
  ),
  _Tip(
    title: 'Power Outage Preparedness',
    titleSw: 'Maandalizi ya Kukatiwa Umeme',
    category: 'earthquake',
    items: [
      'Keep flashlights and extra batteries ready',
      'Charge power banks and phones in advance',
      'Have a battery-powered or hand-crank radio',
      'Stock non-perishable food that doesn\'t need cooking',
      'Keep cash on hand (ATMs may not work)',
      'Know how to manually open your electric garage door',
    ],
    itemsSw: [
      'Weka tochi na betri za ziada tayari',
      'Chaji power bank na simu mapema',
      'Kuwa na redio inayotumia betri au kugeuzwa kwa mkono',
      'Hifadhi chakula ambacho hakiharibu haraka na hakihitaji kupikwa',
      'Weka pesa taslimu mikononi (ATM zinaweza kutofanya kazi)',
      'Jua jinsi ya kufungua mlango wako wa gari wa umeme kwa mkono',
    ],
  ),
];

class PreparednessPage extends StatefulWidget {
  const PreparednessPage({super.key});
  @override
  State<PreparednessPage> createState() => _PreparednessPageState();
}

class _PreparednessPageState extends State<PreparednessPage>
    with SingleTickerProviderStateMixin {
  late final bool _isSwahili;
  late final TabController _tabCtrl;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _tabCtrl = TabController(length: _categories.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _selectedCategory = _categories[_tabCtrl.index].$1;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<_Tip> get _filteredTips {
    if (_selectedCategory == 'all') return _tips;
    return _tips.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tips = _filteredTips;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Maandalizi ya Dharura' : 'Emergency Preparedness',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((cat) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.$4, size: 16),
                  const SizedBox(width: 4),
                  Text(_isSwahili ? cat.$3 : cat.$2),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: tips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.checklist_rounded,
                      size: 48, color: _kSecondary),
                  const SizedBox(height: 12),
                  Text(
                    _isSwahili
                        ? 'Hakuna vidokezo'
                        : 'No tips available',
                    style: const TextStyle(
                        color: _kSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final tip = tips[i];
                final items = _isSwahili ? tip.itemsSw : tip.items;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _kRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _categories
                                    .firstWhere(
                                        (c) => c.$1 == tip.category,
                                        orElse: () => _categories[0])
                                    .$4,
                                color: _kRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isSwahili ? tip.titleSw : tip.title,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...items.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kPrimary,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: _kPrimary,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
