import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../DataStore.dart';
import '../HttpService.dart';
import '../BankTransferScreen.dart';
import '../services/page_cache_service.dart';

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

class MchangoDetailPage extends StatefulWidget {
  final Map<String, dynamic> mchango;

  const MchangoDetailPage({Key? key, required this.mchango}) : super(key: key);

  @override
  State<MchangoDetailPage> createState() => _MchangoDetailPageState();
}

class _MchangoDetailPageState extends State<MchangoDetailPage> {
  final Logger _logger = Logger();
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
  final formatDate = DateFormat('dd MMM yyyy');

  Map<String, dynamic>? _mchangoDetails;
  Map<String, dynamic>? _userStatus;
  bool _isLoading = false;
  bool _isLoadingStatus = false;

  // ============ State for caching and real-time updates ============
  /// IMPORTANT: All data is fetched from the BACKEND API.
  /// Firestore is used ONLY for change notifications, NOT for data.
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  bool _isRefreshing = false;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  String? get _mchangoId => (widget.mchango['_id'] ?? widget.mchango['id'])?.toString();

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
    final mchangoId = _mchangoId;

    if (kikobaId.isEmpty || visitorId.isEmpty || mchangoId == null) {
      _logger.e('[MchangoDetailPage] Cannot load data - missing required IDs');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Step 1: Try to load cached data for instant display
    final cachedData = await PageCacheService.getPageData(
      pageType: 'mchango_detail',
      visitorId: visitorId,
      kikobaId: kikobaId,
      subKey: mchangoId,
    );
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[MchangoDetailPage] Loaded cached data for instant display');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend(showLoadingIfNoCachedData: !_hasCachedData);
  }

