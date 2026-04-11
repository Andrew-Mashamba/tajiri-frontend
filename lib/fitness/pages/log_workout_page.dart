// lib/fitness/pages/log_workout_page.dart
import 'package:flutter/material.dart';
import '../models/fitness_models.dart';
import '../services/fitness_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class LogWorkoutPage extends StatefulWidget {
  final int userId;
  const LogWorkoutPage({super.key, required this.userId});
  @override
  State<LogWorkoutPage> createState() => _LogWorkoutPageState();
}

class _LogWorkoutPageState extends State<LogWorkoutPage> {
  final FitnessService _service = FitnessService();
  final _durationController = TextEditingController(text: '30');
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  WorkoutType _selectedType = WorkoutType.strength;
  bool _isSubmitting = false;

  @override
  void dispose() { _durationController.dispose(); _caloriesController.dispose(); _notesController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingiza muda sahihi')));
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await _service.logWorkout(
      userId: widget.userId,
      type: _selectedType,
      durationMinutes: duration,
      caloriesBurned: int.tryParse(_caloriesController.text.trim()),
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mazoezi yamehifadhiwa!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa'), backgroundColor: Colors.red.shade700));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(backgroundColor: _kCardBg, elevation: 0, scrolledUnderElevation: 1, title: const Text('Rekodi Mazoezi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Workout type grid
          const Text('Aina ya Mazoezi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.85,
            children: WorkoutType.values.map((t) {
              final isSelected = _selectedType == t;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary : _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? _kPrimary : const Color(0xFFE0E0E0)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(t.icon, size: 24, color: isSelected ? Colors.white : _kPrimary),
                    const SizedBox(height: 4),
                    Text(t.displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : _kPrimary)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Duration
          const Text('Muda (dakika)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _durationController, keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              suffixText: 'dk', filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Calories (optional)
          const Text('Kalori (Hiari)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _caloriesController, keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Mfano: 250', hintStyle: TextStyle(color: Colors.grey.shade400), suffixText: 'kcal',
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          const Text('Maelezo (Hiari)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController, maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mazoezi yalikuaje leo...', hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Hifadhi Mazoezi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
