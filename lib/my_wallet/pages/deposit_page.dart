// lib/my_wallet/pages/deposit_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/wallet_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class DepositPage extends StatefulWidget {
  final int userId;
  const DepositPage({super.key, required this.userId});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final WalletService _walletService = WalletService();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedProvider = 'mpesa';
  bool _isLoading = false;

  static const _providers = [
    ('mpesa', 'M-Pesa', Icons.phone_android_rounded),
    ('tigopesa', 'Tigo Pesa', Icons.phone_android_rounded),
    ('airtelmoney', 'Airtel Money', Icons.phone_android_rounded),
    ('halopesa', 'Halo Pesa', Icons.phone_android_rounded),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    final phone = _phoneController.text.trim();

    if (amount == null || amount <= 0) {
      _showError(_isSwahili ? 'Ingiza kiasi sahihi' : 'Enter a valid amount');
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      _showError(_isSwahili ? 'Ingiza nambari ya simu sahihi' : 'Enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _walletService.deposit(
        userId: widget.userId,
        amount: amount,
        provider: _selectedProvider,
        phoneNumber: phone,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSwahili
              ? 'Ombi la kuingiza pesa limetumwa. Thibitisha kwenye simu yako.'
              : 'Deposit request sent. Confirm on your phone.')),
        );
        Navigator.pop(context);
      } else {
        _showError(result.message ?? (_isSwahili ? 'Imeshindwa kuingiza pesa' : 'Failed to deposit'));
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
          isSwahili ? 'Ingiza Pesa' : 'Deposit Money',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider selection
          Text(
            isSwahili ? 'Chagua Mtoa Huduma' : 'Select Provider',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _providers.map((p) {
              final isSelected = _selectedProvider == p.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedProvider = p.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary : _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _kPrimary : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.$3,
                        size: 18,
                        color: isSelected ? Colors.white : _kSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
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

          // Phone number
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
                      isSwahili ? 'Ingiza Pesa' : 'Deposit',
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
