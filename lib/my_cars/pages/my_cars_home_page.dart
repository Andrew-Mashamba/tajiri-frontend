// lib/my_cars/pages/my_cars_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/my_cars_models.dart';
import '../services/my_cars_service.dart';
import '../widgets/car_card.dart';
import 'add_car_page.dart';
import 'car_detail_page.dart';
import 'car_fuel_log_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class MyCarsHomePage extends StatefulWidget {
  final int userId;
  const MyCarsHomePage({super.key, required this.userId});
  @override
  State<MyCarsHomePage> createState() => _MyCarsHomePageState();
}

class _MyCarsHomePageState extends State<MyCarsHomePage> {
  List<Car> _cars = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await MyCarsService.getMyCars();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _cars = result.items;
    });
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child:
              CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    return RefreshIndicator(
        onRefresh: _loadData,
        color: _kPrimary,
        child: _cars.isEmpty ? _buildEmpty() : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              const Icon(Icons.directions_car_rounded,
                  size: 56, color: _kSecondary),
              const SizedBox(height: 14),
              Text(_isSwahili ? 'Huna gari bado' : 'No cars yet',
                  style: const TextStyle(fontSize: 16, color: _kSecondary)),
              const SizedBox(height: 6),
              Text(
                _isSwahili
                    ? 'Ongeza gari lako la kwanza kufuatilia matengenezo na gharama.'
                    : 'Add your first car to track maintenance and expenses.',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _nav(AddCarPage(userId: widget.userId)),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(_isSwahili ? 'Ongeza Gari' : 'Add Car'),
                style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Summary banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.directions_car_rounded,
                    color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(_isSwahili ? 'Gari Zangu' : 'My Garage',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _StatBadge('${_cars.length}',
                    _isSwahili ? 'Magari' : 'Vehicles'),
                const SizedBox(width: 20),
                _StatBadge(
                    '${_cars.where((c) => c.hasInsurance).length}',
                    _isSwahili ? 'Yana Bima' : 'Insured'),
                const SizedBox(width: 20),
                _StatBadge(
                    '${_cars.where((c) => c.serviceOverdue).length}',
                    _isSwahili ? 'Huduma' : 'Service Due'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions
        Row(children: [
          _QuickAction(
            icon: Icons.add_rounded,
            label: _isSwahili ? 'Ongeza' : 'Add Car',
            onTap: () => _nav(AddCarPage(userId: widget.userId)),
          ),
          const SizedBox(width: 10),
          if (_cars.isNotEmpty)
            _QuickAction(
              icon: Icons.local_gas_station_rounded,
              label: _isSwahili ? 'Mafuta' : 'Fuel Log',
              onTap: () => _nav(CarFuelLogPage(
                  carId: _cars.first.id,
                  carName: _cars.first.displayName)),
            ),
        ]),
        const SizedBox(height: 20),

        // Section header
        Text(_isSwahili ? 'Magari Yangu' : 'My Cars',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 8),

        ..._cars.map((car) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CarCard(
                car: car,
                isSwahili: _isSwahili,
                onTap: () => _nav(CarDetailPage(car: car)),
              ),
            )),

        // Reminders
        if (_cars.any((c) =>
            c.daysUntilInsurance != null && c.daysUntilInsurance! <= 30)) ...[
          const SizedBox(height: 16),
          Text(_isSwahili ? 'Vikumbusho' : 'Reminders',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 8),
          ..._cars
              .where((c) =>
                  c.daysUntilInsurance != null && c.daysUntilInsurance! <= 30)
              .map((c) => _ReminderTile(
                    car: c,
                    isSwahili: _isSwahili,
                  )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge(this.value, this.label);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(label,
          style:
              TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
    ]);
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            Icon(icon, color: _kPrimary, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Car car;
  final bool isSwahili;
  const _ReminderTile({required this.car, required this.isSwahili});
  @override
  Widget build(BuildContext context) {
    final expired = car.daysUntilInsurance != null && car.daysUntilInsurance! < 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expired
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.notification_important_rounded,
            color: expired ? Colors.red : Colors.orange, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            expired
                ? '${car.displayName} — ${isSwahili ? 'Bima imeisha!' : 'Insurance expired!'}'
                : '${car.displayName} — ${isSwahili ? 'Bima inaisha siku' : 'Insurance expires in'} ${car.daysUntilInsurance}',
            style: const TextStyle(fontSize: 13, color: _kPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}
