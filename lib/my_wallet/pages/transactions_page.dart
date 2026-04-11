// lib/my_wallet/pages/transactions_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../widgets/transaction_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class TransactionsPage extends StatefulWidget {
  final int userId;
  const TransactionsPage({super.key, required this.userId});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final WalletService _walletService = WalletService();
  final ScrollController _scrollController = ScrollController();

  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _filterType;

  static const int _perPage = 20;
  List<(String?, String)> get _typeFilters {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return [
      (null, isSwahili ? 'Zote' : 'All'),
      ('deposit', isSwahili ? 'Uingizaji' : 'Deposits'),
      ('withdrawal', isSwahili ? 'Uondoaji' : 'Withdrawals'),
      ('transfer_in', isSwahili ? 'Upokeaji' : 'Received'),
      ('transfer_out', isSwahili ? 'Ulipaji' : 'Sent'),
      ('payment', isSwahili ? 'Malipo' : 'Payments'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTransactions();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
      _loadMore();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _page = 1;
    });

    try {
      final result = await _walletService.getTransactions(
        userId: widget.userId,
        page: 1,
        perPage: _perPage,
        type: _filterType,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _transactions = result.transactions;
            _hasMore = result.meta != null
                ? result.meta!.currentPage < result.meta!.lastPage
                : result.transactions.length >= _perPage;
            _page = 2;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _walletService.getTransactions(
        userId: widget.userId,
        page: _page,
        perPage: _perPage,
        type: _filterType,
      );

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (result.success) {
            _transactions.addAll(result.transactions);
            _hasMore = result.meta != null
                ? result.meta!.currentPage < result.meta!.lastPage
                : result.transactions.length >= _perPage;
            _page++;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onFilterChanged(String? type) {
    setState(() => _filterType = type);
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSwahili ? 'Miamala Yote' : 'All Transactions',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: _typeFilters.map((f) {
                  final isSelected = _filterType == f.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: isSelected,
                      selectedColor: _kPrimary.withValues(alpha: 0.15),
                      checkmarkColor: _kPrimary,
                      labelStyle: TextStyle(
                        color: isSelected ? _kPrimary : _kSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (_) => _onFilterChanged(f.$1),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Transaction list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                    )
                  : _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                isSwahili ? 'Hakuna miamala' : 'No transactions',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTransactions,
                          color: _kPrimary,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _transactions.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _transactions.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                                  ),
                                );
                              }
                              return TransactionTile(transaction: _transactions[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
