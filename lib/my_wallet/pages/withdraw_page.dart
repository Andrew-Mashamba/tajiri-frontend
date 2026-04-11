// lib/my_wallet/pages/withdraw_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class WithdrawPage extends StatefulWidget {
  final int userId;
  final Wallet wallet;
  const WithdrawPage({super.key, required this.userId, required this.wallet});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final WalletService _walletService = WalletService();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  String _selectedProvider = 'mpesa';
  bool _isLoading = false;

  static const _providers = [
    ('mpesa', 'M-Pesa'),
    ('tigopesa', 'Tigo Pesa'),
    ('airtelmoney', 'Airtel Money'),
    ('halopesa', 'Halo Pesa'),
  ];

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (amount == null || amount <= 0) {
      _showError(_isSwahili ? 'Ingiza kiasi sahihi' : 'Enter a valid amount');
      return;
    }
    if (amount > widget.wallet.balance) {
      _showError(_isSwahili
          ? 'Salio haitoshi. Salio lako: TZS ${_formatAmount(widget.wallet.balance)}'
          : 'Insufficient balance. Your balance: TZS ${_formatAmount(widget.wallet.balance)}');
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      _showError(_isSwahili ? 'Ingiza nambari ya simu sahihi' : 'Enter a valid phone number');
      return;
    }
    if (pin.isEmpty || pin.length < 4) {
      _showError(_isSwahili ? 'Ingiza PIN yako' : 'Enter your PIN');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _walletService.withdraw(
        userId: widget.userId,
        amount: amount,
        provider: _selectedProvider,
        phoneNumber: phone,
        pin: pin,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSwahili
              ? 'Pesa zinatumwa kwenye simu yako.'
              : 'Money is being sent to your phone.')),
        );
        Navigator.pop(context);
      } else {
        _showError(result.message ?? (_isSwahili ? 'Imeshindwa kutoa pesa' : 'Failed to withdraw'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_isSwahili ? 'Hitilafu imetokea' : 'An error occurred');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSwahili ? 'Toa Pesa' : 'Withdraw Money',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: _kPrimary, size: 22),
                const SizedBox(width: 10),
                Text(isSwahili ? 'Salio:' : 'Balance:', style: const TextStyle(color: _kSecondary, fontSize: 14)),
                const Spacer(),
                Text(
                  'TZS ${_formatAmount(widget.wallet.balance)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Provider
          Text(
            isSwahili ? 'Tuma Kwenye' : 'Send To',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _providers.map((p) {
              final isSelected = _selectedProvider == p.$1;
              return ChoiceChip(
                label: Text(p.$2),
                selected: isSelected,
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                onSelected: (_) => setState(() => _selectedProvider = p.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Amount
          Text(
            isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 24),
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Phone
          Text(
            isSwahili ? 'Nambari ya Simu' : 'Phone Number',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '0712 345 678',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: _kCardBg,
              prefixIcon: const Icon(Icons.phone_rounded, color: _kSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // PIN
          Text(
            isSwahili ? 'PIN ya Pochi' : 'Wallet PIN',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '****',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: _kCardBg,
              prefixIcon: const Icon(Icons.lock_rounded, color: _kSecondary),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Submit
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isSwahili ? 'Toa Pesa' : 'Withdraw',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
