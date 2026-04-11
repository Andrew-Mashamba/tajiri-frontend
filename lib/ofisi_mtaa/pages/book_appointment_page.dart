// lib/ofisi_mtaa/pages/book_appointment_page.dart
import 'package:flutter/material.dart';
import '../models/ofisi_mtaa_models.dart';
import '../services/ofisi_mtaa_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BookAppointmentPage extends StatefulWidget {
  final int mtaaId;
  final List<MtaaOfficial> officials;

  const BookAppointmentPage({
    super.key,
    required this.mtaaId,
    required this.officials,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _purposeCtrl = TextEditingController();
  MtaaOfficial? _selectedOfficial;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  List<TimeSlot> _slots = [];
  String? _selectedTime;
  bool _loadingSlots = false;
  bool _booking = false;

  final _service = OfisiMtaaService();

  @override
  void initState() {
    super.initState();
    if (widget.officials.isNotEmpty) {
      _selectedOfficial = widget.officials.first;
      _loadSlots();
    }
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    if (_selectedOfficial == null) return;
    setState(() => _loadingSlots = true);

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final result =
        await _service.getAvailableSlots(_selectedOfficial!.id, dateStr);

    if (mounted) {
      setState(() {
        _slots = result.items;
        _selectedTime = null;
        _loadingSlots = false;
      });
    }
  }

  Future<void> _book() async {
    if (_selectedTime == null || _purposeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali jaza taarifa zote')),
      );
      return;
    }

    setState(() => _booking = true);
    final result = await _service.bookAppointment({
      'official_id': _selectedOfficial!.id,
      'date_time': _selectedTime,
      'purpose': _purposeCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _booking = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miadi imepangwa!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text(
          'Panga Miadi',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Select official ──
          const Text('Kiongozi',
              style: TextStyle(fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MtaaOfficial>(
                value: _selectedOfficial,
                isExpanded: true,
                items: widget.officials
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(
                            '${o.name} (${o.roleLabel})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (o) {
                  setState(() => _selectedOfficial = o);
                  _loadSlots();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Date ──
          const Text('Tarehe',
              style: TextStyle(fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadSlots();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _kSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Time slots ──
          const Text('Muda',
              style: TextStyle(fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          if (_loadingSlots)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((s) {
                final selected = s.time == _selectedTime;
                return ChoiceChip(
                  label: Text(s.time),
                  selected: selected,
                  selectedColor: _kPrimary,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : s.available
                            ? _kPrimary
                            : _kSecondary,
                    fontSize: 13,
                  ),
                  onSelected: s.available
                      ? (_) => setState(() => _selectedTime = s.time)
                      : null,
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // ── Purpose ──
          const Text('Sababu',
              style: TextStyle(fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _purposeCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Eleza sababu ya miadi...',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Book ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _booking ? null : _book,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _booking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Panga Miadi', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
