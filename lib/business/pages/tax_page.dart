// lib/business/pages/tax_page.dart
// Tax calculator for Tanzanian businesses.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/business_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class TaxPage extends StatefulWidget {
  final int businessId;
  const TaxPage({super.key, required this.businessId});

  @override
  State<TaxPage> createState() => _TaxPageState();
}

class _TaxPageState extends State<TaxPage> {
  String _period = 'monthly';
  final _revenueCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController();
  final _vatCollectedCtrl = TextEditingController();
  final _vatPaidCtrl = TextEditingController();
  TaxCalculation? _result;

  // From payroll data
  final double _payeFromPayroll = 0;
  final double _nssfFromPayroll = 0;
  final double _sdlFromPayroll = 0;
  final double _wcfFromPayroll = 0;

  bool get _isSwahili {
    final s = AppStringsScope.of(context);
    return s?.isSwahili ?? false;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Token available for future API tax calculation
  }

  void _calculate() {
    final revenue =
        double.tryParse(_revenueCtrl.text.replaceAll(',', '')) ?? 0;
    final expenses =
        double.tryParse(_expensesCtrl.text.replaceAll(',', '')) ?? 0;
    final vatCollected =
        double.tryParse(_vatCollectedCtrl.text.replaceAll(',', '')) ?? 0;
    final vatPaid =
        double.tryParse(_vatPaidCtrl.text.replaceAll(',', '')) ?? 0;

    if (revenue <= 0 && expenses <= 0 && vatCollected <= 0 && vatPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Tafadhali weka angalau thamani moja'
              : 'Please enter at least one value')));
      return;
    }

    final profit = revenue - expenses;
    final corporateTax = profit > 0 ? profit * 0.30 : 0.0;
    final vatDue = vatCollected - vatPaid;

    setState(() {
      _result = TaxCalculation(
        businessId: widget.businessId,
        period: _period,
        revenue: revenue,
        expenses: expenses,
        profit: profit,
        corporateTax: corporateTax,
        vatCollected: vatCollected,
        vatPaid: vatPaid,
        vatDue: vatDue > 0 ? vatDue : 0,
        payeTotal: _payeFromPayroll,
        nssfTotal: _nssfFromPayroll,
        sdlTotal: _sdlFromPayroll,
        wcfTotal: _wcfFromPayroll,
      );
    });
  }

  @override
  void dispose() {
    _revenueCtrl.dispose();
    _expensesCtrl.dispose();
    _vatCollectedCtrl.dispose();
    _vatPaidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final sw = _isSwahili;

    return Container(
      color: _kBackground,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period selector
          Container(
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
          ),

          const SizedBox(height: 16),

          // Revenue & Expenses input
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sw ? 'Mapato na Matumizi' : 'Revenue & Expenses',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
                const SizedBox(height: 12),
                _amountField(_revenueCtrl,
                    sw ? 'Mapato (Revenue) TZS' : 'Revenue (TZS)'),
                const SizedBox(height: 10),
                _amountField(_expensesCtrl,
                    sw ? 'Matumizi (Expenses) TZS' : 'Expenses (TZS)'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // VAT input
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sw ? 'VAT (Ushuru wa Ongezeko) — 18%' : 'VAT (Value Added Tax) — 18%',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
                const SizedBox(height: 12),
                _amountField(_vatCollectedCtrl,
                    sw ? 'VAT Uliokusanya (Output Tax) TZS' : 'VAT Collected (Output Tax) TZS'),
                const SizedBox(height: 10),
                _amountField(_vatPaidCtrl,
                    sw ? 'VAT Uliolipa (Input Tax) TZS' : 'VAT Paid (Input Tax) TZS'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Calculate button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_rounded, size: 20),
              label: Text(
                  sw ? 'Hesabu Kodi' : 'Calculate Tax',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 20),

            // Profit card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result!.profit >= 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    _result!.profit >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: _result!.profit >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _result!.profit >= 0
                              ? (sw ? 'Faida' : 'Profit')
                              : (sw ? 'Hasara' : 'Loss'),
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary),
                        ),
                        Text(
                          'TZS ${nf.format(_result!.profit.abs())}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _result!.profit >= 0
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

            const SizedBox(height: 16),

            // Tax breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sw ? 'Maelezo ya Kodi' : 'Tax Breakdown',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  const SizedBox(height: 14),
                  _taxRow(sw ? 'Mapato' : 'Revenue',
                      nf.format(_result!.revenue)),
                  _taxRow(sw ? 'Matumizi' : 'Expenses',
                      '- ${nf.format(_result!.expenses)}',
                      color: Colors.red.shade700),
                  const Divider(height: 16),
                  _taxRow(
                      _result!.profit >= 0
                          ? (sw ? 'Faida' : 'Profit')
                          : (sw ? 'Hasara' : 'Loss'),
                      nf.format(_result!.profit.abs()),
                      isBold: true),
                  const SizedBox(height: 12),
                  _taxRow(
                      sw
                          ? 'Kodi ya Kampuni (30%)'
                          : 'Corporate Tax (30%)',
                      nf.format(_result!.corporateTax),
                      color: Colors.red.shade700),
                  const Divider(height: 16),
                  _taxRow(
                      sw ? 'VAT Uliokusanya' : 'VAT Collected',
                      nf.format(_result!.vatCollected)),
                  _taxRow(sw ? 'VAT Uliolipa' : 'VAT Paid',
                      '- ${nf.format(_result!.vatPaid)}'),
                  _taxRow(sw ? 'VAT Inayodaiwa' : 'VAT Payable',
                      nf.format(_result!.vatDue),
                      color: Colors.red.shade700),
                  if (_result!.payeTotal > 0) ...[
                    const Divider(height: 16),
                    _taxRow(sw ? 'PAYE (Mishahara)' : 'PAYE (Salaries)',
                        nf.format(_result!.payeTotal)),
                    _taxRow('NSSF', nf.format(_result!.nssfTotal)),
                    _taxRow('SDL', nf.format(_result!.sdlTotal)),
                    _taxRow('WCF', nf.format(_result!.wcfTotal)),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sw ? 'JUMLA YA KODI' : 'TOTAL TAX',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary)),
                      Text(
                        'TZS ${nf.format(_result!.totalTaxObligation)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TRA payment reminders
            _traReminders(sw),

            const SizedBox(height: 16),

            // Payment options
            _paymentOptions(sw),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = value),
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

  Widget _amountField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _traReminders(bool sw) {
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
          _reminderRow('VAT',
              sw ? 'Tarehe 20 ya kila mwezi' : '20th of every month'),
          _reminderRow('PAYE',
              sw ? 'Tarehe 7 ya mwezi unaofuata' : '7th of the following month'),
          _reminderRow('SDL',
              sw ? 'Tarehe 7 ya mwezi unaofuata' : '7th of the following month'),
          _reminderRow('NSSF',
              sw ? 'Tarehe 7 ya mwezi unaofuata' : '7th of the following month'),
          _reminderRow(sw ? 'Kodi ya Mapato' : 'Income Tax',
              sw ? 'Tarehe ya mwisho kulingana na aina' : 'Deadline depends on type'),
          _reminderRow(sw ? 'Kodi ya Kampuni' : 'Corporate Tax',
              sw ? 'Awamu kila robo mwaka' : 'Quarterly instalments'),
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
                style: TextStyle(
                    fontSize: 12, color: Colors.blue.shade600),
                maxLines: 1,
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
          _filingRow('VAT',
              sw ? 'Tarehe 20 ya mwezi unaofuata' : '20th of the following month'),
          _filingRow('PAYE',
              sw ? 'Tarehe 7 ya mwezi unaofuata' : '7th of the following month'),
          _filingRow(sw ? 'Kodi ya Kampuni' : 'Corporate Tax',
              sw ? 'Miezi 6 baada ya mwaka wa fedha' : '6 months after financial year'),
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
