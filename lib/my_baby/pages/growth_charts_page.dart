// lib/my_baby/pages/growth_charts_page.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ─── WHO Percentile Data (Boys, 0-24 months) ─────────────────
// Simplified key percentiles for chart rendering.

/// Weight-for-age in kg, index = month (0-24)
const List<double> _who50Weight = [
  3.3, 4.5, 5.6, 6.4, 7.0, 7.5, 7.9, 8.3, 8.6, 8.9, 9.2,
  9.4, 9.6, 9.9, 10.1, 10.3, 10.5, 10.7, 10.9, 11.1, 11.3,
  11.5, 11.8, 12.0, 12.2,
];
const List<double> _who3Weight = [
  2.5, 3.4, 4.3, 5.0, 5.6, 6.0, 6.4, 6.7, 6.9, 7.1, 7.4,
  7.6, 7.7, 7.9, 8.1, 8.3, 8.4, 8.6, 8.8, 8.9, 9.1,
  9.2, 9.4, 9.5, 9.7,
];
const List<double> _who97Weight = [
  4.4, 5.8, 7.1, 8.0, 8.7, 9.3, 9.8, 10.3, 10.7, 11.0, 11.4,
  11.7, 12.0, 12.3, 12.6, 12.8, 13.1, 13.4, 13.7, 13.9, 14.2,
  14.5, 14.7, 15.0, 15.3,
];

/// Height-for-age in cm, index = month (0-24)
const List<double> _who50Height = [
  49.9, 54.7, 58.4, 61.4, 63.9, 65.9, 67.6, 69.2, 70.6, 72.0, 73.3,
  74.5, 75.7, 76.9, 78.0, 79.1, 80.2, 81.2, 82.3, 83.2, 84.2,
  85.1, 86.0, 86.9, 87.8,
];
const List<double> _who3Height = [
  46.1, 50.8, 54.4, 57.3, 59.7, 61.7, 63.3, 64.8, 66.2, 67.5, 68.7,
  69.9, 71.0, 72.1, 73.1, 74.1, 75.0, 76.0, 76.9, 77.7, 78.6,
  79.4, 80.2, 81.0, 81.7,
];
const List<double> _who97Height = [
  53.7, 58.6, 62.4, 65.5, 68.0, 70.1, 71.9, 73.5, 75.0, 76.5, 77.9,
  79.2, 80.5, 81.8, 82.9, 84.0, 85.2, 86.3, 87.3, 88.4, 89.5,
  90.5, 91.5, 92.5, 93.4,
];

/// Head circumference in cm, index = month (0-24)
const List<double> _who50Head = [
  34.5, 37.3, 39.1, 40.5, 41.6, 42.6, 43.3, 44.0, 44.5, 45.0, 45.4,
  45.8, 46.1, 46.3, 46.6, 46.8, 47.0, 47.2, 47.4, 47.5, 47.7,
  47.8, 48.0, 48.1, 48.3,
];
const List<double> _who3Head = [
  31.9, 34.9, 36.8, 38.3, 39.4, 40.3, 41.0, 41.7, 42.2, 42.6, 43.0,
  43.4, 43.6, 43.9, 44.1, 44.3, 44.5, 44.7, 44.8, 45.0, 45.2,
  45.3, 45.4, 45.5, 45.7,
];
const List<double> _who97Head = [
  37.0, 39.6, 41.5, 42.7, 43.8, 44.8, 45.6, 46.3, 46.9, 47.4, 47.8,
  48.2, 48.5, 48.8, 49.1, 49.3, 49.5, 49.7, 49.9, 50.1, 50.2,
  50.4, 50.5, 50.7, 50.8,
];

class GrowthChartsPage extends StatefulWidget {
  final Baby baby;

  const GrowthChartsPage({super.key, required this.baby});

  @override
  State<GrowthChartsPage> createState() => _GrowthChartsPageState();
}

