// lib/business/pages/credit_report_page.dart
// CRB Credit Report & Score (Credit Report) — CreditInfo Tanzania.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class CreditReportPage extends StatefulWidget {
  final int businessId;
  const CreditReportPage({super.key, required this.businessId});

  @override
  State<CreditReportPage> createState() => _CreditReportPageState();
}

class _CreditReportPageState extends State<CreditReportPage> {
  String? _token;
  bool _loading = true;
  bool _requesting = false;
  String? _error;
  CreditReport? _report;
  CreditScore? _score;

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
      final futures = await Future.wait([
        BusinessService.getCreditReport(_token!, widget.businessId),
        BusinessService.getCreditScore(_token!, widget.businessId),
      ]);

      final reportRes = futures[0] as BusinessResult<CreditReport>;
      final scoreRes = futures[1] as BusinessResult<CreditScore>;

      if (mounted) {
        setState(() {
          _loading = false;
          if (reportRes.success && reportRes.data != null) {
            _report = reportRes.data;
          }
          if (scoreRes.success && scoreRes.data != null) {
            _score = scoreRes.data;
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

  Future<void> _requestFreshReport() async {
    if (_token == null) return;
    final sw = _isSwahili;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Omba Ripoti Mpya?' : 'Request New Report?'),
        content: Text(sw
            ? 'Ripoti mpya itaombwa kutoka CreditInfo Tanzania Limited. '
                'Gharama ya huduma inaweza kutumika.'
            : 'A new report will be requested from CreditInfo Tanzania Limited. '
                'Service charges may apply.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Hapana' : 'Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(sw ? 'Ndio, Omba' : 'Yes, Request')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _requesting = true);
    try {
      final res =
          await BusinessService.requestCreditReport(_token!, widget.businessId);
      if (mounted) {
        setState(() => _requesting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.message ??
                (sw ? 'Imeombwa' : 'Requested'))));
        if (res.success) _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _requesting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(sw ? 'Imeshindikana' : 'Request failed')));
      }
    }
  }

  Future<void> _openPdf() async {
    if (_report?.reportPdfUrl == null || _report!.reportPdfUrl!.isEmpty) return;
    final uri = Uri.parse(_report!.reportPdfUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindikana kufungua ripoti'
              : 'Could not open report')));
    }
  }

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return const Color(0xFF4CAF50);
      case 'B':
        return const Color(0xFF8BC34A);
      case 'C':
        return const Color(0xFFFFC107);
      case 'D':
        return const Color(0xFFFF9800);
      case 'E':
        return const Color(0xFFF44336);
      default:
        return _kSecondary;
    }
  }

  String _gradeDescription(String grade) {
    final sw = _isSwahili;
    switch (grade.toUpperCase()) {
      case 'A':
        return sw ? 'Bora Sana' : 'Excellent';
      case 'B':
        return sw ? 'Nzuri' : 'Good';
      case 'C':
        return sw ? 'Wastani' : 'Fair';
      case 'D':
        return sw ? 'Hatarishi' : 'Poor';
      case 'E':
        return sw ? 'Mbaya' : 'Very Poor';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final sw = _isSwahili;

    return Container(
      color: _kBackground,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: _kPrimary, strokeWidth: 2))
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
                            fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(sw ? 'Jaribu Tena' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Credit score ring
                      _buildScoreCard(sw),
                      const SizedBox(height: 16),

                      // Score factors
                      if (_score != null && _score!.factors.isNotEmpty)
                        _buildFactors(sw),

                      // Report summary
                      if (_report != null) ...[
                        const SizedBox(height: 16),
                        _buildReportSummary(nf, sw),
                      ],

                      // Payment history
                      if (_report != null &&
                          _report!.paymentHistory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildPaymentHistory(nf, df, sw),
                      ],

                      const SizedBox(height: 16),

                      // Request fresh report
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _requesting ? null : _requestFreshReport,
                          icon: _requesting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _kPrimary))
                              : const Icon(Icons.refresh_rounded),
                          label: Text(
                              sw ? 'Omba Ripoti Mpya' : 'Request New Report'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: _kPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      // Download PDF
                      if (_report?.reportPdfUrl != null &&
                          _report!.reportPdfUrl!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _openPdf,
                            icon: const Icon(Icons.download_rounded),
                            label: Text(sw
                                ? 'Pakua Ripoti (PDF)'
                                : 'Download Report (PDF)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // CreditInfo notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sw
                                    ? 'Taarifa hii inatolewa na CreditInfo Tanzania Limited, '
                                        'taasisi ya CRB iliyosajiliwa na Benki Kuu ya Tanzania.'
                                    : 'This information is provided by CreditInfo Tanzania Limited, '
                                        'a CRB registered with the Bank of Tanzania.',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // What affects score
                      _buildScoreExplanation(sw),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreCard(bool sw) {
    final score = _score?.score ?? _report?.creditScore ?? 0;
    final grade = _score?.grade ?? _report?.riskGrade ?? 'E';
    final trend = _score?.trend ?? 'stable';
    final color = _gradeColor(grade);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(sw ? 'Alama ya Mkopo' : 'Credit Score',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 16),
          // Score ring
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                score: score,
                maxScore: 999,
                color: color,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      sw ? 'ya 999' : 'of 999',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Grade badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${sw ? "Daraja" : "Grade"} $grade',
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text(
                  '- ${_gradeDescription(grade)}',
                  style: TextStyle(color: color, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Trend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                trend == 'up'
                    ? Icons.trending_up_rounded
                    : trend == 'down'
                        ? Icons.trending_down_rounded
                        : Icons.trending_flat_rounded,
                color: trend == 'up'
                    ? Colors.green.shade300
                    : trend == 'down'
                        ? Colors.red.shade300
                        : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                trend == 'up'
                    ? (sw ? 'Inapanda' : 'Improving')
                    : trend == 'down'
                        ? (sw ? 'Inashuka' : 'Declining')
                        : (sw ? 'Imara' : 'Stable'),
                style: TextStyle(
                  color: trend == 'up'
                      ? Colors.green.shade300
                      : trend == 'down'
                          ? Colors.red.shade300
                          : Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (_score?.lastUpdated != null) ...[
            const SizedBox(height: 6),
            Text(
              '${sw ? "Ilisasishwa" : "Updated"}: ${DateFormat('dd/MM/yyyy').format(_score!.lastUpdated!)}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFactors(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sw ? 'Mambo Yanayoathiri Alama' : 'Score Factors',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
        const SizedBox(height: 10),
        ..._score!.factors.map((f) {
          final isPositive = f.impact == 'positive';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.add_circle_rounded
                      : Icons.remove_circle_rounded,
                  size: 18,
                  color: isPositive
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.factor ?? '',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isPositive
                                  ? Colors.green.shade800
                                  : Colors.red.shade800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (f.description != null && f.description!.isNotEmpty)
                        Text(f.description!,
                            style: TextStyle(
                                fontSize: 11,
                                color: isPositive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReportSummary(NumberFormat nf, bool sw) {
    final r = _report!;
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
          Text(sw ? 'Muhtasari wa Mikopo' : 'Loan Summary',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
          const SizedBox(height: 12),
          _summaryRow(
              sw ? 'Akaunti za Mikopo Hai' : 'Active Loan Accounts',
              '${r.totalActiveLoanAccounts}'),
          _summaryRow(
              sw ? 'Akaunti Zilizofungwa' : 'Closed Accounts',
              '${r.totalClosedAccounts}'),
          _summaryRow(
              sw ? 'Jumla ya Deni' : 'Total Outstanding',
              'TZS ${nf.format(r.totalOutstandingBalance)}'),
          _summaryRow(
              sw ? 'Kiasi Kilichochelewa' : 'Overdue Amount',
              'TZS ${nf.format(r.totalOverdueAmount)}',
              valueColor: r.totalOverdueAmount > 0 ? Colors.red : null),
          if (r.worstArrearStatus != null)
            _summaryRow(
                sw ? 'Hali Mbaya Zaidi ya Ucheleweshaji' : 'Worst Arrear Status',
                r.worstArrearStatus!),
          _summaryRow(
              sw ? 'Uchunguzi (Siku 90)' : 'Inquiries (Last 90 Days)',
              '${r.inquiriesLast90Days}'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? _kPrimary)),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(NumberFormat nf, DateFormat df, bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sw ? 'Historia ya Malipo' : 'Payment History',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
        const SizedBox(height: 10),
        ..._report!.paymentHistory.map((p) {
          final isOverdue = p.arrearsDays > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.lender ?? (sw ? 'Mkopeshaji' : 'Lender'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${p.accountType ?? (sw ? "Mkopo" : "Loan")} ${p.openDate != null ? "- ${df.format(p.openDate!)}" : ""}',
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isOverdue)
                        Text(
                            sw
                                ? 'Siku za ucheleweshaji: ${p.arrearsDays}'
                                : 'Days overdue: ${p.arrearsDays}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.red.shade700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TZS ${nf.format(p.balance)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                            fontSize: 13)),
                    Text(p.status ?? '',
                        style: TextStyle(
                            fontSize: 10,
                            color: isOverdue
                                ? Colors.red.shade700
                                : Colors.green.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScoreExplanation(bool sw) {
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
          Text(sw ? 'Nini Kinaathiri Alama Yako?' : 'What Affects Your Score?',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary)),
          const SizedBox(height: 10),
          _explainRow(
              Icons.schedule_rounded,
              sw ? 'Historia ya Malipo' : 'Payment History',
              sw
                  ? 'Kulipa kwa wakati kunaboresha alama yako.'
                  : 'Paying on time improves your score.'),
          _explainRow(
              Icons.account_balance_wallet_rounded,
              sw ? 'Kiwango cha Deni' : 'Debt Level',
              sw
                  ? 'Deni kubwa kulinganisha na mapato hupunguza alama.'
                  : 'High debt relative to income lowers your score.'),
          _explainRow(
              Icons.timeline_rounded,
              sw ? 'Umri wa Mikopo' : 'Credit Age',
              sw
                  ? 'Mikopo ya muda mrefu yenye historia nzuri inasaidia.'
                  : 'Long-standing accounts with good history help.'),
          _explainRow(
              Icons.search_rounded,
              sw ? 'Uchunguzi' : 'Inquiries',
              sw
                  ? 'Maombi mengi ya mkopo kwa muda mfupi hupunguza alama.'
                  : 'Many loan applications in a short time lower your score.'),
          _explainRow(
              Icons.diversity_3_rounded,
              sw ? 'Aina za Mikopo' : 'Credit Mix',
              sw
                  ? 'Kuwa na aina tofauti za mikopo kunasaidia.'
                  : 'Having different types of credit helps.'),
        ],
      ),
    );
  }

  Widget _explainRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _kPrimary)),
                Text(desc,
                    style:
                        const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the credit score ring
class _ScoreRingPainter extends CustomPainter {
  final int score;
  final int maxScore;
  final Color color;

  _ScoreRingPainter({
    required this.score,
    required this.maxScore,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75, // Start from bottom-left
      math.pi * 1.5, // 270 degrees
      false,
      bgPaint,
    );

    // Score ring
    final progress = score / maxScore;
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      scorePaint,
    );

    // Score markers
    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 4; i++) {
      final angle = -math.pi * 0.75 + (math.pi * 1.5 * i / 4);
      final markerCenter = Offset(
        center.dx + (radius + 16) * math.cos(angle),
        center.dy + (radius + 16) * math.sin(angle),
      );
      canvas.drawCircle(markerCenter, 2, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.score != score || old.color != color;
}
