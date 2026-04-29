// lib/food/pages/chef_product_detail_page.dart
// Buyer-facing detail view for a chef product (e.g. cake-to-order).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../screens/feed/create_image_post_screen.dart';
import '../models/chef_product.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);

class ChefProductDetailPage extends StatefulWidget {
  final int productId;
  final int userId;

  const ChefProductDetailPage({
    super.key,
    required this.productId,
    required this.userId,
  });

  @override
  State<ChefProductDetailPage> createState() => _ChefProductDetailPageState();
}

class _ChefProductDetailPageState extends State<ChefProductDetailPage> {
  final FoodService _service = FoodService();
  bool _loading = true;
  String? _error;
  ChefProduct? _product;
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _service.getChefProduct(widget.productId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _product = res.data;
        _error = null;
      } else {
        _error = res.message ?? 'Failed to load';
      }
    });
  }

  bool get _isOwner =>
      _product?.partnerUserId != null &&
      _product!.partnerUserId == widget.userId;

  Future<void> _openOrderSheet() async {
    if (_product == null) return;
    final placed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _OrderSheet(
        product: _product!,
        userId: widget.userId,
        service: _service,
      ),
    );
    if (placed == true && mounted) {
      _toast('Agizo limewasilishwa');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _shareAsPost() async {
    final p = _product;
    if (p == null) return;
    final price = NumberFormat('#,##0', 'en_US').format(p.basePriceTzs);
    final lines = <String>[
      p.title,
      'TZS $price • ${p.mode.labelSwahili} • Saa ${p.leadTimeHours} kuandaa',
      if ((p.description ?? '').trim().isNotEmpty) p.description!.trim(),
      '',
      'Agiza moja kwa moja kupitia TAJIRI:',
      'tajiri://food/product/${p.id}',
    ];
    final imageUrls = <String>[
      if (p.resolvedCover.isNotEmpty) p.resolvedCover,
      ...p.resolvedPhotos.where((u) => u != p.resolvedCover),
    ];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateImagePostScreen(
          currentUserId: widget.userId,
          initialContent: lines.join('\n'),
          initialImageUrls: imageUrls,
        ),
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
            if (_product != null && !_isOwner) _buildOrderBar(),
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
          const Expanded(
            child: Text(
              'Bidhaa',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded,
                size: 20, color: _kPrimary),
            onPressed: _product == null ? null : _shareAsPost,
          ),
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
    final p = _product!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          _photoCarousel(p),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary)),
                const SizedBox(height: 4),
                Text('TZS ${_fmt(p.basePriceTzs)}',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kAccent)),
                const SizedBox(height: 8),
                _quickRow(p),
                if ((p.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(p.description!,
                      style: const TextStyle(
                          fontSize: 13, color: _kPrimary, height: 1.4)),
                ],
                if (p.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kPrimary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(t,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                _partnerCard(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoCarousel(ChefProduct p) {
    final photos = p.resolvedPhotos;
    if (photos.isEmpty) {
      return Container(
        height: 240,
        color: _kPrimary.withValues(alpha: 0.06),
        child: const Icon(Icons.cake_rounded, size: 64, color: _kSecondary),
      );
    }
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _carouselIndex = i),
            itemBuilder: (_, i) => Image.network(
              photos[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _kPrimary.withValues(alpha: 0.06),
                child: const Icon(Icons.broken_image_rounded,
                    size: 48, color: _kSecondary),
              ),
            ),
          ),
          if (photos.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _carouselIndex ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _carouselIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
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

  Widget _quickRow(ChefProduct p) {
    return Row(
      children: [
        _chip(Icons.schedule_rounded,
            'Saa ${p.leadTimeHours} kuandaa'),
        const SizedBox(width: 8),
        _chip(
          p.mode == ChefProductMode.pickupOnly
              ? Icons.storefront_outlined
              : p.mode == ChefProductMode.deliveryOnly
                  ? Icons.delivery_dining_rounded
                  : Icons.local_shipping_outlined,
          p.mode.labelSwahili,
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kPrimary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
        ],
      ),
    );
  }

  Widget _partnerCard(ChefProduct p) {
    final photo = p.resolvedPartnerPhoto;
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
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? Text(
                    (p.partnerName ?? '?').isNotEmpty
                        ? (p.partnerName ?? '?')[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.partnerName ?? 'Mpishi',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
                if ((p.partnerDistrict ?? p.partnerRegion ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [p.partnerDistrict, p.partnerRegion]
                          .where((e) => (e ?? '').isNotEmpty)
                          .join(', '),
                      style: const TextStyle(
                          fontSize: 11, color: _kSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _product!.isActive ? _openOrderSheet : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            _product!.isActive
                ? 'Agiza sasa — TZS ${_fmt(_product!.basePriceTzs)}'
                : 'Haipatikani kwa sasa',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  String _fmt(int v) => NumberFormat('#,##0', 'en_US').format(v);
}

class _OrderSheet extends StatefulWidget {
  final ChefProduct product;
  final int userId;
  final FoodService service;
  const _OrderSheet({
    required this.product,
    required this.userId,
    required this.service,
  });

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  late int _quantity;
  late String _deliveryMode; // 'pickup' or 'delivery'
  DateTime? _requestedFor;
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minQuantity;
    _deliveryMode =
        widget.product.mode == ChefProductMode.pickupOnly ? 'pickup' : 'delivery';
    _requestedFor =
        DateTime.now().add(Duration(hours: widget.product.leadTimeHours + 1));
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final earliest = DateTime.now()
        .add(Duration(hours: widget.product.leadTimeHours));
    final initial = _requestedFor ?? earliest;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(earliest) ? earliest : initial,
      firstDate: earliest,
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isBefore(earliest)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Inahitaji muda wa kuandaa wa angalau saa ${widget.product.leadTimeHours}'),
      ));
      return;
    }
    setState(() => _requestedFor = picked);
  }

  Future<void> _submit() async {
    if (_requestedFor == null) return;
    if (_deliveryMode == 'delivery' && _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Andika anwani ya kuletewa')),
      );
      return;
    }
    setState(() => _submitting = true);
    final res = await widget.service.orderChefProduct(
      productId: widget.product.id,
      userId: widget.userId,
      quantity: _quantity,
      deliveryMode: _deliveryMode,
      deliveryAddress: _deliveryMode == 'delivery'
          ? _addressCtrl.text.trim()
          : null,
      requestedFor: _requestedFor!,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Imeshindikana')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final canPickup = p.mode != ChefProductMode.deliveryOnly;
    final canDeliver = p.mode != ChefProductMode.pickupOnly;
    final total = p.basePriceTzs * _quantity;

    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Agiza bidhaa',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary)),
          const SizedBox(height: 12),
          _row('Idadi'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded,
                    color: _kPrimary),
                onPressed: _quantity > p.minQuantity
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Text('$_quantity',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: _kPrimary),
                onPressed: () => setState(() => _quantity++),
              ),
              const Spacer(),
              Text('TZS ${NumberFormat('#,##0', 'en_US').format(total)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kAccent)),
            ],
          ),
          if (canPickup && canDeliver) ...[
            const SizedBox(height: 8),
            _row('Njia'),
            const SizedBox(height: 4),
            Row(
              children: [
                _modeChip('pickup', Icons.storefront_outlined, 'Kuchukua'),
                const SizedBox(width: 8),
                _modeChip(
                    'delivery', Icons.delivery_dining_rounded, 'Kuletewa'),
              ],
            ),
          ],
          if (_deliveryMode == 'delivery') ...[
            const SizedBox(height: 12),
            _row('Anwani'),
            TextField(
              controller: _addressCtrl,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Mtaa, eneo, sehemu maalum...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kPrimary),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _row('Inatakiwa lini'),
          GestureDetector(
            onTap: _pickWhen,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: _kCardBg,
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: _kSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _requestedFor != null
                        ? DateFormat('EEE, d MMM • HH:mm')
                            .format(_requestedFor!)
                        : 'Chagua tarehe na muda',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _row('Maelekezo (si lazima)'),
          TextField(
            controller: _notesCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mfano: Andika "Happy Birthday Asha" juu ya keki',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Wasilisha agizo',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String value, IconData icon, String label) {
    final selected = _deliveryMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _deliveryMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : _kCardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? _kPrimary : _kBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: selected ? Colors.white : _kPrimary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _kPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kSecondary)),
    );
  }
}
