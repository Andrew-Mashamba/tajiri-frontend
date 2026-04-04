import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'DataStore.dart';
import 'HttpService.dart';
import 'services/mahesabu_cache_service.dart';

final Logger _mahesabuLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    printTime: true,
  ),
);

class mahesabu extends StatefulWidget {
  const mahesabu({super.key});

  @override
  State<mahesabu> createState() => _MahesabuState();
}

class _MahesabuState extends State<mahesabu> with AutomaticKeepAliveClientMixin<mahesabu> {
  @override
  bool get wantKeepAlive => true;

  // Date range for reports
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();

  // Track which report is currently loading
  String? _loadingReport;

  // Format for displaying dates
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  // Number formatter for currency
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'en_US');

  // Loading and caching state
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  Map<String, dynamic>? _summaryData;

  // Firestore listener for real-time notifications
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  @override
  void initState() {
    super.initState();

    // Fetch summary data when page opens
    _fetchSummaryData();

    // Set up Firestore listener for real-time updates
    _setupFirestoreListener();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  /// Check if device has internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      _mahesabuLogger.e('[MAHESABU] Connectivity check error: $e');
      return true; // Assume connected on error
    }
  }

  /// Fetch summary data directly from BACKEND API
  ///
  /// Data flow:
  /// 1. Show cached data immediately (if available) for instant display
  /// 2. Fetch fresh data from backend API (HttpService)
  /// 3. Cache the fresh data locally for next time
  ///
  /// NOTE: All data comes from backend, NOT from Firestore
  Future<void> _fetchSummaryData({bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId ?? '';
    _mahesabuLogger.i('[MAHESABU] Fetching from BACKEND API (forceRefresh: $forceRefresh)...');

    // 1. Try to show cached data immediately (instant display)
    if (!forceRefresh && !_hasCachedData) {
      final cached = await MahesabuCacheService.getSummary(kikobaId);
      if (cached != null) {
        _mahesabuLogger.i('[MAHESABU] Showing cached summary instantly');
        _lastKnownVersion = await MahesabuCacheService.getVersion(kikobaId);
        if (mounted) {
          setState(() {
            _summaryData = cached;
            _hasCachedData = true;
            _isInitialLoading = false;
          });
        }
      }
    }

    // 2. Check connectivity before fetching
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _mahesabuLogger.w('[MAHESABU] No internet connection');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        if (_hasCachedData) {
          _showConnectivitySnackbar();
        }
      }
      return;
    }

    // 3. Fetch fresh summary data from backend
    try {
      final data = await HttpService.getFullStatementReport(
        kikobaId: kikobaId,
        startDate: _apiDateFormat.format(_startDate),
        endDate: _apiDateFormat.format(_endDate),
      );

      if (data != null && mounted) {
        _mahesabuLogger.i('[MAHESABU] Summary fetch: SUCCESS');

        // Cache the fresh data
        await MahesabuCacheService.saveSummary(kikobaId, data);

        setState(() {
          _summaryData = data;
          _hasCachedData = true;
        });
      } else {
        _mahesabuLogger.w('[MAHESABU] Summary fetch returned null');
      }
    } catch (e) {
      _mahesabuLogger.e('[MAHESABU] Error fetching summary: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  void _showConnectivitySnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hakuna mtandao. Unaona data iliyohifadhiwa.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Set up Firestore listener for CHANGE NOTIFICATIONS ONLY
  ///
  /// IMPORTANT: Firestore is NOT used for data fetching!
  /// - Firestore only notifies when data has changed (via version/updatedAt)
  /// - When notified, we fetch fresh data from BACKEND API (HttpService)
  /// - This keeps data source consistent (backend is source of truth)
  void _setupFirestoreListener() {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null || kikobaId.isEmpty) {
      _mahesabuLogger.w('[MAHESABU] No kikoba ID, skipping Firestore listener');
      return;
    }

    _mahesabuLogger.i('[MAHESABU] Setting up Firestore listener for kikoba: $kikobaId');

    // Listen ONLY for version/timestamp changes - NOT for actual data
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('FinancialUpdates')
        .doc(kikobaId)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!snapshot.exists || _isInitialLoading) return;

        // Only read version info from Firestore (not actual data)
        final notificationData = snapshot.data();
        final newVersion = notificationData?['version'] as int?;
        final updatedAt = notificationData?['updatedAt'];

        // Use version if available, otherwise use updatedAt timestamp hash
        final effectiveVersion = newVersion ?? updatedAt?.hashCode;

        // Only refresh if version actually changed
        if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
          _mahesabuLogger.i('[MAHESABU] Change notification received: version $_lastKnownVersion -> $effectiveVersion');
          _lastKnownVersion = effectiveVersion;

          // Save version for future comparison
          await MahesabuCacheService.saveVersion(kikobaId, effectiveVersion);

          // Clear local caches since data changed
          await MahesabuCacheService.clearReportCaches(kikobaId);

          // Fetch fresh data from BACKEND API (not Firestore!)
          _fetchSummaryData(forceRefresh: true);
        } else {
          _mahesabuLogger.d('[MAHESABU] Version unchanged, skipping refresh');
        }
      },
      onError: (error) {
        _mahesabuLogger.e('[MAHESABU] Firestore listener error: $error');
      },
    );
  }

  /// Refresh data - called by pull-to-refresh
  Future<void> _refreshData() async {
    _mahesabuLogger.i('[REFRESH] Pull-to-refresh triggered');

    // Check connectivity first
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _mahesabuLogger.w('[REFRESH] No internet connection');
      _showConnectivitySnackbar();
      return;
    }

    // Clear caches and fetch fresh data
    final kikobaId = DataStore.currentKikobaId ?? '';
    await MahesabuCacheService.clearReportCaches(kikobaId);
    await _fetchSummaryData(forceRefresh: true);

    _mahesabuLogger.i('[REFRESH] Complete');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Date Range Picker
            _buildDateRangePicker(),
            // Reports List
            Expanded(
              child: _isInitialLoading && !_hasCachedData
                  ? _buildLoadingState()
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: const Color(0xFF1A1A1A),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Card (if available)
                            if (_summaryData != null) ...[
                              const SizedBox(height: 16),
                              _buildQuickSummaryCard(),
                            ],
                            const SizedBox(height: 16),
                            // Activity Reports Section
                            _buildSectionHeader('Ripoti za Shughuli'),
                            const SizedBox(height: 12),
                            _buildActivityReports(),
                            const SizedBox(height: 24),
                            // Financial Statements Section
                            _buildSectionHeader('Taarifa za Fedha'),
                            const SizedBox(height: 12),
                            _buildFinancialStatements(),
                            const SizedBox(height: 24),
                            // Comprehensive Reports Section
                            _buildSectionHeader('Taarifa Kamili'),
                            const SizedBox(height: 12),
                            _buildComprehensiveReports(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build skeleton loading state
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Quick summary skeleton
          _buildSkeletonCard(height: 100),
          const SizedBox(height: 24),
          // Section header skeleton
          _buildSkeletonBox(width: 120, height: 18),
          const SizedBox(height: 12),
          // Activity reports skeleton
          Row(
            children: [
              Expanded(child: _buildSkeletonCard(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard(height: 80)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSkeletonCard(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard(height: 80)),
            ],
          ),
          const SizedBox(height: 24),
          // Section header skeleton
          _buildSkeletonBox(width: 140, height: 18),
          const SizedBox(height: 12),
          _buildSkeletonCard(height: 70),
          const SizedBox(height: 8),
          _buildSkeletonCard(height: 70),
          const SizedBox(height: 8),
          _buildSkeletonCard(height: 70),
          const SizedBox(height: 24),
          // Section header skeleton
          _buildSkeletonBox(width: 110, height: 18),
          const SizedBox(height: 12),
          _buildSkeletonCard(height: 70),
          const SizedBox(height: 8),
          _buildSkeletonCard(height: 70),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({double height = 80}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(value),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(value),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  /// Quick summary card showing key financial metrics
  Widget _buildQuickSummaryCard() {
    final summary = _summaryData?['executive_summary'] ?? {};
    final totalIncome = summary['total_income'] ?? 0;
    final totalExpenses = summary['total_expenses'] ?? 0;
    final netIncome = summary['net_income'] ?? 0;
    final memberCount = summary['member_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Muhtasari wa Haraka',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_isInitialLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickStat('Mapato', totalIncome, const Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat('Matumizi', totalExpenses, const Color(0xFFE53935)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(
                  'Faida',
                  netIncome,
                  netIncome >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Wanachama: $memberCount',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, num value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ripoti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Taarifa za kifedha na shughuli',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              label: 'Kuanzia',
              date: _startDate,
              onTap: () => _selectDate(isStart: true),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF999999),
              size: 18,
            ),
          ),
          Expanded(
            child: _buildDateButton(
              label: 'Hadi',
              date: _endDate,
              onTap: () => _selectDate(isStart: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _dateFormat.format(date),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1A1A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildActivityReports() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildReportCard(
              icon: Icons.card_membership_rounded,
              title: 'Ada',
              subtitle: 'Michango ya uanachama',
              onTap: () => _showAdaReport(),
              reportId: 'ada',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildReportCard(
              icon: Icons.pie_chart_rounded,
              title: 'Hisa',
              subtitle: 'Mchango wa hisa',
              onTap: () => _showHisaReport(),
              reportId: 'hisa',
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildReportCard(
              icon: Icons.savings_rounded,
              title: 'Akiba',
              subtitle: 'Akiba za wanachama',
              onTap: () => _showAkibaReport(),
              reportId: 'akiba',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildReportCard(
              icon: Icons.volunteer_activism_rounded,
              title: 'Mchango',
              subtitle: 'Michango maalum',
              onTap: () => _showMchangoReport(),
              reportId: 'mchango',
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildReportCard(
              icon: Icons.payments_rounded,
              title: 'Matumizi',
              subtitle: 'Gharama zilizolipwa',
              onTap: () => _showExpensesReport(),
              reportId: 'expenses',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildReportCard(
              icon: Icons.account_balance_rounded,
              title: 'Mikopo',
              subtitle: 'Mikopo iliyotolewa',
              onTap: () => _showLoansReport(),
              reportId: 'loans',
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialStatements() {
    return Column(
      children: [
        _buildReportCard(
          icon: Icons.balance_rounded,
          title: 'Mizani ya Majaribio',
          subtitle: 'Trial Balance - Muhtasari wa akaunti zote',
          onTap: () => _showTrialBalanceReport(),
          reportId: 'trial-balance',
          isWide: true,
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          icon: Icons.trending_up_rounded,
          title: 'Taarifa ya Mapato',
          subtitle: 'Income Statement - Mapato na matumizi',
          onTap: () => _showIncomeStatementReport(),
          reportId: 'income-statement',
          isWide: true,
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Mizania',
          subtitle: 'Balance Sheet - Mali, madeni na mtaji',
          onTap: () => _showBalanceSheetReport(),
          reportId: 'balance-sheet',
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildComprehensiveReports() {
    return Column(
      children: [
        _buildReportCard(
          icon: Icons.menu_book_rounded,
          title: 'Leja Kuu',
          subtitle: 'General Ledger - Historia ya akaunti moja',
          onTap: () => _showGeneralLedgerSelector(),
          reportId: 'general-ledger',
          isWide: true,
        ),
        const SizedBox(height: 12),
        _buildReportCard(
          icon: Icons.summarize_rounded,
          title: 'Taarifa Kamili',
          subtitle: 'Full Statement - Ripoti yote kwa pamoja',
          onTap: () => _showFullStatementReport(),
          reportId: 'full-statement',
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required String reportId,
    bool isWide = false,
  }) {
    final isLoading = _loadingReport == reportId;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isWide ? 14 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isWide ? 40 : 36,
                height: isWide ? 40 : 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        icon,
                        color: Colors.white,
                        size: isWide ? 20 : 18,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isWide ? 14 : 13,
                        fontWeight: FontWeight.w600,
                        color: isLoading ? const Color(0xFF999999) : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading ? 'Inapakia...' : subtitle,
                      style: TextStyle(
                        fontSize: isWide ? 11 : 10,
                        color: const Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isLoading)
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF999999),
                  size: isWide ? 22 : 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Error snackbar helper
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
    );
  }

  // ==================== REPORT METHODS ====================

  /// Generic method to fetch report from BACKEND API with caching
  ///
  /// Data flow:
  /// 1. Check local cache first (for instant display)
  /// 2. If no cache, fetch from BACKEND API via HttpService
  /// 3. Cache the result locally
  ///
  /// NOTE: fetchFunction should call HttpService methods (backend API)
  Future<Map<String, dynamic>?> _fetchReportWithCache({
    required String reportType,
    required Future<Map<String, dynamic>?> Function() fetchFunction,
  }) async {
    final kikobaId = DataStore.currentKikobaId ?? '';
    final startDate = _apiDateFormat.format(_startDate);
    final endDate = _apiDateFormat.format(_endDate);

    // 1. Try to get from cache first
    final cached = await MahesabuCacheService.getReport(
      kikobaId: kikobaId,
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
    if (cached != null) {
      _mahesabuLogger.d('[REPORT] Using cached $reportType report');
      return cached;
    }

    // 2. Check connectivity
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _mahesabuLogger.w('[REPORT] No internet for $reportType report');
      _showConnectivitySnackbar();
      return null;
    }

    // 3. Fetch from BACKEND API (via HttpService)
    try {
      _mahesabuLogger.d('[REPORT] Fetching $reportType from BACKEND API...');
      final data = await fetchFunction();
      if (data != null) {
        // Cache the result locally
        await MahesabuCacheService.saveReport(
          kikobaId: kikobaId,
          reportType: reportType,
          startDate: startDate,
          endDate: endDate,
          data: data,
        );
        _mahesabuLogger.d('[REPORT] Fetched from backend and cached: $reportType');
      }
      return data;
    } catch (e) {
      _mahesabuLogger.e('[REPORT] Error fetching $reportType from backend: $e');
      return null;
    }
  }

  Future<void> _showAdaReport() async {
    setState(() => _loadingReport = 'ada');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'ada',
        fetchFunction: () => HttpService.getAdaReport(
          kikobaId: DataStore.currentKikobaId,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata ripoti ya Ada');
        return;
      }

      _showAdaReportSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showAdaReportSheet(Map<String, dynamic> data) {
    final summary = data['summary'] ?? {};
    final transactions = data['transactions'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Ripoti ya Ada', Icons.card_membership_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard([
                        _buildSummaryItem('Jumla Ada', summary['total_amount'] ?? 0),
                        _buildSummaryItem('Faini', summary['total_penalties'] ?? 0),
                        _buildSummaryItem('Jumla Yote', summary['total_collected'] ?? 0),
                        _buildSummaryItem('Malipo', summary['payment_count'] ?? 0, isCurrency: false),
                        _buildSummaryItem('Wanachama', summary['member_count'] ?? 0, isCurrency: false),
                      ]),
                      const SizedBox(height: 20),
                      _buildTransactionsList('Malipo ya Ada', transactions, (tx) => [
                        tx['member_name'] ?? 'N/A',
                        tx['date'] ?? '',
                        tx['total'] ?? 0,
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHisaReport() async {
    setState(() => _loadingReport = 'hisa');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'hisa',
        fetchFunction: () => HttpService.getHisaReport(
          kikobaId: DataStore.currentKikobaId,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata ripoti ya Hisa');
        return;
      }

      _showHisaReportSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showHisaReportSheet(Map<String, dynamic> data) {
    final summary = data['summary'] ?? {};
    final memberBalances = data['member_balances'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Ripoti ya Hisa', Icons.pie_chart_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard([
                        _buildSummaryItem('Michango', summary['total_contributions'] ?? 0),
                        _buildSummaryItem('Faini', summary['total_penalties'] ?? 0),
                        _buildSummaryItem('Jumla', summary['total_collected'] ?? 0),
                        _buildSummaryItem('Thamani ya Hisa', summary['total_shares_value'] ?? 0),
                      ]),
                      const SizedBox(height: 20),
                      _buildMemberBalancesList('Hisa za Wanachama', memberBalances),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAkibaReport() async {
    setState(() => _loadingReport = 'akiba');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'akiba',
        fetchFunction: () => HttpService.getAkibaReport(
          kikobaId: DataStore.currentKikobaId,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata ripoti ya Akiba');
        return;
      }

      _showAkibaReportSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showAkibaReportSheet(Map<String, dynamic> data) {
    final summary = data['summary'] ?? {};
    final memberBalances = data['member_balances'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Ripoti ya Akiba', Icons.savings_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard([
                        _buildSummaryItem('Amana', summary['total_deposits'] ?? 0),
                        _buildSummaryItem('Kutoa', summary['total_withdrawals'] ?? 0),
                        _buildSummaryItem('Tofauti', summary['net_change'] ?? 0),
                        _buildSummaryItem('Salio la Mwanzo', summary['opening_balance'] ?? 0),
                        _buildSummaryItem('Salio la Mwisho', summary['closing_balance'] ?? 0),
                      ]),
                      const SizedBox(height: 20),
                      _buildAkibaMembersList('Akiba za Wanachama', memberBalances),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMchangoReport() async {
    setState(() => _loadingReport = 'mchango');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'mchango',
        fetchFunction: () => HttpService.getMchangoSummaryReport(
          kikobaId: DataStore.currentKikobaId,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata ripoti ya Mchango');
        return;
      }

      _showMchangoReportSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showMchangoReportSheet(Map<String, dynamic> data) {
    final summary = data['summary'] ?? {};
    final requests = data['requests'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Ripoti ya Mchango', Icons.volunteer_activism_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard([
                        _buildSummaryItem('Maombi', summary['total_requests'] ?? 0, isCurrency: false),
                        _buildSummaryItem('Imekusanywa', summary['total_collected'] ?? 0),
                        _buildSummaryItem('Imetolewa', summary['total_disbursed'] ?? 0),
                        _buildSummaryItem('Inangojea', summary['pending_disbursement'] ?? 0),
                      ]),
                      const SizedBox(height: 20),
                      _buildMchangoRequestsList('Maombi ya Mchango', requests),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExpensesReport() async {
    setState(() => _loadingReport = 'expenses');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'expenses',
        fetchFunction: () => HttpService.getExpensesReport(
          kikobaId: DataStore.currentKikobaId,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata ripoti ya Matumizi');
        return;
      }

      _showExpensesReportSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showExpensesReportSheet(Map<String, dynamic> data) {
    final summary = data['summary'] ?? {};
    final byCategory = data['by_category'] as List<dynamic>? ?? [];
    final transactions = data['transactions'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Ripoti ya Matumizi', Icons.payments_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard([
                        _buildSummaryItem('Jumla Matumizi', summary['total_expenses'] ?? 0),
                        _buildSummaryItem('Idadi', summary['expense_count'] ?? 0, isCurrency: false),
                        _buildSummaryItem('Makundi', summary['category_count'] ?? 0, isCurrency: false),
                      ]),
                      const SizedBox(height: 20),
                      _buildCategoryBreakdown('Kwa Kundi', byCategory),
                      const SizedBox(height: 20),
                      _buildExpenseTransactionsList('Matumizi', transactions),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLoansReport() async {
    setState(() => _loadingReport = 'loans');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'loans',
        fetchFunction: () => HttpService.getLoansReport(
          kikobaId: DataStore.currentKikobaId,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata ripoti ya Mikopo');
        return;
      }

      _showLoansReportSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showLoansReportSheet(Map<String, dynamic> data) {
    final summary = data['summary'] ?? {};
    final portfolio = data['portfolio'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Ripoti ya Mikopo', Icons.account_balance_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard([
                        _buildSummaryItem('Imetolewa', summary['total_disbursed'] ?? 0),
                        _buildSummaryItem('Imelipwa', summary['total_repaid'] ?? 0),
                        _buildSummaryItem('Deni Lililobaki', summary['total_outstanding'] ?? 0),
                        _buildSummaryItem('Mikopo Hai', summary['active_loans'] ?? 0, isCurrency: false),
                        _buildSummaryItem('Imekamilika', summary['completed_loans'] ?? 0, isCurrency: false),
                      ]),
                      const SizedBox(height: 20),
                      _buildLoanPortfolioList('Mikopo', portfolio),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTrialBalanceReport() async {
    setState(() => _loadingReport = 'trial-balance');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'trial-balance',
        fetchFunction: () => HttpService.getTrialBalanceReport(
          kikobaId: DataStore.currentKikobaId,
          asOfDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata Mizani ya Majaribio');
        return;
      }

      _showTrialBalanceSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showTrialBalanceSheet(Map<String, dynamic> data) {
    final accounts = data['accounts'] as List<dynamic>? ?? [];
    final totalDebit = data['total_debit'] ?? 0;
    final totalCredit = data['total_credit'] ?? 0;
    final isBalanced = data['is_balanced'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Mizani ya Majaribio', Icons.balance_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrialBalanceSummary(totalDebit, totalCredit, isBalanced),
                      const SizedBox(height: 20),
                      _buildTrialBalanceAccounts(accounts),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showIncomeStatementReport() async {
    setState(() => _loadingReport = 'income-statement');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'income-statement',
        fetchFunction: () => HttpService.getIncomeStatementReport(
          kikobaId: DataStore.currentKikobaId,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata Taarifa ya Mapato');
        return;
      }

      _showIncomeStatementSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showIncomeStatementSheet(Map<String, dynamic> data) {
    final revenue = data['revenue'] ?? {};
    final expenses = data['expenses'] ?? {};
    final netIncome = data['net_income'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Taarifa ya Mapato', Icons.trending_up_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIncomeStatementSection('Mapato', revenue, true),
                      const SizedBox(height: 16),
                      _buildIncomeStatementSection('Matumizi', expenses, false),
                      const SizedBox(height: 16),
                      _buildNetIncomeCard(netIncome),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBalanceSheetReport() async {
    setState(() => _loadingReport = 'balance-sheet');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'balance-sheet',
        fetchFunction: () => HttpService.getBalanceSheetReport(
          kikobaId: DataStore.currentKikobaId,
          asOfDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata Mizania');
        return;
      }

      _showBalanceSheetSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showBalanceSheetSheet(Map<String, dynamic> data) {
    final assets = data['assets'] ?? {};
    final liabilities = data['liabilities'] ?? {};
    final equity = data['equity'] ?? {};
    final isBalanced = data['is_balanced'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Mizania', Icons.account_balance_wallet_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceSheetSection('Mali', assets, Icons.trending_up_rounded),
                      const SizedBox(height: 16),
                      _buildBalanceSheetSection('Madeni', liabilities, Icons.trending_down_rounded),
                      const SizedBox(height: 16),
                      _buildBalanceSheetSection('Mtaji', equity, Icons.account_balance_rounded),
                      const SizedBox(height: 16),
                      _buildBalanceIndicator(isBalanced),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGeneralLedgerSelector() async {
    // First, get the list of accounts from trial balance (use cache)
    setState(() => _loadingReport = 'general-ledger');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'accounts-list',
        fetchFunction: () => HttpService.getTrialBalanceReport(
          kikobaId: DataStore.currentKikobaId,
          asOfDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata orodha ya akaunti');
        return;
      }

      final accounts = data['accounts'] as List<dynamic>? ?? [];
      _showAccountSelectorSheet(accounts);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showAccountSelectorSheet(List<dynamic> accounts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Chagua Akaunti', Icons.menu_book_rounded),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return _buildAccountItem(account);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem(Map<String, dynamic> account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _showGeneralLedgerReport(account['account_code']);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    account['account_code'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    account['account_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF999999), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGeneralLedgerReport(String accountCode) async {
    // Show loading dialog for this since it's triggered from another sheet
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
      ),
    );
    try {
      final data = await _fetchReportWithCache(
        reportType: 'general-ledger-$accountCode',
        fetchFunction: () => HttpService.getGeneralLedgerReport(
          kikobaId: DataStore.currentKikobaId,
          accountCode: accountCode,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);

      if (data == null) {
        _showError('Imeshindikana kupata Leja Kuu');
        return;
      }

      _showGeneralLedgerSheet(data);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError('Kosa: $e');
    }
  }

  void _showGeneralLedgerSheet(Map<String, dynamic> data) {
    final entries = data['entries'] as List<dynamic>? ?? [];
    final openingBalance = data['opening_balance'] ?? 0;
    final closingBalance = data['closing_balance'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader(
                '${data['account_code']} - ${data['account_name']}',
                Icons.menu_book_rounded,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLedgerBalances(openingBalance, closingBalance),
                      const SizedBox(height: 20),
                      _buildLedgerEntries(entries),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFullStatementReport() async {
    setState(() => _loadingReport = 'full-statement');
    try {
      final data = await _fetchReportWithCache(
        reportType: 'full-statement',
        fetchFunction: () => HttpService.getFullStatementReport(
          kikobaId: DataStore.currentKikobaId,
          startDate: _apiDateFormat.format(_startDate),
          endDate: _apiDateFormat.format(_endDate),
        ),
      );
      if (!mounted) return;
      setState(() => _loadingReport = null);

      if (data == null) {
        _showError('Imeshindikana kupata Taarifa Kamili');
        return;
      }

      _showFullStatementSheet(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReport = null);
      _showError('Kosa: $e');
    }
  }

  void _showFullStatementSheet(Map<String, dynamic> data) {
    final summary = data['executive_summary'] ?? {};
    final contributions = data['contributions'] ?? {};
    final loans = data['loans'] ?? {};
    final mchango = data['mchango'] ?? {};
    final expenses = data['expenses'] ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Taarifa Kamili', Icons.summarize_rounded),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExecutiveSummary(summary),
                      const SizedBox(height: 20),
                      _buildContributionsSummary(contributions),
                      const SizedBox(height: 16),
                      _buildLoansSummaryCard(loans),
                      const SizedBox(height: 16),
                      _buildMchangoSummaryCard(mchango),
                      const SizedBox(height: 16),
                      _buildExpensesSummaryCard(expenses),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildSheetHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF666666)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSummaryItem(String label, dynamic value, {bool isCurrency = true}) {
    final displayValue = isCurrency
        ? 'TZS ${_currencyFormat.format(value is num ? value : 0)}'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(String title, List<dynamic> transactions, List<dynamic> Function(Map<String, dynamic>) extractor) {
    if (transactions.isEmpty) {
      return _buildEmptyState('Hakuna malipo');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...transactions.take(20).map((tx) {
          final data = extractor(tx);
          return _buildTransactionItem(data[0], data[1], data[2]);
        }),
      ],
    );
  }

  Widget _buildTransactionItem(String name, String date, dynamic amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'TZS ${_currencyFormat.format(amount is num ? amount : 0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF999999)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberBalancesList(String title, List<dynamic> members) {
    if (members.isEmpty) {
      return _buildEmptyState('Hakuna wanachama');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...members.map((member) {
          final percentage = member['share_percentage'] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['member_name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'TZS ${_currencyFormat.format(member['total_shares'] ?? 0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAkibaMembersList(String title, List<dynamic> members) {
    if (members.isEmpty) {
      return _buildEmptyState('Hakuna akiba');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...members.map((member) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    member['member_name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'TZS ${_currencyFormat.format(member['balance'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '+${_currencyFormat.format(member['deposits'] ?? 0)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '-${_currencyFormat.format(member['withdrawals'] ?? 0)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFE53935)),
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMchangoRequestsList(String title, List<dynamic> requests) {
    if (requests.isEmpty) {
      return _buildEmptyState('Hakuna maombi ya mchango');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...requests.map((req) {
          final progress = (req['progress_percentage'] ?? 0).toDouble();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: req['status'] == 'completed'
                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        req['status'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 10,
                          color: req['status'] == 'completed'
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Na: ${req['requester'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: const Color(0xFFE5E5E5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TZS ${_currencyFormat.format(req['collected'] ?? 0)} / ${_currencyFormat.format(req['target'] ?? 0)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                    ),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryBreakdown(String title, List<dynamic> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...categories.map((cat) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  cat['category_name'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Text(
                'TZS ${_currencyFormat.format(cat['total'] ?? 0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildExpenseTransactionsList(String title, List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyState('Hakuna matumizi');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...transactions.take(20).map((tx) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tx['account'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'TZS ${_currencyFormat.format(tx['amount'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tx['date'] ?? '',
                style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLoanPortfolioList(String title, List<dynamic> loans) {
    if (loans.isEmpty) {
      return _buildEmptyState('Hakuna mikopo');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...loans.map((loan) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loan['member_name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: loan['status'] == 'completed'
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      loan['status'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 10,
                        color: loan['status'] == 'completed'
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mkopo', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
                      Text(
                        'TZS ${_currencyFormat.format(loan['principal'] ?? 0)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Deni', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
                      Text(
                        'TZS ${_currencyFormat.format(loan['outstanding'] ?? 0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTrialBalanceSummary(num totalDebit, num totalCredit, bool isBalanced) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Debit', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${_currencyFormat.format(totalDebit)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: const Color(0xFFE5E5E5),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('Credit', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${_currencyFormat.format(totalCredit)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isBalanced ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isBalanced ? 'Imelingana' : 'Haijalingana',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isBalanced ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBalanceAccounts(List<dynamic> accounts) {
    if (accounts.isEmpty) {
      return _buildEmptyState('Hakuna akaunti');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Akaunti',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...accounts.map((acc) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  acc['account_code'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  acc['account_name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if ((acc['debit'] ?? 0) > 0)
                    Text(
                      'D: ${_currencyFormat.format(acc['debit'])}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A)),
                    ),
                  if ((acc['credit'] ?? 0) > 0)
                    Text(
                      'C: ${_currencyFormat.format(acc['credit'])}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                    ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildIncomeStatementSection(String title, Map<String, dynamic> section, bool isRevenue) {
    final total = section['total'] ?? 0;
    final details = section['details'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'TZS ${_currencyFormat.format(total)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isRevenue ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...details.expand((category) {
              final accounts = category['accounts'] as List<dynamic>? ?? [];
              return accounts.map((acc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        acc['name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'TZS ${_currencyFormat.format(acc['balance'] ?? 0)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ));
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildNetIncomeCard(num netIncome) {
    final isPositive = netIncome >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Faida/Hasara',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            'TZS ${_currencyFormat.format(netIncome.abs())}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSheetSection(String title, Map<String, dynamic> section, IconData icon) {
    final total = section['total'] ?? 0;
    final details = section['details'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                'TZS ${_currencyFormat.format(total)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...details.expand((category) {
              final accounts = category['accounts'] as List<dynamic>? ?? [];
              return accounts.map((acc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        acc['name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'TZS ${_currencyFormat.format(acc['balance'] ?? 0)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ));
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator(bool isBalanced) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBalanced ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFFE53935).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBalanced ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 20,
            color: isBalanced ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
          ),
          const SizedBox(width: 8),
          Text(
            isBalanced ? 'Mizania Imelingana' : 'Mizania Haijalingana',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isBalanced ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerBalances(num opening, num closing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('Salio la Mwanzo', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                const SizedBox(height: 4),
                Text(
                  'TZS ${_currencyFormat.format(opening)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF999999)),
          Expanded(
            child: Column(
              children: [
                const Text('Salio la Mwisho', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                const SizedBox(height: 4),
                Text(
                  'TZS ${_currencyFormat.format(closing)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerEntries(List<dynamic> entries) {
    if (entries.isEmpty) {
      return _buildEmptyState('Hakuna ingizo');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maingizo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((entry) {
          final debit = double.tryParse(entry['debit']?.toString() ?? '0') ?? 0;
          final credit = double.tryParse(entry['credit']?.toString() ?? '0') ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry['description'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry['date'] ?? '',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                    ),
                    Row(
                      children: [
                        if (debit > 0)
                          Text(
                            'D: ${_currencyFormat.format(debit)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A)),
                          ),
                        if (debit > 0 && credit > 0) const SizedBox(width: 8),
                        if (credit > 0)
                          Text(
                            'C: ${_currencyFormat.format(credit)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExecutiveSummary(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muhtasari',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryTile('Mapato', summary['total_income'] ?? 0, Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryTile('Matumizi', summary['total_expenses'] ?? 0, Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  'Faida/Hasara',
                  summary['net_income'] ?? 0,
                  (summary['net_income'] ?? 0) >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryTile('Wanachama', summary['member_count'] ?? 0, Colors.white, isCurrency: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, dynamic value, Color valueColor, {bool isCurrency = true}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCurrency ? 'TZS ${_currencyFormat.format(value)}' : value.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsSummary(Map<String, dynamic> contributions) {
    final ada = contributions['ada'] ?? {};
    final hisa = contributions['hisa'] ?? {};
    final akiba = contributions['akiba'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Michango',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          _buildContributionRow('Ada', ada['total'] ?? 0),
          _buildContributionRow('Hisa', hisa['total'] ?? 0),
          _buildContributionRow('Akiba (Salio)', akiba['balance'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildContributionRow(String label, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          Text(
            'TZS ${_currencyFormat.format(value)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansSummaryCard(Map<String, dynamic> loans) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              const Text(
                'Mikopo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                '${loans['active_count'] ?? 0} hai',
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContributionRow('Imetolewa', loans['disbursed'] ?? 0),
          _buildContributionRow('Imelipwa', loans['repaid'] ?? 0),
          _buildContributionRow('Deni', loans['outstanding'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildMchangoSummaryCard(Map<String, dynamic> mchango) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded, size: 18, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              const Text(
                'Mchango',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                '${mchango['requests_count'] ?? 0} maombi',
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContributionRow('Imekusanywa', mchango['collected'] ?? 0),
          _buildContributionRow('Imetolewa', mchango['disbursed'] ?? 0),
          _buildContributionRow('Inangojea', mchango['pending'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildExpensesSummaryCard(Map<String, dynamic> expenses) {
    final total = expenses['total'] ?? 0;
    final byCategory = expenses['by_category'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded, size: 18, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              const Text(
                'Matumizi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                'TZS ${_currencyFormat.format(total)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
          if (byCategory.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...byCategory.take(3).map((cat) => _buildContributionRow(
              cat['category_name'] ?? 'N/A',
              cat['total'] ?? 0,
            )),
          ],
        ],
      ),
    );
  }
}
