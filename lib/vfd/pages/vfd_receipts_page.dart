import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../invoices/pages/invoice_detail_page.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class VfdReceiptsPage extends StatelessWidget {
  final int businessId;
  const VfdReceiptsPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: _kBackground,
        body: Column(
          children: [
            Container(
              color: _kCardBg,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TabBar(
                isScrollable: true,
                indicatorColor: _kPrimary,
                labelColor: _kPrimary,
                unselectedLabelColor: _kSecondary,
                tabs: [
                  Tab(text: sw ? 'Auto Fiscalization' : 'Auto Fiscalization'),
                  Tab(text: sw ? 'Risiti' : 'Receipts'),
                  Tab(text: sw ? 'Z Report' : 'Z Report'),
                  Tab(text: sw ? 'Queue & Retry' : 'Queue & Retry'),
                  Tab(text: sw ? 'Compliance' : 'Compliance'),
                  Tab(text: sw ? 'Settings' : 'Settings'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _JourneyOneMonitorScreen(businessId: businessId),
                  _JourneyTwoReceiptScreen(businessId: businessId),
                  _JourneyThreeZReportScreen(businessId: businessId),
                  _JourneyFourRetryQueueScreen(businessId: businessId),
                  _JourneyFiveComplianceScreen(businessId: businessId),
                  _JourneySixControlsScreen(businessId: businessId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VfdInvoiceState {
  final String? token;
  final String? error;
  final List<Invoice> paid;
  final List<Invoice> withReceipt;
  final List<Invoice> withoutReceipt;
  final Map<int, FiscalReceipt> receiptByInvoiceId;
  const _VfdInvoiceState({
    required this.token,
    required this.error,
    required this.paid,
    required this.withReceipt,
    required this.withoutReceipt,
    required this.receiptByInvoiceId,
  });
}

Future<_VfdInvoiceState> _loadVfdInvoiceState(int businessId, DateTime month) async {
  final storage = await LocalStorageService.getInstance();
  final token = storage.getAuthToken();
  if (token == null) {
    return const _VfdInvoiceState(
      token: null,
      error: 'Please log in first',
      paid: [],
      withReceipt: [],
      withoutReceipt: [],
      receiptByInvoiceId: {},
    );
  }
  final userId = storage.getUser()?.userId;
  final invoicesRes = await BusinessService.getInvoices(token, businessId);
  if (!invoicesRes.success) {
    return _VfdInvoiceState(
      token: token,
      error: invoicesRes.message ?? 'Failed to load invoices',
      paid: const [],
      withReceipt: const [],
      withoutReceipt: const [],
      receiptByInvoiceId: const {},
    );
  }
  final receiptByInvoiceId = <int, FiscalReceipt>{};
  if (userId != null) {
    final receiptsRes = await BusinessService.getFiscalReceipts(token, businessId, userId);
    if (receiptsRes.success) {
      for (final r in receiptsRes.data) {
        final invoiceId = r.invoiceId;
        if (invoiceId != null) {
          receiptByInvoiceId[invoiceId] = r;
        }
      }
    }
  }
  final paid = invoicesRes.data
      .where((inv) => inv.status == InvoiceStatus.paid)
      .where((inv) {
        final d = inv.paidAt ?? inv.createdAt;
        return d != null && d.year == month.year && d.month == month.month;
      })
      .toList()
    ..sort((a, b) {
      final da = a.paidAt ?? a.createdAt ?? DateTime(2000);
      final db = b.paidAt ?? b.createdAt ?? DateTime(2000);
      return db.compareTo(da);
    });
  final withReceipt = paid
      .where((i) => i.vfdReceiptNumber != null && i.vfdReceiptNumber!.isNotEmpty)
      .toList();
  final withoutReceipt = paid
      .where((i) => i.vfdReceiptNumber == null || i.vfdReceiptNumber!.isEmpty)
      .toList();
  return _VfdInvoiceState(
    token: token,
    error: null,
    paid: paid,
    withReceipt: withReceipt,
    withoutReceipt: withoutReceipt,
    receiptByInvoiceId: receiptByInvoiceId,
  );
}

List<DateTime> _recentMonths() {
  final now = DateTime.now();
  return List.generate(6, (i) => DateTime(now.year, now.month - i));
}

String _fmtCurrency(double v) =>
    NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0).format(v);

String _fmtDate(DateTime? d) => d == null ? '—' : DateFormat('dd MMM yyyy').format(d);

String _fmtMonth(DateTime d) => DateFormat('MMM yyyy').format(d);

class _JourneyOneMonitorScreen extends StatefulWidget {
  final int businessId;
  const _JourneyOneMonitorScreen({required this.businessId});

  @override
  State<_JourneyOneMonitorScreen> createState() => _JourneyOneMonitorScreenState();
}

class _JourneyOneMonitorScreenState extends State<_JourneyOneMonitorScreen> {
  late DateTime _selectedMonth;
  late List<DateTime> _months;
  bool _loading = true;
  String? _error;
  _VfdInvoiceState? _state;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _months = _recentMonths();
    _selectedMonth = _months.first;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = await _loadVfdInvoiceState(widget.businessId, _selectedMonth);
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
      _error = state.error == 'Please log in first' && _sw
          ? 'Tafadhali ingia kwanza'
          : state.error;
    });
  }

  Future<void> _openExternalInvoiceCreator() async {
    final token = _state?.token;
    if (token == null) return;
    final storage = await LocalStorageService.getInstance();
    final userId = storage.getUser()?.userId;
    if (userId == null || !mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExternalInvoiceCreateSheet(
        businessId: widget.businessId,
        token: token,
        userId: userId,
      ),
    );
    if (created == true && mounted) {
      _load();
    }
  }

  Future<void> _openDirectReceiptCreator() async {
    final token = _state?.token;
    if (token == null) return;
    final storage = await LocalStorageService.getInstance();
    final userId = storage.getUser()?.userId;
    if (userId == null || !mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DirectFiscalReceiptSheet(
        businessId: widget.businessId,
        token: token,
        userId: userId,
      ),
    );
    if (created == true && mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: _kSecondary)));
    }
    final state = _state!;
    final done = state.withReceipt.length;
    final pending = state.withoutReceipt.length;
    final total = state.paid.length;
    final ratio = total == 0 ? 0.0 : done / total;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sw
                      ? 'Journey 1: Ufuatiliaji wa mark-paid trigger'
                      : 'Journey 1: Mark-paid trigger monitoring',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  _sw
                      ? 'Trigger ipo kwenye invoice flow; hapa ni monitoring/control center.'
                      : 'Trigger stays in invoice flow; this is a monitoring/control center.',
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_sw ? 'Imefiskalishwa' : 'Fiscalized'}: $done / $total  •  ${_sw ? 'Pending' : 'Pending'}: $pending',
                  style: const TextStyle(color: _kPrimary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openExternalInvoiceCreator,
                    icon: const Icon(Icons.document_scanner_rounded, size: 18),
                    label: Text(_sw
                        ? 'Unda external invoice (scan/upload) + fiscalize'
                        : 'Create external invoice (scan/upload) + fiscalize'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openDirectReceiptCreator,
                    icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                    label: Text(_sw
                        ? 'Generate TRA VFD receipt (no invoice)'
                        : 'Generate TRA VFD receipt (no invoice)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _months.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = _months[i];
                final selected = m == _selectedMonth;
                return ChoiceChip(
                  label: Text(_fmtMonth(m)),
                  selected: selected,
                  selectedColor: _kPrimary,
                  labelStyle: TextStyle(color: selected ? Colors.white : _kSecondary),
                  onSelected: (_) {
                    setState(() => _selectedMonth = m);
                    _load();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ...state.withoutReceipt.take(10).map(
                (inv) => _card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.warning_amber_rounded, color: _kPrimary),
                    title: Text('${_sw ? 'Ankara' : 'Invoice'} #${inv.invoiceNumber}'),
                    subtitle: Text('${_fmtCurrency(inv.totalAmount)} • ${_fmtDate(inv.paidAt)}'),
                    trailing: OutlinedButton(
                      onPressed: inv.id == null || state.token == null
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final res = await BusinessService.retryVfdReceipt(
                                state.token!,
                                inv.id!,
                              );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(res.message ?? 'Retry scheduled')),
                              );
                              _load();
                            },
                      child: Text(_sw ? 'Retry now' : 'Retry now'),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _JourneyTwoReceiptScreen extends StatefulWidget {
  final int businessId;
  const _JourneyTwoReceiptScreen({required this.businessId});

  @override
  State<_JourneyTwoReceiptScreen> createState() => _JourneyTwoReceiptScreenState();
}

class _JourneyTwoReceiptScreenState extends State<_JourneyTwoReceiptScreen> {
  late DateTime _selectedMonth;
  bool _loading = true;
  _VfdInvoiceState? _state;
  String? _error;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = _recentMonths().first;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final state = await _loadVfdInvoiceState(widget.businessId, _selectedMonth);
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
      _error = state.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kPrimary));
    if (_error != null) return Center(child: Text(_error!));
    final invoices = _state!.withReceipt;
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_sw ? 'Hakuna risiti mwezi huu' : 'No receipts for this month'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _load,
              child: Text(_sw ? 'Jaribu tena' : 'Retry'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: invoices.map(_receiptCard).toList(),
      ),
    );
  }

  Widget _receiptCard(Invoice inv) {
    final receipt = _state?.receiptByInvoiceId[inv.id];
    final verificationUrl = inv.vfdReceiptUrl ?? '';
    final verificationCode = (receipt?.fiscalCode?.isNotEmpty ?? false)
        ? receipt!.fiscalCode!
        : (inv.vfdReceiptNumber?.split('-').last ?? inv.vfdReceiptNumber ?? '');
    final receiptNumber = receipt?.receiptNumber ?? inv.vfdReceiptNumber ?? '—';
    final issued = receipt?.issuedAt ?? inv.paidAt;
    final gc = _extractCounter(receipt?.fiscalCode, 'GC') ??
        _extractCounter(receipt?.qrCode, 'GC') ??
        '—';
    final dc = _extractCounter(receipt?.fiscalCode, 'DC') ??
        _extractCounter(receipt?.qrCode, 'DC') ??
        (issued != null ? DateFormat('yyyyMMdd').format(issued) : '—');
    final znum = _extractCounter(receipt?.fiscalCode, 'ZNUM') ??
        _extractCounter(receipt?.qrCode, 'ZNUM') ??
        (issued != null ? DateFormat('yyyyMMdd').format(issued) : '—');
    final shareTemplate =
        '${_sw ? "Risiti ya VFD" : "VFD Receipt"}\n${_sw ? "Ankara" : "Invoice"}: ${inv.invoiceNumber}\n${_sw ? "Kiasi" : "Amount"}: ${_fmtCurrency(inv.totalAmount)}\nRCTNUM: $receiptNumber\nGC: $gc\nDC: $dc\nZNUM: $znum\n${_sw ? "Msimbo wa Uhakiki" : "Verification Code"}: $verificationCode\n${_sw ? "Linki ya Uhakiki" : "Verification Link"}: $verificationUrl';
    return _card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_rounded, color: _kPrimary),
            title: Text(receiptNumber),
            subtitle: Text(
              '${_sw ? 'Ankara' : 'Invoice'} #${inv.invoiceNumber} • ${_fmtCurrency(inv.totalAmount)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoiceDetailPage(
                    invoice: inv,
                    businessId: widget.businessId,
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipField('RCTNUM', receiptNumber),
              _chipField('GC', gc),
              _chipField('DC', dc),
              _chipField('ZNUM', znum),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: verificationCode.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: verificationCode));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_sw
                                  ? 'Msimbo wa uhakiki umenakiliwa'
                                  : 'Verification code copied'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(_sw ? 'Nakili Msimbo' : 'Copy Code'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: verificationUrl.isEmpty
                      ? null
                      : () async {
                          final uri = Uri.tryParse(verificationUrl);
                          if (uri == null) return;
                          final opened = await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                          if (!opened && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_sw
                                    ? 'Imeshindikana kufungua ukurasa wa TRA'
                                    : 'Could not open TRA verification page'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.verified_rounded, size: 16),
                  label: Text(_sw ? 'Thibitisha TRA' : 'Verify on TRA'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: verificationUrl.isEmpty
                      ? null
                      : () {
                          final uri = Uri.tryParse(verificationUrl);
                          if (uri != null) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(_sw ? 'Pakua' : 'Download'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: verificationUrl.isEmpty
                      ? null
                      : () => SharePlus.instance
                          .share(ShareParams(text: shareTemplate)),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(_sw ? 'Shiriki' : 'Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value',
          style: const TextStyle(color: _kSecondary, fontSize: 11)),
    );
  }
}

class _JourneyThreeZReportScreen extends StatefulWidget {
  final int businessId;
  const _JourneyThreeZReportScreen({required this.businessId});

  @override
  State<_JourneyThreeZReportScreen> createState() => _JourneyThreeZReportScreenState();
}

class _JourneyThreeZReportScreenState extends State<_JourneyThreeZReportScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _token;
  int? _userId;
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic> _todayDraft = const {};

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    _token = token;
    _userId = userId;
    if (token == null || userId == null) {
      setState(() => _loading = false);
      return;
    }
    final res = await BusinessService.getVfdZReports(token, widget.businessId, userId);
    final invState = await _loadVfdInvoiceState(widget.businessId, DateTime.now());
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayPaid = invState.paid.where((inv) {
      final d = inv.paidAt ?? inv.createdAt;
      return d != null && DateFormat('yyyy-MM-dd').format(d) == todayKey;
    }).toList();
    final totalAmount = todayPaid.fold<double>(0, (s, inv) => s + inv.totalAmount);
    final totalVat = todayPaid.fold<double>(0, (s, inv) => s + inv.vatAmount);
    if (!mounted) return;
    setState(() {
      _reports = res.data;
      _todayDraft = {
        'total_daily_amount': totalAmount,
        'vat_total': totalVat,
        'receipt_count': todayPaid.length,
        'payment_breakdown': {'unknown': totalAmount},
        'void_count': 0,
        'correction_count': 0,
      };
      _loading = false;
    });
  }

  Future<void> _submitToday() async {
    if (_token == null || _userId == null) return;
    setState(() => _submitting = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await BusinessService.submitVfdZReport(
      _token!,
      widget.businessId,
      _userId!,
      businessDate: today,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success
            ? (_sw ? 'Z report imetumwa' : 'Z report submitted')
            : (res.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kPrimary));
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final submittedToday = _reports.any((r) =>
        (r['business_date']?.toString() ?? '').startsWith(todayKey) &&
        (r['status']?.toString().toLowerCase().contains('submitted') ?? false));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!submittedToday)
          _card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: _kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sw
                        ? 'Z report ya leo haijatumwa'
                        : 'Today Z report is not submitted',
                    style: const TextStyle(color: _kPrimary),
                  ),
                ),
              ],
            ),
          ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_sw ? 'Journey 3: Daily Z Report' : 'Journey 3: Daily Z Report Close',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              Text(
                _sw
                    ? 'Kagua draft, tuma, na fatilia ACK za Z report.'
                    : 'Review draft, submit, and monitor Z report ACK status.',
                style: const TextStyle(color: _kSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _submitToday,
                icon: const Icon(Icons.task_alt_rounded),
                label: Text(_submitting
                    ? (_sw ? 'Inatuma...' : 'Submitting...')
                    : (_sw ? 'Tuma Z Report ya Leo' : "Submit Today's Z Report")),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_sw ? 'Draft Z Report (leo)' : 'Draft Z Report (today)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              Text(
                  '${_sw ? 'Jumla ya mauzo' : 'Total daily amount'}: ${_fmtCurrency((_todayDraft['total_daily_amount'] as num?)?.toDouble() ?? 0)}',
                  style: const TextStyle(color: _kSecondary)),
              Text(
                  '${_sw ? 'Jumla ya VAT' : 'VAT bucket total'}: ${_fmtCurrency((_todayDraft['vat_total'] as num?)?.toDouble() ?? 0)}',
                  style: const TextStyle(color: _kSecondary)),
              Text(
                  '${_sw ? 'Idadi ya risiti' : 'Receipt count'}: ${_todayDraft['receipt_count'] ?? 0}',
                  style: const TextStyle(color: _kSecondary)),
              Text(
                  '${_sw ? 'Void/corrections' : 'Void/corrections'}: ${_todayDraft['void_count'] ?? 0}/${_todayDraft['correction_count'] ?? 0}',
                  style: const TextStyle(color: _kSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ..._reports.map((r) => _card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Z: ${r['znum'] ?? '—'}'),
                subtitle: Text(
                    '${r['business_date'] ?? '—'} • ${r['ack_message'] ?? r['status'] ?? '—'}'),
                trailing: Text('${r['ack_code'] ?? '-'}'),
              ),
            )),
      ],
    );
  }
}

