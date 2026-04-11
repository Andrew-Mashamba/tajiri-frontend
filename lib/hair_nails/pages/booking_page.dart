// lib/hair_nails/pages/booking_page.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';
import '../services/hair_nails_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BookingPage extends StatefulWidget {
  final int userId;
  final Salon salon;
  final SalonService? preselectedService;
  const BookingPage({super.key, required this.userId, required this.salon, this.preselectedService});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final HairNailsService _service = HairNailsService();

  int _step = 0; // 0=service, 1=date/time, 2=confirm
  SalonService? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _paymentMethod = 'mpesa';
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselectedService;
    if (_selectedService != null) _step = 1;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _fmtDate(DateTime dt) {
    final days = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)), child: child!),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)), child: child!),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _confirmBooking() async {
    if (_selectedService == null) return;

    setState(() => _isBooking = true);
    final dateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final result = await _service.bookAppointment(
      userId: widget.userId,
      salonId: widget.salon.id,
      serviceId: _selectedService!.id,
      dateTime: dateTime,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      paymentMethod: _paymentMethod,
      phoneNumber: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : null,
    );

    if (mounted) {
      setState(() => _isBooking = false);
      if (result.success) {
        _showConfirmation(result.data!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa kubook'), backgroundColor: Colors.red));
      }
    }
  }

  void _showConfirmation(Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 32, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 16),
            const Text('Miadi Imewekwa!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 8),
            Text(booking.salonName, style: const TextStyle(fontSize: 14, color: _kSecondary)),
            Text(booking.serviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
            const SizedBox(height: 4),
            Text(_fmtDate(_selectedDate), style: const TextStyle(fontSize: 13, color: _kSecondary)),
            Text('Saa ${_selectedTime.format(context)}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
            const SizedBox(height: 4),
            Text('TZS ${_fmtPrice(booking.totalAmount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // booking page
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Sawa'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Weka Miadi', style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _stepDot(0, 'Huduma'),
                  Expanded(child: Container(height: 2, color: _step > 0 ? _kPrimary : _kPrimary.withValues(alpha: 0.15))),
                  _stepDot(1, 'Tarehe'),
                  Expanded(child: Container(height: 2, color: _step > 1 ? _kPrimary : _kPrimary.withValues(alpha: 0.15))),
                  _stepDot(2, 'Thibitisha'),
                ],
              ),
            ),

            Expanded(
              child: _step == 0
                  ? _buildServiceStep()
                  : _step == 1
                      ? _buildDateStep()
                      : _buildConfirmStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _step >= step;
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: isActive ? _kPrimary : _kPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text('${step + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : _kSecondary))),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: isActive ? _kPrimary : _kSecondary)),
      ],
    );
  }

  Widget _buildServiceStep() {
    final services = widget.salon.services;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Chagua Huduma — ${widget.salon.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 12),
        if (services.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Saluni hii haina huduma zilizoorodheshwa', style: TextStyle(color: _kSecondary))))
        else
          ...services.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: _selectedService?.id == s.id ? _kPrimary.withValues(alpha: 0.06) : _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() { _selectedService = s; _step = 1; }),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _selectedService?.id == s.id ? _kPrimary : Colors.transparent, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                                if (s.description != null) Text(s.description!, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text('${s.durationMinutes} dakika', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                              ],
                            ),
                          ),
                          Text('TZS ${_fmtPrice(s.price)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildDateStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Chagua Tarehe na Saa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 16),

        // Date picker
        Material(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: _kPrimary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tarehe', style: TextStyle(fontSize: 12, color: _kSecondary)),
                      Text(_fmtDate(_selectedDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: _kSecondary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Time picker
        Material(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: _kPrimary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saa', style: TextStyle(fontSize: 12, color: _kSecondary)),
                      Text(_selectedTime.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: _kSecondary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Notes
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Maelezo ya ziada (si lazima)...',
            hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
            filled: true,
            fillColor: _kCardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, side: const BorderSide(color: _kPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(0, 48)),
                  child: const Text('Rudi'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 2),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(0, 48)),
                child: const Text('Endelea'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Thibitisha Miadi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 16),

        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow('Saluni', widget.salon.name),
              _summaryRow('Huduma', _selectedService?.name ?? '-'),
              _summaryRow('Tarehe', _fmtDate(_selectedDate)),
              _summaryRow('Saa', _selectedTime.format(context)),
              _summaryRow('Muda', '${_selectedService?.durationMinutes ?? 0} dakika'),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumla', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                  Text('TZS ${_fmtPrice(_selectedService?.price ?? 0)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment method
        const Text('Njia ya Malipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        _paymentOption('mpesa', 'M-Pesa', Icons.phone_android_rounded),
        _paymentOption('wallet', 'TAJIRI Wallet', Icons.account_balance_wallet_rounded),
        _paymentOption('cash', 'Taslimu (Ulipe Saluni)', Icons.payments_outlined),

        if (_paymentMethod == 'mpesa') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Nambari ya M-Pesa (mfano: 0712345678)',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.phone_rounded, color: _kSecondary),
            ),
          ),
        ],
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, side: const BorderSide(color: _kPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(0, 52)),
                child: const Text('Rudi'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 52),
                  disabledBackgroundColor: _kSecondary,
                ),
                child: _isBooking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Thibitisha na Lipa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _paymentOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? _kPrimary.withValues(alpha: 0.06) : _kCardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _paymentMethod = value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? _kPrimary : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: _kPrimary),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontSize: 14, color: _kPrimary)),
                const Spacer(),
                if (isSelected) const Icon(Icons.check_circle_rounded, size: 20, color: _kPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
