// lib/kalenda_hijri/pages/date_converter_page.dart
import 'package:flutter/material.dart';
import '../models/kalenda_hijri_models.dart';
import '../services/kalenda_hijri_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DateConverterPage extends StatefulWidget {
  const DateConverterPage({super.key});

  @override
  State<DateConverterPage> createState() => _DateConverterPageState();
}

class _DateConverterPageState extends State<DateConverterPage> {
  final _service = KalendaHijriService();
  DateTime _selectedDate = DateTime.now();
  HijriDate? _convertedDate;
  bool _loading = false;

  Future<void> _convert() async {
    setState(() => _loading = true);
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}'
        '-${_selectedDate.day.toString().padLeft(2, '0')}';
    final result = await _service.convertToHijri(dateStr);
    if (mounted) {
      setState(() {
        _convertedDate = result.data;
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _convert();
    }
  }

  @override
  void initState() {
    super.initState();
    _convert();
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
          'Badilisha Tarehe',
          style: TextStyle(
            color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Gregorian Input ────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: _kPrimary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tarehe ya Gregorian',
                                style: TextStyle(
                                    color: _kSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                color: _kPrimary, fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_rounded,
                          color: _kSecondary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Arrow ──────────────────────────────────
              const Center(
                child: Icon(Icons.arrow_downward_rounded,
                    color: _kSecondary, size: 28),
              ),
              const SizedBox(height: 16),

              // ─── Hijri Result ───────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    : Column(
                        children: [
                          const Text('Tarehe ya Hijri',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(
                            _convertedDate?.formatted ?? '--',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _convertedDate?.formattedSw ?? '',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
