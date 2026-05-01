import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F4 #25 — Site-survey fee disclosure dialog.
///
/// Shown before a customer commits to a request that triggers a non-zero
/// `partner_products.site_survey_fee_tzs`. Returns `true` if accepted.
class SiteSurveyFeeDialog extends StatelessWidget {
  final int feeTzs;
  final int? estimatedMinutes;
  final String? rationale;
  const SiteSurveyFeeDialog({
    super.key,
    required this.feeTzs,
    this.estimatedMinutes,
    this.rationale,
  });

  static Future<bool> show(
    BuildContext context, {
    required int feeTzs,
    int? estimatedMinutes,
    String? rationale,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => SiteSurveyFeeDialog(
        feeTzs: feeTzs,
        estimatedMinutes: estimatedMinutes,
        rationale: rationale,
      ),
    );
    return ok == true;
  }

  String _fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isSw ? 'Ada ya ukaguzi' : 'Site-survey fee'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw
                ? 'Kwa kazi kubwa, mtoa huduma huja kukagua kwanza kabla ya kutoa bei kamili.'
                : 'For larger jobs, the partner inspects the site before quoting in full.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(isSw ? 'Ada' : 'Fee',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                    ),
                    Text('TZS ${_fmt(feeTzs)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A))),
                  ],
                ),
                if (estimatedMinutes != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(isSw ? 'Muda wa kufika' : 'On-site time',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                      ),
                      Text('${estimatedMinutes!} ${isSw ? 'dakika' : 'min'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (rationale != null && rationale!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(rationale!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(isSw ? 'Hapana' : 'Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(isSw ? 'Kubali' : 'Accept'),
        ),
      ],
    );
  }
}
