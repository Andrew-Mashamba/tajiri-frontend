// lib/my_baby/pages/health_log_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ─── Health log types ─────────────────────────────────────────────

class _LogType {
  final String key;
  final String labelEn;
  final String labelSw;
  final IconData icon;

  const _LogType({
    required this.key,
    required this.labelEn,
    required this.labelSw,
    required this.icon,
  });

  String label(bool sw) => sw ? labelSw : labelEn;
}

const List<_LogType> _logTypes = [
  _LogType(key: 'temperature', labelEn: 'Temperature', labelSw: 'Joto', icon: Icons.thermostat_rounded),
  _LogType(key: 'medication', labelEn: 'Medication', labelSw: 'Dawa', icon: Icons.medication_rounded),
  _LogType(key: 'illness', labelEn: 'Illness', labelSw: 'Ugonjwa', icon: Icons.sick_rounded),
  _LogType(key: 'allergy', labelEn: 'Allergy', labelSw: 'Mzio', icon: Icons.warning_amber_rounded),
  _LogType(key: 'doctor_visit', labelEn: 'Doctor Visit', labelSw: 'Kumtembelea Daktari', icon: Icons.local_hospital_rounded),
];

// ─── Page ─────────────────────────────────────────────────────────

class HealthLogPage extends StatefulWidget {
  final Baby baby;

  const HealthLogPage({super.key, required this.baby});

  @override
  State<HealthLogPage> createState() => _HealthLogPageState();
}

class _HealthLogPageState extends State<HealthLogPage> {
  final MyBabyService _service = MyBabyService();

