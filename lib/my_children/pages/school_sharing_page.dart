// lib/my_children/pages/school_sharing_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../services/my_children_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SchoolSharingPage extends StatefulWidget {
  final Child child;
  final int userId;

  const SchoolSharingPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<SchoolSharingPage> createState() => _SchoolSharingPageState();
}

class _SchoolSharingPageState extends State<SchoolSharingPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = false;
  String? _token;

  // Share selections
  bool _shareEnrollment = true;
  bool _shareHealthSummary = true;
  bool _shareVaccinationStatus = true;
  bool _shareEmergencyCard = true;

  // Loaded data
  List<Vaccination> _vaccinations = [];
  List<HealthLog> _healthLogs = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_token == null) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getVaccinationSchedule(_token!, widget.child.id),
        _service.getHealthHistory(_token!, widget.child.id),
      ]);
      if (!mounted) return;

      final vaccResult = results[0] as MyBabyListResult<Vaccination>;
      final healthResult = results[1] as MyBabyListResult<HealthLog>;

      setState(() {
        _isLoading = false;
        if (vaccResult.success) _vaccinations = vaccResult.items;
        if (healthResult.success) _healthLogs = healthResult.items;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw
              ? 'Imeshindikana kupakia data'
              : 'Failed to load data')),
        );
      }
    }
  }

  String _buildSchoolFormText() {
    final sw = _sw;
    final child = widget.child;
    final buf = StringBuffer();

    buf.writeln(sw
        ? 'TAARIFA ZA AFYA NA DHARURA ZA MWANAFUNZI'
        : 'STUDENT HEALTH & EMERGENCY INFORMATION');
    buf.writeln('=' * 40);

    if (_shareEnrollment) {
      buf.writeln('${sw ? 'Mwanafunzi' : 'Student'}: ${child.name}');
      if (child.grade != null && child.grade!.isNotEmpty) {
        buf.writeln('${sw ? 'Darasa' : 'Grade'}: ${child.grade}');
      }
      if (child.schoolName != null && child.schoolName!.isNotEmpty) {
        buf.writeln('${sw ? 'Shule' : 'School'}: ${child.schoolName}');
      }
      final dob = child.dateOfBirth;
      buf.writeln(
          '${sw ? 'Tarehe ya kuzaliwa' : 'Date of Birth'}: ${dob.day}/${dob.month}/${dob.year}');
      if (child.gender != null) {
        final g = sw
            ? (child.gender == 'male' ? 'Me' : 'Ke')
            : (child.gender == 'male' ? 'Male' : 'Female');
        buf.writeln('${sw ? 'Jinsia' : 'Gender'}: $g');
      }
      if (child.bloodType != null && child.bloodType!.isNotEmpty) {
        buf.writeln('${sw ? 'Kundi la damu' : 'Blood Type'}: ${child.bloodType}');
      }
      buf.writeln();
    }

    if (_shareHealthSummary) {
      buf.writeln(sw ? 'TAARIFA ZA AFYA' : 'HEALTH INFORMATION');
      buf.writeln('-' * 25);

      // Allergies
      if (child.allergies.isNotEmpty) {
        buf.writeln('${sw ? 'MIZIO' : 'ALLERGIES'}: ${child.allergies.join(', ')}');
      } else {
        buf.writeln(sw ? 'MIZIO: Hakuna zilizorekodiwa' : 'ALLERGIES: None recorded');
      }

      // Chronic conditions from health logs
      final chronicEntries = _healthLogs
          .where((h) => h.type == 'illness' || h.type == 'allergy')
          .toList();
      if (chronicEntries.isNotEmpty) {
        buf.writeln(sw ? 'HALI ZA KIAFYA:' : 'MEDICAL CONDITIONS:');
        for (final h in chronicEntries.take(5)) {
          buf.writeln('  - ${h.title}');
          if (h.description != null && h.description!.isNotEmpty) {
            buf.writeln('    ${h.description}');
          }
        }
      }

      // Current medications
      final medications = _healthLogs
          .where((h) => h.type == 'medication')
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      if (medications.isNotEmpty) {
        buf.writeln(sw ? 'DAWA ZA SASA:' : 'CURRENT MEDICATIONS:');
        for (final m in medications.take(3)) {
          buf.writeln('  - ${m.title}${m.value != null ? ' (${m.value})' : ''}');
        }
      }
      buf.writeln();
    }

    if (_shareVaccinationStatus) {
      buf.writeln(sw ? 'HALI YA CHANJO' : 'VACCINATION STATUS');
      buf.writeln('-' * 25);

      final overdue = _vaccinations.where((v) => v.isOverdue).toList();
      final completed = _vaccinations.where((v) => v.isDone).toList();

      if (overdue.isEmpty) {
        buf.writeln(sw
            ? 'Hali: Chanjo zote zimekamilika'
            : 'Status: Up to date');
      } else {
        buf.writeln(sw
            ? 'Hali: Zimechelewa (${overdue.length})'
            : 'Status: Overdue (${overdue.length})');
        for (final v in overdue) {
          buf.writeln('  - ${sw ? v.swahiliName : v.name}');
        }
      }
      buf.writeln(sw
          ? 'Jumla zilizopewa: ${completed.length}'
          : 'Total given: ${completed.length}');
      buf.writeln();
    }

    if (_shareEmergencyCard) {
      buf.writeln(sw ? 'MAWASILIANO YA DHARURA' : 'EMERGENCY CONTACTS');
      buf.writeln('-' * 25);
      if (child.emergencyContacts.isNotEmpty) {
        for (final c in child.emergencyContacts) {
          final name = c['name'] ?? '';
          final phone = c['phone'] ?? '';
          final relation = c['relation'] ?? c['relationship'] ?? '';
          buf.writeln('  $name ($relation): $phone');
        }
      } else {
        buf.writeln(sw
            ? '  Hakuna mawasiliano ya dharura yaliyowekwa'
            : '  No emergency contacts set');
      }

      // Insurance info
      if (child.insuranceNumber != null && child.insuranceNumber!.isNotEmpty) {
        buf.writeln();
        buf.writeln(sw
            ? 'Namba ya bima: ${child.insuranceNumber}'
            : 'Insurance #: ${child.insuranceNumber}');
      }
      if (child.nhifStatus != null && child.nhifStatus!.isNotEmpty) {
        buf.writeln('NHIF: ${child.nhifStatus}');
      }
      buf.writeln();
    }

    buf.writeln(sw
        ? 'Imetolewa na TAJIRI - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
        : 'Generated by TAJIRI - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');

    return buf.toString();
  }

  void _shareWithSchool() {
    if (!_shareEnrollment &&
        !_shareHealthSummary &&
        !_shareVaccinationStatus &&
        !_shareEmergencyCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Chagua angalau kitu kimoja kushiriki'
            : 'Select at least one item to share')),
      );
      return;
    }
    final text = _buildSchoolFormText();
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
          sw ? 'Shiriki na Shule' : 'Share with School',
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
                _buildPreviewHeader(sw),
                const SizedBox(height: 16),
                _buildSelectionSection(sw),
                const SizedBox(height: 20),
                _buildShareButton(sw),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ─── Preview Header ────────────────────────────────────────────

  Widget _buildPreviewHeader(bool sw) {
    final child = widget.child;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (child.schoolName != null) child.schoolName!,
                    if (child.grade != null) child.grade!,
                  ].join(' - '),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7)),
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
                ? 'Chagua taarifa za mtoto kushiriki na shule'
                : 'Choose child information to share with school',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _ShareCheckbox(
            label: sw ? 'Taarifa za usajili' : 'Enrollment info',
            subtitle: sw
                ? 'Jina, darasa, tarehe ya kuzaliwa'
                : 'Name, grade, date of birth',
            icon: Icons.badge_rounded,
            value: _shareEnrollment,
            onChanged: (v) => setState(() => _shareEnrollment = v ?? true),
          ),
          _ShareCheckbox(
            label: sw ? 'Muhtasari wa afya' : 'Health summary',
            subtitle: sw
                ? 'Mizio, hali za kiafya, dawa'
                : 'Allergies, conditions, medications',
            icon: Icons.health_and_safety_rounded,
            value: _shareHealthSummary,
            onChanged: (v) => setState(() => _shareHealthSummary = v ?? true),
          ),
          _ShareCheckbox(
            label: sw ? 'Hali ya chanjo' : 'Vaccination status',
            subtitle: sw
                ? _vaccinations.where((v) => v.isOverdue).isEmpty
                    ? 'Chanjo zote zimekamilika'
                    : 'Zimechelewa ${_vaccinations.where((v) => v.isOverdue).length}'
                : _vaccinations.where((v) => v.isOverdue).isEmpty
                    ? 'Up to date'
                    : 'Overdue ${_vaccinations.where((v) => v.isOverdue).length}',
            icon: Icons.vaccines_rounded,
            value: _shareVaccinationStatus,
            onChanged: (v) =>
                setState(() => _shareVaccinationStatus = v ?? true),
          ),
          _ShareCheckbox(
            label: sw ? 'Kadi ya dharura' : 'Emergency card',
            subtitle: sw
                ? 'Mawasiliano ya dharura, bima'
                : 'Emergency contacts, insurance',
            icon: Icons.emergency_rounded,
            value: _shareEmergencyCard,
            onChanged: (v) => setState(() => _shareEmergencyCard = v ?? true),
          ),
        ],
      ),
    );
  }

  // ─── Share Button ──────────────────────────────────────────────

  Widget _buildShareButton(bool sw) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _shareWithSchool,
        icon: const Icon(Icons.share_rounded, size: 20),
        label: Text(
          sw ? 'Shiriki na shule' : 'Share with school',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
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
