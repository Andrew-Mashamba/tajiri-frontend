import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F7 #60 — Legal "draft + lawyer review" two-tier flow.
class LegalDraftThenReviewPage extends StatefulWidget {
  final int userId;
  const LegalDraftThenReviewPage({super.key, required this.userId});

  @override
  State<LegalDraftThenReviewPage> createState() => _LegalDraftThenReviewPageState();
}

class _LegalDraftThenReviewPageState extends State<LegalDraftThenReviewPage> {
  String _docType = 'employment_contract';
  final _party1 = TextEditingController();
  final _party2 = TextEditingController();
  final _termsCtrl = TextEditingController();
  bool _submitting = false;
  Map<String, dynamic>? _result;
  int? _orderId;

  @override
  void dispose() {
    _party1.dispose();
    _party2.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final res = await LegalDraftService.order(
      userId: widget.userId,
      documentType: _docType,
      answers: {
        'party_1': _party1.text.trim(),
        'party_2': _party2.text.trim(),
        'key_terms': _termsCtrl.text.trim(),
      },
      draftPriceTzs: 15000,
      reviewPriceTzs: 60000,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _result = res;
      _orderId = (res?['order_id'] as num?)?.toInt();
    });
  }

  Future<void> _purchaseReview() async {
    if (_orderId == null) return;
    final ok = await LegalDraftService.purchaseReview(
      userId: widget.userId,
      orderId: _orderId!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Mwanasheria atakagua' : 'Imeshindikana')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Hati ya kisheria' : 'Legal document'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_result == null) ...[
            DropdownButtonFormField<String>(
              initialValue: _docType,
              decoration: InputDecoration(
                labelText: isSw ? 'Aina ya hati' : 'Document type',
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'employment_contract', child: Text('Employment contract')),
                DropdownMenuItem(value: 'lease_agreement', child: Text('Lease agreement')),
                DropdownMenuItem(value: 'sale_agreement', child: Text('Sale agreement')),
                DropdownMenuItem(value: 'will', child: Text('Will')),
                DropdownMenuItem(value: 'nda', child: Text('NDA')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _docType = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _party1,
              decoration: InputDecoration(
                labelText: isSw ? 'Upande wa kwanza' : 'First party',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _party2,
              decoration: InputDecoration(
                labelText: isSw ? 'Upande wa pili' : 'Second party',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _termsCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: isSw ? 'Vipengele muhimu' : 'Key terms',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSw ? 'Bei' : 'Pricing',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSw
                        ? 'Hati ya AI: TZS 15,000\nUkaguzi wa mwanasheria: +TZS 60,000'
                        : 'AI draft: TZS 15,000\nLawyer review: +TZS 60,000',
                    style: const TextStyle(color: Color(0xFF333333)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A)),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting
                    ? (isSw ? 'AI inaandika…' : 'AI drafting…')
                    : (isSw ? 'Tengeneza hati' : 'Generate draft')),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isSw ? 'Hati imetengenezwa.' : 'Draft generated.',
                style: const TextStyle(
                    color: Color(0xFF1B5E20), fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Text(
                _result?['draft_text']?.toString() ?? '',
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A)),
              icon: const Icon(Icons.gavel_rounded),
              onPressed: _purchaseReview,
              label: Text(isSw
                  ? 'Lipa kwa ukaguzi wa mwanasheria (+60k)'
                  : 'Add lawyer review (+60k)'),
            ),
          ],
        ],
      ),
    );
  }
}
