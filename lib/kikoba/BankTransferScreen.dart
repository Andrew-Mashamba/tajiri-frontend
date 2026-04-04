import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'DataStore.dart';
import 'HttpService.dart';

// Design Guidelines Colors
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);
const _successColor = Color(0xFF4CAF50);
const _errorColor = Color(0xFFF44336);
const _warningColor = Color(0xFFFF9800);

/// Maps bank names to their numeric FSP codes
/// Returns the numeric FSP code if found, otherwise returns the original value
String _getBankFspCode(String bankNameOrCode) {
  // If it's already a numeric code, return it
  if (RegExp(r'^\d+$').hasMatch(bankNameOrCode.trim())) {
    return bankNameOrCode.trim();
  }

  // Bank and Mobile Money Provider FSP Code Mapping
  final Map<String, String> bankFspCodes = {
    // Banks (complete list for Tanzania)
    'BANK OF TANZANIA': '001',
    'BOT': '001',

    'GEPG': '002',

    'CRDB': '003',
    'CRDB LIMITED': '003',
    'CRDB BANK': '003',

    'PEOPLES\' BANK OF ZANZIBAR': '004',
    'PEOPLES BANK OF ZANZIBAR': '004',
    'PBZ': '004',

    'STANDARD CHARTERED BANK': '005',
    'STANDARD CHARTERED': '005',
    'STANCHART': '005',

    'STANBIC BANK TANZANIA': '006',
    'STANBIC': '006',

    'CITIBANK TANZANIA LIMITED': '008',
    'CITIBANK': '008',
    'CITI': '008',

    'BANK OF AFRICA (TANZANIA) LTD': '009',
    'BANK OF AFRICA': '009',
    'BOA': '009',

    'DIAMOND TRUST BANK': '011',
    'DTB': '011',

    'AKIBA COMMERCIAL BANK': '012',
    'AKIBA': '012',

    'EXIM BANK': '013',
    'EXIM': '013',

    'KILIMANJARO CO-OPERATIVE BANK': '014',
    'KILIMANJARO COOP BANK': '014',
    'KCB COOP': '014',

    'NBC LIMITED': '015',
    'NBC': '015',

    'NATIONAL MICROFINANCE BANK': '016',
    'NMB': '016',
    'NMB BANK': '016',

    'KCB BANK TANZANIA LIMITED': '017',
    'KCB': '017',

    'HABIB AFRICAN BANK': '018',
    'HABIB': '018',

    'INTERNATIONAL COMMERCIAL BANK (T)': '019',
    'ICB': '019',

    'ABSA BANK': '020',
    'ABSA': '020',

    'I AND M BANK (T) LTD': '021',
    'I&M BANK': '021',
    'I AND M': '021',

    'NCBA BANK TANZANIA LTD': '023',
    'NCBA': '023',

    'DCB COMMERCIAL BANK': '024',
    'DCB': '024',

    'BANK OF BARODA (T) LTD': '029',
    'BANK OF BARODA': '029',
    'BARODA': '029',

    'AZANIA BANK': '031',
    'AZANIA': '031',

    'UCHUMI COMMERCIAL BANK': '032',
    'UCHUMI BANK': '032',
    'UCHUMI': '032',

    'BANC ABC': '034',
    'ABC BANK': '034',

    'ACCESS BANK (T) LTD': '035',
    'ACCESS BANK': '035',
    'ACCESS': '035',

    'BANK OF INDIA (T) LTD': '036',
    'BANK OF INDIA': '036',
    'BOI': '036',

    'UNITED BANK FOR AFRICA': '038',
    'UBA': '038',

    'MKOMBOZI COMMERCIAL BANK PUBLIC LTD': '039',
    'MKOMBOZI BANK': '039',
    'MKOMBOZI': '039',

    'ECOBANK TANZANIA LTD': '040',
    'ECOBANK': '040',

    'MWANGA HAKIKA MICROFINANCE BANK': '042',
    'MWANGA HAKIKA': '042',

    'LETSHEGO FAIDIKA BANK': '044',
    'LETSHEGO': '044',
    'LETSHEGO BANK': '044',

    'FIRST NATIONAL BANK (T) LTD': '045',
    'FNB': '045',
    'FIRST NATIONAL BANK': '045',

    'AMANA BANK': '046',
    'AMANA': '046',

    'EQUITY BANK (T) LTD': '047',
    'EQUITY BANK': '047',
    'EQUITY': '047',

    'TANZANIA COMMERCIAL BANK PLC': '048',
    'TCB': '048',

    'MAENDELEO BANK': '051',
    'MAENDELEO': '051',

    'TANZANIA AGRICULTURAL DEVELOPMENT': '052',
    'TADB': '052',

    'FINCA MICROFINANCE BANK': '056',
    'FINCA': '056',

    'MWALIMU COMMERCIAL BANK OF TANZANIA': '059',
    'MWALIMU BANK': '059',
    'MWALIMU': '059',

    'GUARANTY TRUST BANK TANZANIA LTD': '061',
    'GTB': '061',
    'GT BANK': '061',

    'YETU MICROFINANCE BANK PLC': '063',
    'YETU': '063',

    'MUCOBA BANK PLC': '064',
    'MUCOBA': '064',

    'CHINA DASHENG BANK LTD': '065',
    'CHINA DASHENG': '065',

    // Mobile Money Providers
    'TIGOPESA': '501',
    'TIGO PESA': '501',
    'TIGO': '501',

    'EASY PESA': '502',
    'EASYPESA': '502',

    'M-PESA': '503',
    'MPESA': '503',

    'AIRTEL MONEY': '504',
    'AIRTEL': '504',

    'T-PESA': '505',
    'TPESA': '505',

    'HALOPESA': '506',
    'HALO PESA': '506',

    'AZAMPESA': '511',
    'AZAM PESA': '511',
  };

  // Try exact match first (case insensitive)
  final upperBankName = bankNameOrCode.trim().toUpperCase();
  if (bankFspCodes.containsKey(upperBankName)) {
    return bankFspCodes[upperBankName]!;
  }

  // Try partial match
  for (var entry in bankFspCodes.entries) {
    if (upperBankName.contains(entry.key) || entry.key.contains(upperBankName)) {
      return entry.value;
    }
  }

  // If no mapping found, return original value
  return bankNameOrCode.trim();
}

