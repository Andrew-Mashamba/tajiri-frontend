// lib/loans/loans_module.dart
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import 'services/loan_service.dart';
import 'models/loan_models.dart';
import 'pages/loans_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);

class LoansModule extends StatefulWidget {
  final int userId;
  const LoansModule({super.key, required this.userId});
  @override
  State<LoansModule> createState() => _LoansModuleState();
}

class _LoansModuleState extends State<LoansModule> {
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';

  CreatorCreditScore? _creditScore;
  List<BoostLoan> _loans = [];

  @override
  void initState() {
    super.initState();
    _initializeModule();
  }

  Future<void> _initializeModule() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });

      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Tafadhali ingia tena kwenye TAJIRI.');
      }

      final service = BoostLoanService();

      // Load credit score and loans in parallel
      final results = await Future.wait([
        service.getCreditScore(widget.userId),
        service.getMyLoans(widget.userId),
      ]);

      final scoreResult = results[0] as LoanResult<CreatorCreditScore>;
      final loansResult = results[1] as LoanListResult<BoostLoan>;

      _creditScore = scoreResult.success
          ? scoreResult.data
          : CreatorCreditScore(
              score: 0,
              monthlyEarningsAvg: 0,
              platformTenureMonths: 0,
            );

      _loans = loansResult.success ? loansResult.items : [];

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              SizedBox(height: 16),
              Text(
                'Inapakia Mikopo...',
                style: TextStyle(color: _kTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: _kTertiary),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.replaceAll('Exception: ', ''),
                  style: const TextStyle(color: _kTertiary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _initializeModule,
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                  child: const Text('Jaribu Tena'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LoansHomePage(
      userId: widget.userId,
      creditScore: _creditScore!,
      loans: _loans,
    );
  }
}
