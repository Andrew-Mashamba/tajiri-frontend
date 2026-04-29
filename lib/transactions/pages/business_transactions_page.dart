// lib/transactions/pages/business_transactions_page.dart
//
// Business-scoped transaction ledger: central API when available, else invoices + expenses.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/transaction_models.dart';
import '../services/transaction_service.dart';
import '../widgets/transaction_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class BusinessTransactionsPage extends StatefulWidget {
  final int businessId;
  const BusinessTransactionsPage({super.key, required this.businessId});

  @override
  State<BusinessTransactionsPage> createState() => _BusinessTransactionsPageState();
}

class _BusinessTransactionsPageState extends State<BusinessTransactionsPage> {
  final NumberFormat _nf = NumberFormat('#,###', 'en');
  final ScrollController _scrollController = ScrollController();

  List<RecordedTransaction> _items = [];
  TransactionDataSource _source = TransactionDataSource.api;
  TransactionListMeta? _meta;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 1;
  static const int _perPage = 30;

  String? _directionFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_source != TransactionDataSource.api) return;
    if (_loadingMore || _meta == null || _meta!.hasMore != true) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.72) {
      _loadMore();
    }
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        setState(() {
          _loading = false;
          _error = _sw ? 'Ingia ili kuona miamala' : 'Sign in to view transactions';
        });
        return;
      }

      final result = await TransactionService.listRecordedTransactions(
        token,
        businessId: widget.businessId,
        page: _page,
        perPage: _perPage,
        status: _statusFilter,
        direction: _directionFilter,
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _loading = false;
          _error = result.message ?? (_sw ? 'Imeshindwa kupakia' : 'Failed to load');
        });
        return;
      }

      var list = result.items;
      if (result.source == TransactionDataSource.composite &&
          (_statusFilter == 'pending' || _statusFilter == 'failed')) {
        list = [];
      }

      setState(() {
        _items = list;
        _meta = result.meta;
        _source = result.source;
        _loading = false;
        _error = null;
        if (_source == TransactionDataSource.api && _meta != null && _meta!.hasMore) {
          _page = 2;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _sw ? 'Hitilafu: $e' : 'Error: $e';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_source != TransactionDataSource.api || _loadingMore) return;
    if (_meta == null || !_meta!.hasMore) return;

    setState(() => _loadingMore = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        setState(() => _loadingMore = false);
        return;
      }

      final result = await TransactionService.listRecordedTransactions(
        token,
        businessId: widget.businessId,
        page: _page,
        perPage: _perPage,
        status: _statusFilter,
        direction: _directionFilter,
      );

      if (!mounted) return;
      if (result.success && result.source == TransactionDataSource.api) {
        setState(() {
          _items.addAll(result.items);
          _meta = result.meta ?? _meta;
          _page++;
          _loadingMore = false;
        });
      } else {
        setState(() => _loadingMore = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setDirection(String? v) {
    setState(() => _directionFilter = v);
    _load(reset: true);
  }

  void _setStatus(String? v) {
    setState(() => _statusFilter = v);
    _load(reset: true);
  }

  void _showDetail(RecordedTransaction t) {
    final sw = _sw;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Maelezo' : 'Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow(sw ? 'Kitambulisho' : 'Trace', t.traceId),
                  _detailRow(sw ? 'Moduli' : 'Module', t.module),
                  _detailRow(sw ? 'Kitendo' : 'Action', t.action),
                  _detailRow(sw ? 'Mwelekeo' : 'Direction', t.direction),
                  _detailRow(sw ? 'Hali' : 'Status', t.status),
                  _detailRow(sw ? 'Kiasi' : 'Amount', '${t.currency} ${_nf.format(t.amount)}'),
                  if ((t.referenceId ?? '').isNotEmpty)
                    _detailRow(sw ? 'Rejeleo' : 'Reference', t.referenceId!),
                  if ((t.message ?? '').isNotEmpty)
                    _detailRow(sw ? 'Ujumbe' : 'Message', t.message!),
                  if (t.metadata.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      sw ? 'Metadata' : 'Metadata',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      const JsonEncoder.withIndent('  ').convert(t.metadata),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontFamily: 'monospace'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: _kSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: _kBackground,
        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: _kBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _load(reset: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_sw ? 'Jaribu tena' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: _kBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_source == TransactionDataSource.composite)
              Material(
                color: Colors.grey.shade200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 20, color: _kPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _sw
                              ? 'Orodha ya miamala ya seva bado haipatikani — unaona muhtasari wa biashara (ankara, matumizi, deni, maagizo).'
                              : 'Live ledger not available — showing a business summary (invoices, expenses, debts, purchase orders).',
                          style: const TextStyle(fontSize: 12, color: _kPrimary),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_source == TransactionDataSource.composite &&
                (_statusFilter == 'pending' || _statusFilter == 'failed'))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  _sw
                      ? 'Muhtasari huu una rekodi zenye hali "imefanikiwa" pekee. Chagua hali nyingine baada ya seva kuunganishwa.'
                      : 'This summary only includes successful records. Pending/failed filters apply when the live ledger is connected.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: _sw ? 'Zote (mwelekeo)' : 'All directions',
                    value: null,
                    selected: _directionFilter == null,
                    onTap: () => _setDirection(null),
                  ),
                  _FilterChip(
                    label: _sw ? 'Mapato' : 'Incoming',
                    value: 'incoming',
                    selected: _directionFilter == 'incoming',
                    onTap: () => _setDirection('incoming'),
                  ),
                  _FilterChip(
                    label: _sw ? 'Matumizi' : 'Outgoing',
                    value: 'outgoing',
                    selected: _directionFilter == 'outgoing',
                    onTap: () => _setDirection('outgoing'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: _sw ? 'Zote (hali)' : 'All statuses',
                    value: null,
                    selected: _statusFilter == null,
                    onTap: () => _setStatus(null),
                  ),
                  _FilterChip(
                    label: _sw ? 'Inasubiri' : 'Pending',
                    value: 'pending',
                    selected: _statusFilter == 'pending',
                    onTap: () => _setStatus('pending'),
                  ),
                  _FilterChip(
                    label: _sw ? 'Imefanikiwa' : 'Done',
                    value: 'success',
                    selected: _statusFilter == 'success',
                    onTap: () => _setStatus('success'),
                  ),
                  _FilterChip(
                    label: _sw ? 'Imeshindwa' : 'Failed',
                    value: 'failed',
                    selected: _statusFilter == 'failed',
                    onTap: () => _setStatus('failed'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: _kPrimary,
              onRefresh: () => _load(reset: true),
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _emptyMessage(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _kSecondary),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _items.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, i) {
                        if (i >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                              ),
                            ),
                          );
                        }
                        final t = _items[i];
                        return TransactionTile(
                          txn: t,
                          amountFormat: _nf,
                          swahili: _sw,
                          onTap: () => _showDetail(t),
                        );
                      },
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _emptyMessage() {
    if (_source == TransactionDataSource.composite &&
        (_statusFilter == 'pending' || _statusFilter == 'failed')) {
      return _sw
          ? 'Hakuna rekodi za aina hii katika muhtasari. Jaribu "Imefanikiwa" au ondoa kichujio cha hali.'
          : 'No rows match this status in the offline summary. Try "Done" or clear the status filter.';
    }
    return _sw ? 'Hakuna miamala bado' : 'No transactions yet';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.grey.shade300,
        checkmarkColor: _kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
