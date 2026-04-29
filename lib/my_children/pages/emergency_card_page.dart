// lib/my_children/pages/emergency_card_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../insurance/insurance_module.dart';
import '../../insurance/services/insurance_service.dart';
import '../../insurance/models/insurance_models.dart';
import '../../services/local_storage_service.dart';
import '../../doctor/doctor_module.dart';
import '../models/my_children_models.dart';
import '../services/my_children_service.dart';
import 'school_sharing_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmergencyCardPage extends StatefulWidget {
  final Child child;

  const EmergencyCardPage({super.key, required this.child});

  @override
  State<EmergencyCardPage> createState() => _EmergencyCardPageState();
}

class _EmergencyCardPageState extends State<EmergencyCardPage> {
  final MyChildrenService _service = MyChildrenService();
  final InsuranceService _insuranceService = InsuranceService();
  String? _token;
  bool _isLoading = true;
  bool _isSaving = false;

  // Card fields
  String _bloodType = '';
  List<String> _allergies = [];
  List<String> _chronicConditions = [];
  List<String> _medications = [];
  List<Map<String, String>> _emergencyContacts = [];
  String _insuranceNumber = '';
  String _doctorName = '';
  String _doctorPhone = '';
  String? _shareCode;

  // Insurance coverage from InsuranceService
  bool _insuranceLoading = false;
  InsurancePolicy? _activeHealthPolicy;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadCard();
    _loadInsuranceCoverage();
  }

  /// Fire-and-forget: fetch user's health insurance policies from InsuranceService
  Future<void> _loadInsuranceCoverage() async {
    setState(() => _insuranceLoading = true);
    try {
      final result = await _insuranceService.getMyPolicies(widget.child.userId);
      if (!mounted) return;
      if (result.success) {
        // Find first active health policy
        final healthPolicies = result.items
            .where((p) => p.category == InsuranceCategory.health && p.isActive)
            .toList();
        setState(() {
          _insuranceLoading = false;
          _activeHealthPolicy = healthPolicies.isNotEmpty ? healthPolicies.first : null;
        });
      } else {
        setState(() => _insuranceLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _insuranceLoading = false);
    }
  }

  Future<void> _loadCard() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result =
          await _service.getEmergencyCard(widget.child.id, token: _token);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          final d = result.data!;
          _bloodType = d['blood_type'] as String? ?? widget.child.bloodType ?? '';
          _allergies = _parseList(d['allergies']) ??
              List<String>.from(widget.child.allergies);
          _chronicConditions = _parseList(d['chronic_conditions']) ?? [];
          _medications = _parseList(d['medications']) ?? [];
          _emergencyContacts = _parseContacts(d['emergency_contacts']) ??
              List<Map<String, String>>.from(widget.child.emergencyContacts);
          _insuranceNumber = d['insurance_number'] as String? ??
              widget.child.insuranceNumber ?? '';
          _doctorName = d['doctor_name'] as String? ?? '';
          _doctorPhone = d['doctor_phone'] as String? ?? '';
          _shareCode = d['share_code'] as String?;
        } else {
          // Use data from child model as defaults
          _bloodType = widget.child.bloodType ?? '';
          _allergies = List<String>.from(widget.child.allergies);
          _emergencyContacts =
              List<Map<String, String>>.from(widget.child.emergencyContacts);
          _insuranceNumber = widget.child.insuranceNumber ?? '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _bloodType = widget.child.bloodType ?? '';
        _allergies = List<String>.from(widget.child.allergies);
        _emergencyContacts =
            List<Map<String, String>>.from(widget.child.emergencyContacts);
        _insuranceNumber = widget.child.insuranceNumber ?? '';
      });
    }
  }

  List<String>? _parseList(dynamic val) {
    if (val is List) return val.map((e) => e.toString()).toList();
    return null;
  }

  List<Map<String, String>>? _parseContacts(dynamic val) {
    if (val is List) {
      return val
          .map((c) => (c as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v?.toString() ?? '')))
          .toList();
    }
    return null;
  }

  Future<void> _saveCard() async {
    if (_token == null) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = <String, dynamic>{
        'blood_type': _bloodType,
        'allergies': _allergies,
        'chronic_conditions': _chronicConditions,
        'medications': _medications,
        'emergency_contacts': _emergencyContacts,
        'insurance_number': _insuranceNumber,
        'doctor_name': _doctorName,
        'doctor_phone': _doctorPhone,
      };
      final result =
          await _service.saveEmergencyCard(widget.child.id, data, token: _token);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (result.success) {
        if (result.data != null && result.data is Map) {
          final d = result.data as Map<String, dynamic>;
          if (d['share_code'] != null) {
            setState(() => _shareCode = d['share_code'] as String);
          }
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(_sw ? 'Imehifadhiwa' : 'Saved'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                result.message ?? (_sw ? 'Imeshindikana kuhifadhi' : 'Failed to save')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(_sw ? 'Hitilafu imetokea' : 'An error occurred')),
      );
    }
  }

  void _shareCardText() {
    final child = widget.child;
    final ageYears = child.ageInYears;
    final ageMonths = child.ageInMonths % 12;
    final ageStr = ageYears > 0
        ? '$ageYears yr${ageMonths > 0 ? ' $ageMonths mo' : ''}'
        : '${child.ageInMonths} mo';

    final buf = StringBuffer();
    buf.writeln('--- EMERGENCY CARD / KADI YA DHARURA ---');
    buf.writeln('Name: ${child.name}');
    buf.writeln(
        'DOB: ${child.dateOfBirth.day}/${child.dateOfBirth.month}/${child.dateOfBirth.year}');
    buf.writeln('Age: $ageStr');
    if (_bloodType.isNotEmpty) buf.writeln('Blood Type: $_bloodType');
    if (_allergies.isNotEmpty) {
      buf.writeln('Allergies: ${_allergies.join(', ')}');
    }
    if (_chronicConditions.isNotEmpty) {
      buf.writeln('Chronic Conditions: ${_chronicConditions.join(', ')}');
    }
    if (_medications.isNotEmpty) {
      buf.writeln('Medications: ${_medications.join(', ')}');
    }
    for (final c in _emergencyContacts) {
      buf.writeln(
          'Emergency Contact: ${c['name'] ?? ''} - ${c['phone'] ?? ''}');
    }
    if (_insuranceNumber.isNotEmpty) {
      buf.writeln('Insurance #: $_insuranceNumber');
    }
    if (_doctorName.isNotEmpty) {
      buf.writeln('Doctor: $_doctorName${_doctorPhone.isNotEmpty ? ' ($_doctorPhone)' : ''}');
    }
    if (_shareCode != null && _shareCode!.isNotEmpty) {
      buf.writeln('Share Code: $_shareCode');
    }

    SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  Future<void> _generateShareCode() async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    // Save first to ensure card exists, then use the share code from response
    await _saveCard();
    if (_shareCode != null && _shareCode!.isNotEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              _sw ? 'Kodi ya kushiriki: $_shareCode' : 'Share code: $_shareCode'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ─── Edit Bottom Sheet ──────────────────────────────────────────

  void _showEditSheet() {
    final sw = _sw;
    final bloodCtrl = TextEditingController(text: _bloodType);
    final allergiesCtrl = TextEditingController(text: _allergies.join(', '));
    final conditionsCtrl =
        TextEditingController(text: _chronicConditions.join(', '));
    final medsCtrl = TextEditingController(text: _medications.join(', '));
    final insuranceCtrl = TextEditingController(text: _insuranceNumber);
    final doctorNameCtrl = TextEditingController(text: _doctorName);
    final doctorPhoneCtrl = TextEditingController(text: _doctorPhone);

    // Emergency contacts — use first or empty
    final contact1NameCtrl = TextEditingController(
        text: _emergencyContacts.isNotEmpty
            ? _emergencyContacts[0]['name'] ?? ''
            : '');
    final contact1PhoneCtrl = TextEditingController(
        text: _emergencyContacts.isNotEmpty
            ? _emergencyContacts[0]['phone'] ?? ''
            : '');
    final contact2NameCtrl = TextEditingController(
        text: _emergencyContacts.length > 1
            ? _emergencyContacts[1]['name'] ?? ''
            : '');
    final contact2PhoneCtrl = TextEditingController(
        text: _emergencyContacts.length > 1
            ? _emergencyContacts[1]['phone'] ?? ''
            : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Hariri Kadi ya Dharura' : 'Edit Emergency Card',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editField(bloodCtrl, sw ? 'Kundi la Damu' : 'Blood Type',
                      'A+, B-, O+...'),
                  const SizedBox(height: 12),
                  _editField(
                      allergiesCtrl,
                      sw ? 'Mzio (tenganisha kwa koma)' : 'Allergies (comma-separated)',
                      sw ? 'Karanga, Maziwa' : 'Peanuts, Milk'),
                  const SizedBox(height: 12),
                  _editField(
                      conditionsCtrl,
                      sw ? 'Magonjwa ya Kudumu' : 'Chronic Conditions',
                      sw ? 'Pumu, Kisukari' : 'Asthma, Diabetes'),
                  const SizedBox(height: 12),
                  _editField(medsCtrl, sw ? 'Dawa za Sasa' : 'Current Medications',
                      sw ? 'Dawa 1, Dawa 2' : 'Med 1, Med 2'),
                  const SizedBox(height: 16),
                  Text(
                    sw ? 'Mawasiliano ya Dharura 1' : 'Emergency Contact 1',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                          child: _editField(
                              contact1NameCtrl, sw ? 'Jina' : 'Name', '')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _editField(
                              contact1PhoneCtrl, sw ? 'Simu' : 'Phone', '')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sw ? 'Mawasiliano ya Dharura 2' : 'Emergency Contact 2',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                          child: _editField(
                              contact2NameCtrl, sw ? 'Jina' : 'Name', '')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _editField(
                              contact2PhoneCtrl, sw ? 'Simu' : 'Phone', '')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _editField(insuranceCtrl,
                      sw ? 'Nambari ya Bima' : 'Insurance Number', ''),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _editField(
                              doctorNameCtrl, sw ? 'Daktari' : 'Doctor Name', '')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _editField(doctorPhoneCtrl,
                              sw ? 'Simu ya Daktari' : 'Doctor Phone', '')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Parse and save
                        setState(() {
                          _bloodType = bloodCtrl.text.trim();
                          _allergies = _splitComma(allergiesCtrl.text);
                          _chronicConditions = _splitComma(conditionsCtrl.text);
                          _medications = _splitComma(medsCtrl.text);
                          _insuranceNumber = insuranceCtrl.text.trim();
                          _doctorName = doctorNameCtrl.text.trim();
                          _doctorPhone = doctorPhoneCtrl.text.trim();

                          final contacts = <Map<String, String>>[];
                          final c1n = contact1NameCtrl.text.trim();
                          final c1p = contact1PhoneCtrl.text.trim();
                          if (c1n.isNotEmpty || c1p.isNotEmpty) {
                            contacts.add({'name': c1n, 'phone': c1p});
                          }
                          final c2n = contact2NameCtrl.text.trim();
                          final c2p = contact2PhoneCtrl.text.trim();
                          if (c2n.isNotEmpty || c2p.isNotEmpty) {
                            contacts.add({'name': c2n, 'phone': c2p});
                          }
                          _emergencyContacts = contacts;
                        });
                        Navigator.pop(ctx);
                        _saveCard();
                      },
                      child: Text(
                        sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      bloodCtrl.dispose();
      allergiesCtrl.dispose();
      conditionsCtrl.dispose();
      medsCtrl.dispose();
      insuranceCtrl.dispose();
      doctorNameCtrl.dispose();
      doctorPhoneCtrl.dispose();
      contact1NameCtrl.dispose();
      contact1PhoneCtrl.dispose();
      contact2NameCtrl.dispose();
      contact2PhoneCtrl.dispose();
    });
  }

  Widget _editField(TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: _kTertiary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _kTertiary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _kTertiary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  List<String> _splitComma(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final child = widget.child;
    final ageYears = child.ageInYears;
    final ageMonths = child.ageInMonths % 12;
    final ageStr = sw
        ? (ageYears > 0
            ? 'Miaka $ageYears${ageMonths > 0 ? ' miezi $ageMonths' : ''}'
            : 'Miezi ${child.ageInMonths}')
        : (ageYears > 0
            ? '$ageYears yr${ageMonths > 0 ? ' $ageMonths mo' : ''}'
            : '${child.ageInMonths} mo');

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
          sw ? 'Kadi ya Dharura' : 'Emergency Card',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: _kPrimary),
            tooltip: sw ? 'Hariri' : 'Edit',
            onPressed: _showEditSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Completeness indicator
                  _buildCompletenessCard(sw),
                  const SizedBox(height: 12),

                  // Main card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _kPrimary.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            const Icon(Icons.emergency_rounded,
                                color: _kPrimary, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sw ? 'KADI YA DHARURA' : 'EMERGENCY CARD',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                  letterSpacing: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Name, DOB, Age
                        _cardRow(
                            sw ? 'Jina' : 'Name', child.name),
                        _cardRow(
                            sw ? 'Tarehe ya Kuzaliwa' : 'Date of Birth',
                            '${child.dateOfBirth.day}/${child.dateOfBirth.month}/${child.dateOfBirth.year}'),
                        _cardRow(sw ? 'Umri' : 'Age', ageStr),

                        if (_bloodType.isNotEmpty)
                          _cardRow(
                              sw ? 'Kundi la Damu' : 'Blood Type', _bloodType),

                        if (_allergies.isNotEmpty)
                          _cardRow(sw ? 'Mzio' : 'Allergies',
                              _allergies.join(', ')),

                        if (_chronicConditions.isNotEmpty)
                          _cardRow(
                              sw ? 'Magonjwa ya Kudumu' : 'Chronic Conditions',
                              _chronicConditions.join(', ')),

                        if (_medications.isNotEmpty)
                          _cardRow(
                              sw ? 'Dawa za Sasa' : 'Current Medications',
                              _medications.join(', ')),

                        // Emergency contacts
                        if (_emergencyContacts.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            sw
                                ? 'Mawasiliano ya Dharura'
                                : 'Emergency Contacts',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ..._emergencyContacts.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '${c['name'] ?? ''} — ${c['phone'] ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 14, color: _kPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],

                        if (_insuranceNumber.isNotEmpty)
                          _cardRow(sw ? 'Bima #' : 'Insurance #',
                              _insuranceNumber),

                        // NHIF status
                        _buildNhifSection(sw),

                        if (_doctorName.isNotEmpty)
                          _cardRow(
                              sw ? 'Daktari' : 'Doctor',
                              '$_doctorName${_doctorPhone.isNotEmpty ? ' ($_doctorPhone)' : ''}'),

                        if (_shareCode != null && _shareCode!.isNotEmpty) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.qr_code_rounded,
                                  size: 18, color: _kSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${sw ? "Kodi" : "Code"}: $_shareCode',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kPrimary,
                              side: const BorderSide(color: _kPrimary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _shareCardText,
                            icon:
                                const Icon(Icons.share_rounded, size: 18),
                            label: Text(
                              sw ? 'Shiriki' : 'Share',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                _isSaving ? null : _generateShareCode,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.qr_code_rounded,
                                    size: 18),
                            label: Text(
                              sw ? 'Pata Kodi' : 'Share Code',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

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
                        ? 'Shiriki na daktari kabla ya miadi'
                        : 'Share with doctor before appointment',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DoctorModule(userId: widget.child.userId))),
                  ),
                  _buildCrossModuleLink(
                    icon: Icons.school_rounded,
                    label: sw
                        ? 'Shiriki na shule ya mtoto'
                        : 'Share with child\'s school',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SchoolSharingPage(child: widget.child, userId: widget.child.userId))),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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

  Widget _buildCompletenessCard(bool sw) {
    int filled = 0;
    const total = 8;
    if (_bloodType.isNotEmpty) filled++;
    if (_allergies.isNotEmpty) filled++;
    if (_chronicConditions.isNotEmpty) filled++;
    if (_medications.isNotEmpty) filled++;
    if (_emergencyContacts.isNotEmpty) filled++;
    if (_insuranceNumber.isNotEmpty) filled++;
    if (_doctorName.isNotEmpty) filled++;
    if (_doctorPhone.isNotEmpty) filled++;

    final fraction = filled / total;
    final pct = (fraction * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                filled == total
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                size: 18,
                color: filled == total ? const Color(0xFF4CAF50) : _kPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw
                      ? 'Profaili: $filled/$total sehemu zimejazwa'
                      : 'Profile: $filled/$total fields complete',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: filled == total ? const Color(0xFF4CAF50) : _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade200,
              color: filled == total
                  ? const Color(0xFF4CAF50)
                  : _kPrimary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNhifSection(bool sw) {
    // Determine display from real InsuranceService data if available
    final String statusLabel;
    final Color statusColor;
    final String? policyName;

    if (_insuranceLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                sw ? 'Hali ya Bima' : 'Insurance Status',
                style: const TextStyle(fontSize: 12, color: _kSecondary, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5, color: _kSecondary)),
            const SizedBox(width: 6),
            Text(sw ? 'Inapakia...' : 'Loading...', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
      );
    }

    if (_activeHealthPolicy != null) {
      statusLabel = sw ? 'Hai' : 'Active';
      statusColor = const Color(0xFF4CAF50);
      policyName = _activeHealthPolicy!.productName;
    } else {
      // Fallback to child's NHIF status field
      final nhifStatus = widget.child.nhifStatus;
      if (nhifStatus == 'active') {
        statusLabel = sw ? 'Hai' : 'Active';
        statusColor = const Color(0xFF4CAF50);
      } else if (nhifStatus == 'inactive') {
        statusLabel = sw ? 'Isiyo hai' : 'Inactive';
        statusColor = Colors.red;
      } else {
        statusLabel = sw ? 'Hakuna bima ya afya' : 'No health insurance';
        statusColor = _kSecondary;
      }
      policyName = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  sw ? 'Hali ya Bima' : 'Insurance Status',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (policyName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 120),
                Expanded(
                  child: Text(
                    policyName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (_activeHealthPolicy != null)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InsuranceModule(userId: widget.child.userId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: Text(
                        sw ? 'Ona Bima' : 'View Policy',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              if (_activeHealthPolicy != null) const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InsuranceModule(userId: widget.child.userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.health_and_safety_rounded, size: 18),
                    label: Text(
                      _activeHealthPolicy != null
                          ? (sw ? 'Angalia Bima' : 'Check Coverage')
                          : (sw ? 'Tafuta Bima' : 'Browse Insurance'),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _kSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: _kPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
