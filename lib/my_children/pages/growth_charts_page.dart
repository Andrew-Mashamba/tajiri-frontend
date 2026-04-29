// lib/my_children/pages/growth_charts_page.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../services/children_notification_helper.dart';
import '../services/my_children_service.dart';
import '../../doctor/doctor_module.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ─── WHO Percentile Data (Boys, 0-24 months) ─────────────────
// Simplified key percentiles for chart rendering.

/// Weight-for-age BOYS in kg, index = month (0-24)
const List<double> _who50WeightBoys = [
  3.3, 4.5, 5.6, 6.4, 7.0, 7.5, 7.9, 8.3, 8.6, 8.9, 9.2,
  9.4, 9.6, 9.9, 10.1, 10.3, 10.5, 10.7, 10.9, 11.1, 11.3,
  11.5, 11.8, 12.0, 12.2,
];
const List<double> _who3WeightBoys = [
  2.5, 3.4, 4.3, 5.0, 5.6, 6.0, 6.4, 6.7, 6.9, 7.1, 7.4,
  7.6, 7.7, 7.9, 8.1, 8.3, 8.4, 8.6, 8.8, 8.9, 9.1,
  9.2, 9.4, 9.5, 9.7,
];
const List<double> _who97WeightBoys = [
  4.4, 5.8, 7.1, 8.0, 8.7, 9.3, 9.8, 10.3, 10.7, 11.0, 11.4,
  11.7, 12.0, 12.3, 12.6, 12.8, 13.1, 13.4, 13.7, 13.9, 14.2,
  14.5, 14.7, 15.0, 15.3,
];

/// Weight-for-age GIRLS in kg, index = month (0-24)
const List<double> _who50WeightGirls = [
  3.2, 4.2, 5.1, 5.8, 6.4, 6.9, 7.3, 7.6, 7.9, 8.2, 8.5,
  8.7, 8.9, 9.2, 9.4, 9.6, 9.8, 10.0, 10.2, 10.4, 10.6,
  10.9, 11.1, 11.3, 11.5,
];
const List<double> _who3WeightGirls = [
  2.4, 3.2, 3.9, 4.5, 5.0, 5.4, 5.7, 6.0, 6.3, 6.5, 6.7,
  6.9, 7.0, 7.2, 7.4, 7.6, 7.7, 7.9, 8.1, 8.2, 8.4,
  8.6, 8.7, 8.9, 9.0,
];
const List<double> _who97WeightGirls = [
  4.2, 5.5, 6.6, 7.5, 8.2, 8.8, 9.3, 9.8, 10.2, 10.6, 10.9,
  11.2, 11.5, 11.8, 12.1, 12.4, 12.6, 12.9, 13.2, 13.5, 13.7,
  14.0, 14.3, 14.6, 14.8,
];

/// Height-for-age BOYS in cm, index = month (0-24)
const List<double> _who50HeightBoys = [
  49.9, 54.7, 58.4, 61.4, 63.9, 65.9, 67.6, 69.2, 70.6, 72.0, 73.3,
  74.5, 75.7, 76.9, 78.0, 79.1, 80.2, 81.2, 82.3, 83.2, 84.2,
  85.1, 86.0, 86.9, 87.8,
];
const List<double> _who3HeightBoys = [
  46.1, 50.8, 54.4, 57.3, 59.7, 61.7, 63.3, 64.8, 66.2, 67.5, 68.7,
  69.9, 71.0, 72.1, 73.1, 74.1, 75.0, 76.0, 76.9, 77.7, 78.6,
  79.4, 80.2, 81.0, 81.7,
];
const List<double> _who97HeightBoys = [
  53.7, 58.6, 62.4, 65.5, 68.0, 70.1, 71.9, 73.5, 75.0, 76.5, 77.9,
  79.2, 80.5, 81.8, 82.9, 84.0, 85.2, 86.3, 87.3, 88.4, 89.5,
  90.5, 91.5, 92.5, 93.4,
];

