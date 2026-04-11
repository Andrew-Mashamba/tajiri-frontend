// lib/rent_car/pages/my_bookings_page.dart
import 'package:flutter/material.dart';
import '../models/rent_car_models.dart';
import '../services/rent_car_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyBookingsPage extends StatefulWidget {
  final int userId;
  const MyBookingsPage({super.key, required this.userId});
  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final RentCarService _service = RentCarService();
  List<RentalBooking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyBookings();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _bookings = result.items;
      });
    }
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.active: return const Color(0xFF2E7D32);
      case BookingStatus.confirmed: return const Color(0xFF1565C0);
      case BookingStatus.pending: return const Color(0xFFE65100);
      case BookingStatus.completed: return _kSecondary;
      case BookingStatus.returned: return _kSecondary;
      case BookingStatus.cancelled: return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 48, color: _kSecondary),
                      const SizedBox(height: 12),
                      const Text('Hakuna bookings', style: TextStyle(color: _kSecondary, fontSize: 14)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(foregroundColor: _kPrimary),
                        child: const Text('Browse Vehicles'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = _bookings[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      b.vehicleTitle ?? 'Vehicle #${b.vehicleId}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(b.status).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      b.status.name.toUpperCase(),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(b.status)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: _kSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    b.pickupDate != null
                                        ? '${b.pickupDate!.day}/${b.pickupDate!.month}/${b.pickupDate!.year}'
                                        : 'TBD',
                                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                                  ),
                                  const Text(' - ', style: TextStyle(color: _kSecondary)),
                                  Text(
                                    b.returnDate != null
                                        ? '${b.returnDate!.day}/${b.returnDate!.month}/${b.returnDate!.year}'
                                        : 'TBD',
                                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'TZS ${b.totalCost.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
