// lib/tax/pages/tax_page.dart
// Multi-business tax overview — auto-reads revenue/expenses/VAT from backend.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../reminders/services/reminders_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class TaxPage extends StatefulWidget {
  final List<Business> businesses;
  const TaxPage({super.key, required this.businesses});

  @override
  State<TaxPage> createState() => _TaxPageState();
}

class _TaxPageState extends State<TaxPage> {
  String _period = 'monthly';
  bool _loading = false;
  final Map<int, TaxCalculation> _resultsByBiz = {};
  final Map<int, String> _errorsByBiz = {};

  String? _token;
  int? _userId;
  List<TaxDeadline> _deadlines = [];
  bool _savingReminders = false;
  bool _remindersSaved = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  List<Business> get _validBizs =>
      widget.businesses.where((b) => b.id != null).toList();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId;
    await Future.wait([_load(), _loadDeadlines()]);
  }

  Future<void> _loadDeadlines() async {
    if (_token == null) return;
    final result = await BusinessService.fetchTaxDeadlineConfig(_token!);
    if (!mounted) return;
    if (result.success && result.data.isNotEmpty) {
      setState(() => _deadlines = result.data);
    }
  }

  Future<void> _setTaxReminders() async {
    if (_token == null || _userId == null || _savingReminders) return;
    setState(() => _savingReminders = true);
    final sw = _isSwahili;

    final templates = await BusinessService.getTaxDeadlines(_token!, _userId!);
    int saved = 0;
    for (final t in templates) {
      final standalone = t.copyWith(
        id: 'standalone_tax_${t.id}',
        isStandalone: true,
      );
      final r = await RemindersService.create(standalone,
          token: _token!, userId: _userId!);
      if (r.success) saved++;
    }

    if (!mounted) return;
    setState(() {
      _savingReminders = false;
      _remindersSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sw
          ? 'Vikumbusho $saved vya kodi vimewekwa!'
          : '$saved tax reminders set successfully!'),
    ));
  }

  (String, String) _dateRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'quarterly':
        final qMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        final from = DateTime(now.year, qMonth, 1);
        final to = DateTime(now.year, qMonth + 3, 0);
        return (DateFormat('yyyy-MM-dd').format(from),
            DateFormat('yyyy-MM-dd').format(to));
      case 'annual':
        return ('${now.year}-01-01', '${now.year}-12-31');
      default: // monthly
        final from = DateTime(now.year, now.month, 1);
        final to = DateTime(now.year, now.month + 1, 0);
        return (DateFormat('yyyy-MM-dd').format(from),
            DateFormat('yyyy-MM-dd').format(to));
    }
  }

  Future<void> _load() async {
    if (_token == null || _validBizs.isEmpty) return;
    setState(() => _loading = true);
    final (dateFrom, dateTo) = _dateRange();

    final futures = _validBizs.map((b) => BusinessService.calculateTax(
          _token!,
          b.id!,
          _period,
          userId: _userId,
          dateFrom: dateFrom,
          dateTo: dateTo,
        ));

    final results = await Future.wait(futures);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _resultsByBiz.clear();
      _errorsByBiz.clear();
      for (var i = 0; i < _validBizs.length; i++) {
        final biz = _validBizs[i];
        final r = results[i];
        if (r.success && r.data != null) {
          _resultsByBiz[biz.id!] = r.data!;
        } else {
          _errorsByBiz[biz.id!] = r.message ?? 'Error';
        }
      }
    });
  }

  TaxCalculation get _aggregate {
    double rev = 0, exp = 0, ct = 0, vatC = 0, vatP = 0, vatD = 0,
        paye = 0, nssf = 0, sdl = 0, wcf = 0, wht = 0;
    for (final r in _resultsByBiz.values) {
      rev += r.revenue;
      exp += r.expenses;
      ct += r.corporateTax;
      vatC += r.vatCollected;
      vatP += r.vatPaid;
      vatD += r.vatDue;
      paye += r.payeTotal;
      nssf += r.nssfTotal;
      sdl += r.sdlTotal;
      wcf += r.wcfTotal;
      wht += r.whtTotal;
    }
    return TaxCalculation(
      period: _period,
      revenue: rev,
      expenses: exp,
      profit: rev - exp,
      corporateTax: ct,
      vatCollected: vatC,
      vatPaid: vatP,
      vatDue: vatD,
      payeTotal: paye,
      nssfTotal: nssf,
      sdlTotal: sdl,
      wcfTotal: wcf,
      whtTotal: wht,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final sw = _isSwahili;
    final multi = _validBizs.length > 1;

    return Container(
      color: _kBackground,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Period selector
            _periodSelector(sw),
            const SizedBox(height: 16),

            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator()))
            else ...[
              // Aggregate card (always shown)
              if (_resultsByBiz.isNotEmpty) ...[
                if (multi)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sw
                                ? 'Jumla — Biashara ${_resultsByBiz.length}'
                                : 'Total — ${_resultsByBiz.length} businesses',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildTaxCard(nf, sw, _aggregate, null),
                const SizedBox(height: 20),
              ],

              // Per-business cards
              if (multi) ...[
                for (final biz in _validBizs) ...[
                  _buildBizHeader(biz, sw),
                  const SizedBox(height: 8),
                  if (_errorsByBiz.containsKey(biz.id!))
                    _buildErrorCard(_errorsByBiz[biz.id!]!, sw)
                  else if (_resultsByBiz.containsKey(biz.id!))
                    _buildTaxCard(nf, sw, _resultsByBiz[biz.id!]!, biz)
                  else
                    _buildEmptyCard(sw),
                  const SizedBox(height: 16),
                ],
              ] else if (_validBizs.isNotEmpty)
                ..._buildSingleBizContent(nf, sw),

              if (_resultsByBiz.isNotEmpty) ...[
                const SizedBox(height: 4),
                _traReminders(sw),
                const SizedBox(height: 16),
                _paymentOptions(sw),
                const SizedBox(height: 16),
                _taxRemindersCta(sw),
              ],
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _periodSelector(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sw ? 'Kipindi' : 'Period',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              _periodChip(sw ? 'Mwezi' : 'Monthly', 'monthly'),
              const SizedBox(width: 8),
              _periodChip(sw ? 'Robo Mwaka' : 'Quarterly', 'quarterly'),
              const SizedBox(width: 8),
              _periodChip(sw ? 'Mwaka' : 'Annual', 'annual'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_period == value) return;
          setState(() => _period = value);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : _kBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _kSecondary,
                )),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSingleBizContent(NumberFormat nf, bool sw) {
    final biz = _validBizs.first;
    if (_errorsByBiz.containsKey(biz.id!)) {
      return [_buildErrorCard(_errorsByBiz[biz.id!]!, sw)];
    }
    if (_resultsByBiz.isEmpty && _errorsByBiz.isEmpty) {
      return [_buildEmptyCard(sw)];
    }
    return [];
  }

  Widget _buildBizHeader(Business biz, bool sw) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.business_rounded, size: 16, color: _kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            biz.name,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTaxCard(
      NumberFormat nf, bool sw, TaxCalculation r, Business? biz) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profit/loss header
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: r.profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  r.profit >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: r.profit >= 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.profit >= 0
                            ? (sw ? 'Faida' : 'Profit')
                            : (sw ? 'Hasara' : 'Loss'),
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                      ),
                      Text(
                        'TZS ${nf.format(r.profit.abs())}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: r.profit >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Text(sw ? 'Maelezo ya Kodi' : 'Tax Breakdown',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary)),
          const SizedBox(height: 10),
          _taxRow(sw ? 'Mapato' : 'Revenue', nf.format(r.revenue)),
          _taxRow(sw ? 'Matumizi' : 'Expenses',
              '- ${nf.format(r.expenses)}',
              color: Colors.red.shade700),
          const Divider(height: 16),
          _taxRow(
              r.profit >= 0
                  ? (sw ? 'Faida' : 'Profit')
                  : (sw ? 'Hasara' : 'Loss'),
              nf.format(r.profit.abs()),
              isBold: true),
          const SizedBox(height: 8),
          _taxRow(
              sw ? 'Kodi ya Kampuni (30%)' : 'Corporate Tax (30%)',
              nf.format(r.corporateTax),
              color: Colors.red.shade700),
          const Divider(height: 16),
          _taxRow(sw ? 'VAT Uliokusanya' : 'VAT Collected',
              nf.format(r.vatCollected)),
          _taxRow(sw ? 'VAT Uliolipa' : 'VAT Paid',
              '- ${nf.format(r.vatPaid)}'),
          _taxRow(sw ? 'VAT Inayodaiwa' : 'VAT Payable',
              nf.format(r.vatDue),
              color: Colors.red.shade700),
          if (r.payeTotal > 0) ...[
            const Divider(height: 16),
            _taxRow(sw ? 'PAYE (Mishahara)' : 'PAYE (Salaries)',
                nf.format(r.payeTotal)),
            _taxRow('NSSF', nf.format(r.nssfTotal)),
            _taxRow('SDL', nf.format(r.sdlTotal)),
            _taxRow('WCF', nf.format(r.wcfTotal)),
          ],
          if (r.whtTotal > 0) ...[
            const Divider(height: 16),
            _taxRow(sw ? 'Kodi ya Zuio (WHT)' : 'Withholding Tax (WHT)',
                nf.format(r.whtTotal),
                color: Colors.red.shade700),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sw ? 'JUMLA YA KODI' : 'TOTAL TAX',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              Text(
                'TZS ${nf.format(r.totalTaxObligation)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String msg, bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style:
                    TextStyle(fontSize: 13, color: Colors.red.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: Text(
          sw ? 'Hakuna data ya kodi' : 'No tax data available',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
      ),
    );
  }

  Widget _taxRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: _kSecondary,
                    fontWeight:
                        isBold ? FontWeight.w600 : FontWeight.normal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('TZS $value',
              style: TextStyle(
                  fontSize: 13,
                  color: color ?? _kPrimary,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _fallbackDeadlines = [
    {'tax': 'VAT', 'deadline': '20th of every month'},
    {'tax': 'PAYE', 'deadline': '7th of the following month'},
    {'tax': 'SDL', 'deadline': '7th of the following month'},
    {'tax': 'NSSF', 'deadline': '7th of the following month'},
    {'tax': 'Corporate Tax', 'deadline': 'Quarterly instalments'},
    {'tax': 'WHT', 'deadline': '7th of the following month'},
  ];

  Widget _traReminders(bool sw) {
    final rows = _deadlines.isNotEmpty
        ? _deadlines
            .map((d) => _reminderRow(d.tax, d.deadline))
            .toList()
        : _fallbackDeadlines
            .map((d) => _reminderRow(d['tax']!, d['deadline']!))
            .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded,
                  color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    sw ? 'Tarehe za Kulipa TRA' : 'TRA Payment Deadlines',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _reminderRow(String label, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(date,
                style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _paymentOptions(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Text(sw ? 'Njia za Kulipa' : 'Payment Options',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('https://www.tra.go.tz');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(sw
                          ? 'Imeshindikana kufungua TRA Portal'
                          : 'Could not open TRA Portal')));
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(sw ? 'Fungua TRA Portal' : 'Open TRA Portal',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(sw ? 'Tarehe za Kufaili TRA:' : 'TRA Filing Deadlines:',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary)),
          const SizedBox(height: 6),
          if (_deadlines.isNotEmpty)
            ..._deadlines.map((d) => _filingRow(d.tax, d.deadline))
          else ...[
            _filingRow('VAT',
                sw ? 'Tarehe 20 ya mwezi unaofuata' : '20th of the following month'),
            _filingRow('PAYE',
                sw ? 'Tarehe 7 ya mwezi unaofuata' : '7th of the following month'),
            _filingRow(
                sw ? 'Kodi ya Kampuni' : 'Corporate Tax',
                sw
                    ? 'Miezi 6 baada ya mwaka wa fedha'
                    : '6 months after financial year'),
          ],
        ],
      ),
    );
  }

  Widget _taxRemindersCta(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw ? 'Vikumbusho vya Kodi' : 'Tax Deadline Reminders',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sw
                ? 'Weka arifa za kiotomatiki kwa kila tarehe ya kodi ya TRA — VAT, PAYE, SDL, NSSF, WHT, na zaidi.'
                : 'Save automatic reminders for TRA filing deadlines — VAT, PAYE, SDL, NSSF, WHT, and more.',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: (_savingReminders || _remindersSaved)
                  ? null
                  : _setTaxReminders,
              icon: _savingReminders
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      _remindersSaved
                          ? Icons.check_circle_rounded
                          : Icons.add_alert_rounded,
                      size: 18,
                    ),
              label: Text(
                _remindersSaved
                    ? (sw ? 'Vikumbusho Vimewekwa' : 'Reminders Set')
                    : (sw ? 'Weka Vikumbusho' : 'Set Tax Reminders'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _remindersSaved ? Colors.green.shade600 : _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filingRow(String label, String deadline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 5, color: _kSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(deadline,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