class _JourneyFourRetryQueueScreen extends StatefulWidget {
  final int businessId;
  const _JourneyFourRetryQueueScreen({required this.businessId});

  @override
  State<_JourneyFourRetryQueueScreen> createState() =>
      _JourneyFourRetryQueueScreenState();
}

class _JourneyFourRetryQueueScreenState extends State<_JourneyFourRetryQueueScreen> {
  String _status = 'pending';
  bool _loading = true;
  String? _token;
  int? _userId;
  List<Map<String, dynamic>> _outbox = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    _token = token;
    _userId = userId;
    if (token == null || userId == null) {
      if (!mounted) return;
      setState(() {
        _outbox = [];
        _loading = false;
      });
      return;
    }
    final res = await BusinessService.getVfdOutbox(
      token,
      widget.businessId,
      userId,
      status: _status,
    );
    if (!mounted) return;
    setState(() {
      _outbox = res.data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kPrimary));
    if (_outbox.isEmpty) {
      return Center(child: Text(_sw ? 'Hakuna items kwenye queue' : 'No queue items'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final s in const ['pending', 'ack_failed', 'network_retry', 'dead_letter'])
                ChoiceChip(
                  label: Text(s),
                  selected: _status == s,
                  onSelected: (_) {
                    setState(() => _status = s);
                    _load();
                  },
                )
            ],
          ),
          const SizedBox(height: 10),
          _card(
            child: Text(
              _sw
                  ? 'Journey 4: Kituo cha retry kwa payload za receipt/z-report.'
                  : 'Journey 4: Retry center for receipt/z-report payloads.',
              style: const TextStyle(color: _kSecondary),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _token == null || _userId == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final res =
                        await BusinessService.retryAllEligibleVfdOutbox(
                      _token!,
                      widget.businessId,
                      _userId!,
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Done')));
                    _load();
                  },
            icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
            label: Text(_sw ? 'Retry all eligible' : 'Retry all eligible'),
          ),
          const SizedBox(height: 10),
          ..._outbox.map((row) => _retryCard(row)),
        ],
      ),
    );
  }

  Widget _retryCard(Map<String, dynamic> row) {
    final outboxId = _asInt(row['id']);
    final payloadType = row['payload_type']?.toString() ?? 'receipt';
    final attempts = _asInt(row['attempt_count']) ?? 0;
    final nextRetry = row['next_retry_at']?.toString();
    final requestHash = row['request_hash']?.toString() ?? '—';
    return _card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_problem_rounded, color: _kPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    '${payloadType.toUpperCase()} • ${row['status']?.toString() ?? 'unknown'}'),
              ),
              OutlinedButton(
                onPressed: outboxId == null || _token == null || _userId == null
                    ? null
                    : () async {
                        final res =
                            await BusinessService.retryVfdOutboxItem(
                          _token!,
                          outboxId,
                          _userId!,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(res.message ?? 'Submitted')));
                        _load();
                      },
                child: const Text('Retry'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              '${_sw ? 'Attempts' : 'Attempts'}: $attempts  •  ${_sw ? 'Next retry' : 'Next retry'}: ${nextRetry ?? '—'}',
              style: const TextStyle(color: _kSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${_sw ? 'Last error' : 'Last error'}: ${row['last_error'] ?? '—'}',
              style: const TextStyle(color: _kSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Hash: $requestHash',
              style: const TextStyle(color: _kSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              final logs = row['retry_logs']?.toString() ?? row.toString();
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(_sw ? 'Maelezo ya retry' : 'Retry details'),
                  content: SingleChildScrollView(child: Text(logs)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_sw ? 'Funga' : 'Close'),
                    )
                  ],
                ),
              );
            },
            child: Text(_sw ? 'View logs' : 'View logs'),
          )
        ],
      ),
    );
  }
}

