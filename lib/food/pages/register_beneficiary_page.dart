import 'package:flutter/material.dart';

import '../models/beneficiary_org.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class RegisterBeneficiaryPage extends StatefulWidget {
  final int userId;
  const RegisterBeneficiaryPage({super.key, required this.userId});

  @override
  State<RegisterBeneficiaryPage> createState() => _RegisterBeneficiaryPageState();
}

class _RegisterBeneficiaryPageState extends State<RegisterBeneficiaryPage> {
  final _formKey = GlobalKey<FormState>();
  final FoodService _service = FoodService();

  BeneficiaryOrgType _type = BeneficiaryOrgType.jumuiya;
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _regNumber = TextEditingController();
  final _regAuthority = TextEditingController();
  final _region = TextEditingController();
  final _district = TextEditingController();
  final _ward = TextEditingController();
  final _street = TextEditingController();
  final _population = TextEditingController();
  final _mealsPerWeek = TextEditingController();
  final _phone = TextEditingController();
  bool _submitting = false;
  BeneficiaryOrg? _existing;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _regNumber, _regAuthority, _region, _district, _ward, _street, _population, _mealsPerWeek, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final res = await _service.getMyBeneficiaryOrg(widget.userId);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _existing = res.success ? res.data : null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final body = <String, dynamic>{
      'user_id': widget.userId,
      'name': _name.text.trim(),
      'type': _type.apiValue,
      if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
      if (_regNumber.text.trim().isNotEmpty) 'registration_number': _regNumber.text.trim(),
      if (_regAuthority.text.trim().isNotEmpty) 'registration_authority': _regAuthority.text.trim(),
      if (_region.text.trim().isNotEmpty) 'region': _region.text.trim(),
      if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
      if (_ward.text.trim().isNotEmpty) 'ward': _ward.text.trim(),
      if (_street.text.trim().isNotEmpty) 'street': _street.text.trim(),
      if (_population.text.trim().isNotEmpty) 'population_served': int.tryParse(_population.text.trim()),
      if (_mealsPerWeek.text.trim().isNotEmpty) 'meals_per_week': int.tryParse(_mealsPerWeek.text.trim()),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
    };

    final res = await _service.registerBeneficiaryOrg(body);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Imewasilishwa. Uhakiki unachukua hadi siku 3 za kazi.'),
      ));
      navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text('Sajili Shirika',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _existing != null
              ? _existingBanner(_existing!)
              : _formBody(),
    );
  }

  Widget _existingBanner(BeneficiaryOrg org) {
    String statusLabel;
    IconData icon;
    if (org.isVerified) {
      statusLabel = 'Imehakikiwa';
      icon = Icons.verified_rounded;
    } else if (org.isRejected) {
      statusLabel = 'Imekataliwa: ${org.rejectionReason ?? "—"}';
      icon = Icons.error_outline_rounded;
    } else {
      statusLabel = 'Inakaguliwa (hadi siku 3 za kazi)';
      icon = Icons.schedule_rounded;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(org.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(org.type.labelSwahili, style: const TextStyle(color: _kSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text(statusLabel, style: const TextStyle(color: _kSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _formBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Aina ya shirika'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BeneficiaryOrgType.values.map((t) {
              final sel = _type == t;
              return ChoiceChip(
                label: Text(t.labelSwahili),
                selected: sel,
                backgroundColor: _kCardBg,
                selectedColor: _kPrimary.withValues(alpha: 0.08),
                labelStyle: TextStyle(
                  color: sel ? _kPrimary : _kSecondary,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(color: _kPrimary.withValues(alpha: 0.08)),
                onSelected: (v) {
                  if (v) setState(() => _type = t);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _field(_name, 'Jina la shirika *', required: true),
          _field(_desc, 'Maelezo mafupi', maxLines: 3),
          _sectionLabel('Usajili'),
          const SizedBox(height: 8),
          _field(_regNumber, 'Nambari ya usajili'),
          _field(_regAuthority, 'Mamlaka ya usajili (BRELA, NGO Board, ...)'),
          _sectionLabel('Mahali'),
          const SizedBox(height: 8),
          _field(_region, 'Mkoa'),
          _field(_district, 'Wilaya'),
          _field(_ward, 'Kata'),
          _field(_street, 'Mtaa / alama'),
          _sectionLabel('Mpango wa huduma'),
          const SizedBox(height: 8),
          _field(_population, 'Idadi ya watu wanaolishwa', keyboard: TextInputType.number),
          _field(_mealsPerWeek, 'Milo kwa wiki', keyboard: TextInputType.number),
          _sectionLabel('Mawasiliano'),
          const SizedBox(height: 8),
          _field(_phone, 'Simu', keyboard: TextInputType.phone),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Wasilisha', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _kSecondary, letterSpacing: 0.6),
        ),
      );

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return 'Jaza sehemu hii';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: _kCardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}
