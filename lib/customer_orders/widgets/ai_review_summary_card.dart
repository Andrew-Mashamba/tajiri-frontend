import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/ai_review_summary_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Spec line 1118 — AI-generated review summary on partner profile.
/// Auto-generated weekly from last 30d reviews. Hides quietly when no
/// review data is available.
class AiReviewSummaryCard extends StatefulWidget {
  final int partnerUserId;
  const AiReviewSummaryCard({super.key, required this.partnerUserId});

  @override
  State<AiReviewSummaryCard> createState() => _AiReviewSummaryCardState();
}

class _AiReviewSummaryCardState extends State<AiReviewSummaryCard> {
  AiReviewSummary? _summary;
  bool _loading = true;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AiReviewSummaryService.fetch(widget.partnerUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _summary = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_summary == null) return const SizedBox.shrink();
    final isSw = _isSwahili;
    final body = isSw ? _summary!.summarySw : _summary!.summaryEn;
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 14, color: Color(0xFFE65100)),
              const SizedBox(width: 6),
              Text(
                isSw ? 'Muhtasari wa AI' : 'AI summary',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                ),
              ),
              const Spacer(),
              Text(
                isSw
                    ? '${_summary!.sampleSize} maoni'
                    : '${_summary!.sampleSize} reviews',
                style: const TextStyle(fontSize: 10, color: _kSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              color: _kPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
