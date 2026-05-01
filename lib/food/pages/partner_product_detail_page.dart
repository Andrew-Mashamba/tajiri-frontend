import 'package:flutter/material.dart';

import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/pages/customer_order_detail_page.dart';
import '../../customer_orders/services/customer_orders_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/pages/partner_profile_page.dart';
import '../../tajirika/services/partner_product_service.dart';
import '../../tajirika/widgets/jss_badge.dart';
import '../../tajirika/widgets/partner_product_booking_sheet.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kMuted = Color(0xFFBDBDBD);
const Color _kWarn = Color(0xFFFFB300);
const Color _kError = Color(0xFFE53935);

/// Customer-facing detail page for a partner_product. Mounted from each
/// vertical's home page (food/mafundi/events/etc.) — pass [cluster] so
/// header/CTA/snackbar copy reads "huduma" vs "bidhaa" per spec §2 / line 951.
class PartnerProductDetailPage extends StatefulWidget {
  final int productId;
  final PartnerProduct? initial;

  /// One of: 'food' (default), 'mafundi', 'events', 'skincare',
  /// 'hair_nails', 'fitness', 'housing'. Drives a few copy strings that
  /// differ by cluster — header title, sticky-bar CTA label, accept snackbar.
  final String cluster;

  const PartnerProductDetailPage({
    super.key,
    required this.productId,
    this.initial,
    this.cluster = 'food',
  });

  @override
  State<PartnerProductDetailPage> createState() =>
      _PartnerProductDetailPageState();
}

class _PartnerProductDetailPageState extends State<PartnerProductDetailPage> {
  PartnerProduct? _product;
  bool _loading = true;
  String? _error;
  int? _userId;
  int _photoIndex = 0;
  String? _defaultDeliveryAddress;

  /// Set after a successful placement on this page so the sticky bar can
  /// switch from CTA → status pill (spec §2.7).
  int? _currentOrderId;
  CustomerOrderStatus? _currentOrderStatus;
  bool _cancelling = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? true;

  bool get _isServiceCluster {
    switch (widget.cluster) {
      case 'mafundi':
      case 'skincare':
      case 'hair_nails':
      case 'fitness':
      case 'housing':
      case 'events':
        return true;
      default:
        return false;
    }
  }

  String get _headerTitle {
    final sw = _isSwahili;
    if (_isServiceCluster) return sw ? 'Huduma ya kuagiza' : 'Service to book';
    return sw ? 'Bidhaa ya kuagiza' : 'Product to order';
  }

  String _ctaLabel(int priceTzs) {
    final sw = _isSwahili;
    if (_isServiceCluster) {
      return sw ? 'Omba huduma — ${_fmtTzs(priceTzs)}' : 'Request — ${_fmtTzs(priceTzs)}';
    }
    return sw ? 'Agiza sasa — ${_fmtTzs(priceTzs)}' : 'Order now — ${_fmtTzs(priceTzs)}';
  }

  String _placedSnackbar(String partnerName) {
    final sw = _isSwahili;
    if (_isServiceCluster) {
      return sw
          ? 'Ombi limefika kwa $partnerName. Utajulishwa atakapokubali.'
          : "Request received by $partnerName. You'll be notified on accept.";
    }
    return sw
        ? 'Oda imefika kwa $partnerName. Utajulishwa atakapokubali.'
        : "Order received by $partnerName. You'll be notified on accept.";
  }

