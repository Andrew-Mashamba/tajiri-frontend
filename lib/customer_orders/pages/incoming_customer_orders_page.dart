// lib/customer_orders/pages/incoming_customer_orders_page.dart
// Inbox for consumer orders.
// - role='partner' (default): partner-facing — orders received as a seller
// - role='customer': buyer-facing — orders the user has placed
// Unifies orders coming from /lib/food/, /lib/tajirika/ partner products, and
// chef listings via the /customer-orders backend (UNION of 9 sources).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../appointments/pages/appointment_status_page.dart';
import '../../business/pages/engagement_proposal_review_page.dart';
import '../../business/pages/engagement_workspace_page.dart';
import '../../consultations/pages/consultation_status_page.dart';
import '../../engagements/pages/engagement_workspace_page.dart' as eng_shared;
import '../../l10n/app_strings_scope.dart';
import '../../tajirika/pages/event_booking_detail_page.dart';
import '../../tajirika/pages/property_inquiry_detail_page.dart';
import '../../mafundi/pages/service_request_status_page.dart';
import '../../service_garage/pages/garage_status_page.dart';
import '../../services/local_storage_service.dart';
import '../../tajirika/pages/appointment_detail_page.dart';
import '../../tajirika/pages/consultation_detail_page.dart';
import '../../tajirika/pages/garage_booking_detail_page.dart';
import '../../tajirika/models/tajirika_models.dart' show SkillCategory;
import '../../tajirika/pages/post_partner_product_page.dart';
import '../../tajirika/pages/service_request_detail_page.dart';
import '../models/customer_order.dart';
import '../services/customer_orders_service.dart';
import 'customer_order_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec §3 line 323: status chips collapse 8 raw statuses into 4 buckets.
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

class IncomingCustomerOrdersPage extends StatefulWidget {
  final int userId;

  /// 'partner' (default) lists orders received as a seller.
  /// 'customer' lists orders the user has placed (buyer view).
  final String role;

  const IncomingCustomerOrdersPage({
    super.key,
    required this.userId,
    this.role = 'partner',
  });

  @override
  State<IncomingCustomerOrdersPage> createState() =>
      _IncomingCustomerOrdersPageState();
}

