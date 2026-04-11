// lib/events/pages/organizer/payout_page.dart
import 'package:flutter/material.dart';
import '../../models/event_enums.dart';
import '../../models/event_strings.dart';
import '../../services/event_organizer_service.dart';
import '../../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PayoutPage extends StatefulWidget {
  final int eventId;

  const PayoutPage({super.key, required this.eventId});

  @override
  State<PayoutPage> createState() => _PayoutPageState();
}

class _PayoutPageState extends State<PayoutPage> {
  final _service = EventOrganizerService();
  final _phoneCtrl = TextEditingController();
  late EventStrings _strings;
  PaymentMethod _method = PaymentMethod.mpesa;
  bool _submitting = false;

  static const _mobileMethods = {
    PaymentMethod.mpesa,
    PaymentMethod.tigoPesa,
    PaymentMethod.airtelMoney,
    PaymentMethod.haloPesa,
  };

  bool get _requiresPhone => _mobileMethods.contains(_method);

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestPayout() async {
    if (_requiresPhone && _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request Payout'),
        content: Text('Request payout via ${_method.displayName}${_requiresPhone ? ' to ${_phoneCtrl.text.trim()}' : ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _submitting = true);
    final result = await _service.requestPayout(
      eventId: widget.eventId,
      method: _method,
      phoneNumber: _requiresPhone ? _phoneCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout request submitted successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to submit payout request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(_strings.requestPayout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 12),
              _MethodGrid(selected: _method, onSelect: (m) => setState(() => _method = m)),
              const SizedBox(height: 24),
              if (_requiresPhone) ...[
                const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: _kPrimary),
                  decoration: InputDecoration(
                    hintText: '+255 7XX XXX XXX',
                    hintStyle: const TextStyle(color: _kSecondary),
                    prefixIcon: const Icon(Icons.phone_rounded, color: _kSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ensure the number is registered with ${_method.displayName}.',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(height: 24),
              ],
              _InfoCard(method: _method),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _requestPayout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_strings.requestPayout, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodGrid extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelect;

  const _MethodGrid({required this.selected, required this.onSelect});

  static const _payoutMethods = [
    PaymentMethod.mpesa,
    PaymentMethod.tigoPesa,
    PaymentMethod.airtelMoney,
    PaymentMethod.haloPesa,
    PaymentMethod.wallet,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _payoutMethods.map((m) {
        final active = selected == m;
        return GestureDetector(
          onTap: () => onSelect(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? _kPrimary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? _kPrimary : Colors.black26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(m.icon, size: 18, color: active ? Colors.white : _kSecondary),
                const SizedBox(width: 6),
                Text(m.displayName, style: TextStyle(fontSize: 13, color: active ? Colors.white : _kPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PaymentMethod method;
  const _InfoCard({required this.method});

  @override
  Widget build(BuildContext context) {
    final isWallet = method == PaymentMethod.wallet;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: _kSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isWallet
                  ? 'Funds will be added to your TAJIRI Wallet balance within 24 hours.'
                  : 'Payouts are processed within 1-3 business days after event completion.',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
