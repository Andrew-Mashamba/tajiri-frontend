// lib/skincare/pages/routine_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';
import '../services/skincare_service.dart';
import '../widgets/routine_step_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class RoutinePage extends StatefulWidget {
  final int userId;
  final List<SkincareRoutine> routines;
  const RoutinePage({super.key, required this.userId, this.routines = const []});
  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> with SingleTickerProviderStateMixin {
  final SkincareService _service = SkincareService();
  late TabController _tabController;

  List<SkincareRoutine> _routines = [];
  bool _isLoading = false;

  // Guided mode state
  bool _isGuidedMode = false;
  int _guidedRoutineIndex = -1;
  int _guidedStepIndex = 0;
  final Set<int> _completedSteps = {};
  Timer? _stepTimer;
  int _timerRemaining = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _routines = List.from(widget.routines);
    if (_routines.isEmpty) _loadRoutines();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    final result = await _service.getRoutines(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _routines = result.items;
      });
    }
  }

  List<SkincareRoutine> get _morningRoutines => _routines.where((r) => r.type == RoutineType.morning).toList();
  List<SkincareRoutine> get _eveningRoutines => _routines.where((r) => r.type == RoutineType.evening).toList();

  void _startGuidedMode(int routineIdx) {
    setState(() {
      _isGuidedMode = true;
      _guidedRoutineIndex = routineIdx;
      _guidedStepIndex = 0;
      _completedSteps.clear();
    });
  }

  void _completeStep(int stepIdx) {
    final routine = _routines[_guidedRoutineIndex];
    setState(() {
      _completedSteps.add(stepIdx);
      // Start timer for next step if current has wait time
      if (routine.steps[stepIdx].waitTimeSeconds > 0) {
        _startTimer(routine.steps[stepIdx].waitTimeSeconds);
      } else {
        _advanceStep();
      }
    });
  }

  void _advanceStep() {
    final routine = _routines[_guidedRoutineIndex];
    if (_guidedStepIndex < routine.steps.length - 1) {
      setState(() => _guidedStepIndex++);
    } else {
      // All steps complete
      setState(() {
        _isGuidedMode = false;
        _guidedRoutineIndex = -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hongera! Umemaliza routine yako'), backgroundColor: Color(0xFF4CAF50)),
        );
      }
    }
  }

  void _startTimer(int seconds) {
    _timerRemaining = seconds;
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerRemaining <= 0) {
        timer.cancel();
        _advanceStep();
      } else {
        setState(() => _timerRemaining--);
      }
    });
  }

  void _stopGuidedMode() {
    _stepTimer?.cancel();
    setState(() {
      _isGuidedMode = false;
      _guidedRoutineIndex = -1;
      _completedSteps.clear();
    });
  }

  Future<void> _addRoutine(RoutineType type) async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Routine Mpya (${type.displayName})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Jina la routine',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Unda'),
          ),
        ],
      ),
    );
    nameController.dispose();

    if (result != null && result.isNotEmpty) {
      final saveResult = await _service.saveRoutine(
        userId: widget.userId,
        name: result,
        type: type,
        steps: [],
      );
      if (mounted && saveResult.success && saveResult.data != null) {
        setState(() => _routines.add(saveResult.data!));
      }
    }
  }

  Future<void> _deleteRoutine(int routineId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Routine?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Huwezi kurudisha routine baada ya kuifuta'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ghairi')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await _service.deleteRoutine(routineId);
      if (mounted && result.success) {
        setState(() => _routines.removeWhere((r) => r.id == routineId));
      }
    }
  }

  Future<void> _addStep(int routineIdx) async {
    final routine = _routines[routineIdx];
    StepType? selectedType;
    final productController = TextEditingController();
    final instructionsController = TextEditingController();
    int waitTime = 0;

    final result = await showModalBottomSheet<RoutineStep>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ongeza Hatua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 12),
              // Step type
              const Text('Aina ya Hatua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: StepType.values.map((st) {
                  final isSelected = selectedType == st;
                  return ChoiceChip(
                    label: Text(st.displayName),
                    avatar: Icon(st.icon, size: 16),
                    selected: isSelected,
                    onSelected: (_) => setSheetState(() => selectedType = st),
                    selectedColor: _kPrimary.withValues(alpha: 0.12),
                    backgroundColor: _kCardBg,
                    labelStyle: TextStyle(fontSize: 12, color: _kPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: productController,
                decoration: const InputDecoration(
                  hintText: 'Jina la bidhaa (si lazima)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(
                  hintText: 'Maelekezo (si lazima)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Muda wa kusubiri:', style: TextStyle(fontSize: 13, color: _kPrimary)),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: waitTime,
                    items: [0, 15, 30, 60, 120, 180, 300]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s == 0 ? 'Hakuna' : '${s}s')))
                        .toList(),
                    onChanged: (v) => setSheetState(() => waitTime = v ?? 0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: selectedType == null
                      ? null
                      : () {
                          Navigator.pop(ctx, RoutineStep(
                            order: routine.steps.length + 1,
                            stepType: selectedType!,
                            productName: productController.text.trim().isEmpty ? null : productController.text.trim(),
                            instructions: instructionsController.text.trim().isEmpty ? null : instructionsController.text.trim(),
                            waitTimeSeconds: waitTime,
                          ));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Ongeza', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    productController.dispose();
    instructionsController.dispose();

    if (result != null) {
      final updatedSteps = [...routine.steps, result];
      final saveResult = await _service.saveRoutine(
        userId: widget.userId,
        name: routine.name,
        type: routine.type,
        steps: updatedSteps,
      );
      if (mounted) {
        if (saveResult.success && saveResult.data != null) {
          setState(() => _routines[routineIdx] = saveResult.data!);
        } else {
          // Optimistic local update
          setState(() {
            _routines[routineIdx] = SkincareRoutine(
              id: routine.id,
              userId: routine.userId,
              name: routine.name,
              type: routine.type,
              steps: updatedSteps,
              isActive: routine.isActive,
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guided mode overlay
    if (_isGuidedMode && _guidedRoutineIndex >= 0 && _guidedRoutineIndex < _routines.length) {
      return _buildGuidedMode();
    }

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Routine ya Ngozi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.wb_sunny_rounded, size: 18), text: 'Asubuhi'),
            Tab(icon: Icon(Icons.nights_stay_rounded, size: 18), text: 'Jioni'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRoutineList(_morningRoutines, RoutineType.morning),
                _buildRoutineList(_eveningRoutines, RoutineType.evening),
              ],
            ),
    );
  }

  Widget _buildRoutineList(List<SkincareRoutine> routines, RoutineType type) {
    if (routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, size: 48, color: _kSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Hakuna routine ya ${type.displayName}',
              style: const TextStyle(fontSize: 14, color: _kSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addRoutine(type),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Unda Routine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: routines.length + 1,
      itemBuilder: (context, index) {
        if (index == routines.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: () => _addRoutine(type),
                icon: const Icon(Icons.add_rounded, size: 18, color: _kPrimary),
                label: const Text('Ongeza Routine', style: TextStyle(color: _kPrimary)),
              ),
            ),
          );
        }

        final routineGlobalIdx = _routines.indexOf(routines[index]);
        final routine = routines[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Routine header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      routine.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _startGuidedMode(routineGlobalIdx),
                    child: const Text('Anza', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: _kPrimary),
                    onPressed: () => _addStep(routineGlobalIdx),
                    tooltip: 'Ongeza hatua',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    onPressed: () => _deleteRoutine(routine.id),
                    tooltip: 'Futa',
                  ),
                ],
              ),
              // Steps — reorderable
              if (routine.steps.isNotEmpty)
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routine.steps.length,
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (newIdx > oldIdx) newIdx--;
                      final steps = List<RoutineStep>.from(routine.steps);
                      final item = steps.removeAt(oldIdx);
                      steps.insert(newIdx, item);
                      // Rebuild with new order numbers
                      final reordered = List.generate(steps.length, (i) => RoutineStep(
                            order: i + 1,
                            stepType: steps[i].stepType,
                            productName: steps[i].productName,
                            instructions: steps[i].instructions,
                            waitTimeSeconds: steps[i].waitTimeSeconds,
                          ));
                      _routines[routineGlobalIdx] = SkincareRoutine(
                        id: routine.id,
                        userId: routine.userId,
                        name: routine.name,
                        type: routine.type,
                        steps: reordered,
                        isActive: routine.isActive,
                      );
                    });
                    // Save in background
                    _service.saveRoutine(
                      userId: widget.userId,
                      name: routine.name,
                      type: routine.type,
                      steps: _routines[routineGlobalIdx].steps,
                    );
                  },
                  itemBuilder: (context, stepIdx) {
                    return Padding(
                      key: ValueKey('${routine.id}_$stepIdx'),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: RoutineStepCard(step: routine.steps[stepIdx]),
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Bonyeza + kuongeza hatua',
                      style: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuidedMode() {
    final routine = _routines[_guidedRoutineIndex];
    final currentStep = routine.steps[_guidedStepIndex];
    final isTimerActive = _timerRemaining > 0;

    return Scaffold(
      backgroundColor: _kPrimary,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: _stopGuidedMode,
        ),
        title: Text(
          routine.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(routine.steps.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _completedSteps.contains(i)
                            ? const Color(0xFF4CAF50)
                            : i == _guidedStepIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Hatua ${_guidedStepIndex + 1} ya ${routine.steps.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),

            // Current step
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(currentStep.stepType.icon, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentStep.stepType.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      if (currentStep.productName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          currentStep.productName!,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (currentStep.instructions != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          currentStep.instructions!,
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Timer display
                      if (isTimerActive) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_rounded, size: 24, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimerDisplay(_timerRemaining),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Subiri...',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Action button
            if (!isTimerActive)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: () => _completeStep(_guidedStepIndex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _guidedStepIndex < routine.steps.length - 1 ? 'Nimemaliza \u2014 Endelea' : 'Maliza Routine',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimerDisplay(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
