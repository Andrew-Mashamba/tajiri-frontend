import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F7 #62 — Retainer subscription config + monthly hour ledger.
class RetainerConfigPage extends StatefulWidget {
  final int userId;
  final int engagementId;
  const RetainerConfigPage({
    super.key,
    required this.userId,
    required this.engagementId,
  });

  @override
  State<RetainerConfigPage> createState() => _RetainerConfigPageState();
}

class _RetainerConfigPageState extends State<RetainerConfigPage> {
  bool _loading = true;
  bool _isRetainer = false;
  int _hoursPerMonth = 8;
  bool _rollsOver = false;
  List<Map<String, dynamic>> _ledger = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await RetainerService.show(widget.engagementId);
    if (!mounted) return;
    final eng = res?['engagement'] is Map<String, dynamic>
        ? res!['engagement'] as Map<String, dynamic>
        : null;
    final ledger = (res?['ledger'] as List?)
            ?.whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];
    setState(() {
      _isRetainer = eng?['is_retainer'] == true || eng?['is_retainer'] == 1;
      _hoursPerMonth = (eng?['retainer_hours_per_month'] as num?)?.toInt() ?? 8;
      _rollsOver = eng?['retainer_rolls_over'] == true || eng?['retainer_rolls_over'] == 1;
      _ledger = ledger;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final ok = await RetainerService.configure(
      engagementId: widget.engagementId,
      userId: widget.userId,
      isRetainer: _isRetainer,
      hoursPerMonth: _hoursPerMonth,
      rollsOver: _rollsOver,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Imehifadhiwa' : 'Imeshindikana')),
    );
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Retainer' : 'Retainer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isSw ? 'Ni retainer' : 'Retainer engagement'),
                        value: _isRetainer,
                        onChanged: (v) => setState(() => _isRetainer = v),
                      ),
                      if (_isRetainer) ...[
                        Row(
                          children: [
                            Expanded(child: Text(isSw ? 'Saa kwa mwezi' : 'Hours / month')),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              onPressed: _hoursPerMonth > 1
                                  ? () => setState(() => _hoursPerMonth--)
                                  : null,
                            ),
                            SizedBox(
                              width: 50,
                              child: Text('$_hoursPerMonth',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              onPressed: _hoursPerMonth < 200
                                  ? () => setState(() => _hoursPerMonth++)
                                  : null,
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(isSw ? 'Saa zinasonga mbele' : 'Hours roll over'),
                          value: _rollsOver,
                          onChanged: (v) => setState(() => _rollsOver = v),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSw ? 'Daftari la saa' : 'Hour ledger',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                if (_ledger.isEmpty)
                  Text(
                    isSw ? 'Hakuna kumbukumbu bado.' : 'No entries yet.',
                    style: const TextStyle(color: Color(0xFF666666)),
                  )
                else
                  ..._ledger.map((row) {
                    final consumed = (row['hours_consumed_minutes'] as num?)?.toInt() ?? 0;
                    final available = (row['hours_available_minutes'] as num?)?.toInt() ?? 0;
                    final period = row['period_month']?.toString() ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(period.substring(0, 7))),
                          Text(
                            '${(consumed / 60).toStringAsFixed(1)}h / ${(available / 60).toStringAsFixed(0)}h',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: consumed > available
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
