import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../DataStore.dart';
import '../HttpService.dart';
import '../addMjumbe.dart';
import '../services/page_cache_service.dart';

// Monochrome Design Guidelines Colors
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);

class UongoziPage extends StatefulWidget {
  const UongoziPage({Key? key}) : super(key: key);

  @override
  State<UongoziPage> createState() => _UongoziPageState();
}

class _UongoziPageState extends State<UongoziPage> {
  final Logger _logger = Logger();
  final formatDate = DateFormat('dd MMM yyyy');
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

  // ============ State for caching and real-time updates ============
  /// IMPORTANT: All data is fetched from the BACKEND API.
  /// Firestore is used ONLY for change notifications, NOT for data.
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  bool _isRefreshing = false;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  int get _totalVikao => DataStore.vikaoList?.length ?? 0;
  int get _totalMaamuzi => DataStore.maamuzimList?.length ?? 0;
  int get _totalBaraza => DataStore.barazaList?.length ?? 0;

  List<Map<String, dynamic>> _pendingWithdrawals = [];
  bool _loadingWithdrawals = false;

  List<dynamic> _pendingLoanApplications = [];
  bool _loadingLoanApplications = false;

  List<dynamic> _pendingMichango = [];
  bool _loadingMichango = false;

  // Matumizi (Expenditures) state
  List<dynamic> _matumiziList = [];
  List<dynamic> _expenseAccounts = [];
  List<dynamic> _expenseCategories = [];
  bool _loadingMatumizi = false;
  double _totalMatumizi = 0;
  int _expenseCount = 0;

  // Pagination and sorting for matumizi
  int _matumiziPage = 0;
  int _matumiziLimit = 10;
  int _matumiziTotal = 0;
  bool _matumiziHasMore = false;
  bool _loadingMoreMatumizi = false;
  String _matumiziSortOrder = 'desc'; // 'desc' = newest first, 'asc' = oldest first

  // Helper function to show error dialog
  void _showErrorDialog(String title, String message, {List<String>? details}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 32),
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
              backgroundColor: Colors.red,
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