class _JourneyFiveComplianceScreen extends StatefulWidget {
  final int businessId;
  const _JourneyFiveComplianceScreen({required this.businessId});

  @override
  State<_JourneyFiveComplianceScreen> createState() =>
      _JourneyFiveComplianceScreenState();
}

class _JourneyFiveComplianceScreenState extends State<_JourneyFiveComplianceScreen> {
  String _period = '30d';
  bool _includeLogs = false;
  bool _loading = true;
  String? _token;
  int? _userId;
  Map<String, dynamic> _dashboard = {};
  String? _error;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    _token = token;
    _userId = userId;
    if (token == null || userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _sw ? 'Tafadhali ingia kwanza' : 'Please log in first';
      });
      return;
    }
    final res = await BusinessService.getVfdComplianceDashboard(
      token,
      widget.businessId,
      userId,
      period: _period,
    );
    if (!mounted) return;
    setState(() {
      _dashboard = res.data ?? {};
      _loading = false;
      _error = res.success ? null : res.message;
    });
  }

  Future<void> _export(String format) async {
    if (_token == null || _userId == null) return;
    final res = await BusinessService.exportVfdComplianceReport(
      _token!,
      widget.businessId,
      _userId!,
      format: format,
      includeDetailLogs: _includeLogs,
      period: _period,
    );
    if (!mounted) return;
    if (!res.success || (res.data ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
      );
      return;
    }
    final uri = Uri.tryParse(res.data!);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kPrimary));
    if (_error != null) return Center(child: Text(_error!));

    final score = _dashboard['compliance_score'] ??
        _dashboard['score'] ??
        _dashboard['success_rate'] ??
        0;
    final pending = _dashboard['pending_count'] ?? _dashboard['pending'] ?? 0;
    final missedZ = _dashboard['missed_z_reports'] ?? _dashboard['missed_z'] ?? 0;
    final tokenHealth = _dashboard['token_health']?.toString() ??
        _dashboard['certificate_health']?.toString() ??
        'unknown';
    final risk = _dashboard['risk_reason']?.toString();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final p in const ['today', '7d', '30d'])
                ChoiceChip(
                  label: Text(p),
                  selected: _period == p,
                  onSelected: (_) {
                    setState(() => _period = p);
                    _load();
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (risk != null && risk.isNotEmpty)
            _card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.priority_high_rounded, color: _kPrimary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(risk)),
                ],
              ),
            ),
          _metricCard(_sw ? 'Compliance score' : 'Compliance score', '$score'),
          _metricCard(_sw ? 'Pending count' : 'Pending count', '$pending'),
          _metricCard(_sw ? 'Missed Z reports' : 'Missed Z reports', '$missedZ'),
          _metricCard(_sw ? 'Token/Cert health' : 'Token/Cert health', tokenHealth),
          SwitchListTile(
            value: _includeLogs,
            onChanged: (v) => setState(() => _includeLogs = v),
            title: Text(_sw ? 'Jumuisha detail logs' : 'Include detail logs'),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _export('pdf'),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _export('csv'),
                  icon: const Icon(Icons.table_chart_rounded, size: 18),
                  label: const Text('CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final text =
                  'Compliance ${DateFormat('yyyy-MM-dd').format(DateTime.now())}\nScore: $score\nPending: $pending\nMissed Z: $missedZ';
              await SharePlus.instance.share(ShareParams(text: text));
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(_sw ? 'Share with Accountant' : 'Share with Accountant'),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return _card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: _kSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
    );
  }
}