  /// Apply cached data
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['mchangoDetails'] != null) {
      _mchangoDetails = Map<String, dynamic>.from(data['mchangoDetails']);
    }
    if (data['userStatus'] != null) {
      _userStatus = Map<String, dynamic>.from(data['userStatus']);
    }
  }

  /// Fetch fresh data from backend API and cache it
  /// IMPORTANT: All data comes from the backend, NOT from Firestore!
  Future<void> _fetchDataFromBackend({bool showLoadingIfNoCachedData = false, bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;
    final mchangoId = _mchangoId;

    if (kikobaId.isEmpty || visitorId.isEmpty || mchangoId == null) return;

    if (showLoadingIfNoCachedData && mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingStatus = true;
      });
    }

    try {
      _logger.d('[MchangoDetailPage] Fetching mchango details from backend...');

      // Fetch both details and status in parallel
      final results = await Future.wait([
        HttpService.getMchangoDetails(mchangoId),
        HttpService.getUserMchangoStatus(mchangoId: mchangoId),
      ]);

      final detailsResponse = results[0];
      final statusResponse = results[1];

      if (mounted) {
        setState(() {
          if (detailsResponse != null && detailsResponse['success'] == true) {
            _mchangoDetails = detailsResponse['mchango'];
          } else {
            _mchangoDetails = widget.mchango; // Fallback
          }

          if (statusResponse != null && statusResponse['success'] == true) {
            _userStatus = statusResponse['status'];
          }

          _isLoading = false;
          _isLoadingStatus = false;
          _isInitialLoading = false;
          _hasCachedData = true;
        });

        // Cache the data for next time
        await PageCacheService.savePageData(
          pageType: 'mchango_detail',
          visitorId: visitorId,
          kikobaId: kikobaId,
          subKey: mchangoId,
          data: {
            'mchangoDetails': _mchangoDetails,
            'userStatus': _userStatus,
            'fetchedAt': DateTime.now().toIso8601String(),
          },
        );
        _logger.d('[MchangoDetailPage] Fetched and cached mchango details');
      }
    } catch (e) {
      _logger.e('[MchangoDetailPage] Error fetching data from backend: $e');
      if (mounted) {
        setState(() {
          _mchangoDetails = widget.mchango; // Fallback
          _isLoading = false;
          _isLoadingStatus = false;
          _isInitialLoading = false;
        });
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
      final newVersion = notificationData['michango_version'] as int?;
      final updatedAt = notificationData['michango_updated_at'];
      int? effectiveVersion = newVersion;

      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[MchangoDetailPage] Firestore notification: version changed');
        _lastKnownVersion = effectiveVersion;
        await _fetchDataFromBackend(forceRefresh: true);
      }
    }, onError: (e) {
      _logger.e('[MchangoDetailPage] Firestore listener error: $e');
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

  String _getTitle() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    return mchangoData['title'] ?? mchangoData['ainayaMchango'] ?? 'Mchango';
  }

  String _getDescription() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    return mchangoData['description'] ?? mchangoData['maelezo'] ?? 'Hakuna maelezo';
  }

  double _getTargetAmount() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    final target = mchangoData['targetAmount'] ?? mchangoData['target_amount'] ?? mchangoData['amount'] ?? 0;
    if (target is num) return target.toDouble();
    if (target is String) return double.tryParse(target) ?? 0.0;
    return 0.0;
  }

  double _getAmountPerPerson() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    final amount = mchangoData['amountPerPerson'] ?? mchangoData['amount_per_person'] ?? 0;
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  double _getCollectedAmount() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    // API returns: totalCollected
    final collected = mchangoData['totalCollected'] ?? mchangoData['collectedAmount'] ?? mchangoData['collected_amount'] ?? 0;
    if (collected is num) return collected.toDouble();
    if (collected is String) return double.tryParse(collected) ?? 0.0;
    return 0.0;
  }

  String? _getDeadline() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    return mchangoData['deadline'] ?? mchangoData['tarehe'];
  }

  String _getStatus() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    return mchangoData['status']?.toString().toLowerCase() ?? 'active';
  }

  List<dynamic> _getContributors() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    // API returns: contributions (list of paid contributors)
    return mchangoData['contributions'] as List<dynamic>? ??
           mchangoData['contributors'] as List<dynamic>? ?? [];
  }

  List<dynamic> _getPendingContributors() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    // API returns: pendingContributors (list of pending contributors)
    return mchangoData['pendingContributors'] as List<dynamic>? ?? [];
  }

  String? _getControlNumber() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    return mchangoData['controlNumber']?.toString();
  }

  String? _getPaymentUrl() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    return mchangoData['paymentUrl']?.toString();
  }

  String? _getMchangoId() {
    final mchangoData = _mchangoDetails ?? widget.mchango;
    return mchangoData['mchangoId']?.toString() ??
           mchangoData['_id']?.toString() ??
           mchangoData['id']?.toString();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'open':
        return _successColor;
      case 'completed':
      case 'closed':
        return _secondaryText;
      case 'pending':
        return _warningColor;
      default:
        return _secondaryText;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Hai';
      case 'open':
        return 'Wazi';
      case 'completed':
        return 'Imekamilika';
      case 'closed':
        return 'Imefungwa';
      case 'pending':
        return 'Inasubiri';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetAmount = _getTargetAmount();
    final collectedAmount = _getCollectedAmount();
    final progress = targetAmount > 0 ? collectedAmount / targetAmount : 0.0;
    final status = _getStatus();
    final contributors = _getContributors();

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
          'Maelezo ya Mchango',
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
        child: _isInitialLoading && !_hasCachedData
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeaderCard(status),
                      const SizedBox(height: 16),

                      // Progress Card
                      _buildProgressCard(targetAmount, collectedAmount, progress),
                      const SizedBox(height: 16),

                      // User Status Card
                      if (!_isLoadingStatus && _userStatus != null)
                        _buildUserStatusCard(),
                      if (!_isLoadingStatus && _userStatus != null)
                        const SizedBox(height: 16),

                      // Description Card
                      _buildDescriptionCard(),
                      const SizedBox(height: 16),

                    // Contributors List
                    if (contributors.isNotEmpty) ...[
                      _buildContributorsSection(contributors),
                      const SizedBox(height: 16),
                    ],

                    // Payment Action Button (show if not completed and user hasn't paid)
                    if (status != 'completed' && status != 'closed') ...[
                      _buildPaymentActionButton(),
                      const SizedBox(height: 16),
                    ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard(String status) {
    final deadline = _getDeadline();
    final daysLeft = deadline != null ? _calculateDaysLeft(deadline) : null;

    return Container(
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
                  Icons.volunteer_activism_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
              ),
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
            ],
          ),
          if (deadline != null) ...[
            const SizedBox(height: 16),
            Divider(color: _borderColor, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: _secondaryText),
                const SizedBox(width: 6),
                Text(
                  'Mwisho: ${_formatDateString(deadline)}',
                  style: const TextStyle(fontSize: 14, color: _secondaryText),
                ),
                if (daysLeft != null) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: daysLeft < 7 ? _errorColor.withOpacity(0.1) : _successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      daysLeft < 0 ? 'Umepita' : 'Siku $daysLeft zilizobaki',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: daysLeft < 7 ? _errorColor : _successColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(double targetAmount, double collectedAmount, double progress) {
    final amountPerPerson = _getAmountPerPerson();

    return Container(
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
          const Text(
            'Maendeleo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryText),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lengo', style: TextStyle(fontSize: 12, color: _secondaryText)),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency.format(targetAmount),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Iliyokusanywa', style: TextStyle(fontSize: 12, color: _secondaryText)),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency.format(collectedAmount),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _successColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: _borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(_successColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% ya lengo',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
          ),
          if (amountPerPerson > 0) ...[
            const SizedBox(height: 16),
            Divider(color: _borderColor, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: _secondaryText),
                const SizedBox(width: 6),
                const Text('Kiasi kwa mtu: ', style: TextStyle(fontSize: 14, color: _secondaryText)),
                Text(
                  formatCurrency.format(amountPerPerson),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primaryText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserStatusCard() {
    if (_userStatus == null) return const SizedBox.shrink();

    final hasPaid = _userStatus!['hasPaid'] ?? false;
    final amount = _userStatus!['amount'] ?? 0.0;
    final paidDate = _userStatus!['paidDate'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPaid ? _successColor.withOpacity(0.1) : _warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPaid ? _successColor.withOpacity(0.3) : _warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPaid ? Icons.check_circle : Icons.pending,
            color: hasPaid ? _successColor : _warningColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPaid ? 'Umechangia' : 'Hujachangia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasPaid ? _successColor : _warningColor,
                  ),
                ),
                if (hasPaid && amount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency.format(amount),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText),
                  ),
                ],
                if (hasPaid && paidDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tarehe: ${_formatDateString(paidDate)}',
                    style: const TextStyle(fontSize: 12, color: _secondaryText),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
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
          const Text(
            'Maelezo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryText),
          ),
          const SizedBox(height: 12),
          Text(
            _getDescription(),
            style: const TextStyle(fontSize: 14, color: _secondaryText, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorsSection(List<dynamic> contributors) {
    final paidContributors = contributors.where((c) => c['hasPaid'] == true).toList();
    final pendingContributors = contributors.where((c) => c['hasPaid'] != true).toList();

    return Container(
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
              const Text(
                'Wachangiaji',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryText),
              ),
              const Spacer(),
              Text(
                '${paidContributors.length}/${contributors.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (paidContributors.isNotEmpty) ...[
            const Text('Wamechangia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _successColor)),
            const SizedBox(height: 8),
            ...paidContributors.map((c) => _buildContributorTile(c, true)),
          ],
          if (pendingContributors.isNotEmpty) ...[
            if (paidContributors.isNotEmpty) const SizedBox(height: 16),
            const Text('Wanasubiri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _warningColor)),
            const SizedBox(height: 8),
            ...pendingContributors.map((c) => _buildContributorTile(c, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildContributorTile(Map<String, dynamic> contributor, bool hasPaid) {
    final name = contributor['userName'] ?? contributor['name'] ?? 'N/A';
    final amount = contributor['amount'] ?? 0.0;
    final paidDate = contributor['paidDate'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: hasPaid ? _successColor.withOpacity(0.2) : _warningColor.withOpacity(0.2),
            child: Icon(
              hasPaid ? Icons.check : Icons.person,
              size: 16,
              color: hasPaid ? _successColor : _warningColor,
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
                ),
                if (hasPaid && paidDate != null)
                  Text(
                    _formatDateString(paidDate),
                    style: const TextStyle(fontSize: 11, color: _secondaryText),
                  ),
              ],
            ),
          ),
          if (hasPaid && amount > 0)
            Text(
              formatCurrency.format(amount),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _successColor),
            ),
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

  int? _calculateDaysLeft(String deadline) {
    try {
      final deadlineDate = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = deadlineDate.difference(now).inDays;
      return difference;
    } catch (e) {
      return null;
    }
  }

  /// Build the payment action button
  Widget _buildPaymentActionButton() {
    final hasPaid = _userStatus?['hasPaid'] ?? false;
    final amountPerPerson = _getAmountPerPerson();

    return Container(
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
          if (hasPaid) ...[
            // Already paid - show confirmation
            Row(
              children: [
                const Icon(Icons.check_circle, color: _successColor, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Umechangia tayari',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _successColor,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Not paid yet - show payment button
            Row(
              children: [
                const Icon(Icons.payment_rounded, color: _warningColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hujachangia bado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _warningColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kiasi: ${formatCurrency.format(amountPerPerson)}',
                        style: const TextStyle(fontSize: 13, color: _secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _showLipaMchangoDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _iconBg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volunteer_activism_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Lipa Mchango', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // PAYMENT FLOW - Similar to AkibaTable "Weka Akiba"
  // ============================================

  /// Show payment dialog for contributing to mchango
  void _showLipaMchangoDialog() {
    final amountPerPerson = _getAmountPerPerson();
    final mchangoTitle = _getTitle();
    final mchangoId = _getMchangoId();
    final controlNumber = _getControlNumber();
    final paymentUrl = _getPaymentUrl();

    // Build payment link from API data or DataStore
    Map<String, dynamic>? paymentLink;
    if (controlNumber != null) {
      paymentLink = {
        'control_number': controlNumber,
        'payment_url': paymentUrl,
        'status': 'pending',
      };
    } else {
      // Fallback to DataStore
      try {
        final payments = DataStore.getControlNumbers('mchango');
        paymentLink = payments.firstWhere(
          (p) => p['status'] == 'pending' && p['mchango_id'] == mchangoId,
          orElse: () => null,
        );
      } catch (e) {
        paymentLink = null;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lipa Mchango',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mchangoTitle,
                            style: const TextStyle(fontSize: 13, color: _secondaryText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kiasi cha Kulipa:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText),
                      ),
                      Text(
                        formatCurrency.format(amountPerPerson),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _successColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Link Option (if available)
                if (paymentLink != null) ...[
                  _buildPaymentOption(
                    context: context,
                    icon: Icons.link_rounded,
                    title: 'Lipa kwa Simu',
                    subtitle: 'Namba: ${paymentLink['control_number']}',
                    onTap: () {
                      Navigator.pop(context);
                      _launchPaymentUrl(context, paymentLink!['payment_url']);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Bank Transfer Option
                _buildPaymentOption(
                  context: context,
                  icon: Icons.account_balance_rounded,
                  title: 'Lipa kwa Benki',
                  subtitle: 'Hamisha fedha kwenda akaunti ya kikundi',
                  onTap: () {
                    Navigator.pop(context);
                    _showBankTransferFlow(
                      amountPerPerson,
                      description: 'Mchango - $mchangoTitle',
                      controlNumber: paymentLink?['control_number']?.toString(),
                    );
                  },
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Center(
                    child: Text('Sitisha', style: TextStyle(color: _secondaryText)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build payment option widget
  Widget _buildPaymentOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconBg.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _iconBg, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _secondaryText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _secondaryText),
          ],
        ),
      ),
    );
  }

  /// Launch payment URL in external browser
  Future<void> _launchPaymentUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link ya malipo haipatikani')),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imeshindwa kufungua link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kosa: $e')),
        );
      }
    }
  }

  /// Navigate to BankTransferScreen for bank payment
  void _showBankTransferFlow(
    double amount, {
    String? description,
    String? controlNumber,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankTransferScreen(
          amount: amount,
          recipientBankName: DataStore.payingBank ?? '',
          recipientAccountNumber: DataStore.payingAccount ?? '',
          recipientBankCode: DataStore.payingBIN ?? '',
          narration: description ?? 'Malipo ya Mchango - ${DataStore.currentUserName}',
          controlNumber: controlNumber,
        ),
      ),
    );
  }
}
