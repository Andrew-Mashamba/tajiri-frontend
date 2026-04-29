// lib/suppliers/pages/supplier_catalog_item_page.dart
// Full-screen detail view for a supplier catalog item (product or service)
// with inline ordering for business owners.
import 'package:flutter/material.dart';

import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../services/message_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);

class SupplierCatalogItemPage extends StatefulWidget {
  final SupplierCatalogItem item;
  final Supplier supplier;
  final int businessId;
  final int currentUserId;
  final bool isOwner;

  const SupplierCatalogItemPage({
    super.key,
    required this.item,
    required this.supplier,
    required this.businessId,
    required this.currentUserId,
    this.isOwner = true,
  });

  @override
  State<SupplierCatalogItemPage> createState() =>
      _SupplierCatalogItemPageState();
}

class _SupplierCatalogItemPageState extends State<SupplierCatalogItemPage> {
  String? _token;
  int _qty = 1;
  bool _submitting = false;
  final PageController _imageCtrl = PageController();
  int _currentImage = 0;

  bool get _isService => widget.item.kind == SupplierCatalogItemKind.service;
  bool get _isSwahili {
    final s = AppStringsScope.of(context);
    return s?.isSwahili ?? false;
  }

  @override
  void initState() {
    super.initState();
    _qty = widget.item.defaultQuantity <= 0 ? 1 : widget.item.defaultQuantity;
    _loadToken();
  }

  @override
  void dispose() {
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final storage = await LocalStorageService.getInstance();
    if (mounted) setState(() => _token = storage.getAuthToken());
  }

  double get _unitPrice => widget.item.unitPrice;
  double get _lineTotal => _unitPrice * _qty;
  String get _currency =>
      (widget.item.currency ?? 'TZS').toUpperCase().trim().isEmpty
          ? 'TZS'
          : widget.item.currency!.toUpperCase().trim();

  bool get _canOrder {
    if (!widget.isOwner) return false;
    if (_unitPrice <= 0) return false;
    if (!_isService && widget.item.stockQuantity != null &&
        widget.item.stockQuantity! <= 0) {
      return false;
    }
    if (_isService && widget.item.availability == 'unavailable') return false;
    return true;
  }

