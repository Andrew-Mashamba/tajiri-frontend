import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../DataStore.dart';
import '../HttpService.dart';
import '../services/page_cache_service.dart';
import '../models/loan_models.dart';
import '../services/loan_service.dart';

// Monochrome Design Guidelines Colors
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);
const _borderColor = Color(0xFFE0E0E0);
const _successColor = Color(0xFF4CAF50);

class MikopoPage extends StatefulWidget {
  const MikopoPage({super.key});

  @override
  State<MikopoPage> createState() => _MikopoPageState();
}

class _MikopoPageState extends State<MikopoPage> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 2);
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ============ State for caching and real-time updates ============
  /// IMPORTANT: Firestore is used ONLY for change notifications, NOT for data.
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;
  bool _isLoadingProducts = false;

  // Current step
  int _currentStep = 0;

  // Form Controllers
  final _principalController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _gracePeriodController = TextEditingController(text: '0');
  final _existingLoanController = TextEditingController();
  final _outstandingBalanceController = TextEditingController(text: '0');
  final _guarantorSearchController = TextEditingController();

  // Form State
  Map<String, dynamic>? _selectedProduct;
  String? _selectedLoanType;
  List<dynamic> _activeLoans = [];
  Map<String, dynamic>? _selectedExistingLoan;
  bool _loadingLoans = false;
  String _repaymentFrequency = 'Monthly';
  final List<Map<String, dynamic>> _charges = [];
  final List<Map<String, dynamic>> _selectedGuarantors = [];
  List<Map<String, dynamic>> _filteredMembers = [];

  // Product-defined values
  double? _productMinAmount;
  double? _productMaxAmount;
  double? _productInterestRate;
  int? _productMinTenure;
  int? _productMaxTenure;
  String? _productRepaymentFrequency;
  bool _fixedInterestRate = false;
  bool _fixedRepaymentFrequency = false;

  // Calculated Values
  double get _principal => double.tryParse(_principalController.text) ?? 0.0;
  double get _interestRate => double.tryParse(_interestRateController.text) ?? 0.0;
  int get _tenure => int.tryParse(_tenureController.text) ?? 0;
  int get _gracePeriod => int.tryParse(_gracePeriodController.text) ?? 0;
  double get _outstandingBalance => double.tryParse(_outstandingBalanceController.text) ?? 0.0;

  double get _totalExposure => _principal + _outstandingBalance;
  double get _totalCharges => _charges.fold(0.0, (sum, charge) => sum + (double.tryParse(charge['amount'].toString()) ?? 0.0));
  double get _grossLoanAmount => _principal + _totalCharges;
  double get _netDisbursement => _grossLoanAmount - _totalCharges;

  // Calculate EMI (Monthly Installment) using reducing balance method
  // Formula: EMI = P × [r × (1 + r)^n] / [(1 + r)^n - 1]
  // Where: P = Principal, r = Monthly interest rate, n = Number of payments
  double get _installmentAmount {
    if (_principal == 0 || _interestRate == 0 || _tenure == 0) return 0.0;
    final monthlyRate = _interestRate / 100 / 12;
    final numberOfPayments = _tenure.toDouble();
    final numerator = monthlyRate * math.pow(1 + monthlyRate, numberOfPayments);
    final denominator = math.pow(1 + monthlyRate, numberOfPayments) - 1;
    return _principal * (numerator / denominator);
  }

  // Calculate total interest using reducing balance method
  // Total Interest = (EMI × Number of Payments) - Principal
  double get _totalInterest {
    if (_principal == 0 || _interestRate == 0 || _tenure == 0) return 0.0;
    return (_installmentAmount * _tenure) - _principal;
  }

  double get _totalRepayment => _principal + _totalInterest;

  DateTime get _firstPaymentDate {
    if (_gracePeriod == 0) return DateTime.now();
    return DateTime.now().add(Duration(days: _gracePeriod));
  }

  DateTime? get _maturityDate {
    if (_tenure == 0) return null;
    final start = _firstPaymentDate;
    return DateTime(start.year, start.month + _tenure, start.day);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadMembers();
    _setupFirestoreListener();
    _loadLoanProducts();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _animationController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _gracePeriodController.dispose();
    _existingLoanController.dispose();
    _outstandingBalanceController.dispose();
    _guarantorSearchController.dispose();
    super.dispose();
  }

  /// Load loan products from backend API
  Future<void> _loadLoanProducts() async {
    if (DataStore.loanProducts != null && DataStore.loanProducts!.isNotEmpty) {
      return; // Products already loaded
    }

    setState(() => _isLoadingProducts = true);

    try {
      final kikobaId = DataStore.currentKikobaId;
      if (kikobaId == null) return;

      // Try to load from cache first
      final visitorId = DataStore.currentUserId;
      final cachedData = await PageCacheService.getMikopoData(visitorId, kikobaId);
      if (cachedData != null && cachedData['loanProducts'] != null) {
        DataStore.loanProducts = List<dynamic>.from(cachedData['loanProducts']);
        _logger.d('[MikopoPage] Loaded ${DataStore.loanProducts?.length} loan products from cache');
      }

      // Fetch fresh data from backend
      final products = await HttpService.getLoanProducts(kikobaId: kikobaId);
      if (products != null && mounted) {
        DataStore.loanProducts = products;
        await PageCacheService.saveMikopoData(visitorId, kikobaId, {
          'loanProducts': products,
          'fetchedAt': DateTime.now().toIso8601String(),
        });
        _logger.d('[MikopoPage] Fetched ${products.length} loan products from backend');
      }
    } catch (e) {
      _logger.e('[MikopoPage] Error loading loan products: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  /// Set up Firestore listener for CHANGE NOTIFICATIONS ONLY
  /// IMPORTANT: Firestore is NOT used for data fetching!
  void _setupFirestoreListener() {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return;

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('FinancialUpdates')
        .doc(kikobaId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final notificationData = snapshot.data();
      if (notificationData == null) return;

      // Listen for loan products updates
      final newVersion = notificationData['loan_products_version'] as int?;
      final updatedAt = notificationData['loan_products_updated_at'];
      int? effectiveVersion = newVersion;

      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[MikopoPage] Firestore notification: loan products version changed');
        _lastKnownVersion = effectiveVersion;
        await _loadLoanProducts();
      }
    }, onError: (e) {
      _logger.e('[MikopoPage] Firestore listener error: $e');
    });
  }

  Future<void> _loadActiveLoans() async {
    setState(() => _loadingLoans = true);

    try {
      final loans = await HttpService.getUserActiveLoans();
      if (mounted) {
        setState(() {
          _activeLoans = loans ?? [];
          _loadingLoans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLoans = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading loans: $e')),
        );
      }
    }
  }

  void _loadMembers() {
    // Load members from DataStore
    final members = (DataStore.membersList ?? []).cast<Map<String, dynamic>>();
    final currentUserId = DataStore.currentUserId;

    // Filter out current user
    _filteredMembers = members
        .where((member) => member['userId'] != currentUserId)
        .toList();
  }

  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        _loadMembers();
      } else {
        final members = (DataStore.membersList ?? []).cast<Map<String, dynamic>>();
        final currentUserId = DataStore.currentUserId;
        _filteredMembers = members
            .where((member) =>
                member['userId'] != currentUserId &&
                ((member['name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (member['phone']?.toString().contains(query) ?? false)))
            .toList();
      }
    });
  }

  void _onProductSelected(Map<String, dynamic>? product) {
    if (product == null) return;

    setState(() {
      _selectedProduct = product;

      // Extract product settings
      _productMinAmount = double.tryParse(product['minAmount']?.toString() ?? '0');
      _productMaxAmount = double.tryParse(product['maxAmount']?.toString() ?? '0');
      _productInterestRate = double.tryParse(product['interestRate']?.toString() ?? '0');
      _productMinTenure = int.tryParse(product['minTenure']?.toString() ?? '0');
      _productMaxTenure = int.tryParse(product['maxTenure']?.toString() ?? '0');
      _productRepaymentFrequency = product['repaymentFrequency']?.toString();
      _fixedInterestRate = product['fixedInterestRate'] == true || product['fixedInterestRate'] == 'true';
      _fixedRepaymentFrequency = product['fixedRepaymentFrequency'] == true || product['fixedRepaymentFrequency'] == 'true';

      // Auto-fill fields
      if (_productInterestRate != null && _productInterestRate! > 0) {
        _interestRateController.text = _productInterestRate!.toString();
      }

      if (_productRepaymentFrequency != null && _productRepaymentFrequency!.isNotEmpty) {
        // Normalize to match dropdown values (capitalize first letter)
        final freq = _productRepaymentFrequency!.toLowerCase();
        if (freq == 'daily') {
          _repaymentFrequency = 'Daily';
        } else if (freq == 'weekly') {
          _repaymentFrequency = 'Weekly';
        } else if (freq == 'bi-weekly' || freq == 'biweekly') {
          _repaymentFrequency = 'Bi-Weekly';
        } else if (freq == 'monthly') {
          _repaymentFrequency = 'Monthly';
        }
      }

      // Load product charges
      _charges.clear();
      if (product['charges'] is List) {
        for (var charge in product['charges']) {
          if (charge is Map) {
            _charges.add({
              'name': charge['name']?.toString() ?? '',
              'amount': charge['amount']?.toString() ?? '0',
              'isProductCharge': true,
            });
          }
        }
      }
    });
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (_currentStep == 0 && _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a loan product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep == 1) {
      if (_selectedLoanType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select loan type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate existing loan selection for top-up
      if (_selectedLoanType == 'topup') {
        if (_selectedExistingLoan == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an existing loan'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    if (_currentStep == 2) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep == 3 && _selectedGuarantors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one guarantor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _animationController.reset();
        _animationController.forward();
      });
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
          'Omba Mkopo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentStep(),
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Row(
        children: [
          _buildStepDot(0, 'Bidhaa'),
          _buildStepLine(0),
          _buildStepDot(1, 'Aina'),
          _buildStepLine(1),
          _buildStepDot(2, 'Maelezo'),
          _buildStepLine(2),
          _buildStepDot(3, 'Wadhamini'),
          _buildStepLine(3),
          _buildStepDot(4, 'Kagua'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? _successColor : (isActive ? _iconBg : _primaryBg),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? _successColor : (isActive ? _iconBg : _borderColor),
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : _secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? _primaryText : _secondaryText,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;

    return Container(
      width: 12,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isCompleted ? _successColor : _borderColor,
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildProductSelectionStep();
      case 1:
        return _buildLoanTypeStep();
      case 2:
        return _buildLoanDetailsStep();
      case 3:
        return _buildGuarantorsStep();
      case 4:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProductSelectionStep() {
    final loanProducts = DataStore.loanProducts ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chagua Bidhaa ya Mkopo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the loan product that best fits your needs',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          if (loanProducts.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: _accentColor),
                    const SizedBox(height: 16),
                    Text(
                      'Hakuna bidhaa za mikopo zilizopo',
                      style: TextStyle(fontSize: 16, color: _secondaryText),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: loanProducts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final product = loanProducts[index];
                final isSelected = _selectedProduct?['id'] == product['id'];
                final minAmount = double.tryParse(product['minAmount']?.toString() ?? '0') ?? 0;
                final maxAmount = double.tryParse(product['maxAmount']?.toString() ?? '0') ?? 0;
                final interestRate = double.tryParse(product['interestRate']?.toString() ?? '0') ?? 0;

                return GestureDetector(
                  onTap: () => _onProductSelected(product),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _iconBg : _borderColor,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _iconBg.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? _iconBg : _primaryBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: isSelected ? Colors.white : _iconBg,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name']?.toString() ?? 'Unnamed Product',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? _iconBg : _primaryText,
                                    ),
                                  ),
                                  if (product['description'] != null && product['description'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        product['description'].toString(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: _secondaryText,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: _successColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _primaryBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildProductDetail(
                                      Icons.money_rounded,
                                      'Loan Amount',
                                      '${formatCurrency.format(minAmount)}\n${formatCurrency.format(maxAmount)}',
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: _borderColor,
                                  ),
                                  Expanded(
                                    child: _buildProductDetail(
                                      Icons.percent_rounded,
                                      'Interest Rate',
                                      '$interestRate% p.a.',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: _borderColor, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildProductDetail(
                                      Icons.schedule_rounded,
                                      'Loan Period',
                                      '${product['minTenure']} - ${product['maxTenure']} months',
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: _borderColor,
                                  ),
                                  Expanded(
                                    child: _buildProductDetail(
                                      Icons.receipt_long_rounded,
                                      'Charges',
                                      '${(product['charges'] as List?)?.length ?? 0} fees',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: _secondaryText),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: _primaryText,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoanTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aina ya Mkopo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'What type of loan application is this?',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          _buildLoanTypeCard(
            'new',
            'New Loan',
            'Apply for a fresh loan with no existing obligations',
            Icons.add_circle_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildLoanTypeCard(
            'topup',
            'Top-up',
            'Increase your existing loan amount',
            Icons.trending_up_rounded,
          ),
          if (_selectedLoanType == 'topup') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select Existing Loan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                      ),
                      if (_loadingLoans)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingLoans)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Loading your loans...',
                          style: TextStyle(color: _secondaryText),
                        ),
                      ),
                    )
                  else if (_activeLoans.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _primaryBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: _secondaryText, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No active loans found. You need an active loan to top-up.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_activeLoans.length, (index) {
                      final loan = _activeLoans[index];
                      final isSelected = _selectedExistingLoan?['loanId'] == loan['loanId'];
                      final loanNumber = loan['loanNumber']?.toString() ?? 'N/A';
                      final product = loan['productName']?.toString() ?? 'Loan';
                      final outstanding = double.tryParse(loan['outstandingBalance']?.toString() ?? '0') ?? 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedExistingLoan = loan;
                              _existingLoanController.text = loanNumber;
                              _outstandingBalanceController.text = outstanding.toStringAsFixed(0);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? _iconBg.withOpacity(0.05) : _primaryBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _iconBg : _borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _iconBg : _accentColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? _iconBg : _primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Loan #$loanNumber',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Outstanding: ${formatCurrency.format(outstanding)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? _iconBg : _primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: _iconBg,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoanTypeCard(String value, String title, String description, IconData icon) {
    final isSelected = _selectedLoanType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLoanType = value;
          _selectedExistingLoan = null; // Reset selected loan
        });

        // Load active loans when top-up is selected
        if (value == 'topup') {
          _loadActiveLoans();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _iconBg : _borderColor,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _iconBg.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? _iconBg : _primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : _iconBg,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? _iconBg : _primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: _successColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kiasi na Masharti',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the loan amount and terms',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _principalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Loan Amount (TZS) *',
                    hintText: _productMinAmount != null && _productMaxAmount != null
                        ? '${formatCurrency.format(_productMinAmount!)} - ${formatCurrency.format(_productMaxAmount!)}'
                        : 'Enter amount',
                    helperText: _productMinAmount != null && _productMaxAmount != null
                        ? 'Range: ${formatCurrency.format(_productMinAmount!)} - ${formatCurrency.format(_productMaxAmount!)}'
                        : null,
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required field';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter valid amount';
                    }
                    if (_productMinAmount != null && amount < _productMinAmount!) {
                      return 'Minimum: ${formatCurrency.format(_productMinAmount!)}';
                    }
                    if (_productMaxAmount != null && amount > _productMaxAmount!) {
                      return 'Maximum: ${formatCurrency.format(_productMaxAmount!)}';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _tenureController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Loan Period (Months) *',
                    hintText: _productMinTenure != null && _productMaxTenure != null
                        ? '$_productMinTenure - $_productMaxTenure months'
                        : 'Enter months',
                    helperText: _productMinTenure != null && _productMaxTenure != null
                        ? 'Range: $_productMinTenure - $_productMaxTenure months'
                        : null,
                    prefixIcon: const Icon(Icons.schedule_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required field';
                    final tenure = int.tryParse(value);
                    if (tenure == null || tenure <= 0) {
                      return 'Enter valid months';
                    }
                    if (_productMinTenure != null && tenure < _productMinTenure!) {
                      return 'Minimum: $_productMinTenure months';
                    }
                    if (_productMaxTenure != null && tenure > _productMaxTenure!) {
                      return 'Maximum: $_productMaxTenure months';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _interestRateController,
                  enabled: !_fixedInterestRate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Interest Rate (% p.a.) *',
                    hintText: 'e.g., 12.50',
                    prefixIcon: const Icon(Icons.percent_rounded),
                    suffixIcon: _fixedInterestRate
                        ? const Tooltip(
                            message: 'Fixed by product',
                            child: Icon(Icons.lock_rounded, size: 18),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required field';
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Enter valid rate';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _repaymentFrequency,
                  decoration: InputDecoration(
                    labelText: 'Repayment Frequency *',
                    prefixIcon: const Icon(Icons.repeat_rounded),
                    suffixIcon: _fixedRepaymentFrequency
                        ? const Tooltip(
                            message: 'Fixed by product',
                            child: Icon(Icons.lock_rounded, size: 18),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'Bi-Weekly', child: Text('Bi-Weekly')),
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                  ],
                  onChanged: _fixedRepaymentFrequency
                      ? null
                      : (value) {
                          setState(() {
                            _repaymentFrequency = value!;
                          });
                        },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _gracePeriodController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Grace Period (Days)',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          if (_charges.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Ada na Gharama',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                children: _charges.map((charge) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          charge['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: _secondaryText,
                          ),
                        ),
                        Text(
                          formatCurrency.format(double.tryParse(charge['amount'].toString()) ?? 0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuarantorsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wadhamini',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select members who will guarantee your loan',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 24),

          // Selected Guarantors Summary
          if (_selectedGuarantors.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _iconBg.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _iconBg.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _successColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_selectedGuarantors.length} Guarantor${_selectedGuarantors.length > 1 ? 's' : ''} Selected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                      ),
                      if (_selectedGuarantors.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedGuarantors.clear();
                            });
                          },
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_selectedGuarantors.length, (index) {
                    final guarantor = _selectedGuarantors[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _iconBg,
                            child: Text(
                              (guarantor['name']?.toString()[0] ?? 'G').toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  guarantor['name']?.toString() ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryText,
                                  ),
                                ),
                                Text(
                                  guarantor['phone']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedGuarantors.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Search Bar
          TextField(
            controller: _guarantorSearchController,
            decoration: InputDecoration(
              labelText: 'Search Members',
              hintText: 'Search by name or phone...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _guarantorSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _guarantorSearchController.clear();
                        _filterMembers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: _filterMembers,
          ),
          const SizedBox(height: 16),

          // Members List
          if (_filteredMembers.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.people_outline_rounded, size: 64, color: _accentColor),
                    const SizedBox(height: 16),
                    Text(
                      'No members found',
                      style: TextStyle(fontSize: 16, color: _secondaryText),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredMembers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = _filteredMembers[index];
                final isSelected = _selectedGuarantors.any((g) => g['userId'] == member['userId']);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGuarantors.removeWhere((g) => g['userId'] == member['userId']);
                      } else {
                        _selectedGuarantors.add(member);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _successColor : _borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _successColor.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSelected ? _successColor : _primaryBg,
                          radius: 24,
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text(
                                  (member['name']?.toString()[0] ?? 'M').toUpperCase(),
                                  style: TextStyle(
                                    color: _iconBg,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name']?.toString() ?? 'Unknown Member',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _successColor : _primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member['phone']?.toString() ?? 'No phone',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _secondaryText,
                                ),
                              ),
                              if (member['role'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _primaryBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      member['role'].toString(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: _secondaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: _successColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muhtasari wa Mkopo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your loan application details',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 24),

          // Product Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Loan Product',
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondaryText,
                            ),
                          ),
                          Text(
                            _selectedProduct?['name']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Loan Type
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category_rounded, color: _iconBg, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Loan Type',
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                        ),
                      ),
                      Text(
                        _selectedLoanType == 'new'
                            ? 'New Loan'
                            : 'Top-up',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Existing Loan Info (for top-up)
          if (_selectedLoanType == 'topup') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primaryBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.history_rounded, color: _iconBg, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Existing Loan Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: _borderColor, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Loan Number',
                        style: TextStyle(fontSize: 13, color: _secondaryText),
                      ),
                      Text(
                        _existingLoanController.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Outstanding Balance',
                        style: TextStyle(fontSize: 13, color: _secondaryText),
                      ),
                      Text(
                        formatCurrency.format(_outstandingBalance),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Exposure',
                        style: TextStyle(fontSize: 13, color: _secondaryText, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        formatCurrency.format(_totalExposure),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _iconBg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Guarantors
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people_rounded, color: _iconBg, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Guarantors',
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondaryText,
                            ),
                          ),
                          Text(
                            '${_selectedGuarantors.length} Selected',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_selectedGuarantors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: _borderColor, height: 1),
                  const SizedBox(height: 12),
                  ...List.generate(_selectedGuarantors.length, (index) {
                    final guarantor = _selectedGuarantors[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _iconBg,
                            radius: 20,
                            child: Text(
                              (guarantor['name']?.toString()[0] ?? 'G').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  guarantor['name']?.toString() ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryText,
                                  ),
                                ),
                                Text(
                                  guarantor['phone']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: _successColor,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Figures
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_iconBg, _iconBg.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildReviewRow('Principal Amount', formatCurrency.format(_principal), isWhite: true),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.3), height: 1),
                const SizedBox(height: 16),
                _buildReviewRow('Total Charges', formatCurrency.format(_totalCharges), isWhite: true),
                const SizedBox(height: 16),
                _buildReviewRow('Interest Amount', formatCurrency.format(_totalInterest), isWhite: true),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Repayment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          formatCurrency.format(_totalRepayment),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                _buildReviewRow('Monthly Installment', formatCurrency.format(_installmentAmount), isBold: true),
                const SizedBox(height: 12),
                _buildReviewRow('Loan Period', '$_tenure months'),
                const SizedBox(height: 12),
                _buildReviewRow('Repayment Frequency', _repaymentFrequency),
                const SizedBox(height: 12),
                _buildReviewRow(
                  'First Payment',
                  DateFormat('dd MMM yyyy').format(_firstPaymentDate),
                ),
                const SizedBox(height: 12),
                _buildReviewRow(
                  'Maturity Date',
                  _maturityDate != null ? DateFormat('dd MMM yyyy').format(_maturityDate!) : '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isBold = false, bool isWhite = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isWhite ? Colors.white.withOpacity(0.9) : _secondaryText,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isWhite ? Colors.white : _primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: _borderColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: _primaryText),
                    SizedBox(width: 8),
                    Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _currentStep == 4 ? _submitLoanApplication : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _iconBg,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 4 ? 'Submit' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_currentStep == 4 ? Icons.check_rounded : Icons.arrow_forward_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitLoanApplication() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting application...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generate application ID
      final applicationId = 'LA_${DateTime.now().millisecondsSinceEpoch}';

      // Prepare application payload
      final productId = (_selectedProduct?['productId'] ?? _selectedProduct?['id'] ?? '').toString();

      final application = {
        'applicationId': applicationId,
        'kikobaId': DataStore.currentKikobaId,
        'userId': DataStore.currentUserId,
        'applicantName': DataStore.currentUserName,
        'applicantPhone': DataStore.userNumber,
        'loanProduct': {
          'productId': productId,  // Send complete productId
          'productName': _selectedProduct?['name'],
        },
        'loanType': _selectedLoanType,
        'loanDetails': {
          'principalAmount': _principal,
          'interestRate': _interestRate,
          'tenure': _tenure,
          'repaymentFrequency': _repaymentFrequency,
          'gracePeriod': _gracePeriod,
        },
        if (_selectedLoanType == 'topup')
          'existingLoan': {
            'loanId': _selectedExistingLoan?['loanId'],
            'loanNumber': _existingLoanController.text,
            'outstandingBalance': _outstandingBalance,
          },
        'guarantors': _selectedGuarantors.asMap().entries.map((entry) {
          final g = entry.value;
          // Calculate guaranteed amount per guarantor (equal split)
          // If guarantor has a specific amount set, use that; otherwise split equally
          final guaranteedAmount = g['amount'] != null
              ? (g['amount'] is num ? (g['amount'] as num).toDouble() : double.tryParse(g['amount'].toString()) ?? 0.0)
              : (_principal / _selectedGuarantors.length);

          final guarantor = <String, dynamic>{
            'userId': g['userId'],
            'name': g['name'],
            'phone': g['phone'],
            'amount': guaranteedAmount,
          };
          // Only include role if it's a non-empty string
          final role = g['role'];
          if (role != null && role is String && role.isNotEmpty) {
            guarantor['role'] = role;
          }
          return guarantor;
        }).toList(),
        'charges': _charges.map((c) => {
          'name': c['name'],
          'amount': double.tryParse(c['amount'].toString()) ?? 0.0,
          'type': c['isProductCharge'] == true ? 'product' : 'custom',
        }).toList(),
        'calculations': {
          'grossLoanAmount': _grossLoanAmount,
          'totalCharges': _totalCharges,
          'netDisbursement': _netDisbursement,
          'totalInterest': _totalInterest,
          'totalRepayment': _totalRepayment,
          'monthlyInstallment': _installmentAmount,
          'totalExposure': _totalExposure,
          'firstPaymentDate': _firstPaymentDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
          'maturityDate': _maturityDate?.toIso8601String().split('T')[0],
        },
        'metadata': {
          'applicationDate': DateTime.now().toIso8601String(),
          'deviceInfo': 'Mobile App',
          'appVersion': '1.0.0',
        },
      };

      // Submit application
      final response = await HttpService.submitLoanApplication(application);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response != null && response['status'] == 'success') {
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: _successColor, size: 32),
                  SizedBox(width: 12),
                  Text('Success!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your loan application has been submitted successfully!'),
                  const SizedBox(height: 16),
                  Text('Application ID: ${response['data']?['applicationId'] ?? applicationId}'),
                  const SizedBox(height: 8),
                  Text('Amount: ${formatCurrency.format(_principal)}'),
                  Text('Monthly Payment: ${formatCurrency.format(_installmentAmount)}'),
                  Text('Duration: $_tenure months'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Steps:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...(response['data']?['nextSteps'] as List<dynamic>? ?? [])
                            .map((step) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• '),
                                      Expanded(child: Text(step.toString())),
                                    ],
                                  ),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _iconBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } else {
        // Show error dialog
        if (mounted) {
          // Parse error message from response
          String errorTitle = 'Ombi Limeshindwa';
          String errorMessage = 'Kuna tatizo limetokea. Tafadhali jaribu tena.';
          List<String> errorDetails = [];

          if (response != null) {
            // Extract main error message
            if (response['message'] != null) {
              errorMessage = response['message'];
            }

            // Extract validation errors
            if (response['errors'] != null && response['errors'] is List) {
              for (var error in response['errors']) {
                if (error is Map && error['message'] != null) {
                  errorDetails.add(error['message']);
                }
              }
            }
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorTitle)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (errorDetails.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Maelezo:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          ...errorDetails.map((detail) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• '),
                                    Expanded(child: Text(detail)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Sawa, Nimeelewa'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error dialog for exceptions
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Kosa'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kuna tatizo limetokea wakati wa kutuma ombi lako.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Sawa'),
              ),
            ],
          ),
        );
      }
    }
  }
}
