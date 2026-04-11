// lib/my_cars/pages/add_car_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/my_cars_models.dart';
import '../services/my_cars_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AddCarPage extends StatefulWidget {
  final int userId;
  const AddCarPage({super.key, required this.userId});
  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  String _fuelType = 'petrol';
  bool _isSaving = false;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _colorCtrl.dispose();
    _engineCtrl.dispose();
    _vinCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final result = await MyCarsService.addCar({
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'year': int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
      'plate_number': _plateCtrl.text.trim().toUpperCase(),
      'fuel_type': _fuelType,
      if (_colorCtrl.text.isNotEmpty) 'color': _colorCtrl.text.trim(),
      if (_engineCtrl.text.isNotEmpty) 'engine_size': _engineCtrl.text.trim(),
      if (_vinCtrl.text.isNotEmpty) 'vin_number': _vinCtrl.text.trim(),
      if (_mileageCtrl.text.isNotEmpty)
        'mileage': double.tryParse(_mileageCtrl.text.trim()) ?? 0,
    });
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _isSwahili ? 'Gari limeongezwa!' : 'Car added successfully!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ??
              (_isSwahili ? 'Imeshindwa kuongeza gari' : 'Failed to add car'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Ongeza Gari' : 'Add Car',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_makeCtrl, _isSwahili ? 'Aina (Make)' : 'Make',
                required: true, hint: 'Toyota'),
            _field(_modelCtrl, _isSwahili ? 'Modeli' : 'Model',
                required: true, hint: 'Land Cruiser'),
            _field(_yearCtrl, _isSwahili ? 'Mwaka' : 'Year',
                required: true, hint: '2018', keyboard: TextInputType.number),
            _field(
                _plateCtrl,
                _isSwahili ? 'Nambari ya Usajili' : 'Plate Number',
                required: true,
                hint: 'T 123 ABC'),
            const SizedBox(height: 12),
            Text(_isSwahili ? 'Aina ya Mafuta' : 'Fuel Type',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                _fuelChip('petrol', _isSwahili ? 'Petroli' : 'Petrol'),
                _fuelChip('diesel', _isSwahili ? 'Dizeli' : 'Diesel'),
                _fuelChip('hybrid', _isSwahili ? 'Mseto' : 'Hybrid'),
                _fuelChip('electric', _isSwahili ? 'Umeme' : 'Electric'),
              ],
            ),
            const SizedBox(height: 12),
            _field(_colorCtrl, _isSwahili ? 'Rangi' : 'Color', hint: 'Nyeupe'),
            _field(_engineCtrl, _isSwahili ? 'Injini (cc)' : 'Engine Size',
                hint: '2500cc', keyboard: TextInputType.text),
            _field(_vinCtrl, 'VIN / Chassis Number',
                hint: 'JTDKN3DU5A0...'),
            _field(_mileageCtrl, _isSwahili ? 'Kilomita' : 'Mileage (km)',
                hint: '85000', keyboard: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isSwahili ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false,
      String? hint,
      TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? (_isSwahili ? 'Inahitajika' : 'Required')
                : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _fuelChip(String value, String label) {
    final selected = _fuelType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12,
          color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => setState(() => _fuelType = value),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _kPrimary : Colors.grey.shade300),
    );
  }
}
