// lib/customer_orders/pages/partner_inbox_page.dart
// Partner-facing inbox with bulk-action selection mode (F3 #18, #20).
// Reuses the unified order list from CustomerOrdersService but adds
// long-press selection, checkboxes, and a floating action bar.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../tajirika/models/tajirika_models.dart' show SkillCategory;
import '../models/customer_order.dart';
import '../services/customer_orders_service.dart';
import '../widgets/lead_expiring_chip.dart';
import '../widgets/repeat_customer_chip.dart';
import 'customer_order_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);

enum _StatusBucket { all, mpya, inaendelea, imekamilika, imeghairiwa }

extension _StatusBucketX on _StatusBucket {
  bool matches(CustomerOrderStatus s) {
    switch (this) {
      case _StatusBucket.all:
        return true;
      case _StatusBucket.mpya:
        return s == CustomerOrderStatus.pending;
      case _StatusBucket.inaendelea:
        return s == CustomerOrderStatus.accepted ||
            s == CustomerOrderStatus.preparing ||
            s == CustomerOrderStatus.ready ||
            s == CustomerOrderStatus.outForDelivery;
      case _StatusBucket.imekamilika:
        return s == CustomerOrderStatus.completed;
      case _StatusBucket.imeghairiwa:
        return s == CustomerOrderStatus.cancelled ||
            s == CustomerOrderStatus.rejected;
    }
  }
}

class PartnerInboxPage extends StatefulWidget {
  final int userId;

  const PartnerInboxPage({super.key, required this.userId});

  @override
  State<PartnerInboxPage> createState() => _PartnerInboxPageState();
}

class _PartnerInboxPageState extends State<PartnerInboxPage> {
  bool _loading = true;
  String? _error;
  List<CustomerOrder> _orders = [];
  _StatusBucket _selectedBucket = _StatusBucket.all;
  CustomerOrderSource? _selectedSource;
  SkillCategory? _selectedSkill;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  bool _bulkProcessing = false;