class BankTransferScreen extends StatefulWidget {
  final double amount;
  final String recipientBankName;
  final String recipientAccountNumber;
  final String recipientBankCode;
  final String narration;
  final String? controlNumber;

  const BankTransferScreen({
    Key? key,
    required this.amount,
    required this.recipientBankName,
    required this.recipientAccountNumber,
    required this.recipientBankCode,
    required this.narration,
    this.controlNumber,
  }) : super(key: key);

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankCodeController = TextEditingController();

  // State variables
  int _currentStep = 0; // 0: Input, 1: Calculate Fees, 2: Confirm, 3: Processing, 4: Status
  bool _isLoading = false;
  Map<String, dynamic>? _feeCalculation;
  Map<String, dynamic>? _transferResult;
  String? _errorMessage;
  String? _payerRef;

  @override
  void initState() {
    super.initState();
    _logger.i('🏦 [BANK TRANSFER] Screen initialized');
    _logger.d('Payment amount: TZS ${widget.amount}');
    _logger.d('Recipient bank: ${widget.recipientBankName}');
    _logger.d('Recipient account: ${widget.recipientAccountNumber}');
    _logger.d('Recipient bank code: ${widget.recipientBankCode}');
    if (widget.controlNumber != null) {
      _logger.d('Control number: ${widget.controlNumber}');
    }
    _loadCurrentMemberBankDetails();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _bankCodeController.dispose();
    super.dispose();
  }