class _IncomingCustomerOrdersPageState
    extends State<IncomingCustomerOrdersPage> {
  bool _loading = true;
  String? _error;
  List<CustomerOrder> _orders = [];

  _StatusBucket _selectedBucket = _StatusBucket.all;

  /// null = all sources.
  CustomerOrderSource? _selectedSource;

  /// null = all skills. Spec line 321 — F13 multi-skill hub gives the partner
  /// a way to scope incoming orders to a single persona at a time.
  SkillCategory? _selectedSkill;

  bool _searchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isCustomer => widget.role == 'customer';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    // Bucket + source filtering happens client-side so a single fetch covers
    // all chips. Backend status filter is omitted intentionally.
    final res = await CustomerOrdersService.list(
      userId: widget.userId,
      role: widget.role,
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _orders = res.items;
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
            _buildSourceChips(),
            _buildSkillChips(),
            _buildBucketChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = _isCustomer
        ? (_isSwahili ? 'Oda zangu' : 'My orders')
        : (_isSwahili ? 'Maagizo ya wateja' : 'Customer orders');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                size: 22, color: _kPrimary),
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
            onPressed: _load,
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
          hintText: _isCustomer
              ? (_isSwahili
                  ? 'Tafuta mshirika au bidhaa...'
                  : 'Search partner or item...')
              : (_isSwahili
                  ? 'Tafuta mnunuzi au bidhaa...'
                  : 'Search buyer or item...'),
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
        onChanged: (v) =>
            setState(() => _searchQuery = v.trim().toLowerCase()),
      ),
    );
  }

  Widget _buildReportsStrip() {
    // Reports strip is partner-centric (today's pipeline). Hide for buyers.
    if (_isCustomer) return const SizedBox.shrink();
    if (_orders.isEmpty) return const SizedBox.shrink();
    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;
    int countToday(CustomerOrderStatus s) =>
        _orders.where((o) => o.status == s && isToday(o.createdAt)).length;
    final pending = countToday(CustomerOrderStatus.pending);
    final accepted = countToday(CustomerOrderStatus.accepted);
    final ready = countToday(CustomerOrderStatus.ready);
    final completed = countToday(CustomerOrderStatus.completed);
    final pipelineTotal = _orders
        .where((o) => !o.status.isTerminal)
        .fold<int>(0, (sum, o) => sum + o.totalPriceTzs);

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
                _metric(pending, _isSwahili ? 'Mapya' : 'New'),
                _metric(accepted, _isSwahili ? 'Yamekubaliwa' : 'Accepted'),
                _metric(ready, _isSwahili ? 'Tayari' : 'Ready'),
                _metric(completed, _isSwahili ? 'Yamekamilika' : 'Done'),
              ],
            ),
            if (pipelineTotal > 0) ...[
              const SizedBox(height: 6),
              const Divider(height: 1, color: _kBorder),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _isSwahili ? 'Yanaendelea: ' : 'Pipeline: ',
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

  /// Spec §3 line 321: source filter row. Renders "All" + every source value
  /// the model knows about, so newly added sources (F4 mafundi, F6 hair_nails,
  /// etc.) light up here automatically once they're parsed in customer_order.dart.
  Widget _buildSourceChips() {
    final all = _isSwahili ? 'Zote' : 'All';
    final entries = <(CustomerOrderSource?, String)>[
      (null, all),
      ...CustomerOrderSource.values.map(
        (s) => (s, _sourceLabel(s)),
      ),
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

  /// Spec §3 line 321: skill filter chip row. Hidden when fewer than 2 skills
  /// appear in the inbox (no value to scope to a single persona).
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

  /// Sorted unique skills present in the loaded orders.
  List<SkillCategory> get _visibleSkills {
    final set = <SkillCategory>{};
    for (final o in _orders) {
      final s = o.skillCategory;
      if (s != null) set.add(s);
    }
    final list = set.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  /// Spec §3 line 323: 4 status buckets — Mpya / Inaendelea / Imekamilika /
  /// Imeghairiwa — replacing one-chip-per-raw-status.
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  List<CustomerOrder> get _filteredOrders {
    final q = _searchQuery;
    return _orders.where((o) {
      if (!_selectedBucket.matches(o.status)) return false;
      if (_selectedSource != null && o.source != _selectedSource) return false;
      if (_selectedSkill != null && o.skillCategory != _selectedSkill) return false;
      if (q.isEmpty) return true;
      final counterparty = _isCustomer
          ? (o.partnerName ?? '').toLowerCase()
          : (o.buyerName ?? '').toLowerCase();
      if (counterparty.contains(q)) return true;
      if (o.itemTitle.toLowerCase().contains(q)) return true;
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
          _isCustomer
              ? (_isSwahili ? 'Hujaagiza bidhaa bado.' : 'No orders yet.')
              : (_isSwahili
                  ? 'Hakuna maagizo ya wateja bado.'
                  : 'No customer orders yet.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          _isCustomer
              ? (_isSwahili
                  ? 'Ukiagiza bidhaa kutoka kwa mshirika, itaonekana hapa.'
                  : 'When you order from a partner, it will appear here.')
              : (_isSwahili
                  ? 'Mteja akiagiza chakula chako au bidhaa, itaonekana hapa.'
                  : 'When a customer orders a meal or product, it will appear here.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
        if (!_isCustomer) ...[
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_business_rounded, size: 18),
              label: Text(
                _isSwahili ? 'Tangaza bidhaa' : 'Post a product',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PostPartnerProductPage(userId: widget.userId),
                  ),
                );
                if (mounted) _load();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _orderCard(CustomerOrder o) {
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
          if (o.source == CustomerOrderSource.serviceRequest) {
            // Service requests use dedicated pages (richer UI: photos, quotes, ETA).
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) {
                  if (widget.role == 'partner') {
                    return ServiceRequestDetailPage(
                      userId: widget.userId,
                      requestId: o.id,
                    );
                  }
                  return ServiceRequestStatusPage(
                    userId: widget.userId,
                    requestId: o.id,
                  );
                },
              ),
            );
          } else if (o.source == CustomerOrderSource.garageBooking) {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) {
                  if (widget.role == 'partner') {
                    return GarageBookingDetailPage(
                      userId: widget.userId,
                      bookingId: o.sourceRefId,
                    );
                  }
                  return GarageStatusPage(
                    userId: widget.userId,
                    bookingId: o.sourceRefId,
                  );
                },
              ),
            );
          } else if (o.source == CustomerOrderSource.appointment) {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) {
                  if (widget.role == 'partner') {
                    return AppointmentDetailPage(
                      userId: widget.userId,
                      appointmentId: o.sourceRefId,
                    );
                  }
                  return AppointmentStatusPage(
                    userId: widget.userId,
                    appointmentId: o.sourceRefId,
                  );
                },
              ),
            );
          } else if (o.source == CustomerOrderSource.consultation) {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) {
                  if (widget.role == 'partner') {
                    return ConsultationDetailPage(
                      userId: widget.userId,
                      consultationId: o.sourceRefId,
                    );
                  }
                  return ConsultationStatusPage(
                    userId: widget.userId,
                    consultationId: o.sourceRefId,
                  );
                },
              ),
            );
          } else if (o.source == CustomerOrderSource.listingInquiry) {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PropertyInquiryDetailPage(
                  userId: widget.userId,
                  inquiryId: o.sourceRefId,
                  role: widget.role,
                ),
              ),
            );
          } else if (o.source == CustomerOrderSource.eventBooking) {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => EventBookingDetailPage(
                  userId: widget.userId,
                  bookingId: o.sourceRefId,
                  role: widget.role,
                ),
              ),
            );
          } else if (o.source == CustomerOrderSource.engagement) {
            // Status='pending' (i.e. engagement.status='proposed') → customer
            // sees the review page; partner sees the workspace (read-only).
            // Once accepted/active/etc, both sides land on the workspace.
            final isProposed = o.status == CustomerOrderStatus.pending;
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) {
                  if (isProposed && widget.role == 'customer') {
                    return EngagementProposalReviewPage(
                      userId: widget.userId,
                      engagementId: o.sourceRefId,
                    );
                  }
                  if (widget.role == 'partner') {
                    return eng_shared.EngagementWorkspacePage(
                      userId: widget.userId,
                      engagementId: o.sourceRefId,
                      role: 'partner',
                    );
                  }
                  return EngagementWorkspacePage(
                    userId: widget.userId,
                    engagementId: o.sourceRefId,
                  );
                },
              ),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CustomerOrderDetailPage(
                  userId: widget.userId,
                  source: o.source,
                  orderId: o.id,
                  role: widget.role,
                ),
              ),
            );
          }
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Icon(
                          _isCustomer
                              ? Icons.storefront_outlined
                              : Icons.person_outline,
                          size: 12,
                          color: _kSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (_isCustomer ? o.partnerName : o.buyerName) ?? '—',
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
                        Icon(
                          o.isDelivery
                              ? Icons.delivery_dining_rounded
                              : Icons.storefront_outlined,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
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
                errorBuilder: (_, __, ___) =>
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
}