class _GrowthChartsPageState extends State<GrowthChartsPage>
    with SingleTickerProviderStateMixin {
  final MyBabyService _service = MyBabyService();
  final GlobalKey _repaintKey = GlobalKey();
  String? _token;

  late TabController _tabController;
  List<GrowthMeasurement> _measurements = [];
  bool _isLoading = true;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getGrowthHistory(_token!, widget.baby.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _measurements = result.items;
          _measurements.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindikana kupakia' : 'Failed to load')),
      );
    }
  }

  Future<void> _shareChart() async {
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/growth_chart.png');
      await file.writeAsBytes(bytes);
      final tabLabel = _tabController.index == 0
          ? (_sw ? 'Uzito' : 'Weight')
          : _tabController.index == 1
              ? (_sw ? 'Urefu' : 'Height')
              : (_sw ? 'Kichwa' : 'Head');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: _sw
              ? 'Chati ya $tabLabel ya ${widget.baby.name}'
              : '$tabLabel chart for ${widget.baby.name}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindwa kushiriki' : 'Failed to share')),
      );
    }
  }

  // ─── Add Measurement ──────────────────────────────────────────

  void _showAddSheet() {
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final headCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sw ? 'Ongeza Kipimo' : 'Add Measurement',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      ctrl: weightCtrl,
                      label: _sw ? 'Uzito (kg)' : 'Weight (kg)',
                      hint: '0.0',
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      ctrl: heightCtrl,
                      label: _sw ? 'Urefu (cm)' : 'Height (cm)',
                      hint: '0.0',
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      ctrl: headCtrl,
                      label: _sw ? 'Kichwa (cm)' : 'Head (cm)',
                      hint: '0.0',
                    ),
                    const SizedBox(height: 12),
                    // Date picker
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: BorderSide(color: _kTertiary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: widget.baby.dateOfBirth,
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final w = double.tryParse(weightCtrl.text);
                          final h = double.tryParse(heightCtrl.text);
                          final hd = double.tryParse(headCtrl.text);
                          if (w == null && h == null && hd == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(_sw
                                  ? 'Weka angalau kipimo kimoja'
                                  : 'Enter at least one measurement'),
                            ));
                            return;
                          }
                          Navigator.pop(ctx);
                          _saveMeasurement(w, h, hd, selectedDate);
                        },
                        child: Text(
                          _sw ? 'Hifadhi' : 'Save',
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
            );
          },
        );
      },
    ).then((_) {
      weightCtrl.dispose();
      heightCtrl.dispose();
      headCtrl.dispose();
    });
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: _kTertiary, fontSize: 14),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Future<void> _saveMeasurement(
      double? w, double? h, double? hd, DateTime date) async {
    if (_token == null) return;
    try {
      final result = await _service.logGrowth(
        token: _token!,
        babyId: widget.baby.id,
        weightKg: w,
        heightCm: h,
        headCm: hd,
        measuredAt: date,
      );
      if (!mounted) return;
      if (result.success) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sw ? 'Imehifadhiwa' : 'Saved'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Hitilafu imetokea' : 'An error occurred')),
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────

  double? _latestValue(int tabIndex) {
    if (_measurements.isEmpty) return null;
    final last = _measurements.last;
    switch (tabIndex) {
      case 0:
        return last.weightKg;
      case 1:
        return last.heightCm;
      case 2:
        return last.headCm;
      default:
        return null;
    }
  }

  String _latestDate() {
    if (_measurements.isEmpty) return '--';
    final d = _measurements.last.measuredAt;
    return '${d.day}/${d.month}/${d.year}';
  }

  String _trendArrow(int tabIndex) {
    final vals = _measurements
        .map((m) {
          switch (tabIndex) {
            case 0:
              return m.weightKg;
            case 1:
              return m.heightCm;
            case 2:
              return m.headCm;
            default:
              return null;
          }
        })
        .where((v) => v != null)
        .cast<double>()
        .toList();
    if (vals.length < 2) return '';
    final diff = vals.last - vals[vals.length - 2];
    if (diff > 0.01) return '\u2191';
    if (diff < -0.01) return '\u2193';
    return '\u2192';
  }

  String? _percentileAlert(int tabIndex) {
    final vals = _measurements
        .map((m) {
          switch (tabIndex) {
            case 0:
              return m.weightKg;
            case 1:
              return m.heightCm;
            case 2:
              return m.headCm;
            default:
              return null;
          }
        })
        .where((v) => v != null)
        .cast<double>()
        .toList();
    if (vals.isEmpty) return null;

    final latestVal = vals.last;
    final ageMonths = widget.baby.ageInMonths.clamp(0, 24);

    List<double> p3;
    List<double> p97;
    switch (tabIndex) {
      case 0:
        p3 = _who3Weight;
        p97 = _who97Weight;
      case 1:
        p3 = _who3Height;
        p97 = _who97Height;
      default:
        p3 = _who3Head;
        p97 = _who97Head;
    }

    if (latestVal < p3[ageMonths]) {
      return _sw
          ? 'Chini ya asilimia ya 3 - wasiliana na daktari'
          : 'Below 3rd percentile - consult a doctor';
    }
    if (latestVal > p97[ageMonths]) {
      return _sw
          ? 'Juu ya asilimia ya 97 - wasiliana na daktari'
          : 'Above 97th percentile - consult a doctor';
    }
    return null;
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          _sw ? 'Ukuaji' : 'Growth',
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
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            tooltip: _sw ? 'Shiriki chati' : 'Share chart',
            onPressed: _measurements.isNotEmpty ? _shareChart : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kTertiary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: _sw ? 'Uzito' : 'Weight'),
            Tab(text: _sw ? 'Urefu' : 'Height'),
            Tab(text: _sw ? 'Kichwa' : 'Head'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _sw ? 'Ongeza Kipimo' : 'Add Measurement',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTab(0),
                  _buildTab(1),
                  _buildTab(2),
                ],
              ),
      ),
    );
  }

  Widget _buildTab(int tabIndex) {
    final latest = _latestValue(tabIndex);
    final unit = tabIndex == 0 ? 'kg' : 'cm';
    final alert = _percentileAlert(tabIndex);
    final trend = _trendArrow(tabIndex);

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Latest measurement card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sw ? 'Kipimo cha Hivi Karibuni' : 'Latest Measurement',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            latest != null
                                ? '${latest.toStringAsFixed(1)} $unit'
                                : '--',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                          if (trend.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              trend,
                              style: const TextStyle(
                                fontSize: 24,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _latestDate(),
                        style: const TextStyle(fontSize: 12, color: _kTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alert
          if (alert != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: _kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert,
                      style: const TextStyle(fontSize: 13, color: _kPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // WHO Chart
          RepaintBoundary(
            key: tabIndex == _tabController.index ? _repaintKey : null,
            child: Container(
              height: 260,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: _WHOChartPainter(
                  tabIndex: tabIndex,
                  measurements: _measurements,
                  babyDob: widget.baby.dateOfBirth,
                ),
              ),
            ),
          ),

          const SizedBox(height: 80), // space for FAB
        ],
      ),
    );
  }
}

