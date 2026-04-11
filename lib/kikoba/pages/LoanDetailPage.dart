import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../../services/income_service.dart';
import '../../services/local_storage_service.dart';
import '../DataStore.dart';
import '../HttpService.dart';
import '../services/page_cache_service.dart';
import '../services/loan_service.dart';
import '../models/loan_models.dart';
import '../widgets/loan/loan_widgets.dart';
import '../screens/mikopo/payment_schedule_screen.dart';
import '../selectPaymentMethod.dart';

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

class LoanDetailPage extends StatefulWidget {
  final Map<String, dynamic> loan;

  const LoanDetailPage({super.key, required this.loan});

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  final Logger _logger = Logger();
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
  final formatDate = DateFormat('dd MMM yyyy');

  List<dynamic> _repaymentSchedule = [];
  Map<String, dynamic>? _scheduleSummary;

  // ============ State for caching and real-time updates ============
  /// IMPORTANT: All data is fetched from the BACKEND API.
  /// Firestore is used ONLY for change notifications, NOT for data.
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  bool _isRefreshing = false;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  String? get _applicationId => widget.loan['applicationId']?.toString();

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupFirestoreListener();
    _recordLoanIncomeIfDisbursed();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  /// Fire-and-forget: record disbursed loan as TAJIRI income (deduplicated by referenceId).
  Future<void> _recordLoanIncomeIfDisbursed() async {
    try {
      final status = widget.loan['status']?.toString().toLowerCase() ?? '';
      if (status != 'active' && status != 'disbursed') return;

      final loanId = widget.loan['applicationId']?.toString();
      if (loanId == null) return;

      final principal = double.tryParse(widget.loan['principalAmount']?.toString() ?? '0') ?? 0.0;
      if (principal <= 0) return;

      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      IncomeService.recordIncome(
        token: token,
        amount: principal,
        source: 'kikoba_loan',
        description: 'Mkopo: ${DataStore.currentKikobaName.isNotEmpty ? DataStore.currentKikobaName : "Kikoba"}',
        referenceId: 'kikoba_loan_$loanId',
        sourceModule: 'kikoba',
      ).catchError((_) => null);
    } catch (_) {}
  }

  /// Load data: first from cache for instant display, then from backend API
  Future<void> _loadData() async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;
    final applicationId = _applicationId;

    if (kikobaId.isEmpty || visitorId.isEmpty || applicationId == null) {
      _logger.e('[LoanDetailPage] Cannot load data - missing required IDs');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Step 1: Try to load cached data for instant display
    final cachedData = await PageCacheService.getPageData(
      pageType: 'loan_detail',
      visitorId: visitorId,
      kikobaId: kikobaId,
      subKey: applicationId,
    );
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[LoanDetailPage] Loaded cached data for instant display');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend(showLoadingIfNoCachedData: !_hasCachedData);
  }

