// lib/pharmacy/pages/order_detail_page.dart
import 'package:flutter/material.dart';
import '../models/pharmacy_models.dart';
import '../services/pharmacy_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class OrderDetailPage extends StatefulWidget {
  final int userId;
  final PharmacyOrder order;
  const OrderDetailPage({super.key, required this.userId, required this.order});
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final PharmacyService _service = PharmacyService();
  late PharmacyOrder _order;
  bool _isDelivery = false;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _payOrder() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza nambari ya M-Pesa')),
      );
      return;
    }

    setState(() => _isPaying = true);

    final result = await _service.payDoctorOrder(
      orderId: _order.id,
      paymentMethod: 'mobile_money',
      phoneNumber: _phoneController.text.trim(),
      isDelivery: _isDelivery,
      deliveryAddress: _isDelivery ? _addressController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isPaying = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Malipo yametumwa! Thibitisha kwenye simu yako.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kulipa'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsPayment = _order.status == PharmacyOrderStatus.awaitingPayment;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Agizo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _order.status.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _order.status.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  needsPayment ? Icons.payment_rounded : Icons.local_pharmacy_rounded,
                  color: _order.status.color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _order.status.displayName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _order.status.color),
                      ),
                      Text(
                        _order.orderId,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Doctor info (if doctor-prescribed)
          if (_order.isDoctorPrescribed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_rounded, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Imeandikwa na Dk. ${_order.doctorName ?? ''}',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Items
          const Text('Dawa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ..._order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.medication_rounded, size: 18, color: _kPrimary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.medicineName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                                Text('${item.strength} × ${item.quantity}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                              ],
                            ),
                          ),
                          Text('TZS ${_fmt(item.totalPrice)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dawa', style: TextStyle(fontSize: 13, color: _kSecondary)),
                    Text('TZS ${_fmt(_order.subtotal)}', style: const TextStyle(fontSize: 13, color: _kPrimary)),
                  ],
                ),
                if (_order.deliveryFee > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Usafirishaji', style: TextStyle(fontSize: 13, color: _kSecondary)),
                      Text('TZS ${_fmt(_order.deliveryFee)}', style: const TextStyle(fontSize: 13, color: _kPrimary)),
                    ],
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jumla', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                    Text('TZS ${_fmt(_order.totalAmount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment section (for awaiting_payment orders)
          if (needsPayment) ...[
            const Text('Malipo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 10),

            // Delivery option
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isDelivery,
                        onChanged: (v) => setState(() => _isDelivery = v ?? false),
                        activeColor: _kPrimary,
                      ),
                      const Text('Peleka nyumbani', style: TextStyle(fontSize: 14, color: _kPrimary)),
                    ],
                  ),
                  if (_isDelivery) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Anwani ya Usafirishaji',
                        hintText: 'Mfano: Kinondoni, Dar es Salaam',
                        filled: true, fillColor: _kBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Phone number
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nambari ya M-Pesa',
                hintText: '0712 345 678',
                prefixIcon: const Icon(Icons.phone_outlined, color: _kSecondary),
                filled: true, fillColor: _kCardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isPaying ? null : _payOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isPaying
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Lipa TZS ${_fmt(_order.totalAmount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],

          // Order details
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _DetailRow(label: 'Tarehe', value: _formatDate(_order.createdAt)),
                if (_order.isDelivery) _DetailRow(label: 'Usafirishaji', value: _order.deliveryAddress ?? 'Ndiyo'),
                if (!_order.isDelivery) const _DetailRow(label: 'Kuchukua', value: 'Duka la Dawa Tajiri'),
                if (_order.estimatedReadyAt != null)
                  _DetailRow(label: 'Muda wa Maandalizi', value: _formatDate(_order.estimatedReadyAt!)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13, color: _kPrimary), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
