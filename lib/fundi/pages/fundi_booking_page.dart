// lib/fundi/pages/fundi_booking_page.dart
import 'package:flutter/material.dart';
import '../models/fundi_models.dart';
import '../services/fundi_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FundiBookingPage extends StatefulWidget {
  final int userId;
  final Fundi fundi;

  const FundiBookingPage({super.key, required this.userId, required this.fundi});

  @override
  State<FundiBookingPage> createState() => _FundiBookingPageState();
}

class _FundiBookingPageState extends State<FundiBookingPage> {
  final FundiService _service = FundiService();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  ServiceCategory? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '09:00';
  bool _isBooking = false;

  final List<String> _timeSlots = [
    '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fundi.services.isNotEmpty) {
      _selectedService = widget.fundi.services.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali chagua huduma')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali eleza tatizo lako')),
      );
      return;
    }

    setState(() => _isBooking = true);

    final result = await _service.createBooking(
      userId: widget.userId,
      fundiId: widget.fundi.id,
      service: _selectedService!,
      scheduledDate: _selectedDate,
      scheduledTime: _selectedTime,
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      estimatedCost: widget.fundi.hourlyRate,
    );

    if (mounted) {
      setState(() => _isBooking = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nafasi imeagizwa! Fundi atawasiliana nawe.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kuagiza')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agiza Fundi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(widget.fundi.name, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Service selection
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Huduma', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.fundi.services.map((cat) {
                    final isSelected = _selectedService == cat;
                    return FilterChip(
                      label: Text(cat.displayName),
                      avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : _kPrimary),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedService = cat),
                      selectedColor: _kPrimary,
                      backgroundColor: _kCardBg,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : _kPrimary,
                      ),
                      side: BorderSide(color: isSelected ? _kPrimary : Colors.grey.shade300),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Date & time
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tarehe & Muda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 14, color: _kPrimary),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: _kSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _timeSlots.map((time) {
                      final isSelected = _selectedTime == time;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: isSelected ? _kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedTime = time),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? Colors.white : _kPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Eleza Tatizo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Eleza kwa ufupi tatizo au kazi inayohitajika...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Address
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Anwani', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Mahali fundi aje (mfano: Mikocheni B)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Agiza Fundi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
