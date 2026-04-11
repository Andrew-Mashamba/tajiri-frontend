// lib/fuel_delivery/pages/order_tracking_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/fuel_delivery_models.dart';
import '../services/fuel_delivery_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class OrderTrackingPage extends StatefulWidget {
  final FuelOrder order;
  const OrderTrackingPage({super.key, required this.order});
  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late FuelOrder _order;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _refreshOrder();
  }

  Future<void> _refreshOrder() async {
    final r = await FuelDeliveryService.getOrderDetail(_order.id);
    if (mounted && r.success && r.data != null) {
      setState(() => _order = r.data!);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Sitisha Agizo?' : 'Cancel Order?'),
        content: Text(_isSwahili
            ? 'Una uhakika unataka kusitisha agizo hili?'
            : 'Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Hapana' : 'No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_isSwahili ? 'Ndiyo' : 'Yes',
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final r = await FuelDeliveryService.cancelOrder(_order.id);
    if (!mounted) return;
    if (r.success) {
      messenger.showSnackBar(SnackBar(
          content:
              Text(_isSwahili ? 'Agizo limesitishwa' : 'Order cancelled')));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(r.message ??
              (_isSwahili ? 'Imeshindwa' : 'Failed to cancel'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
            '${_isSwahili ? 'Agizo' : 'Order'} #${_order.id}',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshOrder,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status timeline
            _statusTimeline(),
            const SizedBox(height: 20),

            // Driver info
            if (_order.driver != null) ...[
              _driverCard(_order.driver!),
              const SizedBox(height: 16),
            ],

            // Order details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isSwahili ? 'Maelezo ya Agizo' : 'Order Details',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const Divider(height: 20),
                    _detailRow(_isSwahili ? 'Mafuta' : 'Fuel',
                        _order.fuelType.toUpperCase()),
                    _detailRow(_isSwahili ? 'Lita' : 'Liters',
                        '${_order.liters.toStringAsFixed(1)} L'),
                    _detailRow(_isSwahili ? 'Bei/Lita' : 'Price/L',
                        'TZS ${_order.pricePerLiter.toStringAsFixed(0)}'),
                    _detailRow(_isSwahili ? 'Usafirishaji' : 'Delivery Fee',
                        'TZS ${_order.deliveryFee.toStringAsFixed(0)}'),
                    const Divider(height: 16),
                    _detailRow(_isSwahili ? 'Jumla' : 'Total',
                        'TZS ${_order.totalCost.toStringAsFixed(0)}',
                        bold: true),
                  ]),
            ),
            const SizedBox(height: 12),

            // Address
            if (_order.deliveryAddress != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 20, color: _kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_order.deliveryAddress!,
                        style: const TextStyle(
                            fontSize: 13, color: _kPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            const SizedBox(height: 20),

            // Cancel button
            if (_order.isActive)
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _cancelOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                      _isSwahili ? 'Sitisha Agizo' : 'Cancel Order',
                      style: const TextStyle(fontSize: 15)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusTimeline() {
    final steps = ['pending', 'confirmed', 'en_route', 'delivered'];
    final labels = _isSwahili
        ? ['Imepokelewa', 'Imethibitishwa', 'Njiani', 'Imefikishwa']
        : ['Pending', 'Confirmed', 'En Route', 'Delivered'];
    final currentIdx = steps.indexOf(_order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final done = i <= currentIdx;
          final color = done ? const Color(0xFF4CAF50) : Colors.grey.shade300;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 24,
                height: 24,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: color),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              if (i < steps.length - 1)
                Container(width: 2, height: 28, color: color),
            ]),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          done ? FontWeight.w600 : FontWeight.normal,
                      color: done ? _kPrimary : _kSecondary)),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _driverCard(DeliveryDriver driver) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _kPrimary.withValues(alpha: 0.08),
          backgroundImage:
              driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
          child: driver.photoUrl == null
              ? Text(driver.name.isNotEmpty ? driver.name[0] : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: _kPrimary))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(driver.name,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text(driver.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
              if (driver.vehiclePlate != null) ...[
                const SizedBox(width: 8),
                Text(driver.vehiclePlate!,
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ]),
          ]),
        ),
        if (driver.phone != null)
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: _kPrimary),
            onPressed: () async {
              final uri = Uri(scheme: 'tel', path: driver.phone);
              try {
                await launchUrl(uri);
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          _isSwahili ? 'Imeshindwa kupiga simu' : 'Could not make call')));
                }
              }
            },
          ),
      ]),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: bold ? _kPrimary : _kSecondary,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: _kPrimary)),
          ]),
    );
  }
}
