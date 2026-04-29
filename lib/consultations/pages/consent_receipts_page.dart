import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/consent_receipt_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 752 — every data-share generates a logged, user-visible receipt.
/// This page lists the user's full consent-receipt history.
class ConsentReceiptsPage extends StatefulWidget {
  final int userId;
  const ConsentReceiptsPage({super.key, required this.userId});

  @override
  State<ConsentReceiptsPage> createState() => _ConsentReceiptsPageState();
}

class _ConsentReceiptsPageState extends State<ConsentReceiptsPage> {
  bool _loading = true;
  List<ConsentReceipt> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ConsentReceiptService.list(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSw ? 'Risiti za Idhini' : 'Consent Receipts',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 56, color: _kSecondary),
                        const SizedBox(height: 12),
                        Text(
                          isSw
                              ? 'Hakuna risiti bado'
                              : 'No consent receipts yet',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSw
                              ? 'Kila wakati unaposhiriki data, risiti itahifadhiwa hapa.'
                              : 'Every data share creates a receipt logged here.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _row(_items[i]),
                  ),
                ),
    );
  }

  Widget _row(ConsentReceipt r) {
    final isSw = _isSwahili;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_actionIcon(r.action), size: 16, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _actionLabel(r.action, isSw),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                  ),
                ),
              ),
              if (r.acknowledgedAt != null)
                Text(
                  DateFormat('d MMM HH:mm').format(r.acknowledgedAt!.toLocal()),
                  style: const TextStyle(fontSize: 10, color: _kSecondary),
                ),
            ],
          ),
          if (r.recipient != null && r.recipient!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              isSw ? 'Mpokeaji: ${r.recipient}' : 'Recipient: ${r.recipient}',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ],
        ],
      ),
    );
  }

  IconData _actionIcon(String a) {
    switch (a) {
      case 'share_lab':
        return Icons.science_outlined;
      case 'record_call':
        return Icons.fiber_manual_record_rounded;
      case 'prescription_send':
        return Icons.medication_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  String _actionLabel(String a, bool isSw) {
    switch (a) {
      case 'share_lab':
        return isSw ? 'Kushiriki ripoti ya maabara' : 'Lab report shared';
      case 'record_call':
        return isSw ? 'Kurekodi simu' : 'Call recording';
      case 'prescription_send':
        return isSw ? 'Kutuma dawa' : 'Prescription sent';
      default:
        return a;
    }
  }
}
