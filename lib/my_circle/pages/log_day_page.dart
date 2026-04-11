// lib/my_circle/pages/log_day_page.dart
import 'package:flutter/material.dart';
import '../models/my_circle_models.dart';
import '../services/my_circle_service.dart';
import '../widgets/flow_selector.dart';
import '../widgets/symptom_grid.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class LogDayPage extends StatefulWidget {
  final int userId;
  final DateTime? initialDate;
  final CycleDay? existingLog;
  final bool isSwahili;

  const LogDayPage({super.key, required this.userId, this.initialDate, this.existingLog, this.isSwahili = false});
  @override
  State<LogDayPage> createState() => _LogDayPageState();
}

class _LogDayPageState extends State<LogDayPage> {
  final MyCircleService _service = MyCircleService();
  final TextEditingController _notesController = TextEditingController();
  bool get _sw => widget.isSwahili;

  late DateTime _selectedDate;
  FlowIntensity _flowIntensity = FlowIntensity.none;
  List<Symptom> _symptoms = [];
  Mood? _selectedMood;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (widget.existingLog != null) {
      _flowIntensity = widget.existingLog!.flowIntensity;
      _symptoms = List.from(widget.existingLog!.symptoms);
      _selectedMood = widget.existingLog!.mood;
      _notesController.text = widget.existingLog!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _kPrimary, onPrimary: Colors.white, surface: _kCardBg),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final result = await _service.logCycleDay(
        userId: widget.userId,
        date: _selectedDate,
        flowIntensity: _flowIntensity,
        symptoms: _symptoms,
        mood: _selectedMood,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw ? 'Imehifadhiwa' : 'Saved'), backgroundColor: _kPrimary),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (_sw ? 'Imeshindwa kuhifadhi' : 'Failed to save')), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Kosa: $e' : 'Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(_sw ? 'Rekodi Siku' : 'Log Day', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: _kPrimary),
                    const SizedBox(width: 12),
                    Text(dateStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const Spacer(),
                    Text(_sw ? 'Badilisha' : 'Change', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Flow selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: FlowSelector(
                selected: _flowIntensity,
                isSwahili: _sw,
                onChanged: (v) => setState(() => _flowIntensity = v),
              ),
            ),
            const SizedBox(height: 16),

            // Symptom grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: SymptomGrid(
                selected: _symptoms,
                isSwahili: _sw,
                onChanged: (v) => setState(() => _symptoms = v),
              ),
            ),
            const SizedBox(height: 16),

            // Mood selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sw ? 'Hisia' : 'Mood', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: Mood.values.map((mood) {
                      final isSelected = _selectedMood == mood;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMood = isSelected ? null : mood),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? _kPrimary : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            children: [
                              Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(
                                mood.displayName(_sw),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : _kSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sw ? 'Maelezo' : 'Notes', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _sw ? 'Andika maelezo yoyote ya ziada...' : 'Write any additional notes...',
                      hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_sw ? 'Hifadhi' : 'Save', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
