// lib/my_children/pages/doctor_sharing_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../doctor/models/doctor_models.dart';
import '../../doctor/services/doctor_service.dart';
import '../models/my_children_models.dart';
import '../services/my_children_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class DoctorSharingPage extends StatefulWidget {
  final Child child;
  final int userId;

  const DoctorSharingPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<DoctorSharingPage> createState() => _DoctorSharingPageState();
}

class _DoctorSharingPageState extends State<DoctorSharingPage> {
  final MyChildrenService _service = MyChildrenService();
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSearching = false;
  String? _token;

  // Share selections
  bool _shareVaccinations = true;
  bool _shareGrowth = true;
  bool _shareHealthLog = true;
  bool _shareEmergencyCard = true;

  // Loaded data
  List<Vaccination> _vaccinations = [];
  List<GrowthMeasurement> _growthHistory = [];
  List<HealthLog> _healthLogs = [];

  // Doctor search
  List<Doctor> _doctors = [];
  String? _generatedCode;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadHealthData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    if (_token == null) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getVaccinationSchedule(_token!, widget.child.id),
        _service.getGrowthHistory(_token!, widget.child.id),
        _service.getHealthHistory(_token!, widget.child.id),
      ]);
      if (!mounted) return;

      final vaccResult = results[0] as MyBabyListResult<Vaccination>;
      final growthResult = results[1] as MyBabyListResult<GrowthMeasurement>;
      final healthResult = results[2] as MyBabyListResult<HealthLog>;

      setState(() {
        _isLoading = false;
        if (vaccResult.success) _vaccinations = vaccResult.items;
        if (growthResult.success) _growthHistory = growthResult.items;
        if (healthResult.success) _healthLogs = healthResult.items;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw
              ? 'Imeshindikana kupakia data'
              : 'Failed to load health data')),
        );
      }
    }
  }

  Future<void> _generateShareCode() async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    setState(() => _isGenerating = true);

    try {
      final result = await _service.inviteCaregiver(
        token: _token!,
        babyId: widget.child.id,
        ownerUserId: widget.userId,
        role: 'doctor',
      );
      if (!mounted) return;
      setState(() => _isGenerating = false);

      if (result.success && result.data != null) {
        setState(() => _generatedCode = result.data!.inviteCode);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kutengeneza msimbo' : 'Failed to generate code'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _searchDoctors(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _doctors = []);
      return;
    }
    setState(() => _isSearching = true);

    try {
      final result = await _doctorService.findDoctors(search: query.trim());
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        if (result.success) _doctors = result.items;
      });
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  String _buildShareText() {
    final sw = _sw;
    final child = widget.child;
    final buf = StringBuffer();

    buf.writeln(sw ? 'REKODI ZA AFYA YA MTOTO' : 'CHILD HEALTH RECORDS');
    buf.writeln('=' * 35);
    buf.writeln('${sw ? 'Jina' : 'Name'}: ${child.name}');

    final age = child.ageLabelLocalized(isSwahili: sw);
    buf.writeln('${sw ? 'Umri' : 'Age'}: $age');

    if (child.bloodType != null && child.bloodType!.isNotEmpty) {
      buf.writeln('${sw ? 'Kundi la damu' : 'Blood Type'}: ${child.bloodType}');
    }
    if (child.allergies.isNotEmpty) {
      buf.writeln('${sw ? 'Mizio' : 'Allergies'}: ${child.allergies.join(', ')}');
    }
    buf.writeln();

    if (_shareVaccinations && _vaccinations.isNotEmpty) {
      buf.writeln(sw ? 'CHANJO' : 'VACCINATIONS');
      buf.writeln('-' * 20);
      final recent = _vaccinations
          .where((v) => v.isDone)
          .toList()
        ..sort((a, b) => (b.givenDate ?? DateTime(2000))
            .compareTo(a.givenDate ?? DateTime(2000)));
      final show = recent.take(5);
      for (final v in show) {
        final date = v.givenDate != null
            ? '${v.givenDate!.day}/${v.givenDate!.month}/${v.givenDate!.year}'
            : '-';
        buf.writeln('  ${sw ? v.swahiliName : v.name} - $date');
      }
      final overdue = _vaccinations.where((v) => v.isOverdue).toList();
      if (overdue.isNotEmpty) {
        buf.writeln(sw ? '  ZIMECHELEWA: ${overdue.length}' : '  OVERDUE: ${overdue.length}');
        for (final v in overdue.take(3)) {
          buf.writeln('    - ${sw ? v.swahiliName : v.name}');
        }
      }
      buf.writeln();
    }

    if (_shareGrowth && _growthHistory.isNotEmpty) {
      buf.writeln(sw ? 'VIPIMO VYA UKUAJI' : 'GROWTH MEASUREMENTS');
      buf.writeln('-' * 20);
      final sorted = List<GrowthMeasurement>.from(_growthHistory)
        ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
      final latest = sorted.first;
      if (latest.weightKg != null) {
        buf.writeln('  ${sw ? 'Uzito' : 'Weight'}: ${latest.weightKg!.toStringAsFixed(1)} kg');
      }
      if (latest.heightCm != null) {
        buf.writeln('  ${sw ? 'Urefu' : 'Height'}: ${latest.heightCm!.toStringAsFixed(1)} cm');
      }
      if (latest.headCm != null) {
        buf.writeln('  ${sw ? 'Kichwa' : 'Head'}: ${latest.headCm!.toStringAsFixed(1)} cm');
      }
      final date = '${latest.measuredAt.day}/${latest.measuredAt.month}/${latest.measuredAt.year}';
      buf.writeln('  ${sw ? 'Tarehe' : 'Date'}: $date');
      buf.writeln();
    }

    if (_shareHealthLog && _healthLogs.isNotEmpty) {
      buf.writeln(sw ? 'REKODI ZA AFYA' : 'HEALTH LOG');
      buf.writeln('-' * 20);
      final sorted = List<HealthLog>.from(_healthLogs)
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      for (final h in sorted.take(5)) {
        final date = '${h.loggedAt.day}/${h.loggedAt.month}/${h.loggedAt.year}';
        buf.writeln('  ${h.title} (${h.type}) - $date');
        if (h.value != null) buf.writeln('    ${h.value}');
      }
      buf.writeln();
    }

    if (_shareEmergencyCard) {
      buf.writeln(sw ? 'MAWASILIANO YA DHARURA' : 'EMERGENCY CONTACTS');
      buf.writeln('-' * 20);
      if (child.emergencyContacts.isNotEmpty) {
        for (final c in child.emergencyContacts) {
          final name = c['name'] ?? '';
          final phone = c['phone'] ?? '';
          final relation = c['relation'] ?? c['relationship'] ?? '';
          buf.writeln('  $name ($relation): $phone');
        }
      } else {
        buf.writeln(sw ? '  Hakuna mawasiliano ya dharura' : '  No emergency contacts set');
      }
      buf.writeln();
    }

    buf.writeln(sw
        ? 'Imetolewa na TAJIRI - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
        : 'Generated by TAJIRI - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');

    return buf.toString();
  }

  void _shareWithDoctor() {
    if (!_shareVaccinations && !_shareGrowth && !_shareHealthLog && !_shareEmergencyCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Chagua angalau kitu kimoja kushiriki'
            : 'Select at least one item to share')),
      );
      return;
    }
    final text = _buildShareText();
    SharePlus.instance.share(ShareParams(text: text));
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
          sw ? 'Shiriki na Daktari' : 'Share with Doctor',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSelectionSection(sw),
                const SizedBox(height: 20),
                _buildShareAsTextSection(sw),
                const SizedBox(height: 20),
                _buildShareCodeSection(sw),
                const SizedBox(height: 20),
                _buildDoctorSearchSection(sw),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ─── Selection Checkboxes ──────────────────────────────────────

  Widget _buildSelectionSection(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Chagua nini kushiriki' : 'Select what to share',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            sw
                ? 'Chagua rekodi za afya unazotaka daktari aone'
                : 'Choose which health records the doctor should see',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _ShareCheckbox(
            label: sw ? 'Rekodi za chanjo' : 'Vaccination record',
            subtitle: sw
                ? 'Chanjo ${_vaccinations.where((v) => v.isDone).length} zilizopewa'
                : '${_vaccinations.where((v) => v.isDone).length} vaccinations given',
            icon: Icons.vaccines_rounded,
            value: _shareVaccinations,
            onChanged: (v) => setState(() => _shareVaccinations = v ?? true),
          ),
          _ShareCheckbox(
            label: sw ? 'Vipimo vya ukuaji' : 'Growth measurements',
            subtitle: sw
                ? 'Vipimo ${_growthHistory.length}'
                : '${_growthHistory.length} measurements',
            icon: Icons.show_chart_rounded,
            value: _shareGrowth,
            onChanged: (v) => setState(() => _shareGrowth = v ?? true),
          ),
          _ShareCheckbox(
            label: sw ? 'Rekodi za afya' : 'Health log',
            subtitle: sw
                ? 'Magonjwa, dawa, mizio'
                : 'Illnesses, medications, allergies',
            icon: Icons.health_and_safety_rounded,
            value: _shareHealthLog,
            onChanged: (v) => setState(() => _shareHealthLog = v ?? true),
          ),
          _ShareCheckbox(
            label: sw ? 'Kadi ya dharura' : 'Emergency card info',
            subtitle: sw
                ? 'Mawasiliano ya dharura, mizio'
                : 'Emergency contacts, allergies',
            icon: Icons.emergency_rounded,
            value: _shareEmergencyCard,
            onChanged: (v) => setState(() => _shareEmergencyCard = v ?? true),
          ),
        ],
      ),
    );
  }

  // ─── Share as Text ─────────────────────────────────────────────

  Widget _buildShareAsTextSection(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Shiriki kama maandishi' : 'Share as text summary',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            sw
                ? 'Tuma muhtasari wa afya kupitia WhatsApp, SMS, n.k.'
                : 'Send a health summary via WhatsApp, SMS, etc.',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _shareWithDoctor,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text(
                sw ? 'Shiriki muhtasari' : 'Share summary',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Share Code ────────────────────────────────────────────────

  Widget _buildShareCodeSection(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Tengeneza msimbo wa ufikivu' : 'Generate access code',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            sw
                ? 'Msimbo wa muda mfupi kwa daktari kuona rekodi'
                : 'Time-limited code for doctor to view records',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (_generatedCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    sw ? 'Msimbo wa daktari' : 'Doctor access code',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _generatedCode!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sw ? 'Unaisha baada ya saa 24' : 'Valid for 24 hours',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generateShareCode,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kPrimary))
                    : const Icon(Icons.qr_code_rounded, size: 18),
                label: Text(
                  sw ? 'Tengeneza msimbo' : 'Generate code',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Doctor Search ─────────────────────────────────────────────

  Widget _buildDoctorSearchSection(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Tafuta daktari' : 'Search for doctor',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            sw
                ? 'Tafuta daktari aliyesajiliwa na utume rekodi moja kwa moja'
                : 'Find a registered doctor and send records directly',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onSubmitted: _searchDoctors,
            decoration: InputDecoration(
              hintText: sw ? 'Andika jina la daktari' : 'Type doctor name',
              hintStyle: TextStyle(color: _kSecondary.withValues(alpha: 0.5)),
              filled: true,
              fillColor: _kPrimary.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixIcon: IconButton(
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kPrimary))
                    : const Icon(Icons.search_rounded, color: _kSecondary),
                onPressed: () => _searchDoctors(_searchController.text),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: _kPrimary),
          ),
          if (_doctors.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._doctors.take(5).map((doc) => _DoctorTile(
                  doctor: doc,
                  isSwahili: sw,
                  onSend: () => _sendToDoctor(doc),
                )),
          ],
        ],
      ),
    );
  }

  void _sendToDoctor(Doctor doctor) {
    final sw = _sw;
    final text = _buildShareText();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Shiriki na Dkt. ${doctor.fullName}' : 'Share with Dr. ${doctor.fullName}'),
        content: Text(sw
            ? 'Fungua menyu ya kushiriki ili kutuma rekodi za afya kwa daktari huyu.'
            : 'This will open the share menu so you can send health records to this doctor via WhatsApp, SMS, or email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SharePlus.instance.share(ShareParams(text: text));
            },
            child: Text(sw ? 'Shiriki' : 'Share',
                style: const TextStyle(
                    color: _kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Share Checkbox ──────────────────────────────────────────────

class _ShareCheckbox extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ShareCheckbox({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, size: 20, color: _kSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Doctor Tile ─────────────────────────────────────────────────

class _DoctorTile extends StatelessWidget {
  final Doctor doctor;
  final bool isSwahili;
  final VoidCallback onSend;

  const _DoctorTile({
    required this.doctor,
    required this.isSwahili,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            backgroundImage: doctor.profilePhotoUrl != null
                ? NetworkImage(doctor.profilePhotoUrl!)
                : null,
            child: doctor.profilePhotoUrl == null
                ? const Icon(Icons.medical_services_rounded,
                    color: _kSecondary, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${doctor.fullName}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  doctor.hospital ?? doctor.specialty.name,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: onSend,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isSwahili ? 'Tuma' : 'Send',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
