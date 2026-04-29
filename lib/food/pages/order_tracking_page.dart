import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/food_models.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kMuted = Color(0xFFE0E0E0);

class OrderTrackingPage extends StatefulWidget {
  final int orderId;
  final int userId;
  const OrderTrackingPage({
    super.key,
    required this.orderId,
    required this.userId,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final FoodService _service = FoodService();

  FoodOrder? _order;
  bool _loading = true;
  String? _loadError;
  Timer? _poll;
  Timer? _tick;
  bool _rateShown = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _load(silent: true));
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final result = await _service.getOrder(widget.orderId);
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() {
        _order = result.data;
        _loading = false;
        _loadError = null;
      });
      if (_order!.status == FoodOrderStatus.delivered && !_rateShown && _order!.rating == null) {
        _rateShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openRateModal();
        });
      }
    } else {
      setState(() {
        _loading = false;
        _loadError = result.message ?? 'Imeshindwa kupakia oda';
      });
    }
  }

  Future<void> _callDriver() async {
    final phone = _order?.driverPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _smsDriver() async {
    final phone = _order?.driverPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _cancel() async {
    if (_order == null || _cancelling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghairi oda?'),
        content: const Text('Hakikisha hujapokea chakula kabla ya kughairi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ghairi')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _cancelling = true);
    final result = await _service.cancelOrder(_order!.id);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (result.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Oda imeghairiwa')));
      _load(silent: true);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kughairi')),
      );
    }
  }

  Future<void> _openRateModal() async {
    if (_order == null) return;
    double rating = 5;
    final commentCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kadiria oda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < rating.round();
                    return IconButton(
                      onPressed: () => setLocal(() => rating = (i + 1).toDouble()),
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 36,
                        color: filled ? Colors.amber.shade600 : _kSecondary,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Maoni yako (hiari)',
                    hintStyle: const TextStyle(color: _kSecondary),
                    filled: true,
                    fillColor: _kBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(ctx);
                      final navigator = Navigator.of(ctx);
                      final rateResult = await _service.rateOrder(
                        orderId: _order!.id,
                        rating: rating,
                        comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                      );
                      if (rateResult.success) {
                        navigator.pop(true);
                      } else {
                        messenger.showSnackBar(
                          SnackBar(content: Text(rateResult.message ?? 'Imeshindwa')),
                        );
                      }
                    },
                    child: const Text('Tuma', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asante kwa maoni')),
      );
      _load(silent: true);
    }
  }

  int _activeStep(FoodOrderStatus s) {
    switch (s) {
      case FoodOrderStatus.pending:
        return 0;
      case FoodOrderStatus.confirmed:
        return 1;
      case FoodOrderStatus.preparing:
        return 2;
      case FoodOrderStatus.readyForPickup:
      case FoodOrderStatus.onTheWay:
        return 3;
      case FoodOrderStatus.delivered:
        return 4;
      case FoodOrderStatus.cancelled:
        return -1;
    }
  }

  String _etaText() {
    final eta = _order?.estimatedDelivery;
    if (eta == null) return 'Muda hautajwi';
    final now = DateTime.now();
    if (eta.isBefore(now)) return 'Yalikuwa tayari';
    final diff = eta.difference(now);
    if (diff.inMinutes < 60) return 'Muda takriban ${diff.inMinutes} dakika';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return 'Muda takriban ${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Fuatilia oda',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kPrimary),
            onPressed: () => _load(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _loadError != null
              ? _errorView()
              : _order == null
                  ? const Center(child: Text('Oda haijapatikana'))
                  : _bodyView(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 10),
          Text(_loadError ?? 'Hitilafu', style: const TextStyle(color: _kSecondary)),
          const SizedBox(height: 10),
          TextButton(onPressed: () => _load(), child: const Text('Jaribu tena')),
        ],
      ),
    );
  }

  Widget _bodyView() {
    final order = _order!;
    final step = _activeStep(order.status);
    return RefreshIndicator(
      onRefresh: () => _load(),
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(order),
          const SizedBox(height: 16),
          if (order.status == FoodOrderStatus.cancelled)
            _cancelledBlock()
          else
            _stepperBlock(step),
          const SizedBox(height: 16),
          if (order.driverName != null || order.driverPhone != null) ...[
            _courierCard(order),
            const SizedBox(height: 16),
          ],
          _itemsCard(order),
          const SizedBox(height: 16),
          _summaryCard(order),
          const SizedBox(height: 24),
          _actions(order),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _headerCard(FoodOrder order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: order.status.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(order.status.icon, color: order.status.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.status.displayName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: order.status.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: _kSecondary, size: 16),
              const SizedBox(width: 6),
              Text(_etaText(), style: const TextStyle(fontSize: 12, color: _kSecondary)),
              const Spacer(),
              Text('#${order.orderId}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperBlock(int step) {
    final labels = const [
      'Imeombwa',
      'Imethibitishwa',
      'Inaandaliwa',
      'Njiani',
      'Imefikishwa',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(labels.length, (i) {
          final active = i <= step;
          final isLast = i == labels.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: active ? _kAccent : _kMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        active ? Icons.check_rounded : Icons.circle_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: i < step ? _kAccent : _kMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 2),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? _kPrimary : _kSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _cancelledBlock() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.cancel_rounded, color: Color(0xFFD32F2F)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Oda hii imeghairiwa',
              style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _courierCard(FoodOrder order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: _kBg,
            child: Icon(Icons.delivery_dining_rounded, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driverName ?? 'Dereva',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  order.driverPhone ?? 'Hakuna simu',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
          if (order.driverPhone != null && order.driverPhone!.isNotEmpty) ...[
            IconButton(
              onPressed: _callDriver,
              icon: const Icon(Icons.call_rounded, color: _kAccent),
            ),
            IconButton(
              onPressed: _smsDriver,
              icon: const Icon(Icons.sms_rounded, color: _kPrimary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemsCard(FoodOrder order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bidhaa',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${it.quantity}×',
                        style: const TextStyle(fontSize: 13, color: _kSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        it.name,
                        style: const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('TZS ${it.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          if (order.items.isEmpty)
            const Text('Hakuna bidhaa', style: TextStyle(color: _kSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summaryCard(FoodOrder order) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      color: bold ? _kPrimary : _kSecondary,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              Text(value,
                  style: TextStyle(
                    fontSize: 13,
                    color: _kPrimary,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  )),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          row('Jumla ndogo', 'TZS ${order.subtotal.toStringAsFixed(0)}'),
          row('Uletaji', 'TZS ${order.deliveryFee.toStringAsFixed(0)}'),
          const Divider(height: 18),
          row('Jumla', 'TZS ${order.total.toStringAsFixed(0)}', bold: true),
          if (order.paymentMethod != null) ...[
            const SizedBox(height: 4),
            row('Malipo', '${order.paymentMethod} · ${order.paymentStatus ?? '-'}'),
          ],
          if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
            const SizedBox(height: 4),
            row('Anwani', order.deliveryAddress!),
          ],
        ],
      ),
    );
  }

  Widget _actions(FoodOrder order) {
    final canCancel = [
      FoodOrderStatus.pending,
      FoodOrderStatus.confirmed,
    ].contains(order.status);
    final delivered = order.status == FoodOrderStatus.delivered;
    return Column(
      children: [
        if (delivered && order.rating == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openRateModal,
              icon: const Icon(Icons.star_rounded, color: Colors.white),
              label: const Text('Kadiria oda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        if (delivered && order.rating != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: _kAccent, size: 18),
                const SizedBox(width: 8),
                Text('Umeshakadiria: ${order.rating!.toStringAsFixed(1)} ⭐',
                    style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        if (canCancel) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelling ? null : _cancel,
              icon: _cancelling
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD32F2F)))
                  : const Icon(Icons.cancel_outlined, color: Color(0xFFD32F2F)),
              label: const Text('Ghairi oda', style: TextStyle(color: Color(0xFFD32F2F))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD32F2F)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
