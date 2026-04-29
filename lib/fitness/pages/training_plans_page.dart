import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/training_plan.dart';
import '../services/training_plan_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec line 643 — recurring training plans + check-ins for 1:1 trainers.
/// Customer view: list of active plans, tap to log a workout.
class TrainingPlansPage extends StatefulWidget {
  final int customerUserId;
  const TrainingPlansPage({super.key, required this.customerUserId});

  @override
  State<TrainingPlansPage> createState() => _TrainingPlansPageState();
}

class _TrainingPlansPageState extends State<TrainingPlansPage> {
  bool _loading = true;
  List<TrainingPlan> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res =
        await TrainingPlanService.listForCustomer(widget.customerUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSw ? 'Mipango ya Mazoezi' : 'Training Plans',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center_rounded,
                            size: 56, color: _kSecondary),
                        const SizedBox(height: 12),
                        Text(
                          isSw
                              ? 'Bado hujapata mpango'
                              : 'No active plans',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: _items.map(_planCard).toList(),
                  ),
                ),
    );
  }

  Widget _planCard(TrainingPlan p) {
    final isSw = _isSwahili;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (p.startsOn != null)
                DateFormat('d MMM').format(p.startsOn!),
              if (p.endsOn != null) '→ ${DateFormat('d MMM').format(p.endsOn!)}',
              isSw ? 'Coach #${p.partnerUserId}' : 'Coach #${p.partnerUserId}',
            ].whereType<String>().join(' • '),
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewLog(p),
                  icon: const Icon(Icons.history_rounded, size: 14),
                  label: Text(isSw ? 'Historia' : 'Log'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _checkIn(p),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: Text(isSw ? 'Rekodi' : 'Check in'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _checkIn(TrainingPlan p) async {
    final reps = TextEditingController();
    final weight = TextEditingController();
    bool isPr = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(_isSwahili ? 'Rekodi mazoezi' : 'Log workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: reps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Reps' : 'Reps',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Uzito (kg)' : 'Weight (kg)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                CheckboxListTile.adaptive(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _isSwahili ? '🏆 PR mpya?' : '🏆 New PR?',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isPr,
                  onChanged: (v) => setStateDialog(() => isPr = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_isSwahili ? 'Funga' : 'Close')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_isSwahili ? 'Hifadhi' : 'Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) {
      reps.dispose();
      weight.dispose();
      return;
    }
    final rep = int.tryParse(reps.text.trim()) ?? 0;
    final wt = int.tryParse(weight.text.trim()) ?? 0;
    final res = await TrainingPlanService.checkin(
      planId: p.id,
      date: DateTime.now(),
      setsRepsWeight: [
        {'reps': rep, 'weight_kg': wt},
      ],
      isPr: isPr,
      prLabel: isPr ? '${wt}kg × $rep' : null,
    );
    reps.dispose();
    weight.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res != null
          ? (isPr
              ? (_isSwahili ? '🏆 PR mpya imehifadhiwa!' : '🏆 New PR saved!')
              : (_isSwahili ? 'Imehifadhiwa' : 'Logged'))
          : (_isSwahili ? 'Imeshindikana' : 'Failed')),
    ));
  }

  Future<void> _viewLog(TrainingPlan p) async {
    final messenger = ScaffoldMessenger.of(context);
    final entries = await TrainingPlanService.listCheckins(p.id);
    if (!mounted) return;
    if (entries.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Hakuna rekodi bado' : 'No check-ins yet'),
      ));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.title} — ${_isSwahili ? 'Historia' : 'Log'}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary),
                ),
                const SizedBox(height: 8),
                ...entries.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          if (c.isPr)
                            const Icon(Icons.emoji_events_rounded,
                                size: 14, color: _kAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                DateFormat('d MMM').format(c.date),
                                if (c.prLabel != null) c.prLabel!,
                                if (c.notes != null && c.notes!.isNotEmpty)
                                  c.notes!,
                              ].join(' • '),
                              style: const TextStyle(
                                  fontSize: 12, color: _kPrimary),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
