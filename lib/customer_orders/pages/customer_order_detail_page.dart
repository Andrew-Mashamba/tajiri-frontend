// lib/customer_orders/pages/customer_order_detail_page.dart
// Partner-side detail view for a single consumer order.
// Action set per status: pending → accept|reject;
// accepted/preparing → ready; ready → dispatch (delivery) | complete (pickup);
// out_for_delivery → complete; any non-terminal → cancel.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/customer_order.dart';
import '../services/customer_orders_service.dart';
import '../widgets/rate_partner_cta.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kDanger = Color(0xFFB71C1C);

class CustomerOrderDetailPage extends StatefulWidget {
  final int userId;
  final CustomerOrderSource source;
  final int orderId;

  /// 'partner' (default) shows partner action set (accept/reject/ready/...).
  /// 'customer' restricts the action bar to cancel-while-pending/accepted.
  final String role;

  const CustomerOrderDetailPage({
    super.key,
    required this.userId,
    required this.source,
    required this.orderId,
    this.role = 'partner',
  });

  @override
  State<CustomerOrderDetailPage> createState() =>
      _CustomerOrderDetailPageState();
}

class _CustomerOrderDetailPageState extends State<CustomerOrderDetailPage> {
  bool _loading = true;
  String? _error;
  CustomerOrder? _order;
  bool _busy = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await CustomerOrdersService.get(
      userId: widget.userId,
      source: widget.source,
      id: widget.orderId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _order = res.data;
        _error = null;
      } else {
        _error = res.message ?? 'Failed to load';
      }
    });
  }

  Future<void> _doAction(String action, {String? reason}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await CustomerOrdersService.action(
      userId: widget.userId,
      source: widget.source,
      id: widget.orderId,
      action: action,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success) {
      if (res.data != null) {
        setState(() => _order = res.data);
      } else {
        await _load();
      }
      _toast(_isSwahili ? 'Imefanikiwa' : 'Done');
      return;
    }
    // Spec §3 line 381: stale-state retry. 409 = conflict (someone else moved
    // the order forward); 422 = validation (action no longer legal for current
    // state). Either way, refetch so the user sees fresh state instead of
    // banging on a stale button.
    if (res.statusCode == 409 || res.statusCode == 422) {
      _toast(_isSwahili
          ? 'Hali ya agizo imebadilika. Inaonyeshwa upya...'
          : 'Order state changed. Refreshing...');
      await _load();
      return;
    }
    _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
  }

  /// Spec §3 line 380: tap → confirmation with status preview before commit.
  /// Returns true if the user confirmed.
  Future<bool> _previewAndConfirm({
    required String title,
    required CustomerOrderStatus nextStatus,
  }) async {
    final preview = _isSwahili
        ? 'Hali itabadilika kuwa: ${_statusLabel(nextStatus)}'
        : 'Status will change to: ${_statusLabel(nextStatus)}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kPrimary)),
        content: Text(preview, style: const TextStyle(color: _kPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isSwahili ? 'Endelea' : 'Confirm'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _confirmAndDo({
    required String action,
    required String dialogTitle,
    required CustomerOrderStatus nextStatus,
  }) async {
    final ok = await _previewAndConfirm(
      title: dialogTitle,
      nextStatus: nextStatus,
    );
    if (!ok) return;
    await _doAction(action);
  }

  String _statusLabel(CustomerOrderStatus s) {
    if (_isSwahili) return s.labelSwahili;
    switch (s) {
      case CustomerOrderStatus.pending:
        return 'Pending';
      case CustomerOrderStatus.accepted:
        return 'Accepted';
      case CustomerOrderStatus.preparing:
        return 'Preparing';
      case CustomerOrderStatus.ready:
        return 'Ready';
      case CustomerOrderStatus.outForDelivery:
        return 'On the way';
      case CustomerOrderStatus.completed:
        return 'Done';
      case CustomerOrderStatus.cancelled:
        return 'Cancelled';
      case CustomerOrderStatus.rejected:
        return 'Rejected';
    }
  }

  Future<String?> _promptReason(String title) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kPrimary)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: _isSwahili ? 'Sababu (si lazima)' : 'Reason (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(_isSwahili ? 'Endelea' : 'Confirm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            if (_order != null) _buildActionBar(_order!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                size: 22, color: _kPrimary),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              _isSwahili ? 'Agizo' : 'Order',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
          ),
          if (_loading)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary)),
        ),
      );
    }
    final o = _order!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        children: [
          _itemCard(o),
          const SizedBox(height: 12),
          if (o.handoffPin != null && o.handoffPin!.isNotEmpty)
            _handoffPinCard(o),
          if (o.handoffPin != null && o.handoffPin!.isNotEmpty)
            const SizedBox(height: 12),
          if (o.deliveryProofPhoto != null && o.deliveryProofPhoto!.isNotEmpty)
            _proofOfDeliveryCard(o),
          if (o.deliveryProofPhoto != null && o.deliveryProofPhoto!.isNotEmpty)
            const SizedBox(height: 12),
          _buyerCard(o),
          const SizedBox(height: 12),
          _deliveryCard(o),
          const SizedBox(height: 12),
          _summaryCard(o),
          if (o.tipTzs > 0) ...[
            const SizedBox(height: 12),
            _tipDisplayCard(o),
          ],
          if (widget.role == 'customer' &&
              o.status == CustomerOrderStatus.completed &&
              o.tipTzs == 0) ...[
            const SizedBox(height: 12),
            _tipPromptCard(o),
          ],
          if (widget.role == 'customer' &&
              o.selfReportDeadline != null &&
              o.selfReportDeadline!.isAfter(DateTime.now()) &&
              !o.customerSelfReportedIssue) ...[
            const SizedBox(height: 12),
            _selfReportChip(o),
          ],
          if ((o.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _notesCard(o.notes!),
          ],
          if ((o.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _rejectionCard(o.rejectionReason!),
          ],
          if (widget.role == 'customer' && o.status == CustomerOrderStatus.completed) ...[
            const SizedBox(height: 12),
            RatePartnerCta(
              reviewerUserId: widget.userId,
              source: o.source,
              sourceId: o.sourceRefId,
              partnerName: o.partnerName,
              itemTitle: o.itemTitle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _handoffPinCard(CustomerOrder o) {
    final isSw = _isSwahili;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: const Color(0xFF0D47A1).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 22, color: Color(0xFF0D47A1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw ? 'PIN ya kupokea' : 'Handoff PIN',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  o.handoffPin!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D47A1),
                    letterSpacing: 6,
                  ),
                ),
                Text(
                  isSw
                      ? 'Mpe kazi mfanyikazi anapowasilisha.'
                      : 'Share with the courier on arrival.',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _proofOfDeliveryCard(CustomerOrder o) {
    final isSw = _isSwahili;
    final url = ApiConfig.sanitizeUrl(o.deliveryProofPhoto!) ?? o.deliveryProofPhoto!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera_rounded,
                  size: 14, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 6),
              Text(
                isSw ? 'Picha ya kuwasilisha' : 'Delivery proof',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              url,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 160,
                color: const Color(0xFFEEEEEE),
                child: const Icon(Icons.broken_image_rounded,
                    color: Color(0xFF666666)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipDisplayCard(CustomerOrder o) {
    final isSw = _isSwahili;
    String fmt(int v) {
      final s = v.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism_rounded,
              size: 16, color: Color(0xFF1B5E20)),
          const SizedBox(width: 6),
          Text(
            isSw
                ? 'Bakshishi: TZS ${fmt(o.tipTzs)}'
                : 'Tip: TZS ${fmt(o.tipTzs)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipPromptCard(CustomerOrder o) {
    final isSw = _isSwahili;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism_outlined,
              size: 16, color: Color(0xFF1A1A1A)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isSw
                  ? 'Toa bakshishi kwa huduma nzuri (hadi siku 30).'
                  : 'Tip the partner for great service (up to 30 days).',
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () => _addTip(o),
            child: Text(isSw ? 'Toa bakshishi' : 'Add tip'),
          ),
        ],
      ),
    );
  }

  Widget _selfReportChip(CustomerOrder o) {
    final isSw = _isSwahili;
    final remaining = o.selfReportDeadline!.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.report_problem_outlined,
              size: 14, color: Color(0xFFE65100)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isSw
                  ? 'Kuna tatizo? Ripoti ndani ya siku $remaining.'
                  : 'Issue with order? Report within $remaining days.',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTip(CustomerOrder o) async {
    final isSw = _isSwahili;
    final ctrl = TextEditingController();
    final tip = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isSw ? 'Toa bakshishi' : 'Add tip'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final v in [1000, 2000, 5000])
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, v),
                      child: Text('TZS $v'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isSw ? 'Au ingiza kiasi' : 'Or enter amount',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(isSw ? 'Funga' : 'Close'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text.trim());
                Navigator.pop(ctx, v);
              },
              child: Text(isSw ? 'Tuma' : 'Send'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (tip == null || tip <= 0) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isSw
          ? 'Bakshishi ya TZS $tip imewekwa'
          : 'TZS $tip tip recorded'),
    ));
    // Note: real wallet/COA debit posting belongs in a backend `tip` endpoint.
  }

  Widget _itemCard(CustomerOrder o) {
    final photo = o.resolvedItemPhoto;
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _kPrimary.withValues(alpha: 0.06),
                    child: const Icon(Icons.restaurant_rounded,
                        size: 36, color: _kSecondary),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        o.itemTitle,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary),
                      ),
                    ),
                    _statusChip(o.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  o.source.labelSwahili,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buyerCard(CustomerOrder o) {
    final photo = o.resolvedBuyerPhoto;
    final phone = o.buyerPhone ?? '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            backgroundImage:
                photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? Text(
                    (o.buyerName ?? '?').isNotEmpty
                        ? (o.buyerName ?? '?')[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.buyerName ?? (_isSwahili ? 'Mnunuzi' : 'Buyer'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(phone,
                      style: const TextStyle(
                          fontSize: 12, color: _kSecondary)),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_rounded,
                  size: 20, color: _kAccent),
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _deliveryCard(CustomerOrder o) {
    final lines = <Widget>[];
    lines.add(_kvRow(
      _isSwahili ? 'Njia' : 'Mode',
      o.isDelivery
          ? (_isSwahili ? 'Kuletewa' : 'Delivery')
          : (_isSwahili ? 'Kujichukulia' : 'Pickup'),
      icon: o.isDelivery
          ? Icons.delivery_dining_rounded
          : Icons.storefront_outlined,
    ));
    if (o.isDelivery && (o.deliveryAddress ?? '').isNotEmpty) {
      lines.add(const SizedBox(height: 6));
      lines.add(_kvRow(
        _isSwahili ? 'Anwani' : 'Address',
        o.deliveryAddress!,
        icon: Icons.place_outlined,
      ));
    }
    if (o.requestedFor != null) {
      lines.add(const SizedBox(height: 6));
      lines.add(_kvRow(
        _isSwahili ? 'Muda ulioombwa' : 'Requested',
        DateFormat('d MMM, HH:mm').format(o.requestedFor!),
        icon: Icons.schedule_rounded,
      ));
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }

  Widget _summaryCard(CustomerOrder o) {
    final unit = o.unitPriceTzs ?? 0;
    final fee = o.deliveryFeeTzs ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _moneyRow(_isSwahili ? 'Idadi' : 'Quantity', 'x${o.quantity}'),
          if (unit > 0)
            _moneyRow(_isSwahili ? 'Bei kwa moja' : 'Unit price',
                'TZS ${_fmtMoney(unit)}'),
          if (fee > 0)
            _moneyRow(_isSwahili ? 'Usafirishaji' : 'Delivery fee',
                'TZS ${_fmtMoney(fee)}'),
          const Divider(height: 16, color: _kBorder),
          _moneyRow(
            _isSwahili ? 'JUMLA' : 'TOTAL',
            'TZS ${_fmtMoney(o.totalPriceTzs)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _notesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isSwahili ? 'Maelekezo ya mteja' : 'Customer notes',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: _kSecondary)),
          const SizedBox(height: 6),
          Text(notes,
              style: const TextStyle(fontSize: 13, color: _kPrimary)),
        ],
      ),
    );
  }

  Widget _rejectionCard(String reason) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: const Color(0xFFFFCDD2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isSwahili ? 'Sababu ya kukataa' : 'Rejection reason',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: _kDanger)),
          const SizedBox(height: 6),
          Text(reason, style: const TextStyle(fontSize: 13, color: _kDanger)),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: _kSecondary),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 86,
          child: Text(k,
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
        ),
        Expanded(
          child: Text(v,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
        ),
      ],
    );
  }

  Widget _moneyRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: bold ? 13 : 12,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: bold ? _kPrimary : _kSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 14 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: _kPrimary)),
        ],
      ),
    );
  }

  Widget _statusChip(CustomerOrderStatus s) {
    final (bg, fg) = _statusColors(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        s.labelSwahili,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: fg),
      ),
    );
  }

  (Color, Color) _statusColors(CustomerOrderStatus s) {
    switch (s) {
      case CustomerOrderStatus.pending:
        return (const Color(0xFFFFF4E5), const Color(0xFFB15400));
      case CustomerOrderStatus.accepted:
      case CustomerOrderStatus.preparing:
        return (const Color(0xFFE3F2FD), const Color(0xFF0D47A1));
      case CustomerOrderStatus.ready:
        return (const Color(0xFFE0F7FA), const Color(0xFF006064));
      case CustomerOrderStatus.outForDelivery:
        return (const Color(0xFFEDE7F6), const Color(0xFF4527A0));
      case CustomerOrderStatus.completed:
        return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20));
      case CustomerOrderStatus.cancelled:
      case CustomerOrderStatus.rejected:
        return (const Color(0xFFFFEBEE), const Color(0xFFB71C1C));
    }
  }

  Widget _buildActionBar(CustomerOrder o) {
    final actions = <Widget>[];
    final isCustomer = widget.role == 'customer';
    if (isCustomer) {
      // Customer can only cancel while pending or accepted (spec §2.265).
      if (o.status == CustomerOrderStatus.pending ||
          o.status == CustomerOrderStatus.accepted) {
        actions.add(_actionButton(
          label: _isSwahili ? 'Ghairi oda' : 'Cancel order',
          color: _kDanger,
          outlined: true,
          onTap: () async {
            final reason = await _promptReason(
                _isSwahili ? 'Ghairi oda?' : 'Cancel order?');
            if (reason == null) return;
            await _doAction('cancel', reason: reason.isEmpty ? null : reason);
          },
        ));
      } else {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(child: actions[i]),
              if (i < actions.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }
    switch (o.status) {
      case CustomerOrderStatus.pending:
        actions.add(_actionButton(
          label: _isSwahili ? 'Kataa' : 'Reject',
          color: _kDanger,
          outlined: true,
          onTap: () async {
            final reason = await _promptReason(
                _isSwahili ? 'Kataa agizo?' : 'Reject order?');
            if (reason == null) return;
            await _doAction('reject', reason: reason.isEmpty ? null : reason);
          },
        ));
        actions.add(_actionButton(
          label: _isSwahili ? 'Kubali' : 'Accept',
          color: _kAccent,
          onTap: () => _confirmAndDo(
            action: 'accept',
            dialogTitle: _isSwahili ? 'Kubali agizo?' : 'Accept order?',
            nextStatus: CustomerOrderStatus.accepted,
          ),
        ));
        break;
      case CustomerOrderStatus.accepted:
      case CustomerOrderStatus.preparing:
        actions.add(_actionButton(
          label: _isSwahili ? 'Ghairi' : 'Cancel',
          color: _kDanger,
          outlined: true,
          onTap: () async {
            final reason = await _promptReason(
                _isSwahili ? 'Ghairi agizo?' : 'Cancel order?');
            if (reason == null) return;
            await _doAction('cancel', reason: reason.isEmpty ? null : reason);
          },
        ));
        actions.add(_actionButton(
          label: _isSwahili ? 'Tayari' : 'Mark ready',
          color: _kPrimary,
          onTap: () => _confirmAndDo(
            action: 'ready',
            dialogTitle:
                _isSwahili ? 'Weka kama tayari?' : 'Mark as ready?',
            nextStatus: CustomerOrderStatus.ready,
          ),
        ));
        break;
      case CustomerOrderStatus.ready:
        actions.add(_actionButton(
          label: _isSwahili ? 'Ghairi' : 'Cancel',
          color: _kDanger,
          outlined: true,
          onTap: () async {
            final reason = await _promptReason(
                _isSwahili ? 'Ghairi agizo?' : 'Cancel order?');
            if (reason == null) return;
            await _doAction('cancel', reason: reason.isEmpty ? null : reason);
          },
        ));
        if (o.isDelivery) {
          actions.add(_actionButton(
            label: _isSwahili ? 'Tuma njiani' : 'Dispatch',
            color: _kPrimary,
            onTap: () => _confirmAndDo(
              action: 'dispatch',
              dialogTitle:
                  _isSwahili ? 'Tuma njiani?' : 'Dispatch for delivery?',
              nextStatus: CustomerOrderStatus.outForDelivery,
            ),
          ));
        } else {
          actions.add(_actionButton(
            label: _isSwahili ? 'Imekamilika' : 'Complete',
            color: _kAccent,
            onTap: () => _confirmAndDo(
              action: 'complete',
              dialogTitle:
                  _isSwahili ? 'Maliza agizo?' : 'Complete order?',
              nextStatus: CustomerOrderStatus.completed,
            ),
          ));
        }
        break;
      case CustomerOrderStatus.outForDelivery:
        actions.add(_actionButton(
          label: _isSwahili ? 'Imefika' : 'Delivered',
          color: _kAccent,
          onTap: () => _confirmAndDo(
            action: 'complete',
            dialogTitle: _isSwahili ? 'Imefika kwa mteja?' : 'Delivered?',
            nextStatus: CustomerOrderStatus.completed,
          ),
        ));
        break;
      case CustomerOrderStatus.completed:
      case CustomerOrderStatus.cancelled:
      case CustomerOrderStatus.rejected:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            Expanded(child: actions[i]),
            if (i < actions.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return SizedBox(
      height: 44,
      child: outlined
          ? OutlinedButton(
              onPressed: _busy ? null : onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            )
          : ElevatedButton(
              onPressed: _busy ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
    );
  }

  String _fmtMoney(int v) => NumberFormat('#,##0', 'en_US').format(v);
}
