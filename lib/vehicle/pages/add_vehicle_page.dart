// lib/vehicle/pages/add_vehicle_page.dart
import 'package:flutter/material.dart';
import '../models/vehicle_models.dart';
import '../services/vehicle_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AddVehiclePage extends StatefulWidget {
  final int userId;
  const AddVehiclePage({super.key, required this.userId});
  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final VehicleService _service = VehicleService();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  FuelType _fuelType = FuelType.petrol;
  bool _isSaving = false;

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _colorCtrl.dispose();
    _engineCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final year = int.tryParse(_yearCtrl.text.trim());
    final plate = _plateCtrl.text.trim().toUpperCase();

    if (make.isEmpty || model.isEmpty || year == null || plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Jaza taarifa zote muhimu: Mtengenezaji, Aina, Mwaka, Namba ya Usajili')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final result = await _service.addVehicle(
      userId: widget.userId,
      make: make,
      model: model,
      year: year,
      plateNumber: plate,
      color: _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : null,
      engineSize:
          _engineCtrl.text.trim().isNotEmpty ? _engineCtrl.text.trim() : null,
      fuelType: _fuelType.name,
      mileage: double.tryParse(_mileageCtrl.text.trim()),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gari limeongezwa!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result.message ?? 'Imeshindwa kuongeza gari')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Ongeza Gari',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plate number (Tanzania format)
          const Text('Namba ya Usajili',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Muundo: T XXX ABC',
              style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 8),
          _field(_plateCtrl, 'Mfano: T 123 ABC',
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters),
          const SizedBox(height: 16),

          // Make
          const Text('Mtengenezaji',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          _field(_makeCtrl, 'Mfano: Toyota'),
          const SizedBox(height: 16),

          // Model
          const Text('Aina',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          _field(_modelCtrl, 'Mfano: Vitz'),
          const SizedBox(height: 16),

          // Year
          const Text('Mwaka',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          _field(_yearCtrl, 'Mfano: 2020',
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),

          // Fuel type
          const Text('Aina ya Mafuta',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          Row(
            children: FuelType.values.map((f) {
              final selected = _fuelType == f;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _fuelType = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : _kCardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(f.displayName,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  selected ? Colors.white : _kPrimary)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Color
          const Text('Rangi',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          _field(_colorCtrl, 'Mfano: Nyeupe'),
          const SizedBox(height: 16),

          // Engine size
          const Text('Ukubwa wa Injini',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          _field(_engineCtrl, 'Mfano: 1300cc'),
          const SizedBox(height: 16),

          // Mileage
          const Text('Maili / Kilomita',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          _field(_mileageCtrl, 'Mfano: 50000',
              keyboardType: TextInputType.number),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Hifadhi Gari',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType,
      TextCapitalization textCapitalization = TextCapitalization.none}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
        filled: true,
        fillColor: _kCardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
