import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../DataStore.dart';
import '../HttpService.dart';
import '../services/page_cache_service.dart';
import '../models/loan_models.dart';
import '../services/loan_service.dart';
import '../screens/udhamini/guarantee_terms_screen.dart';

// Monochrome Design Guidelines Colors
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);
const _borderColor = Color(0xFFE0E0E0);
const _successColor = Color(0xFF4CAF50);
const _warningColor = Color(0xFFFF9800);
const _errorColor = Color(0xFFF44336);

class UdhaminiWaMikopoPage extends StatefulWidget {
  const UdhaminiWaMikopoPage({super.key});

  @override
  State<UdhaminiWaMikopoPage> createState() => _UdhaminiWaMikopoPageState();
}

class _UdhaminiWaMikopoPageState extends State<UdhaminiWaMikopoPage> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 2);
  late TabController _tabController;

  List<dynamic> _pendingRequests = [];
  List<dynamic> _guaranteedLoans = [];
  Map<String, dynamic>? _guarantorLimits;

  // ============ State for caching and real-time updates ============
  /// IMPORTANT: All data is fetched from the BACKEND API.
  /// Firestore is used ONLY for change notifications, NOT for data.
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  bool _isRefreshing = false;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _setupFirestoreListener();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
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

      // Only read version info from Firestore (not actual data)
      final newVersion = notificationData['guarantees_version'] as int?;
      final updatedAt = notificationData['guarantees_updated_at'];
      int? effectiveVersion = newVersion;

      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[UdhaminiPage] Firestore notification: version changed');
        _lastKnownVersion = effectiveVersion;
        await _fetchDataFromBackend(forceRefresh: true);
      }
    }, onError: (e) {
      _logger.e('[UdhaminiPage] Firestore listener error: $e');
    });
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hakuna mtandao. Tafadhali jaribu tena.')),
        );
      }
      return;
    }

    setState(() => _isRefreshing = true);
    await _fetchDataFromBackend(forceRefresh: true);
    setState(() => _isRefreshing = false);
  }

  // Helper function to show error dialog
  void _showErrorDialog(String title, String message, {List<String>? details}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _errorColor, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (details != null && details.isNotEmpty) ...[
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
                    ...details.map((detail) => Padding(
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
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Sawa, Nimeelewa'),
          ),
        ],
      ),
    );
  }

  /// Load data: first from cache for instant display, then from backend API
  Future<void> _loadData() async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty) {
      _logger.e('[UdhaminiPage] Cannot load data - kikobaId or visitorId is empty');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Step 1: Try to load cached data for instant display
    final cachedData = await PageCacheService.getUdhaminiData(visitorId, kikobaId);
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[UdhaminiPage] Loaded cached data for instant display');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend(showLoadingIfNoCachedData: !_hasCachedData);
  }

  /// Apply cached data
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['pendingRequests'] != null) {
      _pendingRequests = List<dynamic>.from(data['pendingRequests']);
    }
    if (data['guaranteedLoans'] != null) {
      _guaranteedLoans = List<dynamic>.from(data['guaranteedLoans']);
    }
    if (data['guarantorLimits'] != null) {
      _guarantorLimits = Map<String, dynamic>.from(data['guarantorLimits']);
    }
  }

  /// Fetch fresh data from backend API and cache it
  /// IMPORTANT: All data comes from the backend, NOT from Firestore!
  Future<void> _fetchDataFromBackend({bool showLoadingIfNoCachedData = false, bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty) return;

    if (showLoadingIfNoCachedData && mounted) {
      setState(() => _isInitialLoading = true);
    }

    try {
      final results = await Future.wait([
        HttpService.getPendingGuaranteeRequests(),
        HttpService.getMyGuaranteedLoans(),
        HttpService.getGuarantorLimit(),
      ]);

      _logger.d('[UdhaminiPage] Fetched data from backend');

      if (mounted) {
        setState(() {
          _pendingRequests = (results[0] as List<dynamic>?) ?? [];
          _guaranteedLoans = (results[1] as List<dynamic>?) ?? [];
          _guarantorLimits = results[2] as Map<String, dynamic>?;
          _isInitialLoading = false;
          _hasCachedData = true;
        });

        // Cache the data for next time
        await PageCacheService.saveUdhaminiData(visitorId, kikobaId, {
          'pendingRequests': _pendingRequests,
          'guaranteedLoans': _guaranteedLoans,
          'guarantorLimits': _guarantorLimits,
          'fetchedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      _logger.e('[UdhaminiPage] Error fetching data from backend: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        if (!_hasCachedData) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading data: $e')),
          );
        }
      }
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
          'Udhamini wa Mikopo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _handleRefresh,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${_pendingRequests.length}'),
                isLabelVisible: _pendingRequests.isNotEmpty,
                child: const Icon(Icons.pending_actions_rounded),
              ),
              text: 'Pending',
            ),
            Tab(
              icon: Badge(
                label: Text('${_guaranteedLoans.length}'),
                isLabelVisible: _guaranteedLoans.isNotEmpty,
                child: const Icon(Icons.verified_user_rounded),
              ),
              text: 'Active',
            ),
            const Tab(
              icon: Icon(Icons.analytics_rounded),
              text: 'Limits',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isInitialLoading && !_hasCachedData
            ? _buildSkeletonLoading()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingRequestsTab(),
                  _buildGuaranteedLoansTab(),
                  _buildLimitsTab(),
                ],
              ),
      ),
    );
  }

  /// Build skeleton loading animation
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 0.7),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
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
                      Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.3), borderRadius: BorderRadius.circular(12))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.3), borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 8),
                            Container(width: 80, height: 12, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                      ),
                      Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(12))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(8)))),
                      const SizedBox(width: 12),
                      Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(8)))),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: _accentColor),
            const SizedBox(height: 16),
            Text(
              'No Pending Requests',
              style: TextStyle(fontSize: 18, color: _secondaryText, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no pending guarantee requests',
              style: TextStyle(fontSize: 14, color: _accentColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildPendingRequestCard(request);
        },
      ),
    );
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> request) {
    // Parse nested backend response structure
    final loanDetails = request['loanDetails'] as Map<String, dynamic>? ?? {};
    final applicant = request['applicant'] as Map<String, dynamic>? ?? {};
    final loanProduct = request['loanProduct'] as Map<String, dynamic>? ?? {};

    // Use guaranteedAmount first, fallback to principalAmount from loanDetails
    final guaranteedAmount = double.tryParse(request['guaranteedAmount']?.toString() ?? '0') ?? 0.0;
    final principal = guaranteedAmount > 0
        ? guaranteedAmount
        : (double.tryParse(loanDetails['principalAmount']?.toString() ?? '0') ?? 0.0);
    final tenure = int.tryParse(loanDetails['tenure']?.toString() ?? '0') ?? 0;
    final interestRate = double.tryParse(loanDetails['interestRate']?.toString() ?? '0') ?? 0.0;

    // Calculate installment if not provided by backend
    var installment = double.tryParse(loanDetails['monthlyInstallment']?.toString() ?? '0') ?? 0.0;
    if (installment == 0 && principal > 0 && tenure > 0) {
      // Simple interest calculation: (Principal + Interest) / Tenure
      final principalAmount = double.tryParse(loanDetails['principalAmount']?.toString() ?? '0') ?? principal;
      final totalInterest = principalAmount * interestRate / 100;
      installment = (principalAmount + totalInterest) / tenure;
    }

    // Parse applicant and product info
    final applicantName = applicant['name']?.toString() ?? request['applicantName']?.toString() ?? 'Unknown';
    final productName = loanProduct['productName']?.toString() ?? request['productName']?.toString() ?? 'N/A';
    final applicationId = request['applicationId']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _warningColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: _warningColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _warningColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _warningColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guarantee Request',
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        applicantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _warningColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.account_balance_wallet_rounded,
                        'Amount',
                        formatCurrency.format(principal),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.credit_card_rounded,
                        'Product',
                        productName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.schedule_rounded,
                        'Tenure',
                        '$tenure months',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.payment_rounded,
                        'Installment',
                        formatCurrency.format(installment),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(applicationId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _errorColor,
                          side: BorderSide(color: _errorColor, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveGuarantee(applicationId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _successColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteedLoansTab() {
    if (_guaranteedLoans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 80, color: _accentColor),
            const SizedBox(height: 16),
            Text(
              'No Guaranteed Loans',
              style: TextStyle(fontSize: 18, color: _secondaryText, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'You are not guaranteeing any loans',
              style: TextStyle(fontSize: 14, color: _accentColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _guaranteedLoans.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final loan = _guaranteedLoans[index];
          return _buildGuaranteedLoanCard(loan);
        },
      ),
    );
  }

  Widget _buildGuaranteedLoanCard(Map<String, dynamic> loan) {
    // Parse nested backend response structure
    final loanDetails = loan['loanDetails'] as Map<String, dynamic>? ?? {};
    final applicant = loan['applicant'] as Map<String, dynamic>? ?? {};
    final loanProduct = loan['loanProduct'] as Map<String, dynamic>? ?? {};

    // Use guaranteedAmount first, fallback to principalAmount from loanDetails
    final guaranteedAmount = double.tryParse(loan['guaranteedAmount']?.toString() ?? '0') ?? 0.0;
    final principal = guaranteedAmount > 0
        ? guaranteedAmount
        : (double.tryParse(loanDetails['principalAmount']?.toString() ?? '0') ?? 0.0);
    final balance = double.tryParse(loan['outstandingBalance']?.toString() ?? '0') ?? 0.0;

    // Parse applicant info - try nested first, then flat fallback
    final applicantName = applicant['name']?.toString() ?? loan['applicantName']?.toString() ?? 'Unknown';
    final productName = loanProduct['productName']?.toString() ?? loan['productName']?.toString() ?? 'N/A';

    // Status can be guaranteeStatus or applicationStatus
    final status = loan['guaranteeStatus']?.toString() ?? loan['applicationStatus']?.toString() ?? loan['status']?.toString() ?? 'active';
    final applicationId = loan['applicationId']?.toString() ?? '';

    final statusColor = status == 'active' || status == 'approved' ? _successColor
        : status == 'defaulted' || status == 'rejected' ? _errorColor
        : status == 'pending' || status == 'pending_approval' ? _warningColor
        : _accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.2),
                child: Icon(Icons.verified_user_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Principal:', style: TextStyle(color: _secondaryText)),
                    Text(
                      formatCurrency.format(principal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Outstanding:', style: TextStyle(color: _secondaryText)),
                    Text(
                      formatCurrency.format(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: balance > 0 ? _errorColor : _successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _withdrawGuarantee(applicationId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _errorColor,
                    side: BorderSide(color: _errorColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  label: const Text('Withdraw Guarantee'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLimitsTab() {
    if (_guarantorLimits == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxGuaranteeAmount = double.tryParse(_guarantorLimits!['maxGuaranteeAmount']?.toString() ?? '0') ?? 0.0;
    final currentGuaranteeAmount = double.tryParse(_guarantorLimits!['currentGuaranteeAmount']?.toString() ?? '0') ?? 0.0;
    final availableAmount = maxGuaranteeAmount - currentGuaranteeAmount;
    final maxActiveLoans = int.tryParse(_guarantorLimits!['maxActiveLoans']?.toString() ?? '0') ?? 0;
    final currentActiveLoans = int.tryParse(_guarantorLimits!['currentActiveLoans']?.toString() ?? '0') ?? 0;
    final utilizationPercentage = maxGuaranteeAmount > 0 ? (currentGuaranteeAmount / maxGuaranteeAmount * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guarantor Capacity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your current guarantee limits and usage',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 24),

          // Utilization Card
          Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Utilization',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${utilizationPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: utilizationPercentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      utilizationPercentage > 80
                          ? _errorColor
                          : utilizationPercentage > 50
                              ? _warningColor
                              : _successColor,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Limits Grid
          Row(
            children: [
              Expanded(
                child: _buildLimitCard(
                  'Max Guarantee',
                  formatCurrency.format(maxGuaranteeAmount),
                  Icons.account_balance_wallet_rounded,
                  _iconBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLimitCard(
                  'Current Usage',
                  formatCurrency.format(currentGuaranteeAmount),
                  Icons.trending_up_rounded,
                  _warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLimitCard(
                  'Available',
                  formatCurrency.format(availableAmount),
                  Icons.savings_rounded,
                  _successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLimitCard(
                  'Active Loans',
                  '$currentActiveLoans / $maxActiveLoans',
                  Icons.format_list_numbered_rounded,
                  _accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: _accentColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Important Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('• Your guarantee limit is based on your savings'),
                _buildInfoRow('• You can guarantee up to $maxActiveLoans loans simultaneously'),
                _buildInfoRow('• Withdraw guarantees for pending applications only'),
                _buildInfoRow('• You are liable if the borrower defaults'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _secondaryText),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: _secondaryText,
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'INASUBIRI';
      case 'pending_approval':
        return 'INASUBIRI';
      case 'approved':
        return 'IMEKUBALIWA';
      case 'rejected':
        return 'IMEKATALIWA';
      case 'active':
        return 'INAENDELEA';
      case 'defaulted':
        return 'IMESHINDWA';
      case 'closed':
        return 'IMEFUNGWA';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _approveGuarantee(String applicationId) async {
    // Find the request to get loan details
    final request = _pendingRequests.firstWhere(
      (r) => r['applicationId']?.toString() == applicationId,
      orElse: () => <String, dynamic>{},
    );

    if (request.isEmpty) {
      _showErrorDialog('Hitilafu', 'Haikuweza kupata maelezo ya ombi la mkopo.');
      return;
    }

    // Create LoanApplication from request data
    final loanApplication = LoanApplication.fromJson(request as Map<String, dynamic>);

    // Navigate to GuaranteeTermsScreen for review before approval
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuaranteeTermsScreen(
          application: loanApplication,
          onAccept: () async {
            // Call LoanService to approve
            final result = await LoanService.approveGuarantee(applicationId);
            if (result.success) {
              if (mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: _successColor,
                  ),
                );
                _loadData();
              }
            } else {
              if (mounted) {
                _showErrorDialog('Imeshindikana', result.message);
              }
            }
          },
          onReject: (String reason) async {
            final result = await LoanService.rejectGuarantee(
              applicationId,
              reason: reason,
            );
            if (result.success) {
              if (mounted) {
                Navigator.pop(context, false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: _errorColor,
                  ),
                );
                _loadData();
              }
            } else {
              if (mounted) {
                _showErrorDialog('Imeshindikana', result.message);
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(String applicationId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kataa Udhamini'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tafadhali toa sababu ya kukataa udhamini huu:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Sababu',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _errorColor),
            child: const Text('Kataa'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) {
      if (confirmed == true && reasonController.text.trim().isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tafadhali weka sababu ya kukataa')),
        );
      }
      return;
    }

    try {
      // Use LoanService for typed response
      final result = await LoanService.rejectGuarantee(
        applicationId,
        reason: reasonController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: _errorColor,
            ),
          );
          _loadData();
        } else {
          _showErrorDialog('Imeshindikana', result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Hitilafu',
          'Tatizo limetokea wakati wa kukataa udhamini.',
          details: [e.toString()],
        );
      }
    }
  }

  Future<void> _withdrawGuarantee(String applicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ondoa Udhamini'),
        content: const Text(
          'Je, una uhakika unataka kujiondoa kwenye udhamini wa ombi hili la mkopo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _errorColor),
            child: const Text('Jiondoe'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Use LoanService for typed response
      final result = await LoanService.withdrawGuarantee(applicationId);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: _successColor,
            ),
          );
          _loadData();
        } else {
          _showErrorDialog('Imeshindikana', result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Hitilafu',
          'Tatizo limetokea wakati wa kujiondoa kwenye udhamini.',
          details: [e.toString()],
        );
      }
    }
  }
}
