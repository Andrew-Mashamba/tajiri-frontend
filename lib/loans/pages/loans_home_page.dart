// lib/loans/pages/loans_home_page.dart
import 'package:flutter/material.dart';
import '../../business/business_notifier.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../services/local_storage_service.dart';
import '../models/loan_models.dart';
import '../services/loan_service.dart';
import '../widgets/credit_score_card.dart';
import '../widgets/loan_tier_card.dart';
import '../widgets/active_loan_card.dart';
import 'apply_loan_page.dart';
import 'loan_detail_page.dart';
import 'score_breakdown_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class LoansHomePage extends StatefulWidget {
  final int userId;
  final CreatorCreditScore creditScore;
  final List<BoostLoan> loans;

  const LoansHomePage({
    super.key,
    required this.userId,
    required this.creditScore,
    required this.loans,
  });

  @override
  State<LoansHomePage> createState() => _LoansHomePageState();
}

class _LoansHomePageState extends State<LoansHomePage> {
  final BoostLoanService _service = BoostLoanService();
  late CreatorCreditScore _creditScore;
  late List<BoostLoan> _loans;
  CreditScore? _businessCreditScore;

  @override
  void initState() {
    super.initState();
    _creditScore = widget.creditScore;
    _loans = widget.loans;
    _loadBusinessCreditScore();
  }

  Future<void> _loadBusinessCreditScore() async {
    final businesses = BusinessNotifier.instance.businesses;
    if (businesses.isEmpty) return;

    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return;

    final res = await BusinessService.getCreditScore(token, businesses.first.id!);
    if (mounted && res.success && res.data != null) {
      setState(() => _businessCreditScore = res.data);
    }
  }

  Future<void> _refresh() async {
    final results = await Future.wait([
      _service.getCreditScore(widget.userId),
      _service.getMyLoans(widget.userId),
    ]);

    final scoreResult = results[0] as LoanResult<CreatorCreditScore>;
    final loansResult = results[1] as LoanListResult<BoostLoan>;

    if (mounted) {
      setState(() {
        if (scoreResult.success && scoreResult.data != null) _creditScore = scoreResult.data!;
        if (loansResult.success) _loans = loansResult.items;
      });
    }
  }

  List<BoostLoan> get _activeLoans => _loans.where((l) => l.isActive).toList();
  List<BoostLoan> get _pastLoans => _loans.where((l) => !l.isActive).toList();

  bool _hasActiveLoanForTier(LoanTier tier) {
    return _activeLoans.any((l) => l.tier == tier);
  }

  double _maxAmountForTier(LoanTier tier) {
    final earningsBased = _creditScore.monthlyEarningsAvg * tier.earningsMultiple;
    return earningsBased.clamp(tier.minAmount, tier.maxAmount);
  }

  bool _isTierEligible(LoanTier tier) {
    final maxTier = _creditScore.maxEligibleTier;
    if (maxTier == null) return false;
    return tier.index <= maxTier.index;
  }

  void _openApply(LoanTier tier) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ApplyLoanPage(
          userId: widget.userId,
          tier: tier,
          creditScore: _creditScore,
          maxAmount: _maxAmountForTier(tier),
        ),
      ),
    );
    if (result == true && mounted) _refresh();
  }

  void _openLoanDetail(BoostLoan loan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanDetailPage(userId: widget.userId, loan: loan),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Credit score card
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScoreBreakdownPage(creditScore: _creditScore),
              ),
            ),
            child: CreditScoreCard(creditScore: _creditScore),
          ),

          // Business CRB Credit Score
          if (_businessCreditScore != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.assessment_rounded,
                          size: 24, color: _kPrimary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('CRB Credit Score: ',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary)),
                            Text('${_businessCreditScore!.score}/999',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _kPrimary)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Grade: ${_businessCreditScore!.grade} — Affects your loan eligibility',
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Active loans
          if (_activeLoans.isNotEmpty) ...[
            const Text(
              'Active Loans',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            ..._activeLoans.map((loan) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ActiveLoanCard(
                    loan: loan,
                    onTap: () => _openLoanDetail(loan),
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // Loan tiers
          const Text(
            'TAJIRI Boost',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Creator loan — repay from your earnings',
            style: TextStyle(fontSize: 13, color: _kSecondary),
          ),
          const SizedBox(height: 12),

          ...LoanTier.values.map((tier) {
            final eligible = _isTierEligible(tier);
            final hasActive = _hasActiveLoanForTier(tier);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LoanTierCard(
                tier: tier,
                isEligible: eligible,
                maxEligibleAmount: eligible ? _maxAmountForTier(tier) : null,
                onApply: (eligible && !hasActive) ? () => _openApply(tier) : null,
              ),
            );
          }),

          // Past loans
          if (_pastLoans.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Loan History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            ..._pastLoans.map((loan) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ActiveLoanCard(
                    loan: loan,
                    onTap: () => _openLoanDetail(loan),
                  ),
                )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