/// Height-for-age GIRLS in cm, index = month (0-24)
const List<double> _who50HeightGirls = [
  49.1, 53.7, 57.1, 59.8, 62.1, 64.0, 65.7, 67.3, 68.7, 70.1, 71.5,
  72.8, 74.0, 75.2, 76.4, 77.5, 78.6, 79.7, 80.7, 81.7, 82.7,
  83.7, 84.6, 85.5, 86.4,
];
const List<double> _who3HeightGirls = [
  45.4, 49.8, 53.0, 55.6, 57.8, 59.6, 61.2, 62.7, 64.0, 65.3, 66.5,
  67.7, 68.9, 70.0, 71.0, 72.0, 73.0, 74.0, 74.9, 75.8, 76.7,
  77.5, 78.4, 79.2, 80.0,
];
const List<double> _who97HeightGirls = [
  52.9, 57.6, 61.1, 64.0, 66.4, 68.5, 70.3, 71.9, 73.5, 75.0, 76.4,
  77.8, 79.2, 80.5, 81.7, 83.0, 84.2, 85.4, 86.5, 87.6, 88.7,
  89.8, 90.8, 91.9, 92.9,
];

// ─── CDC Percentile Data (Ages 2-18 years) ─────────────────
// Key ages in years: 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
// Boys & Girls, 3rd/50th/97th percentiles.

/// CDC Weight BOYS 50th percentile in kg, index maps to age 2-18
const List<double> _cdc50WeightBoys = [
  12.3, 14.3, 16.3, 18.4, 20.7, 23.1, 25.6, 28.6, 31.9, 35.9, 40.5,
  45.8, 51.0, 56.0, 60.8, 64.4, 67.5,
];
const List<double> _cdc3WeightBoys = [
  10.5, 12.0, 13.5, 15.0, 16.5, 18.3, 20.0, 22.0, 24.0, 26.5, 29.5,
  33.0, 37.0, 41.0, 44.5, 47.5, 50.0,
];
const List<double> _cdc97WeightBoys = [
  15.5, 17.8, 20.5, 23.5, 27.0, 31.0, 35.5, 40.5, 46.0, 52.0, 58.0,
  64.0, 70.0, 75.0, 80.0, 84.0, 87.0,
];

/// CDC Weight GIRLS 50th percentile in kg, index maps to age 2-18
const List<double> _cdc50WeightGirls = [
  11.5, 13.9, 16.1, 18.2, 20.2, 22.4, 25.0, 28.1, 31.9, 36.9, 41.5,
  45.3, 48.0, 50.6, 53.0, 54.4, 55.5,
];
const List<double> _cdc3WeightGirls = [
  9.7, 11.4, 13.0, 14.5, 15.9, 17.5, 19.0, 21.0, 23.5, 26.5, 30.0,
  33.5, 36.5, 39.0, 41.0, 42.5, 43.5,
];
const List<double> _cdc97WeightGirls = [
  14.8, 17.5, 20.5, 24.0, 27.5, 31.5, 36.0, 41.0, 47.0, 53.0, 58.0,
  62.0, 65.0, 67.5, 70.0, 72.0, 73.5,
];

/// CDC Height BOYS 50th percentile in cm, index maps to age 2-18
const List<double> _cdc50HeightBoys = [
  87.0, 95.0, 102.0, 109.5, 115.5, 121.5, 127.5, 133.0, 138.0, 143.5,
  149.0, 156.0, 163.5, 170.0, 174.0, 176.0, 177.0,
];
const List<double> _cdc3HeightBoys = [
  82.0, 89.5, 96.0, 102.0, 108.0, 113.5, 119.0, 124.0, 128.5, 133.5,
  138.0, 144.0, 151.0, 157.5, 162.0, 164.5, 165.5,
];
const List<double> _cdc97HeightBoys = [
  92.0, 100.5, 108.0, 117.0, 123.0, 129.5, 136.0, 142.0, 148.0, 154.0,
  160.5, 168.0, 176.0, 182.5, 186.0, 187.5, 188.5,
];

/// CDC Height GIRLS 50th percentile in cm, index maps to age 2-18
const List<double> _cdc50HeightGirls = [
  86.0, 94.0, 101.0, 107.5, 115.0, 120.5, 126.5, 132.5, 138.0, 144.0,
  151.0, 157.0, 160.5, 162.0, 163.0, 163.5, 163.5,
];
const List<double> _cdc3HeightGirls = [
  81.0, 88.5, 95.0, 101.0, 107.5, 113.0, 118.5, 124.0, 129.0, 134.5,
  140.5, 147.0, 150.5, 152.0, 153.0, 153.5, 153.5,
];
const List<double> _cdc97HeightGirls = [
  91.0, 99.5, 107.0, 114.0, 122.5, 128.0, 134.5, 141.0, 147.5, 154.0,
  161.5, 167.5, 170.5, 172.0, 173.0, 173.5, 173.5,
];

