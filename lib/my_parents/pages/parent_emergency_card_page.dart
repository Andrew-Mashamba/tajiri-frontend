// lib/my_parents/pages/parent_emergency_card_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFEF5350);
const Color _kSuccess = Color(0xFF4CAF50);

class ParentEmergencyCardPage extends StatefulWidget {
  final Parent parent;

  const ParentEmergencyCardPage({super.key, required this.parent});

  @override
  State<ParentEmergencyCardPage> createState() =>
      _ParentEmergencyCardPageState();
}

class _ParentEmergencyCardPageState extends State<ParentEmergencyCardPage> {
  final MyParentsService _service = MyParentsService();
  String? _token;
  bool _isLoading = true;
  bool _isSaving = false;

  // Card fields
  String _bloodType = '';
  List<String> _conditions = [];
  List<String> _medications = [];
  List<String> _allergies = [];
  List<Map<String, String>> _emergencyContacts = [];
  String _nhifNumber = '';
  String _doctorName = '';
  String _doctorPhone = '';

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadCard();
  }

  Future<void> _loadCard() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getEmergencyCard(_token!, widget.parent.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          final d = result.data!;
          _bloodType = d['blood_type'] as String? ?? widget.parent.bloodType ?? '';
          _conditions = _parseList(d['conditions']) ?? List<String>.from(widget.parent.chronicConditions);
          _medications = _parseList(d['medications']) ?? [];
          _allergies = _parseList(d['allergies']) ?? List<String>.from(widget.parent.allergies);
          _emergencyContacts = _parseContacts(d['emergency_contacts']) ??
              List<Map<String, String>>.from(widget.parent.emergencyContacts);
          _nhifNumber = d['nhif_number'] as String? ?? widget.parent.nhifNumber ?? '';
          _doctorName = d['doctor_name'] as String? ?? '';
          _doctorPhone = d['doctor_phone'] as String? ?? '';
        } else {
          // Initialize from parent data
          _bloodType = widget.parent.bloodType ?? '';
          _conditions = List<String>.from(widget.parent.chronicConditions);
          _allergies = List<String>.from(widget.parent.allergies);
          _emergencyContacts = List<Map<String, String>>.from(widget.parent.emergencyContacts);
          _nhifNumber = widget.parent.nhifNumber ?? '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _bloodType = widget.parent.bloodType ?? '';
        _conditions = List<String>.from(widget.parent.chronicConditions);
        _allergies = List<String>.from(widget.parent.allergies);
        _emergencyContacts = List<Map<String, String>>.from(widget.parent.emergencyContacts);
        _nhifNumber = widget.parent.nhifNumber ?? '';
      });
    }
  }

  List<String>? _parseList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).toList();
    return null;
  }

  List<Map<String, String>>? _parseContacts(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((c) => (c as Map<String, dynamic>)
              .map((k, val) => MapEntry(k, val?.toString() ?? '')))
          .toList();
    }
    return null;
  }

  int get _completenessScore {
    int score = 0;
    if (widget.parent.name.isNotEmpty) score++;
    if (_bloodType.isNotEmpty) score++;
    if (_conditions.isNotEmpty) score++;
    if (_medications.isNotEmpty) score++;
    if (_allergies.isNotEmpty) score++;
    if (_emergencyContacts.isNotEmpty) score++;
    if (_nhifNumber.isNotEmpty) score++;
    if (_doctorName.isNotEmpty) score++;
    return score;
  }

  void _showAddContactSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                sw ? 'Ongeza Mawasiliano ya Dharura' : 'Add Emergency Contact',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 16),
              _EField(controller: nameCtrl, label: sw ? 'Jina' : 'Name'),
              const SizedBox(height: 12),
              _EField(controller: phoneCtrl,
                  label: sw ? 'Simu' : 'Phone',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _EField(controller: relCtrl,
                  label: sw ? 'Uhusiano' : 'Relationship'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(sw
                            ? 'Tafadhali ingiza jina na simu'
                            : 'Please enter name and phone')),
                      );
                      return;
                    }
                    setState(() {
                      _emergencyContacts.add({
                        'name': name,
                        'phone': phone,
                        if (relCtrl.text.trim().isNotEmpty)
                          'relationship': relCtrl.text.trim(),
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(sw ? 'Ongeza' : 'Add',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      relCtrl.dispose();
    });
  }

  void _removeContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
  }

  void _showEditSheet() {
    final bloodTypeCtrl = TextEditingController(text: _bloodType);
    final conditionsCtrl = TextEditingController(text: _conditions.join(', '));
    final medicationsCtrl = TextEditingController(text: _medications.join(', '));
    final allergiesCtrl = TextEditingController(text: _allergies.join(', '));
    final nhifCtrl = TextEditingController(text: _nhifNumber);
    final doctorNameCtrl = TextEditingController(text: _doctorName);
    final doctorPhoneCtrl = TextEditingController(text: _doctorPhone);
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                sw ? 'Hariri Kadi ya Dharura' : 'Edit Emergency Card',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 16),
              _EField(controller: bloodTypeCtrl,
                  label: sw ? 'Aina ya damu' : 'Blood type'),
              const SizedBox(height: 12),
              _EField(controller: conditionsCtrl,
                  label: sw ? 'Magonjwa sugu (tenganisha na koma)' : 'Chronic conditions (comma-separated)'),
              const SizedBox(height: 12),
              _EField(controller: medicationsCtrl,
                  label: sw ? 'Dawa (tenganisha na koma)' : 'Medications (comma-separated)'),
              const SizedBox(height: 12),
              _EField(controller: allergiesCtrl,
                  label: sw ? 'Mzio (tenganisha na koma)' : 'Allergies (comma-separated)'),
              const SizedBox(height: 12),
              _EField(controller: nhifCtrl,
                  label: sw ? 'Namba ya NHIF' : 'NHIF number'),
              const SizedBox(height: 12),
              _EField(controller: doctorNameCtrl,
                  label: sw ? 'Jina la daktari' : 'Doctor name'),
              const SizedBox(height: 12),
              _EField(controller: doctorPhoneCtrl,
                  label: sw ? 'Simu ya daktari' : 'Doctor phone',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _saveCard(
                            bloodType: bloodTypeCtrl.text.trim(),
                            conditions: conditionsCtrl.text.trim(),
                            medications: medicationsCtrl.text.trim(),
                            allergies: allergiesCtrl.text.trim(),
                            nhifNumber: nhifCtrl.text.trim(),
                            doctorName: doctorNameCtrl.text.trim(),
                            doctorPhone: doctorPhoneCtrl.text.trim(),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(sw ? 'Hifadhi' : 'Save',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      bloodTypeCtrl.dispose();
      conditionsCtrl.dispose();
      medicationsCtrl.dispose();
      allergiesCtrl.dispose();
      nhifCtrl.dispose();
      doctorNameCtrl.dispose();
      doctorPhoneCtrl.dispose();
    });
  }

  Future<void> _saveCard({
    required String bloodType,
    required String conditions,
    required String medications,
    required String allergies,
    required String nhifNumber,
    required String doctorName,
    required String doctorPhone,
  }) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    setState(() => _isSaving = true);

    try {
      final result = await _service.saveEmergencyCard(
        token: _token!,
        parentId: widget.parent.id,
        cardData: {
          'blood_type': bloodType,
          'conditions': conditions.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'medications': medications.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'allergies': allergies.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'emergency_contacts': _emergencyContacts,
          'nhif_number': nhifNumber,
          'doctor_name': doctorName,
          'doctor_phone': doctorPhone,
        },
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kadi imehifadhiwa' : 'Card saved')),
        );
        _loadCard();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  void _shareCard() {
    final sw = _sw;
    final lines = <String>[
      sw ? 'KADI YA DHARURA' : 'EMERGENCY CARD',
      '',
      '${sw ? 'Jina' : 'Name'}: ${widget.parent.name}',
      '${sw ? 'Umri' : 'Age'}: ${widget.parent.ageInYears} ${sw ? 'miaka' : 'years'}',
      if (_bloodType.isNotEmpty) '${sw ? 'Damu' : 'Blood Type'}: $_bloodType',
      if (_conditions.isNotEmpty)
        '${sw ? 'Magonjwa' : 'Conditions'}: ${_conditions.join(', ')}',
      if (_medications.isNotEmpty)
        '${sw ? 'Dawa' : 'Medications'}: ${_medications.join(', ')}',
      if (_allergies.isNotEmpty)
        '${sw ? 'Mzio' : 'Allergies'}: ${_allergies.join(', ')}',
      if (_nhifNumber.isNotEmpty) 'NHIF: $_nhifNumber',
      if (_doctorName.isNotEmpty)
        '${sw ? 'Daktari' : 'Doctor'}: $_doctorName${_doctorPhone.isNotEmpty ? ' ($_doctorPhone)' : ''}',
      if (_emergencyContacts.isNotEmpty) ...[
        '',
        '${sw ? 'Mawasiliano ya Dharura' : 'Emergency Contacts'}:',
        ..._emergencyContacts.map((c) =>
            '  ${c['name'] ?? ''} - ${c['phone'] ?? ''}${c['relationship'] != null ? ' (${c['relationship']})' : ''}'),
      ],
    ];
    SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  void _callAmbulance() {
    final sw = _sw;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emergency_rounded, color: _kDanger, size: 24),
            const SizedBox(width: 8),
            Text(sw ? 'Piga Ambulensi' : 'Call Ambulance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sw ? 'Namba ya dharura:' : 'Emergency number:',
              style: const TextStyle(fontSize: 14, color: _kSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              '114',
              style: TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w800, color: _kDanger),
            ),
            const SizedBox(height: 12),
            Text(
              sw
                  ? 'Piga simu namba hii kwa dharura za afya.'
                  : 'Call this number for medical emergencies.',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Funga' : 'Close',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse('tel:114');
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(sw
                          ? 'Haiwezi kupiga simu kwenye kifaa hiki'
                          : 'Cannot make calls on this device')),
                    );
                  }
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw
                        ? 'Hitilafu ya kupiga simu'
                        : 'Failed to make call')),
                  );
                }
              }
            },
            child: Text(sw ? 'Piga 114 Sasa' : 'Call 114 Now',
                style: const TextStyle(color: _kDanger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final score = _completenessScore;

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
          sw ? 'Kadi ya Dharura' : 'Emergency Card',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: _kPrimary),
            onPressed: _showEditSheet,
            tooltip: sw ? 'Hariri' : 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            onPressed: _shareCard,
            tooltip: sw ? 'Shiriki' : 'Share',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Completeness score
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48, height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: score / 8,
                              strokeWidth: 4,
                              backgroundColor: _kPrimary.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                score >= 6 ? _kSuccess : _kSecondary,
                              ),
                            ),
                            Text(
                              '$score/8',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sw ? 'Ukamilifu wa Kadi' : 'Card Completeness',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                            ),
                            Text(
                              score >= 6
                                  ? (sw ? 'Kadi iko tayari vizuri' : 'Card is well prepared')
                                  : (sw ? 'Ongeza taarifa zaidi' : 'Add more information'),
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
                const SizedBox(height: 16),

                // Parent info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emergency_rounded,
                          size: 32, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        widget.parent.name,
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.parent.ageInYears} ${sw ? 'miaka' : 'years'}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      if (_bloodType.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sw ? 'Damu: ' : 'Blood: '}$_bloodType',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Medical info
                _buildInfoSection(
                  icon: Icons.medical_information_rounded,
                  title: sw ? 'Magonjwa Sugu' : 'Chronic Conditions',
                  items: _conditions,
                  emptyLabel: sw ? 'Hakuna' : 'None recorded',
                ),
                const SizedBox(height: 10),
                _buildInfoSection(
                  icon: Icons.medication_rounded,
                  title: sw ? 'Dawa' : 'Medications',
                  items: _medications,
                  emptyLabel: sw ? 'Hakuna' : 'None recorded',
                ),
                const SizedBox(height: 10),
                _buildInfoSection(
                  icon: Icons.warning_rounded,
                  title: sw ? 'Mzio' : 'Allergies',
                  items: _allergies,
                  emptyLabel: sw ? 'Hakuna' : 'None recorded',
                ),
                const SizedBox(height: 10),

                // Emergency contacts
                _buildContactsSection(sw),
                const SizedBox(height: 10),

                // NHIF & Doctor
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_nhifNumber.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.health_and_safety_rounded,
                                size: 16, color: _kSecondary),
                            const SizedBox(width: 8),
                            Text('NHIF: $_nhifNumber',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(sw
                                      ? 'Moduli ya bima inakuja hivi karibuni'
                                      : 'Insurance module coming soon')),
                                );
                              },
                              child: Text(
                                sw ? 'Angalia Bima' : 'Check Insurance',
                                style: const TextStyle(
                                    fontSize: 10, color: _kPrimary,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_doctorName.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 16, color: _kSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${sw ? 'Daktari: ' : 'Doctor: '}$_doctorName'
                                '${_doctorPhone.isNotEmpty ? ' ($_doctorPhone)' : ''}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (_nhifNumber.isEmpty && _doctorName.isEmpty)
                        Text(
                          sw ? 'Hakuna taarifa za bima au daktari' : 'No insurance or doctor info',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Call ambulance button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _callAmbulance,
                    icon: const Icon(Icons.emergency_rounded, size: 20),
                    label: Text(
                      sw ? 'Piga Ambulensi (114)' : 'Call Ambulance (114)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kDanger,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required String emptyLabel,
  }) {
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
              Icon(icon, size: 16, color: _kSecondary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(emptyLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items
                  .map((item) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item,
                            style: const TextStyle(fontSize: 12, color: _kPrimary)),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildContactsSection(bool sw) {
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
              const Icon(Icons.contacts_rounded, size: 16, color: _kSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(sw ? 'Mawasiliano ya Dharura' : 'Emergency Contacts',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              ),
              GestureDetector(
                onTap: _showAddContactSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: _kPrimary),
                      const SizedBox(width: 2),
                      Text(sw ? 'Ongeza' : 'Add',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_emergencyContacts.isEmpty)
            Text(sw ? 'Hakuna mawasiliano' : 'No contacts added',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400))
          else
            ..._emergencyContacts.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 16, color: _kSecondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            '${c['phone'] ?? ''}'
                            '${c['relationship'] != null && c['relationship']!.isNotEmpty ? ' - ${c['relationship']}' : ''}',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if ((c['phone'] ?? '').isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('tel:${c['phone']}');
                          try {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          } catch (_) {}
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.phone_rounded, size: 16, color: _kSuccess),
                        ),
                      ),
                    GestureDetector(
                      onTap: () => _removeContact(i),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 16, color: _kDanger),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────

class _EField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _EField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        filled: true,
        fillColor: _kPrimary.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: const TextStyle(fontSize: 14, color: _kPrimary),
    );
  }
}
