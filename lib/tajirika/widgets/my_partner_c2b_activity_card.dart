import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../services/partner_c2b_metrics_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec §F — auto-resolving customer/partner activity card. Drop-in on any
/// vertical home page with a single line:
///
/// ```dart
/// const MyPartnerC2BActivityCard(sourceType: 'appointment', role: 'customer'),
/// ```
///
/// The widget resolves `userId` from `LocalStorageService` internally and
/// renders nothing when no user is signed in (so it's safe on guest views).
class MyPartnerC2BActivityCard extends StatefulWidget {
  /// Optional source filter. When omitted, totals across every source.
  final String? sourceType;
  /// Default 'customer'. Partner home pages use 'partner'.
  final String role;
  final int rangeDays;
  /// Optional bilingual title; falls back to a "Your activity" generic.
  final String? titleSwahili;
  final String? titleEnglish;
  const MyPartnerC2BActivityCard({
    super.key,
    this.sourceType,
    this.role = 'customer',
    this.rangeDays = 30,
    this.titleSwahili,
    this.titleEnglish,
  });

  @override
  State<MyPartnerC2BActivityCard> createState() =>
      _MyPartnerC2BActivityCardState();
}

class _MyPartnerC2BActivityCardState extends State<MyPartnerC2BActivityCard> {
  bool _loading = true;
  PartnerC2BMetricsTotals? _totals;
  int? _userId;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final uid = storage.getUser()?.userId;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      _userId = uid;
      final to = DateTime.now();
      final from = to.subtract(Duration(days: widget.rangeDays));
      final rows = await PartnerC2BMetricsApi.fetch(
        userId: uid,
        role: widget.role,
        sourceType: widget.sourceType,
        from: from,
        to: to,
      );
      if (!mounted) return;
      setState(() {
        _totals = PartnerC2BMetricsTotals.from(rows);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 1);
    }
    if (_userId == null || _totals == null || _totals!.totalNew == 0) {
      // Quietly hide when no signal — keeps home pages clean for new users.
      return const SizedBox.shrink();
    }
    final t = _totals!;
    final isSw = _isSwahili;
    final title = (isSw ? widget.titleSwahili : widget.titleEnglish)
        ?? (isSw ? 'Shughuli yako' : 'Your activity');
    final fmt = NumberFormat('#,##0');
    final isCustomer = widget.role == 'customer';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCustomer ? Icons.shopping_bag_rounded : Icons.work_history_rounded,
                size: 16, color: _kAccent,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const Spacer(),
              Text(
                isSw ? 'Siku ${widget.rangeDays}' : '${widget.rangeDays}d',
                style: const TextStyle(fontSize: 10, color: _kSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _stat(
                isSw ? 'Imekamilika' : 'Done',
                '${t.totalCompleted}',
              )),
              Expanded(child: _stat(
                isSw ? 'Inaendelea' : 'Active',
                '${t.totalActive}',
              )),
              Expanded(child: _stat(
                isCustomer ? (isSw ? 'Imelipwa' : 'Spent') : (isSw ? 'Mapato' : 'Earned'),
                'TZS ${fmt.format(t.totalRevenueTzs)}',
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: _kSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
