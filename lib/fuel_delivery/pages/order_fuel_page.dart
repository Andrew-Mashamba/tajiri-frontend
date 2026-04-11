// lib/fuel_delivery/pages/order_fuel_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/budget_context_banner.dart';
import '../models/fuel_delivery_models.dart';
import '../services/fuel_delivery_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class OrderFuelPage extends StatefulWidget {
  const OrderFuelPage({super.key});
  @override
  State<OrderFuelPage> createState() => _OrderFuelPageState();
}

class _OrderFuelPageState extends State<OrderFuelPage> {
  final _addressCtrl = TextEditingController();
  final _litersCtrl = TextEditingController(text: '40');
  final _instructionsCtrl = TextEditingController();
  String _fuelType = 'petrol';
  bool _isOrdering = false;
  late final bool _isSwahili;
  List<FuelPrice> _prices = [];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadPrices();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _litersCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    final r = await FuelDeliveryService.getFuelPrices();
    if (mounted && r.success) setState(() => _prices = r.items);
  }

  double get _currentPrice {
    final match = _prices.where((p) => p.fuelType == _fuelType);
    return match.isNotEmpty ? match.first.pricePerLiter : 0;
  }

  double get _estimatedCost {
    final liters = double.tryParse(_litersCtrl.text) ?? 0;
    return liters * _currentPrice;
  }

  Future<void> _placeOrder() async {
    final liters = double.tryParse(_litersCtrl.text.trim());
    if (liters == null || liters <= 0 || _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Jaza lita na mahali'
              : 'Enter liters and address')));
      return;
    }
    setState(() => _isOrdering = true);
    final result = await FuelDeliveryService.placeOrder({
      'fuel_type': _fuelType,
      'liters': liters,
      'delivery_address': _addressCtrl.text.trim(),
      if (_instructionsCtrl.text.isNotEmpty)
        'special_instructions': _instructionsCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isOrdering = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _isSwahili ? 'Agizo limewekwa!' : 'Order placed!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ??
              (_isSwahili ? 'Imeshindwa' : 'Failed to place order'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Agiza Mafuta' : 'Order Fuel',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Fuel type
          Text(_isSwahili ? 'Aina ya Mafuta' : 'Fuel Type',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            _fuelOption('petrol', 'Petrol', Icons.local_gas_station_rounded),
            const SizedBox(width: 10),
            _fuelOption('diesel', 'Diesel', Icons.local_gas_station_rounded),
            const SizedBox(width: 10),
            _fuelOption('premium', 'Premium', Icons.star_rounded),
          ]),
          const SizedBox(height: 16),

          // Quantity
          Text(_isSwahili ? 'Kiasi (Lita)' : 'Quantity (Liters)',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            _quantityBtn(10),
            _quantityBtn(20),
            _quantityBtn(40),
            _quantityBtn(60),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _litersCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _isSwahili ? 'Au andika kiasi...' : 'Or enter amount...',
              suffixText: 'L',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Address
          Text(_isSwahili ? 'Mahali pa Kupeleka' : 'Delivery Location',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              hintText:
                  _isSwahili ? 'Ingiza anwani...' : 'Enter delivery address...',
              prefixIcon:
                  const Icon(Icons.location_on_rounded, color: _kSecondary),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructionsCtrl,
            decoration: InputDecoration(
              hintText: _isSwahili
                  ? 'Maelekezo maalum (hiari)'
                  : 'Special instructions (optional)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Cost estimate
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: [
              _costRow(_isSwahili ? 'Mafuta' : 'Fuel',
                  'TZS ${_estimatedCost.toStringAsFixed(0)}'),
              _costRow(_isSwahili ? 'Usafirishaji' : 'Delivery Fee',
                  _isSwahili ? 'Itahesabiwa' : 'Calculated at order'),
              const Divider(height: 16),
              _costRow(
                  _isSwahili ? 'Jumla (takriban)' : 'Estimated Total',
                  'TZS ${_estimatedCost.toStringAsFixed(0)}+',
                  bold: true),
            ]),
          ),
          const SizedBox(height: 12),

          BudgetContextBanner(
            category: 'usafiri',
            paymentAmount: _estimatedCost,
            isSwahili: _isSwahili,
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isOrdering ? null : _placeOrder,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isOrdering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isSwahili ? 'Weka Agizo' : 'Place Order',
                      style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fuelOption(String value, String label, IconData icon) {
    final selected = _fuelType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _fuelType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? _kPrimary : Colors.grey.shade300),
          ),
          child: Column(children: [
            Icon(icon,
                size: 22, color: selected ? Colors.white : _kSecondary),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : _kSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }

  Widget _quantityBtn(int liters) {
    final isSelected = _litersCtrl.text == '$liters';
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => setState(() => _litersCtrl.text = '$liters'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _kPrimary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? _kPrimary : Colors.grey.shade300),
            ),
            child: Center(
              child: Text('${liters}L',
                  style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : _kPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _costRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: bold ? _kPrimary : _kSecondary,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
    );
  }
}
