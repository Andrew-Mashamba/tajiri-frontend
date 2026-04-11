// lib/investments/investments_module.dart
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import 'services/investment_service.dart';
import 'models/investment_models.dart';
import 'pages/investments_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);

class InvestmentsModule extends StatefulWidget {
  final int userId;
  const InvestmentsModule({super.key, required this.userId});
  @override
  State<InvestmentsModule> createState() => _InvestmentsModuleState();
}

class _InvestmentsModuleState extends State<InvestmentsModule> {
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';

  PortfolioSummary? _portfolio;

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

      // Load portfolio summary
      final service = InvestmentService();
      final result = await service.getPortfolio(widget.userId);

      _portfolio = result.success
          ? result.data
          : PortfolioSummary.empty();

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
                'Inapakia Uwekezaji...',
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

    return InvestmentsHomePage(
      userId: widget.userId,
      portfolio: _portfolio!,
    );
  }
}
