// lib/vehicle/pages/vehicle_detail_page.dart
import 'package:flutter/material.dart';
import '../models/vehicle_models.dart';
import '../services/vehicle_service.dart';
import 'fuel_log_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class VehicleDetailPage extends StatefulWidget {
  final Vehicle vehicle;
  final int userId;
  const VehicleDetailPage(
      {super.key, required this.vehicle, required this.userId});
  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final VehicleService _service = VehicleService();
  late Vehicle _vehicle;
  List<FuelLog> _fuelLogs = [];
  List<VehicleServiceRecord> _serviceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getFuelLogs(_vehicle.id),
      _service.getServiceRecords(_vehicle.id),
    ]);
    if (mounted) {
      final fuelResult = results[0] as VehicleListResult<FuelLog>;
      final serviceResult = results[1] as VehicleListResult<VehicleServiceRecord>;
      setState(() {
        _isLoading = false;
        if (fuelResult.success) _fuelLogs = fuelResult.items;
        if (serviceResult.success) _serviceRecords = serviceResult.items;
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  double get _totalFuelCost =>
      _fuelLogs.fold(0.0, (sum, l) => sum + l.totalCost);

  double get _totalLiters =>
      _fuelLogs.fold(0.0, (sum, l) => sum + l.liters);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(_vehicle.displayName,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vehicle info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(_vehicle.plateNumber,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3)),
                        const SizedBox(height: 8),
                        Text(_vehicle.displayName,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoChip(
                                label: _vehicle.fuelType.displayName,
                                subtitle: 'Mafuta'),
                            if (_vehicle.color != null)
                              _InfoChip(
                                  label: _vehicle.color!,
                                  subtitle: 'Rangi'),
                            if (_vehicle.engineSize != null)
                              _InfoChip(
                                  label: _vehicle.engineSize!,
                                  subtitle: 'Injini'),
                            if (_vehicle.mileage != null)
                              _InfoChip(
                                  label:
                                      '${_fmtAmount(_vehicle.mileage!)} km',
                                  subtitle: 'Maili'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Insurance status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _vehicle.hasInsurance
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _vehicle.hasInsurance
                              ? Icons.verified_rounded
                              : Icons.warning_rounded,
                          color: _vehicle.hasInsurance
                              ? const Color(0xFF4CAF50)
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _vehicle.hasInsurance
                                ? 'Bima hai — gari lina bima.'
                                : 'Gari hili halina bima. Pata bima kupitia sehemu ya Bima.',
                            style: const TextStyle(
                                fontSize: 13, color: _kPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.local_gas_station_rounded,
                          label: 'Jaza Mafuta',
                          onTap: () => _nav(FuelLogPage(
                              vehicleId: _vehicle.id,
                              vehicleName: _vehicle.displayName)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.build_rounded,
                          label: 'Huduma',
                          onTap: () {
                            // Future: add service record page
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Kuongeza huduma kutapatikana hivi karibuni')));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fuel stats
                  if (_fuelLogs.isNotEmpty) ...[
                    const Text('Takwimu za Mafuta',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                              value: 'TZS ${_fmtAmount(_totalFuelCost)}',
                              label: 'Jumla'),
                          _StatItem(
                              value:
                                  '${_totalLiters.toStringAsFixed(1)} L',
                              label: 'Lita'),
                          _StatItem(
                              value: '${_fuelLogs.length}',
                              label: 'Mara'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Recent fuel logs
                    ..._fuelLogs.take(3).map((l) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.local_gas_station_rounded,
                                  size: 20,
                                  color: _kSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${l.liters.toStringAsFixed(1)} L @ TZS ${_fmtAmount(l.pricePerLiter)}/L',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _kPrimary)),
                                    if (l.station != null)
                                      Text(l.station!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _kSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      'TZS ${_fmtAmount(l.totalCost)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary)),
                                  Text(_fmtDate(l.date),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _kSecondary)),
                                ],
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Service history
                  if (_serviceRecords.isNotEmpty) ...[
                    const Text('Historia ya Huduma',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 10),
                    ..._serviceRecords.take(5).map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(s.serviceType.icon,
                                  size: 20, color: _kSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.serviceType.displayName,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary)),
                                    if (s.description != null)
                                      Text(s.description!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _kSecondary),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      'TZS ${_fmtAmount(s.cost)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary)),
                                  Text(_fmtDate(s.date),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _kSecondary)),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String subtitle;
  const _InfoChip({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        Text(subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: _kSecondary)),
      ],
    );
  }
}