/// CDC BMI BOYS percentiles, index maps to age 2-18 (17 entries)
const List<double> _cdc50BmiBoys = [
  16.4, 15.8, 15.5, 15.4, 15.4, 15.5, 15.8, 16.0, 16.4, 16.9, 17.6,
  18.4, 19.2, 20.0, 20.7, 21.2, 21.6,
];
const List<double> _cdc3BmiBoys = [
  14.8, 14.2, 13.9, 13.8, 13.7, 13.7, 13.8, 13.9, 14.0, 14.2, 14.5,
  14.9, 15.3, 15.7, 16.1, 16.4, 16.7,
];
const List<double> _cdc97BmiBoys = [
  19.4, 18.8, 18.5, 18.3, 18.7, 19.3, 20.2, 21.2, 22.3, 23.5, 24.6,
  25.7, 26.6, 27.3, 27.8, 28.1, 28.3,
];

/// CDC BMI GIRLS percentiles, index maps to age 2-18 (17 entries)
const List<double> _cdc50BmiGirls = [
  16.0, 15.5, 15.3, 15.2, 15.3, 15.5, 15.8, 16.2, 16.7, 17.4, 18.1,
  18.9, 19.7, 20.4, 20.9, 21.3, 21.5,
];
const List<double> _cdc3BmiGirls = [
  14.4, 13.9, 13.6, 13.5, 13.4, 13.4, 13.5, 13.7, 14.0, 14.4, 14.8,
  15.2, 15.6, 16.0, 16.4, 16.7, 17.0,
];
const List<double> _cdc97BmiGirls = [
  19.0, 18.5, 18.3, 18.2, 18.6, 19.3, 20.3, 21.4, 22.5, 23.7, 24.7,
  25.7, 26.5, 27.1, 27.5, 27.7, 27.8,
];

/// Head circumference BOYS in cm, index = month (0-24)
const List<double> _who50HeadBoys = [
  34.5, 37.3, 39.1, 40.5, 41.6, 42.6, 43.3, 44.0, 44.5, 45.0, 45.4,
  45.8, 46.1, 46.3, 46.6, 46.8, 47.0, 47.2, 47.4, 47.5, 47.7,
  47.8, 48.0, 48.1, 48.3,
];
const List<double> _who3HeadBoys = [
  31.9, 34.9, 36.8, 38.3, 39.4, 40.3, 41.0, 41.7, 42.2, 42.6, 43.0,
  43.4, 43.6, 43.9, 44.1, 44.3, 44.5, 44.7, 44.8, 45.0, 45.2,
  45.3, 45.4, 45.5, 45.7,
];
const List<double> _who97HeadBoys = [
  37.0, 39.6, 41.5, 42.7, 43.8, 44.8, 45.6, 46.3, 46.9, 47.4, 47.8,
  48.2, 48.5, 48.8, 49.1, 49.3, 49.5, 49.7, 49.9, 50.1, 50.2,
  50.4, 50.5, 50.7, 50.8,
];

/// Head circumference GIRLS in cm, index = month (0-24)
const List<double> _who50HeadGirls = [
  33.9, 36.5, 38.3, 39.5, 40.6, 41.5, 42.2, 42.8, 43.4, 43.8, 44.2,
  44.6, 44.9, 45.2, 45.4, 45.7, 45.9, 46.1, 46.2, 46.4, 46.6,
  46.7, 46.9, 47.0, 47.2,
];
const List<double> _who3HeadGirls = [
  31.5, 34.2, 36.0, 37.2, 38.3, 39.2, 39.9, 40.4, 40.9, 41.3, 41.7,
  42.0, 42.3, 42.5, 42.8, 43.0, 43.2, 43.4, 43.5, 43.7, 43.8,
  44.0, 44.1, 44.2, 44.4,
];
const List<double> _who97HeadGirls = [
  36.2, 38.9, 40.7, 41.9, 42.9, 43.8, 44.6, 45.2, 45.8, 46.3, 46.7,
  47.0, 47.4, 47.7, 48.0, 48.2, 48.4, 48.6, 48.8, 49.0, 49.1,
  49.3, 49.4, 49.6, 49.7,
];

