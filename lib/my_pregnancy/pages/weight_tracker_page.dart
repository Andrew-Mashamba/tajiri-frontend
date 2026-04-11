// lib/my_pregnancy/pages/weight_tracker_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class WeightTrackerPage extends StatefulWidget {
  final Pregnancy pregnancy;
  final double? prePregnancyWeightKg;
  final double? heightCm;

  const WeightTrackerPage({
    super.key,
    required this.pregnancy,
    this.prePregnancyWeightKg,
    this.heightCm,
  });

  @override
  State<WeightTrackerPage> createState() => _WeightTrackerPageState();
}

class _WeightTrackerPageState extends State<WeightTrackerPage> {
  final MyPregnancyService _service = MyPregnancyService();

  List<_WeightEntry> _entries = [];
  bool _isLoading = true;

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili == true;

  // ─── BMI category ───────────────────────────────────────────

  String get _bmiCategory {
    final w = widget.prePregnancyWeightKg;
    final h = widget.heightCm;
    if (w == null || h == null || h <= 0) return 'normal';
    final bmi = w / ((h / 100) * (h / 100));
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  /// Returns (min, max) recommended total gain in kg
  (double, double) get _recommendedGainRange {
    switch (_bmiCategory) {
      case 'underweight':
        return (12.5, 18.0);
      case 'normal':
        return (11.5, 16.0);
      case 'overweight':
        return (7.0, 11.5);
      case 'obese':
        return (5.0, 9.0);
      default:
        return (11.5, 16.0);
    }
  }

  String _bmiCategoryLabel(bool sw) {
    switch (_bmiCategory) {
      case 'underweight':
        return sw ? 'Uzito mdogo' : 'Underweight';
      case 'normal':
        return sw ? 'Kawaida' : 'Normal';
      case 'overweight':
        return sw ? 'Uzito kupita' : 'Overweight';
      case 'obese':
        return sw ? 'Unene kupita' : 'Obese';
      default:
        return sw ? 'Kawaida' : 'Normal';
    }
  }

  // ─── Data ───────────────────────────────────────────────────

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getWeightEntries(
        pregnancyId: widget.pregnancy.id,
        token: _token,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _entries = result.items
              .map((j) => _WeightEntry(
                    id: j['id'] as int? ?? 0,
                    weightKg: _parseDouble(j['weight_kg']),
                    date: DateTime.tryParse(
                            j['date']?.toString() ?? '') ??
                        DateTime.now(),
                    weekNumber: j['week_number'] as int? ?? 0,
                  ))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWeightEntry(double weightKg, DateTime date) async {
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    try {
      final result = await _service.saveWeightEntry(
        pregnancyId: widget.pregnancy.id,
        weightKg: weightKg,
        date: date,
        weekNumber: widget.pregnancy.currentWeek,
        token: _token,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content:
                Text(sw ? 'Uzito umehifadhiwa' : 'Weight saved'),
          ),
        );
        _loadEntries();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(sw ? 'Kosa: $e' : 'Error: $e')),
      );
    }
  }

  Future<void> _deleteEntry(int entryId) async {
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    try {
      final result = await _service.deleteWeightEntry(entryId: entryId, token: _token);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(sw ? 'Imefutwa' : 'Deleted'),
          ),
        );
        _loadEntries();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message ?? (sw ? 'Imeshindwa kufuta' : 'Failed to delete')),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(sw ? 'Imeshindwa kufuta' : 'Failed to delete'),
        ),
      );
    }
  }

  void _showAddDialog() {
    final sw = _sw;
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Ongeza Uzito' : 'Add Weight',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Weight input
                  TextField(
                    controller: weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: sw ? 'Uzito (kg)' : 'Weight (kg)',
                      hintText: sw ? 'Mfano: 65.5' : 'e.g. 65.5',
                      labelStyle:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 300)),
                        lastDate: DateTime.now(),
                        helpText: sw ? 'Chagua tarehe' : 'Select date',
                        cancelText: sw ? 'Ghairi' : 'Cancel',
                        confirmText: sw ? 'Chagua' : 'Select',
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: _kSecondary),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sw ? 'Tarehe' : 'Date',
                                style: const TextStyle(
                                    fontSize: 11, color: _kSecondary),
                              ),
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        final weight =
                            double.tryParse(weightController.text.trim());
                        if (weight == null || weight <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(sw
                                  ? 'Weka uzito sahihi'
                                  : 'Enter a valid weight'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        _addWeightEntry(weight, selectedDate);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Chart ──────────────────────────────────────────────────

  Widget _buildChart(bool sw) {
    if (_entries.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 36, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                sw ? 'Bado hakuna data ya uzito' : 'No weight data yet',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    // Find min/max for scaling
    final weights = _entries.map((e) => e.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b) - 2;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 2;
    final range = maxW - minW;

    final gain = _recommendedGainRange;
    final startWeight = widget.prePregnancyWeightKg ?? (_entries.isNotEmpty ? _entries.first.weightKg : 60);
    final recMin = startWeight + (gain.$1 * widget.pregnancy.currentWeek / 40);
    final recMax = startWeight + (gain.$2 * widget.pregnancy.currentWeek / 40);

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
            sw ? 'Chati ya Uzito' : 'Weight Chart',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = _entries.length <= 1
                    ? 40.0
                    : ((constraints.maxWidth - 40) / _entries.length)
                        .clamp(12.0, 40.0);
                final totalWidth = barWidth * _entries.length;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth.clamp(constraints.maxWidth, 2000.0),
                    height: 180,
                    child: CustomPaint(
                      painter: _WeightChartPainter(
                        entries: _entries,
                        minW: minW,
                        maxW: maxW,
                        range: range,
                        recMin: recMin,
                        recMax: recMax,
                        barWidth: barWidth,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(sw ? 'Uzito wako' : 'Your weight',
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(sw ? 'Kiwango bora' : 'Recommended',
                  style: const TextStyle(fontSize: 11, color: _kTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final gain = _recommendedGainRange;
    final totalGain = _entries.isNotEmpty && widget.prePregnancyWeightKg != null
        ? _entries.last.weightKg - widget.prePregnancyWeightKg!
        : null;

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
          sw ? 'Kufuatilia Uzito' : 'Weight Tracker',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadEntries,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  children: [
                    // Current weight card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.monitor_weight_rounded,
                                size: 24, color: _kPrimary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sw ? 'Uzito wa Sasa' : 'Current Weight',
                                  style: const TextStyle(
                                      fontSize: 12, color: _kSecondary),
                                ),
                                Text(
                                  _entries.isNotEmpty
                                      ? '${_entries.last.weightKg.toStringAsFixed(1)} kg'
                                      : '-',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: _kPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (totalGain != null)
                                  Text(
                                    '${totalGain >= 0 ? '+' : ''}${totalGain.toStringAsFixed(1)} kg ${sw ? 'tangu mwanzo' : 'since start'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Recommended range card
                    Container(
                      padding: const EdgeInsets.all(14),
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
                                  ? 'BMI: ${_bmiCategoryLabel(sw)}. Ongezeko bora: ${gain.$1.toStringAsFixed(1)}-${gain.$2.toStringAsFixed(1)} kg kwa ujauzito wote.'
                                  : 'BMI: ${_bmiCategoryLabel(sw)}. Recommended gain: ${gain.$1.toStringAsFixed(1)}-${gain.$2.toStringAsFixed(1)} kg for entire pregnancy.',
                              style: const TextStyle(
                                  fontSize: 12, color: _kSecondary),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chart
                    _buildChart(sw),
                    const SizedBox(height: 20),

                    // History
                    Text(
                      sw ? 'Historia ya Uzito' : 'Weight History',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                    ),
                    const SizedBox(height: 10),
                    if (_entries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.scale_rounded,
                                size: 36, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              sw ? 'Bado hakuna rekodi' : 'No records yet',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._entries.reversed.map((e) => _WeightHistoryItem(
                            entry: e,
                            isSwahili: sw,
                            prePregnancyWeight: widget.prePregnancyWeightKg,
                            onDelete: () => _deleteEntry(e.id),
                          )),
                    const SizedBox(height: 80), // FAB clearance
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Chart painter ────────────────────────────────────────────

class _WeightChartPainter extends CustomPainter {
  final List<_WeightEntry> entries;
  final double minW;
  final double maxW;
  final double range;
  final double recMin;
  final double recMax;
  final double barWidth;

  _WeightChartPainter({
    required this.entries,
    required this.minW,
    required this.maxW,
    required this.range,
    required this.recMin,
    required this.recMax,
    required this.barWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || range <= 0) return;

    final chartHeight = size.height - 24; // leave room for labels
    final leftPad = 0.0;

    // Draw recommended range band
    final recMinY = chartHeight - ((recMin - minW) / range * chartHeight);
    final recMaxY = chartHeight - ((recMax - minW) / range * chartHeight);
    final bandPaint = Paint()..color = const Color(0xFFE0E0E0).withValues(alpha: 0.5);
    canvas.drawRect(
      Rect.fromLTRB(leftPad, recMaxY.clamp(0, chartHeight),
          size.width, recMinY.clamp(0, chartHeight)),
      bandPaint,
    );

    // Draw bars
    final barPaint = Paint()..color = _kPrimary;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final x = leftPad + i * barWidth + barWidth * 0.2;
      final w = barWidth * 0.6;
      final barH = ((e.weightKg - minW) / range * chartHeight).clamp(4.0, chartHeight);
      final y = chartHeight - barH;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, w, barH),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        barPaint,
      );

      // Week label below
      textPainter.text = TextSpan(
        text: 'W${e.weekNumber}',
        style: const TextStyle(fontSize: 9, color: _kTertiary),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + w / 2 - textPainter.width / 2, chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── History item ─────────────────────────────────────────────

class _WeightHistoryItem extends StatelessWidget {
  final _WeightEntry entry;
  final bool isSwahili;
  final double? prePregnancyWeight;
  final VoidCallback onDelete;

  const _WeightHistoryItem({
    required this.entry,
    required this.isSwahili,
    this.prePregnancyWeight,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gain = prePregnancyWeight != null
        ? entry.weightKg - prePregnancyWeight!
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPrimary.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                'W${entry.weekNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.weightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (gain != null)
                  Text(
                    '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            _formatDate(entry.date),
            style: const TextStyle(fontSize: 11, color: _kTertiary),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: _kTertiary),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── Internal types ───────────────────────────────────────────

class _WeightEntry {
  final int id;
  final double weightKg;
  final DateTime date;
  final int weekNumber;

  const _WeightEntry({
    required this.id,
    required this.weightKg,
    required this.date,
    required this.weekNumber,
  });
}

double _parseDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}
