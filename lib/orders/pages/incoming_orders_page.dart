// lib/orders/pages/incoming_orders_page.dart
// Inbox of purchase orders destined for any business the user owns.
// Grouped by receiving business when the user owns more than one.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/incoming_order.dart';
import '../services/orders_service.dart';
import 'incoming_order_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);

class IncomingOrdersPage extends StatefulWidget {
  final int userId;

  /// When set, the page opens pre-filtered to this receiving business and
  /// hides the business chips. Used when embedding inside a business profile.
  final int? initialBusinessId;

  const IncomingOrdersPage({
    super.key,
    required this.userId,
    this.initialBusinessId,
  });

  @override
  State<IncomingOrdersPage> createState() => _IncomingOrdersPageState();
}

class _IncomingOrdersPageState extends State<IncomingOrdersPage> {
  String? _token;
  bool _loading = true;
  String? _error;
  List<IncomingOrder> _orders = [];
  List<Business> _myBusinesses = [];

  /// null = all businesses; otherwise filter to a single receiving business.
  int? _selectedBusinessId;

  /// When true the page was opened scoped to a single business; business
  /// chips are hidden and the filter cannot be changed.
  bool get _isLockedToBusiness => widget.initialBusinessId != null;

  /// null = all statuses.
  OrderStatus? _selectedStatus;