// ─── WHO Chart Painter ──────────────────────────────────────────

class _WHOChartPainter extends CustomPainter {
  final int tabIndex;
  final List<GrowthMeasurement> measurements;
  final DateTime babyDob;

  _WHOChartPainter({
    required this.tabIndex,
    required this.measurements,
    required this.babyDob,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Select data
    List<double> p3, p50, p97;
    switch (tabIndex) {
      case 0:
        p3 = _who3Weight;
        p50 = _who50Weight;
        p97 = _who97Weight;
      case 1:
        p3 = _who3Height;
        p50 = _who50Height;
        p97 = _who97Height;
      default:
        p3 = _who3Head;
        p50 = _who50Head;
        p97 = _who97Head;
    }

    const int maxMonths = 24;
    final double yMin = p3.reduce(math.min) - 1;
    final double yMax = p97.reduce(math.max) + 1;

    const double leftPad = 32;
    const double bottomPad = 24;
    final double chartW = size.width - leftPad;
    final double chartH = size.height - bottomPad;

    double xForMonth(double month) => leftPad + (month / maxMonths) * chartW;
    double yForValue(double val) =>
        chartH - ((val - yMin) / (yMax - yMin)) * chartH;

    // Draw percentile band (3rd - 97th) as light grey fill
    final bandPaint = Paint()..color = _kTertiary.withValues(alpha: 0.12);
    final bandPath = Path();
    for (int m = 0; m <= maxMonths; m++) {
      final x = xForMonth(m.toDouble());
      if (m == 0) {
        bandPath.moveTo(x, yForValue(p97[m]));
      } else {
        bandPath.lineTo(x, yForValue(p97[m]));
      }
    }
    for (int m = maxMonths; m >= 0; m--) {
      bandPath.lineTo(xForMonth(m.toDouble()), yForValue(p3[m]));
    }
    bandPath.close();
    canvas.drawPath(bandPath, bandPaint);

    // Draw 50th percentile dashed line
    final medianPaint = Paint()
      ..color = _kTertiary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final medianPath = Path();
    for (int m = 0; m <= maxMonths; m++) {
      final x = xForMonth(m.toDouble());
      final y = yForValue(p50[m]);
      if (m == 0) {
        medianPath.moveTo(x, y);
      } else {
        medianPath.lineTo(x, y);
      }
    }
    // Dash effect via path metrics
    final dashWidth = 6.0;
    final dashGap = 4.0;
    for (final metric in medianPath.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final end = math.min(dist + dashWidth, metric.length);
        final seg = metric.extractPath(dist, end);
        canvas.drawPath(seg, medianPaint);
        dist += dashWidth + dashGap;
      }
    }

    // Draw user's data points
    final userValues = <Offset>[];
    for (final m in measurements) {
      double? val;
      switch (tabIndex) {
        case 0:
          val = m.weightKg;
        case 1:
          val = m.heightCm;
        default:
          val = m.headCm;
      }
      if (val == null) continue;
      final ageMonths =
          m.measuredAt.difference(babyDob).inDays / 30.44;
      if (ageMonths < 0 || ageMonths > maxMonths) continue;
      userValues.add(Offset(xForMonth(ageMonths), yForValue(val)));
    }

    if (userValues.isNotEmpty) {
      // Connect line
      final linePaint = Paint()
        ..color = _kPrimary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final linePath = Path();
      linePath.moveTo(userValues.first.dx, userValues.first.dy);
      for (int i = 1; i < userValues.length; i++) {
        linePath.lineTo(userValues[i].dx, userValues[i].dy);
      }
      canvas.drawPath(linePath, linePaint);

      // Dots
      final dotPaint = Paint()..color = _kPrimary;
      for (final pt in userValues) {
        canvas.drawCircle(pt, 4, dotPaint);
      }
    }

    // X-axis labels (months)
    final textStyle = TextStyle(color: _kTertiary, fontSize: 10);
    for (int m = 0; m <= maxMonths; m += 3) {
      final tp = TextPainter(
        text: TextSpan(text: '$m', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(xForMonth(m.toDouble()) - tp.width / 2, chartH + 4));
    }

    // Y-axis labels
    final yStep = ((yMax - yMin) / 5).ceilToDouble();
    for (double v = yMin.ceilToDouble(); v <= yMax; v += yStep) {
      final tp = TextPainter(
        text: TextSpan(text: v.toStringAsFixed(0), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, yForValue(v) - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _WHOChartPainter old) =>
      old.tabIndex != tabIndex ||
      old.measurements.length != measurements.length;
}
