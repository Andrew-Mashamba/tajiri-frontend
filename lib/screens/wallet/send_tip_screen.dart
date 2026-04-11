/// Story 66: Send Tip
/// As a user, I want to tip a creator.
/// Navigation: Live stream / Creator profile → Tip button.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/wallet_models.dart';
import '../../services/biometric_service.dart';
import '../../services/subscription_service.dart';
import '../../services/wallet_service.dart';
import '../../widgets/budget_context_banner.dart';

class SendTipScreen extends StatefulWidget {
  final int creatorId;
  final int currentUserId;
  final String? creatorDisplayName;

  const SendTipScreen({
    super.key,
    required this.creatorId,
    required this.currentUserId,
    this.creatorDisplayName,
  });

  @override
  State<SendTipScreen> createState() => _SendTipScreenState();
}

class _SendTipScreenState extends State<SendTipScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final WalletService _walletService = WalletService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  Wallet? _wallet;
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;
  double? _selectedAmount;

  static const List<double> _presetAmounts = [500, 1000, 2000, 5000, 10000];
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const double _minTouchTarget = 48.0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _customAmountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _walletService.getWallet(widget.currentUserId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _wallet = result.wallet;
      } else {
        _error = result.message ?? 'Imeshindwa kupakia pochi';
      }
    });
  }

  double? get _effectiveAmount {
    if (_selectedAmount != null) return _selectedAmount;
    final custom = double.tryParse(_customAmountController.text.trim());
    if (custom != null && custom > 0) return custom;
    return null;
  }

  Future<void> _sendTip() async {
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kutuma zawadi',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }

    final amount = _effectiveAmount;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chagua kiasi au ingiza kiasi halali')),
      );
      return;
    }

    final balance = _wallet?.balance ?? 0;
    if (balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salio la pochi halitoshi. Ingiza pesa kwanza.'),
        ),
      );
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza PIN ya pochi (tarakimu 4)')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    final result = await _subscriptionService.sendTip(
      userId: widget.currentUserId,
      creatorId: widget.creatorId,
      amount: amount,
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
      paymentMethod: 'wallet',
      pin: pin,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Tuzo imetumwa!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kutuma tuzo')),
        );
      }
    }
  }

  void _showPinDialog() {
    final amount = _effectiveAmount;
    if (amount == null || amount <= 0) return;

    _pinController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Thibitisha tuzo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TZS ${amount.toStringAsFixed(0)} kutoka pochi yako.',
                style: const TextStyle(fontSize: 14, color: _secondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN (tarakimu 4)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              BudgetContextBanner(
                category: 'burudani',
                paymentAmount: amount,
                isSwahili: false,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: Material(
                  color: _primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _sendTip();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Tuma Tuzo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.creatorDisplayName?.isNotEmpty == true
        ? widget.creatorDisplayName!
        : 'Mwandishi';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Tuma Tuzo'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primary),
              )
            : _error != null
                ? _buildErrorState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chagua kiasi na uandike ujumbe (si lazima). Tuzo linatoka kwenye pochi yako.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _secondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_wallet != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Salio: ${_wallet!.balanceFormatted}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'Kiasi (TZS)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _presetAmounts.map((a) {
                            final selected = _selectedAmount == a;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAmount = a;
                                  _customAmountController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: _minTouchTarget,
                                  minWidth: _minTouchTarget,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? _primary : _accent,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${a.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : _primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            setState(() => _selectedAmount = null);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Kiasi maalum (TZS)',
                            hintText: 'Ingiza kiasi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Ujumbe (si lazima)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            hintText: 'Andika ujumbe kwa mwandishi...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 72,
                            maxHeight: 80,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: InkWell(
                              onTap: _effectiveAmount != null &&
                                      (_wallet?.balance ?? 0) >=
                                          (_effectiveAmount ?? 0)
                                  ? _showPinDialog
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primary,
                                        ),
                                      )
                                    : const Text(
                                        'Tuma Tuzo kwa Pochi',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _accent),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Imeshindwa kupakia',
              style: const TextStyle(color: _primary, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: _minTouchTarget,
              child: TextButton(
                onPressed: _loadWallet,
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
