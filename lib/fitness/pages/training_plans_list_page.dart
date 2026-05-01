import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_i_services.dart';

/// Spec F6 — Recurring training plans + check-ins. List page showing all
/// plans where the viewer is the coach or client.
class TrainingPlansListPage extends StatefulWidget {
  final int userId;
  const TrainingPlansListPage({super.key, required this.userId});

  @override
  State<TrainingPlansListPage> createState() => _TrainingPlansListPageState();
}

class _TrainingPlansListPageState extends State<TrainingPlansListPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _plans = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await TrainingPlanService.mine(widget.userId);
    if (!mounted) return;
    setState(() {
      _plans = rows;
      _loading = false;
    });
  }

  String _fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Mipango ya mafunzo' : 'Training plans'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isSw
                          ? 'Hakuna mpango bado.'
                          : 'No training plans yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _plans.length,
                  itemBuilder: (_, i) {
                    final p = _plans[i];
                    final isCoach =
                        (p['coach_user_id'] as num?)?.toInt() == widget.userId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(p['title']?.toString() ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCoach
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCoach
                                      ? (isSw ? 'Mkocha' : 'Coach')
                                      : (isSw ? 'Mteja' : 'Client'),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isCoach
                                          ? const Color(0xFF1B5E20)
                                          : const Color(0xFF1976D2)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p['duration_weeks']} ${isSw ? "wiki" : "weeks"} • TZS ${_fmt((p['price_tzs'] as num?)?.toInt() ?? 0)}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
