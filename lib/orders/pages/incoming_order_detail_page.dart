// lib/orders/pages/incoming_order_detail_page.dart
// Receiver-side detail view of an incoming purchase order.
// Shows buyer header (chat/call actions for individuals, visit-profile for
// businesses), items, totals, and a status-conditional action bar that
// drives PATCH /api/business/incoming-orders/{id}/status.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../calendar/models/calendar_models.dart';
import '../../calendar/services/calendar_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../screens/calls/outgoing_call_flow_screen.dart';
import '../../services/local_storage_service.dart';
import '../../services/message_service.dart';
import '../models/incoming_order.dart';
import '../services/orders_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);

class IncomingOrderDetailPage extends StatefulWidget {
  final IncomingOrder order;
  final int currentUserId;

  const IncomingOrderDetailPage({
    super.key,
    required this.order,
    required this.currentUserId,
  });

  @override
  State<IncomingOrderDetailPage> createState() =>
      _IncomingOrderDetailPageState();
}

class _IncomingOrderDetailPageState extends State<IncomingOrderDetailPage> {
  late IncomingOrder _order;
  String? _token;
  /// Which action is currently in-flight. `null` = no action running.
  /// Used so only the tapped button shows a spinner.
  OrderStatus? _pendingAction;

  bool get _isBusy => _pendingAction != null;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadToken();
  }

  Future<void> _loadToken() async {
    final storage = await LocalStorageService.getInstance();
    if (!mounted) return;
    setState(() => _token = storage.getAuthToken());
  }

  Future<void> _refresh() async {
    if (_token == null) return;
    final res = await OrdersService.getIncomingOrders(
      _token!,
      widget.currentUserId,
      receivingBusinessId: _order.receivingBusinessId,
    );
    if (!mounted) return;
    if (res.success) {
      final match =
          res.data.where((o) => o.id == _order.id).cast<IncomingOrder?>().firstWhere(
                (o) => o != null,
                orElse: () => null,
              );
      if (match != null) setState(() => _order = match);
    }
  }

  // ── Status transitions ────────────────────────────────────────────────

  Future<void> _transitionTo(OrderStatus next,
      {String? confirmLabel, String? reason}) async {
    if (_token == null || _isBusy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _pendingAction = next);
    final res = await OrdersService.updateStatus(
      _token!,
      _order.id,
      widget.currentUserId,
      next,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _pendingAction = null);
    if (res.success) {
      setState(() => _order = _withStatus(_order, next, reason: reason));
      messenger.showSnackBar(SnackBar(
        content: Text(confirmLabel ??
            (_isSwahili ? 'Hali imebadilishwa' : 'Status updated')),
      ));
      if (next == OrderStatus.accepted) {
        _maybeCreateDeliveryReminder();
      } else if (next == OrderStatus.delivered) {
        _promptRecordRevenue();
      }
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(res.message ??
            (_isSwahili ? 'Imeshindikana' : 'Failed to update')),
      ));
    }
  }

  IncomingOrder _withStatus(IncomingOrder o, OrderStatus s, {String? reason}) =>
      IncomingOrder(
        id: o.id,
        poNumber: o.poNumber,
        status: s,
        items: o.items,
        subtotal: o.subtotal,
        vatAmount: o.vatAmount,
        totalAmount: o.totalAmount,
        receivingBusinessId: o.receivingBusinessId,
        receivingBusinessName: o.receivingBusinessName,
        receivingBusinessLogoUrl: o.receivingBusinessLogoUrl,
        buyerType: o.buyerType,
        buyerUserId: o.buyerUserId,
        buyerBusinessName: o.buyerBusinessName,
        buyerBusinessLogoUrl: o.buyerBusinessLogoUrl,
        buyerFirstName: o.buyerFirstName,
        buyerLastName: o.buyerLastName,
        buyerUsername: o.buyerUsername,
        buyerPhone: o.buyerPhone,
        buyerPhotoUrl: o.buyerPhotoUrl,
        expectedDeliveryDate: o.expectedDeliveryDate,
        notes: o.notes,
        createdAt: o.createdAt,
        rejectionReason: reason ?? o.rejectionReason,
      );

  Future<void> _confirmReject() async {
    final reasonCtrl = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Kataa agizo?' : 'Reject order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSwahili
                  ? 'Kataa agizo ${_order.poNumber}?'
                  : 'Reject order ${_order.poNumber}?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: _isSwahili ? 'Sababu (hiari)' : 'Reason (optional)',
                hintText: _isSwahili
                    ? 'Mfano: Bei juu sana, hakuna stock...'
                    : 'E.g. out of stock, price too low...',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: Text(_isSwahili ? 'Kataa' : 'Reject'),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (res == true) {
      await _transitionTo(
        OrderStatus.rejected,
        confirmLabel: _isSwahili ? 'Agizo limekataliwa' : 'Order rejected',
        reason: reason.isEmpty ? null : reason,
      );
    }
  }

  // ── Cross-module integrations ─────────────────────────────────────────

  /// On Accept: auto-create a calendar event for the expected delivery date.
  Future<void> _maybeCreateDeliveryReminder() async {
    final due = _order.expectedDeliveryDate;
    if (due == null) return;
    final svc = CalendarService();
    final event = CalendarEvent(
      id: 0,
      userId: widget.currentUserId,
      title: _isSwahili
          ? 'Agizo: ${_order.poNumber} kwa ${_order.buyerDisplayName}'
          : 'Order: ${_order.poNumber} for ${_order.buyerDisplayName}',
      date: DateTime(due.year, due.month, due.day),
      isAllDay: true,
      reminder: EventReminder.day1,
      notes: _isSwahili
          ? 'Tarehe ya kufika. Jumla: TZS ${_fmtMoney(_order.totalAmount)}'
          : 'Expected delivery. Total: TZS ${_fmtMoney(_order.totalAmount)}',
      source: EventSource.personal,
    );
    await svc.createEvent(event);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isSwahili
          ? 'Kikumbusho cha kufika kimewekwa'
          : 'Delivery reminder added to calendar'),
    ));
  }

  /// On Delivered: prompt to record as revenue in accounting.
  void _promptRecordRevenue() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Rekodi mapato?' : 'Record revenue?'),
        content: Text(
          _isSwahili
              ? 'Je, rekodi TZS ${_fmtMoney(_order.totalAmount)} kama mapato ya ${_order.receivingBusinessName}?'
              : 'Record TZS ${_fmtMoney(_order.totalAmount)} as revenue in ${_order.receivingBusinessName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Baadaye' : 'Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/accounting');
            },
            child: Text(_isSwahili ? 'Fungua' : 'Open accounting'),
          ),
        ],
      ),
    );
  }

  // ── Chat / Call actions ───────────────────────────────────────────────

  Future<void> _openChat() async {
    final buyerId = _order.buyerUserId;
    if (buyerId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await MessageService()
        .getPrivateConversation(widget.currentUserId, buyerId);
    if (!mounted) return;
    if (res.success && res.conversation != null) {
      Navigator.pushNamed(
        context,
        '/chat/${res.conversation!.id}',
        arguments: <String, dynamic>{'conversation': res.conversation},
      );
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Imeshindikana kufungua gumzo'
            : 'Could not open chat'),
      ));
    }
  }

  void _startCall(String type) {
    final buyerId = _order.buyerUserId;
    if (buyerId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OutgoingCallFlowScreen(
          currentUserId: widget.currentUserId,
          authToken: _token,
          calleeId: buyerId,
          calleeName: _order.buyerDisplayName,
          calleeAvatarUrl: _order.buyerAvatarUrl,
          type: type,
        ),
      ),
    );
  }

  void _visitBuyerProfile() {
    final buyerId = _order.buyerUserId;
    if (buyerId == null) return;
    Navigator.pushNamed(context, '/profile/$buyerId');
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          _order.poNumber,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildReceivingHeader(),
              const SizedBox(height: 10),
              _buildBuyerCard(),
              const SizedBox(height: 10),
              _buildStatusTimeline(),
              const SizedBox(height: 10),
              _buildItemsCard(),
              const SizedBox(height: 10),
              _buildMetaCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildReceivingHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront_outlined, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style:
                    const TextStyle(fontSize: 12, color: _kSecondary),
                children: [
                  TextSpan(
                    text:
                        _isSwahili ? 'Inapokea kama: ' : 'Receiving as: ',
                  ),
                  TextSpan(
                    text: _order.receivingBusinessName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerCard() {
    final isBusiness = _order.buyerType == 'business';
    final canChatCall = _order.buyerUserId != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _visitBuyerProfile,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                  backgroundImage: (_order.buyerAvatarUrl?.isNotEmpty ?? false)
                      ? NetworkImage(_order.buyerAvatarUrl!)
                      : null,
                  child: (_order.buyerAvatarUrl?.isEmpty ?? true)
                      ? Text(
                          _order.buyerDisplayName.isNotEmpty
                              ? _order.buyerDisplayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: _kPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _order.buyerDisplayName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBusiness
                          ? (_isSwahili ? 'Biashara' : 'Business')
                          : (_isSwahili ? 'Mtu binafsi' : 'Individual'),
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                    if (_order.buyerPhone?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        _order.buyerPhone!,
                        style:
                            const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (canChatCall) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _outlineBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: _isSwahili ? 'Gumzo' : 'Chat',
                    onTap: _openChat,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _outlineBtn(
                    icon: Icons.call_rounded,
                    label: _isSwahili ? 'Piga' : 'Call',
                    onTap: () => _startCall('audio'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _outlineBtn(
                    icon: Icons.videocam_rounded,
                    label: _isSwahili ? 'Video' : 'Video',
                    onTap: () => _startCall('video'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: _kPrimary),
      label: Text(
        label,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kBorder),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    const order = [
      OrderStatus.submitted,
      OrderStatus.accepted,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    final isRejected = _order.status == OrderStatus.rejected ||
        _order.status == OrderStatus.cancelled;
    final currentIndex = isRejected ? -1 : order.indexOf(_order.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSwahili ? 'Hali' : 'Status',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _kSecondary),
          ),
          const SizedBox(height: 10),
          if (isRejected)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cancel_rounded,
                        size: 16, color: Color(0xFFB71C1C)),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel(_order.status),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB71C1C)),
                    ),
                  ],
                ),
                if (_order.rejectionReason?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Text(
                    _isSwahili
                        ? 'Sababu: ${_order.rejectionReason}'
                        : 'Reason: ${_order.rejectionReason}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                for (int i = 0; i < order.length; i++) ...[
                  _timelineDot(
                    label: _statusLabel(order[i]),
                    active: i <= currentIndex,
                  ),
                  if (i < order.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < currentIndex ? _kPrimary : _kBorder,
                      ),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _timelineDot({required String label, required bool active}) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: active ? _kPrimary : _kCardBg,
            shape: BoxShape.circle,
            border: Border.all(color: active ? _kPrimary : _kBorder, width: 2),
          ),
          child: active
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: active ? _kPrimary : _kSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSwahili ? 'Bidhaa' : 'Items',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _kSecondary),
          ),
          const SizedBox(height: 8),
          for (final line in _order.items) _itemRow(line),
          const Divider(height: 18, color: _kBorder),
          _totalsRow(
              _isSwahili ? 'Jumla ndogo' : 'Subtotal', _order.subtotal),
          _totalsRow(_isSwahili ? 'VAT' : 'VAT', _order.vatAmount),
          const SizedBox(height: 4),
          _totalsRow(_isSwahili ? 'Jumla' : 'Total', _order.totalAmount,
              bold: true),
        ],
      ),
    );
  }

  Widget _itemRow(IncomingOrderLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              line.description,
              style: const TextStyle(fontSize: 12, color: _kPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_fmtQty(line.quantity)} × ${_fmtMoney(line.unitPrice)}',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: Text(
              _fmtMoney(line.totalPrice),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? _kPrimary : _kSecondary,
              ),
            ),
          ),
          Text(
            'TZS ${_fmtMoney(value)}',
            style: TextStyle(
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    final items = <_MetaRow>[];
    if (_order.expectedDeliveryDate != null) {
      items.add(_MetaRow(
        icon: Icons.event_rounded,
        label: _isSwahili ? 'Tarehe ya kufika' : 'Expected delivery',
        value: DateFormat('d MMM yyyy').format(_order.expectedDeliveryDate!),
      ));
    }
    if (_order.createdAt != null) {
      items.add(_MetaRow(
        icon: Icons.schedule_rounded,
        label: _isSwahili ? 'Iliundwa' : 'Created',
        value: DateFormat('d MMM yyyy, HH:mm').format(_order.createdAt!),
      ));
    }
    if (_order.notes?.isNotEmpty ?? false) {
      items.add(_MetaRow(
        icon: Icons.sticky_note_2_outlined,
        label: _isSwahili ? 'Maelezo' : 'Notes',
        value: _order.notes!,
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (final m in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(m.icon, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.label,
                        style: const TextStyle(
                            fontSize: 10,
                            color: _kSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.value,
                        style: const TextStyle(
                            fontSize: 12, color: _kPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (m != items.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget? _buildActionBar() {
    final status = _order.status;
    // Read-only for terminal / draft states.
    if (status == OrderStatus.delivered ||
        status == OrderStatus.rejected ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.draft) {
      return null;
    }

    final tokenReady = _token != null;

    List<Widget> actions;
    switch (status) {
      case OrderStatus.submitted:
        actions = [
          Expanded(
            child: _secondaryBtn(
              label: _isSwahili ? 'Kataa' : 'Reject',
              loading: _pendingAction == OrderStatus.rejected,
              onTap: !tokenReady || _isBusy ? null : _confirmReject,
              danger: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _primaryBtn(
              label: _isSwahili ? 'Kubali' : 'Accept',
              loading: _pendingAction == OrderStatus.accepted,
              onTap: !tokenReady || _isBusy
                  ? null
                  : () => _transitionTo(
                        OrderStatus.accepted,
                        confirmLabel: _isSwahili
                            ? 'Agizo limekubaliwa'
                            : 'Order accepted',
                      ),
            ),
          ),
        ];
        break;
      case OrderStatus.accepted:
        actions = [
          Expanded(
            child: _secondaryBtn(
              label: _isSwahili ? 'Tuma ujumbe' : 'Message',
              loading: false,
              onTap: (_order.buyerUserId == null || _isBusy) ? null : _openChat,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _primaryBtn(
              label: _isSwahili ? 'Imetumwa' : 'Mark Shipped',
              loading: _pendingAction == OrderStatus.shipped,
              onTap: !tokenReady || _isBusy
                  ? null
                  : () => _transitionTo(
                        OrderStatus.shipped,
                        confirmLabel: _isSwahili
                            ? 'Imetumwa kwa mteja'
                            : 'Order marked as shipped',
                      ),
            ),
          ),
        ];
        break;
      case OrderStatus.shipped:
        actions = [
          Expanded(
            child: _primaryBtn(
              label: _isSwahili ? 'Imefika' : 'Mark Delivered',
              loading: _pendingAction == OrderStatus.delivered,
              onTap: !tokenReady || _isBusy
                  ? null
                  : () => _transitionTo(
                        OrderStatus.delivered,
                        confirmLabel: _isSwahili
                            ? 'Imefika kwa mteja'
                            : 'Order delivered',
                      ),
            ),
          ),
        ];
        break;
      default:
        return null;
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(children: actions),
      ),
    );
  }

  Widget _primaryBtn({
    required String label,
    required VoidCallback? onTap,
    required bool loading,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }

  Widget _secondaryBtn({
    required String label,
    required VoidCallback? onTap,
    required bool loading,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFB71C1C) : _kPrimary;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: danger ? color : _kBorder),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }

  // ── Format helpers ────────────────────────────────────────────────────

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.draft:
        return _isSwahili ? 'Rasimu' : 'Draft';
      case OrderStatus.submitted:
        return _isSwahili ? 'Limewasilishwa' : 'Submitted';
      case OrderStatus.accepted:
        return _isSwahili ? 'Limekubaliwa' : 'Accepted';
      case OrderStatus.rejected:
        return _isSwahili ? 'Limekataliwa' : 'Rejected';
      case OrderStatus.shipped:
        return _isSwahili ? 'Limetumwa' : 'Shipped';
      case OrderStatus.delivered:
        return _isSwahili ? 'Limefika' : 'Delivered';
      case OrderStatus.cancelled:
        return _isSwahili ? 'Limeghairiwa' : 'Cancelled';
    }
  }

  String _fmtMoney(double v) => NumberFormat('#,##0', 'en_US').format(v);
  String _fmtQty(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

class _MetaRow {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow({required this.icon, required this.label, required this.value});
}
