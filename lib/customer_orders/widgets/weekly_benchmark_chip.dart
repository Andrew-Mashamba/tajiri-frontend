import 'dart:convert';

import 'package:flutter/material.dart';
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';

/// Spec F3 #19 — Weekly competitive benchmark surface.
///
/// Reads `/api/partner-weekly-benchmarks?user_id=X` (cron-populated) and
/// renders a one-line "you accepted 12 / median 18" comparator chip on the
/// partner inbox header.
class WeeklyBenchmarkChip extends StatefulWidget {
  final int userId;
  const WeeklyBenchmarkChip({super.key, required this.userId});

  @override
  State<WeeklyBenchmarkChip> createState() => _WeeklyBenchmarkChipState();
}

class _WeeklyBenchmarkChipState extends State<WeeklyBenchmarkChip> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final url = ApiConfig.sanitizeUrl(
          '${ApiConfig.baseUrl}/api/partner-weekly-benchmarks?user_id=${widget.userId}')!;
      final res = await httpGetWithRetry(Uri.parse(url));
      if (!mounted || res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) setState(() => _data = body);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final mine = (d['mine_accepted'] as num?)?.toInt();
    final median = (d['cluster_median_accepted'] as num?)?.toInt();
    if (mine == null || median == null) return const SizedBox.shrink();
    final ahead = mine >= median;
    final accent = ahead ? const Color(0xFF1B5E20) : const Color(0xFFE65100);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            ahead ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSw
                  ? 'Wiki hii: ulipokea $mine • wastani wa eneo lako $median'
                  : 'This week: you accepted $mine • cluster median $median',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
