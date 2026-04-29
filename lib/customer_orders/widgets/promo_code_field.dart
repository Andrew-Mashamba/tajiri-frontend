import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec line 1041 — drop-in promo-code applicator. Hosts the input field +
/// validate/preview button + applied-discount chip. Notifies parent of the
/// final discounted total via `onPreview` so the parent can update its UI;
/// no order placement happens here — the parent calls `applyOrder` after
/// successful checkout to record the redemption.
class PromoCodeField extends StatefulWidget {
  final int subtotalTzs;
  final int? partnerUserId;
  final String? sourceType;
  /// Called whenever a code is validated (or cleared). Pass-through fields:
  /// (code, discountTzs, finalTotalTzs).
  final void Function(String? code, int discountTzs, int finalTotalTzs)? onPreview;
  const PromoCodeField({
    super.key,
    required this.subtotalTzs,
    this.partnerUserId,
    this.sourceType,
    this.onPreview,
  });

  @override
  State<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<PromoCodeField> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _appliedCode;
  int _discountTzs = 0;
  String? _error;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'code': code,
        'subtotal_tzs': widget.subtotalTzs,
      };
      if (widget.partnerUserId != null) body['partner_user_id'] = widget.partnerUserId;
      if (widget.sourceType != null) body['source_type'] = widget.sourceType;
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/promo-codes/preview'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && r['success'] == true) {
        final data = (r['data'] as Map).cast<String, dynamic>();
        final discount = (data['discount_tzs'] as num?)?.toInt() ?? 0;
        final finalTotal = (data['final_total_tzs'] as num?)?.toInt() ?? widget.subtotalTzs;
        setState(() {
          _appliedCode = code;
          _discountTzs = discount;
          _busy = false;
        });
        widget.onPreview?.call(code, discount, finalTotal);
      } else {
        setState(() {
          _busy = false;
          _error = r['message']?.toString();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Kosa: $e';
      });
    }
  }

  void _clear() {
    setState(() {
      _appliedCode = null;
      _discountTzs = 0;
      _error = null;
      _ctrl.clear();
    });
    widget.onPreview?.call(null, 0, widget.subtotalTzs);
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    if (_appliedCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.06),
          border: Border.all(color: _kAccent.withValues(alpha: 0.30)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded, size: 16, color: _kAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${_appliedCode!} · -TZS ${NumberFormat('#,##0').format(_discountTzs)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kAccent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: _clear,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(isSw ? 'Ondoa' : 'Remove',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: isSw ? 'Promo code (hiari)' : 'Promo code (optional)',
                  hintText: 'TAJIRI20',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _preview(),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: _busy ? null : _preview,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(72, 44),
              ),
              child: _busy
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isSw ? 'Tumia' : 'Apply'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFB71C1C))),
        ],
      ],
    );
  }
}
