// lib/my_cars/pages/car_fuel_log_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/my_cars_models.dart';
import '../services/my_cars_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CarFuelLogPage extends StatefulWidget {
  final int carId;
  final String carName;
  const CarFuelLogPage({super.key, required this.carId, required this.carName});
  @override
  State<CarFuelLogPage> createState() => _CarFuelLogPageState();
}

class _CarFuelLogPageState extends State<CarFuelLogPage> {
  List<CarFuelLog> _logs = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await MyCarsService.getFuelLogs(widget.carId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _logs = r.items;
    });
  }

  double get _totalCost => _logs.fold(0, (s, l) => s + l.totalCost);
  double get _totalLiters => _logs.fold(0, (s, l) => s + l.liters);

  void _showAddDialog() {
    final litersCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stationCtrl = TextEditingController();
    final mileageCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 20, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_isSwahili ? 'Ongeza Mafuta' : 'Add Fuel Entry',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 16),
          _sheetField(litersCtrl, _isSwahili ? 'Lita' : 'Liters'),
          _sheetField(
              priceCtrl, _isSwahili ? 'Bei kwa Lita (TZS)' : 'Price/L (TZS)'),
          _sheetField(stationCtrl, _isSwahili ? 'Kituo' : 'Station'),
          _sheetField(
              mileageCtrl, _isSwahili ? 'Kilomita (km)' : 'Mileage (km)'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final liters = double.tryParse(litersCtrl.text) ?? 0;
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (liters <= 0 || price <= 0) return;
                Navigator.pop(ctx);
                final result = await MyCarsService.addFuelLog(widget.carId, {
                  'liters': liters,
                  'price_per_liter': price,
                  'total_cost': liters * price,
                  'fuel_type': 'petrol',
                  if (stationCtrl.text.isNotEmpty) 'station': stationCtrl.text,
                  if (mileageCtrl.text.isNotEmpty)
                    'mileage': double.tryParse(mileageCtrl.text),
                });
                if (result.success) {
                  messenger.showSnackBar(SnackBar(
                      content: Text(
                          _isSwahili ? 'Imeongezwa!' : 'Entry added!')));
                  _load();
                } else {
                  messenger.showSnackBar(SnackBar(
                      content: Text(result.message ??
                          (_isSwahili ? 'Imeshindwa' : 'Failed'))));
                }
              },
              child: Text(_isSwahili ? 'Hifadhi' : 'Save'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
            _isSwahili ? 'Rekodi za Mafuta' : 'Fuel Log',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
              icon: const Icon(Icons.add_rounded), onPressed: _showAddDialog),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Expanded(
                          child: _summaryItem(
                              'TZS ${_totalCost.toStringAsFixed(0)}',
                              _isSwahili ? 'Jumla' : 'Total')),
                      Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.2)),
                      Expanded(
                          child: _summaryItem(
                              '${_totalLiters.toStringAsFixed(1)} L',
                              _isSwahili ? 'Lita' : 'Liters')),
                      Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.2)),
                      Expanded(
                          child: _summaryItem('${_logs.length}',
                              _isSwahili ? 'Mara' : 'Fill-ups')),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  if (_logs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(children: [
                        const Icon(Icons.local_gas_station_rounded,
                            size: 48, color: _kSecondary),
                        const SizedBox(height: 12),
                        Text(
                            _isSwahili
                                ? 'Hakuna rekodi za mafuta'
                                : 'No fuel entries yet',
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary)),
                      ]),
                    )
                  else
                    ..._logs.map(_logTile),
                ],
              ),
            ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label,
          style:
              TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
    ]);
  }

  Widget _logTile(CarFuelLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_gas_station_rounded,
              size: 20, color: _kPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${log.liters.toStringAsFixed(1)} L @ TZS ${log.pricePerLiter.toStringAsFixed(0)}/L',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
                '${log.date.day}/${log.date.month}/${log.date.year}${log.station != null ? ' - ${log.station}' : ''}',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Text('TZS ${log.totalCost.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      ]),
    );
  }
}
