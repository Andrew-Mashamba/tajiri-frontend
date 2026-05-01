import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_i_services.dart';

/// Spec F6 fitness — progress photos + body measurements + PR auto-detect.
class FitnessTrackerPage extends StatefulWidget {
  final int userId;
  const FitnessTrackerPage({super.key, required this.userId});

  @override
  State<FitnessTrackerPage> createState() => _FitnessTrackerPageState();
}

class _FitnessTrackerPageState extends State<FitnessTrackerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  bool _loading = true;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await FitnessTrackerService.summary(widget.userId);
    if (!mounted) return;
    setState(() {
      _summary = s;
      _loading = false;
    });
  }

  Future<void> _addPr() async {
    final exCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    String unit = 'kg';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sCtx) => StatefulBuilder(
        builder: (b, sB) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(sCtx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Log PR',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: exCtrl,
                decoration: const InputDecoration(
                    labelText: 'Exercise', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: valCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Value', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: unit,
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'reps', child: Text('reps')),
                        DropdownMenuItem(value: 'sec', child: Text('sec')),
                        DropdownMenuItem(value: 'km', child: Text('km')),
                      ],
                      onChanged: (v) {
                        if (v != null) sB(() => unit = v);
                      },
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
                onPressed: () => Navigator.pop(sCtx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    final isPr = await FitnessTrackerService.logPr(
      userId: widget.userId,
      exerciseName: exCtrl.text.trim(),
      value: double.tryParse(valCtrl.text.trim()) ?? 0,
      unit: unit,
    );
    if (!mounted) return;
    if (isPr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 New PR!')),
      );
    }
    _load();
  }

  Future<void> _addMeasurement() async {
    final wCtrl = TextEditingController();
    final waistCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(sCtx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Body measurements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: wCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Weight (kg)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: waistCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Waist (cm)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
              onPressed: () => Navigator.pop(sCtx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await FitnessTrackerService.addMeasurement(
      userId: widget.userId,
      weightKg: double.tryParse(wCtrl.text.trim()),
      waistCm: double.tryParse(waistCtrl.text.trim()),
    );
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Maendeleo yangu' : 'My progress'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'PRs'),
            Tab(text: 'Measurements'),
            Tab(text: 'Photos'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _prList(),
                _measurementsList(),
                _photosList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1A1A),
        onPressed: () {
          if (_tab.index == 0) {
            _addPr();
          } else if (_tab.index == 1) {
            _addMeasurement();
          }
          else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isSw ? 'Picha hivi karibuni' : 'Photos coming soon')),
            );
          }
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _prList() {
    final list = (_summary?['prs'] as List?) ?? [];
    if (list.isEmpty) {
      return const Center(child: Text('No PRs yet'));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final r = list[i] as Map;
        return ListTile(
          leading: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC107)),
          title: Text(r['exercise_name']?.toString() ?? '?'),
          subtitle: Text(
            '${r['value']} ${r['unit']}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }

  Widget _measurementsList() {
    final list = (_summary?['measurements'] as List?) ?? [];
    if (list.isEmpty) {
      return const Center(child: Text('No measurements logged'));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final m = list[i] as Map;
        return ListTile(
          title: Text('${m['weight_kg'] ?? '-'} kg'),
          subtitle: Text(
              'waist ${m['waist_cm'] ?? '-'} • chest ${m['chest_cm'] ?? '-'} • hip ${m['hip_cm'] ?? '-'}'),
        );
      },
    );
  }

  Widget _photosList() {
    final list = (_summary?['photos'] as List?) ?? [];
    if (list.isEmpty) {
      return const Center(child: Text('No photos uploaded'));
    }
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(8),
      children: list.map((p) {
        final url = (p as Map)['photo_url']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Image.network(url, fit: BoxFit.cover,
              errorBuilder: (ctx, e, s) =>
                  Container(color: const Color(0xFFEEEEEE))),
        );
      }).toList(),
    );
  }
}
