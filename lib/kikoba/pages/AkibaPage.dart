import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../DataStore.dart';
import '../AkibaTable.dart';
import '../HttpService.dart';
import '../services/page_cache_service.dart';

// Monochrome Design Guidelines Colors
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);

class AkibaPage extends StatefulWidget {
  const AkibaPage({Key? key}) : super(key: key);

  @override
  State<AkibaPage> createState() => _AkibaPageState();
}

class _AkibaPageState extends State<AkibaPage> {
  final Logger _logger = Logger();
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

  // Akiba summary from API
  Map<String, dynamic>? _akibaSummary;

  // ============ State for caching and real-time updates ============
  /// IMPORTANT: All data is fetched from the BACKEND API.
  /// Firestore is used ONLY for change notifications, NOT for data.
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  bool _isRefreshing = false;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  // Local copy of akiba data for this user
  List<Map<String, dynamic>> _akibaData = [];

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
      _logger.e('[AkibaPage] Cannot load data - kikobaId or visitorId is empty');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Step 1: Try to load cached data for instant display
    final cachedData = await PageCacheService.getAkibaData(visitorId, kikobaId);
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[AkibaPage] Loaded cached data for instant display');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend(showLoadingIfNoCachedData: !_hasCachedData);
  }

  /// Apply cached data
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['akibaSummary'] != null) {
      _akibaSummary = Map<String, dynamic>.from(data['akibaSummary']);
    }
    if (data['akibaData'] != null) {
      _akibaData = List<Map<String, dynamic>>.from(data['akibaData']);
    }
  }

  /// Fetch fresh data from backend API and cache it
  /// IMPORTANT: All data comes from the backend, NOT from Firestore!
  Future<void> _fetchDataFromBackend({bool showLoadingIfNoCachedData = false, bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;
    final userId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty || userId.isEmpty) return;

    if (showLoadingIfNoCachedData && mounted) {
      setState(() => _isInitialLoading = true);
    }

    try {
      // Fetch Akiba summary from BACKEND API
      final summary = await HttpService.fetchAkibaSummary(
        kikobaId: kikobaId,
        userId: userId,
      );

      // Fetch dashboard data which includes akiba list from BACKEND API
      final dashboardData = await HttpService.getDashboardData(
        kikobaId: kikobaId,
        visitorId: visitorId,
      );

      // Update summary
      _akibaSummary = summary;

      if (dashboardData != null && dashboardData['akibaList'] != null) {
        // Update global DataStore
        DataStore.akibaList = dashboardData['akibaList'];

        // Filter for current user
        _akibaData = _filterForCurrentUser(dashboardData['akibaList']);
      }

      // Cache the data for next time
      await PageCacheService.saveAkibaData(visitorId, kikobaId, {
        'akibaSummary': summary,
        'akibaData': _akibaData,
        'fetchedAt': DateTime.now().toIso8601String(),
      });

      _logger.d('[AkibaPage] Fetched and cached Akiba summary and ${_akibaData.length} akiba records from backend');

      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _hasCachedData = true;
        });
      }
    } catch (e) {
      _logger.e('[AkibaPage] Error fetching data from backend: $e');
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

  /// Filter akiba data for current user only
  List<Map<String, dynamic>> _filterForCurrentUser(List<dynamic> allData) {
    final currentUserId = DataStore.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return [];

    return allData.where((item) {
      final itemUserId = item['userId']?.toString().trim() ?? '';
      return itemUserId == currentUserId;
    }).toList().cast<Map<String, dynamic>>();
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
      final newVersion = notificationData['akiba_version'] as int?;
      final updatedAt = notificationData['akiba_updated_at'];
      int? effectiveVersion = newVersion;

      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[AkibaPage] Firestore notification: version changed');
        _lastKnownVersion = effectiveVersion;
        await _fetchDataFromBackend(forceRefresh: true);
      }
    }, onError: (e) {
      _logger.e('[AkibaPage] Firestore listener error: $e');
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

  // Akiba statistics from API summary
  double get _totalSaved => (_akibaSummary?['totalSaved'] ?? 0).toDouble();
  double get _totalWithdrawn => (_akibaSummary?['totalWithdrawn'] ?? 0).toDouble();
  double get _currentBalance => (_akibaSummary?['currentBalance'] ?? 0).toDouble();
  int get _transactionCount => _akibaSummary?['transactionCount'] ?? 0;
  String get _akibaStatus => _akibaSummary?['status']?.toString() ?? 'inactive';
  String? get _lastTransactionDate => _akibaSummary?['lastTransactionDate']?.toString();

  // Get current user's akiba data (use local copy or fall back to DataStore)
  List<Map<String, dynamic>> get _currentUserAkibaData {
    if (_akibaData.isNotEmpty) return _akibaData;

    // Fall back to filtering DataStore if local copy is empty
    if (DataStore.akibaList == null) return [];
    return _filterForCurrentUser(DataStore.akibaList!);
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
          'Akiba Yangu - Akaunti Yangu ya Akiba',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _isInitialLoading && !_hasCachedData
              ? _buildSkeletonLoading()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Statistics Cards
                      _buildStatisticsSection(),

                      // Monthly Akiba Table
                      _buildMonthlyTableSection(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Build skeleton loading animation
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            color: _iconBg,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSkeletonCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSkeletonCard()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSkeletonCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSkeletonCard()),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: _cardBg,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonLine(width: 200, height: 24),
                const SizedBox(height: 16),
                ...List.generate(6, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSkeletonLine(width: double.infinity, height: 40),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(value * 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(width: 80, height: 20, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 4),
              Container(width: 50, height: 12, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(value * 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      color: _iconBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Jumla Iliyowekwa', formatCurrency.format(_totalSaved), Icons.savings_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Salio la Sasa', formatCurrency.format(_currentBalance), Icons.account_balance_wallet)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Idadi ya Muamala', '$_transactionCount', Icons.receipt_long)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Hali', _akibaStatus == 'active' ? 'Inatumika' : 'Haitumiki', Icons.info)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTableSection() {
    return Container(
      //margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(0),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Taarifa ya Akiba - Statement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Always show AkibaTable - it contains the action buttons
          // and handles empty state internally
          Padding(
            padding: const EdgeInsets.all(0),
            child: AkibaTable(
              data: _currentUserAkibaData,
            ),
          ),
        ],
      ),
    );
  }
}
