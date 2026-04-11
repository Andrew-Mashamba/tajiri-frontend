// lib/fungu_la_kumi/pages/give_now_page.dart
import 'package:flutter/material.dart';
import '../models/fungu_la_kumi_models.dart';
import '../services/fungu_la_kumi_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class GiveNowPage extends StatefulWidget {
  const GiveNowPage({super.key});
  @override
  State<GiveNowPage> createState() => _GiveNowPageState();
}

class _GiveNowPageState extends State<GiveNowPage> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  GivingType _type = GivingType.tithe;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toa Sasa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Give Now', style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  const Text('Kiasi / Amount (TSh)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _kPrimary),
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixText: 'TSh ',
                      prefixStyle: const TextStyle(fontSize: 18, color: _kSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick amounts
                  Row(
                    children: [5000, 10000, 50000, 100000].map((amt) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _amountCtrl.text = '$amt',
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              alignment: Alignment.center,
                              child: Text('${amt ~/ 1000}K',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Type
                  const Text('Aina / Type',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: GivingType.values.map((t) {
                      final sel = t == _type;
                      return GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? _kPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? _kPrimary : Colors.grey.shade300),
                          ),
                          child: Text(t.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: sel ? Colors.white : _kPrimary,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Note
                  const Text('Dokezo / Note (hiari)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Dokezo lolote...',
                      hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // M-Pesa info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.phone_android_rounded, size: 20, color: _kSecondary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Malipo kupitia M-Pesa / Payment via M-Pesa',
                              style: TextStyle(fontSize: 13, color: _kSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Toa Sasa / Give Now',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final r = await FunguLaKumiService.recordGiving({
      'amount': amount,
      'type': _type.name,
      'payment_method': 'mpesa',
      'note': _noteCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _saving = false);
      if (r.success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.message ?? 'Imeshindwa kutuma / Failed to submit')),
        );
      }
    }
  }
}
