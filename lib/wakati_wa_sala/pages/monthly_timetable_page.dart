// lib/wakati_wa_sala/pages/monthly_timetable_page.dart
import 'package:flutter/material.dart';
import '../models/wakati_wa_sala_models.dart';
import '../services/wakati_wa_sala_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MonthlyTimetablePage extends StatefulWidget {
  final int userId;
  const MonthlyTimetablePage({super.key, required this.userId});

  @override
  State<MonthlyTimetablePage> createState() => _MonthlyTimetablePageState();
}

class _MonthlyTimetablePageState extends State<MonthlyTimetablePage> {
  final _service = WakatiWaSalaService();
  List<DailyPrayerSchedule> _days = [];
  bool _loading = true;
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final result = await _service.getMonthlySchedule(
      latitude: -6.7924,
      longitude: 39.2083,
      month: _month,
      year: _year,
    );
    if (mounted) {
      setState(() {
        _days = result.items;
        _loading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) {
        _month = 1;
        _year++;
      } else if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
    _loadMonth();
  }

  static const _monthNames = [
    '', 'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ratiba ya Mwezi',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Month Selector ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: _kPrimary),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    '${_monthNames[_month]} $_year',
                    style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: _kPrimary),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),

            // ─── Header Row ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: const Row(
                children: [
                  SizedBox(width: 40, child: Text('Siku',
                      style: TextStyle(fontSize: 11, color: _kSecondary,
                          fontWeight: FontWeight.w600))),
                  Expanded(child: Text('Fajr',
                      style: TextStyle(fontSize: 11, color: _kSecondary,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center)),
                  Expanded(child: Text('Dhuhr',
                      style: TextStyle(fontSize: 11, color: _kSecondary,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center)),
                  Expanded(child: Text('Asr',
                      style: TextStyle(fontSize: 11, color: _kSecondary,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center)),
                  Expanded(child: Text('Magh',
                      style: TextStyle(fontSize: 11, color: _kSecondary,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center)),
                  Expanded(child: Text('Isha',
                      style: TextStyle(fontSize: 11, color: _kSecondary,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center)),
                ],
              ),
            ),

            // ─── Table Body ───────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kPrimary,
                      ),
                    )
                  : _days.isEmpty
                      ? const Center(
                          child: Text(
                            'Hakuna data ya mwezi huu',
                            style: TextStyle(
                              color: _kSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _days.length,
                          itemBuilder: (context, i) {
                            final day = _days[i];
                            final prayers = day.prayers;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade200, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: _kPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(
                                    5,
                                    (pi) => Expanded(
                                      child: Text(
                                        pi < prayers.length
                                            ? prayers[pi].time
                                            : '--:--',
                                        style: const TextStyle(
                                          color: _kPrimary,
                                          fontSize: 12,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