  bool _searchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedBusinessId = widget.initialBusinessId;
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (_token == null) {
      setState(() {
        _loading = false;
        _error = 'Not authenticated';
      });
      return;
    }
    await Future.wait([
      if (!_isLockedToBusiness) _loadBusinesses(),
      _loadOrders(),
    ]);
  }

  Future<void> _loadBusinesses() async {
    if (_token == null) return;
    final res = await BusinessService.getMyBusinesses(_token!, widget.userId);
    if (!mounted) return;
    setState(() {
      if (res.success) _myBusinesses = res.data;
    });
  }

  Future<void> _loadOrders() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final res = await OrdersService.getIncomingOrders(
      _token!,
      widget.userId,
      receivingBusinessId: _selectedBusinessId,
      status: _selectedStatus?.wire,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _orders = res.data;
        _error = null;
      } else {
        _error = res.message ?? 'Failed to load';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_searchOpen) _buildSearchField(),
            _buildReportsStrip(),
            if (!_isLockedToBusiness) _buildBusinessChips(),
            _buildStatusChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final scopedBizName = _isLockedToBusiness && _orders.isNotEmpty
        ? _orders.first.receivingBusinessName
        : null;
    final title = _isSwahili ? 'Maagizo' : 'Orders';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_rounded, size: 22, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              scopedBizName != null ? '$title — $scopedBizName' : title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
                _searchOpen
                    ? Icons.close_rounded
                    : Icons.search_rounded,
                size: 20,
                color: _kPrimary),
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }
              });
            },
            tooltip: _isSwahili ? 'Tafuta' : 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                size: 20, color: _kPrimary),
            onPressed: _loadOrders,
            tooltip: _isSwahili ? 'Onyesha upya' : 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: _isSwahili
              ? 'Tafuta PO#, mnunuzi, bidhaa...'
              : 'Search PO#, buyer, item...',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder),
          ),
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
      ),
    );
  }

  Widget _buildReportsStrip() {
    if (_orders.isEmpty) return const SizedBox.shrink();
    final today = DateTime.now();
    bool isToday(DateTime? d) =>
        d != null &&
        d.year == today.year &&
        d.month == today.month &&
        d.day == today.day;
    int countToday(OrderStatus s) =>
        _orders.where((o) => o.status == s && isToday(o.createdAt)).length;
    final submitted = countToday(OrderStatus.submitted);
    final accepted = countToday(OrderStatus.accepted);
    final shipped = countToday(OrderStatus.shipped);
    final delivered = countToday(OrderStatus.delivered);
    final pipelineTotal = _orders
        .where((o) =>
            o.status == OrderStatus.submitted ||
            o.status == OrderStatus.accepted ||
            o.status == OrderStatus.shipped)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSwahili ? 'LEO' : 'TODAY',
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _kSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _metric(
                    submitted, _isSwahili ? 'Yamepokelewa' : 'Submitted'),
                _metric(
                    accepted, _isSwahili ? 'Yamekubaliwa' : 'Accepted'),
                _metric(shipped, _isSwahili ? 'Yametumwa' : 'Shipped'),
                _metric(
                    delivered, _isSwahili ? 'Yamefika' : 'Delivered'),
              ],
            ),
            if (pipelineTotal > 0) ...[
              const SizedBox(height: 6),
              const Divider(height: 1, color: _kBorder),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _isSwahili ? 'Bomba la kazi: ' : 'Pipeline: ',
                    style: const TextStyle(
                        fontSize: 11, color: _kSecondary),
                  ),
                  Text(
                    'TZS ${NumberFormat('#,##0', 'en_US').format(pipelineTotal)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(int value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: _kSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessChips() {
    if (_myBusinesses.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(
            label: _isSwahili ? 'Zote' : 'All',
            selected: _selectedBusinessId == null,
            onTap: () {
              setState(() => _selectedBusinessId = null);
              _loadOrders();
            },
          ),
          ..._myBusinesses.map((b) => _chip(
                label: b.name,
                selected: _selectedBusinessId == b.id,
                onTap: () {
                  setState(() => _selectedBusinessId = b.id);
                  _loadOrders();
                },
              )),
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    final statuses = <OrderStatus?>[
      null,
      OrderStatus.submitted,
      OrderStatus.accepted,
      OrderStatus.shipped,
      OrderStatus.delivered,
      OrderStatus.rejected,
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: statuses
            .map((s) => _chip(
                  label: _statusLabel(s),
                  selected: _selectedStatus == s,
                  onTap: () {
                    setState(() => _selectedStatus = s);
                    _loadOrders();
                  },
                  dense: true,
                ))
            .toList(),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: selected ? _kPrimary : _kCardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: dense ? 10 : 12, vertical: dense ? 5 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? _kPrimary : _kBorder),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: dense ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<IncomingOrder> get _filteredOrders {
    if (_searchQuery.isEmpty) return _orders;
    final q = _searchQuery;
    return _orders.where((o) {
      if (o.poNumber.toLowerCase().contains(q)) return true;
      if (o.buyerDisplayName.toLowerCase().contains(q)) return true;
      for (final line in o.items) {
        if (line.description.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
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
    final orders = _filteredOrders;
    if (orders.isEmpty) {
      return _buildEmpty();
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: _buildGroupedList(orders),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.inbox_outlined, size: 48, color: _kSecondary),
        const SizedBox(height: 12),
        Text(
          _isSwahili
              ? 'Hakuna maagizo bado.'
              : 'No orders yet.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          _isSwahili
              ? 'Mtu akiagiza kwa moja ya biashara zako, yataonekana hapa.'
              : "When someone orders from one of your businesses, it will appear here.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
      ],
    );
  }

  Widget _buildGroupedList(List<IncomingOrder> orders) {
    // Group by receiving business only when showing "All" and user owns >1.
    final shouldGroup =
        _selectedBusinessId == null && _myBusinesses.length >= 2;
    if (!shouldGroup) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(orders[i]),
      );
    }
    final byBiz = <int, List<IncomingOrder>>{};
    for (final o in orders) {
      byBiz.putIfAbsent(o.receivingBusinessId, () => []).add(o);
    }
    final keys = byBiz.keys.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        for (final bizId in keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  _isSwahili
                      ? 'Inapokea: ${byBiz[bizId]!.first.receivingBusinessName}'
                      : 'Receiving: ${byBiz[bizId]!.first.receivingBusinessName}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${byBiz[bizId]!.length}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          ...byBiz[bizId]!.map(_orderCard),
        ],
      ],
    );
  }

  Widget _orderCard(IncomingOrder o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => IncomingOrderDetailPage(
                order: o,
                currentUserId: widget.userId,
              ),
            ),
          );
          // Reload in case status changed.
          _loadOrders();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _avatar(o.buyerAvatarUrl, o.buyerDisplayName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.buyerDisplayName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _statusChip(o.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${o.poNumber}  •  ${o.items.length} ${_isSwahili ? 'bidhaa' : 'items'}',
                      style: const TextStyle(
                          fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'TZS ${_fmtMoney(o.totalAmount)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                        const Spacer(),
                        Text(
                          _relativeTime(o.createdAt),
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String? url, String fallbackName) {
    final initial = fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: _kPrimary.withValues(alpha: 0.08),
      backgroundImage:
          (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
      child: (url == null || url.isEmpty)
          ? Text(initial,
              style: const TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 14))
          : null,
    );
  }

  Widget _statusChip(OrderStatus s) {
    final (bg, fg) = _statusColors(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _statusLabel(s),
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: fg),
      ),
    );
  }

  (Color, Color) _statusColors(OrderStatus s) {
    switch (s) {
      case OrderStatus.submitted:
        return (const Color(0xFFFFF4E5), const Color(0xFFB15400));
      case OrderStatus.accepted:
        return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20));
      case OrderStatus.shipped:
        return (const Color(0xFFE3F2FD), const Color(0xFF0D47A1));
      case OrderStatus.delivered:
        return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20));
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        return (const Color(0xFFFFEBEE), const Color(0xFFB71C1C));
      case OrderStatus.draft:
        return (const Color(0xFFF5F5F5), _kSecondary);
    }
  }

  String _statusLabel(OrderStatus? s) {
    if (s == null) return _isSwahili ? 'Zote' : 'All';
    switch (s) {
      case OrderStatus.draft: return _isSwahili ? 'Rasimu' : 'Draft';
      case OrderStatus.submitted: return _isSwahili ? 'Limewasilishwa' : 'Submitted';
      case OrderStatus.accepted: return _isSwahili ? 'Limekubaliwa' : 'Accepted';
      case OrderStatus.rejected: return _isSwahili ? 'Limekataliwa' : 'Rejected';
      case OrderStatus.shipped: return _isSwahili ? 'Limetumwa' : 'Shipped';
      case OrderStatus.delivered: return _isSwahili ? 'Limefika' : 'Delivered';
      case OrderStatus.cancelled: return _isSwahili ? 'Limeghairiwa' : 'Cancelled';
    }
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return _isSwahili ? 'Sasa hivi' : 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(dt);
  }

  String _fmtMoney(double v) => NumberFormat('#,##0', 'en_US').format(v);
}
