// lib/pharmacy/pages/pharmacy_home_page.dart
//
// Single platform pharmacy — "Duka la Dawa Tajiri"
// No multi-pharmacy search. Doctors create orders for patients.
// Patients find pending orders ready for payment.
//
import 'package:flutter/material.dart';
import '../models/pharmacy_models.dart';
import '../services/pharmacy_service.dart';
import '../widgets/order_card.dart';
import '../widgets/medicine_card.dart';
import 'search_medicine_page.dart';
import 'my_orders_page.dart';
import 'order_detail_page.dart';
import 'talk_to_pharmacist_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class PharmacyHomePage extends StatefulWidget {
  final int userId;
  const PharmacyHomePage({super.key, required this.userId});
  @override
  State<PharmacyHomePage> createState() => _PharmacyHomePageState();
}

class _PharmacyHomePageState extends State<PharmacyHomePage> {
  final PharmacyService _service = PharmacyService();

  List<PharmacyOrder> _pendingDoctorOrders = []; // Created by doctor, awaiting patient payment
  List<PharmacyOrder> _activeOrders = [];
  List<Medicine> _featuredMedicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _service.getDoctorPrescribedOrders(widget.userId),
      _service.getMyOrders(widget.userId),
      _service.getFeaturedMedicines(),
    ]);

    if (mounted) {
      final doctorOrdersResult = results[0] as PharmacyListResult<PharmacyOrder>;
      final ordersResult = results[1] as PharmacyListResult<PharmacyOrder>;
      final medicinesResult = results[2] as PharmacyListResult<Medicine>;

      setState(() {
        _isLoading = false;
        if (doctorOrdersResult.success) {
          _pendingDoctorOrders = doctorOrdersResult.items
              .where((o) => o.status == PharmacyOrderStatus.awaitingPayment)
              .toList();
        }
        if (ordersResult.success) {
          _activeOrders = ordersResult.items.where((o) => o.isActive).toList();
        }
        if (medicinesResult.success) _featuredMedicines = medicinesResult.items;
      });
    }
  }

  void _navigateAndRefresh(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Pharmacy header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Tajiri Pharmacy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your medicine — from doctor to your doorstep.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.search_rounded,
                  label: 'Search Medicine',
                  onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'My Orders',
                  onTap: () => _navigateAndRefresh(MyOrdersPage(userId: widget.userId)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.chat_rounded,
                  label: 'Talk to Pharmacist',
                  onTap: () => _navigateAndRefresh(TalkToPharmacistPage(userId: widget.userId)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Doctor-prescribed orders awaiting payment
          if (_pendingDoctorOrders.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.medication_rounded, color: Colors.blue.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your doctor has prescribed medicine ${_pendingDoctorOrders.length == 1 ? '' : '(${_pendingDoctorOrders.length})'}— pay to receive.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ..._pendingDoctorOrders.map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DoctorOrderCard(
                    order: order,
                    fmt: _fmt,
                    onPay: () => _navigateAndRefresh(
                      OrderDetailPage(userId: widget.userId, order: order),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Active orders
          if (_activeOrders.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                GestureDetector(
                  onTap: () => _navigateAndRefresh(MyOrdersPage(userId: widget.userId)),
                  child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._activeOrders.take(3).map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OrderCard(
                    order: order,
                    onTap: () => _navigateAndRefresh(OrderDetailPage(userId: widget.userId, order: order)),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Rx warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Medicines marked Rx require a doctor\'s prescription. Use "My Doctor" to get one.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Medicine categories
          const Text('Medicine Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _CategoryTile(icon: Icons.medication_rounded, label: 'Tablets', onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId, initialCategory: 'tablet'))),
              _CategoryTile(icon: Icons.local_drink_rounded, label: 'Syrups', onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId, initialCategory: 'syrup'))),
              _CategoryTile(icon: Icons.vaccines_rounded, label: 'Injections', onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId, initialCategory: 'injection'))),
              _CategoryTile(icon: Icons.spa_rounded, label: 'Creams', onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId, initialCategory: 'cream'))),
              _CategoryTile(icon: Icons.water_drop_rounded, label: 'Drops', onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId, initialCategory: 'drops'))),
              _CategoryTile(icon: Icons.child_care_rounded, label: 'Pediatric', onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId, initialCategory: 'pediatric'))),
              _CategoryTile(icon: Icons.pregnant_woman_rounded, label: 'Maternal', onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId, initialCategory: 'maternal'))),
              _CategoryTile(icon: Icons.favorite_rounded, label: 'Vitamins', onTap: () => _navigateAndRefresh(SearchMedicinePage(userId: widget.userId, initialCategory: 'vitamins'))),
            ],
          ),
          const SizedBox(height: 20),

          // Featured medicines
          if (_featuredMedicines.isNotEmpty) ...[
            const Text('Popular Medicines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 10),
            ..._featuredMedicines.take(6).map((med) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MedicineCard(medicine: med),
                )),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Order created by doctor — prominent payment CTA
class _DoctorOrderCard extends StatelessWidget {
  final PharmacyOrder order;
  final String Function(double) fmt;
  final VoidCallback onPay;

  const _DoctorOrderCard({required this.order, required this.fmt, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_rounded, size: 20, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor\'s Prescription${order.doctorName != null ? ' — Dr. ${order.doctorName}' : ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${order.items.length} medicines',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Items preview
          ...order.items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 4, color: _kSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.medicineName} ${item.strength} ×${item.quantity}',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('TZS ${fmt(item.totalPrice)}', style: const TextStyle(fontSize: 12, color: _kPrimary)),
                  ],
                ),
              )),
          if (order.items.length > 3)
            Text('...and ${order.items.length - 3} more', style: const TextStyle(fontSize: 11, color: _kSecondary)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: TZS ${fmt(order.totalAmount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: onPay,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Pay Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CategoryTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: _kPrimary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kPrimary)),
          ],
        ),
      ),
    );
  }
}
