// lib/ambulance/pages/medication_reference_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);

class _Medication {
  final String name;
  final String nameSw;
  final String dosageAdult;
  final String dosageAdultSw;
  final String dosageChild;
  final String dosageChildSw;
  final String warnings;
  final String warningsSw;
  final IconData icon;

  const _Medication({
    required this.name,
    required this.nameSw,
    required this.dosageAdult,
    required this.dosageAdultSw,
    required this.dosageChild,
    required this.dosageChildSw,
    required this.warnings,
    required this.warningsSw,
    required this.icon,
  });
}

const _medications = [
  _Medication(
    name: 'Paracetamol (Acetaminophen)',
    nameSw: 'Paracetamol (Asetaminofeni)',
    dosageAdult: 'Adults: 500-1000mg every 4-6 hours. Max 4000mg/day.',
    dosageAdultSw:
        'Watu wazima: 500-1000mg kila saa 4-6. Kiwango cha juu 4000mg/siku.',
    dosageChild:
        'Children: 10-15mg/kg every 4-6 hours. Max 5 doses/day.',
    dosageChildSw:
        'Watoto: 10-15mg/kg kila saa 4-6. Kiwango cha juu dozi 5/siku.',
    warnings:
        'Do NOT exceed maximum dose. Avoid with liver disease or alcohol use.',
    warningsSw:
        'USIZIDISHE kiwango cha juu. Epuka kwa ugonjwa wa ini au pombe.',
    icon: Icons.healing_rounded,
  ),
  _Medication(
    name: 'Aspirin',
    nameSw: 'Aspirini',
    dosageAdult: 'Adults: 300-600mg every 4-6 hours. Max 4000mg/day.',
    dosageAdultSw:
        'Watu wazima: 300-600mg kila saa 4-6. Kiwango cha juu 4000mg/siku.',
    dosageChild:
        'Children under 16: DO NOT give aspirin (risk of Reye\'s syndrome).',
    dosageChildSw:
        'Watoto chini ya miaka 16: USITOE aspirini (hatari ya ugonjwa wa Reye).',
    warnings:
        'Not for children under 16. Avoid if allergic, asthmatic, or on blood thinners.',
    warningsSw:
        'Si kwa watoto chini ya 16. Epuka kama una mzio, pumu, au dawa za kufanya damu.',
    icon: Icons.medication_rounded,
  ),
  _Medication(
    name: 'ORS (Oral Rehydration Salts)',
    nameSw: 'ORS (Chumvi za Kurejesha Maji Mwilini)',
    dosageAdult:
        'Adults: Dissolve 1 sachet in 1 liter of clean water. Sip frequently.',
    dosageAdultSw:
        'Watu wazima: Changanya pakiti 1 katika lita 1 ya maji safi. Kunywa kidogo kidogo.',
    dosageChild:
        'Children <2yrs: 50-100ml after each loose stool. 2-10yrs: 100-200ml.',
    dosageChildSw:
        'Watoto <miaka 2: 50-100ml baada ya kila kuhara. Miaka 2-10: 100-200ml.',
    warnings:
        'Use within 24 hours of preparation. Do not add sugar or salt to ORS.',
    warningsSw:
        'Tumia ndani ya saa 24 baada ya kuandaa. Usiongeze sukari au chumvi.',
    icon: Icons.water_drop_rounded,
  ),
  _Medication(
    name: 'Antihistamine (Cetirizine/Loratadine)',
    nameSw: 'Dawa ya Mzio (Setirizini/Loratadini)',
    dosageAdult: 'Adults: Cetirizine 10mg once daily or Loratadine 10mg once daily.',
    dosageAdultSw:
        'Watu wazima: Setirizini 10mg mara moja kwa siku au Loratadini 10mg mara moja kwa siku.',
    dosageChild:
        'Children 2-6yrs: 5mg once daily. 6+yrs: 10mg once daily.',
    dosageChildSw:
        'Watoto miaka 2-6: 5mg mara moja kwa siku. Miaka 6+: 10mg mara moja kwa siku.',
    warnings:
        'May cause drowsiness. Avoid driving until you know how it affects you.',
    warningsSw:
        'Inaweza kusababisha kusinzia. Epuka kuendesha gari hadi ujue athari yake.',
    icon: Icons.spa_rounded,
  ),
  _Medication(
    name: 'Ibuprofen',
    nameSw: 'Ibuprofeni',
    dosageAdult: 'Adults: 200-400mg every 4-6 hours. Max 1200mg/day (OTC).',
    dosageAdultSw:
        'Watu wazima: 200-400mg kila saa 4-6. Kiwango cha juu 1200mg/siku.',
    dosageChild:
        'Children 3m+: 5-10mg/kg every 6-8 hours. Max 3 doses/day.',
    dosageChildSw:
        'Watoto miezi 3+: 5-10mg/kg kila saa 6-8. Kiwango cha juu dozi 3/siku.',
    warnings:
        'Take with food. Avoid with kidney disease, ulcers, or asthma. Not for last trimester of pregnancy.',
    warningsSw:
        'Tumia na chakula. Epuka kwa ugonjwa wa figo, vidonda, au pumu. Si kwa miezi 3 ya mwisho ya ujauzito.',
    icon: Icons.medication_liquid_rounded,
  ),
  _Medication(
    name: 'Activated Charcoal',
    nameSw: 'Mkaa wa Kuamilishwa',
    dosageAdult:
        'Adults: 25-100g mixed with water. Use within 1 hour of ingestion.',
    dosageAdultSw:
        'Watu wazima: 25-100g changanya na maji. Tumia ndani ya saa 1 baada ya kumeza.',
    dosageChild:
        'Children: 1g/kg body weight. Only under medical supervision.',
    dosageChildSw:
        'Watoto: 1g/kg uzito wa mwili. Tu chini ya usimamizi wa daktari.',
    warnings:
        'Only for certain poisonings. Do NOT use for acids, alkalis, or petroleum products. Seek medical help.',
    warningsSw:
        'Tu kwa aina fulani za sumu. USITUMIE kwa asidi, alkali, au bidhaa za petroli. Tafuta msaada wa daktari.',
    icon: Icons.science_rounded,
  ),
  _Medication(
    name: 'Oral Rehydration (Homemade)',
    nameSw: 'Kurejesha Maji (Nyumbani)',
    dosageAdult:
        '6 teaspoons sugar + 1/2 teaspoon salt in 1 liter clean water.',
    dosageAdultSw:
        'Vijiko 6 vya sukari + nusu kijiko cha chumvi katika lita 1 ya maji safi.',
    dosageChild:
        'Same recipe. Children: small sips every few minutes.',
    dosageChildSw:
        'Mapishi sawa. Watoto: yunywe kidogo kidogo kila dakika chache.',
    warnings:
        'Use only when ORS sachets are unavailable. Measure carefully. Use within 24 hours.',
    warningsSw:
        'Tumia tu pakiti za ORS hazipo. Pima kwa makini. Tumia ndani ya saa 24.',
    icon: Icons.local_drink_rounded,
  ),
  _Medication(
    name: 'Epinephrine Auto-Injector (EpiPen)',
    nameSw: 'Sindano ya Epinefirini (EpiPen)',
    dosageAdult:
        'Adults/Children >30kg: 0.3mg auto-injector into outer thigh.',
    dosageAdultSw:
        'Watu wazima/Watoto >30kg: sindano ya 0.3mg kwenye paja la nje.',
    dosageChild:
        'Children 15-30kg: 0.15mg (junior auto-injector) into outer thigh.',
    dosageChildSw:
        'Watoto 15-30kg: 0.15mg (sindano ya watoto) kwenye paja la nje.',
    warnings:
        'For severe allergic reactions (anaphylaxis) only. Call emergency services immediately after use.',
    warningsSw:
        'Kwa mzio mkubwa (anaphylaxis) tu. Piga simu ya dharura mara moja baada ya kutumia.',
    icon: Icons.vaccines_rounded,
  ),
];

