// lib/my_parents/pages/health_monitor_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import '../services/parents_notification_helper.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFEF5350);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kWarning = Color(0xFFFFA726);

class HealthMonitorPage extends StatefulWidget {
  final Parent parent;

  const HealthMonitorPage({super.key, required this.parent});

  @override
  State<HealthMonitorPage> createState() => _HealthMonitorPageState();
}

class _HealthMonitorPageState extends State<HealthMonitorPage>
    with SingleTickerProviderStateMixin {
  final MyParentsService _service = MyParentsService();
  late TabController _tabController;
  String? _token;
  bool _isLoading = true;

  List<ParentHealthReading> _bpReadings = [];
  List<ParentHealthReading> _sugarReadings = [];
  List<ParentHealthReading> _weightReadings = [];
  List<ParentHealthReading> _symptomReadings = [];

  double _parentHeight = 1.65; // Default height in meters for BMI

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadSavedHeight();
    _loadReadings();
  }

  Future<void> _loadSavedHeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final h = prefs.getDouble('parent_height_${widget.parent.id}');
      if (h != null && mounted) {
        setState(() => _parentHeight = h);
      }
    } catch (_) {}
  }

  Future<void> _saveHeight(double height) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('parent_height_${widget.parent.id}', height);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReadings() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getHealthReadings(_token!, widget.parent.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _bpReadings = result.items
              .where((r) => r.type == 'blood_pressure')
              .toList()
            ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
          _sugarReadings = result.items
              .where((r) => r.type == 'blood_sugar')
              .toList()
            ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
          _weightReadings = result.items
              .where((r) => r.type == 'weight')
              .toList()
            ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
          _symptomReadings = result.items
              .where((r) => r.type == 'symptom')
              .toList()
            ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Imeshindikana kupakia vipimo'
            : 'Failed to load readings')),
      );
    }
  }

  Future<void> _deleteReading(ParentHealthReading reading) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa kipimo?' : 'Delete reading?'),
        content: Text(sw
            ? 'Hatua hii haiwezi kutenduliwa.'
            : 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: _kDanger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await _service.deleteHealthReading(token: _token!, readingId: reading.id);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kipimo kimefutwa' : 'Reading deleted')),
        );
        _loadReadings();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kufuta' : 'Failed to delete'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _saveReading({
    required String type,
    required double value,
    double? value2,
    String? unit,
    String? notes,
  }) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final result = await _service.logHealthReading(
        token: _token!,
        parentId: widget.parent.id,
        type: type,
        value: value,
        value2: value2,
        unit: unit,
        notes: notes,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kipimo kimehifadhiwa' : 'Reading saved')),
        );
        // Check for abnormal readings and alert
        _checkAbnormalReading(type, value, value2, sw);
        _loadReadings();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  /// Fire-and-forget: alert if a health reading is abnormal.
  void _checkAbnormalReading(String type, double value, double? value2, bool sw) {
    try {
      bool abnormal = false;
      String readingType = type;
      double alertValue = value;

      if (type == 'blood_pressure') {
        readingType = sw ? 'Shinikizo la Damu' : 'Blood Pressure';
        // Systolic > 140 or < 90, or Diastolic > 90 or < 60
        if (value > 140 || value < 90 || (value2 != null && (value2 > 90 || value2 < 60))) {
          abnormal = true;
          alertValue = value; // Use systolic for alert
        }
      } else if (type == 'blood_sugar') {
        readingType = sw ? 'Sukari ya Damu' : 'Blood Sugar';
        // Fasting > 7.0 mmol/L or < 3.9 mmol/L (general thresholds)
        if (value > 7.0 || value < 3.9) {
          abnormal = true;
        }
      } else if (type == 'weight') {
        // Alert if BMI is extreme (< 16 or > 35)
        final bmi = value / (_parentHeight * _parentHeight);
        if (bmi < 16.0 || bmi > 35.0) {
          readingType = sw ? 'Uzito (BMI)' : 'Weight (BMI)';
          alertValue = bmi;
          abnormal = true;
        }
      } else if (type == 'symptom') {
        // Alert if severity is high (>= 7/10)
        if (value >= 7) {
          readingType = sw ? 'Dalili Kali' : 'Severe Symptom';
          abnormal = true;
        }
      }

      if (abnormal) {
        ParentsNotificationHelper.scheduleAbnormalReadingAlert(
          widget.parent.id,
          widget.parent.name,
          readingType,
          alertValue,
          sw,
        );
      }
    } catch (_) {}
  }

  // ─── Add Sheets ─────────────────────────────────────────────────

  void _showAddBP() {
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();
    final pulseCtrl = TextEditingController();
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddReadingSheet(
        title: sw ? 'Ongeza Shinikizo la Damu' : 'Add Blood Pressure',
        children: [
          Row(
            children: [
              Expanded(child: _SheetField(controller: sysCtrl,
                  label: 'Systolic', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _SheetField(controller: diaCtrl,
                  label: 'Diastolic', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _SheetField(controller: pulseCtrl,
                  label: sw ? 'Mapigo' : 'Pulse', keyboardType: TextInputType.number)),
            ],
          ),
        ],
        onSave: () {
          final sys = double.tryParse(sysCtrl.text.trim());
          final dia = double.tryParse(diaCtrl.text.trim());
          if (sys == null || dia == null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(sw
                  ? 'Tafadhali jaza systolic na diastolic'
                  : 'Please enter systolic and diastolic')),
            );
            return;
          }
          final pulse = pulseCtrl.text.trim();
          Navigator.pop(ctx);
          _saveReading(
            type: 'blood_pressure',
            value: sys,
            value2: dia,
            unit: 'mmHg',
            notes: pulse.isNotEmpty ? 'Pulse: $pulse' : null,
          );
        },
      ),
    ).then((_) {
      sysCtrl.dispose();
      diaCtrl.dispose();
      pulseCtrl.dispose();
    });
  }

  void _showAddSugar() {
    final valueCtrl = TextEditingController();
    String sugarType = 'fasting';
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _AddReadingSheet(
          title: sw ? 'Ongeza Sukari ya Damu' : 'Add Blood Sugar',
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sugarType,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'fasting',
                        child: Text(sw ? 'Kabla ya kula' : 'Fasting')),
                    DropdownMenuItem(value: 'random',
                        child: Text(sw ? 'Nasibu' : 'Random')),
                    DropdownMenuItem(value: 'post_meal',
                        child: Text(sw ? 'Baada ya kula' : 'Post-meal')),
                  ],
                  onChanged: (v) {
                    if (v != null) setSheetState(() => sugarType = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SheetField(
              controller: valueCtrl,
              label: sw ? 'Thamani (mmol/L)' : 'Value (mmol/L)',
              keyboardType: TextInputType.number,
            ),
          ],
          onSave: () {
            final val = double.tryParse(valueCtrl.text.trim());
            if (val == null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(sw
                    ? 'Tafadhali ingiza thamani'
                    : 'Please enter a value')),
              );
              return;
            }
            Navigator.pop(ctx);
            _saveReading(
              type: 'blood_sugar',
              value: val,
              unit: 'mmol/L',
              notes: sugarType,
            );
          },
        ),
      ),
    ).then((_) => valueCtrl.dispose());
  }

  void _showAddWeight() {
    final valueCtrl = TextEditingController();
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddReadingSheet(
        title: sw ? 'Ongeza Uzito' : 'Add Weight',
        children: [
          _SheetField(
            controller: valueCtrl,
            label: sw ? 'Uzito (kg)' : 'Weight (kg)',
            keyboardType: TextInputType.number,
          ),
        ],
        onSave: () {
          final val = double.tryParse(valueCtrl.text.trim());
          if (val == null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(sw
                  ? 'Tafadhali ingiza uzito'
                  : 'Please enter weight')),
            );
            return;
          }
          Navigator.pop(ctx);
          _saveReading(type: 'weight', value: val, unit: 'kg');
        },
      ),
    ).then((_) => valueCtrl.dispose());
  }

  void _showAddSymptom() {
    final locationCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    double severity = 5;
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _AddReadingSheet(
          title: sw ? 'Ongeza Dalili' : 'Add Symptom',
          children: [
            _SheetField(
              controller: locationCtrl,
              label: sw ? 'Eneo (mfano: kichwa, tumbo)' : 'Location (e.g. head, stomach)',
            ),
            const SizedBox(height: 12),
            Text(
              '${sw ? 'Ukali' : 'Severity'}: ${severity.toInt()}/10',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            Slider(
              value: severity,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: _kPrimary,
              onChanged: (v) => setSheetState(() => severity = v),
            ),
            const SizedBox(height: 8),
            _SheetField(
              controller: durationCtrl,
              label: sw ? 'Muda (mfano: siku 2)' : 'Duration (e.g. 2 days)',
            ),
            const SizedBox(height: 12),
            _SheetField(
              controller: notesCtrl,
              label: sw ? 'Maelezo' : 'Notes',
              maxLines: 3,
            ),
          ],
          onSave: () {
            final location = locationCtrl.text.trim();
            if (location.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(sw
                    ? 'Tafadhali ingiza eneo'
                    : 'Please enter location')),
              );
              return;
            }
            Navigator.pop(ctx);
            final notes = [
              location,
              if (durationCtrl.text.trim().isNotEmpty) 'Duration: ${durationCtrl.text.trim()}',
              if (notesCtrl.text.trim().isNotEmpty) notesCtrl.text.trim(),
            ].join(' | ');
            _saveReading(
              type: 'symptom',
              value: severity,
              notes: notes,
            );
          },
        ),
      ),
    ).then((_) {
      locationCtrl.dispose();
      durationCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  // ─── BP Helpers ─────────────────────────────────────────────────

  bool _isBPAbnormal(ParentHealthReading r) {
    final sys = r.value;
    final dia = r.value2 ?? 0;
    return sys > 140 || dia > 90 || sys < 90 || dia < 60;
  }

  bool _isSugarAbnormal(ParentHealthReading r) {
    final val = r.value;
    final type = r.notes ?? 'fasting';
    if (type.contains('fasting')) return val > 7.0;
    return val > 11.1;
  }

  bool get _hasAbnormalBP => _bpReadings.any(_isBPAbnormal);
  bool get _hasAbnormalSugar => _sugarReadings.any(_isSugarAbnormal);

  String _bmiCategory(double bmi, bool sw) {
    if (bmi < 18.5) return sw ? 'Uzito mdogo' : 'Underweight';
    if (bmi < 25.0) return sw ? 'Kawaida' : 'Normal';
    if (bmi < 30.0) return sw ? 'Uzito mkubwa' : 'Overweight';
    return sw ? 'Unene kupita kiasi' : 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return _kWarning;
    if (bmi < 25.0) return _kSuccess;
    if (bmi < 30.0) return _kWarning;
    return _kDanger;
  }

  void _showEditHeightDialog() {
    final sw = _sw;
    final ctrl = TextEditingController(text: _parentHeight.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Urefu wa Mzazi (m)' : 'Parent Height (m)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: sw ? 'mfano: 1.65' : 'e.g. 1.65',
            filled: true,
            fillColor: _kPrimary.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () {
              final h = double.tryParse(ctrl.text.trim());
              if (h != null && h > 0.5 && h < 2.5) {
                setState(() => _parentHeight = h);
                _saveHeight(h);
                Navigator.pop(ctx);
              }
            },
            child: Text(sw ? 'Hifadhi' : 'Save',
                style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  Widget _buildCrossModuleLinks(bool sw) {
    final hasAbnormal = _hasAbnormalBP || _hasAbnormalSugar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        if (hasAbnormal)
          _buildCrossModuleLink(
            icon: Icons.medical_services_rounded,
            label: sw
                ? 'Vipimo visivyo kawaida? Panga miadi na daktari'
                : 'Abnormal readings? Book a doctor appointment',
            onTap: () {
              try { Navigator.pushNamed(context, '/doctor'); } catch (_) {}
            },
          ),
        _buildCrossModuleLink(
          icon: Icons.smart_toy_rounded,
          label: sw
              ? 'Uliza Shangazi kuhusu kudhibiti hali ya afya'
              : 'Ask Shangazi about managing health conditions',
          onTap: () {
            try { Navigator.pushNamed(context, '/chat/0'); } catch (_) {}
          },
        ),
        _buildCrossModuleLink(
          icon: Icons.calendar_month_rounded,
          label: sw
              ? 'Weka ukaguzi wa afya wa kila mwezi'
              : 'Set monthly health check reminder',
          onTap: () {
            _scheduleMonthlyHealthCheck(sw);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  void _scheduleMonthlyHealthCheck(bool sw) {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Actually schedule a monthly health check notification
      ParentsNotificationHelper.scheduleMonthlyHealthCheck(
        widget.parent.id,
        widget.parent.name,
        sw,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(sw
            ? 'Ukumbusho wa afya wa kila mwezi umewekwa'
            : 'Monthly health check reminder set')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(sw
            ? 'Imeshindwa kuweka ukumbusho'
            : 'Failed to set reminder')),
      );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────

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
          sw ? 'Ufuatiliaji wa Afya' : 'Health Monitor',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: sw ? 'Shinikizo' : 'Blood Pressure'),
            Tab(text: sw ? 'Sukari' : 'Blood Sugar'),
            Tab(text: sw ? 'Uzito' : 'Weight'),
            Tab(text: sw ? 'Dalili' : 'Symptoms'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBPTab(sw),
                _buildSugarTab(sw),
                _buildWeightTab(sw),
                _buildSymptomTab(sw),
              ],
            ),
    );
  }

  // ─── Blood Pressure Tab ─────────────────────────────────────────

  Widget _buildBPTab(bool sw) {
    return RefreshIndicator(
      onRefresh: _loadReadings,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Weekly average card
          if (_bpReadings.isNotEmpty) ...[
            _buildBPWeeklyAverage(sw),
            const SizedBox(height: 16),
            // Trend bars (last 7)
            _buildBPTrend(sw),
            const SizedBox(height: 16),
          ],
          // Add button
          _AddButton(
            label: sw ? 'Ongeza Kipimo' : 'Add Reading',
            onPressed: _showAddBP,
          ),
          const SizedBox(height: 16),
          // History
          if (_bpReadings.isEmpty)
            _EmptyState(
              icon: Icons.monitor_heart_rounded,
              label: sw ? 'Hakuna vipimo' : 'No readings yet',
            )
          else
            ..._bpReadings.map((r) => _buildBPReadingCard(r, sw)),
          _buildCrossModuleLinks(sw),
        ],
      ),
    );
  }

  Widget _buildBPWeeklyAverage(bool sw) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekReadings = _bpReadings
        .where((r) => r.measuredAt.isAfter(weekAgo))
        .toList();
    if (weekReadings.isEmpty) return const SizedBox.shrink();

    final avgSys = weekReadings.map((r) => r.value).reduce((a, b) => a + b) / weekReadings.length;
    final avgDia = weekReadings.map((r) => r.value2 ?? 0).reduce((a, b) => a + b) / weekReadings.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sw ? 'Wastani wa Wiki' : 'Weekly Average',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${avgSys.toStringAsFixed(0)}/${avgDia.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(width: 6),
              Text('mmHg',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
              const Spacer(),
              Text(
                '${weekReadings.length} ${sw ? 'vipimo' : 'readings'}',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBPTrend(bool sw) {
    final last7 = _bpReadings.take(7).toList().reversed.toList();
    if (last7.isEmpty) return const SizedBox.shrink();

    final maxSys = last7.map((r) => r.value).reduce(math.max);
    final maxVal = maxSys > 0 ? maxSys : 180.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sw ? 'Mwelekeo (Vipimo 7)' : 'Trend (Last 7 Readings)',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: last7.map((r) {
                final height = (r.value / maxVal) * 50;
                final abnormal = _isBPAbnormal(r);
                return Tooltip(
                  message: '${r.value.toStringAsFixed(0)}/${(r.value2 ?? 0).toStringAsFixed(0)}',
                  child: Container(
                    width: 20,
                    height: math.max(height, 4),
                    decoration: BoxDecoration(
                      color: abnormal ? _kDanger.withValues(alpha: 0.7) : _kPrimary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBPReadingCard(ParentHealthReading r, bool sw) {
    final abnormal = _isBPAbnormal(r);
    return GestureDetector(
      onLongPress: () => _deleteReading(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: abnormal
              ? Border.all(color: _kDanger.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (abnormal ? _kDanger : _kSuccess).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.monitor_heart_rounded,
                size: 18,
                color: abnormal ? _kDanger : _kSuccess,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.value.toStringAsFixed(0)}/${(r.value2 ?? 0).toStringAsFixed(0)} mmHg',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (r.notes != null && r.notes!.isNotEmpty)
                    Text(r.notes!,
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${r.measuredAt.day}/${r.measuredAt.month}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
                if (abnormal)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: InkWell(
                      onTap: () {
                        try {
                          Navigator.pushNamed(context, '/doctor');
                        } catch (_) {}
                      },
                      child: Text(
                        sw ? 'Ona Daktari' : 'See Doctor',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _kDanger,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Blood Sugar Tab ────────────────────────────────────────────

  Widget _buildSugarTab(bool sw) {
    return RefreshIndicator(
      onRefresh: _loadReadings,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_sugarReadings.isNotEmpty) ...[
            _buildSugarWeeklyAverage(sw),
            const SizedBox(height: 16),
          ],
          _AddButton(
            label: sw ? 'Ongeza Kipimo' : 'Add Reading',
            onPressed: _showAddSugar,
          ),
          const SizedBox(height: 16),
          if (_sugarReadings.isEmpty)
            _EmptyState(
              icon: Icons.water_drop_rounded,
              label: sw ? 'Hakuna vipimo' : 'No readings yet',
            )
          else
            ..._sugarReadings.map((r) => _buildSugarReadingCard(r, sw)),
          _buildCrossModuleLinks(sw),
        ],
      ),
    );
  }

  Widget _buildSugarWeeklyAverage(bool sw) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekReadings = _sugarReadings
        .where((r) => r.measuredAt.isAfter(weekAgo))
        .toList();
    if (weekReadings.isEmpty) return const SizedBox.shrink();

    final avg = weekReadings.map((r) => r.value).reduce((a, b) => a + b) / weekReadings.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sw ? 'Wastani wa Wiki' : 'Weekly Average',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(width: 6),
              Text('mmol/L',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSugarReadingCard(ParentHealthReading r, bool sw) {
    final abnormal = _isSugarAbnormal(r);
    final typeLabel = (r.notes ?? '').contains('fasting')
        ? (sw ? 'Kabla ya kula' : 'Fasting')
        : (r.notes ?? '').contains('post')
            ? (sw ? 'Baada ya kula' : 'Post-meal')
            : (sw ? 'Nasibu' : 'Random');

    return GestureDetector(
      onLongPress: () => _deleteReading(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: abnormal
              ? Border.all(color: _kDanger.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (abnormal ? _kDanger : _kSuccess).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.water_drop_rounded, size: 18,
                  color: abnormal ? _kDanger : _kSuccess),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.value.toStringAsFixed(1)} mmol/L',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(typeLabel,
                      style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${r.measuredAt.day}/${r.measuredAt.month}',
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
                if (abnormal)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: InkWell(
                      onTap: () {
                        try { Navigator.pushNamed(context, '/doctor'); } catch (_) {}
                      },
                      child: Text(
                        sw ? 'Ona Daktari' : 'See Doctor',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: _kDanger, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Weight Tab ─────────────────────────────────────────────────

  Widget _buildWeightTab(bool sw) {
    return RefreshIndicator(
      onRefresh: _loadReadings,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_weightReadings.isNotEmpty) ...[
            _buildWeightCard(sw),
            const SizedBox(height: 16),
          ],
          _AddButton(
            label: sw ? 'Ongeza Uzito' : 'Add Weight',
            onPressed: _showAddWeight,
          ),
          const SizedBox(height: 16),
          if (_weightReadings.isEmpty)
            _EmptyState(
              icon: Icons.monitor_weight_rounded,
              label: sw ? 'Hakuna vipimo' : 'No readings yet',
            )
          else
            ..._weightReadings.map((r) => _buildWeightReadingCard(r, sw)),
          _buildCrossModuleLinks(sw),
        ],
      ),
    );
  }

  Widget _buildWeightCard(bool sw) {
    final latest = _weightReadings.first;
    final bmi = latest.value / (_parentHeight * _parentHeight);
    final category = _bmiCategory(bmi, sw);
    final bmiCol = _bmiColor(bmi);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sw ? 'Uzito wa Sasa' : 'Current Weight',
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${latest.value.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('BMI', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: bmiCol),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: bmiCol.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w600, color: bmiCol),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Height row with edit button
          Row(
            children: [
              Text(
                '${sw ? 'Urefu' : 'Height'}: ${_parentHeight.toStringAsFixed(2)}m',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _showEditHeightDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    sw ? 'Badilisha' : 'Edit',
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                ),
              ),
            ],
          ),
          if (_weightReadings.length > 1) ...[
            const SizedBox(height: 6),
            () {
              final delta = latest.value - _weightReadings[1].value;
              final sign = delta > 0 ? '+' : '';
              return Text(
                '${sw ? 'Mwelekeo' : 'Trend'}: $sign${delta.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 11,
                  color: delta.abs() < 0.1 ? _kSecondary : (delta > 0 ? _kWarning : _kSuccess),
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightReadingCard(ParentHealthReading r, bool sw) {
    return GestureDetector(
      onLongPress: () => _deleteReading(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.monitor_weight_rounded, size: 18, color: _kSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${r.value.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${r.measuredAt.day}/${r.measuredAt.month}/${r.measuredAt.year}',
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
      ),
    );
  }

  // ─── Symptoms Tab ───────────────────────────────────────────────

  Widget _buildSymptomTab(bool sw) {
    return RefreshIndicator(
      onRefresh: _loadReadings,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AddButton(
            label: sw ? 'Ongeza Dalili' : 'Add Symptom',
            onPressed: _showAddSymptom,
          ),
          const SizedBox(height: 16),
          if (_symptomReadings.isEmpty)
            _EmptyState(
              icon: Icons.healing_rounded,
              label: sw ? 'Hakuna dalili' : 'No symptoms recorded',
            )
          else
            ..._symptomReadings.map((r) => _buildSymptomCard(r, sw)),
          _buildCrossModuleLinks(sw),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(ParentHealthReading r, bool sw) {
    final parts = (r.notes ?? '').split(' | ');
    final location = parts.isNotEmpty ? parts[0] : '';
    final severity = r.value.toInt();

    return GestureDetector(
      onLongPress: () => _deleteReading(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: severity >= 7
              ? Border.all(color: _kDanger.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: severity >= 7
                        ? _kDanger.withValues(alpha: 0.1)
                        : _kWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.healing_rounded, size: 18,
                      color: severity >= 7 ? _kDanger : _kWarning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${sw ? 'Ukali' : 'Severity'}: $severity/10',
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${r.measuredAt.day}/${r.measuredAt.month}',
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                    if (severity >= 7)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: InkWell(
                          onTap: () {
                            try { Navigator.pushNamed(context, '/doctor'); } catch (_) {}
                          },
                          child: Text(
                            sw ? 'Ona Daktari' : 'See Doctor',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: _kDanger, decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (parts.length > 1) ...[
              const SizedBox(height: 6),
              Text(
                parts.sublist(1).join(' | '),
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AddButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimary,
          side: BorderSide(color: _kPrimary.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AddReadingSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  const _AddReadingSheet({
    required this.title,
    required this.children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  AppStringsScope.of(context)?.isSwahili ?? false
                      ? 'Hifadhi'
                      : 'Save',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int? maxLines;

  const _SheetField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
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
