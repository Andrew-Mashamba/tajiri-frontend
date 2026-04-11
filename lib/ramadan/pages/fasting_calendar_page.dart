// lib/ramadan/pages/fasting_calendar_page.dart
import 'package:flutter/material.dart';
import '../models/ramadan_models.dart';
import '../services/ramadan_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FastingCalendarPage extends StatefulWidget {
  final int userId;
  const FastingCalendarPage({super.key, required this.userId});

  @override
  State<FastingCalendarPage> createState() => _FastingCalendarPageState();
}

class _FastingCalendarPageState extends State<FastingCalendarPage> {
  final _service = RamadanService();
  List<RamadanDay> _days = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken() ?? '';
    final result = await _service.getFastingCalendar(
      token: token, latitude: -6.7924, longitude: 39.2083,
    );
    if (mounted) {
      setState(() {
        _days = result.items;
        _loading = false;
      });
    }
  }

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
          'Kalenda ya Kufunga',
          style: TextStyle(
            color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary))
            : _days.isEmpty
                ? const Center(child: Text('Hakuna data ya Ramadan',
                    style: TextStyle(color: _kSecondary, fontSize: 14)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _days.length,
                    itemBuilder: (context, i) {
                      final day = _days[i];
                      return _DayCell(day: day);
                    },
                  ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final RamadanDay day;
  const _DayCell({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: day.isFasted ? _kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: day.isFasted ? _kPrimary : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.dayNumber}',
            style: TextStyle(
              color: day.isFasted ? Colors.white : _kPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            day.isFasted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: day.isFasted ? Colors.white70 : Colors.grey.shade300,
            size: 14,
          ),
        ],
      ),
    );
  }
}
