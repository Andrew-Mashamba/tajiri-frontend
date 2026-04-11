// lib/vehicle/pages/fuel_log_page.dart
import 'package:flutter/material.dart';
import '../models/vehicle_models.dart';
import '../services/vehicle_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FuelLogPage extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;
  const FuelLogPage(
      {super.key, required this.vehicleId, required this.vehicleName});
  @override
  State<FuelLogPage> createState() => _FuelLogPageState();
}

class _FuelLogPageState extends State<FuelLogPage> {
  final VehicleService _service = VehicleService();
  final _litersCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();

  List<FuelLog> _logs = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    _mileageCtrl.dispose();
    _stationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final result = await _service.getFuelLogs(widget.vehicleId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _logs = result.items;
      });
    }
  }

  Future<void> _addLog() async {
    final liters = double.tryParse(_litersCtrl.text.trim());
    final price = double.tryParse(_priceCtrl.text.trim());
    if (liters == null || price == null || liters <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza lita na bei kwa lita')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final result = await _service.addFuelLog(
      vehicleId: widget.vehicleId,
      liters: liters,
      pricePerLiter: price,
      totalCost: liters * price,
      mileage: double.tryParse(_mileageCtrl.text.trim()),
      station:
          _stationCtrl.text.trim().isNotEmpty ? _stationCtrl.text.trim() : null,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imehifadhiwa!')),
        );
        _litersCtrl.clear();
        _priceCtrl.clear();
        _mileageCtrl.clear();
        _stationCtrl.clear();
        _loadLogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kuhifadhi')),
        );
      }
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = _logs.fold(0.0, (sum, l) => sum + l.totalCost);
    final totalLiters = _logs.fold(0.0, (sum, l) => sum + l.liters);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: Text('Mafuta — ${widget.vehicleName}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Add fuel form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ongeza Mafuta',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _field(_litersCtrl, 'Lita',
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(_priceCtrl, 'Bei/Lita (TZS)',
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(_mileageCtrl, 'Kilomita (hiari)',
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(_stationCtrl, 'Kituo (hiari)'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _addLog,
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
                        : const Text('Hifadhi'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          if (_logs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('TZS ${_fmtAmount(totalCost)}', 'Jumla'),
                  _stat('${totalLiters.toStringAsFixed(1)} L', 'Lita'),
                  _stat('${_logs.length}', 'Mara'),
                  if (totalLiters > 0)
                    _stat(
                        'TZS ${_fmtAmount(totalCost / totalLiters)}',
                        'Bei/L wastani'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // History
          const Text('Historia',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary)),
          const SizedBox(height: 10),

          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
          else if (_logs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Hakuna rekodi za mafuta bado',
                    style: TextStyle(color: _kSecondary)),
              ),
            )
          else
            ..._logs.map((l) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station_rounded,
                          size: 20, color: _kSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${l.liters.toStringAsFixed(1)} L @ TZS ${_fmtAmount(l.pricePerLiter)}/L',
                                style: const TextStyle(
                                    fontSize: 13, color: _kPrimary)),
                            if (l.station != null)
                              Text(l.station!,
                                  style: const TextStyle(
                                      fontSize: 11, color: _kSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TZS ${_fmtAmount(l.totalCost)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary)),
                          Text(_fmtDate(l.date),
                              style: const TextStyle(
                                  fontSize: 11, color: _kSecondary)),
                        ],
                      ),
                    ],
                  ),
                )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: _kSecondary)),
      ],
    );
  }
}
