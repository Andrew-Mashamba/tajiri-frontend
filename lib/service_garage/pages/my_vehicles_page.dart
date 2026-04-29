import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/customer_vehicle.dart';
import '../services/customer_vehicle_service.dart';
import '../services/vin_decode_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

class MyVehiclesPage extends StatefulWidget {
  final int userId;
  const MyVehiclesPage({super.key, required this.userId});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  bool _loading = true;
  String? _error;
  List<CustomerVehicle> _vehicles = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await CustomerVehicleService.list(userId: widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _vehicles = res.items;
        _error = null;
      } else {
        _error = res.message;
      }
    });
  }

  Future<void> _addOrEdit({CustomerVehicle? existing}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _VehicleDialog(
        userId: widget.userId,
        existing: existing,
        isSwahili: _isSwahili,
      ),
    );
    if (ok == true && mounted) _load();
  }

  Future<void> _delete(CustomerVehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa gari?' : 'Delete vehicle?'),
        content: Text(v.displayLabel),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await CustomerVehicleService.delete(
        id: v.id, userId: widget.userId);
    if (!mounted) return;
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSwahili ? 'Magari Yangu' : 'My Vehicles'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(child: Text(_error!))
              : _vehicles.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _vehicles.length,
                        itemBuilder: (_, i) => _vehicleRow(_vehicles[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_isSwahili ? 'Ongeza Gari' : 'Add Vehicle'),
      ),
    );
  }

  String _nextServiceLabel(CustomerVehicle v) {
    final sw = _isSwahili;
    final parts = <String>[];
    if (v.nextServiceAtKm != null) {
      parts.add('${NumberFormat('#,##0').format(v.nextServiceAtKm)} km');
    }
    if (v.nextServiceAtDate != null) {
      parts.add(DateFormat('d MMM').format(v.nextServiceAtDate!.toLocal()));
    }
    final tail = parts.join(' • ');
    return sw ? 'Huduma ijayo: $tail' : 'Next service: $tail';
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_rounded, size: 56, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _isSwahili ? 'Hakuna gari bado' : 'No vehicles yet',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _isSwahili
                  ? 'Sajili gari lako kuokoa bidhaa ya huduma kati ya kazi.'
                  : 'Register your vehicle to keep a service history book.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleRow(CustomerVehicle v) {
    final hasRecalls = v.openRecalls.isNotEmpty;
    final nextKm = v.nextServiceAtKm;
    final nextDate = v.nextServiceAtDate;
    final hasPrediction = nextKm != null || nextDate != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _kBorder),
      ),
      child: ListTile(
        isThreeLine: hasRecalls || hasPrediction,
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _kPrimary.withValues(alpha: 0.06),
          backgroundImage: v.photoUrl != null && v.photoUrl!.isNotEmpty
              ? NetworkImage(v.photoUrl!)
              : null,
          child: v.photoUrl == null || v.photoUrl!.isEmpty
              ? const Icon(Icons.directions_car_rounded, color: _kPrimary)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(v.displayLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
            ),
            if (v.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _isSwahili ? 'Msingi' : 'Default',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                if (v.color != null) v.color,
                if (v.mileageKm != null) '${NumberFormat('#,##0').format(v.mileageKm)} km',
                if (v.vin != null && v.vin!.isNotEmpty) 'VIN: ${v.vin}',
              ].whereType<String>().join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
            if (hasPrediction) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 11, color: _kPrimary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _nextServiceLabel(v),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (hasRecalls) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 11, color: Color(0xFFB71C1C)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _isSwahili
                            ? 'Recall ${v.openRecalls.length} wazi'
                            : '${v.openRecalls.length} open recall${v.openRecalls.length > 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB71C1C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (k) {
            if (k == 'edit') _addOrEdit(existing: v);
            if (k == 'history') Navigator.push(context, MaterialPageRoute(
              builder: (_) => VehicleServiceHistoryPage(userId: widget.userId, vehicle: v),
            ));
            if (k == 'delete') _delete(v);
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'history', child: Text(_isSwahili ? 'Historia ya kazi' : 'Service history')),
            PopupMenuItem(value: 'edit', child: Text(_isSwahili ? 'Hariri' : 'Edit')),
            PopupMenuItem(value: 'delete', child: Text(_isSwahili ? 'Futa' : 'Delete')),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => VehicleServiceHistoryPage(userId: widget.userId, vehicle: v),
        )),
      ),
    );
  }
}

class _VehicleDialog extends StatefulWidget {
  final int userId;
  final CustomerVehicle? existing;
  final bool isSwahili;
  const _VehicleDialog({required this.userId, required this.existing, required this.isSwahili});
  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  late final TextEditingController _plate, _make, _model, _year, _vin, _mileage, _color;
  bool _isDefault = false;
  bool _saving = false;
  bool _vinDecoding = false;

