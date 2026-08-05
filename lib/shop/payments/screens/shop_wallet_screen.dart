import 'package:flutter/material.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/wallet_service.dart';
import '../../../my_wallet/pages/wallet_home_page.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);

/// Opens the main app wallet with live balance (`IMPLEMENTATION_PLAN` Phase 5).
class ShopWalletScreen extends StatefulWidget {
  const ShopWalletScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ShopWalletScreen> createState() => _ShopWalletScreenState();
}

class _ShopWalletScreenState extends State<ShopWalletScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openWallet();
  }

  Future<void> _openWallet() async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    final ws = WalletService();
    final wr = await ws.getWallet(widget.userId);
    if (!mounted) return;
    if (!wr.success || wr.wallet == null) {
      setState(() {
        _loading = false;
        _error = wr.message ?? 'Wallet unavailable';
      });
      return;
    }
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WalletHomePage(
          userId: widget.userId,
          wallet: wr.wallet!,
          authToken: token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(color: _kText)),
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kText),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Text(_error ?? 'Opening wallet…'),
      ),
    );
  }
}
