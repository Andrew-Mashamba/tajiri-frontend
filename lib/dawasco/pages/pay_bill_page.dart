// lib/dawasco/pages/pay_bill_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/budget_context_banner.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PayBillPage extends StatefulWidget {
  final WaterBill bill;
  const PayBillPage({super.key, required this.bill});
  @override
  State<PayBillPage> createState() => _PayBillPageState();
}

class _PayBillPageState extends State<PayBillPage> {
  String _method = 'mpesa';
  final _phoneCtrl = TextEditingController();
  bool _paying = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _pay() async {
    final sw = _sw;
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Weka namba ya simu' : 'Enter phone number')));
      return;
    }
    setState(() => _paying = true);
    try {
      final result = await DawascoService.payBill(widget.bill.id, {
        'method': _method,
        'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() => _paying = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Malipo yamefanikiwa!' : 'Payment successful!')));
        Navigator.pop(context, true);
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(result.message ?? (sw ? 'Imeshindwa kulipa' : 'Payment failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final b = widget.bill;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Lipa Bili ya Maji' : 'Pay Water Bill',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Muhtasari wa Bili' : 'Bill Summary',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 12),
            _R(label: sw ? 'Kipindi' : 'Period', value: b.billingPeriod),
            const SizedBox(height: 6),
            _R(label: sw ? 'Matumizi' : 'Consumption', value: '${b.consumption.toStringAsFixed(1)} m\u00B3'),
            const SizedBox(height: 6),
            _R(label: sw ? 'Ada ya kudumu' : 'Standing charge', value: 'TZS ${b.standingCharge.toStringAsFixed(0)}'),
            const SizedBox(height: 6),
            _R(label: sw ? 'Ada ya matumizi' : 'Usage charge', value: 'TZS ${b.consumptionCharge.toStringAsFixed(0)}'),
            const Divider(height: 20),
            _R(label: sw ? 'Jumla' : 'Total', value: 'TZS ${b.totalAmount.toStringAsFixed(0)}', bold: true),
            const SizedBox(height: 8),
            _R(label: sw ? 'Tarehe ya mwisho' : 'Due date', value: '${b.dueDate.day}/${b.dueDate.month}/${b.dueDate.year}'),
          ]),
        ),
        const SizedBox(height: 16),

        // Phone number input
        Text(sw ? 'Namba ya Simu' : 'Phone Number',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: sw ? 'Mfano: 0712345678' : 'e.g. 0712345678',
            hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        const SizedBox(height: 16),

        // Payment method
        Text(sw ? 'Njia ya Malipo' : 'Payment Method',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        RadioGroup<String>(
          groupValue: _method,
          onChanged: (v) { if (v != null) setState(() => _method = v); },
          child: Column(children: [
            RadioListTile<String>(
              title: const Text('M-Pesa', style: TextStyle(fontSize: 14, color: _kPrimary)),
              value: 'mpesa', activeColor: _kPrimary, contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              title: const Text('Tigo Pesa', style: TextStyle(fontSize: 14, color: _kPrimary)),
              value: 'tigopesa', activeColor: _kPrimary, contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              title: const Text('Airtel Money', style: TextStyle(fontSize: 14, color: _kPrimary)),
              value: 'airtelmoney', activeColor: _kPrimary, contentPadding: EdgeInsets.zero,
            ),
          ]),
        ),
        const SizedBox(height: 12),
        BudgetContextBanner(
          category: 'umeme_maji',
          paymentAmount: b.totalAmount,
          isSwahili: sw,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48, width: double.infinity,
          child: ElevatedButton(
            onPressed: _paying ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _paying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('${sw ? 'Lipa' : 'Pay'} TZS ${b.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _R extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _R({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(child: Text(label,
          style: TextStyle(fontSize: 13, color: bold ? _kPrimary : _kSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      Text(value,
          style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}
