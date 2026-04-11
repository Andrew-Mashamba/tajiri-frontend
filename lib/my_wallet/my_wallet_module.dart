// lib/my_wallet/my_wallet_module.dart
import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';
import '../services/local_storage_service.dart';
import '../services/wallet_service.dart';
import '../models/wallet_models.dart';
import 'pages/wallet_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);

class MyWalletModule extends StatefulWidget {
  final int userId;
  const MyWalletModule({super.key, required this.userId});
  @override
  State<MyWalletModule> createState() => _MyWalletModuleState();
}

class _MyWalletModuleState extends State<MyWalletModule> {
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';

  Wallet? _wallet;
  String _authToken = '';

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
        throw Exception('auth_required');
      }

      _authToken = token;

      // Load wallet data
      final walletService = WalletService();
      final result = await walletService.getWallet(widget.userId);

      if (!result.success) {
        throw Exception(result.message ?? 'wallet_load_failed');
      }

      _wallet = result.wallet;

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
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: _kBackground,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                const SizedBox(height: 16),
                Text(
                  isSwahili ? 'Inapakia Pochi...' : 'Loading Wallet...',
                  style: const TextStyle(color: _kTertiary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      final displayError = _errorMessage.replaceAll('Exception: ', '');
      final errorText = displayError == 'auth_required'
          ? (isSwahili ? 'Tafadhali ingia tena kwenye TAJIRI.' : 'Please log in to TAJIRI again.')
          : displayError == 'wallet_load_failed'
              ? (isSwahili ? 'Imeshindwa kupakia pochi' : 'Failed to load wallet')
              : displayError;
      return Scaffold(
        backgroundColor: _kBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: _kTertiary),
                  const SizedBox(height: 16),
                  Text(
                    errorText,
                    style: const TextStyle(color: _kTertiary, fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _initializeModule,
                    style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                    child: Text(isSwahili ? 'Jaribu Tena' : 'Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return WalletHomePage(
      userId: widget.userId,
      wallet: _wallet!,
      authToken: _authToken,
    );
  }
}
