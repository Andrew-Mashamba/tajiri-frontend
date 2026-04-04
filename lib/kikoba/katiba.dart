import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'DataStore.dart';
import 'HttpService.dart';
import 'models/voting_models.dart';
import 'services/katiba_cache_service.dart';

final Logger _katibaLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    printTime: true,
  ),
);

class katiba extends StatefulWidget {
  const katiba({super.key});

  @override
  State<katiba> createState() => _KatibaState();
}

class _KatibaState extends State<katiba> with AutomaticKeepAliveClientMixin<katiba> {
  @override
  bool get wantKeepAlive => true;

  // Minimalist monochrome color palette
  static const Color primaryColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFF666666);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color secondaryTextColor = Color(0xFF666666);

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'en_US');

  String? _loadingSection;
  List<KatibaChangeRequest> _pendingChanges = [];
  bool _loadingPendingChanges = false;
  bool _isInitialLoading = true;
  bool _hasCachedData = false;

  // Firestore listener for real-time notifications
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  // Get if user is chairman
  bool get _isChairman => DataStore.userCheo == 'Mwenyekiti';

  @override
  void initState() {
    super.initState();

    // Fetch fresh data from backend when page opens
    _fetchDataFromBackend();

    // Set up Firestore listener to get notified of changes
    _setupFirestoreListener();

    // Check for pending vote request from notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingVoteRequest();
    });
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
      _katibaLogger.e('[KATIBA] Connectivity check error: $e');
      return true; // Assume connected on error
    }
  }

  /// Fetch all katiba data - uses cache for instant display, then fetches fresh
  Future<void> _fetchDataFromBackend({bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId ?? '';
    _katibaLogger.i('[KATIBA] Fetching data (forceRefresh: $forceRefresh)...');

    // 1. Try to show cached data immediately (instant display)
    if (!forceRefresh && !_hasCachedData) {
      final cached = await KatibaCacheService.getKatiba(kikobaId);
      if (cached != null) {
        _katibaLogger.i('[KATIBA] Showing cached data instantly');
        HttpService.updateKatibaDataStore(cached);
        _lastKnownVersion = await KatibaCacheService.getVersion(kikobaId);
        if (mounted) {
          setState(() {
            _hasCachedData = true;
            _isInitialLoading = false; // Show content immediately
          });
        }
      }
    }

    // 2. Check connectivity before fetching
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _katibaLogger.w('[KATIBA] No internet connection');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        if (_hasCachedData) {
          _showConnectivitySnackbar();
        }
      }
      return;
    }

    // 3. Fetch fresh data from backend
    try {
      final result = await HttpService.getKatibaData();
      _katibaLogger.i('[KATIBA] Backend fetch: ${result['success'] ? 'SUCCESS' : 'FAILED'}');

      if (result['success'] == true && result['data'] != null) {
        // Cache the fresh data
        await KatibaCacheService.saveKatiba(kikobaId, result['data']);

        // Log loan products for debugging
        final data = result['data'];
        _katibaLogger.i('[KATIBA] ══════ LOAN PRODUCTS DEBUG ══════');
        _katibaLogger.i('[KATIBA] loan_products (snake): ${data['loan_products']}');
        _katibaLogger.i('[KATIBA] loanProducts (camel): ${data['loanProducts']}');
        _katibaLogger.i('[KATIBA] DataStore.loanProducts: ${DataStore.loanProducts}');
        _katibaLogger.i('[KATIBA] loanProducts count: ${DataStore.loanProducts?.length ?? 0}');
        _katibaLogger.i('[KATIBA] ══════════════════════════════════');
      } else {
        _katibaLogger.w('[KATIBA] ${result['message']}');
      }

      // Also load pending changes
      await _loadPendingChanges();

    } catch (e) {
      _katibaLogger.e('[KATIBA] Error fetching data: $e');
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

  /// Set up Firestore listener with version-based refresh
  /// Only fetches from backend if version actually changed
  void _setupFirestoreListener() {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null || kikobaId.isEmpty) {
      _katibaLogger.w('[KATIBA] No kikoba ID, skipping Firestore listener');
      return;
    }

    _katibaLogger.i('[KATIBA] Setting up Firestore listener for kikoba: $kikobaId');

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('KatibaUpdates')
        .doc(kikobaId)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!snapshot.exists || _isInitialLoading) return;

        // Get version from Firestore document
        final data = snapshot.data();
        final newVersion = data?['version'] as int?;
        final updatedAt = data?['updatedAt'];

        // Use version if available, otherwise use updatedAt timestamp hash
        final effectiveVersion = newVersion ?? updatedAt?.hashCode;

        // Only refresh if version actually changed
        if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
          _katibaLogger.i('[KATIBA] Version changed: $_lastKnownVersion -> $effectiveVersion, refreshing...');
          _lastKnownVersion = effectiveVersion;

          // Save version for future comparison
          await KatibaCacheService.saveVersion(kikobaId, effectiveVersion);

          // Fetch fresh data
          _fetchDataFromBackend(forceRefresh: true);
        } else {
          _katibaLogger.d('[KATIBA] Version unchanged, skipping refresh');
        }
      },
      onError: (error) {
        _katibaLogger.e('[KATIBA] Firestore listener error: $error');
      },
    );
  }

  void _checkPendingVoteRequest() {
    final requestId = DataStore.pendingVoteRequestId;
    if (requestId != null && requestId.isNotEmpty) {
      // Clear it so it doesn't show again
      DataStore.pendingVoteRequestId = null;

      // Wait for pending changes to load if not loaded yet
      if (_pendingChanges.isEmpty) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _showVotingSheetForRequest(requestId);
        });
      } else {
        _showVotingSheetForRequest(requestId);
      }
    }
  }

  void _showVotingSheetForRequest(String requestId) {
    if (_pendingChanges.isEmpty) return;

    // Find the pending change with this request ID
    KatibaChangeRequest? change;
    try {
      change = _pendingChanges.firstWhere((c) => c.id == requestId);
    } catch (_) {
      // If not found by ID, show the first pending change
      change = _pendingChanges.first;
    }

    if (change != null) {
      _showVotingBottomSheet(change);
    }
  }

  void _showVotingBottomSheet(KatibaChangeRequest change) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.how_to_vote_rounded,
                        color: Colors.orange.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Piga Kura',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Ombi la Kubadili Katiba',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Change details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        change.changeTypeDisplay,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Imeombwa na ${change.requesterName}',
                        style: const TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        change.reason,
                        style: const TextStyle(fontSize: 13, color: textColor),
                      ),
                      if (change.votingSummary != null) ...[
                        const SizedBox(height: 12),
                        _buildVotingProgress(change.votingSummary!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Vote buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _castVote(change, VoteValue.no);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text('Kataa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _castVote(change, VoteValue.yes);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Kubali', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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

  Future<void> _loadPendingChanges() async {
    if (_loadingPendingChanges) return;
    setState(() => _loadingPendingChanges = true);
    try {
      final result = await HttpService.getPendingKatibaChanges();
      if (result['success'] == true && result['data'] != null) {
        final list = result['data'] is List ? result['data'] as List : [];
        setState(() {
          _pendingChanges = list
              .map((json) => KatibaChangeRequest.fromJson(json))
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => _loadingPendingChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isInitialLoading
                  ? _buildLoadingState()
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: primaryColor,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info banner for non-chairman
                            if (!_isChairman) _buildInfoBanner(),
                            // Pending changes section (for all members to vote)
                            if (_pendingChanges.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildPendingChangesSection(),
                            ],
                            const SizedBox(height: 16),
                            // Contributions Section
                            _buildSectionHeader('Michango'),
                            const SizedBox(height: 12),
                            _buildContributionsSection(),
                            const SizedBox(height: 24),
                            // Fines Section
                            _buildSectionHeader('Faini'),
                            const SizedBox(height: 12),
                            _buildFinesSection(),
                            const SizedBox(height: 24),
                            // Loans & Interest Section
                            _buildSectionHeader('Mikopo'),
                            const SizedBox(height: 12),
                            _buildLoansSection(),
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

  Future<void> _refreshData() async {
    _katibaLogger.i('[REFRESH] Pull-to-refresh triggered');

    // Check connectivity first
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _katibaLogger.w('[REFRESH] No internet connection');
      _showConnectivitySnackbar();
      return;
    }

    // Refresh katiba data from dedicated endpoint
    _katibaLogger.d('[REFRESH] Fetching katiba data from server...');
    final result = await HttpService.getKatibaData();
    _katibaLogger.d('[REFRESH] Katiba data refresh: ${result['success'] ? 'SUCCESS' : 'FAILED'}');

    // Cache the fresh data
    if (result['success'] == true && result['data'] != null) {
      final kikobaId = DataStore.currentKikobaId ?? '';
      await KatibaCacheService.saveKatiba(kikobaId, result['data']);
    }

    // Refresh pending katiba changes (voting items)
    _katibaLogger.d('[REFRESH] Fetching pending changes...');
    await _loadPendingChanges();

    if (mounted) {
      setState(() {});
      _katibaLogger.i('[REFRESH] UI updated');
    }
  }

  void _showResultSnackbar(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: success ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: success ? 4 : 5),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Section header skeleton
          _buildSkeletonBox(width: 100, height: 20),
          const SizedBox(height: 12),
          // Cards skeleton
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          const SizedBox(height: 24),
          // Section header skeleton
          _buildSkeletonBox(width: 80, height: 20),
          const SizedBox(height: 12),
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          const SizedBox(height: 24),
          // Section header skeleton
          _buildSkeletonBox(width: 90, height: 20),
          const SizedBox(height: 12),
          _buildSkeletonCard(),
          _buildSkeletonCard(),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildSkeletonBox(width: 40, height: 40, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonBox(width: 120, height: 14),
                const SizedBox(height: 6),
                _buildSkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
          _buildSkeletonBox(width: 60, height: 16),
        ],
      ),
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
      onEnd: () {
        // Restart animation (creates shimmer effect)
      },
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
              color: primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Katiba',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                'Sheria na taratibu za kikoba',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: accentColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mwenyekiti pekee anaweza kubadilisha sheria',
              style: TextStyle(fontSize: 12, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingChangesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote_rounded, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Mabadiliko Yanasubiri Kura (${_pendingChanges.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_loadingPendingChanges)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_pendingChanges.map((change) => _buildPendingChangeCard(change))),
      ],
    );
  }

  Widget _buildPendingChangeCard(KatibaChangeRequest change) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      change.changeTypeDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Imeombwa na ${change.requesterName}',
                      style: const TextStyle(fontSize: 10, color: secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            change.reason,
            style: const TextStyle(fontSize: 12, color: secondaryTextColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (change.votingSummary != null) ...[
            const SizedBox(height: 10),
            _buildVotingProgress(change.votingSummary!),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _castVote(change, VoteValue.no),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Kataa', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _castVote(change, VoteValue.yes),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Kubali', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotingProgress(VotingSummary summary) {
    final total = summary.yesCount + summary.noCount;
    final percent = total > 0 ? (summary.yesCount / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kura: ${summary.yesCount} Ndio, ${summary.noCount} Hapana',
              style: const TextStyle(fontSize: 11, color: secondaryTextColor),
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: percent >= 50 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: const Color(0xFFE5E5E5),
            valueColor: AlwaysStoppedAnimation(
              percent >= 50 ? Colors.green : Colors.orange,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Future<void> _castVote(KatibaChangeRequest change, String vote) async {
    // Show loading
    setState(() => _loadingSection = 'vote_${change.id}');
    try {
      final result = await HttpService.castVote(
        voteableType: VoteableType.katibaChange,
        voteableId: change.id,
        vote: vote,
      );

      if (mounted) {
        _showResultSnackbar(
          result['success'] == true,
          result['message'] ?? (result['success'] == true
              ? 'Kura yako imehifadhiwa'
              : 'Tatizo limetokea'),
        );
        // Refresh pending changes
        await _loadPendingChanges();
      }
    } finally {
      if (mounted) setState(() => _loadingSection = null);
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
          color: textColor,
        ),
      ),
    );
  }

  // ==================== CONTRIBUTIONS SECTION ====================

  Widget _buildContributionsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKiingilioCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildAdaCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildHisaCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildAkibaCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildKiingilioCard() {
    final isActive = DataStore.kiingilioStatus == "1";
    final amount = DataStore.kiingilio;

    return _buildSettingCard(
      icon: Icons.person_add_rounded,
      title: 'Kiingilio',
      subtitle: 'Entry Fee',
      value: isActive ? 'TZS ${_currencyFormat.format(double.tryParse(amount) ?? 0)}' : 'Hakuna',
      isActive: isActive,
      onTap: _isChairman ? () => _showKiingilioSheet() : null,
      isLoading: _loadingSection == 'kiingilio',
    );
  }

  Widget _buildAdaCard() {
    final isActive = DataStore.adaStatus == "1";
    final amount = DataStore.ada;

    return _buildSettingCard(
      icon: Icons.calendar_month_rounded,
      title: 'Ada',
      subtitle: 'Monthly Fee',
      value: isActive ? 'TZS ${_currencyFormat.format(double.tryParse(amount) ?? 0)}' : 'Hakuna',
      isActive: isActive,
      onTap: _isChairman ? () => _showAdaSheet() : null,
      isLoading: _loadingSection == 'ada',
    );
  }

  Widget _buildHisaCard() {
    final isActive = DataStore.hisaStatus == "1";
    final amount = DataStore.Hisa;

    return _buildSettingCard(
      icon: Icons.pie_chart_rounded,
      title: 'Hisa',
      subtitle: 'Shares',
      value: isActive ? 'TZS ${_currencyFormat.format(double.tryParse(amount) ?? 0)}' : 'Hakuna',
      isActive: isActive,
      onTap: _isChairman ? () => _showHisaSheet() : null,
      isLoading: _loadingSection == 'hisa',
    );
  }

  Widget _buildAkibaCard() {
    // Akiba typically doesn't have a fixed amount - it's savings
    return _buildSettingCard(
      icon: Icons.savings_rounded,
      title: 'Akiba',
      subtitle: 'Savings',
      value: 'Bila Kikomo',
      isActive: true,
      onTap: null, // Akiba is always enabled
      isLoading: false,
    );
  }

  // ==================== FINES SECTION ====================

  Widget _buildFinesSection() {
    return Column(
      children: [
        _buildFineCard(
          title: 'Faini Vikao',
          subtitle: 'Kuchelewa/Kutokuhudhuria vikao',
          status: DataStore.fainiVikaoStatus,
          amount: DataStore.fainiVikao,
          onTap: _isChairman ? () => _showFainiSheet('vikao') : null,
          isLoading: _loadingSection == 'faini_vikao',
        ),
        const SizedBox(height: 8),
        _buildFineCard(
          title: 'Faini Ada',
          subtitle: 'Kuchelewa kulipa ada',
          status: DataStore.faini_adaStatus,
          amount: DataStore.faini_ada,
          onTap: _isChairman ? () => _showFainiSheet('ada') : null,
          isLoading: _loadingSection == 'faini_ada',
        ),
        const SizedBox(height: 8),
        _buildFineCard(
          title: 'Faini Hisa',
          subtitle: 'Kuchelewa kununua hisa',
          status: DataStore.faini_hisaStatus,
          amount: DataStore.faini_hisa,
          onTap: _isChairman ? () => _showFainiSheet('hisa') : null,
          isLoading: _loadingSection == 'faini_hisa',
        ),
        const SizedBox(height: 8),
        _buildFineCard(
          title: 'Faini Michango',
          subtitle: 'Kuchelewa kutoa mchango',
          status: DataStore.faini_michangoStatus,
          amount: DataStore.faini_michango,
          onTap: _isChairman ? () => _showFainiSheet('michango') : null,
          isLoading: _loadingSection == 'faini_michango',
        ),
      ],
    );
  }

  Widget _buildFineCard({
    required String title,
    required String subtitle,
    required String? status,
    required String? amount,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    // Status "1" means enabled/active, "0" means disabled
    final isActive = status == "1" || status == "1.0" || status == 1.toString();
    final displayAmount = amount ?? "0";

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : const Color(0xFFF0F0F0),
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
                        Icons.gavel_rounded,
                        color: isActive ? Colors.white : accentColor,
                        size: 18,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLoading ? accentColor : textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10, color: secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                isActive
                    ? 'TZS ${_currencyFormat.format(double.tryParse(displayAmount) ?? 0)}'
                    : 'Hakuna',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? primaryColor : accentColor,
                ),
              ),
              if (_isChairman && !isLoading) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: accentColor, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== LOANS SECTION ====================

  Widget _buildLoansSection() {
    return _buildLoanProductsCard();
  }

  Widget _buildLoanProductsCard() {
    final loanProducts = DataStore.loanProducts ?? [];

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isChairman ? () => _showLoanProductsSheet() : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aina ya Mikopo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loanProducts.isEmpty
                          ? 'Hakuna bidhaa zilizosajiliwa'
                          : '${loanProducts.length} bidhaa',
                      style: const TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              if (_isChairman)
                const Icon(Icons.chevron_right_rounded, color: accentColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== GENERIC SETTING CARD ====================

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isActive,
    required VoidCallback? onTap,
    required bool isLoading,
    bool isWide = false,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isWide ? 14 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isWide ? 40 : 36,
                    height: isWide ? 40 : 36,
                    decoration: BoxDecoration(
                      color: isActive ? primaryColor : const Color(0xFFF0F0F0),
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
                            color: isActive ? Colors.white : accentColor,
                            size: isWide ? 20 : 18,
                          ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isLoading ? accentColor : textColor,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 11, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isActive ? primaryColor : accentColor,
                      ),
                    ),
                    if (_isChairman && !isLoading) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: accentColor, size: 22),
                    ],
                  ],
                ],
              ),
              if (!isWide) ...[
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isLoading ? accentColor : textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: secondaryTextColor),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? primaryColor : accentColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BOTTOM SHEETS ====================

  void _showKiingilioSheet() {
    final controller = TextEditingController(
      text: DataStore.kiingilioStatus == "1" ? DataStore.kiingilio : '',
    );
    bool isActive = DataStore.kiingilioStatus == "1";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _buildEditSheet(
          title: 'Kiingilio',
          subtitle: 'Ada ya kujiunga na kikoba',
          icon: Icons.person_add_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggleRow(
                isActive: isActive,
                onChanged: (value) => setSheetState(() => isActive = value),
              ),
              if (isActive) ...[
                const SizedBox(height: 16),
                _buildAmountField(controller, 'Kiasi cha Kiingilio'),
              ],
            ],
          ),
          onSave: () async {
            Navigator.pop(context);
            setState(() => _loadingSection = 'kiingilio');
            try {
              final amount = isActive ? controller.text.replaceAll(',', '') : '0';
              final status = isActive ? '0' : '1';
              final result = await HttpService.requestKiingilioChange(amount, status);
              if (mounted) {
                _showResultSnackbar(result['success'], result['message']);
              }
            } finally {
              if (mounted) setState(() => _loadingSection = null);
            }
          },
        ),
      ),
    );
  }

  void _showAdaSheet() {
    final controller = TextEditingController(
      text: DataStore.adaStatus == "1" ? DataStore.ada : '',
    );
    bool isActive = DataStore.adaStatus == "1";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _buildEditSheet(
          title: 'Ada',
          subtitle: 'Mchango wa kila mwezi',
          icon: Icons.calendar_month_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggleRow(
                isActive: isActive,
                onChanged: (value) => setSheetState(() => isActive = value),
              ),
              if (isActive) ...[
                const SizedBox(height: 16),
                _buildAmountField(controller, 'Kiasi cha Ada'),
              ],
            ],
          ),
          onSave: () async {
            Navigator.pop(context);
            setState(() => _loadingSection = 'ada');
            try {
              final amount = isActive ? controller.text.replaceAll(',', '') : '0';
              final status = isActive ? '0' : '1';
              final result = await HttpService.requestAdaChange(amount, status);
              if (mounted) {
                _showResultSnackbar(result['success'], result['message']);
              }
            } finally {
              if (mounted) setState(() => _loadingSection = null);
            }
          },
        ),
      ),
    );
  }

  void _showHisaSheet() {
    final controller = TextEditingController(
      text: DataStore.hisaStatus == "1" ? DataStore.Hisa : '',
    );
    bool isActive = DataStore.hisaStatus == "1";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _buildEditSheet(
          title: 'Hisa',
          subtitle: 'Kiasi cha hisa kwa mwezi',
          icon: Icons.pie_chart_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggleRow(
                isActive: isActive,
                onChanged: (value) => setSheetState(() => isActive = value),
              ),
              if (isActive) ...[
                const SizedBox(height: 16),
                _buildAmountField(controller, 'Kiasi cha Hisa'),
              ],
            ],
          ),
          onSave: () async {
            Navigator.pop(context);
            setState(() => _loadingSection = 'hisa');
            try {
              final amount = isActive ? controller.text.replaceAll(',', '') : '0';
              final status = isActive ? '0' : '1';
              final result = await HttpService.requestHisaChange(amount, status);
              if (mounted) {
                _showResultSnackbar(result['success'], result['message']);
              }
            } finally {
              if (mounted) setState(() => _loadingSection = null);
            }
          },
        ),
      ),
    );
  }

  void _showFainiSheet(String fineType) {
    _katibaLogger.i('╔════════════════════════════════════════════════════════════');
    _katibaLogger.i('║ [FAINI SHEET] Opening bottom sheet for fineType: $fineType');
    _katibaLogger.i('╚════════════════════════════════════════════════════════════');

    String? currentStatus;
    String? currentAmount;
    String title;
    String subtitle;
    Future<String> Function(String, String) saveFunction;

    switch (fineType) {
      case 'vikao':
        currentStatus = DataStore.fainiVikaoStatus;
        currentAmount = DataStore.fainiVikao;
        title = 'Faini Vikao';
        subtitle = 'Faini ya kutokuhudhuria vikao';
        saveFunction = HttpService.saveFainiVikao;
        _katibaLogger.d('[FAINI SHEET] Vikao - currentStatus: $currentStatus, currentAmount: $currentAmount');
        break;
      case 'ada':
        currentStatus = DataStore.faini_adaStatus;
        currentAmount = DataStore.faini_ada;
        title = 'Faini Ada';
        subtitle = 'Faini ya kuchelewa kulipa ada';
        saveFunction = HttpService.saveFainiAda;
        _katibaLogger.d('[FAINI SHEET] Ada - currentStatus: $currentStatus, currentAmount: $currentAmount');
        break;
      case 'hisa':
        currentStatus = DataStore.faini_hisaStatus;
        currentAmount = DataStore.faini_hisa;
        title = 'Faini Hisa';
        subtitle = 'Faini ya kuchelewa kununua hisa';
        saveFunction = HttpService.saveFainiHisa;
        _katibaLogger.d('[FAINI SHEET] Hisa - currentStatus: $currentStatus, currentAmount: $currentAmount');
        break;
      case 'michango':
        currentStatus = DataStore.faini_michangoStatus;
        currentAmount = DataStore.faini_michango;
        title = 'Faini Michango';
        subtitle = 'Faini ya kuchelewa kutoa mchango';
        saveFunction = HttpService.saveFainiMichango;
        _katibaLogger.d('[FAINI SHEET] Michango - currentStatus: $currentStatus, currentAmount: $currentAmount');
        break;
      default:
        _katibaLogger.w('[FAINI SHEET] Unknown fineType: $fineType - returning early');
        return;
    }

    final controller = TextEditingController(
      text: currentStatus == "1" ? currentAmount : '',
    );
    bool isActive = currentStatus == "1";

    _katibaLogger.d('[FAINI SHEET] Initial values - isActive: $isActive, controller.text: ${controller.text}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _buildEditSheet(
          title: title,
          subtitle: subtitle,
          icon: Icons.gavel_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggleRow(
                isActive: isActive,
                onChanged: (value) {
                  _katibaLogger.d('[FAINI SHEET] Toggle changed: $isActive -> $value');
                  setSheetState(() => isActive = value);
                },
              ),
              if (isActive) ...[
                const SizedBox(height: 16),
                _buildAmountField(controller, 'Kiasi cha Faini'),
              ],
            ],
          ),
          onSave: () async {
            _katibaLogger.i('╔════════════════════════════════════════════════════════════');
            _katibaLogger.i('║ [HIFADHI CLICKED] Save button pressed for $fineType');
            _katibaLogger.i('╚════════════════════════════════════════════════════════════');

            _katibaLogger.d('[HIFADHI] Raw input values:');
            _katibaLogger.d('  - controller.text: "${controller.text}"');
            _katibaLogger.d('  - isActive: $isActive');

            Navigator.pop(context);
            _katibaLogger.d('[HIFADHI] Bottom sheet closed');

            setState(() => _loadingSection = 'faini_$fineType');
            _katibaLogger.d('[HIFADHI] Loading state set: faini_$fineType');

            try {
              final amount = isActive ? controller.text.replaceAll(',', '') : '0';
              final status = isActive ? '0' : '1';

              _katibaLogger.i('[HIFADHI] Prepared values for API:');
              _katibaLogger.i('  - fineCategory: $fineType');
              _katibaLogger.i('  - amount: $amount');
              _katibaLogger.i('  - status: $status (0=active, 1=inactive)');
              _katibaLogger.i('  - DataStore.currentUserId: ${DataStore.currentUserId}');
              _katibaLogger.i('  - DataStore.currentKikobaId: ${DataStore.currentKikobaId}');

              _katibaLogger.i('[HIFADHI] ➤ Calling HttpService.requestFainiChange()...');
              final stopwatch = Stopwatch()..start();

              final result = await HttpService.requestFainiChange(
                fineCategory: fineType,
                amount: amount,
                status: status,
              );

              stopwatch.stop();
              _katibaLogger.i('[HIFADHI] ✓ API call completed in ${stopwatch.elapsedMilliseconds}ms');
              _katibaLogger.i('[HIFADHI] Result: $result');
              _katibaLogger.i('  - success: ${result['success']}');
              _katibaLogger.i('  - message: ${result['message']}');
              _katibaLogger.i('  - caseId: ${result['caseId']}');

              if (mounted) {
                _katibaLogger.d('[HIFADHI] Showing result snackbar');
                _showResultSnackbar(result['success'], result['message']);
              }
            } catch (e, stackTrace) {
              _katibaLogger.e('[HIFADHI] ✗ Error occurred: $e');
              _katibaLogger.e('[HIFADHI] Stack trace: $stackTrace');
            } finally {
              if (mounted) {
                setState(() => _loadingSection = null);
                _katibaLogger.d('[HIFADHI] Loading state cleared');
              }
              _katibaLogger.i('[HIFADHI] ════════════════ END ════════════════');
            }
          },
        ),
      ),
    );
  }

  void _showLoanProductsSheet() {
    final loanProducts = List<dynamic>.from(DataStore.loanProducts ?? []);

    _katibaLogger.i('[KATIBA] ══════ SHOWING LOAN PRODUCTS SHEET ══════');
    _katibaLogger.i('[KATIBA] DataStore.loanProducts: ${DataStore.loanProducts}');
    _katibaLogger.i('[KATIBA] loanProducts list: $loanProducts');
    _katibaLogger.i('[KATIBA] loanProducts count: ${loanProducts.length}');
    if (loanProducts.isNotEmpty) {
      for (int i = 0; i < loanProducts.length; i++) {
        _katibaLogger.i('[KATIBA] Product[$i]: ${loanProducts[i]}');
      }
    }
    _katibaLogger.i('[KATIBA] ═══════════════════════════════════════════');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSheetHeader('Aina ya Mikopo', Icons.account_balance_rounded),
              Expanded(
                child: loanProducts.isEmpty
                    ? _buildEmptyProductsState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: loanProducts.length,
                        itemBuilder: (context, index) {
                          final product = loanProducts[index];
                          return _buildProductItem(product, index);
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToLoanProductForm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text(
                      'Ongeza Bidhaa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: accentColor),
          SizedBox(height: 12),
          Text(
            'Hakuna bidhaa za mikopo',
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
          SizedBox(height: 4),
          Text(
            'Bonyeza "Ongeza Bidhaa" kuanza',
            style: TextStyle(fontSize: 12, color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']?.toString() ?? 'Unnamed',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TZS ${_currencyFormat.format(product['minAmount'] ?? 0)} - ${_currencyFormat.format(product['maxAmount'] ?? 0)}',
                  style: const TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
                Text(
                  'Riba: ${product['interestRate'] ?? 0}%',
                  style: const TextStyle(fontSize: 11, color: accentColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLoanProductForm(product: product, index: index);
            },
            icon: const Icon(Icons.edit_rounded, size: 20),
            color: primaryColor,
          ),
          IconButton(
            onPressed: () => _deleteLoanProduct(index),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  void _navigateToLoanProductForm({Map<String, dynamic>? product, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanProductFormPage(
          product: product,
          index: index,
          onSave: () => setState(() {}),
        ),
      ),
    );
  }

  Future<void> _deleteLoanProduct(int index) async {
    final products = List<dynamic>.from(DataStore.loanProducts ?? []);
    if (index >= products.length) return;

    final product = products[index];
    final productId = product['id']?.toString();
    final productName = product['name']?.toString() ?? 'Unnamed';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Futa Bidhaa?'),
        content: Text('Una uhakika unataka kufuta "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana', style: TextStyle(color: accentColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Futa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && productId != null) {
      if (!mounted) return;
      Navigator.pop(context); // Close the products sheet
      final success = await HttpService.deleteLoanProduct(productId);
      if (success) {
        products.removeAt(index);
        DataStore.loanProducts = products;
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bidhaa "$productName" imefutwa'),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    }
  }

  // ==================== SHEET BUILDERS ====================

  Widget _buildEditSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    required VoidCallback onSave,
  }) {
    // Use Builder to get the correct context with keyboard insets
    return Builder(
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSheetHeader(title, icon, subtitle: subtitle),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: child,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Hifadhi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader(String title, IconData icon, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
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
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: accentColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required bool isActive,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isActive ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Hakuna',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: !isActive ? Colors.white : accentColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Kuna',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : accentColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: accentColor, fontSize: 13),
        prefixText: 'TZS ',
        prefixStyle: const TextStyle(color: textColor, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

// ==================== LOAN PRODUCT FORM PAGE ====================

class LoanProductFormPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  final int? index;
  final VoidCallback onSave;

  const LoanProductFormPage({
    super.key,
    this.product,
    this.index,
    required this.onSave,
  });

  @override
  State<LoanProductFormPage> createState() => _LoanProductFormPageState();
}

class _LoanProductFormPageState extends State<LoanProductFormPage> {
  static const Color primaryColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFF666666);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1A1A1A);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _interestRateController;
  late TextEditingController _minTenureController;
  late TextEditingController _maxTenureController;

  String _repaymentFrequency = 'monthly'; // Default to monthly

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?['name']?.toString() ?? '');
    _descriptionController = TextEditingController(text: p?['description']?.toString() ?? '');
    _minAmountController = TextEditingController(text: p?['minAmount']?.toString() ?? '');
    _maxAmountController = TextEditingController(text: p?['maxAmount']?.toString() ?? '');
    _interestRateController = TextEditingController(text: p?['interestRate']?.toString() ?? '');
    _minTenureController = TextEditingController(text: p?['minTenure']?.toString() ?? '1');
    _maxTenureController = TextEditingController(text: p?['maxTenure']?.toString() ?? '12');
    _repaymentFrequency = p?['repaymentFrequency']?.toString() ?? p?['repayment_frequency']?.toString() ?? 'monthly';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _interestRateController.dispose();
    _minTenureController.dispose();
    _maxTenureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Hariri Bidhaa' : 'Ongeza Bidhaa',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Jina la Bidhaa',
                hint: 'Mfano: Mkopo wa Dharura',
                validator: (v) => v?.isEmpty == true ? 'Jina linahitajika' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Maelezo',
                hint: 'Maelezo mafupi ya bidhaa',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minAmountController,
                      label: 'Kiasi Chini (TZS)',
                      hint: '10000',
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Kinahitajika' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxAmountController,
                      label: 'Kiasi Juu (TZS)',
                      hint: '1000000',
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Kinahitajika' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _interestRateController,
                label: 'Riba (%)',
                hint: '10',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v?.isEmpty == true ? 'Riba inahitajika' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minTenureController,
                      label: 'Muda Chini (miezi)',
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxTenureController,
                      label: 'Muda Juu (miezi)',
                      hint: '12',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Repayment Frequency Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mzunguko wa Malipo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _repaymentFrequency,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Kila Siku')),
                        DropdownMenuItem(value: 'weekly', child: Text('Kila Wiki')),
                        DropdownMenuItem(value: 'biweekly', child: Text('Kila Wiki 2')),
                        DropdownMenuItem(value: 'monthly', child: Text('Kila Mwezi')),
                        DropdownMenuItem(value: 'quarterly', child: Text('Kila Miezi 3')),
                        DropdownMenuItem(value: 'annually', child: Text('Kila Mwaka')),
                        DropdownMenuItem(value: 'lump_sum', child: Text('Mara Moja (End of Term)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _repaymentFrequency = value);
                        }
                      },
                      style: const TextStyle(fontSize: 14, color: textColor),
                      dropdownColor: cardColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Hifadhi Mabadiliko' : 'Ongeza Bidhaa',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: accentColor, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(fontSize: 14, color: textColor),
    );
  }

  Future<void> _saveProduct() async {
    _katibaLogger.i('╔════════════════════════════════════════════════════════════');
    _katibaLogger.i('║ [LoanProductForm._saveProduct] START');
    _katibaLogger.i('╚════════════════════════════════════════════════════════════');

    if (!_formKey.currentState!.validate()) {
      _katibaLogger.w('[LoanProductForm._saveProduct] Form validation failed');
      return;
    }

    _katibaLogger.i('[LoanProductForm._saveProduct] Form validation passed');
    setState(() => _isLoading = true);

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'minAmount': double.tryParse(_minAmountController.text) ?? 0,
        'maxAmount': double.tryParse(_maxAmountController.text) ?? 0,
        'interestRate': double.tryParse(_interestRateController.text) ?? 0,
        'minTenure': int.tryParse(_minTenureController.text) ?? 1,
        'maxTenure': int.tryParse(_maxTenureController.text) ?? 12,
        'repaymentFrequency': _repaymentFrequency,
      };

      final isUpdate = widget.product != null && widget.product!['id'] != null;
      final productId = isUpdate ? widget.product!['id'].toString() : null;

      _katibaLogger.i('[LoanProductForm._saveProduct] ══════ PRODUCT DATA ══════');
      _katibaLogger.i('[LoanProductForm._saveProduct] Action: ${isUpdate ? 'UPDATE' : 'CREATE'}');
      _katibaLogger.i('[LoanProductForm._saveProduct] Product ID: $productId');
      _katibaLogger.i('[LoanProductForm._saveProduct] Product Data:');
      _katibaLogger.i('  - name: ${productData['name']}');
      _katibaLogger.i('  - description: ${productData['description']}');
      _katibaLogger.i('  - minAmount: ${productData['minAmount']}');
      _katibaLogger.i('  - maxAmount: ${productData['maxAmount']}');
      _katibaLogger.i('  - interestRate: ${productData['interestRate']}%');
      _katibaLogger.i('  - minTenure: ${productData['minTenure']} months');
      _katibaLogger.i('  - maxTenure: ${productData['maxTenure']} months');
      _katibaLogger.i('  - repaymentFrequency: ${productData['repaymentFrequency']}');
      _katibaLogger.i('[LoanProductForm._saveProduct] ══════════════════════════');

      _katibaLogger.i('[LoanProductForm._saveProduct] Calling HttpService.requestLoanProductChange...');

      // Create voting request instead of direct save
      final result = await HttpService.requestLoanProductChange(
        action: isUpdate ? 'update' : 'create',
        productData: productData,
        productId: productId,
      );

      _katibaLogger.i('[LoanProductForm._saveProduct] ══════ RESULT ══════');
      _katibaLogger.i('[LoanProductForm._saveProduct] Success: ${result['success']}');
      _katibaLogger.i('[LoanProductForm._saveProduct] Message: ${result['message']}');
      _katibaLogger.i('[LoanProductForm._saveProduct] Case ID: ${result['caseId']}');
      _katibaLogger.i('[LoanProductForm._saveProduct] Full Result: $result');
      _katibaLogger.i('[LoanProductForm._saveProduct] ════════════════════');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result['success'] ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(result['message'])),
              ],
            ),
            backgroundColor: result['success'] ? Colors.green[700] : Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      _katibaLogger.i('[LoanProductForm._saveProduct] ════════════════ END ════════════════');
    } catch (e, stackTrace) {
      _katibaLogger.e('[LoanProductForm._saveProduct] ✗ ERROR: $e');
      _katibaLogger.e('[LoanProductForm._saveProduct] Stack trace: $stackTrace');
      _katibaLogger.i('[LoanProductForm._saveProduct] ════════════════ END (ERROR) ════════════════');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
