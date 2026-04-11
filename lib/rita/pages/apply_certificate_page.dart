// lib/rita/pages/apply_certificate_page.dart
import 'package:flutter/material.dart';
import '../models/rita_models.dart';
import '../services/rita_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ApplyCertificatePage extends StatefulWidget {
  final int userId;
  const ApplyCertificatePage({super.key, required this.userId});
  @override
  State<ApplyCertificatePage> createState() => _ApplyCertificatePageState();
}

class _ApplyCertificatePageState extends State<ApplyCertificatePage> {
  int _step = 0;
  CertificateType _type = CertificateType.birth;
  final _nameCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  DateTime? _dateOfEvent;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await RitaService.applyForCertificate({
      'type': _type.name,
      'holder_name': _nameCtrl.text.trim(),
      'place_of_event': _placeCtrl.text.trim(),
      'date_of_event': _dateOfEvent?.toIso8601String(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success && result.data != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ombi limewasilishwa: ${result.data!.trackingNumber}')),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuwasilisha')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfEvent = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Omba Cheti',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress
          Row(children: List.generate(3, (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= _step ? _kPrimary : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2)),
            ),
          ))),
          const SizedBox(height: 20),

          if (_step == 0) ...[
            const Text('Chagua Aina ya Cheti', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text('Select certificate type', style: TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 16),
            _TypeOption(label: 'Cheti cha Kuzaliwa', sublabel: 'Birth Certificate',
                icon: Icons.child_care_rounded, selected: _type == CertificateType.birth,
                onTap: () => setState(() => _type = CertificateType.birth)),
            const SizedBox(height: 8),
            _TypeOption(label: 'Cheti cha Kifo', sublabel: 'Death Certificate',
                icon: Icons.sentiment_very_dissatisfied_rounded, selected: _type == CertificateType.death,
                onTap: () => setState(() => _type = CertificateType.death)),
            const SizedBox(height: 8),
            _TypeOption(label: 'Cheti cha Ndoa', sublabel: 'Marriage Certificate',
                icon: Icons.favorite_rounded, selected: _type == CertificateType.marriage,
                onTap: () => setState(() => _type = CertificateType.marriage)),
            const SizedBox(height: 24),
            SizedBox(height: 48, width: double.infinity, child: ElevatedButton(
              onPressed: () => setState(() => _step = 1),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Endelea / Continue', style: TextStyle(color: Colors.white)),
            )),
          ] else if (_step == 1) ...[
            const Text('Taarifa za Mhusika', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 16),
            _buildField('Jina kamili / Full name', _nameCtrl),
            const SizedBox(height: 12),
            _buildField('Mahali / Place of event', _placeCtrl),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(child: Text(
                    _dateOfEvent != null
                        ? '${_dateOfEvent!.day}/${_dateOfEvent!.month}/${_dateOfEvent!.year}'
                        : 'Tarehe ya tukio / Date of event',
                    style: TextStyle(fontSize: 14,
                        color: _dateOfEvent != null ? _kPrimary : _kSecondary),
                  )),
                  const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Rudi', style: TextStyle(color: _kPrimary)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _nameCtrl.text.trim().isNotEmpty ? () => setState(() => _step = 2) : null,
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Endelea', style: TextStyle(color: Colors.white)),
              )),
            ]),
          ] else ...[
            const Text('Thibitisha / Confirm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SummaryRow(label: 'Aina', value: _type == CertificateType.birth ? 'Kuzaliwa' : _type == CertificateType.death ? 'Kifo' : 'Ndoa'),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Jina', value: _nameCtrl.text),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Mahali', value: _placeCtrl.text),
                if (_dateOfEvent != null) ...[
                  const SizedBox(height: 8),
                  _SummaryRow(label: 'Tarehe', value: '${_dateOfEvent!.day}/${_dateOfEvent!.month}/${_dateOfEvent!.year}'),
                ],
              ]),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _step = 1),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48),
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Rudi', style: TextStyle(color: _kPrimary)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Wasilisha', style: TextStyle(color: Colors.white)),
              )),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      style: const TextStyle(fontSize: 14, color: _kPrimary),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeOption({required this.label, required this.sublabel, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _kPrimary.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _kPrimary : const Color(0xFFE0E0E0), width: selected ? 2 : 1),
          ),
          child: Row(children: [
            Icon(icon, size: 24, color: _kPrimary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
              Text(sublabel, style: const TextStyle(fontSize: 12, color: _kSecondary)),
            ])),
            if (selected) const Icon(Icons.check_circle_rounded, size: 20, color: _kPrimary),
          ]),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}
