import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/biometric_service.dart';
import '../../services/subscription_service.dart';

/// Screen for requesting payouts to mobile money
class PayoutRequestScreen extends StatefulWidget {
  final int currentUserId;
  final double availableBalance;

  const PayoutRequestScreen({
    super.key,
    required this.currentUserId,
    required this.availableBalance,
  });

  @override
  State<PayoutRequestScreen> createState() => _PayoutRequestScreenState();
}

class _PayoutRequestScreenState extends State<PayoutRequestScreen> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF22C55E);
  static const Color _kDanger = Color(0xFFEF4444);

  final SubscriptionService _subscriptionService = SubscriptionService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  String? _selectedProvider;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _providers = [
    {'id': 'mpesa', 'name': 'M-Pesa', 'icon': Icons.phone_android},
    {'id': 'tigopesa', 'name': 'Tigo Pesa', 'icon': Icons.phone_android},
    {'id': 'airtel', 'name': 'Airtel Money', 'icon': Icons.phone_android},
    {'id': 'halopesa', 'name': 'Halo Pesa', 'icon': Icons.phone_android},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kuomba malipo',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }

    final s = AppStringsScope.of(context);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.selectPaymentProvider ?? 'Select a payment provider'),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.enterValidAmount ?? 'Enter a valid amount'),
        ),
      );
      return;
    }

    if (amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.amountExceedsBalance ?? 'Amount exceeds available balance'),
          backgroundColor: _kDanger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _subscriptionService.requestPayout(
      userId: widget.currentUserId,
      amount: amount,
      paymentMethod: 'mobile_money',
      accountNumber: _phoneController.text.trim(),
      accountName: _nameController.text.trim(),
      provider: _selectedProvider,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.payoutRequestSubmitted ?? 'Payout request submitted successfully'),
          backgroundColor: _kSuccess,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? s?.payoutRequestFailed ?? 'Failed to submit request'),
          backgroundColor: _kDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(s?.requestPayout ?? 'Request Payout'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Available balance card
                _buildBalanceCard(s),
                const SizedBox(height: 24),

                // Amount input
                _buildSectionLabel(s?.amount ?? 'Amount'),
                const SizedBox(height: 8),
                _buildAmountInput(s),
                const SizedBox(height: 20),

                // Provider selection
                _buildSectionLabel(s?.paymentProvider ?? 'Payment Provider'),
                const SizedBox(height: 12),
                _buildProviderGrid(),
                const SizedBox(height: 20),

                // Phone number
                _buildSectionLabel(s?.phoneNumber ?? 'Phone Number'),
                const SizedBox(height: 8),
                _buildPhoneInput(s),
                const SizedBox(height: 20),

                // Account name
                _buildSectionLabel(s?.accountName ?? 'Account Name'),
                const SizedBox(height: 8),
                _buildNameInput(s),
                const SizedBox(height: 32),

                // Submit button
                _buildSubmitButton(s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AppStrings? s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.availableBalance ?? 'Available Balance',
            style: const TextStyle(
              color: _kSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TZS ${widget.availableBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _kPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAmountInput(AppStrings? s) {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        hintText: s?.enterAmount ?? 'Enter amount',
        prefixText: 'TZS ',
        prefixStyle: const TextStyle(
          color: _kPrimary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kSecondary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kSecondary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return s?.enterAmount ?? 'Enter amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return s?.enterValidAmount ?? 'Enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildProviderGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _providers.map((provider) {
        final isSelected = _selectedProvider == provider['id'];
        return _buildProviderChip(
          id: provider['id'] as String,
          name: provider['name'] as String,
          icon: provider['icon'] as IconData,
          isSelected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildProviderChip({
    required String id,
    required String name,
    required IconData icon,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected ? _kPrimary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selectedProvider = id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _kPrimary : _kSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : _kPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : _kPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput(AppStrings? s) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        hintText: '0712345678',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.phone_outlined, color: _kSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kSecondary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kSecondary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return s?.enterPhoneNumber ?? 'Enter phone number';
        }
        if (value.length < 10) {
          return s?.invalidPhoneNumber ?? 'Invalid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildNameInput(AppStrings? s) {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: s?.enterAccountName ?? 'Enter account holder name',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.person_outline, color: _kSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kSecondary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kSecondary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return s?.enterAccountName ?? 'Enter account name';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton(AppStrings? s) {
    return SizedBox(
      height: 56,
      child: Material(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isSubmitting ? null : _submitRequest,
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
                : Text(
                    s?.submitRequest ?? 'Submit Request',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