class GrowthChartsPage extends StatefulWidget {
  final Baby baby;

  const GrowthChartsPage({super.key, required this.baby});

  @override
  State<GrowthChartsPage> createState() => _GrowthChartsPageState();
}

class _GrowthChartsPageState extends State<GrowthChartsPage>
    with SingleTickerProviderStateMixin {
  final MyChildrenService _service = MyChildrenService();
  final GlobalKey _repaintKey = GlobalKey();
  String? _token;
  int? _currentUserId;

  late TabController _tabController;
  List<GrowthMeasurement> _measurements = [];
  bool _isLoading = true;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  bool get _isBoy => widget.baby.gender?.toLowerCase() != 'female';
  bool get _showBmiTab => widget.baby.ageInYears >= 2;
  bool get _useCdcStandard => widget.baby.ageInYears >= 5;

  @override
  void initState() {
    super.initState();
    _currentUserId = LocalStorageService.instanceSync?.getUser()?.userId;
    _tabController = TabController(length: _showBmiTab ? 4 : 3, vsync: this);
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
      // Schedule monthly measurement reminder
      if (result.success) {
        ChildrenNotificationHelper.scheduleMonthlyMeasurementReminder(
          widget.baby.id, widget.baby.name, _sw,
        ).catchError((_) {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindikana kupakia' : 'Failed to load')),
      );
    }
  }

  void _confirmDeleteGrowth(GrowthMeasurement measurement) {
    if (measurement.id == null) return;
    final sw = _sw;
    final dateLabel =
        '${measurement.measuredAt.day}/${measurement.measuredAt.month}/${measurement.measuredAt.year}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa?' : 'Delete?'),
        content: Text(sw ? 'Futa kipimo cha $dateLabel?' : 'Delete measurement from $dateLabel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteGrowth(_token!, measurement.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imefutwa' : 'Deleted')),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imeshindikana kufuta' : 'Failed to delete')),
                  );
                }
              }
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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
      case 3:
        // BMI = weight / (height_m ^ 2)
        if (last.weightKg != null && last.heightCm != null && last.heightCm! > 0) {
          final hm = last.heightCm! / 100;
          return last.weightKg! / (hm * hm);
        }
        return null;
      default:
        return null;
    }
  }

  String _latestDate() {
    if (_measurements.isEmpty) return '--';
    final d = _measurements.last.measuredAt;
    return '${d.day}/${d.month}/${d.year}';
  }

  double? _extractValue(GrowthMeasurement m, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return m.weightKg;
      case 1:
        return m.heightCm;
      case 2:
        return m.headCm;
      case 3:
        if (m.weightKg != null && m.heightCm != null && m.heightCm! > 0) {
          final hm = m.heightCm! / 100;
          return m.weightKg! / (hm * hm);
        }
        return null;
      default:
        return null;
    }
  }

  String _trendArrow(int tabIndex) {
    final vals = _measurements
        .map((m) => _extractValue(m, tabIndex))
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
        .map((m) => _extractValue(m, tabIndex))
        .where((v) => v != null)
        .cast<double>()
        .toList();
    if (vals.isEmpty) return null;

    final latestVal = vals.last;
    final ageMonths = widget.baby.ageInMonths;
    final ageYears = widget.baby.ageInYears;

    List<double> p3;
    List<double> p97;

    if (tabIndex == 3) {
      // BMI — CDC data for ages 2-18
      final idx = (ageYears - 2).clamp(0, _cdc3BmiBoys.length - 1);
      p3 = _isBoy ? _cdc3BmiBoys : _cdc3BmiGirls;
      p97 = _isBoy ? _cdc97BmiBoys : _cdc97BmiGirls;
      if (latestVal < p3[idx]) {
        return _sw
            ? 'BMI chini ya asilimia ya 3 - wasiliana na daktari'
            : 'BMI below 3rd percentile - consult a doctor';
      }
      if (latestVal > p97[idx]) {
        return _sw
            ? 'BMI juu ya asilimia ya 97 - wasiliana na daktari'
            : 'BMI above 97th percentile - consult a doctor';
      }
      return null;
    }

    // For weight/height — use CDC if child > 24 months
    if (ageMonths > 24 && tabIndex <= 1) {
      final cdcIdx = (ageYears - 2).clamp(0, _cdc3WeightBoys.length - 1);
      switch (tabIndex) {
        case 0:
          p3 = _isBoy ? _cdc3WeightBoys : _cdc3WeightGirls;
          p97 = _isBoy ? _cdc97WeightBoys : _cdc97WeightGirls;
        default:
          p3 = _isBoy ? _cdc3HeightBoys : _cdc3HeightGirls;
          p97 = _isBoy ? _cdc97HeightBoys : _cdc97HeightGirls;
      }
      if (latestVal < p3[cdcIdx]) {
        return _sw
            ? 'Chini ya asilimia ya 3 - wasiliana na daktari'
            : 'Below 3rd percentile - consult a doctor';
      }
      if (latestVal > p97[cdcIdx]) {
        return _sw
            ? 'Juu ya asilimia ya 97 - wasiliana na daktari'
            : 'Above 97th percentile - consult a doctor';
      }
      return null;
    }

    // WHO data for 0-24 months
    final clampedMonths = ageMonths.clamp(0, 24);
    switch (tabIndex) {
      case 0:
        p3 = _isBoy ? _who3WeightBoys : _who3WeightGirls;
        p97 = _isBoy ? _who97WeightBoys : _who97WeightGirls;
      case 1:
        p3 = _isBoy ? _who3HeightBoys : _who3HeightGirls;
        p97 = _isBoy ? _who97HeightBoys : _who97HeightGirls;
      default:
        p3 = _isBoy ? _who3HeadBoys : _who3HeadGirls;
        p97 = _isBoy ? _who97HeadBoys : _who97HeadGirls;
    }

    if (latestVal < p3[clampedMonths]) {
      return _sw
          ? 'Chini ya asilimia ya 3 - wasiliana na daktari'
          : 'Below 3rd percentile - consult a doctor';
    }
    if (latestVal > p97[clampedMonths]) {
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
            if (_showBmiTab) const Tab(text: 'BMI'),
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
            : Column(
                children: [
                  // WHO/CDC standard indicator
                  _buildStandardIndicator(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTab(0),
                        _buildTab(1),
                        _buildTab(2),
                        if (_showBmiTab) _buildTab(3),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStandardIndicator() {
    final isCdc = _useCdcStandard || widget.baby.ageInMonths > 24;
    final standard = isCdc
        ? (_sw ? 'Viwango vya CDC' : 'CDC Growth Charts')
        : (_sw ? 'Viwango vya WHO' : 'WHO Standards');
    final ageRange = isCdc
        ? (_sw ? '2-18 miaka' : '2-18 years')
        : (_sw ? '0-24 miezi' : '0-24 months');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _kPrimary.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(
            isCdc ? Icons.verified_rounded : Icons.public_rounded,
            size: 16,
            color: _kPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$standard ($ageRange)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isBoy
                  ? (_sw ? 'Mvulana' : 'Boy')
                  : (_sw ? 'Msichana' : 'Girl'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int tabIndex) {
    final latest = _latestValue(tabIndex);
    final unit = tabIndex == 0 ? 'kg' : (tabIndex == 3 ? 'kg/m\u00B2' : 'cm');
    final alert = _percentileAlert(tabIndex);
    final trend = _trendArrow(tabIndex);

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Latest measurement card
          GestureDetector(
            onLongPress: _measurements.isNotEmpty
                ? () => _confirmDeleteGrowth(_measurements.last)
                : null,
            child: Container(
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

          // Growth Chart
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
                painter: _GrowthChartPainter(
                  tabIndex: tabIndex,
                  measurements: _measurements,
                  babyDob: widget.baby.dateOfBirth,
                  childAgeMonths: widget.baby.ageInMonths,
                  isBoy: _isBoy,
                ),
              ),
            ),
          ),

          // ─── Cross-module links (contextual) ──────────
          if (alert != null) ...[
            const SizedBox(height: 8),
            if (_currentUserId != null)
              _buildCrossModuleLink(
                icon: Icons.local_hospital_rounded,
                label: _sw
                    ? 'Wasiliana na daktari kuhusu ukuaji wa ${widget.baby.name}'
                    : 'Consult your doctor about ${widget.baby.name}\'s growth',
                iconColor: Colors.red.shade400,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => DoctorModule(userId: _currentUserId!))),
              ),
            // Show shop supplements when weight is below 3rd percentile
            if (tabIndex == 0 && alert.contains('3'))
              _buildCrossModuleLink(
                icon: Icons.shopping_cart_rounded,
                label: _sw
                    ? 'Nunua virutubisho vya lishe'
                    : 'Shop nutritional supplements',
                onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
              ),
          ],
          _buildCrossModuleLink(
            icon: Icons.chat_rounded,
            label: _sw
                ? 'Uliza Shangazi kuhusu uzito unaofaa kwa umri'
                : 'Ask Shangazi about healthy weight for age',
            onTap: () => Navigator.pushNamed(context, '/chat/0'),
          ),

          const SizedBox(height: 80), // space for FAB
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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}

// ─── Growth Chart Painter (WHO 0-24m + CDC 2-18yr) ──────────────

class _GrowthChartPainter extends CustomPainter {
  final int tabIndex;
  final List<GrowthMeasurement> measurements;
  final DateTime babyDob;
  final int childAgeMonths;
  final bool isBoy;

  _GrowthChartPainter({
    required this.tabIndex,
    required this.measurements,
    required this.babyDob,
    required this.childAgeMonths,
    required this.isBoy,
  });

  bool get _useCdc => childAgeMonths > 24 && tabIndex <= 1;
  bool get _isBmi => tabIndex == 3;

  @override
  void paint(Canvas canvas, Size size) {
    List<double> p3, p50, p97;
    int dataPoints;
    double xLabelStep;
    String Function(int idx) xLabelText;
    double Function(GrowthMeasurement m) xPosition;
    double Function(GrowthMeasurement m)? valueExtractor;

    if (_isBmi) {
      // BMI chart for ages 2-18
      p3 = isBoy ? _cdc3BmiBoys : _cdc3BmiGirls;
      p50 = isBoy ? _cdc50BmiBoys : _cdc50BmiGirls;
      p97 = isBoy ? _cdc97BmiBoys : _cdc97BmiGirls;
      dataPoints = p50.length; // 17 entries (2-18)
      xLabelStep = 2;
      xLabelText = (idx) => '${idx + 2}';
      xPosition = (m) {
        final ageYrs = m.measuredAt.difference(babyDob).inDays / 365.25;
        return (ageYrs - 2).clamp(0, dataPoints - 1).toDouble();
      };
      valueExtractor = (m) {
        if (m.weightKg != null && m.heightCm != null && m.heightCm! > 0) {
          final hm = m.heightCm! / 100;
          return m.weightKg! / (hm * hm);
        }
        return -1;
      };
    } else if (_useCdc) {
      // CDC for 2-18 years
      switch (tabIndex) {
        case 0:
          p3 = isBoy ? _cdc3WeightBoys : _cdc3WeightGirls;
          p50 = isBoy ? _cdc50WeightBoys : _cdc50WeightGirls;
          p97 = isBoy ? _cdc97WeightBoys : _cdc97WeightGirls;
        default:
          p3 = isBoy ? _cdc3HeightBoys : _cdc3HeightGirls;
          p50 = isBoy ? _cdc50HeightBoys : _cdc50HeightGirls;
          p97 = isBoy ? _cdc97HeightBoys : _cdc97HeightGirls;
      }
      dataPoints = p50.length; // 17 entries (2-18)
      xLabelStep = 2;
      xLabelText = (idx) => '${idx + 2}yr';
      xPosition = (m) {
        final ageYrs = m.measuredAt.difference(babyDob).inDays / 365.25;
        return (ageYrs - 2).clamp(0, dataPoints - 1).toDouble();
      };
      valueExtractor = (m) {
        switch (tabIndex) {
          case 0:
            return m.weightKg ?? -1;
          default:
            return m.heightCm ?? -1;
        }
      };
    } else {
      // WHO for 0-24 months
      switch (tabIndex) {
        case 0:
          p3 = isBoy ? _who3WeightBoys : _who3WeightGirls;
          p50 = isBoy ? _who50WeightBoys : _who50WeightGirls;
          p97 = isBoy ? _who97WeightBoys : _who97WeightGirls;
        case 1:
          p3 = isBoy ? _who3HeightBoys : _who3HeightGirls;
          p50 = isBoy ? _who50HeightBoys : _who50HeightGirls;
          p97 = isBoy ? _who97HeightBoys : _who97HeightGirls;
        default:
          p3 = isBoy ? _who3HeadBoys : _who3HeadGirls;
          p50 = isBoy ? _who50HeadBoys : _who50HeadGirls;
          p97 = isBoy ? _who97HeadBoys : _who97HeadGirls;
      }
      dataPoints = p50.length; // 25 entries (0-24 months)
      xLabelStep = 3;
      xLabelText = (idx) => '$idx';
      xPosition = (m) {
        return (m.measuredAt.difference(babyDob).inDays / 30.44)
            .clamp(0, dataPoints - 1)
            .toDouble();
      };
      valueExtractor = (m) {
        switch (tabIndex) {
          case 0:
            return m.weightKg ?? -1;
          case 1:
            return m.heightCm ?? -1;
          default:
            return m.headCm ?? -1;
        }
      };
    }

    final int maxIdx = dataPoints - 1;
    final double yMin = p3.reduce(math.min) - 1;
    final double yMax = p97.reduce(math.max) + 1;

    const double leftPad = 32;
    const double bottomPad = 24;
    final double chartW = size.width - leftPad;
    final double chartH = size.height - bottomPad;

    double xFor(double idx) => leftPad + (idx / maxIdx) * chartW;
    double yFor(double val) =>
        chartH - ((val - yMin) / (yMax - yMin)) * chartH;

    // Percentile band
    final bandPaint = Paint()..color = _kTertiary.withValues(alpha: 0.12);
    final bandPath = Path();
    for (int i = 0; i <= maxIdx; i++) {
      final x = xFor(i.toDouble());
      if (i == 0) {
        bandPath.moveTo(x, yFor(p97[i]));
      } else {
        bandPath.lineTo(x, yFor(p97[i]));
      }
    }
    for (int i = maxIdx; i >= 0; i--) {
      bandPath.lineTo(xFor(i.toDouble()), yFor(p3[i]));
    }
    bandPath.close();
    canvas.drawPath(bandPath, bandPaint);

    // 50th percentile dashed line
    final medianPaint = Paint()
      ..color = _kTertiary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final medianPath = Path();
    for (int i = 0; i <= maxIdx; i++) {
      final x = xFor(i.toDouble());
      final y = yFor(p50[i]);
      if (i == 0) {
        medianPath.moveTo(x, y);
      } else {
        medianPath.lineTo(x, y);
      }
    }
    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in medianPath.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final end = math.min(dist + dashWidth, metric.length);
        final seg = metric.extractPath(dist, end);
        canvas.drawPath(seg, medianPaint);
        dist += dashWidth + dashGap;
      }
    }

    // User data points
    final userValues = <Offset>[];
    for (final m in measurements) {
      final val = valueExtractor(m);
      if (val < 0) continue;
      final xIdx = xPosition(m);
      if (xIdx < 0 || xIdx > maxIdx) continue;
      userValues.add(Offset(xFor(xIdx), yFor(val)));
    }

    if (userValues.isNotEmpty) {
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

      final dotPaint = Paint()..color = _kPrimary;
      for (final pt in userValues) {
        canvas.drawCircle(pt, 4, dotPaint);
      }
    }

    // X-axis labels
    final textStyle = TextStyle(color: _kTertiary, fontSize: 10);
    for (int i = 0; i <= maxIdx; i += xLabelStep.toInt()) {
      final tp = TextPainter(
        text: TextSpan(text: xLabelText(i), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(xFor(i.toDouble()) - tp.width / 2, chartH + 4));
    }

    // Y-axis labels
    final yStep = ((yMax - yMin) / 5).ceilToDouble();
    if (yStep > 0) {
      for (double v = yMin.ceilToDouble(); v <= yMax; v += yStep) {
        final tp = TextPainter(
          text: TextSpan(text: v.toStringAsFixed(0), style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(0, yFor(v) - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter old) =>
      old.tabIndex != tabIndex ||
      old.measurements.length != measurements.length ||
      old.childAgeMonths != childAgeMonths ||
      old.isBoy != isBoy;
}