class _JourneySixControlsScreen extends StatefulWidget {
  final int businessId;
  const _JourneySixControlsScreen({required this.businessId});

  @override
  State<_JourneySixControlsScreen> createState() => _JourneySixControlsScreenState();
}

class _JourneySixControlsScreenState extends State<_JourneySixControlsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _token;
  int? _userId;

  String _environment = 'test';
  final _certSerialCtrl = TextEditingController();
  final _keyRefCtrl = TextEditingController();
  final _maxAttemptsCtrl = TextEditingController(text: '10');
  final _backoffCtrl = TextEditingController(text: '1,3,10,30,120');
  bool _alertsEnabled = true;
  bool _blockUnsafeRetries = true;
  bool _requireAdminConfirmation = true;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _certSerialCtrl.dispose();
    _keyRefCtrl.dispose();
    _maxAttemptsCtrl.dispose();
    _backoffCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    _token = token;
    _userId = userId;
    if (token == null || userId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    final res = await BusinessService.getVfdSettings(token, widget.businessId, userId);
    if (!mounted) return;
    setState(() {
      final data = res.data ?? {};
      _environment = data['environment']?.toString() ?? _environment;
      _certSerialCtrl.text = data['certificate_serial']?.toString() ?? '';
      _keyRefCtrl.text = data['certificate_key_reference']?.toString() ?? '';
      _maxAttemptsCtrl.text =
          (data['max_retry_attempts'] ?? _maxAttemptsCtrl.text).toString();
      _backoffCtrl.text = data['backoff_schedule']?.toString() ?? _backoffCtrl.text;
      _alertsEnabled = _asBool(data['alerts_enabled']) ?? _alertsEnabled;
      _blockUnsafeRetries =
          _asBool(data['block_unsafe_retries']) ?? _blockUnsafeRetries;
      _requireAdminConfirmation =
          _asBool(data['require_admin_confirmation']) ?? _requireAdminConfirmation;
      _loading = false;
    });
  }

  Future<bool> _reauth() async {
    final passCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_sw ? 'Thibitisha tena' : 'Re-authenticate'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _sw ? 'Nenosiri/PIN' : 'Password/PIN',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_sw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, passCtrl.text.trim().isNotEmpty),
            child: Text(_sw ? 'Endelea' : 'Continue'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _save() async {
    if (_token == null || _userId == null) return;
    final pass = await _reauth();
    if (!pass) return;
    setState(() => _saving = true);
    final res = await BusinessService.updateVfdSettings(_token!, widget.businessId, _userId!, {
      'environment': _environment,
      'certificate_serial': _certSerialCtrl.text.trim(),
      'certificate_key_reference': _keyRefCtrl.text.trim(),
      'max_retry_attempts': int.tryParse(_maxAttemptsCtrl.text.trim()) ?? 10,
      'backoff_schedule': _backoffCtrl.text.trim(),
      'alerts_enabled': _alertsEnabled,
      'block_unsafe_retries': _blockUnsafeRetries,
      'require_admin_confirmation': _requireAdminConfirmation,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(res.success
              ? (res.message ?? (_sw ? 'Imehifadhiwa' : 'Saved'))
              : (res.message ?? (_sw ? 'Imeshindikana' : 'Failed')))),
    );
  }

  Future<void> _rotateCredentials() async {
    if (_token == null || _userId == null) return;
    final pass = await _reauth();
    if (!pass) return;
    setState(() => _saving = true);
    final res = await BusinessService.rotateVfdCredentials(
        _token!, widget.businessId, _userId!, {
      'certificate_serial': _certSerialCtrl.text.trim(),
      'certificate_key_reference': _keyRefCtrl.text.trim(),
      'environment': _environment,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(res.success
              ? (res.message ?? (_sw ? 'Rotation imekamilika' : 'Rotation completed'))
              : (res.message ?? (_sw ? 'Imeshindikana' : 'Failed')))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kPrimary));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sw
                    ? 'Journey 6: VFD settings, rotation, safety controls'
                    : 'Journey 6: VFD settings, rotation, safety controls',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _sw
                    ? 'Hakuna registration/token management hapa, ni operational controls tu.'
                    : 'No registration/token management here, only operational controls.',
                style: const TextStyle(color: _kSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(_environment),
                initialValue: _environment,
                decoration:
                    InputDecoration(labelText: _sw ? 'Environment' : 'Environment'),
                items: const [
                  DropdownMenuItem(value: 'test', child: Text('Test')),
                  DropdownMenuItem(value: 'production', child: Text('Production')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _environment = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _certSerialCtrl,
                decoration: InputDecoration(
                    labelText: _sw ? 'Certificate serial' : 'Certificate serial'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _keyRefCtrl,
                decoration: InputDecoration(
                    labelText: _sw
                        ? 'Certificate key reference'
                        : 'Certificate key reference'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _maxAttemptsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: _sw ? 'Max retry attempts' : 'Max retry attempts'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _backoffCtrl,
                decoration: InputDecoration(
                    labelText: _sw
                        ? 'Backoff schedule (min)'
                        : 'Backoff schedule (min)'),
              ),
              SwitchListTile(
                value: _alertsEnabled,
                onChanged: (v) => setState(() => _alertsEnabled = v),
                title: Text(_sw ? 'Washa alerts' : 'Enable alerts'),
              ),
              SwitchListTile(
                value: _blockUnsafeRetries,
                onChanged: (v) => setState(() => _blockUnsafeRetries = v),
                title: Text(_sw ? 'Zuia retries zisizo salama' : 'Block unsafe retries'),
              ),
              SwitchListTile(
                value: _requireAdminConfirmation,
                onChanged: (v) => setState(() => _requireAdminConfirmation = v),
                title:
                    Text(_sw ? 'Hitaji uthibitisho wa admin' : 'Require admin confirmation'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _rotateCredentials,
                icon: const Icon(Icons.sync_lock_rounded, size: 18),
                label: Text(_sw ? 'Rotate Credentials' : 'Rotate Credentials'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(_sw ? 'Hifadhi' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _card({required Widget child, EdgeInsetsGeometry? margin}) {
  return Container(
    margin: margin,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v == 1;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}

String? _extractCounter(String? source, String key) {
  if (source == null || source.isEmpty) return null;
  final regex = RegExp('(?:^|[;|,\\s])$key[:=\\-]?([A-Za-z0-9_\\-]+)');
  final m = regex.firstMatch(source);
  return m?.group(1);
}

class _ExternalInvoiceCreateSheet extends StatefulWidget {
  final int businessId;
  final String token;
  final int userId;
  const _ExternalInvoiceCreateSheet({
    required this.businessId,
    required this.token,
    required this.userId,
  });

  @override
  State<_ExternalInvoiceCreateSheet> createState() =>
      _ExternalInvoiceCreateSheetState();
}

class _ExternalInvoiceCreateSheetState extends State<_ExternalInvoiceCreateSheet> {
  final _customerCtrl = TextEditingController();
  final _invoiceNumberCtrl = TextEditingController();
  final _tinCtrl = TextEditingController();
  final _vrnCtrl = TextEditingController();
  final _descriptionCtrl =
      TextEditingController(text: 'External invoice from scan/upload');
  final _amountCtrl = TextEditingController();
  final _vatCtrl = TextEditingController(text: '18');
  final _notesCtrl = TextEditingController();
  final _picker = ImagePicker();

  XFile? _image;
  bool _saving = false;
  bool _ocrBusy = false;
  String? _ocrHint;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _invoiceNumberCtrl.dispose();
    _tinCtrl.dispose();
    _vrnCtrl.dispose();
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    _vatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 85,
    );
    if (!mounted || x == null) return;
    setState(() {
      _image = x;
      _ocrHint = null;
    });
    await _runOcrPrefill(x);
  }

  Future<void> _runOcrPrefill(XFile imageFile) async {
    setState(() => _ocrBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final recognized = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      final raw = recognized.text.trim();
      if (raw.isEmpty) {
        if (!mounted) return;
        setState(() => _ocrHint = _sw
            ? 'OCR haikupata maandishi yanayosomeka'
            : 'OCR did not detect readable text');
        return;
      }
      final lines = raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final extractedAmount = _extractAmount(raw);
      final extractedInvoiceNo = _extractInvoiceOrReceiptNumber(raw);
      final extractedVendor = _extractVendor(lines);
      final extractedTin = _extractTin(raw);
      final extractedVrn = _extractVrn(raw);
      if (_amountCtrl.text.trim().isEmpty && extractedAmount != null) {
        _amountCtrl.text = extractedAmount.toStringAsFixed(2);
      }
      if (_invoiceNumberCtrl.text.trim().isEmpty && extractedInvoiceNo != null) {
        _invoiceNumberCtrl.text = extractedInvoiceNo;
      }
      if (_customerCtrl.text.trim().isEmpty && extractedVendor != null) {
        _customerCtrl.text = extractedVendor;
      }
      if (_tinCtrl.text.trim().isEmpty && extractedTin != null) {
        _tinCtrl.text = extractedTin;
      }
      if (_vrnCtrl.text.trim().isEmpty && extractedVrn != null) {
        _vrnCtrl.text = extractedVrn;
      }
      if (_descriptionCtrl.text.trim().isEmpty) {
        _descriptionCtrl.text =
            _sw ? 'External invoice line' : 'External invoice line';
      }
      if (!mounted) return;
      setState(() {
        _ocrHint = _sw
            ? 'OCR imejaza baadhi ya taarifa. Hakiki kabla ya kutuma.'
            : 'OCR prefilled fields. Please verify before submitting.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ocrHint = _sw
            ? 'OCR imeshindikana, jaza fields kwa mkono.'
            : 'OCR failed, fill fields manually.';
      });
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _ocrBusy = false);
    }
  }

  Future<void> _createAndFiscalize() async {
    final messenger = ScaffoldMessenger.of(context);
    final customer = _customerCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0;
    final vatRate = double.tryParse(_vatCtrl.text.trim().replaceAll(',', '')) ?? 18;
    if (customer.isEmpty || description.isEmpty || amount <= 0) {
      messenger.showSnackBar(SnackBar(
        content: Text(_sw
            ? 'Jaza customer, description na amount sahihi'
            : 'Enter customer, description, and a valid amount'),
      ));
      return;
    }
    setState(() => _saving = true);
    final vatAmount = amount * (vatRate / 100);
    final totalAmount = amount + vatAmount;
    final notes = [
      _notesCtrl.text.trim(),
      if (_image != null) 'external_invoice_image: ${_image!.path}',
      if (_invoiceNumberCtrl.text.trim().isNotEmpty)
        'external_invoice_number: ${_invoiceNumberCtrl.text.trim()}',
      if (_tinCtrl.text.trim().isNotEmpty)
        'external_vendor_tin: ${_tinCtrl.text.trim()}',
      if (_vrnCtrl.text.trim().isNotEmpty)
        'external_vendor_vrn: ${_vrnCtrl.text.trim()}',
      'source: external_scan_upload',
    ].where((e) => e.isNotEmpty).join('\n');
    final body = <String, dynamic>{
      'user_id': widget.userId,
      'business_id': widget.businessId,
      'customer_name': customer,
      'customer_tin':
          _tinCtrl.text.trim().isNotEmpty ? _tinCtrl.text.trim() : null,
      'items': [
        {
          'description': description,
          'quantity': 1,
          'unit_label': 'pcs',
          'unit_price': amount,
          'total_price': amount,
          'is_vat_exempt': false,
        }
      ],
      'subtotal': amount,
      'discount_value': 0,
      'discount_amount': 0,
      'vat_rate': vatRate,
      'vat_amount': vatAmount,
      'total_amount': totalAmount,
      'due_date': DateTime.now().toIso8601String(),
      'notes': notes,
      'status': 'paid',
      'amount_paid': totalAmount,
      'balance_remaining': 0,
    };
    try {
      final invoiceRes = await BusinessService.createInvoice(widget.token, body);
      if (!mounted) return;
      if (!invoiceRes.success || invoiceRes.data?.id == null) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(
          content: Text(invoiceRes.message ?? (_sw ? 'Imeshindikana' : 'Failed')),
        ));
        return;
      }
      final fiscalRes = await BusinessService.issueFiscalReceipt(
        widget.token,
        invoiceRes.data!.id!,
        widget.userId,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      if (fiscalRes.success) {
        messenger.showSnackBar(SnackBar(
          content: Text(_sw
              ? 'External invoice imeundwa na kufiscalize'
              : 'External invoice created and fiscalized'),
        ));
        Navigator.pop(context, true);
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(fiscalRes.message ??
              (_sw
                  ? 'Invoice imeundwa, fiscalization imeshindikana'
                  : 'Invoice created, fiscalization failed')),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _sw
                      ? 'External Invoice (Scan/Upload) + Fiscalize'
                      : 'External Invoice (Scan/Upload) + Fiscalize',
                  style: const TextStyle(
                      color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: Text(_sw ? 'Scan Camera' : 'Scan Camera'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(_sw ? 'Upload Image' : 'Upload Image'),
                      ),
                    ),
                  ],
                ),
                if (_image != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton.icon(
                        onPressed:
                            _ocrBusy ? null : () => _runOcrPrefill(_image!),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(_sw ? 'Run OCR again' : 'Re-run OCR'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_image!.path),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_ocrBusy) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 3),
                  ],
                  if (_ocrHint != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _ocrHint!,
                      style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _customerCtrl,
                  decoration: InputDecoration(
                    labelText: _sw ? 'Vendor/Customer name' : 'Vendor/Customer name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _invoiceNumberCtrl,
                  decoration: InputDecoration(
                    labelText: _sw ? 'Invoice number' : 'Invoice number',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _tinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'TIN'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _vrnCtrl,
                  decoration: const InputDecoration(labelText: 'VRN'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionCtrl,
                  decoration: InputDecoration(
                    labelText: _sw ? 'Item description' : 'Item description',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (TZS)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _vatCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'VAT rate (%)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: _sw ? 'Notes (optional)' : 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _createAndFiscalize,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.receipt_long_rounded, size: 18),
                    label: Text(_saving
                        ? (_sw ? 'Inahifadhi...' : 'Saving...')
                        : (_sw
                            ? 'Unda External Invoice + Fiscalize'
                            : 'Create External Invoice + Fiscalize')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectFiscalReceiptSheet extends StatefulWidget {
  final int businessId;
  final String token;
  final int userId;
  const _DirectFiscalReceiptSheet({
    required this.businessId,
    required this.token,
    required this.userId,
  });

  @override
  State<_DirectFiscalReceiptSheet> createState() =>
      _DirectFiscalReceiptSheetState();
}

class _DirectFiscalReceiptSheetState extends State<_DirectFiscalReceiptSheet> {
  final _customerCtrl = TextEditingController(text: 'Walk-in Customer');
  final _descriptionCtrl = TextEditingController(text: 'Direct VFD sale');
  final _amountCtrl = TextEditingController();
  final _vatCtrl = TextEditingController(text: '18');
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    _vatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final customer = _customerCtrl.text.trim().isEmpty
        ? 'Walk-in Customer'
        : _customerCtrl.text.trim();
    final description = _descriptionCtrl.text.trim().isEmpty
        ? 'Direct VFD sale'
        : _descriptionCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0;
    final vatRate = double.tryParse(_vatCtrl.text.trim().replaceAll(',', '')) ?? 18;
    if (amount <= 0) {
      messenger.showSnackBar(SnackBar(
        content:
            Text(_sw ? 'Weka amount sahihi' : 'Enter a valid amount'),
      ));
      return;
    }
    setState(() => _saving = true);
    final vatAmount = amount * (vatRate / 100);
    final total = amount + vatAmount;
    final body = <String, dynamic>{
      'user_id': widget.userId,
      'business_id': widget.businessId,
      'customer_name': customer,
      'items': [
        {
          'description': description,
          'quantity': 1,
          'unit_label': 'pcs',
          'unit_price': amount,
          'total_price': amount,
          'is_vat_exempt': false,
        }
      ],
      'subtotal': amount,
      'discount_value': 0,
      'discount_amount': 0,
      'vat_rate': vatRate,
      'vat_amount': vatAmount,
      'total_amount': total,
      'due_date': DateTime.now().toIso8601String(),
      'notes': [
        'source: direct_vfd_receipt_no_source_invoice',
        _notesCtrl.text.trim(),
      ].where((e) => e.isNotEmpty).join('\n'),
      'status': 'paid',
      'amount_paid': total,
      'balance_remaining': 0,
    };
    try {
      final invoiceRes = await BusinessService.createInvoice(widget.token, body);
      if (!mounted) return;
      if (!invoiceRes.success || invoiceRes.data?.id == null) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(
            content: Text(invoiceRes.message ??
                (_sw ? 'Imeshindikana kuunda invoice ya ndani' : 'Failed to create internal invoice'))));
        return;
      }
      final fiscalRes = await BusinessService.issueFiscalReceipt(
        widget.token,
        invoiceRes.data!.id!,
        widget.userId,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      if (fiscalRes.success) {
        messenger.showSnackBar(SnackBar(
            content: Text(_sw
                ? 'TRA VFD receipt imezalishwa'
                : 'TRA VFD receipt generated')));
        Navigator.pop(context, true);
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(fiscalRes.message ??
                (_sw
                    ? 'Receipt generation imeshindikana'
                    : 'Receipt generation failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sw
                      ? 'Direct TRA VFD Receipt (No Invoice)'
                      : 'Direct TRA VFD Receipt (No Invoice)',
                  style: const TextStyle(
                      color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Creates an internal paid invoice automatically, then fiscalizes it.',
                  style: TextStyle(color: _kSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customerCtrl,
                  decoration: const InputDecoration(labelText: 'Customer name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Item description'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (TZS)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _vatCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'VAT rate (%)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.receipt_rounded, size: 18),
                    label: Text(_saving
                        ? (_sw ? 'Inahifadhi...' : 'Saving...')
                        : (_sw
                            ? 'Generate Direct TRA VFD Receipt'
                            : 'Generate Direct TRA VFD Receipt')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double? _extractAmount(String text) {
  final amountPatterns = <RegExp>[
    RegExp(r'(?i)(total|amount due|grand total|jumla)\s*[:\-]?\s*(?:tzs|kes|usd)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)'),
    RegExp(r'(?i)(?:tzs|kes|usd)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)'),
  ];
  for (final pattern in amountPatterns) {
    final m = pattern.firstMatch(text);
    if (m != null) {
      final value = m.group(m.groupCount);
      if (value == null) continue;
      final parsed = double.tryParse(value.replaceAll(',', ''));
      if (parsed != null && parsed > 0) return parsed;
    }
  }

  // Fallback: largest plausible numeric amount in the text.
  final values = RegExp(r'([0-9][0-9,]{2,}(?:\.[0-9]{1,2})?)')
      .allMatches(text)
      .map((m) => double.tryParse((m.group(1) ?? '').replaceAll(',', '')))
      .whereType<double>()
      .where((v) => v > 0)
      .toList();
  if (values.isEmpty) return null;
  values.sort();
  return values.last;
}

String? _extractInvoiceOrReceiptNumber(String text) {
  final patterns = <RegExp>[
    // Tanzania-style invoice/receipt labels.
    RegExp(r'(?i)(invoice\s*(?:no|number|#)|tax\s*invoice\s*(?:no|number|#)|receipt\s*(?:no|number|#)|fiscal\s*receipt\s*(?:no|number|#)|risiti\s*no)\s*[:#\-]?\s*([A-Za-z0-9\-\/]{4,})'),
    // Common compact patterns e.g. INV-2026-0001, RCPT/00123.
    RegExp(r'(?i)\b(?:inv|rcpt)[\-_]?\s*([A-Za-z0-9\-\/]{4,})\b'),
    // Fallback for strictly numeric receipt number labels.
    RegExp(r'(?i)(sdc\s*receipt\s*no|receipt\s*id)\s*[:#\-]?\s*([0-9]{4,})'),
  ];
  for (final pattern in patterns) {
    final m = pattern.firstMatch(text);
    if (m != null) {
      final v = m.group(m.groupCount)?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
  }
  return null;
}

String? _extractVendor(List<String> lines) {
  if (lines.isEmpty) return null;
  for (final line in lines.take(8)) {
    final s = line.trim();
    if (s.length < 3) continue;
    if (RegExp(r'(?i)invoice|receipt|tax|tin|date|time|total|amount|vat').hasMatch(s)) {
      continue;
    }
    if (RegExp(r'[A-Za-z]').hasMatch(s)) return s;
  }
  return lines.first;
}

String? _extractTin(String text) {
  final patterns = <RegExp>[
    // Explicit labels: TIN: 123456789
    RegExp(r'(?i)\btin\b\s*[:\-]?\s*([0-9]{9,12})\b'),
    // Backup: "Taxpayer Identification Number"
    RegExp(r'(?i)taxpayer\s+identification\s+number\s*[:\-]?\s*([0-9]{9,12})\b'),
  ];
  for (final pattern in patterns) {
    final m = pattern.firstMatch(text);
    if (m != null) return m.group(1);
  }
  return null;
}

String? _extractVrn(String text) {
  final patterns = <RegExp>[
    // VRN: 40-123456-A or VRN 40123456A
    RegExp(r'(?i)\bvrn\b\s*[:\-]?\s*([A-Za-z0-9\-]{6,20})\b'),
    RegExp(r'(?i)vat\s*registration\s*number\s*[:\-]?\s*([A-Za-z0-9\-]{6,20})\b'),
  ];
  for (final pattern in patterns) {
    final m = pattern.firstMatch(text);
    if (m != null) return m.group(1)?.toUpperCase();
  }
  return null;
}
