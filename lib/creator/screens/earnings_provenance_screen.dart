// lib/creator/screens/earnings_provenance_screen.dart
//
// Per-event provenance ledger — strategy §9.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../models/creator_earnings_models.dart';
import '../services/creator_earnings_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);

class EarningsProvenanceScreen extends StatefulWidget {
  final int currentUserId;
  final int? postId;
  final String? stream;

  const EarningsProvenanceScreen({
    super.key,
    required this.currentUserId,
    this.postId,
    this.stream,
  });

  @override
  State<EarningsProvenanceScreen> createState() => _EarningsProvenanceScreenState();
}

class _EarningsProvenanceScreenState extends State<EarningsProvenanceScreen> {
  final _service = CreatorEarningsService();
  final List<EarningEventItem> _items = [];
  final _scroll = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _token;
  int _page = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _hydrate();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final token = (await LocalStorageService.getInstance()).getAuthToken();
    if (!mounted) return;
    setState(() => _token = token);
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _items.clear();
      _page = 1;
    });
    try {
      final result = widget.postId != null
          ? await _service.getPostEarningEvents(postId: widget.postId!, token: _token!, page: 1)
          : await _service.getEvents(userId: widget.currentUserId, token: _token!, page: 1, stream: widget.stream);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _lastPage = result.lastPage;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _sanitize(e.toString());
      });
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage || _token == null) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final result = widget.postId != null
          ? await _service.getPostEarningEvents(postId: widget.postId!, token: _token!, page: next)
          : await _service.getEvents(userId: widget.currentUserId, token: _token!, page: next, stream: widget.stream);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page = next;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  String _sanitize(String raw) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return isSw ? 'Hakuna intaneti.' : "Can't reach the server.";
    }
    return isSw ? 'Imeshindwa kupakia.' : 'Failed to load.';
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: isSw ? 'Matukio ya mapato' : 'Earnings ledger'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _error != null && _items.isEmpty
                ? _buildError(isSw)
                : _items.isEmpty
                    ? _buildEmpty(isSw)
                    : RefreshIndicator(
                        color: _kPrimary,
                        onRefresh: _refresh,
                        child: ListView.separated(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length + (_loadingMore ? 1 : 0),
                          separatorBuilder: (_, _) => const Divider(height: 1, color: _kBorder, indent: 16, endIndent: 16),
                          itemBuilder: (ctx, i) {
                            if (i >= _items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
                              );
                            }
                            return _ProvenanceEventTile(
                              event: _items[i],
                              isSw: isSw,
                              onDispute: () => _showDisputeSheet(_items[i]),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildEmpty(bool isSw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          isSw ? 'Hakuna matukio bado.' : 'No events yet.',
          style: const TextStyle(color: _kSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildError(bool isSw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_error ?? '', style: const TextStyle(color: _kSecondary, fontSize: 14), textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _refresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(isSw ? 'Jaribu tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDisputeSheet(EarningEventItem event) async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isSw ? 'Pinga tukio hili' : 'Dispute this event',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 8),
            Text(
              isSw
                  ? 'Eleza kwa nini hesabu hii ni mbaya. Tutachunguza ndani ya siku 5 za kazi.'
                  : 'Tell us why this credit is wrong. We investigate within 5 business days.',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              maxLines: 3, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isSw ? 'Sababu...' : 'Reason...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(isSw ? 'Tuma' : 'Submit'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.isNotEmpty && _token != null) {
      try {
        await _service.fileDispute(
          userId: widget.currentUserId,
          eventId: event.eventId,
          reason: result,
          token: _token!,
        );
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isSw ? 'Imepokea' : 'Filed'),
            content: Text(isSw ? 'Tutawasiliana nawe ndani ya siku 5.' : "We'll respond within 5 days."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isSw ? 'Imeshindwa' : 'Failed'),
            content: Text(_sanitize(e.toString())),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    }
  }
}

class _ProvenanceEventTile extends StatelessWidget {
  final EarningEventItem event;
  final bool isSw;
  final VoidCallback onDispute;

  const _ProvenanceEventTile({required this.event, required this.isSw, required this.onDispute});

  @override
  Widget build(BuildContext context) {
    final isPending = event.settlementStatus == 'pending';
    final isReversed = event.settlementStatus == 'reversed';
    final statusColor = isReversed
        ? const Color(0xFFD32F2F)
        : (isPending ? _kSecondary : _kPrimary);
    final statusLabel = isReversed
        ? (isSw ? 'Imerejeshwa' : 'Reversed')
        : (isPending ? (isSw ? 'Inangoja' : 'Pending') : (isSw ? 'Imeisha' : 'Cleared'));

    return InkWell(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onDispute();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${event.metric} · ${event.roleLabel(isSw)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _PayoutKindChip(kind: event.kind, isSw: isSw),
                      const SizedBox(width: 6),
                      if (!event.isChargeable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFE5E5),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text(
                            'SKIPPED',
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.isChargeable
                        ? '${event.rateTsh.toStringAsFixed(2)} × ${event.rawCount} × ${event.multiplierSummary()}'
                        : (event.chargeReason ?? '—'),
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(_formatDate(event.occurredAt),
                      style: const TextStyle(fontSize: 11, color: _kTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TZS ${event.netToCreator.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary, fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 4),
                Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final parts = iso.split('T');
    if (parts.length < 2) return iso;
    final time = parts[1].split('.').first.split(':').take(2).join(':');
    return '${parts[0]} · $time';
  }
}

class _PayoutKindChip extends StatelessWidget {
  final PayoutKind kind;
  final bool isSw;
  const _PayoutKindChip({required this.kind, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (kind) {
      PayoutKind.engagement => (
          const Color(0xFFEEF2FF),
          const Color(0xFF1A1A1A),
          isSw ? 'mwingiliano' : 'engagement'
        ),
      PayoutKind.royalty => (
          const Color(0xFFFFF4E5),
          const Color(0xFF8A4B00),
          isSw ? 'royalty' : 'royalty'
        ),
      PayoutKind.distribution => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          isSw ? 'usambazaji' : 'distribution'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
