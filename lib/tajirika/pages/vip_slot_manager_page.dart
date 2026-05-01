import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_i_services.dart';

/// Spec F12 #VIP standing-slot reservation. Partners hold preferred recurring
/// slots for VIP customers before public booking opens.
class VipSlotManagerPage extends StatefulWidget {
  final int partnerUserId;
  const VipSlotManagerPage({super.key, required this.partnerUserId});

  @override
  State<VipSlotManagerPage> createState() => _VipSlotManagerPageState();
}

class _VipSlotManagerPageState extends State<VipSlotManagerPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _slots = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await VipSlotService.partnerList(widget.partnerUserId);
    if (!mounted) return;
    setState(() {
      _slots = rows;
      _loading = false;
    });
  }

  Future<void> _addSlot() async {
    final vipCtrl = TextEditingController();
    String day = 'Mon';
    final timeCtrl = TextEditingController(text: '10:00');
    int duration = 60;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sCtx) => StatefulBuilder(
        builder: (b, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(sCtx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('VIP standing slot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: vipCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'VIP user_id', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: day,
                items: const [
                  DropdownMenuItem(value: 'Mon', child: Text('Monday')),
                  DropdownMenuItem(value: 'Tue', child: Text('Tuesday')),
                  DropdownMenuItem(value: 'Wed', child: Text('Wednesday')),
                  DropdownMenuItem(value: 'Thu', child: Text('Thursday')),
                  DropdownMenuItem(value: 'Fri', child: Text('Friday')),
                  DropdownMenuItem(value: 'Sat', child: Text('Saturday')),
                  DropdownMenuItem(value: 'Sun', child: Text('Sunday')),
                ],
                onChanged: (v) {
                  if (v != null) setS(() => day = v);
                },
                decoration: const InputDecoration(
                    labelText: 'Day of week', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Start time (HH:MM)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: duration,
                items: const [30, 45, 60, 90, 120]
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text('$m min')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setS(() => duration = v);
                },
                decoration: const InputDecoration(
                    labelText: 'Duration', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A)),
                onPressed: () => Navigator.pop(sCtx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    final id = await VipSlotService.save(
      userId: widget.partnerUserId,
      vipUserId: int.tryParse(vipCtrl.text.trim()) ?? 0,
      dayOfWeek: day,
      startsAt: timeCtrl.text.trim(),
      durationMinutes: duration,
    );
    if (!mounted) return;
    if (id != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Vipindi vya VIP' : 'VIP standing slots'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _slots.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isSw
                          ? 'Hujaweka vipindi vya VIP bado.'
                          : 'No VIP slots yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _slots.length,
                  itemBuilder: (_, i) {
                    final s = _slots[i];
                    return ListTile(
                      leading: const Icon(Icons.workspace_premium_rounded,
                          color: Color(0xFFAA00FF)),
                      title: Text(
                        '${s['day_of_week']} ${s['starts_at']} • ${s['duration_minutes']} min',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('VIP user #${s['vip_user_id']}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A1A1A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(isSw ? 'Ongeza VIP' : 'Add VIP slot',
            style: const TextStyle(color: Colors.white)),
        onPressed: _addSlot,
      ),
    );
  }
}
