// lib/my_baby/pages/vaccination_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';
import '../widgets/vaccination_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

/// Tanzania EPI vaccination schedule — local fallback when API returns empty.
const List<Map<String, dynamic>> _tanzaniaEPI = [
  {'name_en': 'BCG', 'name_sw': 'BCG', 'age_label': 'Birth', 'due_age_days': 0},
  {'name_en': 'OPV-0', 'name_sw': 'OPV-0', 'age_label': 'Birth', 'due_age_days': 0},
  {'name_en': 'DPT-HepB-Hib-1', 'name_sw': 'Penta-1', 'age_label': '6 weeks', 'due_age_days': 42},
  {'name_en': 'OPV-1', 'name_sw': 'OPV-1', 'age_label': '6 weeks', 'due_age_days': 42},
  {'name_en': 'PCV13-1', 'name_sw': 'PCV-1', 'age_label': '6 weeks', 'due_age_days': 42},
  {'name_en': 'Rotavirus-1', 'name_sw': 'Rota-1', 'age_label': '6 weeks', 'due_age_days': 42},
  {'name_en': 'DPT-HepB-Hib-2', 'name_sw': 'Penta-2', 'age_label': '10 weeks', 'due_age_days': 70},
  {'name_en': 'OPV-2', 'name_sw': 'OPV-2', 'age_label': '10 weeks', 'due_age_days': 70},
  {'name_en': 'PCV13-2', 'name_sw': 'PCV-2', 'age_label': '10 weeks', 'due_age_days': 70},
  {'name_en': 'Rotavirus-2', 'name_sw': 'Rota-2', 'age_label': '10 weeks', 'due_age_days': 70},
  {'name_en': 'DPT-HepB-Hib-3', 'name_sw': 'Penta-3', 'age_label': '14 weeks', 'due_age_days': 98},
  {'name_en': 'OPV-3', 'name_sw': 'OPV-3', 'age_label': '14 weeks', 'due_age_days': 98},
  {'name_en': 'PCV13-3', 'name_sw': 'PCV-3', 'age_label': '14 weeks', 'due_age_days': 98},
  {'name_en': 'IPV', 'name_sw': 'IPV', 'age_label': '14 weeks', 'due_age_days': 98},
  {'name_en': 'Vitamin A (1st)', 'name_sw': 'Vitamini A (1)', 'age_label': '6 months', 'due_age_days': 183},
  {'name_en': 'Measles-Rubella-1', 'name_sw': 'Surua-Rubela-1', 'age_label': '9 months', 'due_age_days': 274},
  {'name_en': 'OPV-4', 'name_sw': 'OPV-4', 'age_label': '9 months', 'due_age_days': 274},
  {'name_en': 'Vitamin A (2nd)', 'name_sw': 'Vitamini A (2)', 'age_label': '12 months', 'due_age_days': 365},
  {'name_en': 'Measles-Rubella-2', 'name_sw': 'Surua-Rubela-2', 'age_label': '15 months', 'due_age_days': 457},
  {'name_en': 'Vitamin A (3rd)', 'name_sw': 'Vitamini A (3)', 'age_label': '18 months', 'due_age_days': 548},
  {'name_en': 'DPT-HepB-Hib Booster', 'name_sw': 'Penta Booster', 'age_label': '18 months', 'due_age_days': 548},
];

class VaccinationPage extends StatefulWidget {
  final Baby baby;

  const VaccinationPage({super.key, required this.baby});

  @override
  State<VaccinationPage> createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage> {
  final MyBabyService _service = MyBabyService();
  final ImagePicker _picker = ImagePicker();
  String? _token;

  bool _isLoading = true;
  List<Vaccination> _vaccinations = [];

  // RCH card photo
  BabyPhoto? _rchCardPhoto;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadVaccinations();
    _loadRchCardPhoto();
  }

