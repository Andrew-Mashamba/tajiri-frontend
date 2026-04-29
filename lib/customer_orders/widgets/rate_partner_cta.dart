import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/customer_order.dart';
import '../models/partner_review.dart';
import '../pages/rate_partner_page.dart';
import '../services/partner_review_service.dart';

/// Drop-in CTA card shown on completed-order customer detail pages
/// (spec §11 line 1059). Self-loads existing review if present so it doubles
/// as an "Edit your rating" entry within the 24h window.
class RatePartnerCta extends StatefulWidget {
  final int reviewerUserId;
  final CustomerOrderSource source;
  final int sourceId;
  final String? partnerName;
  /// Spec line 1093 — passed through so the F11 anti-troll Chat handoff can
  /// resolve a private conversation with the partner directly.
  final int? partnerUserId;
  final String? itemTitle;
  final EdgeInsetsGeometry margin;

  const RatePartnerCta({
    super.key,
    required this.reviewerUserId,
    required this.source,
    required this.sourceId,
    this.partnerName,
    this.partnerUserId,
    this.itemTitle,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<RatePartnerCta> createState() => _RatePartnerCtaState();
}

class _RatePartnerCtaState extends State<RatePartnerCta> {
  PartnerReview? _existing;
  bool _loaded = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final r = await PartnerReviewService.findExisting(
      source: widget.source,
      sourceId: widget.sourceId,
      reviewerUserId: widget.reviewerUserId,
    );
    if (!mounted) return;
    setState(() {
      _existing = r;
      _loaded = true;
    });
  }

  Future<void> _openRate() async {
    final saved = await Navigator.push<PartnerReview?>(
      context,
      MaterialPageRoute(
        builder: (_) => RatePartnerPage(
          reviewerUserId: widget.reviewerUserId,
          source: widget.source,
          sourceId: widget.sourceId,
          partnerName: widget.partnerName,
          partnerUserId: widget.partnerUserId,
          itemTitle: widget.itemTitle,
          existing: _existing,
        ),
      ),
    );
    if (!mounted) return;
    if (saved != null) setState(() => _existing = saved);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final hasReview = _existing != null;
    return Padding(
      padding: widget.margin,
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openRate,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  hasReview ? Icons.edit_rounded : Icons.star_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasReview
                            ? (_isSwahili ? 'Hariri Maoni Yako' : 'Edit Your Rating')
                            : (_isSwahili
                                ? 'Toa Nyota kwa ${widget.partnerName ?? "mshirika"}'
                                : 'Rate ${widget.partnerName ?? "the partner"}'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasReview
                            ? (_isSwahili
                                ? 'Una nyota ${_existing!.stars} • Saa 24 za kuhariri'
                                : '${_existing!.stars} stars • 24h to edit')
                            : (_isSwahili
                                ? 'Maoni yako yanasaidia wengine'
                                : 'Your review helps others'),
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
