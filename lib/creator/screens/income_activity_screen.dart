// IncomeActivityScreen — full Tajiri Pay wallet activity log.
// Spec §3 (replaces earnings_ledger_screen.dart functionality): the
// "Shughuli" target opened from the wallet hero on the Mapato home view.
//
// Displays paginated WalletTransactions in a clean monochrome list.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';

class IncomeActivityScreen extends StatefulWidget {
  final int creatorId;
  const IncomeActivityScreen({super.key, required this.creatorId});

  @override
  State<IncomeActivityScreen> createState() => _IncomeActivityScreenState();
}

class _IncomeActivityScreenState extends State<IncomeActivityScreen> {
  final WalletService _service = WalletService();
  final ScrollController _scroll = ScrollController();

  final List<WalletTransaction> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      if (kDebugMode) {
        debugPrint('[Mapato/Activity] page $_page');
      }
      final result = await _service.getTransactions(
        userId: widget.creatorId,
        page: _page,
        perPage: 20,
      );
      if (!mounted) return;
      if (result.success && result.transactions.isNotEmpty) {
        setState(() {
          _items.addAll(result.transactions);
          _page += 1;
          if (result.transactions.length < 20) _hasMore = false;
          _loading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _loading = false;
          if (!result.success && _items.isEmpty) {
            _error = result.message;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Mapato/Activity] load error: $e');
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasMore = false;
        if (_items.isEmpty) _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSw ? 'Shughuli' : 'Activity',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF1A1A1A),
          onRefresh: _loadFirstPage,
          child: _buildBody(isSw),
        ),
      ),
    );
  }

  Widget _buildBody(bool isSw) {
    if (_items.isEmpty && _loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF1A1A1A),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error != null
                        ? (isSw
                            ? 'Imeshindwa kupakua shughuli.'
                            : 'Could not load activity.')
                        : (isSw ? 'Hakuna shughuli bado' : 'No activity yet'),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          );
        }
        return _ActivityRow(txn: _items[index], isSw: isSw);
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final WalletTransaction txn;
  final bool isSw;
  const _ActivityRow({required this.txn, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.isCredit;
    final amountText =
        '${isCredit ? "+" : "−"} TSh ${_thousands(txn.amount.round())}';
    final dateText = _formatDate(txn.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconFor(txn.type),
                size: 18,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titleFor(txn),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (txn.provider != null) txn.providerName,
                      dateText,
                    ].where((x) => x.isNotEmpty).join(' · '),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amountText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (txn.status != 'completed' && txn.status != 'settled')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _StatusPill(status: txn.status, isSw: isSw),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'deposit':
        return Icons.arrow_downward_rounded;
      case 'withdrawal':
        return Icons.arrow_upward_rounded;
      case 'transfer_in':
        return Icons.south_west_rounded;
      case 'transfer_out':
        return Icons.north_east_rounded;
      case 'payment':
        return Icons.shopping_cart_outlined;
      case 'refund':
        return Icons.undo_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _titleFor(WalletTransaction txn) {
    if (txn.description != null && txn.description!.isNotEmpty) {
      return txn.description!;
    }
    if (isSw) return txn.typeName;
    switch (txn.type) {
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'transfer_in':
        return 'Transfer in';
      case 'transfer_out':
        return 'Transfer out';
      case 'payment':
        return 'Payment';
      case 'refund':
        return 'Refund';
    }
    return txn.type;
  }

  String _formatDate(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return isSw ? 'sasa hivi' : 'just now';
    if (diff.inMinutes < 60) {
      return isSw ? 'dakika ${diff.inMinutes}' : '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return isSw ? 'saa ${diff.inHours}' : '${diff.inHours}h';
    }
    if (diff.inDays == 1) return isSw ? 'jana' : 'yesterday';
    if (diff.inDays < 7) {
      return isSw ? 'siku ${diff.inDays}' : '${diff.inDays}d';
    }
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
  }

  static String _thousands(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool isSw;
  const _StatusPill({required this.status, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(status);
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _labelFor(String s) {
    switch (s) {
      case 'pending':
        return isSw ? 'Inasubiri' : 'Pending';
      case 'processing':
        return isSw ? 'Inafanyika' : 'Processing';
      case 'failed':
        return isSw ? 'Imeshindwa' : 'Failed';
      case 'cancelled':
        return isSw ? 'Imeghairiwa' : 'Cancelled';
      case 'reversed':
        return isSw ? 'Imerejeshwa' : 'Reversed';
      default:
        return s;
    }
  }

  Color _colorFor(String s) {
    switch (s) {
      case 'pending':
      case 'processing':
        return const Color(0xFF666666);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFD32F2F);
      case 'reversed':
        return const Color(0xFF666666);
      default:
        return const Color(0xFF666666);
    }
  }
}
