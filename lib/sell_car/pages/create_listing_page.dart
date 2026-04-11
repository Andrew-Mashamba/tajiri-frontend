// lib/sell_car/pages/create_listing_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/sell_car_models.dart';
import '../services/sell_car_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});
  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _fuelType = 'petrol';
  String _transmission = 'automatic';
  String _condition = 'good';
  bool _isSaving = false;
  PriceSuggestion? _suggestion;
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
    _priceCtrl.dispose();
    _mileageCtrl.dispose();
    _engineCtrl.dispose();
    _colorCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _getSuggestion() async {
    if (_makeCtrl.text.isEmpty || _modelCtrl.text.isEmpty) return;
    final r = await SellCarService.getPriceSuggestion(
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
      mileage: double.tryParse(_mileageCtrl.text.trim()) ?? 0,
      condition: _condition,
    );
    if (mounted && r.success) setState(() => _suggestion = r.data);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final result = await SellCarService.createListing({
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'year': int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
      'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
      'mileage': double.tryParse(_mileageCtrl.text.trim()) ?? 0,
      'fuel_type': _fuelType,
      'transmission': _transmission,
      'condition': _condition,
      if (_engineCtrl.text.isNotEmpty) 'engine_size': _engineCtrl.text.trim(),
      if (_colorCtrl.text.isNotEmpty) 'color': _colorCtrl.text.trim(),
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text.trim(),
      if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Tangazo limeundwa!'
              : 'Listing created!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ??
              (_isSwahili ? 'Imeshindwa' : 'Failed to create'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
            _isSwahili ? 'Unda Tangazo' : 'Create Listing',
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
            Row(children: [
              Expanded(
                  child: _field(_yearCtrl, _isSwahili ? 'Mwaka' : 'Year',
                      required: true,
                      hint: '2018',
                      keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: _field(
                      _mileageCtrl, _isSwahili ? 'Km' : 'Mileage',
                      required: true,
                      hint: '85000',
                      keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 8),
            Text(_isSwahili ? 'Hali' : 'Condition',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              _condChip('excellent',
                  _isSwahili ? 'Bora' : 'Excellent'),
              _condChip('good', _isSwahili ? 'Nzuri' : 'Good'),
              _condChip('fair', _isSwahili ? 'Wastani' : 'Fair'),
              _condChip('poor', _isSwahili ? 'Mbaya' : 'Poor'),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isSwahili ? 'Mafuta' : 'Fuel',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, children: [
                        _fuelChip('petrol', 'Petrol'),
                        _fuelChip('diesel', 'Diesel'),
                      ]),
                    ]),
              ),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isSwahili ? 'Gia' : 'Transmission',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, children: [
                        _transChip('automatic', 'Auto'),
                        _transChip('manual', 'Manual'),
                      ]),
                    ]),
              ),
            ]),
            const SizedBox(height: 12),
            _field(_engineCtrl, _isSwahili ? 'Injini (cc)' : 'Engine',
                hint: '2500cc'),
            _field(_colorCtrl, _isSwahili ? 'Rangi' : 'Color',
                hint: 'Nyeupe'),
            _field(_locationCtrl, _isSwahili ? 'Mahali' : 'Location',
                hint: 'Dar es Salaam'),

            // Price suggestion
            TextButton.icon(
              onPressed: _getSuggestion,
              icon: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: _kPrimary),
              label: Text(
                  _isSwahili ? 'Pata Bei Pendekezi' : 'Get Price Suggestion',
                  style: const TextStyle(fontSize: 12, color: _kPrimary)),
            ),
            if (_suggestion != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(children: [
                  _priceRow(
                      _isSwahili ? 'Uza Haraka' : 'Quick Sale',
                      'TZS ${_suggestion!.quickSalePrice.toStringAsFixed(0)}'),
                  _priceRow(_isSwahili ? 'Bei ya Haki' : 'Fair Price',
                      'TZS ${_suggestion!.fairPrice.toStringAsFixed(0)}'),
                  _priceRow(
                      _isSwahili ? 'Matumaini' : 'Optimistic',
                      'TZS ${_suggestion!.optimisticPrice.toStringAsFixed(0)}'),
                ]),
              ),
            _field(_priceCtrl, _isSwahili ? 'Bei (TZS)' : 'Price (TZS)',
                required: true,
                hint: '35000000',
                keyboard: TextInputType.number),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _isSwahili ? 'Maelezo' : 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
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
                    : Text(
                        _isSwahili ? 'Chapisha Tangazo' : 'Publish Listing',
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
      padding: const EdgeInsets.only(bottom: 10),
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
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _condChip(String value, String label) {
    final sel = _condition == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 11, color: sel ? Colors.white : _kPrimary)),
      selected: sel,
      onSelected: (_) => setState(() => _condition = value),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: sel ? _kPrimary : Colors.grey.shade300),
    );
  }

  Widget _fuelChip(String value, String label) {
    final sel = _fuelType == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 11, color: sel ? Colors.white : _kPrimary)),
      selected: sel,
      onSelected: (_) => setState(() => _fuelType = value),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: sel ? _kPrimary : Colors.grey.shade300),
    );
  }

  Widget _transChip(String value, String label) {
    final sel = _transmission == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 11, color: sel ? Colors.white : _kPrimary)),
      selected: sel,
      onSelected: (_) => setState(() => _transmission = value),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: sel ? _kPrimary : Colors.grey.shade300),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
          ]),
    );
  }
}
