// lib/my_wallet/pages/transfer_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class TransferPage extends StatefulWidget {
  final int userId;
  final Wallet wallet;
  const TransferPage({super.key, required this.userId, required this.wallet});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final WalletService _walletService = WalletService();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _pinController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _usePhone = true; // true = phone, false = user ID

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
    _recipientController.dispose();
    _pinController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    final recipient = _recipientController.text.trim();
    final pin = _pinController.text.trim();

    if (amount == null || amount <= 0) {
      _showError(_isSwahili ? 'Ingiza kiasi sahihi' : 'Enter a valid amount');
      return;
    }
    if (amount > widget.wallet.balance) {
      _showError(_isSwahili ? 'Salio haitoshi' : 'Insufficient balance');
      return;
    }
    if (recipient.isEmpty) {
      _showError(_usePhone
          ? (_isSwahili ? 'Ingiza nambari ya simu' : 'Enter phone number')
          : (_isSwahili ? 'Ingiza ID ya mtumiaji' : 'Enter user ID'));
      return;
    }
    if (pin.isEmpty || pin.length < 4) {
      _showError(_isSwahili ? 'Ingiza PIN yako' : 'Enter your PIN');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _walletService.transfer(
        userId: widget.userId,
        recipientPhone: _usePhone ? recipient : null,
        recipientId: !_usePhone ? int.tryParse(recipient) : null,
        amount: amount,
        pin: pin,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSwahili ? 'Pesa zimetumwa!' : 'Money sent!')),
        );
        Navigator.pop(context);
      } else {
        _showError(result.message ?? (_isSwahili ? 'Imeshindwa kutuma pesa' : 'Failed to transfer'));
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
          isSwahili ? 'Tuma Pesa' : 'Transfer Money',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recipient toggle
          Row(
            children: [
              Text(
                isSwahili ? 'Mpokeaji' : 'Recipient',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              const Spacer(),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(isSwahili ? 'Simu' : 'Phone', style: const TextStyle(fontSize: 12))),
                  ButtonSegment(value: false, label: Text('ID', style: const TextStyle(fontSize: 12))),
                ],
                selected: {_usePhone},
                onSelectionChanged: (v) => setState(() {
                  _usePhone = v.first;
                  _recipientController.clear();
                }),
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _recipientController,
            keyboardType: _usePhone ? TextInputType.phone : TextInputType.number,
            decoration: InputDecoration(
              hintText: _usePhone ? '0712 345 678' : 'User ID',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: _kCardBg,
              prefixIcon: Icon(
                _usePhone ? Icons.phone_rounded : Icons.person_rounded,
                color: _kSecondary,
              ),
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

          // Description (optional)
          Text(
            isSwahili ? 'Maelezo (Hiari)' : 'Description (Optional)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: isSwahili ? 'Mfano: Malipo ya chakula' : 'E.g.: Payment for food',
              hintStyle: TextStyle(color: Colors.grey.shade400),
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
                      isSwahili ? 'Tuma Pesa' : 'Send Money',
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
