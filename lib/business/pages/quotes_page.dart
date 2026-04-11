// lib/business/pages/quotes_page.dart
// Quotes / Estimates — list, filter, send, convert to invoice.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';
import 'create_quote_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class QuotesPage extends StatefulWidget {
  final int businessId;
  const QuotesPage({super.key, required this.businessId});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _token;
  bool _loading = true;
  String? _error;
  List<Quote> _allQuotes = [];

  final _statusFilters = const [null, 'draft', 'sent', 'accepted'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _load();
    });
    _init();
  }

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  List<String> get _tabs => _isSwahili
      ? const ['Zote', 'Rasimu', 'Zimetumwa', 'Zimekubaliwa']
      : const ['All', 'Drafts', 'Sent', 'Accepted'];

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = _statusFilters[_tabCtrl.index];
      final res = await BusinessService.getQuotes(
          _token!, widget.businessId, status: status);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _allQuotes = res.data;
          } else {
            _error = res.message ?? 'Failed to load quotes';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _sendQuote(Quote q) async {
    if (_token == null || q.id == null) return;
    try {
      final res = await BusinessService.sendQuote(_token!, q.id!);
      if (mounted) {
        final sw = _isSwahili;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.message ??
                (sw ? 'Imetumwa' : 'Sent'))));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isSwahili ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  Future<void> _convertToInvoice(Quote q) async {
    if (_token == null || q.id == null) return;
    try {
      final res = await BusinessService.convertQuoteToInvoice(_token!, q.id!);
      if (mounted) {
        final sw = _isSwahili;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.message ??
                (sw ? 'Imebadilishwa kuwa ankara' : 'Converted to invoice'))));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isSwahili ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  Future<void> _rejectQuote(Quote q) async {
    if (_token == null || q.id == null) return;
    try {
      final res =
          await BusinessService.updateQuoteStatus(_token!, q.id!, 'rejected');
      if (mounted) {
        final sw = _isSwahili;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.success
                ? (sw ? 'Imekataliwa' : 'Rejected')
                : (sw ? 'Imeshindikana' : 'Failed'))));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isSwahili ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  void _shareQuote(Quote q) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final sw = _isSwahili;
    final text = '${sw ? 'Makadirio' : 'Quote'}: ${q.quoteNumber}\n'
        '${sw ? 'Mteja' : 'Customer'}: ${q.customerName ?? (sw ? "Mteja" : "Customer")}\n'
        '${sw ? 'Kiasi' : 'Amount'}: TZS ${nf.format(q.totalAmount)}\n'
        '${q.validUntil != null ? '${sw ? 'Hadi' : 'Valid until'}: ${df.format(q.validUntil!)}\n' : ''}\n'
        'Powered by TAJIRI';
    SharePlus.instance.share(ShareParams(text: text));
  }

  Color _statusColor(QuoteStatus s) {
    switch (s) {
      case QuoteStatus.draft:
        return Colors.grey;
      case QuoteStatus.sent:
        return Colors.blue;
      case QuoteStatus.accepted:
        return Colors.green;
      case QuoteStatus.rejected:
        return Colors.red;
      case QuoteStatus.converted:
        return Colors.teal;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final sw = _isSwahili;

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CreateQuotePage(businessId: widget.businessId)),
          );
          if (created == true) _load();
        },
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Material(
            color: _kCardBg,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: _kPrimary,
              unselectedLabelColor: _kSecondary,
              indicatorColor: _kPrimary,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        sw ? 'Imeshindikana kupakia' : 'Failed to load',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(sw ? 'Jaribu tena' : 'Retry'),
                        style:
                            TextButton.styleFrom(foregroundColor: _kPrimary),
                      ),
                    ],
                  ),
                )
              : _allQuotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.request_quote_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(sw ? 'Hakuna makadirio bado' : 'No quotes yet',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            sw
                                ? 'Bonyeza + kuunda kadirio jipya'
                                : 'Tap + to create a new quote',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _allQuotes.length,
                        itemBuilder: (_, i) {
                          final q = _allQuotes[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          q.quoteNumber.isNotEmpty
                                              ? q.quoteNumber
                                              : 'QT-${q.id ?? ''}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _kPrimary,
                                              fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(q.status)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          quoteStatusLabel(q.status,
                                              swahili: sw),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor(q.status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                          q.customerName ??
                                              (sw ? 'Mteja' : 'Customer'),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: _kSecondary)),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'TZS ${nf.format(q.totalAmount)}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: _kPrimary),
                                          ),
                                          if (q.validUntil != null)
                                            Text(
                                              '${sw ? 'Hadi' : 'Valid'}: ${df.format(q.validUntil!)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: q.validUntil!.isBefore(
                                                        DateTime.now())
                                                    ? Colors.red
                                                    : _kSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (q.status == QuoteStatus.draft ||
                                    q.status == QuoteStatus.sent ||
                                    q.status == QuoteStatus.accepted)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, right: 8, bottom: 8),
                                    child: Row(
                                      children: [
                                        if (q.status == QuoteStatus.draft)
                                          _actionBtn(
                                              sw ? 'Tuma' : 'Send',
                                              Icons.send_rounded,
                                              () => _sendQuote(q)),
                                        if (q.status == QuoteStatus.accepted)
                                          _actionBtn(
                                              sw
                                                  ? 'Badili Ankara'
                                                  : 'To Invoice',
                                              Icons.swap_horiz_rounded,
                                              () => _convertToInvoice(q)),
                                        if (q.status == QuoteStatus.sent)
                                          _actionBtn(
                                              sw ? 'Kataa' : 'Reject',
                                              Icons.close_rounded,
                                              () => _rejectQuote(q)),
                                        _actionBtn(
                                            sw ? 'Shiriki' : 'Share',
                                            Icons.share_rounded,
                                            () => _shareQuote(q)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        height: 36,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 14),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kPrimary, width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
