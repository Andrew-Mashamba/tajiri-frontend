import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F5 #29 — Body-shop bidding on photos alone.
///
/// Customer-side card that shows live bids on a service request when the
/// skill is `panelBeating` or `sprayPainting`. Customer taps "Award" on the
/// chosen bid to confirm.
class BodyShopBidsSection extends StatefulWidget {
  final int serviceRequestId;
  final int customerUserId;
  const BodyShopBidsSection({
    super.key,
    required this.serviceRequestId,
    required this.customerUserId,
  });

  @override
  State<BodyShopBidsSection> createState() => _BodyShopBidsSectionState();
}

class _BodyShopBidsSectionState extends State<BodyShopBidsSection> {
  bool _loading = true;
  List<Map<String, dynamic>> _bids = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await BodyShopBidsService.listForRequest(widget.serviceRequestId);
    if (!mounted) return;
    setState(() {
      _bids = rows;
      _loading = false;
    });
  }

  Future<void> _award(Map<String, dynamic> bid) async {
    final ok = await BodyShopBidsService.award(
      (bid['id'] as num).toInt(),
      userId: widget.customerUserId,
    );
    if (!mounted) return;
    if (ok) _load();
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
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_bids.isEmpty) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSw ? 'Bei zilizopendekezwa' : 'Bids received',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          ..._bids.map((b) {
            final status = b['status']?.toString() ?? 'open';
            final isAwarded = status == 'awarded';
            final isDeclined = status == 'declined';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['partner_name']?.toString() ?? 'Partner',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          'TZS ${_fmt((b['bid_tzs'] as num?)?.toInt() ?? 0)}'
                          '${b['estimated_days'] != null ? "  •  ${b['estimated_days']}d" : ""}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF666666)),
                        ),
                        if (b['notes'] != null &&
                            (b['notes'] as String).isNotEmpty)
                          Text(
                            b['notes'] as String,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF999999)),
                          ),
                      ],
                    ),
                  ),
                  if (isAwarded)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF1B5E20))
                  else if (isDeclined)
                    Text(isSw ? 'Imekataliwa' : 'Declined',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF999999)))
                  else
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A)),
                      onPressed: () => _award(b),
                      child: Text(isSw ? 'Chagua' : 'Award'),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
