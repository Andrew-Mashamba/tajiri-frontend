import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/widgets/rate_partner_cta.dart';
import '../../housing/models/listing_inquiry.dart';
import '../../housing/services/listing_inquiry_service.dart';
import '../../customer_orders/widgets/lead_expiring_chip.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Detail page for a single listing_inquiry. Used by both the unified inbox
/// dispatcher and the partner inquiry inbox.
///
/// State-aware action bar:
///   pending → Acknowledge / Schedule / Reject
///   acknowledged → Schedule / Reject
///   scheduled → Mark viewed / Reject
///   viewed → (waits for customer offer) / Reject
///   offer_made → Accept offer / Reject offer
class PropertyInquiryDetailPage extends StatefulWidget {
  final int userId;
  final int inquiryId;
  final String role; // 'partner' | 'customer'

  const PropertyInquiryDetailPage({
    super.key,
    required this.userId,
    required this.inquiryId,
    required this.role,
  });

  @override
  State<PropertyInquiryDetailPage> createState() => _PropertyInquiryDetailPageState();
}

class _PropertyInquiryDetailPageState extends State<PropertyInquiryDetailPage> {
  ListingInquiry? _i;
  bool _loading = true;
  String? _error;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isPartner => widget.role == 'partner';

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
    final res = await ListingInquiryService.get(id: widget.inquiryId, userId: widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _i = res.inquiry;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _acknowledge() async {
    final res = await ListingInquiryService.acknowledge(id: widget.inquiryId, userId: widget.userId);
    _afterAction(res, _isSwahili ? 'Imepokelewa' : 'Acknowledged');
  }

  Future<void> _schedule() async {
    final i = _i;
    if (i == null) return;
    final initial = i.preferredViewingAt ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;
    final pick = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final res = await ListingInquiryService.schedule(
      id: widget.inquiryId,
      userId: widget.userId,
      scheduledAt: pick,
    );
    _afterAction(res, _isSwahili ? 'Kuonana kumepangwa' : 'Viewing scheduled');
  }

  Future<void> _markViewed() async {
    final res = await ListingInquiryService.markViewed(id: widget.inquiryId, userId: widget.userId);
    _afterAction(res, _isSwahili ? 'Imeonwa' : 'Marked viewed');
  }

  Future<void> _accept() async {
    final res = await ListingInquiryService.acceptOffer(id: widget.inquiryId, userId: widget.userId);
    _afterAction(res, _isSwahili ? 'Bei imekubaliwa' : 'Offer accepted');
  }

  Future<void> _reject() async {
    final reason = await _askReason(_isSwahili ? 'Sababu ya kukataa' : 'Reject reason');
    if (reason == null) return;
    final res = await ListingInquiryService.rejectOffer(
      id: widget.inquiryId,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    _afterAction(res, _isSwahili ? 'Imekataliwa' : 'Rejected');
  }

  Future<void> _cancel() async {
    final reason = await _askReason(_isSwahili ? 'Sababu ya kughairi' : 'Cancellation reason');
    if (reason == null) return;
    final res = await ListingInquiryService.cancel(
      id: widget.inquiryId,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    _afterAction(res, _isSwahili ? 'Imeghairiwa' : 'Cancelled');
  }

  void _afterAction(ListingInquiryResult res, String okMsg) {
    if (!mounted) return;
    if (res.success) {
      _toast(okMsg);
      _load();
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
    }
  }

  Future<String?> _askReason(String title) {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(hintText: _isSwahili ? 'Sababu (hiari)' : 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            child: Text(_isSwahili ? 'Tuma' : 'Submit'),
          ),
        ],
      ),
    );
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
          _isSwahili ? 'Swali #${widget.inquiryId}' : 'Inquiry #${widget.inquiryId}',
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
              : _i == null
                  ? Center(child: Text(_isSwahili ? 'Hapatikani' : 'Not found',
                      style: const TextStyle(color: _kMuted)))
                  : _buildBody(_i!),
      bottomNavigationBar: _i == null ? null : _buildActionBar(_i!),
    );
  }

  Widget _buildBody(ListingInquiry i) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          _statusCard(i),
          const SizedBox(height: 6),
          LeadExpiringChipFetcher(
            orderId: i.id,
            sourceApiValue: 'listing_inquiry',
            isSwahili: _isSwahili,
          ),
          const SizedBox(height: 10),
          _listingCard(i),
          const SizedBox(height: 10),
          _detailsCard(i),
          const SizedBox(height: 10),
          _counterpartyCard(i),
          if (i.parentInquiryId != null) ...[
            const SizedBox(height: 10),
            _counterOfferBanner(i),
          ],
          if (!_isPartner && i.status == InquiryStatus.accepted) ...[
            const SizedBox(height: 10),
            RatePartnerCta(
              reviewerUserId: widget.userId,
              source: CustomerOrderSource.listingInquiry,
              sourceId: i.id,
              partnerName: i.partnerName,
              itemTitle: i.listingTitle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusCard(ListingInquiry i) {
    final (bg, fg) = _statusColors(i.status);
    final responseMin = i.partnerResponseMinutes;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_isSwahili ? "Hali" : "Status"}: ${_isSwahili ? i.status.labelSwahili : i.status.label}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
          if (responseMin != null && responseMin >= 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 10, color: fg),
                  const SizedBox(width: 2),
                  Text(
                    _isSwahili
                        ? 'Jibu: $responseMin daka'
                        : 'Replied in $responseMin min',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  Widget _listingCard(ListingInquiry i) {
    return _card([
      Row(
        children: [
          const Icon(Icons.home_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              i.listingTitle ?? '—',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      if (i.listingPriceTzs != null)
        Text(
          '${_isSwahili ? "Bei iliyowekwa" : "Listed"}: TZS ${NumberFormat('#,##0', 'en_US').format(i.listingPriceTzs)}',
          style: const TextStyle(fontSize: 11, color: _kMuted),
        ),
    ]);
  }

  Widget _detailsCard(ListingInquiry i) {
    return _card([
      _kv(_isSwahili ? 'Aina' : 'Kind', _isSwahili ? i.kind.labelSwahili : i.kind.label, icon: Icons.label_outline_rounded),
      if (i.preferredViewingAt != null)
        _kv(_isSwahili ? 'Tarehe iliyopendekezwa' : 'Preferred',
            DateFormat('EEE d MMM • HH:mm').format(i.preferredViewingAt!),
            icon: Icons.event_rounded),
      if (i.scheduledAt != null)
        _kv(_isSwahili ? 'Imepangwa' : 'Scheduled',
            DateFormat('EEE d MMM • HH:mm').format(i.scheduledAt!),
            icon: Icons.event_available_rounded),
      if (i.offerPriceTzs != null)
        _kv(_isSwahili ? 'Bei iliyotolewa' : 'Offer',
            'TZS ${NumberFormat('#,##0', 'en_US').format(i.offerPriceTzs)}',
            icon: Icons.attach_money_rounded),
      if (i.message != null && i.message!.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(_isSwahili ? 'Ujumbe' : 'Message',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
        const SizedBox(height: 4),
        Text(i.message!, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
      ],
      if (i.rejectionReason != null && i.rejectionReason!.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          '${_isSwahili ? "Sababu ya kukataa" : "Rejected"}: ${i.rejectionReason}',
          style: const TextStyle(fontSize: 11, color: Color(0xFFB71C1C)),
        ),
      ],
    ]);
  }

  Widget _counterpartyCard(ListingInquiry i) {
    final showName = _isPartner ? i.customerName : i.partnerName;
    final showLabel = _isPartner
        ? (_isSwahili ? 'Mteja' : 'Customer')
        : (_isSwahili ? 'Wakala' : 'Agent');
    return _card([
      Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _kPrimary.withValues(alpha: 0.06),
            child: Text(
              (showName ?? '?').characters.first,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(showName ?? '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text(showLabel, style: const TextStyle(fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
            tooltip: _isSwahili ? 'WhatsApp' : 'WhatsApp',
            onPressed: () => _openWhatsApp(i),
          ),
        ],
      ),
      if (i.prequalCompletedAt != null) ...[
        const SizedBox(height: 8),
        _prequalSummary(i),
      ],
    ]);
  }

  Future<void> _openWhatsApp(ListingInquiry i) async {
    final messenger = ScaffoldMessenger.of(context);
    final isSw = _isSwahili;
    final phone = _isPartner ? null : null; // backend exposes phone elsewhere
    if (phone == null || phone.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(isSw
            ? 'Nambari haijajulikana. Tumia mazungumzo ya ndani ya app.'
            : 'No phone on file. Use in-app chat instead.'),
      ));
      return;
    }
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final greeting = Uri.encodeComponent(
      isSw
          ? 'Habari, ningependa maelezo zaidi kuhusu ${i.listingTitle ?? "tangazo"}.'
          : 'Hi, I\'d like more info on ${i.listingTitle ?? "the listing"}.',
    );
    final uri = Uri.parse('https://wa.me/$cleaned?text=$greeting');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(isSw
            ? 'Imeshindikana kufungua WhatsApp'
            : 'Could not open WhatsApp'),
      ));
    }
  }

  Widget _prequalSummary(ListingInquiry i) {
    final isSw = _isSwahili;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  size: 12, color: Color(0xFF0D47A1)),
              const SizedBox(width: 4),
              Text(
                isSw ? 'Maandalizi ya mteja' : 'Pre-qualification',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (i.prequalMoveIn != null)
            Text(
              '${isSw ? "Kuhamia" : "Move-in"}: ${i.prequalMoveIn}',
              style: const TextStyle(fontSize: 11),
            ),
          if (i.prequalFinancing != null)
            Text(
              '${isSw ? "Kifedha" : "Financing"}: ${i.prequalFinancing}',
              style: const TextStyle(fontSize: 11),
            ),
          if (i.prequalWorkingWithAgent != null)
            Text(
              '${isSw ? "Wakala mwingine" : "Other agent"}: ${i.prequalWorkingWithAgent! ? (isSw ? "Ndio" : "Yes") : (isSw ? "Hapana" : "No")}',
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _counterOfferBanner(ListingInquiry i) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _isSwahili
            ? 'Hii ni jibu kwa swali la awali #${i.parentInquiryId}'
            : 'This responds to inquiry #${i.parentInquiryId}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB15400)),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _kv(String k, String v, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _kMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(k, style: const TextStyle(fontSize: 12, color: _kMuted))),
          Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
    );
  }

  Widget? _buildActionBar(ListingInquiry i) {
    if (i.hasFinalised) return null;

    final List<Widget> actions = [];
    Widget btn(IconData icon, String label, VoidCallback onTap, {Color color = _kPrimary}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    }
    Widget outline(IconData icon, String label, VoidCallback onTap, {Color color = _kPrimary}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ),
      );
    }

    if (_isPartner) {
      switch (i.status) {
        case InquiryStatus.pending:
          actions.add(outline(Icons.close_rounded, _isSwahili ? 'Kataa' : 'Reject', _reject, color: const Color(0xFFB71C1C)));
          actions.add(outline(Icons.check_rounded, _isSwahili ? 'Pokea' : 'Ack', _acknowledge));
          actions.add(btn(Icons.event_rounded, _isSwahili ? 'Panga' : 'Schedule', _schedule));
          break;
        case InquiryStatus.acknowledged:
          actions.add(outline(Icons.close_rounded, _isSwahili ? 'Kataa' : 'Reject', _reject, color: const Color(0xFFB71C1C)));
          actions.add(btn(Icons.event_rounded, _isSwahili ? 'Panga' : 'Schedule', _schedule));
          break;
        case InquiryStatus.scheduled:
          actions.add(outline(Icons.close_rounded, _isSwahili ? 'Kataa' : 'Reject', _reject, color: const Color(0xFFB71C1C)));
          actions.add(btn(Icons.visibility_rounded, _isSwahili ? 'Imeonwa' : 'Mark viewed', _markViewed));
          break;
        case InquiryStatus.viewed:
          actions.add(outline(Icons.close_rounded, _isSwahili ? 'Kataa' : 'Reject', _reject, color: const Color(0xFFB71C1C)));
          break;
        case InquiryStatus.offerMade:
          actions.add(outline(Icons.close_rounded, _isSwahili ? 'Kataa' : 'Reject', _reject, color: const Color(0xFFB71C1C)));
          actions.add(btn(Icons.check_circle_rounded, _isSwahili ? 'Kubali' : 'Accept', _accept, color: const Color(0xFF1B5E20)));
          break;
        case InquiryStatus.accepted:
        case InquiryStatus.rejected:
        case InquiryStatus.cancelled:
          return null;
      }
    } else {
      // customer side: only cancel
      actions.add(btn(Icons.cancel_rounded, _isSwahili ? 'Ghairi' : 'Cancel', _cancel,
          color: const Color(0xFFB71C1C)));
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(children: actions),
      ),
    );
  }
}