  bool _isLoading = true;
  List<HealthLog> _logs = [];
  String? _token;
  String? _errorMessage;
  String? _filterType;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.getHealthHistory(
        _token!,
        widget.baby.id,
        type: _filterType,
      );
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _logs = result.items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddForm(_LogType logType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HealthLogForm(
        logType: logType,
        baby: widget.baby,
        token: _token ?? '',
        service: _service,
        isSwahili: _sw,
        onSaved: () {
          Navigator.pop(ctx);
          _loadLogs();
        },
      ),
    );
  }

  _LogType _logTypeForKey(String key) {
    return _logTypes.firstWhere(
      (t) => t.key == key,
      orElse: () => _logTypes.first,
    );
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
          sw ? 'Rekodi ya Afya' : 'Health Log',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick-add buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 80,
                child: Row(
                  children: _logTypes.map((lt) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _QuickAddButton(
                          icon: lt.icon,
                          label: lt.label(sw),
                          onTap: () => _showAddForm(lt),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: sw ? 'Zote' : 'All',
                    isSelected: _filterType == null,
                    onTap: () {
                      setState(() => _filterType = null);
                      _loadLogs();
                    },
                  ),
                  ..._logTypes.map((lt) => _FilterChip(
                        label: lt.label(sw),
                        isSelected: _filterType == lt.key,
                        onTap: () {
                          setState(() => _filterType = lt.key);
                          _loadLogs();
                        },
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // History list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary))
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14, color: _kSecondary),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _loadLogs,
                                  child: Text(sw ? 'Jaribu tena' : 'Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _logs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.health_and_safety_rounded,
                                      size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    sw
                                        ? 'Bado hakuna rekodi za afya'
                                        : 'No health records yet',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadLogs,
                              color: _kPrimary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                itemCount: _logs.length,
                                itemBuilder: (_, i) {
                                  final log = _logs[i];
                                  final lt = _logTypeForKey(log.type);
                                  return _HealthLogItem(
                                    log: log,
                                    logType: lt,
                                    isSwahili: sw,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Add Button ─────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: _kPrimary),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? _kPrimary : _kCardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Health Log Item ──────────────────────────────────────────────

class _HealthLogItem extends StatelessWidget {
  final HealthLog log;
  final _LogType logType;
  final bool isSwahili;

  const _HealthLogItem({
    required this.log,
    required this.logType,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(log.icon, size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (log.value != null && log.value!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.value!,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (log.description != null &&
                    log.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.description!,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${log.loggedAt.day}/${log.loggedAt.month}/${log.loggedAt.year}  ${log.loggedAt.hour.toString().padLeft(2, '0')}:${log.loggedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              logType.label(isSwahili),
              style: const TextStyle(fontSize: 10, color: _kSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Health Log Form (Bottom Sheet) ───────────────────────────────

class _HealthLogForm extends StatefulWidget {
  final _LogType logType;
  final Baby baby;
  final String token;
  final MyBabyService service;
  final bool isSwahili;
  final VoidCallback onSaved;

  const _HealthLogForm({
    required this.logType,
    required this.baby,
    required this.token,
    required this.service,
    required this.isSwahili,
    required this.onSaved,
  });

  @override
  State<_HealthLogForm> createState() => _HealthLogFormState();
}

class _HealthLogFormState extends State<_HealthLogForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Common fields
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _logDate = DateTime.now();

  // Medication-specific fields
  String _medFrequency = 'once_daily';
  DateTime? _medStartDate;
  DateTime? _medEndDate;

  bool get sw => widget.isSwahili;

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: widget.baby.dateOfBirth,
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _logDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      String title = _titleController.text.trim();
      String? value = _valueController.text.trim();
      String? desc = _descriptionController.text.trim();

      // Build title from type-specific fields
      if (widget.logType.key == 'temperature') {
        title = '${sw ? 'Joto' : 'Temperature'}: ${value.isNotEmpty ? value : '-'}°C';
        value = '${value.isNotEmpty ? value : '0'}°C';
      }

      // Append medication metadata to description
      if (widget.logType.key == 'medication') {
        final freqLabels = {
          'once_daily': sw ? 'Mara moja kwa siku' : 'Once daily',
          'twice_daily': sw ? 'Mara mbili kwa siku' : 'Twice daily',
          'three_times': sw ? 'Mara tatu kwa siku' : 'Three times daily',
          'as_needed': sw ? 'Inapohitajika' : 'As needed',
        };
        final parts = <String>[];
        parts.add('${sw ? 'Mara' : 'Freq'}: ${freqLabels[_medFrequency] ?? _medFrequency}');
        if (_medStartDate != null) {
          parts.add('${sw ? 'Kuanza' : 'Start'}: ${_medStartDate!.day}/${_medStartDate!.month}/${_medStartDate!.year}');
        }
        if (_medEndDate != null) {
          parts.add('${sw ? 'Kumaliza' : 'End'}: ${_medEndDate!.day}/${_medEndDate!.month}/${_medEndDate!.year}');
        }
        final medMeta = parts.join(' | ');
        desc = desc.isNotEmpty ? '$medMeta\n$desc' : medMeta;
      }

      if (title.isEmpty) {
        title = widget.logType.label(sw);
      }

      final result = await widget.service.logHealth(
        token: widget.token,
        babyId: widget.baby.id,
        type: widget.logType.key,
        title: title,
        value: value.isNotEmpty ? value : null,
        description: desc.isNotEmpty ? desc : null,
        loggedAt: _logDate,
      );

      if (!mounted) return;

      if (result.success) {
        messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Imehifadhiwa!' : 'Saved!'),
        ));
        widget.onSaved();
      } else {
        setState(() => _isSaving = false);
        messenger.showSnackBar(SnackBar(
          content: Text(result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save')),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Icon(widget.logType.icon, size: 22, color: _kPrimary),
                  const SizedBox(width: 10),
                  Text(
                    widget.logType.label(sw),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type-specific fields
              ..._buildFields(),

              const SizedBox(height: 16),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: _kSecondary),
                      const SizedBox(width: 10),
                      Text(
                        '${_logDate.day}/${_logDate.month}/${_logDate.year}',
                        style: const TextStyle(
                            fontSize: 14, color: _kPrimary),
                      ),
                      const Spacer(),
                      Text(
                        sw ? 'Badilisha tarehe' : 'Change date',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          sw ? 'Hifadhi' : 'Save',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    switch (widget.logType.key) {
      case 'temperature':
        return [
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Joto (°C)' : 'Temperature (°C)',
            hint: sw ? 'Mfano: 37.5' : 'e.g. 37.5',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return sw ? 'Tafadhali ingiza joto' : 'Please enter temperature';
              }
              final num = double.tryParse(v);
              if (num == null || num < 30 || num > 45) {
                return sw ? 'Joto lisilo sahihi' : 'Invalid temperature';
              }
              return null;
            },
          ),
        ];

      case 'medication':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Jina la dawa' : 'Medication name',
            hint: sw ? 'Mfano: Paracetamol' : 'e.g. Paracetamol',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Kipimo' : 'Dosage',
            hint: sw ? 'Mfano: 5ml' : 'e.g. 5ml',
          ),
          const SizedBox(height: 12),
          // Frequency dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _medFrequency,
              decoration: InputDecoration(
                labelText: sw ? 'Mara ngapi' : 'Frequency',
                labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'once_daily',
                  child: Text(sw ? 'Mara moja kwa siku' : 'Once daily'),
                ),
                DropdownMenuItem(
                  value: 'twice_daily',
                  child: Text(sw ? 'Mara mbili kwa siku' : 'Twice daily'),
                ),
                DropdownMenuItem(
                  value: 'three_times',
                  child: Text(sw ? 'Mara tatu kwa siku' : 'Three times daily'),
                ),
                DropdownMenuItem(
                  value: 'as_needed',
                  child: Text(sw ? 'Inapohitajika' : 'As needed'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _medFrequency = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Start date
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _medStartDate ?? DateTime.now(),
                firstDate: widget.baby.dateOfBirth,
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: sw ? 'Tarehe ya kuanza' : 'Start date',
              );
              if (picked != null && mounted) {
                setState(() => _medStartDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: _kSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _medStartDate != null
                        ? '${sw ? 'Kuanza' : 'Start'}: ${_medStartDate!.day}/${_medStartDate!.month}/${_medStartDate!.year}'
                        : (sw ? 'Tarehe ya kuanza (hiari)' : 'Start date (optional)'),
                    style: TextStyle(
                      fontSize: 13,
                      color: _medStartDate != null ? _kPrimary : _kSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // End date
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _medEndDate ?? (_medStartDate ?? DateTime.now()),
                firstDate: _medStartDate ?? widget.baby.dateOfBirth,
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: sw ? 'Tarehe ya kumaliza' : 'End date',
              );
              if (picked != null && mounted) {
                setState(() => _medEndDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded,
                      size: 16, color: _kSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _medEndDate != null
                        ? '${sw ? 'Kumaliza' : 'End'}: ${_medEndDate!.day}/${_medEndDate!.month}/${_medEndDate!.year}'
                        : (sw ? 'Tarehe ya kumaliza (hiari)' : 'End date (optional)'),
                    style: TextStyle(
                      fontSize: 13,
                      color: _medEndDate != null ? _kPrimary : _kSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Maelezo' : 'Notes',
            hint: sw ? 'Maelezo ya ziada' : 'Additional notes',
            maxLines: 2,
          ),
        ];

      case 'illness':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Jina la ugonjwa' : 'Illness name',
            hint: sw ? 'Mfano: Homa' : 'e.g. Fever',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Dalili' : 'Symptoms',
            hint: sw ? 'Eleza dalili' : 'Describe symptoms',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Matibabu na matokeo' : 'Treatment & outcome',
            hint: sw ? 'Matibabu yaliyotolewa' : 'Treatment given',
            maxLines: 2,
          ),
        ];

      case 'allergy':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Kitu kinachosababisha mzio' : 'Allergen',
            hint: sw ? 'Mfano: Maziwa' : 'e.g. Milk',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Majibu ya mwili' : 'Reaction',
            hint: sw ? 'Eleza dalili za mzio' : 'Describe the reaction',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Ukali' : 'Severity',
            hint: sw ? 'Kidogo / Wastani / Kali' : 'Mild / Moderate / Severe',
          ),
        ];

      case 'doctor_visit':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Sababu ya ziara' : 'Visit reason',
            hint: sw ? 'Mfano: Uchunguzi wa kawaida' : 'e.g. Routine checkup',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Uchunguzi' : 'Diagnosis',
            hint: sw ? 'Matokeo ya daktari' : "Doctor's findings",
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Dawa na ufuatiliaji' : 'Prescription & follow-up',
            hint: sw ? 'Dawa zilizotolewa, tarehe ya ufuatiliaji' : 'Medications prescribed, follow-up date',
            maxLines: 3,
          ),
        ];

      default:
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Kichwa' : 'Title',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Maelezo' : 'Description',
            maxLines: 3,
          ),
        ];
    }
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return sw ? 'Sehemu hii inahitajika' : 'This field is required';
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _kPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: _kCardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
      ),
    );
  }
}
