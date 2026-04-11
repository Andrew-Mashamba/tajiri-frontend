// lib/tanesco/pages/tariff_calculator_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../widgets/appliance_slider.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class _ApplianceEntry {
  final String name;
  final IconData icon;
  final double watts;
  double hoursPerDay;
  _ApplianceEntry({required this.name, required this.icon, required this.watts, double hours = 0}) : hoursPerDay = hours;
}

class TariffCalculatorPage extends StatefulWidget {
  const TariffCalculatorPage({super.key});
  @override
  State<TariffCalculatorPage> createState() => _TariffCalculatorPageState();
}

class _TariffCalculatorPageState extends State<TariffCalculatorPage> {
  String _tariff = 'D1'; // D1 = domestic, T1 = general
  final List<_ApplianceEntry> _appliances = [
    _ApplianceEntry(name: 'Jokofu / Fridge', icon: Icons.kitchen_rounded, watts: 150),
    _ApplianceEntry(name: 'Televisheni / TV', icon: Icons.tv_rounded, watts: 100),
    _ApplianceEntry(name: 'Pasi / Iron', icon: Icons.iron_rounded, watts: 1200),
    _ApplianceEntry(name: 'AC', icon: Icons.ac_unit_rounded, watts: 1500),
    _ApplianceEntry(name: 'Taa / Bulb (LED)', icon: Icons.lightbulb_rounded, watts: 10),
    _ApplianceEntry(name: 'Taa / Bulb (CFL)', icon: Icons.lightbulb_outline_rounded, watts: 25),
    _ApplianceEntry(name: 'Feni / Fan', icon: Icons.wind_power_rounded, watts: 75),
    _ApplianceEntry(name: 'Microwave', icon: Icons.microwave_rounded, watts: 1000),
    _ApplianceEntry(name: 'Kufulia / Washing Machine', icon: Icons.local_laundry_service_rounded, watts: 500),
    _ApplianceEntry(name: 'Kompyuta / Computer', icon: Icons.computer_rounded, watts: 200),
    _ApplianceEntry(name: 'Moto wa Maji / Water Heater', icon: Icons.hot_tub_rounded, watts: 3000),
  ];

  // Custom appliance fields
  final _customNameCtrl = TextEditingController();
  final _customWattsCtrl = TextEditingController();

  @override
  void dispose() {
    _customNameCtrl.dispose();
    _customWattsCtrl.dispose();
    super.dispose();
  }

  double get _totalMonthlyKwh {
    double total = 0;
    for (final a in _appliances) {
      total += (a.watts * a.hoursPerDay * 30) / 1000;
    }
    return total;
  }

  double get _totalMonthlyCost {
    final kwh = _totalMonthlyKwh;
    if (_tariff == 'D1') {
      if (kwh <= 75) return kwh * 100 + 5682;
      return 75 * 100 + (kwh - 75) * 350 + 5682;
    }
    // T1 general
    return kwh * 232;
  }

  double get _serviceCharge => _tariff == 'D1' ? 5682 : 0;

  void _showAddCustom() {
    _customNameCtrl.clear();
    _customWattsCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Ongeza Kifaa / Add Appliance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 12),
            TextField(
              controller: _customNameCtrl,
              decoration: InputDecoration(
                hintText: 'Jina / Name', hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customWattsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Watts', hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48, width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = _customNameCtrl.text.trim();
                  final watts = double.tryParse(_customWattsCtrl.text.trim());
                  if (name.isEmpty || watts == null || watts <= 0) return;
                  Navigator.pop(ctx);
                  setState(() {
                    _appliances.add(_ApplianceEntry(
                      name: name, icon: Icons.electrical_services_rounded, watts: watts));
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ongeza / Add', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Hesabu Matumizi' : 'Tariff Calculator',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _showAddCustom),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jumla / Total Monthly',
                          style: TextStyle(fontSize: 10, color: _kSecondary)),
                      Text('${_totalMonthlyKwh.toStringAsFixed(1)} kWh',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TZS ${_totalMonthlyCost.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
                    Text('+ TZS ${_serviceCharge.toStringAsFixed(0)} service',
                        style: const TextStyle(fontSize: 10, color: _kSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // Tariff selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _TariffChip(label: 'D1 Nyumba', active: _tariff == 'D1',
                    onTap: () => setState(() => _tariff = 'D1')),
                const SizedBox(width: 8),
                _TariffChip(label: 'T1 Biashara', active: _tariff == 'T1',
                    onTap: () => setState(() => _tariff = 'T1')),
              ],
            ),
          ),

          // Tariff info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tariff == 'D1'
                          ? '0-75 kWh: TZS 100/kWh | 76+ kWh: TZS 350/kWh | Service: TZS 5,682/mwezi'
                          : 'TZS 232/kWh (General Use T1)',
                      style: const TextStyle(fontSize: 10, color: _kSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Appliance list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: _appliances.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = _appliances[i];
                return Dismissible(
                  key: ValueKey('${a.name}_${a.watts}_$i'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                  ),
                  onDismissed: (_) => setState(() => _appliances.removeAt(i)),
                  child: ApplianceSlider(
                    name: a.name,
                    icon: a.icon,
                    watts: a.watts,
                    hoursPerDay: a.hoursPerDay,
                    onHoursChanged: (v) => setState(() => a.hoursPerDay = v),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TariffChip extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _TariffChip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? _kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? _kPrimary : Colors.grey.shade300),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: active ? Colors.white : _kSecondary)),
    ),
  );
}
