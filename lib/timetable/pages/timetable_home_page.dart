// lib/timetable/pages/timetable_home_page.dart
import 'package:flutter/material.dart';
import '../models/timetable_models.dart';
import '../services/timetable_service.dart';
import 'add_entry_page.dart';
import 'day_view_page.dart';
import '../widgets/timetable_block.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TimetableHomePage extends StatefulWidget {
  final int userId;
  const TimetableHomePage({super.key, required this.userId});
  @override
  State<TimetableHomePage> createState() => _TimetableHomePageState();
}

class _TimetableHomePageState extends State<TimetableHomePage> {
  final TimetableService _service = TimetableService();
  List<TimetableEntry> _entries = [];
  bool _isLoading = true;
  int _selectedDay = DateTime.now().weekday - 1; // 0=Mon

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final result = await _service.getEntries();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _entries = result.items;
      });
    }
  }

  List<TimetableEntry> get _todayEntries {
    if (_selectedDay > 5) return [];
    final day = SchoolDay.values[_selectedDay.clamp(0, 5)];
    return _entries.where((e) => e.day == day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadEntries,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [
                          Icon(Icons.calendar_today_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text('Ratiba', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 6),
                        Text('Timetable — ${_entries.length} vipindi', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Day selector
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 6,
                        itemBuilder: (_, i) {
                          final day = SchoolDay.values[i];
                          final isSelected = i == _selectedDay;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedDay = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? _kPrimary : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? _kPrimary : Colors.grey.shade300),
                                ),
                                alignment: Alignment.center,
                                child: Text(day.shortName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : _kPrimary)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Entries
                    if (_todayEntries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        child: Column(children: [
                          const Icon(Icons.free_breakfast_rounded, size: 48, color: _kSecondary),
                          const SizedBox(height: 8),
                          Text('Hakuna kipindi ${SchoolDay.values[_selectedDay.clamp(0, 5)].displayName}', style: const TextStyle(color: _kSecondary, fontSize: 14)),
                          const Text('No classes this day', style: TextStyle(color: _kSecondary, fontSize: 12)),
                        ]),
                      )
                    else
                      ..._todayEntries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TimetableBlock(
                              entry: e,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DayViewPage(entries: _todayEntries, day: SchoolDay.values[_selectedDay.clamp(0, 5)]))),
                            ),
                          )),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEntryPage(userId: widget.userId))).then((_) => _loadEntries()),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
