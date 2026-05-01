import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);

/// Shows a bottom sheet with payment options and returns the selected method.
/// Returns one of: 'mpesa', 'wallet', 'cod'. Null if dismissed.
Future<String?> showPaymentMethodSheet({
  required BuildContext context,
  required int amountTzs,
}) async {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _kBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _PaymentMethodSheet(amountTzs: amountTzs),
  );
}

class _PaymentMethodSheet extends StatelessWidget {
  final int amountTzs;

  const _PaymentMethodSheet({required this.amountTzs});

  String _fmtTzs(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TSh ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Lipa ${_fmtTzs(amountTzs)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Chagua njia ya malipo',
              style: TextStyle(fontSize: 13, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.phone_android_rounded,
              label: 'M-Pesa',
              sublabel: 'Lipa kwa M-Pesa',
              onTap: () => Navigator.of(context).pop('mpesa'),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Wallet',
              sublabel: 'Lipa kwa Tajiri Wallet',
              onTap: () => Navigator.of(context).pop('wallet'),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.payments_rounded,
              label: 'Cash on Delivery',
              sublabel: 'Lipa wakati wa kupokea',
              onTap: () => Navigator.of(context).pop('cod'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _kAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
