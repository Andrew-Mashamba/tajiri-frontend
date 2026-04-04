import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../DataStore.dart';
import '../AdaTable.dart';
import '../HttpService.dart';
import '../PaymentLinksWidget.dart';
import '../selectPaymentMethod.dart';
import '../services/page_cache_service.dart';
import 'package:logger/logger.dart';

// Monochrome Design Guidelines Colors
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);

class AdaPage extends StatefulWidget {
  const AdaPage({Key? key}) : super(key: key);

  @override
  State<AdaPage> createState() => _AdaPageState();
}

class _AdaPageState extends State<AdaPage> {
  final Logger _logger = Logger();
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

  // Ada summary from API
  Map<String, dynamic>? _adaSummary;

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
      _logger.e('[AdaPage] Cannot load data - kikobaId or visitorId is empty');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Step 1: Try to load cached data for instant display
    final cachedData = await PageCacheService.getAdaData(visitorId, kikobaId);
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[AdaPage] Loaded cached data for instant display');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend(showLoadingIfNoCachedData: !_hasCachedData);
  }

  /// Apply cached data to DataStore
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['adaSummary'] != null) {
      _adaSummary = Map<String, dynamic>.from(data['adaSummary']);
    }
    if (data['controlNumbers'] != null) {
      DataStore.controlNumbersAda = List<Map<String, dynamic>>.from(data['controlNumbers']);
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
      final currentYear = DateTime.now().year;

      // Fetch Ada summary from BACKEND API
      final summary = await HttpService.fetchAdaSummary(
        kikobaId: kikobaId,
        userId: userId,
        year: currentYear,
      );

      // Fetch control numbers from BACKEND API
      final controlNumbers = await HttpService.fetchControlNumbers(
        kikobaId: kikobaId,
        type: 'ada',
        userId: userId,
        year: currentYear,
        status: 'all',
      );

      // Update state and DataStore
      _adaSummary = summary;
      DataStore.controlNumbersAda = controlNumbers;

      // Cache the data for next time
      await PageCacheService.saveAdaData(visitorId, kikobaId, {
        'adaSummary': summary,
        'controlNumbers': controlNumbers,
        'fetchedAt': DateTime.now().toIso8601String(),
      });

      _logger.d('[AdaPage] Fetched and cached Ada summary and ${controlNumbers.length} control numbers from backend');

      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _hasCachedData = true;
        });
      }
    } catch (e) {
      _logger.e('[AdaPage] Error fetching data from backend: $e');
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
  /// We only read the version number to know when to refresh from backend.
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
      final newVersion = notificationData['ada_version'] as int?;
      final updatedAt = notificationData['ada_updated_at'];
      int? effectiveVersion = newVersion;

      // If no version field, use timestamp as version
      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API (not Firestore!)
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[AdaPage] Firestore notification: version changed from $_lastKnownVersion to $effectiveVersion');
        _lastKnownVersion = effectiveVersion;

        // Fetch fresh data from BACKEND API
        await _fetchDataFromBackend(forceRefresh: true);
      }
    }, onError: (e) {
      _logger.e('[AdaPage] Firestore listener error: $e');
    });
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    // Check connectivity first
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

  // Ada statistics from API summary
  double get _totalPaid => (_adaSummary?['totalPaid'] ?? 0).toDouble();
  double get _totalDebt => (_adaSummary?['totalDebt'] ?? 0).toDouble();
  double get _totalPenalty => (_adaSummary?['totalPenalty'] ?? 0).toDouble();
  int get _paidMonths => _adaSummary?['paidMonths'] ?? 0;
  int get _pendingMonths => _adaSummary?['pendingMonths'] ?? 0;
  double get _kipimoKiasi => (_adaSummary?['kipimoKiasi'] ?? 0).toDouble();

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
          'Ada Yangu - Michango ya Kila Mwezi',
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

                      // Monthly Ada Table
                      _buildMonthlyTableSection(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Build skeleton loading animation for initial load
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Skeleton for statistics section
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
          // Skeleton for table section
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
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 50,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
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
              Expanded(child: _buildStatCard('Kilicholipwa', formatCurrency.format(_totalPaid), Icons.payments_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Deni', formatCurrency.format(_totalDebt), Icons.account_balance_wallet)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Penati', formatCurrency.format(_totalPenalty), Icons.warning_amber_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Miezi Iliyolipwa', '$_paidMonths', Icons.check_circle)),
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
                  'Jedwali la Malipo ya Kila Mwezi',
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
          Padding(
            padding: const EdgeInsets.all(0),
            child: AdaTable(
              data: DataStore.adaListList?.cast<Map<String, dynamic>>() ?? [],
              onDataLoaded: () {
                // Rebuild UI when control numbers are loaded
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }



  void _handlePayment() {
    try {
      final DateTime now = DateTime.now();
      final String formattedDate = "${now.month}/${now.year}";

      DataStore.paymentService = "ada";
      DataStore.maelezoYaMalipo = "Malipo ya ada mwezi $formattedDate ya ${DataStore.currentUserName}";

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const selectPaymentMethode()),
      );
    } catch (e) {
      _logger.e('Error during payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuna tatizo la malipo. Jaribu tena.'),
        ),
      );
    }
  }
}
