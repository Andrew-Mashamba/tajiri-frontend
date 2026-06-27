import '../../loans/models/loan_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL creator boost loans (Phase 60).
class GraphqlLoansService {
  static const _creditScoreFields = r'''
    score
    monthlyEarningsAvg
    platformTenureMonths
    streakDays
    earningsGrowthPercent
    revenueSources
    repaymentRate
    breakdown
  ''';

  static const _loanFields = r'''
    id
    userId
    loanId
    tier
    principalAmount
    feeAmount
    totalRepayable
    amountRepaid
    repaymentPercent
    status
    applicationDate
    disbursementDate
    dueDate
    completedDate
    graceDaysRemaining
    canRequestPause
    rejectionReason
  ''';

  static const _repaymentFields = r'''
    id
    loanId
    amount
    earningType
    date
  ''';

  static Map<String, dynamic> _creditScoreToLegacy(Map<String, dynamic> row) {
    final breakdown = row['breakdown'];
    return {
      'score': row['score'],
      'monthly_earnings_avg': row['monthlyEarningsAvg'],
      'platform_tenure_months': row['platformTenureMonths'],
      'streak_days': row['streakDays'],
      'earnings_growth_percent': row['earningsGrowthPercent'],
      'revenue_sources': row['revenueSources'],
      'repayment_rate': row['repaymentRate'],
      'breakdown': breakdown is List ? breakdown : [],
    };
  }

  static Map<String, dynamic> _loanToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'loan_id': row['loanId'],
      'tier': row['tier'],
      'principal_amount': row['principalAmount'],
      'fee_amount': row['feeAmount'],
      'total_repayable': row['totalRepayable'],
      'amount_repaid': row['amountRepaid'],
      'repayment_percent': row['repaymentPercent'],
      'status': row['status'],
      'application_date': row['applicationDate'],
      'disbursement_date': row['disbursementDate'],
      'due_date': row['dueDate'],
      'completed_date': row['completedDate'],
      'grace_days_remaining': row['graceDaysRemaining'],
      'can_request_pause': row['canRequestPause'] == true,
      'rejection_reason': row['rejectionReason'],
    };
  }

  static Map<String, dynamic> _repaymentToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'loan_id': int.parse(row['loanId'].toString()),
      'amount': row['amount'],
      'earning_type': row['earningType'],
      'date': row['date'],
    };
  }

  static Future<LoanResult<CreatorCreditScore>> getCreditScore() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorCreditScore {
          creatorCreditScore {
            $_creditScoreFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['creatorCreditScore'] as Map<String, dynamic>;
      return LoanResult(
        success: true,
        data: CreatorCreditScore.fromJson(_creditScoreToLegacy(row)),
      );
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<LoanResult<BoostLoan>> applyForLoan({
    required LoanTier tier,
    required double amount,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ApplyBoostLoan(\$input: ApplyBoostLoanInput!) {
          applyBoostLoan(input: \$input) {
            $_loanFields
          }
        }
        ''',
        variables: {
          'input': {
            'tier': tier.name,
            'amount': amount,
          },
        },
        auth: true,
      );
      final row = data['applyBoostLoan'] as Map<String, dynamic>;
      return LoanResult(
        success: true,
        data: BoostLoan.fromJson(_loanToLegacy(row)),
      );
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<LoanListResult<BoostLoan>> getMyLoans() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBoostLoans {
          myBoostLoans {
            $_loanFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myBoostLoans'] as List<dynamic>? ?? [];
      return LoanListResult(
        success: true,
        items: rows
            .map((row) => BoostLoan.fromJson(
                _loanToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return LoanListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<LoanResult<BoostLoan>> getLoanDetail(int loanId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BoostLoan(\$loanId: ID!) {
          boostLoan(loanId: \$loanId) {
            $_loanFields
          }
        }
        ''',
        variables: {'loanId': loanId.toString()},
        auth: true,
      );
      final row = data['boostLoan'] as Map<String, dynamic>;
      return LoanResult(
        success: true,
        data: BoostLoan.fromJson(_loanToLegacy(row)),
      );
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<LoanListResult<LoanRepaymentEvent>> getRepaymentHistory(
      int loanId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BoostLoanRepayments(\$loanId: ID!) {
          boostLoanRepayments(loanId: \$loanId) {
            $_repaymentFields
          }
        }
        ''',
        variables: {'loanId': loanId.toString()},
        auth: true,
      );
      final rows = data['boostLoanRepayments'] as List<dynamic>? ?? [];
      return LoanListResult(
        success: true,
        items: rows
            .map((row) => LoanRepaymentEvent.fromJson(
                _repaymentToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return LoanListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<LoanResult<BoostLoan>> requestPause(int loanId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PauseBoostLoan(\$loanId: ID!) {
          pauseBoostLoan(loanId: \$loanId) {
            $_loanFields
          }
        }
        ''',
        variables: {'loanId': loanId.toString()},
        auth: true,
      );
      final row = data['pauseBoostLoan'] as Map<String, dynamic>;
      return LoanResult(
        success: true,
        data: BoostLoan.fromJson(_loanToLegacy(row)),
      );
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<LoanResult<void>> makeManualRepayment({
    required int loanId,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RepayBoostLoan(\$loanId: ID!, \$input: RepayBoostLoanInput!) {
          repayBoostLoan(loanId: \$loanId, input: \$input) {
            $_repaymentFields
          }
        }
        ''',
        variables: {
          'loanId': loanId.toString(),
          'input': {
            'amount': amount,
            'paymentMethod': paymentMethod,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
          },
        },
        auth: true,
      );
      return LoanResult(success: true);
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }
}