  @override
  void initState() {
    super.initState();
    _product = widget.initial;
    _loading = widget.initial == null;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    _userId = user?.userId;
    final addr = user?.location?.displayAddress;
    if (addr != null && addr.isNotEmpty) _defaultDeliveryAddress = addr;
    await _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = _product == null;
      _error = null;
    });
    final res = await PartnerProductService.getProduct(widget.productId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.product != null) {
        _product = res.product;
      } else if (_product == null) {
        _error = res.message ?? 'Imeshindikana kupakua bidhaa';
      }
    });
  }

  String _fmtTzs(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TSh ${buf.toString()}';
  }

  String _modeLabel(String mode) {
    final sw = _isSwahili;
    switch (mode) {
      case 'pickup_only':
        return sw ? 'Nichukue tu' : 'Pickup only';
      case 'delivery_only':
        return sw ? 'Niletewe tu' : 'Delivery only';
      case 'both':
        return sw ? 'Nichukue au niletewe' : 'Pickup or delivery';
      case 'digital_only':
        return sw ? 'Kidijitali' : 'Digital';
      default:
        return mode;
    }
  }

  String _leadTimeLabel(int hours) {
    final sw = _isSwahili;
    if (hours < 24) return sw ? 'Saa $hours' : '${hours}h';
    final days = (hours / 24).round();
    return sw ? 'Siku $days' : '${days}d';
  }

  Future<void> _openBookingSheet() async {
    final p = _product;
    if (p == null) return;
    final sw = _isSwahili;
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sw ? 'Tafadhali ingia kwanza' : 'Please sign in first'),
        ),
      );
      return;
    }
    if (_userId == p.partnerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sw
              ? (_isServiceCluster
                  ? 'Huwezi kuomba huduma yako mwenyewe'
                  : 'Huwezi kuagiza bidhaa yako mwenyewe')
              : (_isServiceCluster
                  ? "You can't book your own service"
                  : "You can't order your own product")),
        ),
      );
      return;
    }
    final orderId = await showPartnerProductBookingSheet(
      context: context,
      product: p,
      buyerUserId: _userId!,
      confirmCtaSwahili: sw ? 'Agiza sasa' : 'Order now',
      defaultDeliveryAddress: _defaultDeliveryAddress,
    );
    if (!mounted || orderId == null) return;
    setState(() {
      _currentOrderId = orderId;
      _currentOrderStatus = CustomerOrderStatus.pending;
    });
    final partnerName = p.partnerName ?? (sw ? 'mshirika' : 'partner');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_placedSnackbar(partnerName)),
        backgroundColor: _kAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openCurrentOrderDetail() async {
    final orderId = _currentOrderId;
    final userId = _userId;
    if (orderId == null || userId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerOrderDetailPage(
          userId: userId,
          source: CustomerOrderSource.partnerProduct,
          orderId: orderId,
          role: 'customer',
        ),
      ),
    );
    if (!mounted) return;
    // Refresh status from server in case it changed in detail.
    final res = await CustomerOrdersService.get(
      userId: userId,
      source: CustomerOrderSource.partnerProduct,
      id: orderId,
    );
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() => _currentOrderStatus = res.data!.status);
    }
  }

  Future<void> _cancelCurrentOrder() async {
    final orderId = _currentOrderId;
    final userId = _userId;
    if (orderId == null || userId == null) return;
    final sw = _isSwahili;
    final reason = await _promptCancelReason();
    if (reason == null || !mounted) return;
    setState(() => _cancelling = true);
    final res = await CustomerOrdersService.action(
      userId: userId,
      source: CustomerOrderSource.partnerProduct,
      id: orderId,
      action: 'cancel',
      reason: reason.isEmpty ? null : reason,
    );
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (res.success) {
      setState(() {
        _currentOrderStatus = CustomerOrderStatus.cancelled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sw ? 'Oda imeghairiwa' : 'Order cancelled'),
          backgroundColor: _kAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ??
              (sw ? 'Imeshindikana kughairi' : 'Cancellation failed')),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _promptCancelReason() async {
    final sw = _isSwahili;
    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ghairi oda?' : 'Cancel order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sw
                  ? 'Sababu (hiari)'
                  : 'Reason (optional)',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: sw
                    ? 'Mfano: Nimebadilisha mawazo'
                    : 'e.g. Changed my mind',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(sw ? 'Hapana' : 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kError,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(sw ? 'Ghairi' : 'Cancel'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _error != null && p == null
                ? _errorState(_error!)
                : p == null
                    ? Center(
                        child: Text(_isSwahili
                            ? (_isServiceCluster
                                ? 'Huduma haijapatikana'
                                : 'Bidhaa haijapatikana')
                            : (_isServiceCluster
                                ? 'Service not found'
                                : 'Product not found')),
                      )
                    : _buildBody(p),
      ),
      bottomNavigationBar: p == null ? null : _buildStickyBar(p),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: _kBorder),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _refresh,
              child: Text(_isSwahili ? 'Jaribu tena' : 'Try again',
                  style: const TextStyle(color: _kPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PartnerProduct p) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _kPrimary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          _buildPhotoCarousel(p),
          if (!p.isActive) _buildInactiveBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(p.skillCategory?.icon ?? Icons.work_rounded,
                    size: 16, color: _kSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.skillCategory?.labelSwahili ?? p.skillCategoryRaw,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary),
                  ),
                ),
                if (p.kind != PartnerProductKind.standard) _kindChip(p.kind),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              p.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _priceBlock(p),
          ),
          if (p.isLegalPack) _legalPackBlock(p),
          _partnerCard(p),
          if (p.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                p.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  height: 1.4,
                ),
              ),
            ),
          if (p.tags.isNotEmpty) _tagRow(p.tags),
          if (p.dietaryTags.isNotEmpty) _tagRow(p.dietaryTags, accent: true),
          _buildLeadModeStrip(p),
          if (p.variants.isNotEmpty) _variantPreview(p),
          _buildEditNote(),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Widget _buildEditNote() {
    final sw = _isSwahili;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: _kSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              sw
                  ? 'Kuhariri, ghairi na uweke mpya'
                  : 'To edit, cancel and re-order',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: _kPrimary, size: 22),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              _headerTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(PartnerProduct p) {
    final photos = p.photos;
    if (photos.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          color: _kBorder,
          child: const Icon(Icons.image_rounded, size: 48, color: _kMuted),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _photoIndex = i),
            itemBuilder: (_, i) {
              final url = photos[i].resolvedPhotoUrl;
              return url.isEmpty
                  ? Container(
                      color: _kBorder,
                      child: const Icon(Icons.broken_image_rounded,
                          size: 36, color: _kMuted),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: _kBorder,
                        child: const Icon(Icons.broken_image_rounded,
                            size: 36, color: _kMuted),
                      ),
                    );
            },
          ),
          if (photos.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (i) => Container(
                    width: i == _photoIndex ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _photoIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInactiveBanner() {
    final sw = _isSwahili;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: _kWarn.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _kWarn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sw
                  ? 'Hii bidhaa haipatikani sasa'
                  : 'Currently unavailable',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceBlock(PartnerProduct p) {
    final sw = _isSwahili;
    final discountPct = p.lastMinuteDiscountPct;
    final hasDiscount = discountPct != null && discountPct > 0 && discountPct < 100;
    final effective = hasDiscount
        ? (p.basePriceTzs * (100 - discountPct) ~/ 100)
        : p.basePriceTzs;
    final anchor = p.aiCostAnchorTzs;
    final showAnchor = anchor != null && anchor > 0 &&
        (anchor - p.basePriceTzs).abs() * 100 ~/ (anchor == 0 ? 1 : anchor) >= 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _fmtTzs(effective),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kAccent,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 8),
              Text(
                _fmtTzs(p.basePriceTzs),
                style: const TextStyle(
                  fontSize: 13,
                  color: _kSecondary,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _kError.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sw ? '-$discountPct% dakika za mwisho' : '-$discountPct% last-min',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _kError,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (showAnchor) ...[
          const SizedBox(height: 4),
          Text(
            sw
                ? 'Bei ya kawaida (AI): ${_fmtTzs(anchor)}'
                : 'Typical price (AI): ${_fmtTzs(anchor)}',
            style: const TextStyle(
              fontSize: 11,
              color: _kSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _legalPackBlock(PartnerProduct p) {
    final sw = _isSwahili;
    if (p.legalPackDeliverables.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            sw ? 'Pakiti ya kisheria' : 'Legal pack',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel_rounded,
                    size: 14, color: Color(0xFF1B5E20)),
                const SizedBox(width: 6),
                Text(
                  sw ? 'Pakiti ya kisheria — inajumuisha:' : 'Legal pack — includes:',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...p.legalPackDeliverables.map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 12, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindChip(PartnerProductKind kind) {
    Color bg;
    String label;
    switch (kind) {
      case PartnerProductKind.amc:
        bg = const Color(0xFFFFF8E1);
        label = 'AMC';
        break;
      case PartnerProductKind.productized:
        bg = const Color(0xFFE3F2FD);
        label = 'SKU';
        break;
      case PartnerProductKind.standard:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }

  Widget _partnerCard(PartnerProduct p) {
    final sw = _isSwahili;
    final rating = p.partnerRating;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PartnerProfilePage(partnerId: p.partnerId),
          ),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _kBorder,
              backgroundImage: p.resolvedPartnerPhoto.isEmpty
                  ? null
                  : NetworkImage(p.resolvedPartnerPhoto),
              child: p.resolvedPartnerPhoto.isEmpty
                  ? const Icon(Icons.person_rounded,
                      size: 22, color: _kMuted)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.partnerName ?? (sw ? 'Mshirika' : 'Partner'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.partnerJobSuccessScore != null) ...[
                        const SizedBox(width: 6),
                        JssBadge(
                          score: p.partnerJobSuccessScore,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (rating != null && rating > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 12, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: _kSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        sw ? 'Tazama wasifu' : 'View partner',
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _kSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _tagRow(List<String> tags, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags
            .map(
              (t) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent
                      ? _kAccent.withValues(alpha: 0.10)
                      : _kBorder.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#$t',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accent ? _kAccent : _kSecondary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLeadModeStrip(PartnerProduct p) {
    final sw = _isSwahili;
    final leadPart = sw
        ? 'Itakuwa tayari ndani ya ${_leadTimeLabel(p.leadTimeHours)}'
        : 'Ready in ${_leadTimeLabel(p.leadTimeHours)}';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: _kSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$leadPart • ${_modeLabel(p.mode)}',
              style: const TextStyle(fontSize: 12, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantPreview(PartnerProduct p) {
    final sw = _isSwahili;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Aina zinazopatikana' : 'Available variants',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ...p.variants.map(
            (v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 4, color: _kSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      v.labelSwahili ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: _kPrimary),
                    ),
                  ),
                  Text(
                    _fmtTzs(v.priceTzs),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBar(PartnerProduct p) {
    if (_currentOrderId != null) {
      return SafeArea(top: false, child: _buildStatusPillBar(p));
    }
    final sw = _isSwahili;
    final disabled =
        !p.isActive || _userId == null || _userId == p.partnerUserId;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: const BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : _openBookingSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size.fromHeight(48),
            disabledBackgroundColor: _kMuted,
          ),
          child: Text(
            disabled
                ? (p.isActive
                    ? (sw ? 'Sijaingia' : 'Sign in')
                    : (sw ? 'Haipatikani' : 'Unavailable'))
                : _ctaLabel(p.basePriceTzs),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPillBar(PartnerProduct p) {
    final sw = _isSwahili;
    final status = _currentOrderStatus ?? CustomerOrderStatus.pending;
    final partnerName = p.partnerName ?? (sw ? 'mshirika' : 'partner');
    final canCancel = status == CustomerOrderStatus.pending ||
        status == CustomerOrderStatus.accepted;
    final pillLabel = switch (status) {
      CustomerOrderStatus.pending => sw
          ? 'Iko kwa $partnerName'
          : 'With $partnerName',
      CustomerOrderStatus.accepted => sw
          ? '$partnerName amekubali'
          : '$partnerName accepted',
      CustomerOrderStatus.preparing => sw
          ? '$partnerName anaandaa'
          : '$partnerName is preparing',
      CustomerOrderStatus.ready => sw ? 'Tayari' : 'Ready',
      CustomerOrderStatus.outForDelivery => sw ? 'Njiani' : 'On the way',
      CustomerOrderStatus.completed => sw ? 'Imekamilika' : 'Completed',
      CustomerOrderStatus.cancelled => sw ? 'Imeghairiwa' : 'Cancelled',
      CustomerOrderStatus.rejected => sw ? 'Imekataliwa' : 'Rejected',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _openCurrentOrderDetail,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pillLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          if (canCancel) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _cancelling ? null : _cancelCurrentOrder,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kError,
                side: const BorderSide(color: _kError),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _cancelling
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_kError),
                      ),
                    )
                  : Text(
                      sw ? 'Ghairi' : 'Cancel',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
