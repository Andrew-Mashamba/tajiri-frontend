// lib/doctor/pages/book_appointment_page.dart
import 'package:flutter/material.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';
import 'consent_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BookAppointmentPage extends StatefulWidget {
  final int userId;
  final Doctor doctor;
  const BookAppointmentPage({super.key, required this.userId, required this.doctor});
  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final DoctorService _service = DoctorService();
  final _reasonController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _phoneController = TextEditingController();

  ConsultationType _selectedType = ConsultationType.video;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _symptomsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali andika sababu ya mashauriano')),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza nambari ya M-Pesa')),
      );
      return;
    }

    // Navigate to consent page first
    final consented = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ConsentPage()),
    );

    if (consented != true || !mounted) return;

    setState(() => _isSubmitting = true);

    final scheduledAt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final result = await _service.bookAppointment(
      patientId: widget.userId,
      doctorId: widget.doctor.id,
      type: _selectedType,
      scheduledAt: scheduledAt,
      reason: _reasonController.text.trim(),
      symptoms: _symptomsController.text.trim().isNotEmpty ? _symptomsController.text.trim() : null,
      paymentMethod: 'mobile_money',
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miadi imewekwa! Thibitisha malipo kwenye simu yako.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuweka miadi'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Weka Miadi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Doctor summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(doc.initials, style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dk. ${doc.fullName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                      Text(doc.specialty.displayName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    ],
                  ),
                ),
                Text('TZS ${_fmt(doc.consultationFee)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Consultation type
          const Text('Aina ya Mashauriano', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 10),
          Row(
            children: ConsultationType.values.map((type) {
              final isSelected = _selectedType == type;
              final enabled = (type == ConsultationType.video && doc.acceptsVideo) ||
                  (type == ConsultationType.audio && doc.acceptsAudio) ||
                  (type == ConsultationType.chat && doc.acceptsChat);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: type != ConsultationType.chat ? 8 : 0),
                  child: GestureDetector(
                    onTap: enabled ? () => setState(() => _selectedType = type) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimary : (enabled ? _kCardBg : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? _kPrimary : const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type == ConsultationType.video ? Icons.videocam_rounded
                                : type == ConsultationType.audio ? Icons.phone_rounded
                                : Icons.chat_rounded,
                            color: isSelected ? Colors.white : (enabled ? _kPrimary : Colors.grey),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type == ConsultationType.video ? 'Video'
                                : type == ConsultationType.audio ? 'Simu'
                                : 'Ujumbe',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : (enabled ? _kPrimary : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Date & time
          const Text('Tarehe na Saa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCardBg, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCardBg, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: _kSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reason
          const Text('Sababu ya Mashauriano *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Mfano: Maumivu ya kichwa ya mara kwa mara',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Symptoms (optional)
          const Text('Dalili (Hiari)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _symptomsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Eleza dalili zako...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 20),

          // Payment
          const Text('Nambari ya M-Pesa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '0712 345 678',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.phone_outlined, color: _kSecondary),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Lipa TZS ${_fmt(doc.consultationFee)} na Weka Miadi', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
