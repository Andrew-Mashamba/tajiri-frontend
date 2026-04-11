// lib/nightlife/pages/reserve_table_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/nightlife_models.dart';
import '../services/nightlife_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ReserveTablePage extends StatefulWidget {
  final List<Venue> venues;
  const ReserveTablePage({super.key, required this.venues});
  @override
  State<ReserveTablePage> createState() => _ReserveTablePageState();
}

class _ReserveTablePageState extends State<ReserveTablePage> {
  bool _isSwahili = true;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  int? _selectedVenueId;
  DateTime _selectedDate = DateTime.now();
  String _time = '20:00';
  int _guests = 2;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    if (widget.venues.isNotEmpty) {
      _selectedVenueId = widget.venues.first.id;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedVenueId == null) return;
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await NightlifeService.reserveTable({
      'venue_id': _selectedVenueId,
      'date': _selectedDate.toIso8601String().substring(0, 10),
      'time': _time,
      'guests': _guests,
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            _isSwahili ? 'Nafasi imewekwa!' : 'Table reserved!'),
      ));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')));
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Weka Nafasi' : 'Reserve Table',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(_isSwahili ? 'Mahali' : 'Venue'),
            DropdownButtonFormField<int>(
              value: _selectedVenueId,
              decoration: _dec(''),
              items: widget.venues
                  .map((v) => DropdownMenuItem(
                      value: v.id, child: Text(v.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedVenueId = v),
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Tarehe' : 'Date'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: _kPrimary),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate.toString().substring(0, 10),
                      style:
                          const TextStyle(fontSize: 14, color: _kPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Saa' : 'Time'),
            DropdownButtonFormField<String>(
              value: _time,
              decoration: _dec(''),
              items: ['18:00', '19:00', '20:00', '21:00', '22:00', '23:00']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _time = v ?? '20:00'),
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Wageni' : 'Guests'),
            DropdownButtonFormField<int>(
              value: _guests,
              decoration: _dec(''),
              items: List.generate(10, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) => setState(() => _guests = v ?? 2),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isSwahili ? 'Weka Nafasi' : 'Reserve'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
      );
}
