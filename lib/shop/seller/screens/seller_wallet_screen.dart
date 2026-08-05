import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../../services/http_retry.dart';
import '../../../config/api_config.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/graphql/graphql_wallet_service.dart';
import '../../escrow/models/escrow_models.dart';
import '../../escrow/services/escrow_service.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

class _TxRow {
  final String description;
  final String date;
  final double amount;
  final bool credit;

  const _TxRow({
    required this.description,
    required this.date,
    required this.amount,
    required this.credit,
  });
}

/// Seller wallet — balance, ad spend, transaction ledger, and withdraw.
class SellerWalletScreen extends StatefulWidget {
  const SellerWalletScreen({super.key});

  @override
  State<SellerWalletScreen> createState() => _SellerWalletScreenState();
}

class _SellerWalletScreenState extends State<SellerWalletScreen> {
  bool _loading = true;
  double _balance = 0;
  double _adSpend = 0;
  double _refundExposure = 0;
  EscrowWalletSummary? _escrowSummary;
  final List<_TxRow> _txns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken() ?? '';

      // Load wallet balance and escrow summary in parallel
      final results = await Future.wait([
        _fetchWallet(token),
        EscrowService.getWalletSummary(token),
      ]);

      if (!mounted) return;

      final walletData = results[0] as Map<String, dynamic>?;
      if (walletData != null) {
        _balance = (walletData['available_balance'] as num?)?.toDouble() ?? 0.0;
        _adSpend = (walletData['ad_spend'] as num?)?.toDouble() ?? 0.0;
        _refundExposure = (walletData['refund_exposure'] as num?)?.toDouble() ?? 0.0;

        final txList = walletData['transactions'] as List<dynamic>? ?? [];
        _txns.clear();
        for (final tx in txList) {
          if (tx is Map<String, dynamic>) {
            _txns.add(_TxRow(
              description: tx['description'] as String? ?? '',
              date: tx['date'] as String? ?? '',
              amount: (tx['amount'] as num?)?.toDouble() ?? 0.0,
              credit: tx['type'] == 'credit',
            ));
          }
        }
      }

      final summary = results[1] as EscrowWalletSummary?;
      if (summary != null) {
        _escrowSummary = summary;
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchWallet(String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlWalletService.getSellerWallet();
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/shop/seller/wallet');
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            pinned: true,
            centerTitle: false,
            title: const Text(
              'Wallet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kText),
            ),
            iconTheme: const IconThemeData(color: _kText),
            actions: [
              IconButton(
                icon: const HeroIcon(HeroIcons.arrowDownOnSquare,
                    style: HeroIconStyle.outline, color: _kText, size: 22),
                onPressed: () {},
                tooltip: 'Export',
              ),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                // Balance hero
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [_kCardShadow],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Balance',
                            style:
                                TextStyle(fontSize: 13, color: _kMuted)),
                        const SizedBox(height: 6),
                        Text(
                          'TZS ${_balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _kText),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: _kDivider),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Ad Spend',
                              value:
                                  'TZS ${_adSpend.toStringAsFixed(0)}',
                            ),
                          ),
                          Expanded(
                            child: _MiniStat(
                              label: 'Refund Exposure',
                              value:
                                  'TZS ${_refundExposure.toStringAsFixed(0)}',
                            ),
                          ),
                        ]),
                        if (_escrowSummary != null) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: _kDivider),
                          const SizedBox(height: 12),
                          _EscrowSummaryRow(summary: _escrowSummary!),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, '/shop/seller/payouts'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kText,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                            child: const Text('Withdraw Funds',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ]),
                ),

                // Transactions header
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Recent Transactions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [_kCardShadow],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _txns.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: _kDivider),
                    itemBuilder: (context, i) {
                      final tx = _txns[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F0F0),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: HeroIcon(
                              tx.credit
                                  ? HeroIcons.arrowDownLeft
                                  : HeroIcons.arrowUpRight,
                              style: HeroIconStyle.outline,
                              color: _kText,
                              size: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          tx.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kText),
                        ),
                        subtitle: Text(tx.date,
                            style: const TextStyle(
                                fontSize: 12, color: _kFaint)),
                        trailing: Text(
                          '${tx.credit ? '+' : '-'} TZS ${tx.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tx.credit
                                ? _kText
                                : _kMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: _kFaint)),
      const SizedBox(height: 2),
      Text(value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kText)),
    ]);
  }
}

class _EscrowSummaryRow extends StatelessWidget {
  final EscrowWalletSummary summary;
  const _EscrowSummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HeroIcon(
          HeroIcons.lockClosed,
          style: HeroIconStyle.outline,
          size: 16,
          color: _kMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'In Escrow',
                style: TextStyle(fontSize: 11, color: _kFaint),
              ),
              const SizedBox(height: 2),
              Text(
                summary.heldAmountFormatted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
              ),
            ],
          ),
        ),
        if (summary.pendingReleaseCount > 0)
          Text(
            '${summary.pendingReleaseCount} order${summary.pendingReleaseCount == 1 ? '' : 's'} pending release',
            style: const TextStyle(fontSize: 11, color: _kFaint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
