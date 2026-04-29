import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/wallet_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/wallet_service.dart';
import '../../services/tajiri_pay_qr_service.dart';
import '../../models/tajiri_pay_qr_models.dart';
import '../../my_wallet/pages/tanqr_poster_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BusinessQrCardsPage extends StatefulWidget {
  final int userId;
  const BusinessQrCardsPage({super.key, required this.userId});

  @override
  State<BusinessQrCardsPage> createState() => _BusinessQrCardsPageState();
}

class _BusinessQrCardsPageState extends State<BusinessQrCardsPage> {
  final WalletService _walletService = WalletService();
  final TajiriPayQrService _tanqrService = TajiriPayQrService();

  bool _loading = true;
  List<TajiriPayQrCode> _codes = const [];

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final user = storage.getUser();
    if (token == null || user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _codes = _tanqrService.getCachedBusinessQrs(widget.userId);
        });
      }
      return;
    }

    final walletResult = await _walletService.getWallet(widget.userId);
    final wallet = walletResult.wallet ?? Wallet(balance: 0);
    final ownerName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final codes = await _tanqrService.getQrCardsForBusinessModule(
      token: token,
      userId: widget.userId,
      walletCurrency: wallet.currency,
      ownerDisplayName: ownerName.isEmpty ? 'TAJIRI' : ownerName,
      ownerPhone: user.phoneNumber,
      ownerAddress: user.location?.displayAddress,
    );

    if (!mounted) return;
    setState(() {
      _codes = codes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    if (_codes.isEmpty) {
      return const Center(
        child: Text('No TANQR codes available', style: TextStyle(color: _kSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCodes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _codes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final code = _codes[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TanQrPosterPage(code: code)),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    QrImageView(
                      data: code.tanqrPayload,
                      size: 82,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code.displayName,
                            style: const TextStyle(
                              color: _kPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cardSubtitle(code),
                            style: const TextStyle(color: _kSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            code.aliasMerchantId,
                            style: const TextStyle(
                              color: _kSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _kSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _cardSubtitle(TajiriPayQrCode code) {
    switch (code.sourceType) {
      case 'shop':
        return 'Shop TANQR';
      case 'business':
        return 'Business TANQR';
      case 'shop_info':
        return 'Shop information QR';
      case 'business_info':
        return 'Business information QR';
      case 'user_contact':
        return 'User contact QR';
      default:
        return 'QR card';
    }
  }
}
