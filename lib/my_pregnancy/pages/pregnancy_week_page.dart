// lib/my_pregnancy/pages/pregnancy_week_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PregnancyWeekPage extends StatefulWidget {
  final Pregnancy pregnancy;
  final WeekInfo? weekInfo;

  const PregnancyWeekPage({
    super.key,
    required this.pregnancy,
    this.weekInfo,
  });

  @override
  State<PregnancyWeekPage> createState() => _PregnancyWeekPageState();
}

class _PregnancyWeekPageState extends State<PregnancyWeekPage> {
  final MyPregnancyService _service = MyPregnancyService();
  late int _currentWeek;
  WeekInfo? _weekInfo;
  bool _isLoading = false;
  bool _isSavingSymptoms = false;

  // Symptom logging
  final Set<PregnancySymptom> _loggedSymptoms = {};

  // Checklist state
  final Set<int> _checkedItems = {};

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  bool get _sw =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.pregnancy.currentWeek.clamp(1, 42);
    _weekInfo = widget.weekInfo;
    if (_weekInfo == null) _loadWeekInfo();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pregnancy_checklist_week_$_currentWeek';
      final saved = prefs.getStringList(key);
      if (saved != null && mounted) {
        setState(() {
          _checkedItems.clear();
          _checkedItems.addAll(saved.map((s) => int.tryParse(s) ?? -1).where((i) => i >= 0));
        });
      }
    } catch (_) {}
  }

  Future<void> _saveChecklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pregnancy_checklist_week_$_currentWeek';
      await prefs.setStringList(key, _checkedItems.map((i) => '$i').toList());
    } catch (_) {}
  }

  Future<void> _loadWeekInfo() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getWeekInfo(_currentWeek, token: _token);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _weekInfo = result.data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeWeek(int delta) {
    final newWeek = (_currentWeek + delta).clamp(1, 42);
    if (newWeek != _currentWeek) {
      setState(() {
        _currentWeek = newWeek;
        _weekInfo = null;
        _loggedSymptoms.clear();
        _checkedItems.clear();
      });
      _loadWeekInfo();
      _loadChecklist();
    }
  }

  Future<void> _saveSymptoms() async {
    if (_loggedSymptoms.isEmpty) return;
    setState(() => _isSavingSymptoms = true);
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final result = await _service.saveSymptoms(
        pregnancyId: widget.pregnancy.id,
        weekNumber: _currentWeek,
        symptoms: _loggedSymptoms.map((s) => s.name).toList(),
        userId: widget.pregnancy.userId,
        token: _token,
      );
      if (mounted) {
        if (result.success) {
          messenger.showSnackBar(
            SnackBar(
                content: Text(sw
                    ? 'Dalili zimehifadhiwa'
                    : 'Symptoms saved')),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
                content: Text(result.message ??
                    (sw
                        ? 'Imeshindwa kuhifadhi dalili'
                        : 'Failed to save symptoms'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(sw
                  ? 'Kosa: $e'
                  : 'Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSavingSymptoms = false);
  }

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
          sw ? 'Wiki $_currentWeek' : 'Week $_currentWeek',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: _kPrimary),
                onPressed: _currentWeek > 1 ? () => _changeWeek(-1) : null,
              ),
              IconButton(
                icon:
                    const Icon(Icons.chevron_right_rounded, color: _kPrimary),
                onPressed: _currentWeek < 42 ? () => _changeWeek(1) : null,
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Baby size card
                _buildBabySizeCard(sw),
                const SizedBox(height: 16),

                // Development milestones
                _buildSection(
                  sw ? 'Maendeleo ya Mtoto' : 'Baby Development',
                  Icons.child_care_rounded,
                  _weekInfo?.developmentSummary ?? _getDefaultDevelopment(sw),
                ),
                const SizedBox(height: 12),

                // Mother's body changes
                _buildSection(
                  sw ? 'Mabadiliko ya Mwili Wako' : 'Your Body Changes',
                  Icons.pregnant_woman_rounded,
                  _weekInfo?.motherTips ?? _getDefaultMotherTips(sw),
                ),
                const SizedBox(height: 16),

                // Weekly checklist
                _buildChecklist(sw),
                const SizedBox(height: 16),

                // Symptom logger
                _buildSymptomLogger(sw),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildBabySizeCard(bool sw) {
    final sizeInfo = _weekInfo;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _weekToEmoji(_currentWeek),
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 12),
          Text(
            sizeInfo?.babySizeComparison ?? _getDefaultSize(sw),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (sizeInfo != null && sizeInfo.babyLengthCm > 0) ...[
                _StatChip(
                    label: sw ? 'Urefu' : 'Length',
                    value: '${sizeInfo.babyLengthCm} cm'),
                const SizedBox(width: 16),
              ],
              if (sizeInfo != null && sizeInfo.babyWeightGrams > 0)
                _StatChip(
                  label: sw ? 'Uzito' : 'Weight',
                  value: sizeInfo.babyWeightGrams >= 1000
                      ? '${(sizeInfo.babyWeightGrams / 1000).toStringAsFixed(1)} kg'
                      : '${sizeInfo.babyWeightGrams.toStringAsFixed(0)} g',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
                fontSize: 13, color: _kSecondary, height: 1.5),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(bool sw) {
    final items = _weekInfo?.checklist ?? _getDefaultChecklist(sw);
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                sw ? 'Orodha ya Mambo ya Kufanya' : 'To-Do List',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isChecked = _checkedItems.contains(index);
            return CheckboxListTile(
              value: isChecked,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _checkedItems.add(index);
                  } else {
                    _checkedItems.remove(index);
                  }
                });
                _saveChecklist();
              },
              title: Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  color: isChecked ? _kSecondary : _kPrimary,
                  decoration:
                      isChecked ? TextDecoration.lineThrough : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: _kPrimary,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSymptomLogger(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_rounded,
                  size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                sw ? "Rekodi Dalili za Leo" : "Log Today's Symptoms",
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PregnancySymptom.values.map((symptom) {
              final selected = _loggedSymptoms.contains(symptom);
              return FilterChip(
                label: Text(symptom.displayName(isSwahili: sw)),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _loggedSymptoms.add(symptom);
                    } else {
                      _loggedSymptoms.remove(symptom);
                    }
                  });
                  // Show danger warning
                  if (v && symptom.isDanger) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(
                          sw
                              ? 'TAHADHARI: ${symptom.swahiliName} ni dalili ya hatari. Nenda hospitali!'
                              : 'WARNING: ${symptom.englishName} is a danger sign. Go to the hospital!',
                          style: const TextStyle(color: Colors.white),
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                selectedColor: symptom.isDanger
                    ? Colors.red.shade100
                    : _kPrimary.withValues(alpha: 0.15),
                checkmarkColor: symptom.isDanger ? Colors.red : _kPrimary,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? (symptom.isDanger ? Colors.red : _kPrimary)
                      : _kSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: symptom.isDanger && selected
                      ? Colors.red.shade300
                      : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
          if (_loggedSymptoms.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _isSavingSymptoms ? null : _saveSymptoms,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSavingSymptoms
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        sw ? 'Hifadhi Dalili' : 'Save Symptoms',
                        style: const TextStyle(fontSize: 14),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Default content when API data is not available ──────────

  String _getDefaultSize(bool sw) {
    if (sw) {
      if (_currentWeek <= 8) return 'Mbegu ndogo';
      if (_currentWeek <= 14) return 'Tunda dogo';
      if (_currentWeek <= 22) return 'Tunda la wastani';
      if (_currentWeek <= 30) return 'Tunda kubwa';
      return 'Tunda kubwa sana';
    } else {
      if (_currentWeek <= 8) return 'Small seed';
      if (_currentWeek <= 14) return 'Small fruit';
      if (_currentWeek <= 22) return 'Medium fruit';
      if (_currentWeek <= 30) return 'Large fruit';
      return 'Very large fruit';
    }
  }

  String _getDefaultDevelopment(bool sw) {
    if (sw) {
      if (_currentWeek <= 4) {
        return 'Mimba imeanza kuota. Seli zinaanza kugawanyika na kuunda msingi wa mtoto.';
      }
      if (_currentWeek <= 8) {
        return 'Moyo wa mtoto unaanza kupiga. Mikono na miguu inaanza kuonekana. Ubongo unakua haraka.';
      }
      if (_currentWeek <= 12) {
        return 'Mtoto ana vidole vyote. Uso unaanza kuchukua sura. Viungo muhimu vinaendelea kukua.';
      }
      if (_currentWeek <= 16) {
        return 'Mtoto anaweza kusogea. Mifupa inaimarika. Nywele zinaanza kuota.';
      }
      if (_currentWeek <= 20) {
        return 'Unaweza kuhisi mateke ya mtoto! Masikio yake yanasikia sauti. Ngozi inakua.';
      }
      if (_currentWeek <= 28) {
        return 'Mtoto anafungua macho. Mapafu yanaendelea kukua. Ubongo unakua haraka sana.';
      }
      if (_currentWeek <= 36) {
        return 'Mtoto anajitayarisha kuzaliwa. Mafuta yanajikusanya chini ya ngozi. Kichwa kinaweza kugeuka chini.';
      }
      return 'Mtoto yuko tayari kuzaliwa! Viungo vyote vimekamilika. Subiri kwa furaha.';
    } else {
      if (_currentWeek <= 4) {
        return 'The embryo is forming. Cells are dividing and building the foundation of the baby.';
      }
      if (_currentWeek <= 8) {
        return 'The baby\'s heart is starting to beat. Arms and legs are forming. The brain is growing rapidly.';
      }
      if (_currentWeek <= 12) {
        return 'The baby has all fingers and toes. The face is taking shape. Important organs continue to develop.';
      }
      if (_currentWeek <= 16) {
        return 'The baby can move. Bones are strengthening. Hair is starting to grow.';
      }
      if (_currentWeek <= 20) {
        return 'You can feel the baby kick! Ears can hear sounds. Skin is developing.';
      }
      if (_currentWeek <= 28) {
        return 'The baby opens its eyes. Lungs continue to develop. The brain is growing very rapidly.';
      }
      if (_currentWeek <= 36) {
        return 'The baby is preparing for birth. Fat is accumulating under the skin. The head may turn down.';
      }
      return 'The baby is ready to be born! All organs are complete. Wait with joy.';
    }
  }

  String _getDefaultMotherTips(bool sw) {
    if (sw) {
      if (_currentWeek <= 12) {
        return 'Kichefuchefu ni kawaida katika trimesta ya kwanza. Kula kidogo kidogo mara nyingi. Pumzika vya kutosha. Anza kunywa vitamini za ujauzito.';
      }
      if (_currentWeek <= 24) {
        return 'Tumbo linaanza kuonekana. Unaweza kuhisi mtoto akisogea. Endelea na mazoezi ya wastani. Kunywa maji mengi.';
      }
      if (_currentWeek <= 36) {
        return 'Mwili unajiandaa kwa kujifungua. Miguu inaweza kuvimba. Pumzika na miguu juu. Andaa vifaa vya hospitali.';
      }
      return 'Uko karibu sana! Angalia dalili za uchungu. Hakikisha una mpango wa kwenda hospitali. Piga simu daktari kama kuna wasiwasi.';
    } else {
      if (_currentWeek <= 12) {
        return 'Nausea is normal in the first trimester. Eat small meals frequently. Rest well. Start prenatal vitamins.';
      }
      if (_currentWeek <= 24) {
        return 'Your bump is showing. You may feel the baby move. Continue moderate exercise. Drink plenty of water.';
      }
      if (_currentWeek <= 36) {
        return 'Your body is preparing for delivery. Feet may swell. Rest with feet up. Pack your hospital bag.';
      }
      return 'You are very close! Watch for labor signs. Make sure you have a plan to get to the hospital. Call your doctor if concerned.';
    }
  }

  List<String> _getDefaultChecklist(bool sw) {
    if (sw) {
      if (_currentWeek <= 8) {
        return [
          'Anza kunywa folic acid',
          'Panga miadi ya kliniki ya kwanza',
          'Acha pombe na sigara',
          'Kula vyakula vyenye chuma',
        ];
      }
      if (_currentWeek <= 14) {
        return [
          'Nenda kliniki ya kwanza',
          'Fanya vipimo vya damu na mkojo',
          'Piga picha ya ultrasound ya kwanza',
          'Sema na mwenzi kuhusu mpango wa kuzaa',
        ];
      }
      if (_currentWeek <= 20) {
        return [
          'Fanya ultrasound ya anatomy scan',
          'Anza mazoezi ya kegel',
          'Andaa chumba cha mtoto',
          'Saga jina la mtoto',
        ];
      }
      if (_currentWeek <= 28) {
        return [
          'Fanya kipimo cha sukari (glucose test)',
          'Anza kuhesabu mateke',
          'Jiandae kwa darasa la kujifungua',
          'Tengeneza mpango wa kuzaa',
        ];
      }
      if (_currentWeek <= 36) {
        return [
          'Andaa begi la hospitali',
          'Chagua hospitali ya kujifungulia',
          'Fanya kipimo cha GBS',
          'Jifunze kuhusu kunyonyesha',
        ];
      }
      return [
        'Begi la hospitali liko tayari?',
        'Mpango wa usafiri kwenda hospitali',
        'Nambari za dharura zimehifadhiwa?',
        'Pumzika na subiri kwa amani',
      ];
    } else {
      if (_currentWeek <= 8) {
        return [
          'Start taking folic acid',
          'Schedule first clinic visit',
          'Stop alcohol and smoking',
          'Eat iron-rich foods',
        ];
      }
      if (_currentWeek <= 14) {
        return [
          'Go to first clinic visit',
          'Get blood and urine tests',
          'Get first ultrasound',
          'Discuss birth plan with partner',
        ];
      }
      if (_currentWeek <= 20) {
        return [
          'Get anatomy scan ultrasound',
          'Start kegel exercises',
          'Prepare the nursery',
          'Choose a baby name',
        ];
      }
      if (_currentWeek <= 28) {
        return [
          'Get glucose test',
          'Start counting kicks',
          'Prepare for birthing class',
          'Create a birth plan',
        ];
      }
      if (_currentWeek <= 36) {
        return [
          'Pack hospital bag',
          'Choose delivery hospital',
          'Get GBS test',
          'Learn about breastfeeding',
        ];
      }
      return [
        'Is hospital bag ready?',
        'Transport plan to hospital',
        'Emergency numbers saved?',
        'Rest and wait peacefully',
      ];
    }
  }

  String _weekToEmoji(int week) {
    if (week <= 6) return '🫘';
    if (week <= 9) return '🫐';
    if (week <= 11) return '🍋';
    if (week <= 14) return '🍊';
    if (week <= 16) return '🥑';
    if (week <= 19) return '🌶️';
    if (week <= 21) return '🍌';
    if (week <= 24) return '🌽';
    if (week <= 27) return '🥬';
    if (week <= 30) return '🥥';
    if (week <= 33) return '🍍';
    if (week <= 36) return '🍈';
    return '🍉';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
