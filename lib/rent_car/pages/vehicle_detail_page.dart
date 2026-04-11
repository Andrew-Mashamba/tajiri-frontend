// lib/rent_car/pages/vehicle_detail_page.dart
import 'package:flutter/material.dart';
import '../models/rent_car_models.dart';
import '../services/rent_car_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class VehicleDetailPage extends StatefulWidget {
  final RentalVehicle vehicle;
  const VehicleDetailPage({super.key, required this.vehicle});
  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final RentCarService _service = RentCarService();
  int _photoIndex = 0;
  bool _isBooking = false;

  RentalVehicle get v => widget.vehicle;

  Future<void> _bookVehicle() async {
    setState(() => _isBooking = true);
    final now = DateTime.now();
    final result = await _service.createBooking(
      vehicleId: v.id,
      pickupDate: now.add(const Duration(days: 1)).toIso8601String(),
      returnDate: now.add(const Duration(days: 3)).toIso8601String(),
    );
    if (mounted) {
      setState(() => _isBooking = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Booking confirmed!'), backgroundColor: _kPrimary),
        );
        Navigator.pop(context);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Booking failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // Photo header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: _kPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: v.photos.isNotEmpty
                  ? PageView.builder(
                      itemCount: v.photos.length,
                      onPageChanged: (i) => setState(() => _photoIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        v.photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE8E8E8),
                          child: const Icon(Icons.directions_car_rounded, size: 64, color: _kSecondary),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFE8E8E8),
                      child: const Icon(Icons.directions_car_rounded, size: 64, color: _kSecondary),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo indicator
                  if (v.photos.length > 1)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(v.photos.length, (i) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _photoIndex ? _kPrimary : const Color(0xFFD0D0D0),
                            ),
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Title and rating
                  Text(v.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB300)),
                      const SizedBox(width: 4),
                      Text('${v.rating.toStringAsFixed(1)} (${v.reviewCount} reviews)',
                          style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(v.category.label,
                            style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Specs row
                  Row(
                    children: [
                      _Spec(icon: Icons.airline_seat_recline_normal_rounded, label: '${v.seats} seats'),
                      _Spec(icon: Icons.settings_rounded, label: v.transmission),
                      _Spec(icon: Icons.local_gas_station_rounded, label: v.fuelType),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Pricing
                  const Text('Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 10),
                  _PriceRow(label: 'Daily', amount: v.dailyRate),
                  if (v.weeklyRate > 0) _PriceRow(label: 'Weekly', amount: v.weeklyRate),
                  if (v.monthlyRate > 0) _PriceRow(label: 'Monthly', amount: v.monthlyRate),
                  const SizedBox(height: 16),

                  // Policies
                  const Text('Policies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 10),
                  _PolicyTile(icon: Icons.speed_rounded, label: 'Mileage', value: v.mileagePolicy),
                  _PolicyTile(icon: Icons.local_gas_station_rounded, label: 'Fuel', value: v.fuelPolicy),
                  if (v.location != null)
                    _PolicyTile(icon: Icons.location_on_rounded, label: 'Location', value: v.location!),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isBooking ? null : _bookVehicle,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isBooking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Book Now - TZS ${v.dailyRate.toStringAsFixed(0)}/day',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Spec({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Icon(icon, size: 22, color: _kPrimary),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  const _PriceRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: _kSecondary)),
          Text('TZS ${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        ],
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PolicyTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
