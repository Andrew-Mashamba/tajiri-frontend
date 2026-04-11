// lib/transport/pages/my_trips_page.dart
import 'package:flutter/material.dart';
import '../models/transport_models.dart';
import '../services/transport_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyTripsPage extends StatefulWidget {
  final int userId;
  const MyTripsPage({super.key, required this.userId});
  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> with SingleTickerProviderStateMixin {
  final TransportService _service = TransportService();
  late TabController _tabController;

  List<Trip> _allTrips = [];
  List<Trip> _rideTrips = [];
  List<Trip> _busTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);

    final allResult = await _service.getMyTrips(userId: widget.userId);
    final rideResult = await _service.getMyTrips(userId: widget.userId, type: 'ride');
    final busResult = await _service.getMyTrips(userId: widget.userId, type: 'bus');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (allResult.success) _allTrips = allResult.items;
        if (rideResult.success) _rideTrips = rideResult.items;
        if (busResult.success) _busTrips = busResult.items;
      });
    }
  }

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildTripList(List<Trip> trips, String emptyMessage) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final trip = trips[i];
          final isRide = trip.type == TripType.ride;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRide ? (trip.vehicleType?.icon ?? Icons.directions_car_rounded) : Icons.directions_bus_rounded,
                    size: 18,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip.from} -> ${trip.to}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(trip.date),
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TZS ${_fmtPrice(trip.fare)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    if (trip.rating != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                          Text(
                            trip.rating!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10, color: _kSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
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
        title: const Text('Safari Zangu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Zote'),
            Tab(text: 'Teksi'),
            Tab(text: 'Basi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripList(_allTrips, 'Hakuna safari bado'),
                _buildTripList(_rideTrips, 'Hakuna safari za teksi'),
                _buildTripList(_busTrips, 'Hakuna safari za basi'),
              ],
            ),
    );
  }
}
