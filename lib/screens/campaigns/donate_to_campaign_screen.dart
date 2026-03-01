/// Story 82: Donate to Campaign
/// As a user, I want to donate to a campaign.
/// Navigation: Campaign detail → Donate button.
/// Payment: Wallet or mobile money. POST /api/campaigns/{id}/donate

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/contribution_models.dart';
import '../../models/wallet_models.dart';
import '../../services/contribution_service.dart';
import '../../services/wallet_service.dart';

class DonateToCampaignScreen extends StatefulWidget {
  final Campaign campaign;
  final int currentUserId;

  const DonateToCampaignScreen({
    super.key,
    required this.campaign,
    required this.currentUserId,
  });

  @override
  State<DonateToCampaignScreen> createState() => _DonateToCampaignScreenState();
}

class _DonateToCampaignScreenState extends State<DonateToCampaignScreen> {
  final ContributionService _contributionService = ContributionService();
  final WalletService _walletService = WalletService();
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  Wallet? _wallet;
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;
  double? _selectedAmount;
  String _paymentMethod = 'wallet'; // 'wallet' | 'mobile_money'
  bool _isAnonymous = false;

  static const List<double> _presetAmounts = [1000, 5000, 10000, 25000, 50000];
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
    _customAmountController.dispose();
    _messageController.dispose();
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

  double get _minAmount => widget.campaign.minimumDonation;

  bool get _amountValid {
    final amount = _effectiveAmount;
    if (amount == null || amount < _minAmount) return false;
    if (_paymentMethod == 'wallet') {
      return (_wallet?.balance ?? 0) >= amount;
    }
    return true;
  }

  void _submitDonate() {
    final amount = _effectiveAmount;
    if (amount == null || amount < _minAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kiasi kiwe angalau TSh ${_minAmount.toStringAsFixed(0)}'),
        ),
      );
      return;
    }

    if (_paymentMethod == 'wallet') {
      final balance = _wallet?.balance ?? 0;
      if (balance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salio la pochi halitoshi. Ingiza pesa kwanza.'),
          ),
        );
        return;
      }
      _showPinDialog();
    } else {
      _performDonate(pin: null);
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
                'Thibitisha mchango',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TSh ${amount.toStringAsFixed(0)} kutoka pochi yako.',
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
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: Material(
                  color: _primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      final pin = _pinController.text.trim();
                      if (pin.length != 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingiza PIN ya pochi (tarakimu 4)'),
                          ),
                        );
                        return;
                      }
                      _performDonate(pin: pin);
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
                              'Changia',
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

  Future<void> _performDonate({String? pin}) async {
    final amount = _effectiveAmount!;
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    final result = await _contributionService.donateToCampaign(
      widget.campaign.id,
      amount: amount,
      paymentMethod: _paymentMethod,
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
      isAnonymous: _isAnonymous,
      pin: pin,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Asante! Mchango wako umepokelewa.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kuchangia')),
        );
      }
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: _accent),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Hitilafu',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _secondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Changia Mchango'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primary),
              )
            : _error != null && _wallet == null
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
                          widget.campaign.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chagua kiasi na njia ya malipo. Kiwango cha chini: TSh ${_minAmount.toStringAsFixed(0)}.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _secondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_wallet != null && _paymentMethod == 'wallet') ...[
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
                            final belowMin = a < _minAmount;
                            return GestureDetector(
                              onTap: belowMin
                                  ? null
                                  : () {
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
                                    color: selected
                                        ? _primary
                                        : (belowMin ? _accent.withValues(alpha: 0.5) : _accent),
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
                                    color: selected
                                        ? Colors.white
                                        : (belowMin ? _accent : _primary),
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
                          decoration: InputDecoration(
                            labelText: 'Kiasi maalum (TZS, angalau ${_minAmount.toStringAsFixed(0)})',
                            hintText: 'Ingiza kiasi',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Njia ya malipo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPaymentOption(
                                label: 'Pochi',
                                icon: Icons.account_balance_wallet,
                                value: 'wallet',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPaymentOption(
                                label: 'Pesa za simu',
                                icon: Icons.phone_android,
                                value: 'mobile_money',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ujumbe (si lazima)',
                          style: const TextStyle(
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
                          maxLines: 2,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            hintText: 'Andika ujumbe kwa kampeni...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (widget.campaign.allowAnonymousDonations) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: _minTouchTarget,
                            child: CheckboxListTile(
                              value: _isAnonymous,
                              onChanged: (v) {
                                setState(() => _isAnonymous = v ?? false);
                              },
                              title: const Text(
                                'Changia kwa siri (asiyejulikana)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                        ],
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
                              onTap: _amountValid && !_isSubmitting
                                  ? _submitDonate
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
                                    : Text(
                                        'Changia',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _amountValid
                                              ? _primary
                                              : _accent,
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

  Widget _buildPaymentOption({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final selected = _paymentMethod == value;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          setState(() => _paymentMethod = value);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          constraints: const BoxConstraints(minHeight: _minTouchTarget * 1.2),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? _primary : _accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? _primary : _secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: _primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
