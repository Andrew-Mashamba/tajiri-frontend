// lib/car_insurance/pages/file_claim_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/car_insurance_models.dart';
import '../services/car_insurance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FileClaimPage extends StatefulWidget {
  final List<InsurancePolicy> policies;
  const FileClaimPage({super.key, required this.policies});
  @override
  State<FileClaimPage> createState() => _FileClaimPageState();
}

class _FileClaimPageState extends State<FileClaimPage> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _policeCtrl = TextEditingController();
  int? _selectedPolicyId;
  String _claimType = 'accident';
  DateTime _incidentDate = DateTime.now();
  bool _isSaving = false;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    if (widget.policies.isNotEmpty) {
      _selectedPolicyId = widget.policies.first.id;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _policeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedPolicyId == null) return;
    setState(() => _isSaving = true);
    final result = await CarInsuranceService.fileClaim({
      'policy_id': _selectedPolicyId,
      'type': _claimType,
      'description': _descCtrl.text.trim(),
      'incident_date': _incidentDate.toIso8601String(),
      if (_amountCtrl.text.isNotEmpty)
        'claim_amount': double.tryParse(_amountCtrl.text.trim()),
      if (_policeCtrl.text.isNotEmpty)
        'police_report_number': _policeCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _isSwahili ? 'Dai limewasilishwa!' : 'Claim submitted!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ??
              (_isSwahili ? 'Imeshindwa' : 'Failed to submit claim'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Dai Bima' : 'File a Claim',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Policy selector
            Text(_isSwahili ? 'Chagua Bima' : 'Select Policy',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedPolicyId,
                  isExpanded: true,
                  items: widget.policies
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                                '${p.policyNumber} - ${p.vehicleDisplay}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPolicyId = v),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Claim type
            Text(_isSwahili ? 'Aina ya Dai' : 'Claim Type',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              _typeChip('accident', _isSwahili ? 'Ajali' : 'Accident'),
              _typeChip('theft', _isSwahili ? 'Wizi' : 'Theft'),
              _typeChip('fire', _isSwahili ? 'Moto' : 'Fire'),
              _typeChip('other', _isSwahili ? 'Nyingine' : 'Other'),
            ]),
            const SizedBox(height: 14),

            // Incident date
            Text(_isSwahili ? 'Tarehe ya Tukio' : 'Incident Date',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          '${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
                          style: const TextStyle(fontSize: 13))),
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: _kSecondary),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isSwahili ? 'Inahitajika' : 'Required')
                  : null,
              decoration: InputDecoration(
                labelText: _isSwahili ? 'Maelezo' : 'Description',
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _inputField(_amountCtrl,
                _isSwahili ? 'Kiasi (TZS)' : 'Claim Amount (TZS)',
                keyboard: TextInputType.number),
            _inputField(_policeCtrl,
                _isSwahili ? 'Nambari ya OB' : 'Police Report (OB Number)'),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
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
                    : Text(_isSwahili ? 'Wasilisha Dai' : 'Submit Claim',
                        style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = _claimType == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12, color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => setState(() => _claimType = value),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _kPrimary : Colors.grey.shade300),
    );
  }
}
