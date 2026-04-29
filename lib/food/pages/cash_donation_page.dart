import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/beneficiary_org.dart';
import '../services/food_service.dart';
import 'donation_receipt_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kBorder = Color(0xFFE0E0E0);

class CashDonationPage extends StatefulWidget {
  final int userId;
  final BeneficiaryOrg org;
  final bool institutional;
  final bool prefillZaka;
  final bool prefillFungu;
  const CashDonationPage({
    super.key,
    required this.userId,
    required this.org,
    this.institutional = false,
    this.prefillZaka = false,
    this.prefillFungu = false,
  });

  @override
  State<CashDonationPage> createState() => _CashDonationPageState();
}

class _CashDonationPageState extends State<CashDonationPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = FoodService();

  final _amountCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _orgNameCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _paymentRefCtrl = TextEditingController();

  String _paymentMethod = 'mpesa';
  late bool _zaka = widget.prefillZaka;
  late bool _fungu = widget.prefillFungu;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _purposeCtrl.dispose();
    _orgNameCtrl.dispose();
    _regNumCtrl.dispose();
    _contactPersonCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    _paymentRefCtrl.dispose();
    super.dispose();
  }

  bool get _isInstitutional => widget.institutional;

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0;
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiasi kidogo sana')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);

    final result = await _service.createCashDonation(
      donorUserId: widget.userId,
      orgId: widget.org.id,
      amount: amount,
      donorType: _isInstitutional ? 'institution' : 'individual',
      organizationName: _isInstitutional ? _orgNameCtrl.text.trim() : null,
      registrationNumber: _isInstitutional && _regNumCtrl.text.trim().isNotEmpty
          ? _regNumCtrl.text.trim()
          : null,
      contactPerson: _isInstitutional && _contactPersonCtrl.text.trim().isNotEmpty
          ? _contactPersonCtrl.text.trim()
          : null,
      contactPhone: _contactPhoneCtrl.text.trim().isEmpty ? null : _contactPhoneCtrl.text.trim(),
      contactEmail: _contactEmailCtrl.text.trim().isEmpty ? null : _contactEmailCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      paymentReference: _paymentRefCtrl.text.trim().isEmpty ? null : _paymentRefCtrl.text.trim(),
      zakaTagged: _zaka,
      funguLaKumiTagged: _fungu,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success && result.data != null) {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => DonationReceiptPage(donation: result.data!, userId: widget.userId),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kukamilisha mchango')),
      );
    }
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kSecondary),
        filled: true,
        fillColor: _kCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary),
        ),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary, letterSpacing: 0.2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final methods = const [
      ('mpesa', 'M-Pesa'),
      ('tigopesa', 'Tigo Pesa'),
      ('airtelmoney', 'Airtel Money'),
      ('halopesa', 'HaloPesa'),
      ('wallet', 'Pochi ya TAJIRI'),
      ('bank', 'Benki'),
    ];
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isInstitutional ? 'Tumikia kikundi' : 'Changia ${widget.org.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism_rounded, color: _kPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.org.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          _isInstitutional
                              ? 'Mchango wa kampuni au kikundi kwa kikundi hiki'
                              : 'Utapokea risiti mara baada ya malipo',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _sectionHeader('Kiasi'),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _dec('Kiasi (TZS)', hint: 'k.m. 500000'),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', ''));
                if (n == null || n < 100) return 'Ingiza kiasi cha angalau TZS 100';
                return null;
              },
            ),
            if (_isInstitutional) ...[
              _sectionHeader('Taarifa za kampuni/kikundi'),
              TextFormField(
                controller: _orgNameCtrl,
                decoration: _dec('Jina la kampuni/kikundi', hint: 'k.m. CRDB Bank PLC'),
                validator: (v) {
                  if (!_isInstitutional) return null;
                  if ((v ?? '').trim().isEmpty) return 'Jina la kampuni linahitajika';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _regNumCtrl,
                decoration: _dec('Namba ya usajili (hiari)', hint: 'k.m. 12345-XYZ'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contactPersonCtrl,
                decoration: _dec('Mwasiliani (hiari)', hint: 'Jina kamili'),
              ),
            ],
            _sectionHeader('Mawasiliano'),
            TextFormField(
              controller: _contactPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec('Simu (hiari)', hint: '+255...'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contactEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('Barua pepe (hiari)', hint: 'risiti@kampuni.co.tz'),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return null;
                if (!s.contains('@') || !s.contains('.')) return 'Barua pepe si sahihi';
                return null;
              },
            ),
            _sectionHeader('Madhumuni'),
            TextFormField(
              controller: _purposeCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: _dec('Maelezo ya mchango (hiari)',
                  hint: 'k.m. Chakula cha watoto yatima kwa mwezi huu'),
            ),
            _sectionHeader('Njia ya malipo'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: methods.map((m) {
                final picked = _paymentMethod == m.$1;
                return ChoiceChip(
                  label: Text(m.$2),
                  selected: picked,
                  onSelected: (_) => setState(() => _paymentMethod = m.$1),
                  selectedColor: _kPrimary,
                  backgroundColor: _kCard,
                  side: const BorderSide(color: _kBorder),
                  labelStyle: TextStyle(
                    color: picked ? Colors.white : _kPrimary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _paymentRefCtrl,
              decoration: _dec('Rejea ya malipo (hiari)', hint: 'k.m. QE1234ABCD'),
            ),
            _sectionHeader('Alamisho'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _zaka,
              onChanged: (v) => setState(() => _zaka = v),
              activeThumbColor: _kAccent,
              title: const Text('Weka kama zaka', style: TextStyle(color: _kPrimary, fontSize: 14)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _fungu,
              onChanged: (v) => setState(() => _fungu = v),
              activeThumbColor: _kAccent,
              title: const Text('Weka kama fungu la kumi', style: TextStyle(color: _kPrimary, fontSize: 14)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_rounded, color: Colors.white),
                label: Text(_submitting ? 'Inatumwa...' : 'Lipa na pokea risiti',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
