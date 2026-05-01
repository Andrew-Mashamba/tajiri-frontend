import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/event_quote_request_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCardBg = Colors.white;
const Color _kBorder = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF2E7D32);
const Color _kError = Color(0xFFE53935);

/// Customer-side detail page — shows the brief, the live bid feed, and the
/// award control. Polls for new bids every 15 seconds while the auction is
/// open. Spec line 1018.
class EventBriefDetailPage extends StatefulWidget {
  final int briefId;
  final int customerUserId;

  const EventBriefDetailPage({
    super.key,
    required this.briefId,
    required this.customerUserId,
  });

  @override
  State<EventBriefDetailPage> createState() => _EventBriefDetailPageState();
}

class _EventBriefDetailPageState extends State<EventBriefDetailPage> {
  EventQuoteRequest? _brief;
  bool _loading = true;
  bool _awarding = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_brief?.status == 'open') _load(silent: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? true;

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final brief = await EventQuoteRequestService.show(widget.briefId);
    if (!mounted) return;
    setState(() {
      _brief = brief;
      _loading = false;
    });
  }

  Future<void> _award(EventQuoteBid bid) async {
    final sw = _isSwahili;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Thibitisha' : 'Confirm award'),
        content: Text(
          sw
              ? 'Mpe ${bid.partnerName ?? "mhudumu"} kazi hii kwa TZS ${_fmt(bid.bidTotalTzs)}? Ofa zingine zitafungwa.'
              : 'Award ${bid.partnerName ?? "this partner"} the job at TZS ${_fmt(bid.bidTotalTzs)}? Other bids will be closed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(sw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(sw ? 'Mpe' : 'Award'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _awarding = true);
    final ok = await EventQuoteRequestService.award(
      requestId: widget.briefId,
      userId: widget.customerUserId,
      bidId: bid.id,
    );
    if (!mounted) return;
    setState(() => _awarding = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sw ? 'Imeshaadhibitishwa' : 'Awarded')),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sw ? 'Imeshindikana. Jaribu tena.' : 'Failed. Try again.')),
      );
    }
  }

  Future<void> _cancelBrief() async {
    final sw = _isSwahili;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ghairi ombi?' : 'Cancel brief?'),
        content: Text(
          sw
              ? 'Ombi hili litafungwa na ofa zote zitaghairiwa. Una uhakika?'
              : 'This brief will close and all open bids will be cancelled. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(sw ? 'Hapana' : 'No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _kError),
            child: Text(sw ? 'Ndiyo' : 'Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await EventQuoteRequestService.cancel(
      requestId: widget.briefId,
      userId: widget.customerUserId,
    );
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sw ? 'Imeshindikana' : 'Failed')),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          sw ? 'Ombi lako' : 'Your brief',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_brief?.status == 'open')
            IconButton(
              tooltip: sw ? 'Ghairi' : 'Cancel',
              icon: const Icon(Icons.close_rounded),
              onPressed: _cancelBrief,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _brief == null
              ? Center(
                  child: Text(sw ? 'Halikupatikana' : 'Not found'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _buildSummary(_brief!, sw),
                      const SizedBox(height: 20),
                      _buildBidsHeader(_brief!, sw),
                      const SizedBox(height: 8),
                      ..._brief!.bids.map((b) => _buildBidCard(_brief!, b, sw)),
                      if (_brief!.bids.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text(
                              sw
                                  ? 'Hakuna ofa bado. Tumeshawajulisha wahudumu.'
                                  : 'No bids yet. We\'ve notified matched partners.',
                              style: const TextStyle(color: _kSecondary, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummary(EventQuoteRequest b, bool sw) {
    final fmt = DateFormat('EEE d MMM, HH:mm', sw ? 'sw' : 'en');
    final remaining = b.expiresAt.difference(DateTime.now());
    final closed = b.status != 'open' || remaining.isNegative;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.eventTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusChip(b.status, sw),
            ],
          ),
          const SizedBox(height: 12),
          _kvRow(Icons.event_outlined, fmt.format(b.eventStartsAt), sw),
          if (b.eventAddress != null && b.eventAddress!.isNotEmpty)
            _kvRow(Icons.place_outlined, b.eventAddress!, sw),
          _kvRow(Icons.group_outlined,
              sw ? '${b.partySize} wageni' : '${b.partySize} guests', sw),
          if (b.budgetMaxTzs != null || b.budgetMinTzs != null)
            _kvRow(
              Icons.payments_outlined,
              _formatBudget(b.budgetMinTzs, b.budgetMaxTzs, sw),
              sw,
            ),
          if (b.description != null && b.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              b.description!,
              style: const TextStyle(fontSize: 13.5, color: _kSecondary, height: 1.45),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: closed ? const Color(0xFFEEEEEE) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  closed ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 16,
                  color: closed ? _kSecondary : const Color(0xFF0D47A1),
                ),
                const SizedBox(width: 8),
                Text(
                  closed
                      ? (b.status == 'awarded'
                          ? (sw ? 'Imeshachaguliwa' : 'Awarded')
                          : (sw ? 'Muda umeisha' : 'Window closed'))
                      : (sw
                          ? 'Inafungwa baada ya ${_remainingShort(remaining, sw)}'
                          : 'Closes in ${_remainingShort(remaining, sw)}'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: closed ? _kSecondary : const Color(0xFF0D47A1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidsHeader(EventQuoteRequest b, bool sw) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          sw ? 'Ofa zilizopokelewa' : 'Bids received',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        Text(
          '${b.bids.length}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kSecondary),
        ),
      ],
    );
  }

  Widget _buildBidCard(EventQuoteRequest brief, EventQuoteBid bid, bool sw) {
    final isAwarded = bid.id == brief.awardedQuoteId;
    final canAward = brief.status == 'open' && bid.status == 'submitted' && !_awarding;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAwarded ? _kSuccess : _kBorder,
          width: isAwarded ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bid.partnerName ?? (sw ? 'Mhudumu' : 'Partner'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              if (isAwarded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSuccess,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sw ? 'Amechaguliwa' : 'Awarded',
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'TZS ${_fmt(bid.bidTotalTzs)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kPrimary),
          ),
          if (bid.bidDepositTzs != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sw
                    ? 'Amana: TZS ${_fmt(bid.bidDepositTzs!)}'
                    : 'Deposit: TZS ${_fmt(bid.bidDepositTzs!)}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ),
          if (bid.pitch != null && bid.pitch!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bid.pitch!,
              style: const TextStyle(fontSize: 13.5, color: _kSecondary, height: 1.45),
            ),
          ],
          if (canAward) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => _award(bid),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  sw ? 'Mpe huyu' : 'Award this bid',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────

  Widget _kvRow(IconData icon, String text, bool sw) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _kSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, color: _kSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, bool sw) {
    final mapping = {
      'open': (sw ? 'Wazi' : 'Open', const Color(0xFFE3F2FD), const Color(0xFF0D47A1)),
      'awarded': (sw ? 'Imechaguliwa' : 'Awarded', const Color(0xFFE8F5E9), _kSuccess),
      'cancelled': (sw ? 'Imeghairiwa' : 'Cancelled', const Color(0xFFFFEBEE), _kError),
      'expired': (sw ? 'Imeisha' : 'Expired', const Color(0xFFEEEEEE), _kSecondary),
    };
    final m = mapping[status] ?? (status, const Color(0xFFEEEEEE), _kSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: m.$2, borderRadius: BorderRadius.circular(12)),
      child: Text(
        m.$1,
        style: TextStyle(fontSize: 11.5, color: m.$3, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatBudget(int? min, int? max, bool sw) {
    if (min != null && max != null) return 'TZS ${_fmt(min)}–${_fmt(max)}';
    if (max != null) return sw ? 'Hadi TZS ${_fmt(max)}' : 'Up to TZS ${_fmt(max)}';
    if (min != null) return sw ? 'Kuanzia TZS ${_fmt(min)}' : 'From TZS ${_fmt(min)}';
    return '';
  }

  String _fmt(int n) {
    final s = n.toString();
    final sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) sb.write(',');
      sb.write(s[i]);
    }
    return sb.toString();
  }

  String _remainingShort(Duration d, bool sw) {
    if (d.isNegative) return sw ? '0d' : '0m';
    if (d.inHours >= 1) return sw ? '${d.inHours} saa' : '${d.inHours} h';
    return sw ? '${d.inMinutes} dakika' : '${d.inMinutes} min';
  }
}