  /// F3 #20 — cached customer history per buyer_user_id.
  final Map<int, int> _priorOrdersCache = {};

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Not authenticated';
      });
      return;
    }
    final res = await CustomerOrdersService.list(
      userId: widget.userId,
      role: 'partner',
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _orders = res.items;
        _error = null;
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _error = res.message ?? 'Failed to load';
      }
    });
    _fetchCustomerHistory();
  }

  Future<void> _fetchCustomerHistory() async {
    final uniqueBuyers = _orders.map((o) => o.buyerUserId).toSet().toList();
    if (uniqueBuyers.length > 30) uniqueBuyers.length = 30;
    final futures = uniqueBuyers.map((buyerId) => _fetchOneHistory(buyerId));
    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  Future<void> _fetchOneHistory(int buyerId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/partner-inbox/customer-history')
          .replace(queryParameters: {
        'customer_user_id': '$buyerId',
        'partner_user_id': '${widget.userId}',
      });
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          final count = (data['prior_orders_count'] as num?)?.toInt() ?? 0;
          _priorOrdersCache[buyerId] = count;
        }
      }
    } catch (_) {
      // silently fail; chip hides when no data
    }
  }

  void _enterSelection(CustomerOrder order) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add('${order.source.apiValue}:${order.id}');
    });
  }

  void _toggleSelection(CustomerOrder order) {
    final key = '${order.source.apiValue}:${order.id}';
    setState(() {
      if (_selectedIds.contains(key)) {
        _selectedIds.remove(key);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(key);
      }
    });
  }

  List<CustomerOrder> get _filteredOrders {
    return _orders.where((o) {
      if (!_selectedBucket.matches(o.status)) return false;
      if (_selectedSource != null && o.source != _selectedSource) return false;
      if (_selectedSkill != null && o.skillCategory != _selectedSkill) return false;
      return true;
    }).toList();
  }

  List<CustomerOrder> get _selectedOrders {
    return _filteredOrders.where((o) {
      final key = '${o.source.apiValue}:${o.id}';
      return _selectedIds.contains(key);
    }).toList();
  }

  Future<void> _batchAccept() async {
    final items = _batchPayload();
    if (items.isEmpty) return;
    setState(() => _bulkProcessing = true);
    final res = await CustomerOrdersService.batchAccept(
      userId: widget.userId,
      items: items,
    );
    setState(() => _bulkProcessing = false);
    if (res.success) {
      _selectedIds.clear();
      _selectionMode = false;
      await _load();
    } else {
      _showSnack(res.message ?? 'Failed');
    }
  }

  Future<void> _batchDecline() async {
    final items = _batchPayload();
    if (items.isEmpty) return;
    setState(() => _bulkProcessing = true);
    final res = await CustomerOrdersService.batchDecline(
      userId: widget.userId,
      items: items,
    );
    setState(() => _bulkProcessing = false);
    if (res.success) {
      _selectedIds.clear();
      _selectionMode = false;
      await _load();
    } else {
      _showSnack(res.message ?? 'Failed');
    }
  }

  List<Map<String, dynamic>> _batchPayload() {
    return _selectedOrders
        .where((o) =>
            o.source == CustomerOrderSource.chefProduct ||
            o.source == CustomerOrderSource.chefListing ||
            o.source == CustomerOrderSource.partnerProduct)
        .map((o) => {'source': o.source.apiValue, 'id': o.id})
        .toList();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
            _buildSourceChips(),
            _buildSkillChips(),
            _buildBucketChips(),
            Expanded(child: _buildBody()),
            if (_selectionMode) _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = _isSwahili ? 'Maagizo ya wateja' : 'Customer orders';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _kPrimary),
            onPressed: () => Navigator.maybePop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.receipt_long_rounded, size: 22, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_selectionMode)
            TextButton(
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              }),
              child: Text(_isSwahili ? 'Ghairi' : 'Cancel'),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: _kPrimary),
              onPressed: _load,
              tooltip: _isSwahili ? 'Onyesha upya' : 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildSourceChips() {
    final all = _isSwahili ? 'Zote' : 'All';
    final entries = <(CustomerOrderSource?, String)>[
      (null, all),
      ...CustomerOrderSource.values.map((s) => (s, _sourceLabel(s))),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: entries
            .map((e) => _chip(
                  label: e.$2,
                  selected: _selectedSource == e.$1,
                  onTap: () => setState(() => _selectedSource = e.$1),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSkillChips() {
    final skills = _visibleSkills;
    if (skills.length < 2) return const SizedBox.shrink();
    final entries = <(SkillCategory?, String)>[
      (null, _isSwahili ? 'Zote' : 'All'),
      ...skills.map((s) => (s, _isSwahili ? s.labelSwahili : s.label)),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: entries
            .map((e) => _chip(
                  label: e.$2,
                  selected: _selectedSkill == e.$1,
                  onTap: () => setState(() => _selectedSkill = e.$1),
                ))
            .toList(),
      ),
    );
  }

  List<SkillCategory> get _visibleSkills {
    final set = <SkillCategory>{};
    for (final o in _orders) {
      final s = o.skillCategory;
      if (s != null) set.add(s);
    }
    final list = set.toList()..sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  Widget _buildBucketChips() {
    final buckets = <_StatusBucket>[
      _StatusBucket.all,
      _StatusBucket.mpya,
      _StatusBucket.inaendelea,
      _StatusBucket.imekamilika,
      _StatusBucket.imeghairiwa,
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: buckets
            .map((b) => _chip(
                  label: _bucketLabel(b),
                  selected: _selectedBucket == b,
                  onTap: () => setState(() => _selectedBucket = b),
                ))
            .toList(),
      ),
    );
  }

  String _sourceLabel(CustomerOrderSource s) {
    if (_isSwahili) return s.labelSwahili;
    switch (s) {
      case CustomerOrderSource.chefListing:
        return 'Daily meal';
      case CustomerOrderSource.chefProduct:
        return 'Pre-order';
      case CustomerOrderSource.partnerProduct:
        return 'Product';
      case CustomerOrderSource.serviceRequest:
        return 'Service';
      case CustomerOrderSource.garageBooking:
        return 'Garage';
      case CustomerOrderSource.appointment:
        return 'Appointment';
      case CustomerOrderSource.consultation:
        return 'Consultation';
      case CustomerOrderSource.engagement:
        return 'Engagement';
      case CustomerOrderSource.listingInquiry:
        return 'Property';
      case CustomerOrderSource.eventBooking:
        return 'Event';
    }
  }

  String _bucketLabel(_StatusBucket b) {
    switch (b) {
      case _StatusBucket.all:
        return _isSwahili ? 'Zote' : 'All';
      case _StatusBucket.mpya:
        return _isSwahili ? 'Mpya' : 'New';
      case _StatusBucket.inaendelea:
        return _isSwahili ? 'Inaendelea' : 'Active';
      case _StatusBucket.imekamilika:
        return _isSwahili ? 'Imekamilika' : 'Done';
      case _StatusBucket.imeghairiwa:
        return _isSwahili ? 'Imeghairiwa' : 'Cancelled';
    }
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? _kPrimary : _kBorder),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        ),
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
    final orders = _filteredOrders;
    if (orders.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(orders[i]),
      ),
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
          _isSwahili ? 'Hakuna maagizo ya wateja bado.' : 'No customer orders yet.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          _isSwahili
              ? 'Mteja akiagiza chakula chako au bidhaa, itaonekana hapa.'
              : 'When a customer orders a meal or product, it will appear here.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
      ],
    );
  }

  Widget _orderCard(CustomerOrder o) {
    final selected = _selectedIds.contains('${o.source.apiValue}:${o.id}');
    final priorCount = _priorOrdersCache[o.buyerUserId] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: selected ? _kPrimary : _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _selectionMode
            ? () => _toggleSelection(o)
            : () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerOrderDetailPage(
                      userId: widget.userId,
                      source: o.source,
                      orderId: o.id,
                      role: 'partner',
                    ),
                  ),
                );
                _load();
              },
        onLongPress: !_selectionMode && _canBulk(o)
            ? () => _enterSelection(o)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectionMode && _canBulk(o))
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleSelection(o),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              _itemThumb(o),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.itemTitle,
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
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 12, color: _kSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            o.buyerName ?? '—',
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            o.source.labelSwahili,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        LeadExpiringChip(
                          minutesLeft: o.minutesLeft,
                          competitorCount: o.competitorCount,
                          isSwahili: _isSwahili,
                        ),
                        RepeatCustomerChip(
                          priorOrdersCount: priorCount,
                          isSwahili: _isSwahili,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'TZS ${_fmtMoney(o.totalPriceTzs)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'x${o.quantity}',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                        ),
                        const Spacer(),
                        Text(
                          _relativeTime(o.createdAt),
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600),
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

  bool _canBulk(CustomerOrder o) =>
      o.status == CustomerOrderStatus.pending &&
      (o.source == CustomerOrderSource.chefProduct ||
          o.source == CustomerOrderSource.chefListing ||
          o.source == CustomerOrderSource.partnerProduct);

  Widget _itemThumb(CustomerOrder o) {
    final url = o.resolvedItemPhoto;
    final fallbackIcon = o.skillCategory?.icon ?? Icons.restaurant_rounded;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        color: _kPrimary.withValues(alpha: 0.06),
        child: url.isEmpty
            ? Icon(fallbackIcon, size: 22, color: _kSecondary)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(fallbackIcon, size: 22, color: _kSecondary),
              ),
      ),
    );
  }

  Widget _statusChip(CustomerOrderStatus s) {
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

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return _isSwahili ? 'Sasa' : 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(dt);
  }

  String _fmtMoney(int v) => NumberFormat('#,##0', 'en_US').format(v);

  Widget _buildActionBar() {
    final count = _selectedIds.length;
    final acceptLabel = _isSwahili ? 'Kubali zote' : 'Accept all';
    final declineLabel = _isSwahili ? 'Kataa zote' : 'Decline all';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '$count ${_isSwahili ? 'zilizochaguliwa' : 'selected'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (_bulkProcessing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              TextButton(
                onPressed: count > 0 ? _batchDecline : null,
                child: Text(declineLabel),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: count > 0 ? _batchAccept : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(acceptLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
