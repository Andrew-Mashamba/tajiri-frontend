import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Plain-language NDA gate per spec §7.4.1 (lines 658–659).
///
/// Renders an inline confidentiality block + checkbox + signature-line affirmation.
/// Always pre-empts attachment / intake submission for legal & medical verticals.
/// For business consulting it's still required (intake routinely contains
/// sensitive company info).
class NdaAcceptanceGate extends StatelessWidget {
  final String partnerDisplayName;
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final TextEditingController signatureController;

  const NdaAcceptanceGate({
    super.key,
    required this.partnerDisplayName,
    required this.accepted,
    required this.onChanged,
    required this.signatureController,
  });

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSwahili ? 'Mkataba wa Usiri' : 'Confidentiality Agreement',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isSwahili
                ? 'Mahojiano haya ni ya siri. $partnerDisplayName hatashiriki habari yako bila ruhusa yako. Maelezo yako ya kibinafsi yanahifadhiwa kwa usalama na yanapatikana tu kwako na kwa $partnerDisplayName.'
                : 'This consultation is confidential. $partnerDisplayName will not share your information without your consent. Your personal details are stored securely and accessible only to you and $partnerDisplayName.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => onChanged(!accepted),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: accepted,
                      onChanged: (v) => onChanged(v ?? false),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSwahili
                          ? 'Nakubali masharti haya ya usiri'
                          : 'I accept these confidentiality terms',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: signatureController,
            enabled: accepted,
            decoration: InputDecoration(
              labelText: isSwahili ? 'Saini (jina lako kamili)' : 'Signature (your full name)',
              hintText: isSwahili ? 'Mfano: Asha Mwakasege' : 'e.g. Asha Mwakasege',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
