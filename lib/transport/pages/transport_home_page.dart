// lib/transport/pages/transport_home_page.dart
import 'package:flutter/material.dart';
import '../models/transport_models.dart';
import '../services/transport_service.dart';
import 'book_ride_page.dart';
import 'bus_tickets_page.dart';
import 'my_trips_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class TransportHomePage extends StatefulWidget {
  final int userId;
  const TransportHomePage({super.key, required this.userId});
  @override
  State<TransportHomePage> createState() => _TransportHomePageState();
}

class _TransportHomePageState extends State<TransportHomePage> {
  final TransportService _service = TransportService();

  List<Trip> _recentTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final result = await _service.getMyTrips(userId: widget.userId, type: null);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _recentTrips = result.items;
      });
    }
  }

  void _openBookRide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookRidePage(userId: widget.userId)),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _openBusTickets() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BusTicketsPage(userId: widget.userId)),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _openMyTrips() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyTripsPage(userId: widget.userId)),
    ).then((_) {
      if (mounted) _loadData();
    });
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
          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.local_taxi_rounded,
                  label: 'Piga Teksi',
                  subtitle: 'Book Ride',
                  onTap: _openBookRide,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.directions_bus_rounded,
                  label: 'Tiketi za Basi',
                  subtitle: 'Bus Tickets',
                  onTap: _openBusTickets,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.history_rounded,
                  label: 'Safari Zangu',
                  subtitle: 'My Trips',
                  onTap: _openMyTrips,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vehicle types
          const Text(
            'Aina za Usafiri',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: VehicleType.values.map((type) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: type != VehicleType.values.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: _openBookRide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(type.icon, size: 24, color: _kPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.displayName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            type.subtitle,
                            style: const TextStyle(fontSize: 9, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Popular routes for buses
          const Text(
            'Njia Maarufu za Basi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          _PopularRoute(from: 'Dar es Salaam', to: 'Arusha', onTap: _openBusTickets),
          const SizedBox(height: 6),
          _PopularRoute(from: 'Dar es Salaam', to: 'Dodoma', onTap: _openBusTickets),
          const SizedBox(height: 6),
          _PopularRoute(from: 'Dar es Salaam', to: 'Mwanza', onTap: _openBusTickets),
          const SizedBox(height: 6),
          _PopularRoute(from: 'Arusha', to: 'Moshi', onTap: _openBusTickets),
          const SizedBox(height: 24),

          // Recent trips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Safari za Hivi Karibuni', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              GestureDetector(
                onTap: _openMyTrips,
                child: const Text('Zote', style: TextStyle(fontSize: 13, color: _kSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_recentTrips.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Hakuna safari bado', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text(
                    'Safari zako zitaonekana hapa',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          else
            ..._recentTrips.take(5).map((trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TripCard(trip: trip),
                )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

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
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: _kSecondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularRoute extends StatelessWidget {
  final String from;
  final String to;
  final VoidCallback onTap;

  const _PopularRoute({required this.from, required this.to, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.directions_bus_outlined, size: 18, color: _kSecondary),
              const SizedBox(width: 10),
              Text(from, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: _kSecondary),
              ),
              Text(to, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                  '${_fmtDate(trip.date)} | ${isRide ? trip.vehicleType?.displayName ?? "Gari" : trip.company ?? "Basi"}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
          ),
          Text(
            'TZS ${_fmtPrice(trip.fare)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
    );
  }
}
