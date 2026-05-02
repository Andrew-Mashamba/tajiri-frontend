// Wallet hero — Tajiri Pay balance + pending + lifetime + actions.
// Spec §3 (IA): the dark hero block at the top of the home view.
// Tajiri Pay is the default rail (per memory: feedback_tajiri_pay_default_rail).

import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/income_source.dart';

class WalletHeroCard extends StatelessWidget {
  final IncomeSummary summary;
  final VoidCallback? onWithdraw;
  final VoidCallback? onActivity;

  const WalletHeroCard({
    super.key,
    required this.summary,
    this.onWithdraw,
    this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;

    final pendingText = summary.walletPendingMinor > 0
        ? '+ ${formatTzsMinor(summary.walletPendingMinor)} ${isSw ? "inakuja" : "incoming"}'
        : '';
    final lifetimeText = summary.walletLifetimeMinor > 0
        ? '${isSw ? "jumla yote" : "lifetime"} ${formatTzsMinor(summary.walletLifetimeMinor)}'
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TAJIRI PAY · WALLET',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: Color(0xAACCCCCC),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            formatTzsMinor(summary.walletBalanceMinor),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFAFAFA),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (pendingText.isNotEmpty || lifetimeText.isNotEmpty)
            Text(
              [pendingText, lifetimeText].where((x) => x.isNotEmpty).join(' · '),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xCCCCCCCC),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: isSw ? 'Toa pesa' : 'Withdraw',
                  filled: true,
                  onTap: onWithdraw,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroButton(
                  label: isSw ? 'Shughuli' : 'Activity',
                  filled: false,
                  onTap: onActivity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  const _HeroButton({required this.label, required this.filled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFFFAFAFA) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: filled
                ? null
                : Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: filled ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
