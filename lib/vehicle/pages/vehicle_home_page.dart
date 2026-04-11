// lib/vehicle/pages/vehicle_home_page.dart
import 'package:flutter/material.dart';
import '../models/vehicle_models.dart';
import '../services/vehicle_service.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_page.dart';
import 'vehicle_detail_page.dart';
import 'fuel_log_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class VehicleHomePage extends StatefulWidget {
  final int userId;
  const VehicleHomePage({super.key, required this.userId});
  @override
  State<VehicleHomePage> createState() => _VehicleHomePageState();
}

class _VehicleHomePageState extends State<VehicleHomePage> {
  final VehicleService _service = VehicleService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyVehicles(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _vehicles = result.items;
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_car_rounded,
                        color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Gari Tajiri',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Dhibiti magari yako, mafuta, bima, na matengenezo.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _HeaderStat(
                        value: '${_vehicles.length}', label: 'Magari'),
                    const SizedBox(width: 20),
                    _HeaderStat(
                        value: _vehicles
                            .where((v) => v.hasInsurance)
                            .length
                            .toString(),
                        label: 'Yana Bima'),
                    const SizedBox(width: 20),
                    _HeaderStat(
                        value: _vehicles
                            .where((v) => v.serviceOverdue)
                            .length
                            .toString(),
                        label: 'Huduma Imepita'),
                  ],
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
                      icon: Icons.add_rounded,
                      label: 'Ongeza Gari',
                      onTap: () => _nav(
                          AddVehiclePage(userId: widget.userId)))),
              const SizedBox(width: 10),
              if (_vehicles.isNotEmpty) ...[
                Expanded(
                    child: _QuickAction(
                        icon: Icons.local_gas_station_rounded,
                        label: 'Jaza Mafuta',
                        onTap: () => _nav(FuelLogPage(
                            vehicleId: _vehicles.first.id,
                            vehicleName: _vehicles.first.displayName)))),
                const SizedBox(width: 10),
              ],
              Expanded(
                  child: _QuickAction(
                      icon: Icons.shield_rounded,
                      label: 'Bima',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Nenda kwenye sehemu ya Bima kwa bima ya gari')));
                      })),
            ],
          ),
          const SizedBox(height: 20),

          // Vehicles list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Magari Yangu',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
              TextButton.icon(
                onPressed: () =>
                    _nav(AddVehiclePage(userId: widget.userId)),
                icon: const Icon(Icons.add_rounded,
                    size: 18, color: _kPrimary),
                label: const Text('Ongeza',
                    style: TextStyle(fontSize: 13, color: _kPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_vehicles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.directions_car_rounded,
                        size: 48, color: _kSecondary),
                    const SizedBox(height: 12),
                    const Text('Huna gari bado',
                        style:
                            TextStyle(fontSize: 16, color: _kSecondary)),
                    const SizedBox(height: 6),
                    const Text(
                        'Ongeza gari lako la kwanza kufuatilia mafuta na matengenezo.',
                        style: TextStyle(fontSize: 13, color: _kSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          _nav(AddVehiclePage(userId: widget.userId)),
                      style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary),
                      child: const Text('Ongeza Gari'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._vehicles.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VehicleCard(
                    vehicle: v,
                    onTap: () => _nav(VehicleDetailPage(
                        vehicle: v, userId: widget.userId)),
                  ),
                )),

          // Upcoming reminders
          if (_vehicles.any((v) =>
              v.nextServiceDate != null &&
              v.daysUntilService != null &&
              v.daysUntilService! <= 30)) ...[
            const SizedBox(height: 16),
            const Text('Vikumbusho',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            ..._vehicles
                .where((v) =>
                    v.daysUntilService != null && v.daysUntilService! <= 30)
                .map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: v.serviceOverdue
                            ? Colors.red.withValues(alpha: 0.08)
                            : Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notification_important_rounded,
                            color:
                                v.serviceOverdue ? Colors.red : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              v.serviceOverdue
                                  ? '${v.displayName} — Huduma imepita muda!'
                                  : '${v.displayName} — Huduma baada ya siku ${v.daysUntilService}',
                              style: const TextStyle(
                                  fontSize: 13, color: _kPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
