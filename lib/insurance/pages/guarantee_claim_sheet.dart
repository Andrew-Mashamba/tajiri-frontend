import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../services/guarantee_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

/// Bottom sheet for a customer to file a guarantee claim.
Future<void> showGuaranteeClaimSheet({
  required BuildContext context,
  required int policyId,
  required int customerUserId,
  required String partnerName,
}) async {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFAFAFA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ClaimSheet(
      policyId: policyId,
      customerUserId: customerUserId,
      partnerName: partnerName,
    ),
  );
}

class _ClaimSheet extends StatefulWidget {
  final int policyId;
  final int customerUserId;
  final String partnerName;

  const _ClaimSheet({
    required this.policyId,
    required this.customerUserId,
    required this.partnerName,
  });

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  String _reason = 'no_fix_no_fee';
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isSw = _isSwahili;
    final desc = _descCtrl.text.trim();
    if (desc.length < 20) {
      setState(() => _error = isSw
          ? 'Eleza zaidi (angalau herufi 20)'
          : 'Please describe more (at least 20 chars)');
      return;
    }
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final res = await GuaranteeService.fileClaim(
      policyId: widget.policyId,
      customerUserId: widget.customerUserId,
      reason: _reason,
      description: desc,
      amountClaimedTzs: amount,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSw ? 'Malalamiko yamewekwa' : 'Claim filed successfully')),
      );
    } else {
      setState(() => _error = res.message ?? (isSw ? 'Imeshindwa' : 'Failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSw ? 'Weka malalamiko ya bima' : 'File guarantee claim',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.partnerName,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _reason,
            decoration: InputDecoration(
              labelText: isSw ? 'Sababu' : 'Reason',
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'no_fix_no_fee', child: Text(isSw ? 'Hakuna matengenezo' : 'No fix, no fee')),
              DropdownMenuItem(value: 'damage', child: Text(isSw ? 'Uharibifu' : 'Damage')),
              DropdownMenuItem(value: 'delay', child: Text(isSw ? 'Kuchelewa' : 'Delay')),
              DropdownMenuItem(value: 'other', child: Text(isSw ? 'Nyingine' : 'Other')),
            ],
            onChanged: (v) => setState(() => _reason = v ?? 'no_fix_no_fee'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: isSw ? 'Eleza tatizo' : 'Describe the issue',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isSw ? 'Kiasi unachodai (TZS)' : 'Amount claimed (TZS)',
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isSw ? 'Wasilisha' : 'Submit claim'),
          ),
        ],
      ),
    );
  }
}
