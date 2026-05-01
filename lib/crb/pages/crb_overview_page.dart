// lib/crb/pages/crb_overview_page.dart
// CRB overview — personal score hero card + per-business score cards.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../business/models/business_models.dart' hide CreditReport, CreditScore;
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/crb_models.dart';
import '../services/crb_service.dart';
import 'credit_report_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class CrbOverviewPage extends StatefulWidget {
  final int userId;
  final List<Business> businesses;

  const CrbOverviewPage({
    super.key,
    required this.userId,
    required this.businesses,
  });

  @override
  State<CrbOverviewPage> createState() => _CrbOverviewPageState();
}

class _CrbOverviewPageState extends State<CrbOverviewPage> {
  String? _token;
  bool _loading = true;
  String? _error;

  // Personal score (fetched via first business's NIN lookup on backend)
  CreditScore? _personalScore;
  CreditReport? _personalReport;

  // Per-business scores — keyed by businessId
  final Map<int, CreditScore?> _bizScores = {};

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

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
    if (_token == null || widget.businesses.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bizIds =
          widget.businesses.map((b) => b.id).whereType<int>().toList();

      // Fetch personal score + report from first business, all biz scores in parallel
      final futures = await Future.wait([
        CrbService.getCreditReport(_token!, bizIds.first),
        CrbService.getCreditScore(_token!, bizIds.first),
        ...bizIds.skip(1).map((id) => CrbService.getCreditScore(_token!, id)),
      ]);

      if (!mounted) return;

      final reportRes = futures[0] as CrbResult<CreditReport>;
      final scoreRes = futures[1] as CrbResult<CreditScore>;

      setState(() {
        _loading = false;
        if (reportRes.success) _personalReport = reportRes.data;
        if (scoreRes.success) _personalScore = scoreRes.data;
        if (!reportRes.success && !scoreRes.success) {
          _error = reportRes.message ?? scoreRes.message;
        }

        // First biz same score as personal
        _bizScores[bizIds.first] = scoreRes.data;

        // Remaining businesses
        final remainingIds = bizIds.skip(1).toList();
        for (var i = 0; i < remainingIds.length; i++) {
          final res = futures[2 + i] as CrbResult<CreditScore>;
          _bizScores[remainingIds[i]] = res.success ? res.data : null;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
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

  String _gradeLabel(String grade, bool sw) {
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
        return sw ? 'Mbaya Sana' : 'Very Poor';
      default:
        return sw ? 'Hakuna Historia' : 'No History';
    }
  }

  void _openDetail(int businessId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditReportPage(businessId: businessId, standalone: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;
    if (widget.businesses.isEmpty) return _buildNoBusiness(sw);

    return Container(
      color: _kBackground,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null && _personalScore == null && _personalReport == null
              ? _buildError(sw)
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      _buildPersonalHero(sw),
                      const SizedBox(height: 24),
                      if (widget.businesses.length > 1) ...[
                        Text(
                          sw ? 'Biashara Zangu' : 'My Businesses',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                        const SizedBox(height: 10),
                        ...widget.businesses
                            .where((b) => b.id != null)
                            .map((biz) => _buildBizCard(biz, sw)),
                      ],
                      const SizedBox(height: 16),
                      _buildCreditInfoNotice(sw),
                      const SizedBox(height: 16),
                      _buildScoreExplanation(sw),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoBusiness(bool sw) {
    return Container(
      color: _kBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business_center_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                sw ? 'Hakuna Biashara Iliyosajiliwa' : 'No Business Registered',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                sw
                    ? 'Sajili biashara yako kwenye kichupo cha Biashara ili uone alama yako ya CRB.'
                    : 'Register your business in the Business tab to view your CRB credit score.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(bool sw) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            sw ? 'Imeshindikana kupakia' : 'Failed to load',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(sw ? 'Jaribu Tena' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalHero(bool sw) {
    final score = _personalScore?.score ?? _personalReport?.creditScore ?? 0;
    final grade = _personalScore?.grade ?? _personalReport?.riskGrade ?? 'XX';
    final trend = _personalScore?.trend ?? 'stable';
    final color = _gradeColor(grade);
    final nf = NumberFormat('#,###', 'en');
    final firstBizId = widget.businesses.isNotEmpty ? widget.businesses.first.id : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            sw ? 'Alama Yangu ya Mkopo' : 'My CRB Score',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _ScoreRingPainter(score: score, maxScore: 999, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      sw ? 'ya 999' : 'of 999',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${sw ? "Daraja" : "Grade"} $grade',
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text(
                  '– ${_gradeLabel(grade, sw)}',
                  style: TextStyle(color: color, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
          if (_personalReport != null) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(
                    sw ? 'Mikopo Hai' : 'Active Loans',
                    '${_personalReport!.totalActiveLoanAccounts}'),
                _statChip(
                    sw ? 'Deni Lote' : 'Total Debt',
                    'TZS ${nf.format(_personalReport!.totalOutstandingBalance.toInt())}'),
                _statChip(
                    sw ? 'Malimbikizo' : 'Overdue',
                    'TZS ${nf.format(_personalReport!.totalOverdueAmount.toInt())}'),
              ],
            ),
          ],
          if (firstBizId != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => _openDetail(firstBizId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  sw ? 'Tazama Ripoti Kamili' : 'View Full Report',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildBizCard(Business biz, bool sw) {
    final score = _bizScores[biz.id];
    final s = score?.score ?? 0;
    final grade = score?.grade ?? 'XX';
    final color = _gradeColor(grade);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _openDetail(biz.id!),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    grade,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biz.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      score == null
                          ? (sw ? 'Hakuna data' : 'No data')
                          : '${sw ? "Alama" : "Score"}: $s/999 · ${_gradeLabel(grade, sw)}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditInfoNotice(bool sw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sw
                  ? 'Taarifa hii inatolewa na CreditInfo Tanzania Limited, '
                      'taasisi ya CRB iliyosajiliwa na Benki Kuu ya Tanzania.'
                  : 'This information is provided by CreditInfo Tanzania Limited, '
                      'a CRB registered with the Bank of Tanzania.',
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
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
          Text(
            sw ? 'Nini Kinaathiri Alama Yako?' : 'What Affects Your Score?',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          _explainRow(Icons.schedule_rounded,
              sw ? 'Historia ya Malipo' : 'Payment History',
              sw
                  ? 'Kulipa kwa wakati kunaboresha alama yako.'
                  : 'Paying on time improves your score.'),
          _explainRow(Icons.account_balance_wallet_rounded,
              sw ? 'Kiwango cha Deni' : 'Debt Level',
              sw
                  ? 'Deni kubwa kulinganisha na mapato hupunguza alama.'
                  : 'High debt relative to income lowers your score.'),
          _explainRow(Icons.timeline_rounded,
              sw ? 'Umri wa Mikopo' : 'Credit Age',
              sw
                  ? 'Mikopo ya muda mrefu yenye historia nzuri inasaidia.'
                  : 'Long-standing accounts with good history help.'),
          _explainRow(Icons.search_rounded,
              sw ? 'Uchunguzi' : 'Inquiries',
              sw
                  ? 'Maombi mengi ya mkopo kwa muda mfupi hupunguza alama.'
                  : 'Many loan applications in a short time lower your score.'),
          _explainRow(Icons.diversity_3_rounded,
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
                        fontWeight: FontWeight.w600, fontSize: 13, color: _kPrimary)),
                Text(desc,
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

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