  Future<void> _loadVaccinations() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getVaccinationSchedule(_token!, widget.baby.id);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _vaccinations = result.items;
            // Fix 6: If API returns empty, generate from local Tanzania EPI schedule
            if (_vaccinations.isEmpty) {
              _vaccinations = _generateFromEPI(widget.baby);
            }
          } else {
            // Also fall back to EPI on failure
            _vaccinations = _generateFromEPI(widget.baby);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _vaccinations = _generateFromEPI(widget.baby);
        });
      }
    }
  }

  /// Generate vaccination objects from the hardcoded Tanzania EPI schedule.
  List<Vaccination> _generateFromEPI(Baby baby) {
    return _tanzaniaEPI.asMap().entries.map((entry) {
      final i = entry.key;
      final epi = entry.value;
      final dueAgeDays = epi['due_age_days'] as int;
      final dueDate = baby.dateOfBirth.add(Duration(days: dueAgeDays));
      return Vaccination(
        id: -(i + 1), // Negative IDs for local-only entries
        babyId: baby.id,
        name: epi['name_en'] as String,
        swahiliName: epi['name_sw'] as String,
        dueDate: dueDate,
        isDone: false,
        ageLabel: epi['age_label'] as String,
        dueAgeDays: dueAgeDays,
      );
    }).toList();
  }

  Future<void> _loadRchCardPhoto() async {
    if (_token == null) return;
    try {
      final result = await _service.getPhotos(_token!, widget.baby.id);
      if (!mounted) return;
      if (result.success) {
        final rchPhotos = result.items.where((p) => p.type == 'rch_card').toList();
        if (rchPhotos.isNotEmpty) {
          setState(() => _rchCardPhoto = rchPhotos.first);
        }
      }
    } catch (_) {
      // Silently fail — RCH card is optional
    }
  }

  Future<void> _snapRchCard() async {
    if (_token == null) return;
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final result = await _service.uploadPhoto(
        token: _token!,
        babyId: widget.baby.id,
        filePath: picked.path,
        type: 'rch_card',
      );

      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() => _rchCardPhoto = result.data);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kadi ya RCH imehifadhiwa!' : 'RCH card saved!')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
      );
    }
  }

  Future<void> _shareVaccinationRecord() async {
    final sw = _sw;
    final buffer = StringBuffer();
    buffer.writeln(sw
        ? 'REKODI YA CHANJO -- ${widget.baby.name}'
        : 'VACCINATION RECORD -- ${widget.baby.name}');
    buffer.writeln(sw
        ? 'Tarehe ya Kuzaliwa: ${_formatDate(widget.baby.dateOfBirth, sw)}'
        : 'Date of Birth: ${_formatDate(widget.baby.dateOfBirth, sw)}');
    buffer.writeln('');
    for (final v in _vaccinations) {
      final effectiveDate = v.effectiveDueDate(widget.baby.dateOfBirth);
      final String status;
      if (v.isDone) {
        status = '\u2705'; // check mark
      } else if (v.isOverdueWithDob(widget.baby.dateOfBirth)) {
        status = sw ? '\u26A0\uFE0F IMECHELEWA' : '\u26A0\uFE0F OVERDUE';
      } else {
        status = '\u23F3'; // hourglass
      }
      final dateInfo = v.isDone && v.givenDate != null
          ? (sw ? 'Imetolewa: ${_formatDate(v.givenDate!, sw)}' : 'Given: ${_formatDate(v.givenDate!, sw)}')
          : effectiveDate != null
              ? (sw ? 'Inatarajiwa: ${_formatDate(effectiveDate, sw)}' : 'Due: ${_formatDate(effectiveDate, sw)}')
              : '';
      final name = sw
          ? (v.swahiliName.isNotEmpty ? v.swahiliName : v.name)
          : v.name;
      buffer.writeln('$status $name -- $dateInfo');
    }
    buffer.writeln('');
    buffer.writeln(sw ? 'Kutoka TAJIRI' : 'Sent from TAJIRI');

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Future<void> _markDone(Vaccination vacc) async {
    if (_token == null) return;
    // Local-only vaccinations (negative IDs) can't be marked done via API
    if (vacc.id < 0) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Chanjo hii ni ya ndani — sajili mtoto kwenye seva kwanza'
            : 'This is a local schedule — register baby on server first')),
      );
      return;
    }
    final now = DateTime.now();
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _service.markVaccinationDone(_token!, vacc.id, now);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(sw
                  ? '${vacc.swahiliName.isNotEmpty ? vacc.swahiliName : vacc.name} imekamilika'
                  : '${vacc.name} completed')),
        );
        _loadVaccinations();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa kukamilisha chanjo' : 'Failed to complete vaccination'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(sw ? 'Kosa: $e' : 'Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final doneCount = _vaccinations.where((v) => v.isDone).length;
    final overdueCount =
        _vaccinations.where((v) => v.isOverdueWithDob(widget.baby.dateOfBirth)).length;
    final totalCount = _vaccinations.length;

    // Group vaccinations by age label
    // Fix 10: Use effectiveDueDate for display
    final grouped = <String, List<Vaccination>>{};
    for (final v in _vaccinations) {
      grouped.putIfAbsent(v.ageLabel, () => []).add(v);
    }

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
          sw ? 'Ratiba ya Chanjo' : 'Vaccination Schedule',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
        actions: [
          // RCH card camera button
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: _kPrimary),
            tooltip: sw ? 'Piga picha ya Kadi ya RCH' : 'Snap RCH Card',
            onPressed: _snapRchCard,
          ),
          // Share vaccination record button
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            tooltip: sw ? 'Shiriki rekodi' : 'Share record',
            onPressed: _vaccinations.isNotEmpty ? _shareVaccinationRecord : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadVaccinations,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                children: [
                  // RCH card photo (if available)
                  if (_rchCardPhoto != null) ...[
                    _buildRchCardPreview(sw),
                    const SizedBox(height: 12),
                  ],

                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              value: '$doneCount',
                              label: sw ? 'Zilizotolewa' : 'Given',
                              color: const Color(0xFF4CAF50),
                            ),
                            _SummaryItem(
                              value: '${totalCount - doneCount}',
                              label: sw ? 'Zilizobaki' : 'Remaining',
                              color: Colors.white,
                            ),
                            if (overdueCount > 0)
                              _SummaryItem(
                                value: '$overdueCount',
                                label: sw ? 'Zilizochelewa' : 'Overdue',
                                color: Colors.red.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalCount > 0
                                ? doneCount / totalCount
                                : 0,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: _kSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sw
                                ? 'Ratiba ya Chanjo ya Tanzania (EPI) - Hakikisha mtoto anapata chanjo zote kwa wakati.'
                                : 'Tanzania EPI Vaccination Schedule - Make sure your baby gets all vaccines on time.',
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_vaccinations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          sw
                              ? 'Ratiba ya chanjo itaonekana hapa baada ya kusajili mtoto.'
                              : 'The vaccination schedule will appear here after registering the baby.',
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // Grouped vaccination list
                  ...grouped.entries.map((entry) {
                    // Fix 10: Compute effective due date for the group header
                    final firstVacc = entry.value.first;
                    final effectiveGroupDate = firstVacc.effectiveDueDate(widget.baby.dateOfBirth);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8, top: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      _kPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (effectiveGroupDate != null)
                                Text(
                                  _formatDate(effectiveGroupDate, sw),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _kSecondary),
                                ),
                            ],
                          ),
                        ),
                        ...entry.value.map((vacc) => VaccinationCard(
                              vaccination: vacc,
                              isSwahili: sw,
                              onMarkDone: vacc.isDone
                                  ? null
                                  : () => _markDone(vacc),
                              babyDob: widget.baby.dateOfBirth,
                            )),
                      ],
                    );
                  }),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildRchCardPreview(bool sw) {
    return GestureDetector(
      onTap: _snapRchCard,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _rchCardPhoto!.displayUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade100,
                child: Icon(Icons.broken_image_rounded,
                    size: 32, color: Colors.grey.shade300),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: _kPrimary.withValues(alpha: 0.7),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      sw ? 'Kadi ya RCH' : 'RCH Card',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      sw ? 'Bonyeza kubadilisha' : 'Tap to update',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, bool sw) {
    const monthsSw = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final months = sw ? monthsSw : monthsEn;
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
