// lib/my_cars/pages/car_detail_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/my_cars_models.dart';
import '../services/my_cars_service.dart';
import 'car_fuel_log_page.dart';
import '../../sell_car/pages/sell_car_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CarDetailPage extends StatefulWidget {
  final Car car;
  const CarDetailPage({super.key, required this.car});
  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  late Car _car;
  List<CarServiceRecord> _services = [];
  List<CarFuelLog> _fuelLogs = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _car = widget.car;
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final sRes = await MyCarsService.getServiceRecords(_car.id);
    final fRes = await MyCarsService.getFuelLogs(_car.id);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (sRes.success) _services = sRes.items;
      if (fRes.success) _fuelLogs = fRes.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_car.displayName,
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _infoCard(),
                  const SizedBox(height: 16),
                  _statusRow(),
                  const SizedBox(height: 16),
                  _quickActions(),
                  const SizedBox(height: 20),
                  _sectionTitle(_isSwahili ? 'Matengenezo ya Hivi Karibuni' : 'Recent Services'),
                  const SizedBox(height: 8),
                  if (_services.isEmpty)
                    _emptyMsg(_isSwahili ? 'Hakuna rekodi za matengenezo' : 'No service records')
                  else
                    ..._services.take(5).map(_serviceTile),
                  const SizedBox(height: 20),
                  _sectionTitle(_isSwahili ? 'Rekodi za Mafuta' : 'Fuel Log'),
                  const SizedBox(height: 8),
                  if (_fuelLogs.isEmpty)
                    _emptyMsg(_isSwahili ? 'Hakuna rekodi za mafuta' : 'No fuel records')
                  else
                    ..._fuelLogs.take(5).map(_fuelTile),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _car.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(_car.photoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car_rounded,
                            size: 28,
                            color: _kPrimary)))
                : const Icon(Icons.directions_car_rounded,
                    size: 28, color: _kPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_car.displayName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_car.plateNumber,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                          letterSpacing: 1.5)),
                ]),
          ),
        ]),
        const SizedBox(height: 16),
        _detailRow(_isSwahili ? 'Mafuta' : 'Fuel', _car.fuelType),
        if (_car.color != null)
          _detailRow(_isSwahili ? 'Rangi' : 'Color', _car.color!),
        if (_car.engineSize != null)
          _detailRow(_isSwahili ? 'Injini' : 'Engine', _car.engineSize!),
        _detailRow('Km', '${_car.mileage.toStringAsFixed(0)} km'),
        if (_car.vinNumber != null) _detailRow('VIN', _car.vinNumber!),
      ]),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _statusRow() {
    return Row(children: [
      _statusChip(
        icon: Icons.shield_rounded,
        label: _car.hasInsurance
            ? (_isSwahili ? 'Bima' : 'Insured')
            : (_isSwahili ? 'Haina Bima' : 'No Insurance'),
        color: _car.hasInsurance ? const Color(0xFF4CAF50) : Colors.orange,
      ),
      const SizedBox(width: 10),
      _statusChip(
        icon: Icons.build_rounded,
        label: _car.serviceOverdue
            ? (_isSwahili ? 'Huduma Imepita' : 'Service Overdue')
            : (_isSwahili ? 'Sawa' : 'OK'),
        color: _car.serviceOverdue ? Colors.red : const Color(0xFF4CAF50),
      ),
    ]);
  }

  Widget _statusChip(
      {required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _quickActions() {
    return Row(children: [
      _actionBtn(Icons.local_gas_station_rounded,
          _isSwahili ? 'Mafuta' : 'Fuel', () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CarFuelLogPage(
                    carId: _car.id, carName: _car.displayName)));
      }),
      const SizedBox(width: 10),
      _actionBtn(
          Icons.description_rounded,
          _isSwahili ? 'Nyaraka' : 'Docs',
          () async {
        final result = await MyCarsService.getDocuments(_car.id);
        if (!mounted) return;
        if (result.success && result.items.isNotEmpty) {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            builder: (ctx) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_isSwahili ? 'Nyaraka za Gari' : 'Car Documents',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 12),
                ...result.items.map((doc) => ListTile(
                      leading: Icon(
                        doc.isExpired ? Icons.warning_rounded : Icons.description_rounded,
                        color: doc.isExpired ? Colors.red : _kPrimary,
                      ),
                      title: Text(doc.title ?? doc.type,
                          style: const TextStyle(fontSize: 13, color: _kPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: doc.expiryDate != null
                          ? Text(
                              '${doc.isExpired ? (_isSwahili ? "Imeisha" : "Expired") : (_isSwahili ? "Inaisha" : "Expires")}: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                              style: TextStyle(fontSize: 11, color: doc.isExpired ? Colors.red : _kSecondary))
                          : null,
                    )),
              ]),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_isSwahili ? 'Hakuna nyaraka' : 'No documents found')));
        }
      }),
      const SizedBox(width: 10),
      _actionBtn(
          Icons.sell_rounded, _isSwahili ? 'Uza' : 'Sell', () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SellCarHomePage(userId: _car.userId)));
      }),
    ]);
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            Icon(icon, color: _kPrimary, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary));
  }

  Widget _emptyMsg(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: _kSecondary))),
    );
  }

  Widget _serviceTile(CarServiceRecord rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.build_circle_rounded, size: 20, color: _kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rec.serviceType,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (rec.garageName != null)
              Text(rec.garageName!,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        Text('TZS ${rec.cost.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
      ]),
    );
  }

  Widget _fuelTile(CarFuelLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.local_gas_station_rounded,
            size: 20, color: _kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${log.liters.toStringAsFixed(1)} L',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            if (log.station != null)
              Text(log.station!,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        Text('TZS ${log.totalCost.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
      ]),
    );
  }
}
