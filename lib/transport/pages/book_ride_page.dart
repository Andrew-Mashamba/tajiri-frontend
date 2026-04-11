// lib/transport/pages/book_ride_page.dart
import 'package:flutter/material.dart';
import '../models/transport_models.dart';
import '../services/transport_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BookRidePage extends StatefulWidget {
  final int userId;
  const BookRidePage({super.key, required this.userId});
  @override
  State<BookRidePage> createState() => _BookRidePageState();
}

class _BookRidePageState extends State<BookRidePage> {
  final TransportService _service = TransportService();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  VehicleType _selectedVehicle = VehicleType.car;
  List<FareEstimate> _estimates = [];
  bool _isEstimating = false;
  bool _isBooking = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  Future<void> _getEstimates() async {
    if (_pickupController.text.trim().isEmpty || _dropoffController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka mahali pa kuanzia na kuishia')),
      );
      return;
    }

    setState(() => _isEstimating = true);
    final result = await _service.getFareEstimates(
      pickup: _pickupController.text.trim(),
      dropoff: _dropoffController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _isEstimating = false;
        if (result.success) _estimates = result.items;
      });
    }
  }

  Future<void> _bookRide() async {
    setState(() => _isBooking = true);
    final result = await _service.requestRide(
      userId: widget.userId,
      pickup: _pickupController.text.trim(),
      dropoff: _dropoffController.text.trim(),
      vehicleType: _selectedVehicle,
      paymentMethod: 'wallet',
    );
    if (mounted) {
      setState(() => _isBooking = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safari imeagizwa! Inatafuta dereva...')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kuagiza safari')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Piga Teksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location inputs
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.grey.shade300),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: _pickupController,
                            decoration: InputDecoration(
                              hintText: 'Unaanzia wapi?',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _dropoffController,
                            decoration: InputDecoration(
                              hintText: 'Unakwenda wapi?',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _getEstimates(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Vehicle selection
          const Text(
            'Chagua Aina ya Gari',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: VehicleType.values.where((v) => v != VehicleType.bus).map((type) {
              final isSelected = type == _selectedVehicle;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isSelected ? _kPrimary : _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedVehicle = type),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Icon(
                              type.icon,
                              size: 28,
                              color: isSelected ? Colors.white : _kPrimary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Get estimate button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isEstimating ? null : _getEstimates,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isEstimating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                    )
                  : const Text(
                      'Pata Bei ya Kadirio',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
            ),
          ),

          // Fare estimates
          if (_estimates.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Makadirio ya Bei',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            ..._estimates.map((est) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: est.vehicleType == _selectedVehicle
                        ? _kPrimary.withValues(alpha: 0.08)
                        : _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: est.vehicleType == _selectedVehicle
                        ? Border.all(color: _kPrimary, width: 1)
                        : null,
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedVehicle = est.vehicleType),
                    child: Row(
                      children: [
                        Icon(est.vehicleType.icon, size: 24, color: _kPrimary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                est.vehicleType.displayName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                              ),
                              Text(
                                '~${est.estimatedMinutes} dk | ${est.distance.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 11, color: _kSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'TZS ${_fmtPrice(est.estimatedFare)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                )),
          ],

          const SizedBox(height: 24),

          // Book button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isBooking || _pickupController.text.trim().isEmpty || _dropoffController.text.trim().isEmpty
                  ? null
                  : _bookRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Agiza ${_selectedVehicle.displayName}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
