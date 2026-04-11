// lib/ewura/pages/ewura_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/ewura_models.dart';
import '../services/ewura_service.dart';
import '../widgets/fuel_price_card.dart';
import 'station_list_page.dart';
import 'tariff_calculator_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class EwuraHomePage extends StatefulWidget {
  final int userId;
  const EwuraHomePage({super.key, required this.userId});
  @override
  State<EwuraHomePage> createState() => _EwuraHomePageState();
}

class _EwuraHomePageState extends State<EwuraHomePage> {
  List<FuelPrice> _prices = [];
  bool _isLoading = true;
  bool _isSwahili = true;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);
    final r = await EwuraService.getFuelPrices(region: _selectedRegion);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _prices = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili ? 'Imeshindwa kupakia bei' : 'Failed to load prices')),
      ));
    }
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadPrices,
            color: _kPrimary,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                  // Quick actions
                  Row(
                    children: [
                      _ActionTile(
                        icon: Icons.local_gas_station_rounded,
                        label: _isSwahili ? 'Vituo' : 'Stations',
                        onTap: () => _nav(const StationListPage()),
                      ),
                      const SizedBox(width: 10),
                      _ActionTile(
                        icon: Icons.calculate_rounded,
                        label: _isSwahili ? 'Tozo' : 'Tariffs',
                        onTap: () => _nav(const TariffCalculatorPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Region filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isSwahili ? 'Bei za Mafuta' : 'Fuel Prices',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary),
                      ),
                      DropdownButton<String?>(
                        value: _selectedRegion,
                        hint: Text(_isSwahili ? 'Mkoa' : 'Region',
                            style: const TextStyle(
                                fontSize: 13, color: _kSecondary)),
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                  _isSwahili ? 'Yote' : 'All')),
                          ...['Dar es Salaam', 'Dodoma', 'Arusha',
                              'Mwanza', 'Mbeya', 'Tanga']
                              .map((r) => DropdownMenuItem(
                                  value: r, child: Text(r))),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedRegion = v);
                          _loadPrices();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_prices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          _isSwahili
                              ? 'Hakuna bei kwa sasa'
                              : 'No prices available',
                          style: const TextStyle(
                              fontSize: 14, color: _kSecondary),
                        ),
                      ),
                    )
                  else
                    ..._prices.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FuelPriceCard(
                              price: p, isSwahili: _isSwahili),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            Icon(icon, color: _kPrimary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