  /// Load all data - first from cache, then from backend API
  Future<void> _loadData() async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty) {
      _logger.e('[UongoziPage] Cannot load data - kikobaId or visitorId is empty');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Try to load cached data first
    final cachedData = await PageCacheService.getUongoziData(visitorId, kikobaId);
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[UongoziPage] Loaded cached data for instant display');
    }

    // Fetch fresh data from backend API
    await _fetchAllDataFromBackend();
  }

  /// Apply cached data
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['pendingWithdrawals'] != null) {
      _pendingWithdrawals = List<Map<String, dynamic>>.from(data['pendingWithdrawals']);
    }
    if (data['pendingLoanApplications'] != null) {
      _pendingLoanApplications = List<dynamic>.from(data['pendingLoanApplications']);
    }
    if (data['pendingMichango'] != null) {
      _pendingMichango = List<dynamic>.from(data['pendingMichango']);
    }
  }

  /// Fetch all data from backend API
  Future<void> _fetchAllDataFromBackend() async {
    if (!_hasCachedData && mounted) {
      setState(() => _isInitialLoading = true);
    }

    await Future.wait([
      _loadPendingWithdrawals(),
      _loadPendingLoanApplications(),
      _loadPendingMichango(),
    ]);

    // Cache the data
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;
    if (kikobaId.isNotEmpty && visitorId.isNotEmpty) {
      await PageCacheService.saveUongoziData(visitorId, kikobaId, {
        'pendingWithdrawals': _pendingWithdrawals,
        'pendingLoanApplications': _pendingLoanApplications,
        'pendingMichango': _pendingMichango,
        'fetchedAt': DateTime.now().toIso8601String(),
      });
    }

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
        _hasCachedData = true;
      });
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

      // Listen for leadership/admin updates
      final newVersion = notificationData['uongozi_version'] as int?;
      final updatedAt = notificationData['uongozi_updated_at'];
      int? effectiveVersion = newVersion;

      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[UongoziPage] Firestore notification: version changed');
        _lastKnownVersion = effectiveVersion;
        await _fetchAllDataFromBackend();
      }
    }, onError: (e) {
      _logger.e('[UongoziPage] Firestore listener error: $e');
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
    await _fetchAllDataFromBackend();
    setState(() => _isRefreshing = false);
  }

  /// Build skeleton loading animation
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Stats row skeleton
          Row(
            children: [
              Expanded(child: _buildSkeletonCard(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard(height: 80)),
            ],
          ),
          const SizedBox(height: 24),
          // List skeleton
          ...List.generate(5, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSkeletonListItem(),
          )),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({double height = 100}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(value * 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.3), borderRadius: BorderRadius.circular(4))),
              const Spacer(),
              Container(width: 60, height: 14, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.3), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 2),
              Container(width: 40, height: 10, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(4))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonListItem() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
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
        );
      },
    );
  }

  Future<void> _loadPendingWithdrawals() async {
    if (DataStore.currentKikobaId == null) return;

    setState(() {
      _loadingWithdrawals = true;
    });

    try {
      final response = await HttpService.getPendingWithdrawals(DataStore.currentKikobaId!);
      if (response != null && response['success'] == true) {
        setState(() {
          _pendingWithdrawals = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _loadingWithdrawals = false;
        });
      } else {
        setState(() {
          _loadingWithdrawals = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingWithdrawals = false;
      });
    }
  }

  Future<void> _loadPendingLoanApplications() async {
    if (DataStore.currentKikobaId == null) return;

    setState(() {
      _loadingLoanApplications = true;
    });

    try {
      final applications = await HttpService.getLoanApplications(
        kikobaId: DataStore.currentKikobaId,
        status: 'approved',
      );

      print('📋 Approved Loan Applications Response: $applications');
      print('📋 Number of approved applications: ${applications?.length ?? 0}');

      if (mounted) {
        setState(() {
          _pendingLoanApplications = applications ?? [];
          _loadingLoanApplications = false;
        });
        print('📋 State updated with ${_pendingLoanApplications.length} applications');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading loan applications: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _loadingLoanApplications = false;
        });
      }
    }
  }

  // Statistics for michango processing (with partial disbursement support)
  int _michangoTargetReachedCount = 0;
  int _michangoDeadlinePassedCount = 0;
  double _michangoTotalCollected = 0;
  double _michangoTotalDisbursed = 0;
  double _michangoAvailableForDisbursement = 0;

  Future<void> _loadPendingMichango() async {
    if (DataStore.currentKikobaId == null) return;

    setState(() {
      _loadingMichango = true;
    });

    try {
      // Use the new API that returns active michango with disbursement info
      final response = await HttpService.getMichangoReadyForProcessing();

      print('📋 Active Michango Response: $response');

      if (mounted) {
        if (response != null && response['success'] == true) {
          final michangoList = response['michango'] as List<dynamic>? ?? [];
          final reachedTarget = response['reached_target'] as Map<String, dynamic>? ?? {};
          final deadlinePassed = response['deadline_passed'] as Map<String, dynamic>? ?? {};

          print('✅ Found ${michangoList.length} active michango');

          setState(() {
            _pendingMichango = michangoList;
            _michangoTargetReachedCount = reachedTarget['count'] ?? 0;
            _michangoDeadlinePassedCount = deadlinePassed['count'] ?? 0;
            _michangoTotalCollected = double.tryParse(response['total_collected']?.toString() ?? '0') ?? 0.0;
            _michangoTotalDisbursed = double.tryParse(response['total_disbursed']?.toString() ?? '0') ?? 0.0;
            _michangoAvailableForDisbursement = double.tryParse(response['available_for_disbursement']?.toString() ?? '0') ?? 0.0;
            _loadingMichango = false;
          });
        } else {
          setState(() {
            _pendingMichango = [];
            _michangoTargetReachedCount = 0;
            _michangoDeadlinePassedCount = 0;
            _michangoTotalCollected = 0;
            _michangoTotalDisbursed = 0;
            _michangoAvailableForDisbursement = 0;
            _loadingMichango = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error loading michango: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _loadingMichango = false;
        });
      }
    }
  }

  Future<void> _loadMatumizi({bool refresh = true}) async {
    if (DataStore.currentKikobaId == null) return;

    if (refresh) {
      setState(() {
        _loadingMatumizi = true;
        _matumiziPage = 0;
        _matumiziList = [];
      });
    }

    try {
      // Load expense summary, history, and accounts in parallel
      final results = await Future.wait([
        HttpService.getExpenseSummary(),
        HttpService.getExpenseHistory(
          limit: _matumiziLimit,
          offset: _matumiziPage * _matumiziLimit,
        ),
        HttpService.getExpenseAccountsList(),
      ]);

      final summaryResponse = results[0];
      final historyResponse = results[1];
      final accountsResponse = results[2];

      if (mounted) {
        // Process summary data
        double total = 0;
        int count = 0;
        if (summaryResponse != null && summaryResponse['success'] == true) {
          final summaryData = summaryResponse['data'] as Map<String, dynamic>? ?? {};
          total = double.tryParse(summaryData['total_expenses']?.toString() ?? '0') ?? 0;
          count = int.tryParse(summaryData['expense_count']?.toString() ?? '0') ?? 0;
        }

        // Process history data with pagination
        List<dynamic> historyData = [];
        int totalEntries = 0;
        bool hasMore = false;
        if (historyResponse != null && historyResponse['success'] == true) {
          final data = historyResponse['data'];
          // API returns { entries: [...], pagination: {...} }
          if (data is Map) {
            if (data['entries'] is List) {
              historyData = data['entries'] as List<dynamic>;
            }
            // Extract pagination info
            final pagination = data['pagination'] as Map<String, dynamic>?;
            if (pagination != null) {
              totalEntries = pagination['total'] ?? 0;
              hasMore = pagination['has_more'] ?? false;
            }
          } else if (data is List) {
            historyData = data;
          }
        }

        // Sort based on current sort order
        if (_matumiziSortOrder == 'asc') {
          historyData.sort((a, b) {
            final dateA = a['created_at']?.toString() ?? '';
            final dateB = b['created_at']?.toString() ?? '';
            return dateA.compareTo(dateB);
          });
        }

        // Process accounts data
        List<dynamic> accountsData = [];
        if (accountsResponse != null && accountsResponse['success'] == true) {
          final data = accountsResponse['data'];
          if (data is List) {
            accountsData = data;
          }
        }

        setState(() {
          _matumiziList = historyData;
          _expenseAccounts = accountsData;
          _totalMatumizi = total;
          _expenseCount = count;
          _matumiziTotal = totalEntries;
          _matumiziHasMore = hasMore;
          _loadingMatumizi = false;
        });
      }
    } catch (e) {
      print('❌ Error loading matumizi: $e');
      if (mounted) {
        setState(() {
          _loadingMatumizi = false;
        });
      }
    }
  }

  Future<void> _loadMoreMatumizi() async {
    if (_loadingMoreMatumizi || !_matumiziHasMore) return;

    setState(() {
      _loadingMoreMatumizi = true;
      _matumiziPage++;
    });

    try {
      final historyResponse = await HttpService.getExpenseHistory(
        limit: _matumiziLimit,
        offset: _matumiziPage * _matumiziLimit,
      );

      if (mounted && historyResponse != null && historyResponse['success'] == true) {
        final data = historyResponse['data'];
        List<dynamic> newEntries = [];
        bool hasMore = false;

        if (data is Map) {
          if (data['entries'] is List) {
            newEntries = data['entries'] as List<dynamic>;
          }
          final pagination = data['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            hasMore = pagination['has_more'] ?? false;
          }
        }

        // Sort if needed
        if (_matumiziSortOrder == 'asc') {
          newEntries.sort((a, b) {
            final dateA = a['created_at']?.toString() ?? '';
            final dateB = b['created_at']?.toString() ?? '';
            return dateA.compareTo(dateB);
          });
        }

        setState(() {
          _matumiziList.addAll(newEntries);
          _matumiziHasMore = hasMore;
          _loadingMoreMatumizi = false;
        });
      } else {
        setState(() => _loadingMoreMatumizi = false);
      }
    } catch (e) {
      print('❌ Error loading more matumizi: $e');
      if (mounted) {
        setState(() {
          _loadingMoreMatumizi = false;
          _matumiziPage--; // Revert page on error
        });
      }
    }
  }

  void _toggleMatumiziSortOrder() {
    setState(() {
      _matumiziSortOrder = _matumiziSortOrder == 'desc' ? 'asc' : 'desc';
    });
    _loadMatumizi();
  }

  Future<void> _loadExpenseCategories() async {
    try {
      final response = await HttpService.getExpenseCategories();
      if (mounted && response != null && response['success'] == true) {
        setState(() {
          _expenseCategories = response['data'] as List<dynamic>? ?? [];
        });
      }
    } catch (e) {
      print('❌ Error loading expense categories: $e');
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
          'Shuguli za Uongozi',
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
      body: SafeArea(
        top: false, // AppBar handles top safe area
        child: _isInitialLoading && !_hasCachedData
            ? _buildSkeletonLoading()
            : RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildWanachamaSection(),
              const SizedBox(height: 16),
              _buildWasilishaMichangoSection(),
              const SizedBox(height: 16),
              _buildPendingLoanApplicationsSection(),
              const SizedBox(height: 16),
              _buildPendingWithdrawalsSection(),
              const SizedBox(height: 16),
              _buildFanyaMatumiziSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ), // SafeArea
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      color: _iconBg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Vikao', '$_totalVikao', Icons.event)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Maamuzi', '$_totalMaamuzi', Icons.gavel)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Baraza', '$_totalBaraza', Icons.groups)),
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
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildWanachamaSection() {
    final totalMembers = DataStore.membersList?.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wanachama',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText),
                        ),
                        Text(
                          '$totalMembers ${totalMembers == 1 ? "mwanachama" : "wanachama"}',
                          style: const TextStyle(fontSize: 11, color: _secondaryText, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Ongeza Mwanachama Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const addMjumbe()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ongeza Mwanachama',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Mwalike mwanachama mpya kwenye kikundi',
                                style: TextStyle(fontSize: 12, color: _secondaryText),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _accentColor, size: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Anzisha Mchango Kwa Niaba Button
                InkWell(
                  onTap: () => _showAnzishaMchangoKwaNiabaDialog(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Anzisha Mchango Kwa Niaba',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Omba mchango kwa niaba ya mwanachama',
                                style: TextStyle(fontSize: 12, color: _secondaryText),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _accentColor, size: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Futa Uwanachama Button
                InkWell(
                  onTap: () => _showRemoveMemberDialog(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_remove_alt_1_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Futa Uwanachama wa Mtu',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ondoa mwanachama kwenye kikundi',
                                style: TextStyle(fontSize: 12, color: _secondaryText),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _accentColor, size: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Anzisha Kesi ya Kura Button
                InkWell(
                  onTap: () => _showCreateVotingCaseDialog(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Anzisha Kesi ya Kura',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Wasilisha suala kwa wanachama kupiga kura',
                                style: TextStyle(fontSize: 12, color: _secondaryText),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _accentColor, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasilishaMichangoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wasilisha Michango',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText),
                        ),
                        if (_pendingMichango.isNotEmpty)
                          Text(
                            '${_pendingMichango.length} ${_pendingMichango.length == 1 ? "mchango" : "michango"} tayari',
                            style: const TextStyle(fontSize: 11, color: _secondaryText, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_loadingMichango)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: _iconBg),
                    onPressed: _loadPendingMichango,
                  ),
              ],
            ),
          ),

          // Statistics Row - Status counts
          if (_pendingMichango.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Target Reached
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            '$_michangoTargetReachedCount',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                          ),
                          Text(
                            'Lengo Limefikiwa',
                            style: TextStyle(fontSize: 9, color: Colors.green.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Deadline Passed
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.schedule, color: Colors.orange.shade700, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            '$_michangoDeadlinePassedCount',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.orange.shade700),
                          ),
                          Text(
                            'Muda Umepita',
                            style: TextStyle(fontSize: 9, color: Colors.orange.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Financial Statistics Row - Collected, Disbursed, Available
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Total Collected
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.savings_rounded, color: _iconBg, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency.format(_michangoTotalCollected),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _primaryText),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Imekusanywa',
                            style: TextStyle(fontSize: 9, color: _secondaryText),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Total Disbursed
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.send_rounded, color: Colors.blue.shade700, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency.format(_michangoTotalDisbursed),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Imetolewa',
                            style: TextStyle(fontSize: 9, color: Colors.blue.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Available for Disbursement
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.green.shade700, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency.format(_michangoAvailableForDisbursement),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Inapatikana',
                            style: TextStyle(fontSize: 9, color: Colors.green.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Process All Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pendingMichango.isNotEmpty ? _showProcessAllDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _iconBg,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
                  label: Text(
                    'Sindika Michango Yote (${_pendingMichango.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1),
          if (_loadingMichango && _pendingMichango.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_pendingMichango.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _accentColor),
                  const SizedBox(height: 8),
                  Text('Hakuna michango ya kuwasilisha', style: TextStyle(color: _secondaryText)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingMichango.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final mchango = _pendingMichango[index];
                return _buildMchangoCard(mchango);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMchangoCard(Map<String, dynamic> mchango) {
    final title = mchango['ainayaMchango']?.toString() ?? mchango['title']?.toString() ?? 'Mchango';
    final requesterName = mchango['requester_name']?.toString() ??
                          mchango['requester']?['userName']?.toString() ??
                          mchango['userName']?.toString() ?? 'Mwanachama';
    final targetAmount = double.tryParse(mchango['target']?.toString() ?? mchango['targetAmount']?.toString() ?? '0') ?? 0.0;
    final totalCollected = double.tryParse(mchango['collected']?.toString() ?? mchango['totalCollected']?.toString() ?? '0') ?? 0.0;
    final totalDisbursed = double.tryParse(mchango['disbursed']?.toString() ?? '0') ?? 0.0;
    final availableForDisbursement = double.tryParse(mchango['available_for_disbursement']?.toString() ?? '0') ?? 0.0;
    final progressPercentage = double.tryParse(mchango['progress_percentage']?.toString() ?? mchango['progressPercentage']?.toString() ?? '0') ?? 0.0;
    final status = mchango['status']?.toString().toLowerCase() ?? 'active';
    final mchangoId = mchango['mchangoId']?.toString() ?? mchango['id']?.toString() ?? '';
    final deadline = mchango['deadline']?.toString() ?? mchango['tarehe']?.toString() ?? '';
    final contributorsCount = int.tryParse(mchango['contributorsCount']?.toString() ?? '0') ?? 0;
    final reason = mchango['reason']?.toString() ?? ''; // 'target_reached' or 'deadline_passed'
    final userId = mchango['requester_id']?.toString() ?? mchango['userId']?.toString() ?? '';

    final isTargetReached = reason == 'target_reached' || progressPercentage >= 100;
    final isDeadlinePassed = reason == 'deadline_passed';
    final hasAvailableFunds = availableForDisbursement > 0;
    final isFullyDisbursed = totalDisbursed >= totalCollected && totalCollected > 0;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: isTargetReached ? Colors.green.shade50 : _primaryBg,
        child: Icon(
          isTargetReached ? Icons.check_circle : Icons.volunteer_activism,
          color: isTargetReached ? Colors.green : _iconBg,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Kwa: $requesterName', style: const TextStyle(fontSize: 12, color: _secondaryText)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                formatCurrency.format(totalCollected),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isTargetReached ? Colors.green : _primaryText,
                ),
              ),
              Text(
                ' / ${formatCurrency.format(targetAmount)}',
                style: const TextStyle(fontSize: 12, color: _secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progressPercentage / 100).clamp(0.0, 1.0),
              backgroundColor: _accentColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isTargetReached ? Colors.green : _iconBg,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${progressPercentage.toStringAsFixed(0)}% • $contributorsCount waliochangia',
            style: const TextStyle(fontSize: 11, color: _secondaryText),
          ),
        ],
      ),
      children: [
        // Details Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildMchangoDetailRow('Lengo', formatCurrency.format(targetAmount)),
              const SizedBox(height: 8),
              _buildMchangoDetailRow('Imekusanywa', formatCurrency.format(totalCollected)),
              const SizedBox(height: 8),
              _buildMchangoDetailRow('Walichangia', '$contributorsCount'),
              if (deadline.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildMchangoDetailRow('Tarehe ya Mwisho', deadline.split('T').first),
              ],
              const SizedBox(height: 8),
              _buildMchangoDetailRow('Hali', _getMchangoStatusText(status, isTargetReached)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Disbursement Info Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payments_rounded, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Hali ya Utoaji',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          formatCurrency.format(totalDisbursed),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          'Imetolewa',
                          style: TextStyle(fontSize: 10, color: Colors.blue.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.blue.shade200,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          formatCurrency.format(availableForDisbursement),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: hasAvailableFunds ? Colors.green.shade700 : _secondaryText,
                          ),
                        ),
                        Text(
                          'Inapatikana',
                          style: TextStyle(fontSize: 10, color: hasAvailableFunds ? Colors.green.shade600 : _secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isFullyDisbursed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Imetolewa yote',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Status Badge - shows reason for being ready
        if (isTargetReached && !isFullyDisbursed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lengo limefikiwa! Tayari kusindikwa.',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (isDeadlinePassed && !isFullyDisbursed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Muda umepita! Imekusanya ${progressPercentage.toStringAsFixed(0)}%.',
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (isFullyDisbursed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mchango umekamilika. Fedha zote zimetolewa.',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (!isFullyDisbursed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _iconBg, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tayari kusindikwa. Imekusanya ${progressPercentage.toStringAsFixed(0)}%.',
                    style: const TextStyle(color: _primaryText, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Action Buttons
        Row(
          children: [
            // View Details Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showMchangoDetailsDialog(mchango),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _iconBg,
                  side: const BorderSide(color: _iconBg),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Angalia'),
              ),
            ),
            const SizedBox(width: 12),
            // Disburse Button - uses new partial disbursement API
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasAvailableFunds ? () => _showDisburseMchangoDialog(mchango) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasAvailableFunds ? Colors.green : _accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accentColor.withOpacity(0.5),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(hasAvailableFunds ? Icons.send_rounded : Icons.check_circle_rounded, size: 18),
                label: Text(hasAvailableFunds ? 'Toa Fedha' : 'Imekamilika'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMchangoDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _secondaryText)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText)),
      ],
    );
  }

  String _getMchangoStatusText(String status, bool isTargetReached) {
    switch (status) {
      case 'active':
        return isTargetReached ? 'Lengo Limefikiwa' : 'Inaendelea';
      case 'pending_disbursement':
      case 'ready_for_disbursement':
        return 'Tayari Kusambazwa';
      case 'completed':
        return 'Imekamilika';
      case 'closed':
        return 'Imefungwa';
      case 'disbursed':
        return 'Imesambazwa';
      default:
        return status;
    }
  }

  // Show mchango details dialog with contributors/non-contributors tabs
  void _showMchangoDetailsDialog(Map<String, dynamic> mchango) {
    final title = mchango['ainayaMchango']?.toString() ?? 'Mchango';
    final mchangoId = mchango['mchangoId']?.toString() ?? mchango['id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _MchangoReportSheet(
          mchango: mchango,
          mchangoId: mchangoId,
          title: title,
          scrollController: scrollController,
          onRemind: (nonContributors) => _sendReminders(mchangoId, nonContributors),
        ),
      ),
    );
  }

  // Send reminders to non-contributors
  Future<void> _sendReminders(String mchangoId, List<dynamic> nonContributors) async {
    if (nonContributors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hakuna wasiokuwa wamechangia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Tuma Vikumbusho', style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(
          'Tuma vikumbusho kwa wasiokuwa wamechangia ${nonContributors.length}?',
          style: const TextStyle(fontSize: 15, color: _primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Sitisha', style: TextStyle(color: _secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _iconBg,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tuma'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await HttpService.sendMchangoReminders(mchangoId: mchangoId);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response != null && response['success'] == true) {
        final sentCount = response['sentCount'] ?? 0;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vikumbusho $sentCount vimetumwa'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            'Imeshindwa Kutuma',
            response?['message'] ?? 'Imeshindwa kutuma vikumbusho. Tafadhali jaribu tena.',
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _showErrorDialog('Kosa', 'Kuna tatizo limetokea: $e');
      }
    }
  }

  String _getReasonText(String reason) {
    switch (reason) {
      case 'target_reached':
        return 'Lengo Limefikiwa';
      case 'deadline_passed':
        return 'Muda Umepita';
      default:
        return 'Tayari Kusindikwa';
    }
  }

  // Show process single mchango confirmation dialog
  void _showProcessMchangoDialog(Map<String, dynamic> mchango) {
    final title = mchango['ainayaMchango']?.toString() ?? 'Mchango';
    final mchangoId = mchango['mchangoId']?.toString() ?? mchango['id']?.toString() ?? '';
    final requesterName = mchango['requester_name']?.toString() ??
                          mchango['requester']?['userName']?.toString() ?? 'Mwanachama';
    final totalCollected = double.tryParse(mchango['collected']?.toString() ?? mchango['totalCollected']?.toString() ?? '0') ?? 0.0;
    final reason = mchango['reason']?.toString() ?? '';

    final willDisburse = totalCollected > 0;
    final actionText = willDisburse ? 'Sambaza' : 'Funga';
    final actionDescription = willDisburse
        ? 'Fedha ${formatCurrency.format(totalCollected)} zitahamishwa kwa $requesterName.'
        : 'Mchango utafungwa bila kusambaza fedha.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: willDisburse ? Colors.green : _iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        willDisburse ? Icons.send_rounded : Icons.close_rounded,
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
                            'Sindika Mchango',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                          ),
                          Text(title, style: const TextStyle(fontSize: 13, color: _secondaryText)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Recipient Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _iconBg,
                            child: Text(
                              requesterName.isNotEmpty ? requesterName[0].toUpperCase() : 'M',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mpokeaji', style: TextStyle(fontSize: 11, color: _secondaryText)),
                                Text(
                                  requesterName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kiasi', style: TextStyle(fontSize: 13, color: _secondaryText)),
                          Text(
                            formatCurrency.format(totalCollected),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: willDisburse ? Colors.green : _primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kitendo', style: TextStyle(fontSize: 13, color: _secondaryText)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: willDisburse ? Colors.green.shade100 : _primaryBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              actionText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: willDisburse ? Colors.green.shade700 : _primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: willDisburse ? Colors.green.shade50 : _primaryBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: willDisburse ? Colors.green.shade200 : _accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: willDisburse ? Colors.green.shade700 : _iconBg,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          actionDescription,
                          style: const TextStyle(fontSize: 12, color: _primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: _accentColor),
                        ),
                        child: const Text('Sitisha', style: TextStyle(color: _primaryText)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _processMchango(mchango);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: willDisburse ? Colors.green : _iconBg,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(willDisburse ? Icons.send_rounded : Icons.check_rounded, size: 20),
                        label: Text(
                          'Thibitisha $actionText',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show partial disbursement dialog
  void _showDisburseMchangoDialog(Map<String, dynamic> mchango) {
    final title = mchango['ainayaMchango']?.toString() ?? mchango['title']?.toString() ?? 'Mchango';
    final mchangoId = mchango['mchangoId']?.toString() ?? mchango['id']?.toString() ?? '';
    final requesterName = mchango['requester_name']?.toString() ??
                          mchango['requester']?['userName']?.toString() ??
                          mchango['userName']?.toString() ?? 'Mwanachama';
    final userId = mchango['requester_id']?.toString() ?? mchango['userId']?.toString() ?? '';
    final totalCollected = double.tryParse(mchango['collected']?.toString() ?? mchango['totalCollected']?.toString() ?? '0') ?? 0.0;
    final totalDisbursed = double.tryParse(mchango['disbursed']?.toString() ?? '0') ?? 0.0;
    final availableForDisbursement = double.tryParse(mchango['available_for_disbursement']?.toString() ?? '0') ?? 0.0;

    final amountController = TextEditingController(text: availableForDisbursement.toStringAsFixed(0));
    final notesController = TextEditingController();
    String selectedPaymentMethod = 'mobile_money';
    bool isProcessing = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Toa Fedha',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                              ),
                              Text(title, style: const TextStyle(fontSize: 13, color: _secondaryText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Recipient Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _primaryBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _accentColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _iconBg,
                                child: Text(
                                  requesterName.isNotEmpty ? requesterName[0].toUpperCase() : 'M',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Mpokeaji', style: TextStyle(fontSize: 11, color: _secondaryText)),
                                    Text(
                                      requesterName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          // Financial Summary
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      formatCurrency.format(totalCollected),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryText),
                                    ),
                                    const Text('Imekusanywa', style: TextStyle(fontSize: 10, color: _secondaryText)),
                                  ],
                                ),
                              ),
                              Container(height: 30, width: 1, color: _accentColor.withOpacity(0.3)),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      formatCurrency.format(totalDisbursed),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                                    ),
                                    const Text('Imetolewa', style: TextStyle(fontSize: 10, color: _secondaryText)),
                                  ],
                                ),
                              ),
                              Container(height: 30, width: 1, color: _accentColor.withOpacity(0.3)),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      formatCurrency.format(availableForDisbursement),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                                    ),
                                    const Text('Inapatikana', style: TextStyle(fontSize: 10, color: _secondaryText)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    const Text('Kiasi cha Kutoa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixText: 'TZS ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: _primaryText),
                        hintText: 'Weka kiasi',
                        filled: true,
                        fillColor: _primaryBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _iconBg, width: 2),
                        ),
                        suffixIcon: TextButton(
                          onPressed: () {
                            amountController.text = availableForDisbursement.toStringAsFixed(0);
                          },
                          child: const Text('Yote', style: TextStyle(color: _iconBg, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 0;
                        if (amount > availableForDisbursement) {
                          setDialogState(() {
                            errorMessage = 'Kiasi kimezidi kiasi kinachopatikana';
                          });
                        } else {
                          setDialogState(() {
                            errorMessage = null;
                          });
                        }
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                    const SizedBox(height: 16),

                    // Payment Method
                    const Text('Njia ya Malipo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _primaryBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'mobile_money',
                            groupValue: selectedPaymentMethod,
                            onChanged: (value) => setDialogState(() => selectedPaymentMethod = value!),
                            title: const Text('Mobile Money', style: TextStyle(fontSize: 14)),
                            secondary: const Icon(Icons.phone_android_rounded, color: _iconBg),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            dense: true,
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            value: 'bank_transfer',
                            groupValue: selectedPaymentMethod,
                            onChanged: (value) => setDialogState(() => selectedPaymentMethod = value!),
                            title: const Text('Benki', style: TextStyle(fontSize: 14)),
                            secondary: const Icon(Icons.account_balance_rounded, color: _iconBg),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            dense: true,
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            value: 'cash',
                            groupValue: selectedPaymentMethod,
                            onChanged: (value) => setDialogState(() => selectedPaymentMethod = value!),
                            title: const Text('Taslimu', style: TextStyle(fontSize: 14)),
                            secondary: const Icon(Icons.payments_rounded, color: _iconBg),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const Text('Maelezo (Hiari)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Andika maelezo...',
                        filled: true,
                        fillColor: _primaryBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: _accentColor),
                            ),
                            child: const Text('Sitisha', style: TextStyle(color: _primaryText)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isProcessing || errorMessage != null
                                ? null
                                : () async {
                                    final amount = double.tryParse(amountController.text) ?? 0;
                                    if (amount <= 0) {
                                      setDialogState(() {
                                        errorMessage = 'Tafadhali weka kiasi sahihi';
                                      });
                                      return;
                                    }
                                    if (amount > availableForDisbursement) {
                                      setDialogState(() {
                                        errorMessage = 'Kiasi kimezidi kiasi kinachopatikana';
                                      });
                                      return;
                                    }

                                    setDialogState(() {
                                      isProcessing = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      final response = await HttpService.disburseMchango(
                                        mchangoId: mchangoId,
                                        userId: userId,
                                        amount: amount,
                                        paymentMethod: selectedPaymentMethod,
                                        notes: notesController.text.isNotEmpty ? notesController.text : null,
                                      );

                                      if (mounted) Navigator.pop(context);

                                      if (response != null && response['success'] == true) {
                                        await _loadPendingMichango();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${formatCurrency.format(amount)} imetolewa kwa $requesterName'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          _showDisbursementSuccessDialog(response, requesterName, amount);
                                        }
                                      } else {
                                        if (mounted) {
                                          _showErrorDialog(
                                            'Imeshindwa Kutoa',
                                            response?['message'] ?? 'Imeshindwa kutoa fedha. Tafadhali jaribu tena.',
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        isProcessing = false;
                                        errorMessage = 'Hitilafu: $e';
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.green.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded, size: 20),
                            label: Text(
                              isProcessing ? 'Inatoa...' : 'Toa Fedha',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show success dialog after disbursement
  void _showDisbursementSuccessDialog(Map<String, dynamic> response, String recipientName, double amount) {
    final disbursementId = response['disbursement']?['disbursement_id']?.toString() ?? '';
    final newBalance = double.tryParse(response['disbursement']?['new_balance']?.toString() ?? '0') ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fedha Zimetolewa!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency.format(amount),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.green.shade700),
            ),
            const SizedBox(height: 4),
            Text('kwa $recipientName', style: const TextStyle(fontSize: 14, color: _secondaryText)),
            const SizedBox(height: 16),
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
                      const Text('Salio Lililobaki', style: TextStyle(fontSize: 12, color: _secondaryText)),
                      Text(
                        formatCurrency.format(newBalance),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
                      ),
                    ],
                  ),
                  if (disbursementId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nambari ya Utoaji', style: TextStyle(fontSize: 12, color: _secondaryText)),
                        Text(
                          disbursementId.length > 8 ? '${disbursementId.substring(0, 8)}...' : disbursementId,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primaryText),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _iconBg,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sawa'),
            ),
          ),
        ],
      ),
    );
  }

  // Process single mchango using new API
  Future<void> _processMchango(Map<String, dynamic> mchango) async {
    final title = mchango['ainayaMchango']?.toString() ?? 'Mchango';
    final mchangoId = mchango['mchangoId']?.toString() ?? mchango['id']?.toString() ?? '';
    final requesterName = mchango['requester_name']?.toString() ??
                          mchango['requester']?['userName']?.toString() ?? 'Mwanachama';

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await HttpService.processMchango(mchangoId: mchangoId);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response != null && response['success'] == true) {
        await _loadPendingMichango();

        final action = response['action'] ?? 'processed';
        final amount = double.tryParse(response['amount']?.toString() ?? '0') ?? 0.0;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == 'disbursed'
                    ? '${formatCurrency.format(amount)} imesambazwa kwa $requesterName'
                    : 'Mchango "$title" umefungwa',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Show success dialog
          _showProcessSuccessDialog(mchango, action, amount);
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            'Imeshindwa Kusindika',
            response?['message'] ?? 'Imeshindwa kusindika mchango. Tafadhali jaribu tena.',
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showErrorDialog('Kosa', 'Kuna tatizo limetokea: $e');
      }
    }
  }

  // Show process all dialog
  void _showProcessAllDialog() {
    final totalAmount = _michangoTotalCollected;
    final count = _pendingMichango.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Sindika Michango Yote', style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Una uhakika unataka kusindika michango $count?',
              style: const TextStyle(fontSize: 15, color: _primaryText),
            ),
            const SizedBox(height: 16),
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
                      const Text('Jumla ya Michango:', style: TextStyle(fontSize: 13, color: _secondaryText)),
                      Text('$count', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primaryText)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lengo Limefikiwa:', style: TextStyle(fontSize: 13, color: _secondaryText)),
                      Text('$_michangoTargetReachedCount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Muda Umepita:', style: TextStyle(fontSize: 13, color: _secondaryText)),
                      Text('$_michangoDeadlinePassedCount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumla ya Fedha:', style: TextStyle(fontSize: 13, color: _secondaryText)),
                      Text(
                        formatCurrency.format(totalAmount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kitendo hiki hakiwezi kurudishwa.',
                      style: TextStyle(fontSize: 12, color: _primaryText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sitisha', style: TextStyle(color: _secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _iconBg,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _processAllMichango();
            },
            child: const Text('Sindika Yote'),
          ),
        ],
      ),
    );
  }

  // Process all michango using bulk API
  Future<void> _processAllMichango() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Inasindika michango...', style: TextStyle(fontSize: 15, color: _primaryText)),
            const SizedBox(height: 8),
            Text('Tafadhali subiri', style: TextStyle(fontSize: 13, color: _secondaryText)),
          ],
        ),
      ),
    );

    try {
      final response = await HttpService.processAllMichango();

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response != null && response['success'] == true) {
        await _loadPendingMichango();

        final processedCount = response['processed_count'] ?? 0;
        final failedCount = response['failed_count'] ?? 0;
        final processed = response['processed'] as List<dynamic>? ?? [];

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Michango $processedCount imesindikwa${failedCount > 0 ? ', $failedCount imeshindwa' : ''}'),
              backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
            ),
          );

          // Show summary dialog
          _showProcessAllResultDialog(processedCount, failedCount, processed);
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            'Imeshindwa Kusindika',
            response?['message'] ?? 'Imeshindwa kusindika michango. Tafadhali jaribu tena.',
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showErrorDialog('Kosa', 'Kuna tatizo limetokea: $e');
      }
    }
  }

  // Show single process success dialog
  void _showProcessSuccessDialog(Map<String, dynamic> mchango, String action, double amount) {
    final title = mchango['ainayaMchango']?.toString() ?? 'Mchango';
    final requesterName = mchango['requester_name']?.toString() ??
                          mchango['requester']?['userName']?.toString() ?? 'Mwanachama';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action == 'disbursed' ? Icons.check_circle : Icons.task_alt,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              action == 'disbursed' ? 'Mchango Umesambazwa!' : 'Mchango Umefungwa!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              action == 'disbursed'
                  ? '${formatCurrency.format(amount)} imesambazwa kwa $requesterName kwa mchango wa "$title".'
                  : 'Mchango wa "$title" umefungwa bila kusambaza fedha.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _secondaryText),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _iconBg,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Sawa'),
            ),
          ),
        ],
      ),
    );
  }

  // Show process all result dialog
  void _showProcessAllResultDialog(int processedCount, int failedCount, List<dynamic> processed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failedCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
              color: failedCount > 0 ? Colors.orange : Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Michango Imesindikwa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
            ),
            const SizedBox(height: 16),
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
                      const Text('Imesindikwa:', style: TextStyle(fontSize: 13, color: _secondaryText)),
                      Text(
                        '$processedCount',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  if (failedCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Imeshindwa:', style: TextStyle(fontSize: 13, color: _secondaryText)),
                        Text(
                          '$failedCount',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (processed.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Column(
                    children: processed.take(5).map((item) {
                      final itemTitle = item['ainayaMchango']?.toString() ?? 'Mchango';
                      final itemAction = item['action']?.toString() ?? 'processed';
                      final itemAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              itemAction == 'disbursed' ? Icons.send_rounded : Icons.close_rounded,
                              size: 16,
                              color: itemAction == 'disbursed' ? Colors.green : _secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                itemTitle,
                                style: const TextStyle(fontSize: 12, color: _primaryText),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              itemAmount > 0 ? formatCurrency.format(itemAmount) : 'Imefungwa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: itemAmount > 0 ? Colors.green.shade700 : _secondaryText,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (processed.length > 5)
                Text(
                  '...na ${processed.length - 5} mengine',
                  style: const TextStyle(fontSize: 11, color: _secondaryText),
                ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _iconBg,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Sawa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanyaMatumiziSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fanya Matumizi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText),
                        ),
                        if (_matumiziList.isNotEmpty)
                          Text(
                            '${_matumiziList.length} ${_matumiziList.length == 1 ? "tumizi" : "matumizi"}',
                            style: const TextStyle(fontSize: 11, color: _secondaryText, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_loadingMatumizi)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: _iconBg),
                        onPressed: _loadMatumizi,
                      ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: _iconBg),
                      onPressed: _showAddMatumiziDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Summary
          if (_totalMatumizi > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, size: 18, color: _iconBg),
                        const SizedBox(width: 8),
                        const Text(
                          'Jumla ya Matumizi',
                          style: TextStyle(fontSize: 13, color: _secondaryText),
                        ),
                      ],
                    ),
                    Text(
                      formatCurrency.format(_totalMatumizi),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primaryText),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          // Add New Expenditure Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: _showAddMatumiziDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_card_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ongeza Matumizi Mapya',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Inahitaji idhini ya wanachama',
                            style: TextStyle(fontSize: 12, color: _secondaryText),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _accentColor),
                  ],
                ),
              ),
            ),
          ),

          // Expenditure List
          if (_loadingMatumizi && _matumiziList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_matumiziList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _accentColor),
                  const SizedBox(height: 8),
                  Text('Hakuna matumizi yaliyorekodiwa', style: TextStyle(color: _secondaryText)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matumiziList.length > 5 ? 5 : _matumiziList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final matumizi = _matumiziList[index] as Map<String, dynamic>;
                return _buildMatumiziCard(matumizi);
              },
            ),

          // See All Button
          if (_matumiziList.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  _showAllMatumiziSheet();
                },
                child: Text(
                  'Ona Matumizi Yote (${_matumiziList.length})',
                  style: const TextStyle(color: _iconBg, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatumiziCard(Map<String, dynamic> matumizi) {
    final description = matumizi['description']?.toString() ?? matumizi['maelezo']?.toString() ?? 'Matumizi';
    final amount = double.tryParse(matumizi['amount']?.toString() ?? matumizi['kiasi']?.toString() ?? '0') ?? 0.0;
    final accountCode = matumizi['account_code']?.toString() ?? matumizi['expense_account_code']?.toString() ?? '';
    final accountName = matumizi['account_name']?.toString() ?? '';
    final date = matumizi['created_at']?.toString() ?? matumizi['date']?.toString() ?? matumizi['tarehe']?.toString();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _primaryBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getMatumiziIcon(accountName),
          color: _iconBg,
          size: 22,
        ),
      ),
      title: Text(
        description,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (accountName.isNotEmpty)
            Text(
              accountName,
              style: const TextStyle(fontSize: 12, color: _secondaryText),
            )
          else if (accountCode.isNotEmpty)
            Text(
              accountCode,
              style: const TextStyle(fontSize: 12, color: _secondaryText),
            ),
          if (date != null)
            Text(
              date,
              style: const TextStyle(fontSize: 11, color: _accentColor),
            ),
        ],
      ),
      trailing: Text(
        formatCurrency.format(amount),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primaryText),
      ),
      onTap: () => _showMatumiziDetailsDialog(matumizi),
    );
  }

  IconData _getMatumiziIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ofisi':
      case 'office':
        return Icons.business_rounded;
      case 'safari':
      case 'travel':
        return Icons.directions_car_rounded;
      case 'chakula':
      case 'food':
        return Icons.restaurant_rounded;
      case 'vifaa':
      case 'equipment':
        return Icons.inventory_2_rounded;
      case 'mshahara':
      case 'salary':
        return Icons.payments_rounded;
      case 'kodi':
      case 'rent':
        return Icons.home_rounded;
      case 'umeme':
      case 'utilities':
        return Icons.bolt_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  void _showAddMatumiziDialog() {
    final titleController = TextEditingController();
    final maelezoController = TextEditingController();
    final kiasiController = TextEditingController();
    final payeeNameController = TextEditingController();
    Map<String, dynamic>? selectedAccount;
    List<dynamic> accounts = List.from(_expenseAccounts); // Use cached data initially
    bool isLoadingAccounts = accounts.isEmpty; // Only show loading if no cached data
    bool hasFetched = false;
    bool isSubmitting = false;
    bool isSheetMounted = true; // Track if sheet is still open

    // Capture ScaffoldMessenger before opening sheet (use parent context)
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Pre-select first account if available from cache
    if (accounts.isNotEmpty) {
      selectedAccount = accounts.first as Map<String, dynamic>;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Fetch fresh data when sheet opens (only once)
          if (!hasFetched) {
            hasFetched = true;
            Future.microtask(() async {
              try {
                final accountsResponse = await HttpService.getExpenseAccountsList();
                if (!isSheetMounted) return; // Check if sheet is still open
                if (accountsResponse != null && accountsResponse['success'] == true) {
                  final data = accountsResponse['data'];
                  final freshAccounts = data is List ? data : <dynamic>[];
                  if (isSheetMounted) {
                    setSheetState(() {
                      accounts = freshAccounts;
                      isLoadingAccounts = false;
                      // Always update selectedAccount from fresh list to maintain reference equality
                      if (freshAccounts.isNotEmpty) {
                        if (selectedAccount != null) {
                          // Find matching account by ID from fresh list
                          final selectedId = selectedAccount!['id'];
                          final match = freshAccounts.firstWhere(
                            (a) => a['id'] == selectedId,
                            orElse: () => freshAccounts.first,
                          );
                          selectedAccount = match as Map<String, dynamic>;
                        } else {
                          selectedAccount = freshAccounts.first as Map<String, dynamic>;
                        }
                      }
                      // Update parent state too
                      _expenseAccounts = freshAccounts;
                    });
                  }
                } else {
                  if (isSheetMounted) {
                    setSheetState(() => isLoadingAccounts = false);
                  }
                }
              } catch (e) {
                print('❌ Error fetching expense accounts: $e');
                if (isSheetMounted) {
                  setSheetState(() => isLoadingAccounts = false);
                }
              }
            });
          }

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_card_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekodi Matumizi',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                            ),
                            Text(
                              'Rekodi malipo ya matumizi',
                              style: TextStyle(fontSize: 12, color: _secondaryText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: _secondaryText),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Expense Account Dropdown with loading state
                  if (isLoadingAccounts && accounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: _primaryBg,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: Colors.grey),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Inapakia akaunti...', style: TextStyle(color: Colors.grey))),
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _iconBg,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedAccount,
                      decoration: InputDecoration(
                        labelText: 'Akaunti ya Matumizi',
                        prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: _primaryBg,
                        suffixIcon: isLoadingAccounts
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      hint: const Text('Chagua akaunti'),
                      isExpanded: true,
                      menuMaxHeight: 250, // Makes dropdown scrollable
                      items: accounts.map((account) {
                        final code = account['code']?.toString() ?? '';
                        final name = account['name']?.toString() ?? '';
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: account as Map<String, dynamic>,
                          child: Text(
                            '$code - $name',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setSheetState(() => selectedAccount = value);
                      },
                    ),

                  if (!isLoadingAccounts && accounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hakuna akaunti za matumizi. Ongeza akaunti kwanza.',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                const SizedBox(height: 16),

                // Title Field (REQUIRED)
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Kichwa cha Matumizi *',
                    hintText: 'Mfano: Kununua vifaa vya ofisi',
                    prefixIcon: const Icon(Icons.title_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: _primaryBg,
                  ),
                ),

                const SizedBox(height: 16),

                // Amount Field
                TextField(
                  controller: kiasiController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CurrencyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Kiasi (TZS) *',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.payments_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: _primaryBg,
                  ),
                ),

                const SizedBox(height: 16),

                // Payee Name Field (REQUIRED)
                TextField(
                  controller: payeeNameController,
                  decoration: InputDecoration(
                    labelText: 'Jina la Mpokeaji *',
                    hintText: 'Mfano: Duka la Vifaa ABC',
                    prefixIcon: const Icon(Icons.person_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: _primaryBg,
                  ),
                ),

                const SizedBox(height: 16),

                // Description Field
                TextField(
                  controller: maelezoController,
                  decoration: InputDecoration(
                    labelText: 'Maelezo *',
                    hintText: 'Eleza kwa ufupi matumizi haya (min 10 herufi)',
                    prefixIcon: const Icon(Icons.description_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: _primaryBg,
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _iconBg,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting || selectedAccount == null
                        ? null
                        : () async {
                            // Validate
                            if (selectedAccount == null) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Tafadhali chagua akaunti ya matumizi')),
                              );
                              return;
                            }

                            if (titleController.text.trim().isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Tafadhali ingiza kichwa cha matumizi')),
                              );
                              return;
                            }

                            final amount = double.tryParse(kiasiController.text.replaceAll(',', ''));
                            if (amount == null || amount <= 0) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Tafadhali ingiza kiasi sahihi')),
                              );
                              return;
                            }

                            if (payeeNameController.text.trim().isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Tafadhali ingiza jina la mpokeaji')),
                              );
                              return;
                            }

                            if (maelezoController.text.trim().length < 10) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Maelezo lazima yawe herufi 10 au zaidi')),
                              );
                              return;
                            }

                            if (isSheetMounted) {
                              setSheetState(() => isSubmitting = true);
                            }

                            try {
                              // Create expense request (pending until approved)
                              final response = await HttpService.createExpenseRequest(
                                amount: amount,
                                category: selectedAccount!['code']?.toString() ?? 'general',
                                title: titleController.text.trim(),
                                description: maelezoController.text.trim(),
                                payeeName: payeeNameController.text.trim(),
                              );

                              if (response['success'] == true) {
                                Navigator.pop(context);
                                await _loadMatumizi();
                                if (mounted) {
                                  // Show voting info dialog
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.how_to_vote_rounded, color: Colors.orange.shade700, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text('Ombi Limetumwa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Ombi la matumizi limetumwa kwa wanachama kupiga kura.', style: TextStyle(fontSize: 14)),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text('Matumizi yatarekodishwa baada ya wanachama kukubali.', style: TextStyle(fontSize: 12)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Sawa')),
                                      ],
                                    ),
                                  );
                                }
                              } else {
                                if (isSheetMounted) {
                                  setSheetState(() => isSubmitting = false);
                                }
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(response['message'] ?? 'Imeshindwa kutuma ombi'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (isSheetMounted) {
                                setSheetState(() => isSubmitting = false);
                              }
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Kuna tatizo: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Rekodi Malipo', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        ); // SafeArea
        },
      ),
    ).then((_) {
      isSheetMounted = false; // Mark sheet as closed
    });
  }

  void _showMatumiziDetailsDialog(Map<String, dynamic> matumizi) {
    final description = matumizi['description']?.toString() ?? matumizi['maelezo']?.toString() ?? 'Matumizi';
    final amount = double.tryParse(matumizi['amount']?.toString() ?? matumizi['kiasi']?.toString() ?? '0') ?? 0.0;
    final accountCode = matumizi['account_code']?.toString() ?? matumizi['expense_account_code']?.toString() ?? '';
    final accountName = matumizi['account_name']?.toString() ?? '';
    final date = matumizi['created_at']?.toString() ?? matumizi['date']?.toString();
    final paymentMethod = matumizi['payment_method']?.toString();
    final paidBy = matumizi['paid_by_name']?.toString() ?? matumizi['paid_by']?.toString();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMatumiziIcon(accountName),
                      color: _iconBg,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (accountName.isNotEmpty)
                          Text(accountName, style: const TextStyle(fontSize: 12, color: _secondaryText))
                        else if (accountCode.isNotEmpty)
                          Text(accountCode, style: const TextStyle(fontSize: 12, color: _secondaryText)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Kiasi', formatCurrency.format(amount)),
                    if (accountCode.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Akaunti', accountCode),
                    ],
                    const SizedBox(height: 12),
                    _buildDetailRow('Tarehe', date ?? 'Haijulikani'),
                    if (paymentMethod != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Njia ya Malipo', paymentMethod),
                    ],
                    if (paidBy != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Amelipa', paidBy),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _secondaryText)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText)),
      ],
    );
  }

  void _showAllMatumiziSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Matumizi Yote',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryText),
                              ),
                              Text(
                                '${_matumiziList.length}${_matumiziTotal > 0 ? " / $_matumiziTotal" : ""} • ${formatCurrency.format(_totalMatumizi)}',
                                style: const TextStyle(fontSize: 12, color: _secondaryText),
                              ),
                            ],
                          ),
                        ),
                        // Sort Button
                        IconButton(
                          icon: Icon(
                            _matumiziSortOrder == 'desc'
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: _iconBg,
                          ),
                          tooltip: _matumiziSortOrder == 'desc' ? 'Mpya kwanza' : 'Ya zamani kwanza',
                          onPressed: () {
                            _toggleMatumiziSortOrder();
                            setSheetState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: _secondaryText),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Sort indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded, size: 14, color: _secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          _matumiziSortOrder == 'desc' ? 'Mpya kwanza' : 'Ya zamani kwanza',
                          style: const TextStyle(fontSize: 11, color: _secondaryText),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),

                  // List
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _matumiziList.length + (_matumiziHasMore ? 1 : 0),
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        // Load More button at the end
                        if (index == _matumiziList.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: _loadingMoreMatumizi
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryBg,
                                        foregroundColor: _iconBg,
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.expand_more_rounded),
                                      label: const Text('Pakia zaidi'),
                                      onPressed: () async {
                                        await _loadMoreMatumizi();
                                        setSheetState(() {});
                                      },
                                    ),
                            ),
                          );
                        }
                        final matumizi = _matumiziList[index] as Map<String, dynamic>;
                        return _buildMatumiziCard(matumizi);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVikaoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.event, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Vikao', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: _iconBg),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ongeza kikao kipya')),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (DataStore.vikaoList != null && DataStore.vikaoList.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: DataStore.vikaoList.length > 5 ? 5 : DataStore.vikaoList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final kikao = DataStore.vikaoList[index];
                final title = kikao['title'] ?? kikao['name'] ?? 'Kikao #${index + 1}';
                final date = kikao['date'] ?? kikao['created_at'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _iconBg.withOpacity(0.1),
                    child: Icon(Icons.event, color: _iconBg, size: 20),
                  ),
                  title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    date != null ? 'Tarehe: $date' : 'Tarehe haijawekwa',
                    style: TextStyle(fontSize: 12, color: _secondaryText),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Maelezo ya $title')),
                    );
                  },
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _accentColor),
                  const SizedBox(height: 8),
                  Text('Hakuna vikao', style: TextStyle(color: _secondaryText)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaamuzimSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.gavel, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Maamuzi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: _iconBg),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ongeza uamuzi mpya')),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (DataStore.maamuzimList != null && DataStore.maamuzimList.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: DataStore.maamuzimList.length > 5 ? 5 : DataStore.maamuzimList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final uamuzi = DataStore.maamuzimList[index];
                final title = uamuzi['title'] ?? uamuzi['decision'] ?? 'Uamuzi #${index + 1}';
                final status = uamuzi['status'] ?? 'pending';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _iconBg.withOpacity(0.1),
                    child: Icon(
                      status == 'approved' ? Icons.check_circle : Icons.pending,
                      color: _iconBg,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    title.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    status == 'approved' ? 'Umeidhinishwa' : 'Inasubiri',
                    style: TextStyle(fontSize: 11, color: _secondaryText),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Maelezo ya $title')),
                    );
                  },
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _accentColor),
                  const SizedBox(height: 8),
                  Text('Hakuna maamuzi', style: TextStyle(color: _secondaryText)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarazaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.groups, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Baraza', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: _iconBg),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ongeza baraza jipya')),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (DataStore.barazaList != null && DataStore.barazaList.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: DataStore.barazaList.length > 5 ? 5 : DataStore.barazaList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final baraza = DataStore.barazaList[index];
                final title = baraza['title'] ?? baraza['topic'] ?? 'Baraza #${index + 1}';
                final participants = baraza['participants'] ?? baraza['members'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _iconBg.withOpacity(0.1),
                    child: Icon(Icons.groups, color: _iconBg, size: 20),
                  ),
                  title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    participants != null ? 'Washiriki: $participants' : 'Bonyeza kuona maelezo',
                    style: TextStyle(fontSize: 12, color: _secondaryText),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Maelezo ya $title')),
                    );
                  },
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _accentColor),
                  const SizedBox(height: 8),
                  Text('Hakuna baraza', style: TextStyle(color: _secondaryText)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingLoanApplicationsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mikopo Iliyopitishwa',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText),
                        ),
                        if (_pendingLoanApplications.isNotEmpty)
                          Text(
                            '${_pendingLoanApplications.length} ${_pendingLoanApplications.length == 1 ? "mkopo" : "mikopo"}',
                            style: const TextStyle(fontSize: 11, color: _secondaryText, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_loadingLoanApplications)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: _iconBg),
                    onPressed: _loadPendingLoanApplications,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loadingLoanApplications && _pendingLoanApplications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_pendingLoanApplications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _accentColor),
                  const SizedBox(height: 8),
                  Text('Hakuna mikopo iliyopitishwa', style: TextStyle(color: _secondaryText)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingLoanApplications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final application = _pendingLoanApplications[index];
                return _buildLoanApplicationCard(application);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoanApplicationCard(Map<String, dynamic> application) {
    final applicantName = application['applicantName']?.toString() ?? 'Unknown';
    final productName = application['loanProduct']?['productName']?.toString() ?? 'N/A';
    final principalAmount = double.tryParse(application['loanDetails']?['principalAmount']?.toString() ?? '0') ?? 0.0;
    final monthlyInstallment = double.tryParse(application['calculations']?['monthlyInstallment']?.toString() ?? '0') ?? 0.0;
    final tenure = int.tryParse(application['loanDetails']?['tenure']?.toString() ?? '0') ?? 0;
    final applicationId = application['applicationId']?.toString() ?? '';
    final guarantors = application['guarantors'] as List<dynamic>? ?? [];

    // Get approval status for display
    final approvals = application['approvals'] as Map<String, dynamic>? ?? {};
    final chairmanApproved = approvals['chairman'] as bool? ?? false;
    final secretaryApproved = approvals['secretary'] as bool? ?? false;
    final accountantApproved = approvals['accountant'] as bool? ?? false;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: _primaryBg,
        child: Text(
          applicantName.isNotEmpty ? applicantName[0].toUpperCase() : 'U',
          style: const TextStyle(color: _iconBg, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        applicantName,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(productName, style: const TextStyle(fontSize: 12, color: _secondaryText)),
          const SizedBox(height: 2),
          Text(
            formatCurrency.format(principalAmount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
          ),
        ],
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildLoanDetailRow('Kiasi', formatCurrency.format(principalAmount)),
              const SizedBox(height: 8),
              _buildLoanDetailRow('Muda', '$tenure months'),
              const SizedBox(height: 8),
              _buildLoanDetailRow('Malipo kila mwezi', formatCurrency.format(monthlyInstallment)),
              const SizedBox(height: 8),
              _buildLoanDetailRow('Wadhamini', '${guarantors.length}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Approval Status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _accentColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hali ya Idhini (Approval Status)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
              ),
              const SizedBox(height: 8),
              _buildApprovalRow('Mwenyekiti (Chairman)', chairmanApproved),
              const SizedBox(height: 4),
              _buildApprovalRow('Katibu (Secretary)', secretaryApproved),
              const SizedBox(height: 4),
              _buildApprovalRow('Mhasibu (Accountant)', accountantApproved),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Approved Status Indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mkopo Umeidhinishwa',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inasubiri kutolewa',
                      style: TextStyle(color: Colors.green.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'APPROVED',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Disburse Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDisburseLoanDialog(
              applicationId,
              applicantName,
              principalAmount,
              tenure,
              productName,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _iconBg,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.payments_outlined, size: 20),
            label: const Text('Toa Mkopo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _secondaryText)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText)),
      ],
    );
  }

  Widget _buildApprovalRow(String role, bool approved) {
    return Row(
      children: [
        Icon(
          approved ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: approved ? Colors.green : _accentColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            role,
            style: TextStyle(
              fontSize: 12,
              color: approved ? Colors.green.shade700 : _secondaryText,
              fontWeight: approved ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveLoanApplication(String applicationId, String applicantName, double amount, int tenure, String userRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Idhini Ombi la Mkopo'),
        content: Text('Una uhakika unataka kuidhinisha ombi la mkopo kwa $applicantName?\n\nKama $userRole, idhini yako itahesabiwa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ndiyo, Kubali'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await HttpService.approveLoanApplication(
        applicationId,
        approvedAmount: amount,
        approvedTenure: tenure,
        comments: 'Approved by $userRole',
        approverRole: userRole,
      );

      if (mounted) {
        if (response != null && response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ombi la mkopo limekubaliwa'), backgroundColor: Colors.green),
          );
          _loadPendingLoanApplications();
        } else {
          // Parse error details based on backend response structure
          String errorMessage = 'Imeshindwa kukubali ombi. Tafadhali jaribu tena.';
          List<String> errorDetails = [];

          if (response != null) {
            // Get main message
            if (response['message'] != null) {
              errorMessage = response['message'];
            }

            // Parse validation errors (Map format: {"field": ["error1", "error2"]})
            if (response['errors'] != null && response['errors'] is Map) {
              final errors = response['errors'] as Map;
              for (var entry in errors.entries) {
                if (entry.value is List) {
                  for (var msg in entry.value) {
                    errorDetails.add(msg.toString());
                  }
                } else {
                  errorDetails.add('${entry.key}: ${entry.value}');
                }
              }
            }

            // Parse details object for additional context
            if (response['details'] != null && response['details'] is Map) {
              final details = response['details'] as Map;

              // Show hint if available
              if (details['hint'] != null) {
                errorDetails.add(details['hint'].toString());
              }

              // Show pending guarantors if applicable
              if (details['pendingGuarantors'] != null && details['pendingGuarantors'] is List) {
                final pending = (details['pendingGuarantors'] as List).join(', ');
                if (pending.isNotEmpty) {
                  errorDetails.add('Wadhamini wanaosubiri: $pending');
                }
              }

              // Show rejected guarantors if applicable
              if (details['rejectedGuarantors'] != null && details['rejectedGuarantors'] is List) {
                final rejected = (details['rejectedGuarantors'] as List).join(', ');
                if (rejected.isNotEmpty) {
                  errorDetails.add('Wadhamini waliokataa: $rejected');
                }
              }

              // Show current status if it's a status error
              if (details['currentStatus'] != null) {
                errorDetails.add('Hali ya sasa: ${details['currentStatus']}');
              }
            }
          }

          _showErrorDialog('Idhini Imeshindwa', errorMessage, details: errorDetails);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Kosa',
          'Kuna tatizo limetokea wakati wa kuidhinisha ombi.',
          details: [e.toString()],
        );
      }
    }
  }

  Future<void> _showRejectLoanDialog(String applicationId, String applicantName) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Kataa Ombi la Mkopo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Andika sababu ya kukataa ombi la $applicantName:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Sababu',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kataa'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    try {
      final response = await HttpService.rejectLoanApplication(
        applicationId,
        reason: reasonController.text.trim(),
      );

      if (mounted) {
        if (response != null && response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ombi la mkopo limekataliwa'), backgroundColor: Colors.orange),
          );
          _loadPendingLoanApplications();
        } else {
          // Parse error details based on backend response structure
          String errorMessage = 'Imeshindwa kukataa ombi. Tafadhali jaribu tena.';
          List<String> errorDetails = [];

          if (response != null) {
            if (response['message'] != null) {
              errorMessage = response['message'];
            }

            // Parse validation errors (Map format)
            if (response['errors'] != null && response['errors'] is Map) {
              final errors = response['errors'] as Map;
              for (var entry in errors.entries) {
                if (entry.value is List) {
                  for (var msg in entry.value) {
                    errorDetails.add(msg.toString());
                  }
                } else {
                  errorDetails.add('${entry.key}: ${entry.value}');
                }
              }
            }

            // Parse details object
            if (response['details'] != null && response['details'] is Map) {
              final details = response['details'] as Map;
              if (details['hint'] != null) {
                errorDetails.add(details['hint'].toString());
              }
              if (details['currentStatus'] != null) {
                errorDetails.add('Hali ya sasa: ${details['currentStatus']}');
              }
            }
          }

          _showErrorDialog('Kukataa Kumeshindwa', errorMessage, details: errorDetails);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Kosa',
          'Kuna tatizo limetokea wakati wa kukataa ombi.',
          details: [e.toString()],
        );
      }
    }
  }

  Future<void> _showDisburseLoanDialog(
    String applicationId,
    String applicantName,
    double principalAmount,
    int tenure,
    String productName,
  ) async {
    String selectedPaymentMethod = 'mobile_money';
    final notesController = TextEditingController();
    bool isProcessing = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _iconBg.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payments_outlined, color: _iconBg, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Toa Mkopo'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loan Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muhtasari wa Mkopo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(),
                      _buildSummaryRow('Mwombaji:', applicantName),
                      _buildSummaryRow('Bidhaa:', productName),
                      _buildSummaryRow('Kiasi:', formatCurrency.format(principalAmount)),
                      _buildSummaryRow('Muda:', '$tenure miezi'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method Selection
                const Text(
                  'Njia ya Malipo:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Mobile Money', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('M-Pesa, Tigo Pesa, Airtel Money', style: TextStyle(fontSize: 11)),
                        value: 'mobile_money',
                        groupValue: selectedPaymentMethod,
                        onChanged: isProcessing ? null : (value) {
                          setDialogState(() => selectedPaymentMethod = value!);
                        },
                        dense: true,
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Akaunti ya Benki', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Uhamisho wa benki', style: TextStyle(fontSize: 11)),
                        value: 'bank_transfer',
                        groupValue: selectedPaymentMethod,
                        onChanged: isProcessing ? null : (value) {
                          setDialogState(() => selectedPaymentMethod = value!);
                        },
                        dense: true,
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Taslimu', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Malipo ya moja kwa moja', style: TextStyle(fontSize: 11)),
                        value: 'cash',
                        groupValue: selectedPaymentMethod,
                        onChanged: isProcessing ? null : (value) {
                          setDialogState(() => selectedPaymentMethod = value!);
                        },
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes (Optional)
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Maelezo (Hiari)',
                    hintText: 'Ongeza maelezo yoyote...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                  enabled: !isProcessing,
                ),
                const SizedBox(height: 16),

                // Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kitendo hiki hakiwezi kurudishwa. Fedha zitahamishwa moja kwa moja.',
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isProcessing) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Inahamisha fedha...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context, false),
              child: const Text('Ghairi'),
            ),
            ElevatedButton.icon(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setDialogState(() => isProcessing = true);

                      try {
                        final response = await HttpService.disburseLoan(
                          applicationId,
                          paymentMethod: selectedPaymentMethod,
                          notes: notesController.text.trim().isNotEmpty
                              ? notesController.text.trim()
                              : null,
                        );

                        if (!context.mounted) return;

                        if (response != null && response['status'] == 'success') {
                          Navigator.pop(context, true);
                        } else {
                          setDialogState(() => isProcessing = false);

                          // Show error in dialog
                          String errorMsg = response?['message'] ?? 'Imeshindwa kutoa mkopo';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isProcessing = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Kosa: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _iconBg,
                disabledBackgroundColor: _iconBg.withOpacity(0.5),
              ),
              icon: const Icon(Icons.send, size: 18),
              label: Text(isProcessing ? 'Inatuma...' : 'Toa Mkopo'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Mkopo wa $applicantName umetolewa kikamilifu!')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      _loadPendingLoanApplications(); // Refresh the list
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900)),
        ],
      ),
    );
  }

  Widget _buildPendingWithdrawalsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.pending_actions, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maombi ya Kutoa Akiba',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText),
                        ),
                        if (_pendingWithdrawals.isNotEmpty)
                          Text(
                            '${_pendingWithdrawals.length} ${_pendingWithdrawals.length == 1 ? "ombi" : "maombi"}',
                            style: const TextStyle(fontSize: 11, color: _secondaryText, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_loadingWithdrawals)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: _iconBg),
                    onPressed: _loadPendingWithdrawals,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loadingWithdrawals && _pendingWithdrawals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_pendingWithdrawals.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingWithdrawals.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final withdrawal = _pendingWithdrawals[index];
                final amount = double.tryParse(withdrawal['amount']?.toString() ?? '0') ?? 0.0;
                final memberName = '${withdrawal['member']?['firstName'] ?? ''} ${withdrawal['member']?['lastName'] ?? ''}'.trim();
                final destinationType = withdrawal['destination_type'] ?? '';
                final createdAt = withdrawal['created_at']?.toString() ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _primaryBg,
                    child: Icon(
                      destinationType == 'bank' ? Icons.account_balance : Icons.phone_android,
                      color: _iconBg,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    memberName.isEmpty ? 'Mwanachama' : memberName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatCurrency.format(amount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                      if (createdAt.isNotEmpty)
                        Text(
                          'Tarehe: ${createdAt.split('T').first}',
                          style: TextStyle(fontSize: 11, color: _secondaryText),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        onPressed: () => _showApproveDialog(withdrawal),
                        tooltip: 'Idhinisha',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                        onPressed: () => _showRejectDialog(withdrawal),
                        tooltip: 'Kataa',
                      ),
                    ],
                  ),
                  onTap: () => _showWithdrawalDetails(withdrawal),
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _accentColor),
                  const SizedBox(height: 8),
                  Text('Hakuna maombi ya kusubiri', style: TextStyle(color: _secondaryText)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showWithdrawalDetails(Map<String, dynamic> withdrawal) {
    final amount = double.tryParse(withdrawal['amount']?.toString() ?? '0') ?? 0.0;
    final memberName = '${withdrawal['member']?['firstName'] ?? ''} ${withdrawal['member']?['lastName'] ?? ''}'.trim();
    final userId = withdrawal['userId']?.toString() ?? '';
    final destinationType = withdrawal['destination_type'] ?? '';
    final destinationAccount = withdrawal['destination_account'] ?? '';
    final destinationName = withdrawal['destination_name'] ?? '';
    final description = withdrawal['description'] ?? 'Uondoaji wa Akiba';
    final createdAt = withdrawal['created_at']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maelezo ya Ombi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Jina:', memberName),
              _buildDetailRow('Kiasi:', formatCurrency.format(amount)),
              _buildDetailRow(
                'Njia:',
                destinationType == 'bank' ? 'Benki' : 'Mkoba wa Simu',
              ),
              _buildDetailRow('Akaunti/Simu:', destinationAccount),
              _buildDetailRow('Jina la Mpokeaji:', destinationName),
              _buildDetailRow('Maelezo:', description),
              if (createdAt.isNotEmpty)
                _buildDetailRow('Tarehe:', createdAt.split('T').first),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Funga'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Idhinisha'),
            onPressed: () {
              Navigator.pop(context);
              _showApproveDialog(withdrawal);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Kataa'),
            onPressed: () {
              Navigator.pop(context);
              _showRejectDialog(withdrawal);
            },
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> withdrawal) {
    final amount = double.tryParse(withdrawal['amount']?.toString() ?? '0') ?? 0.0;
    final memberName = '${withdrawal['member']?['firstName'] ?? ''} ${withdrawal['member']?['lastName'] ?? ''}'.trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Idhinisha Ombi'),
          ],
        ),
        content: Text(
          'Una uhakika unataka kuidhinisha ombi la $memberName la kutoa ${formatCurrency.format(amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sitisha'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              _approveWithdrawal(withdrawal);
            },
            child: const Text('Idhinisha'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> withdrawal) {
    final amount = double.tryParse(withdrawal['amount']?.toString() ?? '0') ?? 0.0;
    final memberName = '${withdrawal['member']?['firstName'] ?? ''} ${withdrawal['member']?['lastName'] ?? ''}'.trim();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Kataa Ombi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Una uhakika unataka kukataa ombi la $memberName la kutoa ${formatCurrency.format(amount)}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Sababu (Optional)',
                hintText: 'Eleza sababu ya kukataa',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sitisha'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _rejectWithdrawal(withdrawal, reasonController.text.trim());
            },
            child: const Text('Kataa'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveWithdrawal(Map<String, dynamic> withdrawal) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final requestId = withdrawal['request_id']?.toString() ?? '';
      final response = await HttpService.approveWithdrawal(
        requestId: requestId,
        approvedBy: DataStore.currentUserId ?? '',
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response != null && response['success'] == true) {
        // Reload pending withdrawals
        await _loadPendingWithdrawals();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ombi limeidhinishwa!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['error'] ?? 'Imeshindwa kuidhinisha'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kosa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectWithdrawal(Map<String, dynamic> withdrawal, String reason) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final requestId = withdrawal['request_id']?.toString() ?? '';
      final response = await HttpService.rejectWithdrawal(
        requestId: requestId,
        rejectedBy: DataStore.currentUserId ?? '',
        reason: reason.isEmpty ? null : reason,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response != null && response['success'] == true) {
        // Reload pending withdrawals
        await _loadPendingWithdrawals();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ombi limekataliwa'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['error'] ?? 'Imeshindwa kukataa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kosa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRemoveMemberDialog() {
    final members = DataStore.membersList ?? [];

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hakuna wanachama wa kuondoa')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
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
                    child: const Icon(Icons.person_remove_alt_1_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Futa Uwanachama',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                      ),
                      Text(
                        'Chagua mwanachama wa kuondoa',
                        style: TextStyle(fontSize: 13, color: _secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Members List
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: members.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final name = member['userName'] ?? member['name'] ?? 'Mwanachama';
                  final phone = member['userNumber'] ?? member['phone'] ?? '';
                  final oderId = member['userId'] ?? member['id'] ?? '';
                  final role = member['role'] ?? 'Mjumbe';

                  // Don't allow removing self
                  final isSelf = oderId == DataStore.currentUserId;

                  return ListTile(
                    enabled: !isSelf,
                    leading: CircleAvatar(
                      backgroundColor: isSelf ? _accentColor : _primaryBg,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: TextStyle(
                          color: isSelf ? Colors.white : _iconBg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelf ? _accentColor : _primaryText,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (phone.isNotEmpty)
                          Text(phone, style: const TextStyle(fontSize: 12, color: _secondaryText)),
                        Text(
                          isSelf ? 'Wewe (huwezi kujiondoa)' : role,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelf ? _accentColor : _secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelf
                        ? null
                        : const Icon(Icons.remove_circle_outline, color: _accentColor),
                    onTap: isSelf ? null : () {
                      Navigator.pop(context);
                      _confirmRemoveMember(member);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(Map<String, dynamic> member) {
    final name = member['userName'] ?? member['name'] ?? 'Mwanachama';
    final userId = member['userId'] ?? member['id'] ?? '';
    final reasonController = TextEditingController();
    String selectedRemovalType = 'disciplinary';

    final removalTypes = [
      {'value': 'voluntary', 'label': 'Hiari', 'icon': Icons.volunteer_activism_rounded},
      {'value': 'disciplinary', 'label': 'Nidhamu', 'icon': Icons.gavel_rounded},
      {'value': 'inactive', 'label': 'Kutokuwa Hai', 'icon': Icons.snooze_rounded},
      {'value': 'deceased', 'label': 'Amefariki', 'icon': Icons.sentiment_very_dissatisfied_rounded},
      {'value': 'other', 'label': 'Nyingine', 'icon': Icons.more_horiz_rounded},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Thibitisha Kuondoa', style: TextStyle(fontSize: 16))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: _primaryText),
                    children: [
                      const TextSpan(text: 'Una uhakika unataka kumondoa '),
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' kutoka kwenye kikundi hiki?'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Removal type dropdown
                DropdownButtonFormField<String>(
                  value: selectedRemovalType,
                  decoration: InputDecoration(
                    labelText: 'Aina ya Kuondolewa',
                    prefixIcon: const Icon(Icons.category_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: _primaryBg,
                  ),
                  items: removalTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['value'] as String,
                      child: Row(
                        children: [
                          Icon(type['icon'] as IconData, size: 18, color: _iconBg),
                          const SizedBox(width: 8),
                          Text(type['label'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedRemovalType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Sababu *',
                    hintText: 'Eleza sababu ya kumondoa (angalau herufi 10)',
                    helperText: 'Lazima herufi 10 au zaidi',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: _primaryBg,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _iconBg, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Ombi litahitaji kupitishwa na wanachama wengine',
                          style: TextStyle(fontSize: 12, color: _primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Sitisha', style: TextStyle(color: _secondaryText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _iconBg,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sababu lazima iwe na angalau herufi 10'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _removeMember(userId, name, reason, selectedRemovalType);
              },
              child: const Text('Ondoa'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(String userId, String memberName, String reason, String removalType) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create membership removal request (requires voting approval)
      final response = await HttpService.removeMember(
        kikobaId: DataStore.currentKikobaId ?? '',
        memberId: userId,
        removalType: removalType,
        reason: reason,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response != null && response['success'] == true) {
        if (mounted) {
          _showVotingRequestCreatedDialog(memberName);
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            'Imeshindwa',
            response?['message'] ?? 'Imeshindwa kutuma ombi. Tafadhali jaribu tena.',
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showErrorDialog('Kosa', 'Kuna tatizo limetokea: $e');
      }
    }
  }

  void _showVotingRequestCreatedDialog(String title, [String? message]) {
    // If only title is provided, use it as memberName for backward compatibility
    final dialogTitle = message != null ? title : 'Ombi Limetumwa';
    final dialogMessage = message ?? 'Ombi la kumfuta $title limetumwa kwa wanachama kupiga kura.';
    final infoMessage = message != null
        ? 'Wanachama watapiga kura kukubali au kukataa ombi hili.'
        : 'Mwanachama atafutwa baada ya wanachama wengi kukubali.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.how_to_vote_rounded, color: Colors.green.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dialogTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogMessage,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      infoMessage,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
  }

  void _showCreateVotingCaseDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final optionController = TextEditingController();
    final minVotesController = TextEditingController();
    final thresholdController = TextEditingController();

    bool isSubmitting = false;
    String selectedCategory = 'general';
    String selectedVotingType = 'yes_no';
    List<String> options = [];
    DateTime? selectedDeadline;
    bool showAdvanced = false;

    final categories = [
      {'value': 'general', 'label': 'Kawaida', 'icon': Icons.ballot_rounded},
      {'value': 'policy', 'label': 'Sera/Kanuni', 'icon': Icons.policy_rounded},
      {'value': 'financial', 'label': 'Fedha', 'icon': Icons.attach_money_rounded},
      {'value': 'membership', 'label': 'Uanachama', 'icon': Icons.people_rounded},
      {'value': 'event', 'label': 'Tukio', 'icon': Icons.event_rounded},
      {'value': 'other', 'label': 'Nyingine', 'icon': Icons.more_horiz_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anzisha Kesi ya Kura',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _primaryText),
                          ),
                          Text(
                            'Wasilisha suala kwa wanachama',
                            style: TextStyle(fontSize: 13, color: _secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title field
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Kichwa cha Suala *',
                    hintText: 'Mfano: Kubadili saa za mikutano',
                    prefixIcon: const Icon(Icons.title_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Aina ya Suala',
                    prefixIcon: const Icon(Icons.category_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: categories.map((cat) => DropdownMenuItem(
                    value: cat['value'] as String,
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 20, color: _iconBg),
                        const SizedBox(width: 8),
                        Text(cat['label'] as String),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => setSheetState(() => selectedCategory = value ?? 'general'),
                ),
                const SizedBox(height: 16),

                // Description field
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Maelezo ya Suala *',
                    hintText: 'Eleza kwa ufupi suala unaloleta kwa kura...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description_rounded),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),

                // Voting Type Toggle
                const Text(
                  'Aina ya Kura',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() {
                            selectedVotingType = 'yes_no';
                            options.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedVotingType == 'yes_no' ? _iconBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.thumb_up_alt_rounded,
                                  size: 18,
                                  color: selectedVotingType == 'yes_no' ? Colors.white : _secondaryText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Ndiyo/Hapana',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedVotingType == 'yes_no' ? Colors.white : _secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedVotingType = 'multiple_choice'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedVotingType == 'multiple_choice' ? _iconBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.list_alt_rounded,
                                  size: 18,
                                  color: selectedVotingType == 'multiple_choice' ? Colors.white : _secondaryText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Chaguo Nyingi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedVotingType == 'multiple_choice' ? Colors.white : _secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Multiple choice options
                if (selectedVotingType == 'multiple_choice') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Chaguo za Kura (2-10)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText),
                  ),
                  const SizedBox(height: 8),
                  // Options list
                  if (options.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: index < options.length - 1
                                  ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _iconBg.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _iconBg,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(option, style: const TextStyle(fontSize: 14))),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade400),
                                  onPressed: () => setSheetState(() => options.removeAt(index)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // Add option field
                  if (options.length < 10)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optionController,
                            decoration: InputDecoration(
                              hintText: 'Ingiza chaguo...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty && options.length < 10) {
                                setSheetState(() {
                                  options.add(value.trim());
                                  optionController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final value = optionController.text.trim();
                            if (value.isNotEmpty && options.length < 10) {
                              setSheetState(() {
                                options.add(value);
                                optionController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _iconBg,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                ],

                const SizedBox(height: 16),

                // Deadline picker
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline ?? now.add(const Duration(days: 7)),
                      firstDate: now.add(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(primary: _iconBg),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDeadline = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: _secondaryText),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDeadline != null
                                ? 'Mwisho: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                                : 'Chagua tarehe ya mwisho (si lazima)',
                            style: TextStyle(
                              color: selectedDeadline != null ? _primaryText : _secondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (selectedDeadline != null)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setSheetState(() => selectedDeadline = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Advanced settings toggle
                InkWell(
                  onTap: () => setSheetState(() => showAdvanced = !showAdvanced),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: _secondaryText,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mipangilio ya Ziada',
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Advanced settings
                if (showAdvanced) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minVotesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Kura za Chini',
                            hintText: 'Mfano: 5',
                            prefixIcon: const Icon(Icons.people_outline_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: thresholdController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Asilimia %',
                            hintText: 'Mfano: 66.67',
                            prefixIcon: const Icon(Icons.percent_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acha tupu kutumia mipangilio ya kikoba',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],

                const SizedBox(height: 20),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedVotingType == 'yes_no'
                              ? 'Wanachama watapiga kura Ndiyo au Hapana.'
                              : 'Wanachama watachagua moja kati ya chaguo ulizoongeza.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Ghairi', style: TextStyle(color: _primaryText)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final description = descriptionController.text.trim();

                                if (title.isEmpty || title.length < 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kichwa lazima kiwe na herufi 5 au zaidi'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }
                                if (description.isEmpty || description.length < 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Maelezo lazima yawe na herufi 10 au zaidi'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }
                                if (selectedVotingType == 'multiple_choice' && options.length < 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Ongeza chaguo 2 au zaidi'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);

                                try {
                                  final minVotes = int.tryParse(minVotesController.text.trim());
                                  final threshold = double.tryParse(thresholdController.text.trim());

                                  final response = await HttpService.createVotingCase(
                                    title: title,
                                    description: description,
                                    category: selectedCategory,
                                    votingType: selectedVotingType,
                                    options: selectedVotingType == 'multiple_choice' ? options : null,
                                    minimumVotes: minVotes,
                                    approvalThreshold: threshold,
                                    deadline: selectedDeadline != null
                                        ? '${selectedDeadline!.year}-${selectedDeadline!.month.toString().padLeft(2, '0')}-${selectedDeadline!.day.toString().padLeft(2, '0')}'
                                        : null,
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);

                                    if (response['success'] == true) {
                                      _showVotingRequestCreatedDialog(
                                        'Kesi ya Kura Imeundwa',
                                        'Suala "$title" limewasilishwa kwa wanachama kupiga kura.',
                                      );
                                    } else {
                                      _showErrorDialog(
                                        'Imeshindwa',
                                        response['message'] ?? 'Imeshindwa kuunda kesi ya kura. Tafadhali jaribu tena.',
                                      );
                                    }
                                  }
                                } catch (e) {
                                  setSheetState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Kosa: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _iconBg,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Tuma Suala', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAnzishaMchangoKwaNiabaDialog() {
    final members = DataStore.membersList ?? [];

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hakuna wanachama')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
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
                    child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anzisha Mchango Kwa Niaba',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                      ),
                      Text(
                        'Chagua mwanachama',
                        style: TextStyle(fontSize: 13, color: _secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Members List
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: members.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final name = member['userName'] ?? member['name'] ?? 'Mwanachama';
                  final phone = member['userNumber'] ?? member['phone'] ?? '';
                  final oderId = member['userId'] ?? member['id'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _primaryBg,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          color: _iconBg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: _primaryText),
                    ),
                    subtitle: phone.isNotEmpty
                        ? Text(phone, style: const TextStyle(fontSize: 12, color: _secondaryText))
                        : null,
                    trailing: const Icon(Icons.chevron_right_rounded, color: _accentColor),
                    onTap: () {
                      Navigator.pop(context);
                      _showMchangoFormDialog(member);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMchangoFormDialog(Map<String, dynamic> member) {
    final memberName = member['userName'] ?? member['name'] ?? 'Mwanachama';
    final memberId = member['userId'] ?? member['id'] ?? '';
    final memberPhone = member['userNumber'] ?? member['phone'] ?? '';

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetAmountController = TextEditingController();
    final amountPerPersonController = TextEditingController();
    final tareheController = TextEditingController();
    DateTime? selectedDate;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _iconBg,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Anzisha Mchango Kwa Niaba',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                memberName,
                                style: const TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Member Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _primaryBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _iconBg,
                              child: Text(
                                memberName.isNotEmpty ? memberName[0].toUpperCase() : 'M',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memberName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: _primaryText),
                                  ),
                                  if (memberPhone.isNotEmpty)
                                    Text(
                                      memberPhone,
                                      style: const TextStyle(fontSize: 12, color: _secondaryText),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle, color: _iconBg),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Fields
                      const Text(
                        'Taarifa za Mchango',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryText),
                      ),
                      const SizedBox(height: 16),

                      // Aina ya Mchango
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Aina ya Mchango *',
                          hintText: 'Mfano: Harusi, Msiba, Elimu',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category_rounded),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Maelezo
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Maelezo *',
                          hintText: 'Eleza sababu ya mchango kwa ufupi',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Icons.description_rounded),
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Target Amount
                      TextField(
                        controller: targetAmountController,
                        decoration: InputDecoration(
                          labelText: 'Kiasi cha Lengo (TZS) *',
                          hintText: '500,000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.savings_rounded),
                          prefixText: 'TZS ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CurrencyInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount Per Person
                      TextField(
                        controller: amountPerPersonController,
                        decoration: InputDecoration(
                          labelText: 'Kiasi kwa Kila Mtu (TZS) *',
                          hintText: '10,000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.person_rounded),
                          prefixText: 'TZS ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CurrencyInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: _iconBg,
                                    onPrimary: Colors.white,
                                    surface: _cardBg,
                                    onSurface: _primaryText,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setSheetState(() {
                              selectedDate = picked;
                              tareheController.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: TextField(
                            controller: tareheController,
                            decoration: InputDecoration(
                              labelText: 'Tarehe ya Mwisho *',
                              hintText: 'Chagua tarehe',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.calendar_today_rounded),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                              helperText: selectedDate != null
                                  ? 'Siku ${selectedDate!.difference(DateTime.now()).inDays} kutoka leo'
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: _accentColor),
                        ),
                        child: const Text('Ghairi', style: TextStyle(color: _primaryText)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                // Validate
                                final validationError = _validateMchangoForm(
                                  titleController.text,
                                  descriptionController.text,
                                  targetAmountController.text,
                                  amountPerPersonController.text,
                                  selectedDate,
                                );

                                if (validationError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(validationError), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                setSheetState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  final isChairman = DataStore.userCheo == 'Mwenyekiti';
                                  Map<String, dynamic>? response;

                                  if (isChairman) {
                                    // Chairman can create mchango directly
                                    response = await HttpService.createMchango(
                                      ainayaMchango: titleController.text.trim(),
                                      maelezo: descriptionController.text.trim(),
                                      tarehe: tareheController.text,
                                      targetAmount: double.parse(targetAmountController.text.replaceAll(',', '')),
                                      amountPerPerson: double.parse(amountPerPersonController.text.replaceAll(',', '')),
                                      userId: memberId,
                                      userName: memberName,
                                      mobileNumber: memberPhone,
                                    );
                                  } else {
                                    // Non-chairman: create voting request
                                    response = await HttpService.createMchangoRequest(
                                      title: titleController.text.trim(),
                                      description: descriptionController.text.trim(),
                                      targetAmount: double.parse(targetAmountController.text.replaceAll(',', '')),
                                      amountPerPerson: double.parse(amountPerPersonController.text.replaceAll(',', '')),
                                      deadline: tareheController.text,
                                      beneficiaryId: memberId,
                                      beneficiaryName: memberName,
                                    );
                                  }

                                  if (mounted) {
                                    Navigator.pop(context);

                                    if (response != null && response['success'] == true) {
                                      if (isChairman) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Mchango kwa niaba ya $memberName umeanzishwa!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        // Show voting request created dialog
                                        _showVotingRequestCreatedDialog(
                                          'Ombi la Mchango Limetumwa',
                                          'Ombi la kuanzisha mchango kwa niaba ya $memberName limetumwa kwa wanachama kupiga kura.',
                                        );
                                      }
                                    } else {
                                      _showErrorDialog(
                                        'Imeshindwa',
                                        response?['message'] ?? 'Imeshindwa kuanzisha mchango. Tafadhali jaribu tena.',
                                      );
                                    }
                                  }
                                } catch (e) {
                                  setSheetState(() {
                                    isSubmitting = false;
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Kosa: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _iconBg,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('Tuma Ombi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateMchangoForm(
    String title,
    String description,
    String targetAmount,
    String amountPerPerson,
    DateTime? date,
  ) {
    if (title.trim().isEmpty) {
      return 'Tafadhali ingiza aina ya mchango';
    }
    if (title.trim().length < 3) {
      return 'Aina ya mchango iwe na herufi 3 au zaidi';
    }
    if (description.trim().isEmpty) {
      return 'Tafadhali ingiza maelezo ya mchango';
    }
    if (description.trim().length < 10) {
      return 'Maelezo yawe na herufi 10 au zaidi';
    }
    if (targetAmount.isEmpty) {
      return 'Tafadhali ingiza kiasi cha lengo';
    }
    if (amountPerPerson.isEmpty) {
      return 'Tafadhali ingiza kiasi kwa kila mtu';
    }
    if (date == null) {
      return 'Tafadhali chagua tarehe ya mwisho';
    }

    final target = double.tryParse(targetAmount.replaceAll(',', ''));
    final perPerson = double.tryParse(amountPerPerson.replaceAll(',', ''));

    if (target == null || target < 1000) {
      return 'Kiasi cha lengo kiwe TZS 1,000 au zaidi';
    }
    if (perPerson == null || perPerson < 100) {
      return 'Kiasi kwa mtu kiwe TZS 100 au zaidi';
    }
    if (perPerson > target) {
      return 'Kiasi kwa mtu hakiwezi kuzidi kiasi cha lengo';
    }

    return null;
  }
}

// Currency input formatter for thousand separators
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = newValue.text.replaceAll(',', '');
    final number = int.tryParse(value);
    if (number == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###', 'en_US');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Mchango Report Sheet Widget - displays contributors/non-contributors
class _MchangoReportSheet extends StatefulWidget {
  final Map<String, dynamic> mchango;
  final String mchangoId;
  final String title;
  final ScrollController scrollController;
  final Function(List<dynamic>) onRemind;

  const _MchangoReportSheet({
    required this.mchango,
    required this.mchangoId,
    required this.title,
    required this.scrollController,
    required this.onRemind,
  });

  @override
  State<_MchangoReportSheet> createState() => _MchangoReportSheetState();
}

class _MchangoReportSheetState extends State<_MchangoReportSheet> with SingleTickerProviderStateMixin {
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
  final formatDate = DateFormat('dd MMM yyyy, HH:mm');

  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // Report data
  Map<String, dynamic>? _summary;
  List<dynamic> _contributors = [];
  List<dynamic> _nonContributors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await HttpService.getMchangoReport(widget.mchangoId);

      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _summary = data['summary'] as Map<String, dynamic>?;
            _contributors = data['contributors'] as List<dynamic>? ?? [];
            _nonContributors = data['nonContributors'] as List<dynamic>? ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Data haipo';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = response?['message'] ?? 'Imeshindwa kupata taarifa';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Kuna tatizo limetokea: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ripoti ya Mchango',
                        style: TextStyle(fontSize: 12, color: _secondaryText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _secondaryText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _secondaryText,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.summarize_rounded, size: 16),
                      const SizedBox(width: 4),
                      const Text('Muhtasari'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Wamechangia (${_contributors.length})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending_outlined, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Hawajachangia (${_nonContributors.length})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _iconBg),
                        SizedBox(height: 16),
                        Text('Inapakia taarifa...', style: TextStyle(color: _secondaryText)),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: _accentColor),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _secondaryText),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _iconBg,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _loadReportData,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Jaribu Tena'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSummaryTab(),
                          _buildContributorsTab(),
                          _buildNonContributorsTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final targetAmount = double.tryParse(widget.mchango['kiasi']?.toString() ?? '0') ?? 0.0;
    final collectedAmount = double.tryParse(_summary?['total_collected']?.toString() ?? '0') ?? 0.0;
    final remainingAmount = targetAmount - collectedAmount;
    final progressPercent = targetAmount > 0 ? (collectedAmount / targetAmount * 100).clamp(0, 100) : 0.0;
    final deadline = widget.mchango['mwisho'] ?? widget.mchango['deadline'];
    final reason = widget.mchango['reason']?.toString() ?? '';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Progress card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Maendeleo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText)),
                  Text(
                    '${progressPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: progressPercent >= 100 ? Colors.green.shade700 : _primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 8,
                  backgroundColor: _accentColor.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation(
                    progressPercent >= 100 ? Colors.green : _iconBg,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Lengo',
                      formatCurrency.format(targetAmount),
                      Icons.flag_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      'Imekusanywa',
                      formatCurrency.format(collectedAmount),
                      Icons.savings_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Imebaki',
                      formatCurrency.format(remainingAmount > 0 ? remainingAmount : 0),
                      Icons.pending_rounded,
                    ),
                  ),
                  if (deadline != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryItem(
                        'Mwisho',
                        deadline.toString(),
                        Icons.calendar_today_rounded,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status card
        if (reason.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: reason == 'target_reached'
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: reason == 'target_reached'
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  reason == 'target_reached'
                      ? Icons.check_circle_rounded
                      : Icons.access_time_rounded,
                  color: reason == 'target_reached'
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason == 'target_reached' ? 'Lengo Limefikiwa' : 'Muda Umepita',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: reason == 'target_reached'
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason == 'target_reached'
                            ? 'Mchango uko tayari kusindikwa'
                            : 'Tarehe ya mwisho imepita, mchango uko tayari kusindikwa',
                        style: TextStyle(
                          fontSize: 12,
                          color: reason == 'target_reached'
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Counts card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCountItem(
                  'Waliochangia',
                  _contributors.length.toString(),
                  Icons.people_rounded,
                  Colors.green.shade700,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: _accentColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildCountItem(
                  'Hawajachangia',
                  _nonContributors.length.toString(),
                  Icons.person_off_rounded,
                  Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _iconBg),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: _secondaryText)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCountItem(String label, String count, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              count,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _secondaryText)),
      ],
    );
  }

  Widget _buildContributorsTab() {
    if (_contributors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: _accentColor),
            const SizedBox(height: 16),
            const Text(
              'Hakuna waliochangia bado',
              style: TextStyle(fontSize: 16, color: _secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _contributors.length,
      itemBuilder: (context, index) {
        final contributor = _contributors[index] as Map<String, dynamic>;
        final name = contributor['name']?.toString() ?? contributor['userName']?.toString() ?? 'Mwanachama';
        final phone = contributor['phone']?.toString() ?? contributor['mobile']?.toString() ?? '';
        final amount = double.tryParse(contributor['amount_paid']?.toString() ?? contributor['amount']?.toString() ?? '0') ?? 0.0;
        final paidAt = contributor['paid_at']?.toString() ?? contributor['date']?.toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: const TextStyle(fontSize: 12, color: _secondaryText),
                      ),
                    if (paidAt != null)
                      Text(
                        paidAt,
                        style: const TextStyle(fontSize: 11, color: _accentColor),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency.format(amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Amechangia',
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNonContributorsTab() {
    return Column(
      children: [
        // Send reminders button
        if (_nonContributors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _iconBg,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onRemind(_nonContributors);
                },
                icon: const Icon(Icons.notifications_active_rounded, size: 20),
                label: Text('Tuma Vikumbusho (${_nonContributors.length})'),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Non-contributors list
        Expanded(
          child: _nonContributors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration_rounded, size: 64, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Wote wamechangia!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hakuna anayesubiri kuchangia',
                        style: TextStyle(fontSize: 14, color: _secondaryText),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _nonContributors.length,
                  itemBuilder: (context, index) {
                    final person = _nonContributors[index] as Map<String, dynamic>;
                    final name = person['name']?.toString() ?? person['userName']?.toString() ?? 'Mwanachama';
                    final phone = person['phone']?.toString() ?? person['mobile']?.toString() ?? '';
                    final expectedAmount = double.tryParse(person['expected_amount']?.toString() ?? person['amount']?.toString() ?? '0') ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
                                    style: const TextStyle(fontSize: 12, color: _secondaryText),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency.format(expectedAmount),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Anasubiri',
                                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