class MedicationReferencePage extends StatefulWidget {
  const MedicationReferencePage({super.key});
  @override
  State<MedicationReferencePage> createState() =>
      _MedicationReferencePageState();
}

class _MedicationReferencePageState extends State<MedicationReferencePage> {
  late final bool _isSwahili;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Rejea ya Dawa' : 'Medication Reference',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _medications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final med = _medications[i];
          final expanded = _expandedIndex == i;
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  onTap: () => setState(() {
                    _expandedIndex = expanded ? null : i;
                  }),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(med.icon, color: _kRed, size: 20),
                  ),
                  title: Text(
                    _isSwahili ? med.nameSw : med.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _kSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                ),
                if (expanded) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Adult dosage
                        Text(
                          _isSwahili
                              ? 'Kipimo - Watu Wazima:'
                              : 'Dosage - Adults:',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSwahili
                              ? med.dosageAdultSw
                              : med.dosageAdult,
                          style: const TextStyle(
                              fontSize: 13,
                              color: _kPrimary,
                              height: 1.4),
                        ),
                        const SizedBox(height: 10),

                        // Child dosage
                        Text(
                          _isSwahili
                              ? 'Kipimo - Watoto:'
                              : 'Dosage - Children:',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSwahili
                              ? med.dosageChildSw
                              : med.dosageChild,
                          style: const TextStyle(
                              fontSize: 13,
                              color: _kPrimary,
                              height: 1.4),
                        ),
                        const SizedBox(height: 10),

                        // Warnings
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_rounded,
                                  size: 16, color: Color(0xFFE65100)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isSwahili ? 'Onyo:' : 'Warning:',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFE65100)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isSwahili
                                          ? med.warningsSw
                                          : med.warnings,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFE65100),
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
