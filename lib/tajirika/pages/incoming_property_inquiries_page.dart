import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../housing/models/listing_inquiry.dart';
import '../../housing/services/listing_inquiry_service.dart';
import '../../l10n/app_strings_scope.dart';
import 'property_inquiry_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Partner-facing inquiries inbox grouped by listing (spec line 873).
class IncomingPropertyInquiriesPage extends StatefulWidget {
  final int userId;
  const IncomingPropertyInquiriesPage({super.key, required this.userId});

  @override
  State<IncomingPropertyInquiriesPage> createState() => _IncomingPropertyInquiriesPageState();
}

class _IncomingPropertyInquiriesPageState extends State<IncomingPropertyInquiriesPage> {
  bool _loading = true;
  String? _error;
  List<ListingInquiry> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ListingInquiryService.list(userId: widget.userId, role: 'partner');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.items;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  Future<void> _open(ListingInquiry i) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyInquiryDetailPage(
          userId: widget.userId,
          inquiryId: i.id,
          role: 'partner',
        ),
      ),
    );
    if (mounted) _load();
  }

  Map<int, List<ListingInquiry>> get _grouped {
    final m = <int, List<ListingInquiry>>{};
    for (final i in _items) {
      m.putIfAbsent(i.listingId, () => []).add(i);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isSwahili ? 'Maswali ya Mali' : 'Property Inquiries',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: _kMuted))),
                )
              : _items.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _buildList(),
                    ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline_rounded, size: 56, color: _kMuted),
            const SizedBox(height: 12),
            Text(_isSwahili ? 'Hakuna maswali bado' : 'No inquiries yet',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final groups = _grouped.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: groups.length,
      itemBuilder: (_, gi) {
        final entry = groups[gi];
        final inquiries = entry.value;
        final title = inquiries.first.listingTitle ?? '#${entry.key}';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: _kPrimary.withValues(alpha: 0.04),
                child: Row(
                  children: [
                    const Icon(Icons.home_rounded, size: 14, color: _kPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
                    ),
                    Text('${inquiries.length}',
                        style: const TextStyle(fontSize: 11, color: _kMuted)),
                  ],
                ),
              ),
              ...inquiries.map(_inquiryRow),
            ],
          ),
        );
      },
    );
  }

  Widget _inquiryRow(ListingInquiry i) {
    final (bg, fg) = _statusColors(i.status);
    return InkWell(
      onTap: () => _open(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isSwahili ? i.kind.labelSwahili : i.kind.label,
                style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: _kPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.customerName ?? '—',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (i.message != null && i.message!.isNotEmpty)
                    Text(
                      i.message!,
                      style: const TextStyle(fontSize: 10, color: _kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (i.offerPriceTzs != null)
              Text(
                'TZS ${NumberFormat('#,##0', 'en_US').format(i.offerPriceTzs)}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isSwahili ? i.status.labelSwahili : i.status.label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _statusColors(InquiryStatus s) {
    switch (s) {
      case InquiryStatus.pending: return (const Color(0xFFFFF4E5), const Color(0xFFB15400));
      case InquiryStatus.acknowledged: return (const Color(0xFFE3F2FD), const Color(0xFF0D47A1));
      case InquiryStatus.scheduled: return (const Color(0xFFEDE7F6), const Color(0xFF4527A0));
      case InquiryStatus.viewed: return (const Color(0xFFE0F7FA), const Color(0xFF006064));
      case InquiryStatus.offerMade: return (const Color(0xFFFFF8E1), const Color(0xFFE65100));
      case InquiryStatus.accepted: return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20));
      case InquiryStatus.rejected:
      case InquiryStatus.cancelled: return (const Color(0xFFFFEBEE), const Color(0xFFB71C1C));
    }
  }
}
