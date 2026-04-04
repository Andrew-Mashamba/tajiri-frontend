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
import 'LoanDetailPage.dart';

// Monochrome Design Guidelines Colors
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _borderColor = Color(0xFFE0E0E0);
const _successColor = Color(0xFF4CAF50);
const _warningColor = Color(0xFFFF9800);
const _errorColor = Color(0xFFF44336);

class MyLoansListPage extends StatefulWidget {
  const MyLoansListPage({super.key});

  @override
  State<MyLoansListPage> createState() => _MyLoansListPageState();
}

class _MyLoansListPageState extends State<MyLoansListPage> {
  final Logger _logger = Logger();
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
  final formatDate = DateFormat('dd MMM yyyy');

  List<dynamic> _loans = [];

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
    _loadData();
    _setupFirestoreListener();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  /// Load data: first from cache for instant display, then from backend API
  Future<void> _loadData() async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty) {
      _logger.e('[MyLoansListPage] Cannot load data - kikobaId or visitorId is empty');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Step 1: Try to load cached data for instant display
    final cachedData = await PageCacheService.getLoansData(visitorId, kikobaId);
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[MyLoansListPage] Loaded cached data for instant display');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend(showLoadingIfNoCachedData: !_hasCachedData);
  }

  /// Apply cached data
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['loans'] != null) {
      _loans = List<dynamic>.from(data['loans']);
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
      _logger.d('[MyLoansListPage] Calling getUserLoans API...');

      // Call API to get user loans from BACKEND
      final response = await HttpService.getUserLoans();

      if (mounted) {
        if (response != null && response['success'] == true) {
          final loans = response['loans'] as List<dynamic>? ?? [];
          _logger.d('[MyLoansListPage] Fetched ${loans.length} loans from backend');

          setState(() {
            _loans = loans;
            _isInitialLoading = false;
            _hasCachedData = true;
          });

          // Cache the data for next time
          await PageCacheService.saveLoansData(visitorId, kikobaId, {
            'loans': loans,
            'fetchedAt': DateTime.now().toIso8601String(),
          });
        } else {
          _logger.e('[MyLoansListPage] API call failed: $response');
          setState(() => _isInitialLoading = false);

          if (!_hasCachedData && response != null) {
            final errorMessage = response['message'] ?? 'Imeshindwa kupakua mikopo';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      }
    } catch (e) {
      _logger.e('[MyLoansListPage] Error fetching data from backend: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        if (!_hasCachedData) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tatizo la mtandao. Tafadhali jaribu tena.')),
          );
        }
      }
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

      // Only read version info from Firestore (not actual data)
      final newVersion = notificationData['loans_version'] as int?;
      final updatedAt = notificationData['loans_updated_at'];
      int? effectiveVersion = newVersion;

      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[MyLoansListPage] Firestore notification: version changed');
        _lastKnownVersion = effectiveVersion;
        await _fetchDataFromBackend(forceRefresh: true);
      }
    }, onError: (e) {
      _logger.e('[MyLoansListPage] Firestore listener error: $e');
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

  /// Get status color using LoanStatus enum
  Color _getStatusColor(String? status) {
    final loanStatus = LoanStatus.fromString(status);
    // Map to our local color scheme
    final statusColor = loanStatus.statusColor;
    if (statusColor == Colors.green) return _successColor;
    if (statusColor == Colors.orange) return _warningColor;
    if (statusColor == Colors.red) return _errorColor;
    if (statusColor == Colors.blue) return _secondaryText; // closed
    return _secondaryText;
  }

  /// Get status label using LoanStatus enum
  String _getStatusLabel(String? status) {
    return LoanStatus.fromString(status).displayName;
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
          'Mikopo Yangu',
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
            ),
        ],
      ),
      body: _isInitialLoading && !_hasCachedData
          ? _buildSkeletonLoading()
          : _loans.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _loans.length,
                    itemBuilder: (context, index) {
                      final loan = _loans[index];
                      return _buildLoanCard(loan);
                    },
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(value * 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                  Container(height: 1, color: _borderColor),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 50, height: 12, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 4),
                            Container(width: 100, height: 16, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.3), borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 40, height: 12, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 4),
                            Container(width: 100, height: 16, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.3), borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hakuna Mikopo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hujawahi kuomba mkopo',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    // Extract loan details from new API structure
    final loanNumber = loan['applicationId']?.toString() ?? loan['loanNumber']?.toString() ?? 'N/A';
    final loanProduct = loan['loanProduct'] as Map<String, dynamic>?;
    final productName = loanProduct?['productName']?.toString() ?? loan['productName']?.toString() ?? 'Mkopo';
    final principal = double.tryParse(loan['principalAmount']?.toString() ?? '0') ?? 0.0;

    // For outstanding balance, use from calculations or assume full amount for pending loans
    final calculations = loan['calculations'] as Map<String, dynamic>?;
    final outstanding = double.tryParse(loan['outstandingBalance']?.toString() ?? calculations?['totalRepayment']?.toString() ?? '0') ?? 0.0;

    final status = loan['status']?.toString();

    // Extract dates from dates object
    final dates = loan['dates'] as Map<String, dynamic>?;
    final disbursedDate = dates?['disbursedDate']?.toString() ?? loan['disbursedDate']?.toString();
    final maturityDate = dates?['maturityDate']?.toString() ?? loan['maturityDate']?.toString();
    final applicationDate = dates?['applicationDate']?.toString();

    // Extract guarantor information
    final guarantors = loan['guarantors'] as List<dynamic>? ?? [];
    final approvedGuarantors = guarantors.where((g) => g['status'] == 'approved').length;
    final pendingGuarantors = guarantors.where((g) => g['status'] == 'pending').length;
    final rejectedGuarantors = guarantors.where((g) => g['status'] == 'rejected').length;
    final totalGuarantors = guarantors.length;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanDetailPage(loan: loan),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Namba: $loanNumber',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: _secondaryText, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: _borderColor, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mkopo',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency.format(principal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deni',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency.format(outstanding),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: outstanding > 0 ? _errorColor : _successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Guarantor Information
          if (totalGuarantors > 0) ...[
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
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 16, color: _secondaryText),
                      const SizedBox(width: 6),
                      Text(
                        'Wadhamini ($totalGuarantors)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (approvedGuarantors > 0)
                        _buildGuarantorBadge('Wameidhinisha: $approvedGuarantors', _successColor),
                      if (pendingGuarantors > 0)
                        _buildGuarantorBadge('Wanasubiri: $pendingGuarantors', _warningColor),
                      if (rejectedGuarantors > 0)
                        _buildGuarantorBadge('Wamekataa: $rejectedGuarantors', _errorColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
          // Dates
          if (applicationDate != null || disbursedDate != null || maturityDate != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (applicationDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.send, size: 14, color: _secondaryText),
                      const SizedBox(width: 6),
                      Text(
                        'Imetumwa: ${_formatDateString(applicationDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                if (disbursedDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: _secondaryText),
                      const SizedBox(width: 6),
                      Text(
                        'Kutoka: ${_formatDateString(disbursedDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                if (maturityDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 14, color: _secondaryText),
                      const SizedBox(width: 6),
                      Text(
                        'Hadi: ${_formatDateString(maturityDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return formatDate.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildGuarantorBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
