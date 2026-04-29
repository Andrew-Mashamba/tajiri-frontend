import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/models/partner_review.dart';
import '../../customer_orders/services/partner_review_service.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kStarOn = Color(0xFFFFB300);

/// Spec §11 line 1067 — partner-side review management.
class MyReviewsPage extends StatefulWidget {
  final int userId;
  const MyReviewsPage({super.key, required this.userId});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  bool _loading = true;
  PartnerReviewListResult? _result;
  String? _filterSource;
  int? _minStars;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await PartnerReviewService.listForPartner(
      partnerUserId: widget.userId,
      filterSource: _filterSource,
      minStars: _minStars,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _reply(PartnerReview r) async {
    final ctrl = TextEditingController();
    final reply = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Jibu la mteja' : 'Reply to customer',
            style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: _isSwahili ? 'Andika jibu lako (5-1000)' : 'Your reply (5-1000)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.length < 5) return;
              Navigator.pop(ctx, t);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(_isSwahili ? 'Tuma' : 'Submit'),
          ),
        ],
      ),
    );
    if (reply == null) return;
    final res = await PartnerReviewService.reply(
      id: r.id,
      partnerUserId: widget.userId,
      reply: reply,
    );
    if (!mounted) return;
    if (res.success) {
      _toast(_isSwahili ? 'Jibu limetumwa' : 'Reply posted');
      _load();
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final agg = _result?.aggregate ?? PartnerReviewAggregate.empty();
    final items = _result?.items ?? const <PartnerReview>[];
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isSwahili ? 'Maoni Yangu' : 'My Reviews',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _aggregateCard(agg),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _empty()
                  else
                    ...items.map(_reviewRow),
                ],
              ),
            ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_border_rounded, size: 56, color: _kMuted),
          const SizedBox(height: 12),
          Text(_isSwahili ? 'Hakuna maoni bado' : 'No reviews yet',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 6),
          Text(
            _isSwahili
                ? 'Maoni ya wateja yataonyeshwa hapa baada ya kukamilisha hafla.'
                : 'Customer reviews appear here once orders complete.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }

  Widget _aggregateCard(PartnerReviewAggregate agg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: _kStarOn, size: 28),
              const SizedBox(width: 6),
              Text(
                agg.count == 0 ? '—' : agg.avgStars.toStringAsFixed(1),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                _isSwahili ? 'maoni ${agg.count}' : '${agg.count} reviews',
                style: const TextStyle(fontSize: 12, color: _kMuted),
              ),
            ],
          ),
          if (agg.count > 0) ...[
            const SizedBox(height: 12),
            for (var s = 5; s >= 1; s--) _distRow(s, agg),
          ],
        ],
      ),
    );
  }

  Widget _distRow(int stars, PartnerReviewAggregate agg) {
    final count = agg.distribution[stars] ?? 0;
    final pct = agg.count == 0 ? 0.0 : (count / agg.count);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text('$stars',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary)),
          ),
          const Icon(Icons.star_rounded, size: 11, color: _kStarOn),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: _kBorder,
                valueColor: const AlwaysStoppedAnimation(_kStarOn),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text('$count',
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 11, color: _kMuted)),
          ),
        ],
      ),
    );
  }

  Widget _replyWindowChip(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _isSwahili ? 'Muda umeisha' : 'Window closed',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF666666),
          ),
        ),
      );
    }
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final label = days > 0
        ? (_isSwahili ? 'Siku $days zilizobaki' : '$days days left')
        : (_isSwahili ? 'Saa $hours zilizobaki' : '$hours h left');
    final urgent = remaining.inHours < 24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: urgent
              ? const Color(0xFFE65100)
              : const Color(0xFF0D47A1),
        ),
      ),
    );
  }

  Widget _reviewRow(PartnerReview r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                    i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: _kStarOn,
                  )),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.isAnonymous ? (_isSwahili ? 'Mteja' : 'Customer') : (r.reviewerName ?? '—'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (r.isVerifiedBooking) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 9, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 2),
                      Text(
                        _isSwahili ? 'Imethibitishwa' : 'Verified',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (r.isReturningCustomer) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    r.priorOrdersCount > 1
                        ? (_isSwahili
                            ? 'Mteja wa kawaida (${r.priorOrdersCount})'
                            : '${r.priorOrdersCount} prior orders')
                        : (_isSwahili ? 'Mteja wa kurudia' : 'Returning'),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (r.createdAt != null)
                Text(
                  DateFormat('d MMM').format(r.createdAt!),
                  style: const TextStyle(fontSize: 10, color: _kMuted),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isSwahili ? r.source.labelSwahili : r.source.labelSwahili,
            style: const TextStyle(fontSize: 10, color: _kMuted),
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.comment!, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
          ],
          if (r.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: r.tags.map((t) {
                final parsed = ReviewTag.fromString(t);
                final label = parsed != null
                    ? (_isSwahili ? parsed.labelSwahili : parsed.label)
                    : t;
                final isPos = parsed?.isPositive ?? true;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPos
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPos ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (r.partnerReply != null && r.partnerReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSwahili ? 'Jibu lako' : 'Your reply',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(r.partnerReply!,
                      style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
                ],
              ),
            ),
          ],
          if (r.canPartnerReply) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _reply(r),
                  icon: const Icon(Icons.reply_rounded, size: 14),
                  label: Text(_isSwahili ? 'Jibu hadharani' : 'Public reply'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kBorder),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (r.replyWindowExpiresAt != null) ...[
                  const SizedBox(width: 6),
                  _replyWindowChip(r.replyWindowExpiresAt!),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
