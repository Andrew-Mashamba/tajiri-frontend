// lib/my_circle/pages/cycle_calendar_page.dart
import 'package:flutter/material.dart';
import '../models/my_circle_models.dart';
import '../services/my_circle_service.dart';
import 'log_day_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

const Color _kPeriod = Color(0xFFEF5350);
const Color _kFertile = Color(0xFF66BB6A);
const Color _kPredicted = Color(0xFF42A5F5);

class CycleCalendarPage extends StatefulWidget {
  final int userId;
  final bool isSwahili;
  const CycleCalendarPage({super.key, required this.userId, this.isSwahili = false});
  @override
  State<CycleCalendarPage> createState() => _CycleCalendarPageState();
}

class _CycleCalendarPageState extends State<CycleCalendarPage> {
  final MyCircleService _service = MyCircleService();
  final PageController _pageController = PageController(initialPage: 600);

  late DateTime _baseMonth;
  final Map<String, CycleDay> _loggedDays = {};
  CyclePrediction? _prediction;
  bool _isLoading = true;
  int _currentPageIndex = 600;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _loadMonth(now.month, now.year);
    _loadPredictions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int pageIndex) {
    final offset = pageIndex - 600;
    return DateTime(_baseMonth.year, _baseMonth.month + offset);
  }

  Future<void> _loadMonth(int month, int year) async {
    setState(() => _isLoading = true);
    final result = await _service.getCycleDays(userId: widget.userId, month: month, year: year);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          for (final day in result.items) {
            final key = '${day.date.year}-${day.date.month}-${day.date.day}';
            _loggedDays[key] = day;
          }
        }
      });
    }
  }

  Future<void> _loadPredictions() async {
    final result = await _service.getPredictions(widget.userId);
    if (mounted && result.success) {
      setState(() => _prediction = result.data);
    }
  }

  void _onPageChanged(int index) {
    _currentPageIndex = index;
    final month = _monthForPage(index);
    _loadMonth(month.month, month.year);
  }

  void _onDayTap(DateTime date) async {
    final key = '${date.year}-${date.month}-${date.day}';
    final existing = _loggedDays[key];
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LogDayPage(
          userId: widget.userId,
          initialDate: date,
          existingLog: existing,
          isSwahili: widget.isSwahili,
        ),
      ),
    );
    if (result == true && mounted) {
      final month = _monthForPage(_currentPageIndex);
      _loadMonth(month.month, month.year);
      _loadPredictions();
    }
  }

  _DayType _getDayType(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    final logged = _loggedDays[key];
    if (logged != null && logged.hasPeriod) return _DayType.period;

    if (_prediction != null) {
      final d = DateTime(date.year, date.month, date.day);
      if (_prediction!.fertileWindowStart != null && _prediction!.fertileWindowEnd != null) {
        final fs = DateTime(_prediction!.fertileWindowStart!.year, _prediction!.fertileWindowStart!.month, _prediction!.fertileWindowStart!.day);
        final fe = DateTime(_prediction!.fertileWindowEnd!.year, _prediction!.fertileWindowEnd!.month, _prediction!.fertileWindowEnd!.day);
        if (!d.isBefore(fs) && !d.isAfter(fe)) return _DayType.fertile;
      }
      if (_prediction!.nextPeriodDate != null) {
        final np = DateTime(_prediction!.nextPeriodDate!.year, _prediction!.nextPeriodDate!.month, _prediction!.nextPeriodDate!.day);
        final periodEnd = np.add(const Duration(days: 5));
        if (!d.isBefore(np) && d.isBefore(periodEnd)) return _DayType.predicted;
      }
    }

    return _DayType.normal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(widget.isSwahili ? 'Kalenda ya Duru' : 'Cycle Calendar', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final month = _monthForPage(index);
                  return _MonthView(
                    month: month,
                    getDayType: _getDayType,
                    loggedDays: _loggedDays,
                    onDayTap: _onDayTap,
                    isLoading: _isLoading,
                    isSwahili: widget.isSwahili,
                  );
                },
              ),
            ),
            // Legend
            Container(
              padding: const EdgeInsets.all(16),
              color: _kCardBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LegendItem(color: _kPeriod, label: widget.isSwahili ? 'Hedhi' : 'Period'),
                  _LegendItem(color: _kFertile, label: widget.isSwahili ? 'Rutuba' : 'Fertile'),
                  _LegendItem(color: _kPredicted, label: widget.isSwahili ? 'Utabiri' : 'Predicted'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DayType { normal, period, fertile, predicted }

// ─── Month View ────────────────────────────────────────────────

class _MonthView extends StatelessWidget {
  final DateTime month;
  final _DayType Function(DateTime) getDayType;
  final Map<String, CycleDay> loggedDays;
  final ValueChanged<DateTime> onDayTap;
  final bool isLoading;
  final bool isSwahili;

  const _MonthView({
    required this.month,
    required this.getDayType,
    required this.loggedDays,
    required this.onDayTap,
    required this.isLoading,
    this.isSwahili = false,
  });

  static const _swMonths = [
    '', 'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];
  static const _enMonths = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // Mon=Jumatatu, Tue=Jumanne, Wed=Jumatano, Thu=Alhamisi, Fri=Ijumaa, Sat=Jumamosi, Sun=Jumapili
  static const _swDays = ['Jt', 'Jn', 'Jt', 'Al', 'Ij', 'Jm', 'Jp'];
  static const _enDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Month title
          Text(
            '${(isSwahili ? _swMonths : _enMonths)[month.month]} ${month.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          // Day headers
          Row(
            children: (isSwahili ? _swDays : _enDays).map((d) => Expanded(
              child: Center(child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kSecondary))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
          else
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
                itemCount: 42,
                itemBuilder: (context, index) {
                  final dayOffset = index - (startWeekday - 1);
                  if (dayOffset < 0 || dayOffset >= daysInMonth) return const SizedBox();

                  final date = DateTime(month.year, month.month, dayOffset + 1);
                  final dayType = getDayType(date);
                  final isToday = _isToday(date);
                  final key = '${date.year}-${date.month}-${date.day}';
                  final hasLog = loggedDays.containsKey(key);

                  Color bgColor;
                  Color textColor;
                  switch (dayType) {
                    case _DayType.period:
                      bgColor = _kPeriod;
                      textColor = Colors.white;
                    case _DayType.fertile:
                      bgColor = _kFertile.withValues(alpha: 0.2);
                      textColor = _kPrimary;
                    case _DayType.predicted:
                      bgColor = _kPredicted.withValues(alpha: 0.2);
                      textColor = _kPrimary;
                    case _DayType.normal:
                      bgColor = Colors.transparent;
                      textColor = _kPrimary;
                  }

                  return GestureDetector(
                    onTap: () => onDayTap(date),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: isToday ? Border.all(color: _kPrimary, width: 2) : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${dayOffset + 1}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                            ),
                            if (hasLog)
                              Container(
                                width: 4, height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dayType == _DayType.period ? Colors.white : _kPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

// ─── Legend Item ────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: _kSecondary)),
      ],
    );
  }
}
