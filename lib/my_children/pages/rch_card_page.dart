// lib/my_children/pages/rch_card_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../doctor/doctor_module.dart';
import '../../insurance/insurance_module.dart';
import '../models/my_children_models.dart';
import '../services/my_children_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class RchCardPage extends StatefulWidget {
  final Child child;

  const RchCardPage({super.key, required this.child});

  @override
  State<RchCardPage> createState() => _RchCardPageState();
}

class _RchCardPageState extends State<RchCardPage> {
  final MyChildrenService _service = MyChildrenService();
  String? _token;
  bool _isLoading = true;

  List<Vaccination> _vaccinations = [];
  List<GrowthMeasurement> _growthHistory = [];
  List<HealthLog> _healthHistory = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getVaccinationSchedule(_token!, widget.child.id),
        _service.getGrowthHistory(_token!, widget.child.id),
        _service.getHealthHistory(_token!, widget.child.id),
      ]);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        final vaccResult = results[0] as MyBabyListResult<Vaccination>;
        if (vaccResult.success) _vaccinations = vaccResult.items;

        final growthResult = results[1] as MyBabyListResult<GrowthMeasurement>;
        if (growthResult.success) {
          _growthHistory = growthResult.items;
          _growthHistory.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
        }

        final healthResult = results[2] as MyBabyListResult<HealthLog>;
        if (healthResult.success) _healthHistory = healthResult.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindikana kupakia' : 'Failed to load')),
      );
    }
  }

  String _buildShareText() {
    final c = widget.child;
    final sw = _sw;
    final buf = StringBuffer();

    // Header
    buf.writeln('═══════════════════════════════════');
    buf.writeln(sw ? '  KADI YA RCH (DIJITALI)' : '  DIGITAL RCH CARD');
    buf.writeln('═══════════════════════════════════');
    buf.writeln();

    // Child profile
    buf.writeln(sw ? '── TAARIFA ZA MTOTO ──' : '── CHILD PROFILE ──');
    buf.writeln('${sw ? 'Jina' : 'Name'}: ${c.name}');
    buf.writeln('${sw ? 'Tarehe ya Kuzaliwa' : 'Date of Birth'}: '
        '${c.dateOfBirth.day}/${c.dateOfBirth.month}/${c.dateOfBirth.year}');
    buf.writeln('${sw ? 'Umri' : 'Age'}: ${c.ageLabelLocalized(isSwahili: sw)}');
    if (c.gender != null) {
      final g = c.gender!.toLowerCase() == 'male'
          ? (sw ? 'Mvulana' : 'Male')
          : (sw ? 'Msichana' : 'Female');
      buf.writeln('${sw ? 'Jinsi' : 'Gender'}: $g');
    }
    if (c.bloodType != null && c.bloodType!.isNotEmpty) {
      buf.writeln('${sw ? 'Kundi la Damu' : 'Blood Type'}: ${c.bloodType}');
    }
    buf.writeln();

    // Vaccinations
    buf.writeln(sw ? '── CHANJO ──' : '── VACCINATIONS ──');
    final givenVacc = _vaccinations.where((v) => v.isDone).toList();
    final pendingVacc = _vaccinations.where((v) => !v.isDone).toList();
    if (givenVacc.isEmpty && pendingVacc.isEmpty) {
      buf.writeln(sw ? 'Hakuna rekodi za chanjo' : 'No vaccination records');
    } else {
      for (final v in givenVacc) {
        final name = sw ? v.swahiliName : v.name;
        final dateStr = v.givenDate != null
            ? '${v.givenDate!.day}/${v.givenDate!.month}/${v.givenDate!.year}'
            : (sw ? 'Tarehe haijulikani' : 'Date unknown');
        buf.writeln('  [x] $name - $dateStr');
      }
      for (final v in pendingVacc) {
        final name = sw ? v.swahiliName : v.name;
        final dueStr = v.dueDate != null
            ? '${sw ? 'Inatarajiwa' : 'Due'}: ${v.dueDate!.day}/${v.dueDate!.month}/${v.dueDate!.year}'
            : '';
        buf.writeln('  [ ] $name $dueStr');
      }
    }
    buf.writeln();

    // Growth
    buf.writeln(sw ? '── UKUAJI ──' : '── GROWTH ──');
    if (_growthHistory.isEmpty) {
      buf.writeln(sw ? 'Hakuna vipimo' : 'No measurements');
    } else {
      final latest = _growthHistory.last;
      if (latest.weightKg != null) {
        buf.writeln('${sw ? 'Uzito' : 'Weight'}: ${latest.weightKg!.toStringAsFixed(1)} kg');
      }
      if (latest.heightCm != null) {
        buf.writeln('${sw ? 'Urefu' : 'Height'}: ${latest.heightCm!.toStringAsFixed(1)} cm');
      }
      if (latest.headCm != null) {
        buf.writeln('${sw ? 'Kichwa' : 'Head'}: ${latest.headCm!.toStringAsFixed(1)} cm');
      }
      buf.writeln('${sw ? 'Tarehe' : 'Date'}: '
          '${latest.measuredAt.day}/${latest.measuredAt.month}/${latest.measuredAt.year}');
    }
    buf.writeln();

    // Health summary
    buf.writeln(sw ? '── MUHTASARI WA AFYA ──' : '── HEALTH SUMMARY ──');
    if (c.allergies.isNotEmpty) {
      buf.writeln('${sw ? 'Mzio' : 'Allergies'}: ${c.allergies.join(', ')}');
    }
    final conditions = _healthHistory
        .where((h) => h.type == 'illness' || h.type == 'allergy')
        .toList();
    if (conditions.isNotEmpty) {
      buf.writeln(sw ? 'Hali za Kiafya:' : 'Health Conditions:');
      for (final h in conditions.take(5)) {
        buf.writeln('  - ${h.title}');
      }
    }
    final visits = _healthHistory
        .where((h) => h.type == 'doctor_visit')
        .toList();
    if (visits.isNotEmpty) {
      buf.writeln(sw ? 'Ziara za Daktari:' : 'Doctor Visits:');
      for (final v in visits.take(3)) {
        buf.writeln('  - ${v.title} (${v.loggedAt.day}/${v.loggedAt.month}/${v.loggedAt.year})');
      }
    }

    buf.writeln();
    buf.writeln('═══════════════════════════════════');
    buf.writeln(sw ? 'Imetolewa na TAJIRI' : 'Generated by TAJIRI');
    buf.writeln('═══════════════════════════════════');
    return buf.toString();
  }

  Future<void> _shareCard() async {
    try {
      final text = _buildShareText();
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindwa kushiriki' : 'Failed to share')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Kadi ya RCH' : 'Digital RCH Card',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            tooltip: sw ? 'Shiriki Kadi' : 'Share Card',
            onPressed: _isLoading ? null : _shareCard,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadAllData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(sw),
                    const SizedBox(height: 16),
                    _buildChildProfile(sw),
                    const SizedBox(height: 16),
                    _buildVaccinationSection(sw),
                    const SizedBox(height: 16),
                    _buildGrowthSection(sw),
                    const SizedBox(height: 16),
                    _buildHealthSummary(sw),

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
                      icon: Icons.local_hospital_rounded,
                      label: sw
                          ? 'Shiriki kadi na daktari kabla ya miadi'
                          : 'Share card with doctor before appointment',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DoctorModule(userId: widget.child.userId))),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.verified_user_rounded,
                      label: sw
                          ? 'Angalia bima ya afya'
                          : 'Check insurance coverage',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => InsuranceModule(userId: widget.child.userId))),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw
                      ? 'Kadi ya Afya ya Uzazi na Mtoto'
                      : 'Reproductive & Child Health Card',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sw ? 'Kadi ya Dijitali' : 'Digital Health Card',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
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

  Widget _buildChildProfile(bool sw) {
    final c = widget.child;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(sw ? 'Taarifa za Mtoto' : 'Child Profile', Icons.person_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              // Photo placeholder
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: c.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          c.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx2, err, st) => const Icon(
                              Icons.child_care_rounded,
                              size: 32,
                              color: _kTertiary),
                        ),
                      )
                    : const Icon(Icons.child_care_rounded,
                        size: 32, color: _kTertiary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.ageLabelLocalized(isSwahili: sw),
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: _kTertiary),
          _infoRow(
            sw ? 'Tarehe ya Kuzaliwa' : 'Date of Birth',
            '${c.dateOfBirth.day}/${c.dateOfBirth.month}/${c.dateOfBirth.year}',
          ),
          if (c.gender != null)
            _infoRow(
              sw ? 'Jinsi' : 'Gender',
              c.gender!.toLowerCase() == 'male'
                  ? (sw ? 'Mvulana' : 'Male')
                  : (sw ? 'Msichana' : 'Female'),
            ),
          if (c.bloodType != null && c.bloodType!.isNotEmpty)
            _infoRow(sw ? 'Kundi la Damu' : 'Blood Type', c.bloodType!),
          if (c.birthWeightGrams != null)
            _infoRow(
              sw ? 'Uzito wa Kuzaliwa' : 'Birth Weight',
              '${(c.birthWeightGrams! / 1000).toStringAsFixed(2)} kg',
            ),
          if (c.birthLengthCm != null)
            _infoRow(
              sw ? 'Urefu wa Kuzaliwa' : 'Birth Length',
              '${c.birthLengthCm!.toStringAsFixed(1)} cm',
            ),
        ],
      ),
    );
  }

  Widget _buildVaccinationSection(bool sw) {
    final given = _vaccinations.where((v) => v.isDone).toList();
    final pending = _vaccinations.where((v) => !v.isDone).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(sw ? 'Chanjo' : 'Vaccinations', Icons.vaccines_rounded),
          const SizedBox(height: 8),
          // Summary row
          Row(
            children: [
              _statChip(
                '${given.length}',
                sw ? 'Zilizopewa' : 'Given',
                _kPrimary,
              ),
              const SizedBox(width: 8),
              _statChip(
                '${pending.length}',
                sw ? 'Zinasubiri' : 'Pending',
                _kSecondary,
              ),
            ],
          ),
          if (given.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...given.map((v) => _vaccRow(v, sw, true)),
          ],
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              sw ? 'Zinasubiri:' : 'Pending:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ...pending.take(5).map((v) => _vaccRow(v, sw, false)),
            if (pending.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  sw
                      ? '+${pending.length - 5} zaidi'
                      : '+${pending.length - 5} more',
                  style: const TextStyle(fontSize: 12, color: _kTertiary),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _vaccRow(Vaccination v, bool sw, bool done) {
    final name = sw ? v.swahiliName : v.name;
    final displayName = name.isNotEmpty ? name : (sw ? v.name : v.swahiliName);
    String? dateStr;
    if (done && v.givenDate != null) {
      dateStr = '${v.givenDate!.day}/${v.givenDate!.month}/${v.givenDate!.year}';
    } else if (!done && v.dueDate != null) {
      dateStr = '${sw ? 'Inatarajiwa' : 'Due'}: '
          '${v.dueDate!.day}/${v.dueDate!.month}/${v.dueDate!.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: done ? _kPrimary : _kTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (dateStr != null)
            Text(
              dateStr,
              style: const TextStyle(fontSize: 11, color: _kTertiary),
            ),
        ],
      ),
    );
  }

  Widget _buildGrowthSection(bool sw) {
    final latest = _growthHistory.isNotEmpty ? _growthHistory.last : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(sw ? 'Ukuaji' : 'Growth', Icons.show_chart_rounded),
          const SizedBox(height: 12),
          if (latest == null)
            Text(
              sw ? 'Hakuna vipimo bado' : 'No measurements yet',
              style: const TextStyle(fontSize: 13, color: _kTertiary),
            )
          else ...[
            Row(
              children: [
                if (latest.weightKg != null)
                  Expanded(
                    child: _growthMetric(
                      sw ? 'Uzito' : 'Weight',
                      '${latest.weightKg!.toStringAsFixed(1)} kg',
                      Icons.monitor_weight_rounded,
                    ),
                  ),
                if (latest.heightCm != null)
                  Expanded(
                    child: _growthMetric(
                      sw ? 'Urefu' : 'Height',
                      '${latest.heightCm!.toStringAsFixed(1)} cm',
                      Icons.height_rounded,
                    ),
                  ),
                if (latest.headCm != null)
                  Expanded(
                    child: _growthMetric(
                      sw ? 'Kichwa' : 'Head',
                      '${latest.headCm!.toStringAsFixed(1)} cm',
                      Icons.circle_outlined,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // BMI for children 2+
            if (widget.child.ageInYears >= 2 &&
                latest.weightKg != null &&
                latest.heightCm != null &&
                latest.heightCm! > 0) ...[
              Builder(builder: (_) {
                final hm = latest.heightCm! / 100;
                final bmi = latest.weightKg! / (hm * hm);
                return _infoRow('BMI', bmi.toStringAsFixed(1));
              }),
            ],
            Text(
              '${sw ? 'Kipimo cha mwisho' : 'Last measured'}: '
              '${latest.measuredAt.day}/${latest.measuredAt.month}/${latest.measuredAt.year}',
              style: const TextStyle(fontSize: 11, color: _kTertiary),
            ),
          ],
          if (_growthHistory.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              sw
                  ? 'Jumla ya vipimo: ${_growthHistory.length}'
                  : 'Total measurements: ${_growthHistory.length}',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _growthMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 22, color: _kPrimary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _kSecondary),
        ),
      ],
    );
  }

  Widget _buildHealthSummary(bool sw) {
    final allergies = widget.child.allergies;
    final conditions = _healthHistory
        .where((h) => h.type == 'illness' || h.type == 'allergy')
        .toList();
    final visits = _healthHistory
        .where((h) => h.type == 'doctor_visit')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            sw ? 'Muhtasari wa Afya' : 'Health Summary',
            Icons.health_and_safety_rounded,
          ),
          const SizedBox(height: 12),

          // Allergies
          Text(
            sw ? 'Mzio' : 'Allergies',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (allergies.isEmpty)
            Text(
              sw ? 'Hakuna mzio uliorekodiwa' : 'No allergies recorded',
              style: const TextStyle(fontSize: 12, color: _kTertiary),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: allergies
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          a,
                          style: const TextStyle(fontSize: 12, color: _kPrimary),
                        ),
                      ))
                  .toList(),
            ),

          if (conditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              sw ? 'Hali za Kiafya' : 'Health Conditions',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ...conditions.take(5).map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(h.icon, size: 14, color: _kSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          h.title,
                          style: const TextStyle(fontSize: 12, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (visits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              sw ? 'Ziara za Hivi Karibuni' : 'Recent Doctor Visits',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ...visits.take(3).map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded,
                          size: 14, color: _kSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          v.title,
                          style: const TextStyle(fontSize: 12, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${v.loggedAt.day}/${v.loggedAt.month}/${v.loggedAt.year}',
                        style: const TextStyle(fontSize: 11, color: _kTertiary),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
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

  // ─── Shared Widgets ──────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