  /// Load and pre-fill the current user's bank account details from members data
  void _loadCurrentMemberBankDetails() {
    _logger.i('👤 [MEMBER DATA] Loading current member bank details...');
    _logger.d('Current user ID: ${DataStore.currentUserId}');

    try {
      final membersList = DataStore.membersList;
      if (membersList == null || membersList.isEmpty) {
        _logger.w('⚠️ [MEMBER DATA] Members list is null or empty');
        return;
      }

      _logger.d('Members list count: ${membersList.length}');

      // Find the current user's member data
      final currentMember = membersList.firstWhere(
        (member) => member['userId']?.toString() == DataStore.currentUserId,
        orElse: () => null,
      );

      if (currentMember != null) {
        _logger.i('✅ [MEMBER DATA] Found current member data');

        // Pre-fill form fields with member's bank account details
        _logger.i('📥 [DATA LOAD] Pre-populating "Taarifa za Akaunti Yako":');

        if (currentMember['bank_account'] != null && currentMember['bank_account'].toString().isNotEmpty) {
          _accountNumberController.text = currentMember['bank_account'].toString();
          _logger.i('  ✓ Account Number: ${currentMember['bank_account']}');
        } else {
          _logger.w('  ⚠️ Account Number: EMPTY/NULL');
        }

        if (currentMember['bank_name'] != null && currentMember['bank_name'].toString().isNotEmpty) {
          _bankNameController.text = currentMember['bank_name'].toString();
          _logger.i('  ✓ Bank Name: ${currentMember['bank_name']}');
        } else {
          _logger.w('  ⚠️ Bank Name: EMPTY/NULL');
        }

        if (currentMember['bank_code'] != null && currentMember['bank_code'].toString().isNotEmpty) {
          _bankCodeController.text = currentMember['bank_code'].toString();
          _logger.i('  ✓ Bank Code: ${currentMember['bank_code']}');
        } else {
          _logger.w('  ⚠️ Bank Code: EMPTY/NULL');
        }

        _logger.i('📥 [DATA LOAD] Complete - Form fields populated');
        _logger.i('═══════════════════════════════════════════════════════');

        // CRITICAL VALIDATION: Check if member's account is same as kikoba account
        final memberAccount = _accountNumberController.text.trim();
        final kikobaAccount = widget.recipientAccountNumber.trim();

        if (memberAccount.isNotEmpty && memberAccount == kikobaAccount) {
          _logger.e('🚨 [CRITICAL ERROR] Member account is SAME as Kikoba account!');
          _logger.e('  Member Account: $memberAccount');
          _logger.e('  Kikoba Account: $kikobaAccount');
          _logger.e('  This will cause a transfer FROM kikoba TO same kikoba account!');
          _logger.e('  Member needs to update their personal bank account in their profile.');
        } else if (memberAccount.isNotEmpty) {
          _logger.i('✅ [VALIDATION] Accounts are different (correct):');
          _logger.i('  Member Account: $memberAccount (source)');
          _logger.i('  Kikoba Account: $kikobaAccount (destination)');
        }
      } else {
        _logger.w('⚠️ [MEMBER DATA] Current member not found in members list');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ [MEMBER DATA] Error loading member bank details', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _iconBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lipa kwa Benki',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildInputStep();
      case 1:
        return _buildFeeCalculationStep();
      case 2:
        return _buildConfirmationStep();
      case 3:
        return _buildProcessingStep();
      case 4:
        return _buildStatusStep();
      default:
        return _buildInputStep();
    }
  }

  // Step 0: User input for bank details
  Widget _buildInputStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          const Text(
            'Taarifa za Akaunti Yako',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _accountNumberController,
            label: 'Namba ya Akaunti',
            hint: 'Ingiza namba ya akaunti yako',
            icon: Icons.account_balance_wallet,
            keyboardType: TextInputType.number,
            enabled: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bankNameController,
            label: 'Jina la Benki',
            hint: 'Mfano: CRDB, NMB, NBC',
            icon: Icons.account_balance,
            enabled: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bankCodeController,
            label: 'Bank Code (Optional)',
            hint: 'Ingiza bank code',
            icon: Icons.numbers,
            required: false,
            enabled: false,
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            label: 'Endelea',
            icon: Icons.arrow_forward_rounded,
            onPressed: _handleCalculateFees,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  // Step 1: Fee calculation
  Widget _buildFeeCalculationStep() {
    if (_feeCalculation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final fee = _feeCalculation!['fee'] ?? 0.0;
    final totalAmount = _feeCalculation!['total'] ?? widget.amount;
    final routing = _feeCalculation!['routing_system'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Muhtasari wa Malipo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          children: [
            _buildSummaryRow('Kiasi', formatCurrency.format(widget.amount)),
            _buildSummaryRow('Ada ya benki', formatCurrency.format(fee)),
            const Divider(height: 24),
            _buildSummaryRow(
              'Jumla',
              formatCurrency.format(totalAmount),
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('Njia', routing, isSmall: true),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoBox(
          'Pesa itahamishwa kutoka akaunti yako kwenda akaunti ya kikundi.',
          Icons.info_outline,
          _warningColor,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Rudi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'Thibitisha',
                icon: Icons.check_circle_outline,
                onPressed: _handleConfirmTransfer,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 2: Confirmation
  Widget _buildConfirmationStep() {
    return Column(
      children: [
        const Icon(Icons.security_rounded, size: 64, color: _warningColor),
        const SizedBox(height: 16),
        const Text(
          'Thibitisha Malipo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _primaryText),
        ),
        const SizedBox(height: 8),
        Text(
          'Je, una uhakika unataka kuhamisha ${formatCurrency.format(_feeCalculation?['total'] ?? widget.amount)}?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: _secondaryText),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sitisha'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'Lipa Sasa',
                icon: Icons.send_rounded,
                onPressed: _handleInitiateTransfer,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Processing
  Widget _buildProcessingStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        const Text(
          'Inahamisha Pesa...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _primaryText),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tafadhali subiri, hii inaweza kuchukua sekunde chache',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: _secondaryText),
        ),
      ],
    );
  }

  // Step 4: Status (Success/Error)
  Widget _buildStatusStep() {
    final isSuccess = _transferResult?['success'] == true;
    final message = _transferResult?['message'] ?? _errorMessage ?? 'Taarifa hazipatikani';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
          size: 80,
          color: isSuccess ? _successColor : _errorColor,
        ),
        const SizedBox(height: 24),
        Text(
          isSuccess ? 'Malipo Yamefanikiwa!' : 'Malipo Yameshindwa',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isSuccess ? _successColor : _errorColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: _secondaryText),
        ),
        if (isSuccess && _payerRef != null) ...[
          const SizedBox(height: 24),
          _buildInfoBox(
            'Marejeleo: $_payerRef',
            Icons.receipt_long,
            _accentColor,
          ),
        ],
        const SizedBox(height: 32),
        if (isSuccess)
          _buildActionButton(
            label: 'Rudiruk Mwanzo',
            icon: Icons.home_rounded,
            onPressed: () => Navigator.pop(context),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Jaribu Tena'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Funga',
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // UI Components
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maelezo ya Malipo',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Kiasi', formatCurrency.format(widget.amount)),
          _buildInfoRow('Benki ya Pokea', widget.recipientBankName),
          _buildInfoRow('Akaunti ya Pokea', widget.recipientAccountNumber),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = true,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: enabled ? _iconBg : _accentColor),
        filled: !enabled,
        fillColor: !enabled ? _primaryBg : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.3)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _iconBg, width: 2),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali jaza sehemu hii';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildSummaryCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              color: _secondaryText,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 12 : (isBold ? 18 : 14),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _secondaryText)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText)),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _iconBg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  // Actions
  Future<void> _handleCalculateFees() async {
    _logger.i('💰 [STEP 1] Calculate Transfer Fees - Starting...');

    if (!_formKey.currentState!.validate()) {
      _logger.w('⚠️ [STEP 1] Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Convert bank name to FSP code if needed
    final String destinationFspCode = _getBankFspCode(widget.recipientBankCode);

    _logger.d('Request parameters:');
    _logger.d('  Amount: TZS ${widget.amount}');
    _logger.d('  Destination FSP ID (original): ${widget.recipientBankCode}');
    if (destinationFspCode != widget.recipientBankCode) {
      _logger.d('  Destination FSP ID (converted): $destinationFspCode');
    }

    try {
      final result = await HttpService.calculateTransferFees(
        amount: widget.amount,
        destinationFspId: destinationFspCode,
      );

      _logger.d('API Response received:');
      _logger.d('  Success: ${result['success']}');

      if (result['success']) {
        _logger.i('✅ [STEP 1] Fee calculation successful');
        _logger.d('  Amount: TZS ${result['amount']}');
        _logger.d('  Fee: TZS ${result['fee']}');
        _logger.d('  Total: TZS ${result['total']}');
        _logger.d('  Currency: ${result['currency']}');
        _logger.d('  Routing System: ${result['routing_system']}');
        _logger.d('  Is Mobile Money: ${result['is_mobile_money']}');

        setState(() {
          _feeCalculation = result;
          _currentStep = 1;
        });
      } else {
        _logger.e('❌ [STEP 1] Fee calculation failed: ${result['error']}');
        _showError(result['error'] ?? 'Imeshindwa kukokotoa ada');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ [STEP 1] Exception during fee calculation', error: e, stackTrace: stackTrace);
      _showError('Kosa: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleConfirmTransfer() {
    _logger.i('✔️ [STEP 2] User confirmed transfer - Moving to step 3');
    setState(() => _currentStep = 2);
  }

  Future<void> _handleInitiateTransfer() async {
    _logger.i('📤 [STEP 3] Initiate Bank Transfer - Starting...');

    setState(() {
      _isLoading = true;
      _currentStep = 3;
    });

    // Convert bank names to FSP codes if needed
    final String destinationFspCode = _getBankFspCode(widget.recipientBankCode);
    final String sourceFspCode = _getBankFspCode(_bankCodeController.text.trim());
    final String sourceAccount = _accountNumberController.text.trim();
    final String destinationAccount = widget.recipientAccountNumber.trim();

    // Validation checks
    if (sourceAccount.isEmpty) {
      _logger.e('❌ [STEP 3] Validation failed: Source account is empty');
      _showError('Tafadhali ingiza namba ya akaunti yako');
      setState(() {
        _isLoading = false;
        _currentStep = 0;
      });
      return;
    }

    if (sourceAccount == destinationAccount) {
      _logger.e('❌ [STEP 3] Validation failed: Source and destination accounts are the same');
      _logger.e('  Source Account: $sourceAccount');
      _logger.e('  Destination Account: $destinationAccount');
      _showError('Akaunti ya kutuma na kupokea ni sawa. Tafadhali hakikisha unatumia akaunti yako binafsi, si akaunti ya kikoba.');
      setState(() {
        _isLoading = false;
        _currentStep = 0;
      });
      return;
    }

    _logger.i('💸 Payment Flow:');
    _logger.i('  FROM: Member\'s Account ($sourceAccount) - ${_bankNameController.text}');
    _logger.i('  TO: Kikoba Account ($destinationAccount) - ${widget.recipientBankName}');
    _logger.i('  Amount: TZS ${_feeCalculation?['total'] ?? widget.amount}');

    _logger.d('Transfer parameters:');
    _logger.d('  Kikoba ID: ${DataStore.currentKikobaId}');
    _logger.d('  User ID: ${DataStore.currentUserId}');
    _logger.d('  Source Account: ${_accountNumberController.text}');
    _logger.d('  Source Bank Name: ${_bankNameController.text}');
    _logger.d('  Source FSP ID (original): ${_bankCodeController.text}');
    if (sourceFspCode != _bankCodeController.text.trim()) {
      _logger.d('  Source FSP ID (converted): $sourceFspCode');
    }
    _logger.d('  Destination Account: ${widget.recipientAccountNumber}');
    _logger.d('  Destination FSP ID (original): ${widget.recipientBankCode}');
    if (destinationFspCode != widget.recipientBankCode) {
      _logger.d('  Destination FSP ID (converted): $destinationFspCode');
    }
    _logger.d('  Destination Name: ${DataStore.currentKikobaName}');
    _logger.d('  Amount: TZS ${_feeCalculation?['total'] ?? widget.amount}');
    _logger.d('  Description: ${widget.narration}');

    try {
      // Convert amount to double to avoid type mismatch
      final double transferAmount = (_feeCalculation?['total'] ?? widget.amount).toDouble();

      // Log exact data being sent to backend for comparison
      _logger.i('═══════════════════════════════════════════════════════');
      _logger.i('📤 [DATA SEND] Sending to Backend API:');
      _logger.i('');
      _logger.i('  SOURCE (Member\'s Account):');
      _logger.i('    Account Number: $sourceAccount');
      _logger.i('    Bank Name: ${_bankNameController.text.trim()}');
      _logger.i('    Bank Code: ${_bankCodeController.text.trim()} → FSP: $sourceFspCode');
      _logger.i('');
      _logger.i('  DESTINATION (Kikoba Account):');
      _logger.i('    Account Number: $destinationAccount');
      _logger.i('    Bank Name: ${widget.recipientBankName}');
      _logger.i('    Bank Code: ${widget.recipientBankCode} → FSP: $destinationFspCode');
      _logger.i('');
      _logger.i('  TRANSFER DETAILS:');
      _logger.i('    Amount: TZS $transferAmount');
      _logger.i('    Description: ${widget.narration}');
      _logger.i('');
      _logger.d('📤 Full API Request Body:');
      _logger.d('{');
      _logger.d('  "kikoba_id": "${DataStore.currentKikobaId}",');
      _logger.d('  "user_id": "${DataStore.currentUserId}",');
      _logger.d('  "direction": "DEPOSIT",');
      _logger.d('  "source_account": "$sourceAccount",');
      _logger.d('  "source_bank_name": "${_bankNameController.text.trim()}",');
      _logger.d('  "source_fsp_id": "$sourceFspCode",');
      _logger.d('  "destination_account": "$destinationAccount",');
      _logger.d('  "destination_fsp_id": "$destinationFspCode",');
      _logger.d('  "destination_name": "${DataStore.currentKikobaName ?? 'Kikoba'}",');
      _logger.d('  "amount": $transferAmount,');
      _logger.d('  "description": "${widget.narration}"');
      if (widget.controlNumber != null) {
        _logger.d('  "control_number": "${widget.controlNumber}"');
      }
      _logger.d('}');
      _logger.i('═══════════════════════════════════════════════════════');

      final result = await HttpService.initiateTransfer(
        kikobaId: DataStore.currentKikobaId,
        userId: DataStore.currentUserId,
        destinationAccount: destinationAccount,
        destinationFspId: destinationFspCode,
        destinationName: DataStore.currentKikobaName ?? 'Kikoba',
        amount: transferAmount,
        description: widget.narration,
        // Source account details (member's personal bank account)
        sourceAccount: sourceAccount,
        sourceBankName: _bankNameController.text.trim(),
        sourceFspId: sourceFspCode,
        // Direction: DEPOSIT for Member → Kikoba transfer
        direction: 'DEPOSIT',
        // Control number for bill payment tracking
        controlNumber: widget.controlNumber,
      );

      _logger.d('API Response received:');
      _logger.d('  Success: ${result['success']}');
      _logger.d('  Status Code: ${result['statusCode']}');
      _logger.d('  Full Response: $result');

      if (result['success'] == true) {
        _logger.i('✅ [STEP 3] Transfer initiated successfully');
        _logger.d('  Payer Reference: ${result['payerRef']}');
        _logger.d('  Status: ${result['status']}');
        _logger.d('  Amount: TZS ${result['amount']}');
        _logger.d('  Routing System: ${result['routing_system']}');
        _logger.d('  Message: ${result['message']}');
      } else {
        _logger.e('❌ [STEP 3] Transfer initiation failed');
        _logger.e('  HTTP Status Code: ${result['statusCode']}');
        _logger.e('  Error Message: ${result['error'] ?? result['message']}');
        _logger.e('  Full Error Response: $result');
      }

      setState(() {
        _transferResult = result;
        _payerRef = result['payerRef'];
        _currentStep = 4;
      });
    } catch (e, stackTrace) {
      _logger.e('❌ [STEP 3] Exception during transfer initiation', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Kosa: $e';
        _currentStep = 4;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    _logger.e('🚨 [ERROR] Showing error to user: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