  Future<void> _openChat() async {
    final ownerId = widget.supplier.ownerUserId;
    final messenger = ScaffoldMessenger.of(context);
    if (ownerId == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Muuzaji hana akaunti ya gumzo'
            : 'Supplier has no chat account'),
      ));
      return;
    }
    final result = await MessageService()
        .getPrivateConversation(widget.currentUserId, ownerId);
    if (!mounted) return;
    if (result.success && result.conversation != null) {
      Navigator.pushNamed(
        context,
        '/chat/${result.conversation!.id}',
        arguments: <String, dynamic>{'conversation': result.conversation},
      );
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Imeshindikana kufungua gumzo'
            : 'Could not open chat'),
      ));
    }
  }

  Future<void> _createOrder() async {
    if (_token == null || _submitting || !_canOrder) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final body = {
      'user_business_id': widget.businessId,
      'supplier_id': widget.supplier.id,
      'supplier_name': widget.supplier.name,
      'items': [
        {
          'description': widget.item.name,
          'quantity': _qty,
          'unit_price': _unitPrice,
          'total_price': _lineTotal,
        }
      ],
    };

    try {
      final res = await BusinessService.createPurchaseOrder(
          _token!, widget.businessId, body);
      if (!mounted) return;
      if (!res.success || res.data?.id == null) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(
          content: Text(res.message ??
              (_isSwahili ? 'Imeshindikana' : 'Failed to create order')),
          backgroundColor: Colors.red,
        ));
        return;
      }
      // The backend always creates POs in draft status; transition to "sent"
      // so the supplier sees it immediately.
      final sendRes =
          await BusinessService.markPOSent(_token!, res.data!.id!);
      if (!mounted) return;
      if (!sendRes.success) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Agizo limetengenezwa lakini halijatumwa. Jaribu tena kutoka kwenye orodha ya maagizo.'
              : 'Order created but could not be sent. Retry from the orders list.'),
          backgroundColor: Colors.red,
        ));
        navigator.pop(true);
        return;
      }
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Agizo limetumwa kwa muuzaji'
            : 'Order sent to supplier'),
      ));
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Imeshindikana. Jaribu tena.'
            : 'Failed. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _kCardBg,
        title: Text(
          _isService
              ? (_isSwahili ? 'Huduma' : 'Service')
              : (_isSwahili ? 'Bidhaa' : 'Product'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildImage(item),
                  _buildHeader(item),
                  const SizedBox(height: 8),
                  if (item.detail != null && item.detail!.trim().isNotEmpty)
                    _buildDescription(item.detail!.trim()),
                  _buildDetailsSection(item),
                  if (!_isService) _buildFulfillmentSection(item),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (widget.isOwner)
              _buildStickyBar()
            else
              _buildContactBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(SupplierCatalogItem item) {
    final fallbackIcon = _isService
        ? Icons.handyman_rounded
        : Icons.inventory_2_rounded;
    final title = item.name.trim();
    final semanticsLabel = title.isNotEmpty
        ? (_isService
            ? (_isSwahili ? 'Picha ya huduma: $title' : 'Service photo: $title')
            : (_isSwahili ? 'Picha ya bidhaa: $title' : 'Product photo: $title'))
        : (_isService
            ? (_isSwahili ? 'Picha ya huduma' : 'Service photo')
            : (_isSwahili ? 'Picha ya bidhaa' : 'Product photo'));
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: _kPrimary.withValues(alpha: 0.05),
              child: item.imageUrls.isNotEmpty
                  ? PageView.builder(
                      controller: _imageCtrl,
                      itemCount: item.imageUrls.length,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemBuilder: (_, i) => Image.network(
                        item.imageUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(fallbackIcon,
                              size: 72, color: _kSecondary),
                        ),
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kPrimary),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Icon(fallbackIcon, size: 72, color: _kSecondary),
                    ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isService
                    ? (_isSwahili ? 'HUDUMA' : 'SERVICE')
                    : (_isSwahili ? 'BIDHAA' : 'PRODUCT'),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          if (item.category != null && item.category!.isNotEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _kBorder),
                ),
                child: Text(
                  item.category!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          if (item.imageUrls.length > 1) ...[
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImage + 1}/${item.imageUrls.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(item.imageUrls.length, (i) {
                  final active = i == _currentImage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SupplierCatalogItem item) {
    final hasCompare =
        item.compareAtPrice != null && item.compareAtPrice! > _unitPrice;
    final discount = hasCompare
        ? (((item.compareAtPrice! - _unitPrice) / item.compareAtPrice!) * 100)
            .round()
        : 0;

    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name.trim().isNotEmpty
                ? item.name
                : (_isService
                    ? (_isSwahili ? 'Huduma' : 'Untitled service')
                    : (_isSwahili ? 'Bidhaa' : 'Untitled product')),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _unitPrice > 0
                      ? '$_currency ${_fmtMoney(_unitPrice)}'
                      : (_isSwahili ? 'Bei haijawekwa' : 'Price not set'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _unitPrice > 0 ? _kPrimary : _kSecondary,
                  ),
                ),
              ),
              if (hasCompare) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    _fmtMoney(item.compareAtPrice!),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-$discount%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_isService &&
              item.pricingType != null &&
              item.pricingType != 'fixed') ...[
            const SizedBox(height: 4),
            Text(
              _humanize(item.pricingType!),
              style: const TextStyle(
                fontSize: 12,
                color: _kSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildStatusChip(item),
        ],
      ),
    );
  }

  Widget _buildStatusChip(SupplierCatalogItem item) {
    if (_isService) {
      if (item.availability == 'unavailable') {
        return _statusPill(
          _isSwahili ? 'Haipatikani' : 'Unavailable',
          Colors.red.shade700,
        );
      }
      if (item.availability == 'available') {
        return _statusPill(
          _isSwahili ? 'Inapatikana' : 'Available',
          Colors.green.shade700,
        );
      }
      return const SizedBox.shrink();
    }
    final stock = item.stockQuantity;
    if (stock == null) return const SizedBox.shrink();
    if (stock <= 0) {
      return _statusPill(
        _isSwahili ? 'Imeisha' : 'Out of stock',
        Colors.red.shade700,
      );
    }
    if (stock <= 5) {
      return _statusPill(
        _isSwahili ? 'Baki $stock tu' : 'Only $stock left',
        Colors.orange.shade800,
      );
    }
    return _statusPill(
      _isSwahili ? 'Inapatikana' : 'In stock',
      Colors.green.shade700,
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSwahili ? 'Maelezo' : 'Description',
            style: const TextStyle(
              fontSize: 12,
              color: _kSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: _kPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(SupplierCatalogItem item) {
    final rows = <Widget>[];

    if (item.category != null && item.category!.isNotEmpty) {
      rows.add(_detailRow(
          _isSwahili ? 'Kategoria' : 'Category', item.category!));
    }
    if (!_isService && item.condition != null && item.condition!.isNotEmpty) {
      rows.add(_detailRow(_isSwahili ? 'Hali' : 'Condition',
          _humanize(item.condition!)));
    }
    if (!_isService && item.stockQuantity != null) {
      rows.add(_detailRow(
          _isSwahili ? 'Idadi iliyopo' : 'In stock', '${item.stockQuantity}'));
    }
    if (_isService && item.durationMinutes != null &&
        item.durationMinutes! > 0) {
      rows.add(_detailRow(_isSwahili ? 'Muda' : 'Duration',
          _fmtDuration(item.durationMinutes!)));
    }
    if (_isService && item.pricingType != null &&
        item.pricingType!.isNotEmpty) {
      rows.add(_detailRow(_isSwahili ? 'Aina ya bei' : 'Pricing',
          _humanize(item.pricingType!)));
    }
    if (item.locationName != null && item.locationName!.isNotEmpty) {
      rows.add(_detailRow(
          _isSwahili ? 'Mahali' : 'Location', item.locationName!));
    }
    rows.add(_detailRow(_isSwahili ? 'Muuzaji' : 'Supplier', widget.supplier.name));

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSwahili ? 'Maelezo Muhimu' : 'Details',
            style: const TextStyle(
              fontSize: 12,
              color: _kSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _kSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: _kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentSection(SupplierCatalogItem item) {
    final options = <Widget>[];

    if (item.allowPickup == true) {
      options.add(_fulfillmentRow(
        icon: Icons.storefront_rounded,
        title: _isSwahili ? 'Kuchukua dukani' : 'Pickup',
        subtitle: _isSwahili ? 'Bila malipo' : 'No charge',
      ));
    }
    if (item.allowDelivery == true) {
      final fee = item.deliveryFee;
      options.add(_fulfillmentRow(
        icon: Icons.delivery_dining_rounded,
        title: _isSwahili ? 'Utoaji wa ndani' : 'Local delivery',
        subtitle: fee != null && fee > 0
            ? '$_currency ${_fmtMoney(fee)}'
            : (_isSwahili ? 'Bila malipo' : 'No charge'),
      ));
    }
    if (item.allowShipping == true) {
      options.add(_fulfillmentRow(
        icon: Icons.local_shipping_rounded,
        title: _isSwahili ? 'Kutuma' : 'Shipping',
        subtitle: _isSwahili ? 'Gharama huongezwa' : 'Calculated at checkout',
      ));
    }

    if (options.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSwahili ? 'Jinsi ya Kupokea' : 'Fulfillment',
            style: const TextStyle(
              fontSize: 12,
              color: _kSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...options,
        ],
      ),
    );
  }

  Widget _fulfillmentRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBar() {
    final maxStock = _isService ? null : widget.item.stockQuantity;
    final canIncrement = maxStock == null || _qty < maxStock;

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Qty stepper.
          Container(
            decoration: BoxDecoration(
              color: _kBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepperBtn(
                  icon: Icons.remove_rounded,
                  enabled: _qty > 1,
                  onTap: () => setState(() => _qty = (_qty - 1).clamp(1, 9999)),
                ),
                SizedBox(
                  width: 40,
                  height: 48,
                  child: Center(
                    child: Text(
                      '$_qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ),
                _stepperBtn(
                  icon: Icons.add_rounded,
                  enabled: canIncrement,
                  onTap: () => setState(() => _qty += 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // CTA.
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed:
                    (_submitting || !_canOrder || _token == null) ? null : _createOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  disabledBackgroundColor: _kSecondary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _canOrder
                                  ? (_isSwahili ? 'Agiza' : 'Order')
                                  : (_isSwahili
                                      ? 'Haipatikani'
                                      : 'Unavailable'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (_canOrder) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 14,
                                color:
                                    Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_currency ${_fmtMoney(_lineTotal)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactBar() {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: _openChat,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(
            _isSwahili ? 'Wasiliana na Muuzaji' : 'Contact Supplier',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  Widget _stepperBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _kPrimary : _kSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  String _humanize(String raw) {
    if (raw.isEmpty) return raw;
    final words = raw.replaceAll('_', ' ').split(' ');
    return words
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _fmtDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _fmtMoney(double v) {
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m.group(1)},',
    );
    return parts.length == 1 ? whole : '$whole.${parts[1]}';
  }
}