  /// Apply cached data
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['repaymentSchedule'] != null) {
      _repaymentSchedule = List<dynamic>.from(data['repaymentSchedule']);
    }
    if (data['scheduleSummary'] != null) {
      _scheduleSummary = Map<String, dynamic>.from(data['scheduleSummary']);
    }
  }

  /// Fetch fresh data from backend API and cache it
  /// IMPORTANT: All data comes from the backend, NOT from Firestore!
  Future<void> _fetchDataFromBackend({bool showLoadingIfNoCachedData = false, bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;
    final applicationId = _applicationId;

    if (kikobaId.isEmpty || visitorId.isEmpty || applicationId == null) return;

    if (showLoadingIfNoCachedData && mounted) {
      setState(() => _isInitialLoading = true);
    }

    try {
      _logger.d('[LoanDetailPage] Fetching repayment schedule from backend...');

      final response = await HttpService.getLoanRepaymentSchedule(applicationId);

      if (mounted) {
        if (response != null && response['status'] == 'success') {
          final data = response['data'];
          setState(() {
            _repaymentSchedule = data['schedules'] as List<dynamic>? ?? [];
            _scheduleSummary = data['summary'] as Map<String, dynamic>?;
            _isInitialLoading = false;
            _hasCachedData = true;
          });

          // Cache the data for next time
          await PageCacheService.savePageData(
            pageType: 'loan_detail',
            visitorId: visitorId,
            kikobaId: kikobaId,
            subKey: applicationId,
            data: {
              'repaymentSchedule': _repaymentSchedule,
              'scheduleSummary': _scheduleSummary,
              'fetchedAt': DateTime.now().toIso8601String(),
            },
          );
          _logger.d('[LoanDetailPage] Fetched and cached repayment schedule');
        } else {
          setState(() => _isInitialLoading = false);
        }
      }
    } catch (e) {
      _logger.e('[LoanDetailPage] Error fetching data from backend: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        if (!_hasCachedData) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imeshindwa kupata data. Jaribu tena.')),
          );
        }
      }
    }
  }

  /// Set up Firestore listener for CHANGE NOTIFICATIONS ONLY
  /// IMPORTANT: Firestore is NOT used for data fetching!
  void _setupFirestoreListener() {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId.isEmpty) return;

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
        _logger.d('[LoanDetailPage] Firestore notification: version changed');
        _lastKnownVersion = effectiveVersion;
        await _fetchDataFromBackend(forceRefresh: true);
      }
    }, onError: (e) {
      _logger.e('[LoanDetailPage] Firestore listener error: $e');
    });
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
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

  Future<void> _payInstallment(Map<String, dynamic> installment) async {
    final amount = installment['amount'] ?? installment['totalAmount'] ?? installment['installmentAmount'];
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot determine installment amount')),
      );
      return;
    }

    final loanId = widget.loan['applicationId']?.toString() ?? widget.loan['id']?.toString() ?? '';
    DataStore.paymentService = "rejesho";
    DataStore.paymentAmount = amount;
    DataStore.paidServiceId = loanId;
    DataStore.personPaidId = DataStore.currentUserId ?? '';
    DataStore.maelezoYaMalipo =
        "${DataStore.currentUserName} amelipa awamu ya ${installment['installmentNumber']} ya mkopo, "
        "kiasi cha TZS ${amount.toString()}";

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const selectPaymentMethode()),
      );
    }
  }

  Future<void> _liquidateLoan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Funga Mkopo'),
        content: const Text('Je, una uhakika unataka kulipia mkopo wote sasa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _iconBg,
            ),
            child: const Text('Ndiyo, Lipia'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final calculations = widget.loan['calculations'] as Map<String, dynamic>?;
      final outstandingBalance = calculations?['outstandingBalance'] ?? calculations?['totalRemaining'] ?? 0;
      final loanId = widget.loan['applicationId']?.toString() ?? widget.loan['id']?.toString() ?? '';

      DataStore.paymentService = "closeloan";
      DataStore.paymentAmount = outstandingBalance;
      DataStore.paidServiceId = loanId;
      DataStore.personPaidId = DataStore.currentUserId ?? '';
      DataStore.maelezoYaMalipo =
          "${DataStore.currentUserName} amefunga mkopo, kiasi cha TZS ${outstandingBalance.toString()}";

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const selectPaymentMethode()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanProduct = widget.loan['loanProduct'] as Map<String, dynamic>?;
    final productName = loanProduct?['productName']?.toString() ?? 'Mkopo';
    final applicationId = widget.loan['applicationId']?.toString() ?? 'N/A';
    final status = widget.loan['status']?.toString() ?? '';
    final isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'disbursed';

    final calculations = widget.loan['calculations'] as Map<String, dynamic>?;
    final principal = double.tryParse(widget.loan['principalAmount']?.toString() ?? '0') ?? 0.0;
    final totalRepayment = double.tryParse(calculations?['totalRepayment']?.toString() ?? '0') ?? 0.0;
    final monthlyInstallment = double.tryParse(calculations?['monthlyInstallment']?.toString() ?? '0') ?? 0.0;
    final outstanding = double.tryParse(widget.loan['outstandingBalance']?.toString() ?? totalRepayment.toString()) ?? 0.0;

    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _iconBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          productName,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
            // Loan Summary Card
            Container(
              margin: const EdgeInsets.all(16),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Namba: $applicationId',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _secondaryText,
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem('Mkopo', formatCurrency.format(principal)),
                      ),
                      Expanded(
                        child: _buildSummaryItem('Jumla ya Kulipa', formatCurrency.format(totalRepayment)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem('Awamu ya Mwezi', formatCurrency.format(monthlyInstallment)),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Deni Lililobaki',
                          formatCurrency.format(outstanding),
                          valueColor: outstanding > 0 ? _errorColor : _successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Liquidate/Close Loan Button
            if (isActive && outstanding > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _liquidateLoan,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Lipia na Funga Mkopo Sasa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _iconBg,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Schedule Summary
            if (_scheduleSummary != null) ...[
              const SizedBox(height: 16),
              _buildScheduleSummary(_scheduleSummary!),
            ],

            // View Full Schedule Button (navigates to PaymentScheduleScreen)
            if (_applicationId != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScheduleScreen(
                          applicationId: _applicationId!,
                          loanTitle: '$productName ($applicationId)',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_view_month, size: 18),
                  label: const Text('Angalia Ratiba Kamili'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _iconBg,
                    side: const BorderSide(color: _iconBg),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Loan Status Timeline (shows progress for pending loans)
            if (!isActive && _buildLoanStatusTimeline(status) != null) ...[
              const SizedBox(height: 24),
              _buildLoanStatusTimeline(status)!,
            ],

            // Guarantor Progress Card (for guarantor_pending status)
            if (_buildGuarantorProgressCard(status) != null) ...[
              const SizedBox(height: 16),
              _buildGuarantorProgressCard(status)!,
            ],

            // Voting Progress Widget (for pending_approval status)
            if (_buildVotingProgressWidget(status) != null) ...[
              const SizedBox(height: 16),
              _buildVotingProgressWidget(status)!,
            ],

            // Rejection Details Card (for rejected loans)
            if (_buildRejectionDetailsCard(status) != null) ...[
              const SizedBox(height: 16),
              _buildRejectionDetailsCard(status)!,
            ],

            // Cancel Application Button (for pending loans)
            if (_canCancelApplication(status)) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _showCancelDialog,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Ghairi Ombi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _errorColor,
                    side: const BorderSide(color: _errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Repayment Schedule
            if (isActive) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 20, color: _primaryText),
                    const SizedBox(width: 8),
                    const Text(
                      'Ratiba ya Malipo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _isInitialLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _repaymentSchedule.isEmpty
                      ? _buildEmptySchedule()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _repaymentSchedule.length,
                          itemBuilder: (context, index) {
                            final installment = _repaymentSchedule[index];
                            return _buildInstallmentCard(installment);
                          },
                        ),
            ],
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            color: valueColor ?? _primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
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
    );
  }

  Widget _buildScheduleSummary(Map<String, dynamic> summary) {
    final totalInstallments = summary['totalInstallments']?.toString() ?? '0';
    final paidInstallments = summary['paidInstallments']?.toString() ?? '0';
    final overdueInstallments = summary['overdueInstallments']?.toString() ?? '0';
    final totalRepaid = double.tryParse(summary['totalRepaid']?.toString() ?? '0') ?? 0.0;
    final remainingBalance = double.tryParse(summary['remainingBalance']?.toString() ?? '0') ?? 0.0;
    final totalArrears = double.tryParse(summary['totalArrears']?.toString() ?? '0') ?? 0.0;
    final totalPenalty = double.tryParse(summary['totalPenalty']?.toString() ?? '0') ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muhtasari wa Malipo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryBadge('Jumla', totalInstallments, _primaryText)),
              Expanded(child: _buildSummaryBadge('Imelipwa', paidInstallments, _successColor)),
              Expanded(child: _buildSummaryBadge('Imechelewa', overdueInstallments, _errorColor)),
            ],
          ),
          if (totalRepaid > 0 || totalArrears > 0 || totalPenalty > 0) ...[
            const SizedBox(height: 16),
            Divider(color: _borderColor, height: 1),
            const SizedBox(height: 16),
            if (totalRepaid > 0)
              _buildSummaryRow('Kilicholipwa', formatCurrency.format(totalRepaid), _successColor),
            if (remainingBalance > 0)
              _buildSummaryRow('Kilichobaki', formatCurrency.format(remainingBalance), _primaryText),
            if (totalArrears > 0)
              _buildSummaryRow('Madeni', formatCurrency.format(totalArrears), _errorColor),
            if (totalPenalty > 0)
              _buildSummaryRow('Faini', formatCurrency.format(totalPenalty), _warningColor),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: _secondaryText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: const Center(
        child: Text(
          'Ratiba ya malipo haijapatikana',
          style: TextStyle(
            fontSize: 14,
            color: _secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildInstallmentCard(Map<String, dynamic> installment) {
    final installmentNumber = installment['installmentNumber']?.toString() ?? '0';
    final totalAmount = double.tryParse(installment['totalAmount']?.toString() ?? '0') ?? 0.0;
    final principalAmount = double.tryParse(installment['principalAmount']?.toString() ?? '0') ?? 0.0;
    final interestAmount = double.tryParse(installment['interestAmount']?.toString() ?? '0') ?? 0.0;
    final repaidAmount = double.tryParse(installment['repaidAmount']?.toString() ?? '0') ?? 0.0;
    final amountInArrears = double.tryParse(installment['amountInArrears']?.toString() ?? '0') ?? 0.0;
    final penalty = double.tryParse(installment['penalty']?.toString() ?? '0') ?? 0.0;
    final daysInArrears = int.tryParse(installment['daysInArrears']?.toString() ?? '0') ?? 0;
    final outstandingBalance = double.tryParse(installment['outstandingBalance']?.toString() ?? '0') ?? 0.0;

    final dueDate = installment['dueDate']?.toString();
    final paidDate = installment['paidDate']?.toString();
    final status = installment['status']?.toString()?.toLowerCase() ?? 'pending';
    final isPaid = status == 'paid' || paidDate != null;
    final isOverdue = status == 'overdue' || daysInArrears > 0;
    final isPartial = status == 'partial';

    Color statusColor = _warningColor;
    if (isPaid) statusColor = _successColor;
    else if (isOverdue) statusColor = _errorColor;
    else if (isPartial) statusColor = _warningColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPaid ? _successColor.withOpacity(0.3) : isOverdue ? _errorColor.withOpacity(0.3) : _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle : isOverdue ? Icons.warning : Icons.schedule,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Awamu #$installmentNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPaid ? 'Imelipwa: ${_formatDateString(paidDate)}' : 'Tarehe: ${_formatDateString(dueDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency.format(totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isPaid ? 'Imelipwa' : isOverdue ? 'Imechelewa' : isPartial ? 'Nusu' : 'Haijalipwa',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Breakdown: Principal + Interest
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mtaji:', style: TextStyle(fontSize: 12, color: _secondaryText)),
                    Text(formatCurrency.format(principalAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryText)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Riba:', style: TextStyle(fontSize: 12, color: _secondaryText)),
                    Text(formatCurrency.format(interestAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryText)),
                  ],
                ),
                if (repaidAmount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kilicholipwa:', style: TextStyle(fontSize: 12, color: _secondaryText)),
                      Text(formatCurrency.format(repaidAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _successColor)),
                    ],
                  ),
                ],
                if (amountInArrears > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Deni (${daysInArrears}d):', style: const TextStyle(fontSize: 12, color: _errorColor)),
                      Text(formatCurrency.format(amountInArrears), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _errorColor)),
                    ],
                  ),
                ],
                if (penalty > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Faini:', style: TextStyle(fontSize: 12, color: _warningColor)),
                      Text(formatCurrency.format(penalty), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _warningColor)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Outstanding Balance
          if (outstandingBalance >= 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Salio baada ya awamu: ', style: TextStyle(fontSize: 11, color: _secondaryText)),
                Text(formatCurrency.format(outstandingBalance), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primaryText)),
              ],
            ),
          ],

          // Pay Button
          if (!isPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _payInstallment(installment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _iconBg,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isOverdue || amountInArrears > 0 ? 'Lipa Sasa (+ Faini)' : 'Lipa Awamu Hii Sasa'),
              ),
            ),
          ],
        ],
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

  /// Check if application can be cancelled
  bool _canCancelApplication(String status) {
    final loanStatus = LoanStatus.fromString(status);
    return loanStatus == LoanStatus.draft ||
           loanStatus == LoanStatus.guarantorPending ||
           loanStatus == LoanStatus.pendingApproval;
  }

  /// Show cancel application dialog
  Future<void> _showCancelDialog() async {
    // Create a LoanApplication from the loan data
    final application = LoanApplication.fromJson(widget.loan);

    final cancelled = await CancelApplicationDialog.show(
      context: context,
      application: application,
      onConfirm: (String? reason) async {
        await LoanService.cancelApplication(
          _applicationId!,
          reason: reason,
        );
      },
    );

    if (cancelled == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ombi limeghairiwa'),
          backgroundColor: _successColor,
        ),
      );
      Navigator.pop(context); // Go back to loan list
    }
  }

  /// Build guarantor progress card for guarantor_pending status
  Widget? _buildGuarantorProgressCard(String status) {
    final loanStatus = LoanStatus.fromString(status);
    if (loanStatus != LoanStatus.guarantorPending) return null;

    final guarantors = widget.loan['guarantors'] as List<dynamic>? ?? [];
    if (guarantors.isEmpty) return null;

    // Convert to Guarantor models
    final guarantorModels = guarantors.map((g) {
      return Guarantor.fromJson(g as Map<String, dynamic>);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GuarantorProgressCard(
        guarantors: guarantorModels,
        showAmount: true,
      ),
    );
  }

  /// Build voting progress widget for pending_approval status
  Widget? _buildVotingProgressWidget(String status) {
    final loanStatus = LoanStatus.fromString(status);
    if (loanStatus != LoanStatus.pendingApproval) return null;

    final votingData = widget.loan['votingSession'] as Map<String, dynamic>?;
    if (votingData == null) return null;

    // Create LoanVotingSummary from voting data
    final votingSummary = LoanVotingSummary.fromJson(votingData);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: VotingProgressWidget(
        voting: votingSummary,
        compact: false,
      ),
    );
  }

  /// Build rejection details card for rejected loans
  Widget? _buildRejectionDetailsCard(String status) {
    final loanStatus = LoanStatus.fromString(status);
    if (loanStatus != LoanStatus.rejected &&
        loanStatus != LoanStatus.guarantorRejected &&
        loanStatus != LoanStatus.cancelled &&
        loanStatus != LoanStatus.failed) {
      return null;
    }

    // Create LoanApplication from loan data for the rejection card
    final application = LoanApplication.fromJson(widget.loan);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RejectionDetailsCard(
        application: application,
        showRemediationSteps: true,
        onReapply: () {
          Navigator.pop(context);
          // Navigate to new application
          Navigator.pushNamed(context, '/mikopo');
        },
      ),
    );
  }

  /// Build loan status timeline for pending loans
  Widget? _buildLoanStatusTimeline(String status) {
    final loanStatus = LoanStatus.fromString(status);

    // Only show timeline for non-active statuses
    if (loanStatus == LoanStatus.active ||
        loanStatus == LoanStatus.closed ||
        loanStatus == LoanStatus.cancelled) {
      return null;
    }

    // Create a LoanApplication from the loan data for the timeline
    final loanApplication = LoanApplication.fromJson(widget.loan);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LoanStatusTimeline(
        application: loanApplication,
        showDetails: true,
      ),
    );
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
}
