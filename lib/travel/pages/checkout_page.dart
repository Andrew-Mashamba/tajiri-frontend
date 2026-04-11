import 'package:flutter/material.dart';
import '../../widgets/budget_context_banner.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/mode_icon.dart';
import 'booking_confirmation_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CheckoutPage extends StatefulWidget {
  final TransportOption option;
  final List<Passenger> passengers;
  final int userId;

  const CheckoutPage({
    super.key,
    required this.option,
    required this.passengers,
    required this.userId,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TravelService _service = TravelService();
  final TextEditingController _phoneController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.mpesa;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _needsPhone => _paymentMethod != PaymentMethod.wallet;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatPrice(double amount, String currency) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  Future<void> _onConfirm() async {
    if (_needsPhone && _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka nambari ya simu / Please enter phone number')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _service.createBooking(
        optionId: widget.option.id,
        userId: widget.userId,
        passengers: widget.passengers,
        paymentMethod: _paymentMethod,
        paymentPhone: _needsPhone ? _phoneController.text.trim() : null,
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (result.success && result.data != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationPage(booking: result.data!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Imeshindwa kubuking / Booking failed'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hitilafu imetokea / An error occurred: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final opt = widget.option;
    final total = opt.price.amount * widget.passengers.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Malipo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Checkout',
              style: TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Route summary card
          _buildRouteSummary(opt),
          const SizedBox(height: 16),

          // Passengers summary
          _buildPassengersSummary(),
          const SizedBox(height: 16),

          // Price breakdown
          _buildPriceBreakdown(opt, total),
          const SizedBox(height: 16),

          // Payment method
          _buildPaymentMethod(),

          // Phone number
          if (_needsPhone) ...[
            const SizedBox(height: 16),
            _buildPhoneInput(),
          ],

          const SizedBox(height: 16),
          BudgetContextBanner(
            category: 'usafiri',
            paymentAmount: total,
            isSwahili: true,
          ),

          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Thibitisha & Lipa / Confirm & Pay \u2014 ${_formatPrice(total, opt.price.currency)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSummary(TransportOption opt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ModeIcon(mode: opt.mode, size: 28, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${opt.origin.city} \u2192 ${opt.destination.city}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(opt.departure)} \u2022 ${_formatTime(opt.departure)} - ${_formatTime(opt.arrival)}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${opt.operator.name} \u2022 ${opt.mode.displayName} / ${opt.mode.subtitle}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Abiria / Passengers',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          ...widget.passengers.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    i == 0 ? Icons.person_rounded : Icons.person_outline_rounded,
                    size: 18,
                    color: _kSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.name.isNotEmpty ? p.name : 'Passenger ${i + 1}',
                      style: const TextStyle(fontSize: 14, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (i == 0)
                    const Text(
                      'Mkuu / Lead',
                      style: TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(TransportOption opt, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muhtasari wa Bei / Price Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          _priceRow(
            'Bei kwa kila abiria / Per passenger',
            _formatPrice(opt.price.amount, opt.price.currency),
          ),
          _priceRow(
            'Abiria / Passengers',
            '\u00d7 ${widget.passengers.length}',
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jumla / Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              Text(
                _formatPrice(total, opt.price.currency),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Njia ya Malipo / Payment Method',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          RadioGroup<PaymentMethod>(
            groupValue: _paymentMethod,
            onChanged: (v) { if (v != null) setState(() => _paymentMethod = v); },
            child: Column(
              children: PaymentMethod.values.map((method) {
                return RadioListTile<PaymentMethod>(
                  value: method,
                  title: Text(
                    method.displayName,
                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                  ),
                  activeColor: _kPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nambari ya Simu / Phone Number',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '0712 345 678',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