  Future<void> _decodeVin() async {
    final vin = _vin.text.trim();
    if (vin.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili
            ? 'VIN inahitaji herufi 11+'
            : 'VIN needs 11+ chars'),
      ));
      return;
    }
    setState(() => _vinDecoding = true);
    final res = await VinDecodeService.decode(vin);
    if (!mounted) return;
    setState(() => _vinDecoding = false);
    if (res == null || !res.hasUsefulData) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili
            ? 'VIN haijatambulika'
            : 'VIN not recognised'),
      ));
      return;
    }
    setState(() {
      if (_make.text.trim().isEmpty && (res.make ?? '').isNotEmpty) {
        _make.text = res.make!;
      }
      if (_model.text.trim().isEmpty && (res.model ?? '').isNotEmpty) {
        _model.text = res.model!;
      }
      if (_year.text.trim().isEmpty && res.year != null) {
        _year.text = '${res.year}';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.isSwahili
          ? 'Imejazwa: ${res.make ?? '?'} ${res.model ?? ''} ${res.year ?? ''}'
          : 'Decoded: ${res.make ?? '?'} ${res.model ?? ''} ${res.year ?? ''}'),
    ));
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _plate = TextEditingController(text: e?.plate ?? '');
    _make = TextEditingController(text: e?.make ?? '');
    _model = TextEditingController(text: e?.model ?? '');
    _year = TextEditingController(text: e?.year?.toString() ?? '');
    _vin = TextEditingController(text: e?.vin ?? '');
    _mileage = TextEditingController(text: e?.mileageKm?.toString() ?? '');
    _color = TextEditingController(text: e?.color ?? '');
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _plate.dispose(); _make.dispose(); _model.dispose();
    _year.dispose(); _vin.dispose(); _mileage.dispose(); _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_plate.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final svc = widget.existing == null
        ? CustomerVehicleService.create(
            userId: widget.userId,
            plate: _plate.text.trim(),
            make: _make.text.trim().isEmpty ? null : _make.text.trim(),
            model: _model.text.trim().isEmpty ? null : _model.text.trim(),
            year: int.tryParse(_year.text.trim()),
            vin: _vin.text.trim().isEmpty ? null : _vin.text.trim(),
            mileageKm: int.tryParse(_mileage.text.replaceAll(',', '').trim()),
            color: _color.text.trim().isEmpty ? null : _color.text.trim(),
            isDefault: _isDefault,
          )
        : CustomerVehicleService.update(
            id: widget.existing!.id,
            userId: widget.userId,
            plate: _plate.text.trim(),
            make: _make.text.trim(),
            model: _model.text.trim(),
            year: int.tryParse(_year.text.trim()),
            vin: _vin.text.trim(),
            mileageKm: int.tryParse(_mileage.text.replaceAll(',', '').trim()),
            color: _color.text.trim(),
            isDefault: _isDefault,
          );
    final res = await svc;
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (widget.isSwahili ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return AlertDialog(
      title: Text(widget.existing == null
          ? (sw ? 'Ongeza Gari' : 'Add Vehicle')
          : (sw ? 'Hariri Gari' : 'Edit Vehicle')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: sw ? 'Namba ya gari *' : 'Plate *', border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: TextField(controller: _make, decoration: InputDecoration(labelText: sw ? 'Aina (Toyota, Mazda...)' : 'Make', border: const OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 6),
              Expanded(child: TextField(controller: _model, decoration: InputDecoration(labelText: sw ? 'Model' : 'Model', border: const OutlineInputBorder(), isDense: true))),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: TextField(
                controller: _year,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: sw ? 'Mwaka' : 'Year', border: const OutlineInputBorder(), isDense: true),
              )),
              const SizedBox(width: 6),
              Expanded(child: TextField(
                controller: _color,
                decoration: InputDecoration(labelText: sw ? 'Rangi' : 'Color', border: const OutlineInputBorder(), isDense: true),
              )),
            ]),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vin,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'VIN',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _vinDecoding
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: sw ? 'Tafuta kupitia VIN' : 'Decode VIN',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _vinDecoding ? null : _decodeVin,
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _mileage,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: sw ? 'Mileage (km)' : 'Mileage (km)', border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: Text(sw ? 'Gari la msingi' : 'Default vehicle',
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(sw ? 'Funga' : 'Close')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(sw ? 'Hifadhi' : 'Save'),
        ),
      ],
    );
  }
}

class VehicleServiceHistoryPage extends StatefulWidget {
  final int userId;
  final CustomerVehicle vehicle;
  const VehicleServiceHistoryPage({super.key, required this.userId, required this.vehicle});

  @override
  State<VehicleServiceHistoryPage> createState() =>
      _VehicleServiceHistoryPageState();
}

class _VehicleServiceHistoryPageState extends State<VehicleServiceHistoryPage> {
  ServiceHistoryResult? _result;
  bool _loading = true;
  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await CustomerVehicleService.serviceHistory(
        vehicleId: widget.vehicle.id, userId: widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = _result?.vehicle ?? widget.vehicle;
    final bookings = _result?.bookings ?? const <VehicleServiceHistoryEntry>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(v.displayLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              child: bookings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _isSwahili
                              ? 'Hakuna kazi za nyuma kwa gari hili.'
                              : 'No past service for this vehicle.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _kSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: bookings.length,
                      itemBuilder: (_, i) => _entryRow(bookings[i]),
                    ),
            ),
    );
  }

  Widget _entryRow(VehicleServiceHistoryEntry e) {
    final cost = e.finalCostTzs ?? e.costCapTzs;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _kBorder),
      ),
      child: ListTile(
        title: Text(e.faultSummary ?? '—',
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [
            e.partnerName,
            if (e.completedAt != null)
              DateFormat('d MMM y').format(e.completedAt!.toLocal())
            else if (e.createdAt != null)
              DateFormat('d MMM y').format(e.createdAt!.toLocal()),
            e.status,
          ].whereType<String>().join(' • '),
          style: const TextStyle(fontSize: 11, color: _kSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: cost == null
            ? null
            : Text('TZS ${NumberFormat('#,##0').format(cost)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
    );
  }
}
