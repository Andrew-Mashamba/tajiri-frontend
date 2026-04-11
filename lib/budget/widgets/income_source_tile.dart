import 'package:flutter/material.dart';
import '../models/budget_models.dart';

/// Income row with source icon, description, and amount.
/// Accepts either an IncomeRecord or simple fields.
class IncomeSourceTile extends StatelessWidget {
  final String source;
  final String description;
  final double amount;
  final bool isSwahili;

  const IncomeSourceTile({
    super.key,
    required this.source,
    required this.description,
    required this.amount,
    this.isSwahili = false,
  });

  /// Convenience constructor from an IncomeRecord model.
  factory IncomeSourceTile.fromRecord({
    Key? key,
    required IncomeRecord record,
    bool isSwahili = false,
  }) {
    return IncomeSourceTile(
      key: key,
      source: record.source,
      description: record.description,
      amount: record.amount,
      isSwahili: isSwahili,
    );
  }

  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF4CAF50);

  String _formatTZS(double value) {
    if (value >= 1000000) {
      return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${value.toStringAsFixed(0)}';
  }

  IconData get _sourceIcon {
    switch (source.toLowerCase()) {
      case 'top_up':
        return Icons.account_balance_wallet_rounded;
      case 'transfer_in':
        return Icons.swap_horiz_rounded;
      case 'payment_received':
        return Icons.request_quote_rounded;
      case 'creator_subscription':
        return Icons.loyalty_rounded;
      case 'creator_tip':
        return Icons.favorite_rounded;
      case 'creator_payout':
        return Icons.monetization_on_rounded;
      case 'creator_fund':
        return Icons.emoji_events_rounded;
      case 'shop_sale':
        return Icons.storefront_rounded;
      case 'tajirika_job':
        return Icons.work_rounded;
      case 'tajirika_payout':
        return Icons.handshake_rounded;
      case 'michango_withdrawal':
        return Icons.volunteer_activism_rounded;
      case 'ad_revenue':
        return Icons.campaign_rounded;
      case 'stream_gift':
        return Icons.card_giftcard_rounded;
      case 'event_ticket':
        return Icons.confirmation_number_rounded;
      case 'kikoba_payout':
        return Icons.savings_rounded;
      case 'salary':
      case 'mshahara':
        return Icons.account_balance_rounded;
      case 'manual':
        return Icons.edit_rounded;
      case 'business':
      case 'biashara':
        return Icons.storefront_rounded;
      case 'freelance':
        return Icons.laptop_rounded;
      case 'investment':
      case 'uwekezaji':
        return Icons.trending_up_rounded;
      case 'gift':
      case 'zawadi':
        return Icons.card_giftcard_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'refund':
        return Icons.replay_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kSuccess.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_sourceIcon, color: _kSuccess, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displaySource,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+ ${_formatTZS(amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kSuccess,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, List<String>> _sourceLabels = {
    'top_up': ['Top Up', 'Jaza Mkoba'],
    'transfer_in': ['Transfer Received', 'Uhamisho Ulipokelewa'],
    'payment_received': ['Payment Received', 'Malipo Yalipokelewa'],
    'creator_subscription': ['Subscriptions', 'Usajili'],
    'creator_tip': ['Tips', 'Tuzo'],
    'creator_payout': ['Creator Payout', 'Malipo ya Ubunifu'],
    'creator_fund': ['Creator Fund', 'Mfuko wa Ubunifu'],
    'shop_sale': ['Shop Sales', 'Mauzo ya Duka'],
    'tajirika_job': ['Service Earnings', 'Mapato ya Huduma'],
    'tajirika_payout': ['Partner Payout', 'Malipo ya Mshirika'],
    'michango_withdrawal': ['Michango Withdrawal', 'Utoaji wa Michango'],
    'ad_revenue': ['Ad Revenue', 'Mapato ya Matangazo'],
    'stream_gift': ['Stream Gifts', 'Zawadi za Live'],
    'event_ticket': ['Ticket Sales', 'Mauzo ya Tiketi'],
    'kikoba_payout': ['Kikoba Payout', 'Malipo ya Kikoba'],
    'salary': ['Salary', 'Mshahara'],
    'manual': ['Manual Entry', 'Ingizo la Mkono'],
    'other': ['Other', 'Nyingine'],
  };

  String get _displaySource {
    if (source.isEmpty) return isSwahili ? 'Chanzo' : 'Source';
    final pair = _sourceLabels[source];
    if (pair != null) return isSwahili ? pair[1] : pair[0];
    // Fallback: replace underscores and capitalize first letter
    final clean = source.replaceAll('_', ' ');
    return clean[0].toUpperCase() + clean.substring(1);
  }
}
