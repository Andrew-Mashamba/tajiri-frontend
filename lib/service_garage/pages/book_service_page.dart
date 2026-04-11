// lib/service_garage/pages/book_service_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/service_garage_models.dart';
import '../services/service_garage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BookServicePage extends StatefulWidget {
  final Garage garage;
  const BookServicePage({super.key, required this.garage});
  @override
  State<BookServicePage> createState() => _BookServicePageState();
}

class _BookServicePageState extends State<BookServicePage> {
  final _descCtrl = TextEditingController();
  String _serviceType = 'oil_change';
  DateTime _appointmentDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;
  late final bool _isSwahili;

  final _serviceTypes = const [
    ('oil_change', 'Mafuta ya Injini', 'Oil Change'),
    ('full_service', 'Huduma Kamili', 'Full Service'),
    ('brake_service', 'Breki', 'Brake Service'),
    ('tire_service', 'Matairi', 'Tire Service'),
    ('ac_service', 'AC', 'AC Service'),
    ('electrical', 'Umeme', 'Electrical'),
    ('body_work', 'Bodi', 'Body Work'),
    ('diagnostic', 'Uchunguzi', 'Diagnostic'),
    ('other', 'Nyingine', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && mounted) {
      setState(() => _appointmentDate = picked);
    }
  }

  Future<void> _book() async {
    setState(() => _isSaving = true);
    final result = await ServiceGarageService.bookService({
      'garage_id': widget.garage.id,
      'service_type': _serviceType,
      'appointment_date': _appointmentDate.toIso8601String(),
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _isSwahili ? 'Miadi imewekwa!' : 'Booking confirmed!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ??
              (_isSwahili ? 'Imeshindwa' : 'Failed to book'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Weka Miadi' : 'Book Service',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Garage info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              const Icon(Icons.build_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.garage.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (widget.garage.address != null)
                        Text(widget.garage.address!,
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Service type
          Text(_isSwahili ? 'Aina ya Huduma' : 'Service Type',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _serviceTypes
                .map((t) => _serviceChip(
                    t.$1, _isSwahili ? t.$2 : t.$3))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Date
          Text(_isSwahili ? 'Tarehe ya Miadi' : 'Appointment Date',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Expanded(
                    child: Text(
                        '${_appointmentDate.day}/${_appointmentDate.month}/${_appointmentDate.year}',
                        style: const TextStyle(fontSize: 13))),
                const Icon(Icons.calendar_today_rounded,
                    size: 18, color: _kSecondary),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(_isSwahili ? 'Maelezo ya Tatizo' : 'Problem Description',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _isSwahili
                  ? 'Eleza tatizo la gari lako...'
                  : 'Describe your car problem...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              onPressed: _isSaving ? null : _book,
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
                      _isSwahili
                          ? 'Thibitisha Miadi'
                          : 'Confirm Booking',
                      style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceChip(String value, String label) {
    final selected = _serviceType == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 11, color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => setState(() => _serviceType = value),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _kPrimary : Colors.grey.shade300),
    );
  }
}
