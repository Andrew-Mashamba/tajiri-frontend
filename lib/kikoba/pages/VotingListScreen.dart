import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../HttpService.dart';
import '../DataStore.dart';
import '../widgets/voting_card.dart';
import '../services/page_cache_service.dart';

// Monochrome design colors (from design-guidelines.md)
const _primaryBg = Color(0xFFFAFAFA);
const _buttonBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accent = Color(0xFF999999);

/// Screen showing all pending voting items for a kikoba
class VotingListScreen extends StatefulWidget {
  final String? kikobaId;
  final String? initialType; // Filter by type if specified

  const VotingListScreen({
    super.key,
    this.kikobaId,
    this.initialType,
  });

  @override
  State<VotingListScreen> createState() => _VotingListScreenState();
}

class _VotingListScreenState extends State<VotingListScreen> {
  final Logger _logger = Logger();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _pendingItems = [];
  String _selectedFilter = 'all';
  Set<String> _votingItemIds = {}; // Track items being voted on

  // ============ State for caching and real-time updates ============
  /// IMPORTANT: All data is fetched from the BACKEND API.
  /// Firestore is used ONLY for change notifications, NOT for data.
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  bool _isRefreshing = false;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Zote'},
    {'value': 'membership_removal', 'label': 'Kuondoa'},
    {'value': 'expense_request', 'label': 'Matumizi'},
    {'value': 'katiba_change', 'label': 'Katiba'},
    {'value': 'fine_approval', 'label': 'Faini'},
    {'value': 'loan_application', 'label': 'Mikopo'},
    {'value': 'voting_case', 'label': 'Kura'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedFilter = widget.initialType!;
    }
    _loadData();
    _setupFirestoreListener();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  String get _kikobaId => widget.kikobaId ?? DataStore.currentKikobaId;

  /// Load data: first from cache for instant display, then from backend API
  Future<void> _loadData() async {
    final kikobaId = _kikobaId;
    final visitorId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty) {
      _logger.e('[VotingListScreen] Cannot load data - missing required IDs');
      if (mounted) {
        setState(() {
          _error = 'Kikoba ID haijulikani';
          _isInitialLoading = false;
          _isLoading = false;
        });
      }
      return;
    }

    // Step 1: Try to load cached data for instant display
    final cachedData = await PageCacheService.getPageData(
      pageType: 'voting_list',
      visitorId: visitorId,
      kikobaId: kikobaId,
      subKey: _selectedFilter,
    );
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
        _isLoading = false;
      });
      _logger.d('[VotingListScreen] Loaded cached data for instant display');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend(showLoadingIfNoCachedData: !_hasCachedData);
  }

  /// Apply cached data
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['pendingItems'] != null) {
      _pendingItems = (data['pendingItems'] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
  }

  /// Fetch fresh data from backend API and cache it
  /// IMPORTANT: All data comes from the backend, NOT from Firestore!
  Future<void> _fetchDataFromBackend({bool showLoadingIfNoCachedData = false, bool forceRefresh = false}) async {
    final kikobaId = _kikobaId;
    final visitorId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty) return;

    if (showLoadingIfNoCachedData && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      _logger.d('[VotingListScreen] Fetching voting items from backend...');

      final response = await HttpService.getPendingVotingItems(
        kikobaId: kikobaId,
        type: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (mounted) {
        _logger.d('[VotingListScreen] Response success: ${response['success']}, filter: $_selectedFilter');
        _logger.d('[VotingListScreen] Response data type: ${response['data'].runtimeType}');
        _logger.d('[VotingListScreen] Response data: ${response['data']}');

        if (response['success'] == true) {
          final data = response['data'];
          List<Map<String, dynamic>> items = [];

          // Handle both Map and List responses
          if (data is Map<String, dynamic>) {
            data.forEach((key, value) {
              if (value is List) {
                for (var item in value) {
                  if (item is Map<String, dynamic>) {
                    items.add(item);
                  }
                }
              }
            });
          } else if (data is List) {
            items = data.whereType<Map<String, dynamic>>().toList();
          }

          setState(() {
            _pendingItems = items;
            _isLoading = false;
            _isInitialLoading = false;
            _hasCachedData = true;
            _error = null;
          });

          // Cache the data for next time
          await PageCacheService.savePageData(
            pageType: 'voting_list',
            visitorId: visitorId,
            kikobaId: kikobaId,
            subKey: _selectedFilter,
            data: {
              'pendingItems': _pendingItems,
              'fetchedAt': DateTime.now().toIso8601String(),
            },
          );
          _logger.d('[VotingListScreen] Fetched and cached ${items.length} voting items');
          _logger.d('[VotingListScreen] Items: $items');
        } else {
          setState(() {
            _error = response['message'] ?? 'Imeshindwa kupakia maombi';
            _isLoading = false;
            _isInitialLoading = false;
          });
        }
      }
    } catch (e) {
      _logger.e('[VotingListScreen] Error fetching data from backend: $e');
      if (mounted) {
        setState(() {
          _error = 'Tatizo la mtandao. Jaribu tena.';
          _isLoading = false;
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
    final kikobaId = _kikobaId;
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
      final newVersion = notificationData['voting_version'] as int?;
      final updatedAt = notificationData['voting_updated_at'];
      int? effectiveVersion = newVersion;

      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[VotingListScreen] Firestore notification: version changed');
        _lastKnownVersion = effectiveVersion;
        await _fetchDataFromBackend(forceRefresh: true);
      }
    }, onError: (e) {
      _logger.e('[VotingListScreen] Firestore listener error: $e');
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

  Future<void> _castVote(Map<String, dynamic> item, String vote) async {
    // Detect if this is a loan application
    final isLoanApplication = item['application_id'] != null || item['principal_amount'] != null;

    // Use application_id for loans, otherwise use id
    final itemId = isLoanApplication
        ? (item['application_id']?.toString() ?? item['id']?.toString() ?? '')
        : (item['id']?.toString() ?? '');

    // Determine type - loan applications should use 'loan_application'
    final itemType = isLoanApplication
        ? 'loan_application'
        : (item['type']?.toString() ?? item['voteable_type']?.toString() ?? '');

    if (itemId.isEmpty || itemType.isEmpty) {
      _showError('Taarifa za kura hazipo');
      return;
    }

    setState(() => _votingItemIds.add(itemId));

    try {
      final response = await HttpService.castVote(
        voteableType: itemType,
        voteableId: itemId,
        vote: vote,
      );

      if (response['success'] == true) {
        _showSuccess('Kura yako imesajiliwa');
        // Reload the list from backend
        await _fetchDataFromBackend(forceRefresh: true);
      } else {
        _showError(response['message'] ?? 'Imeshindwa kupiga kura');
      }
    } catch (e) {
      _logger.e('Error casting vote: $e');
      _showError('Tatizo la mtandao. Jaribu tena.');
    } finally {
      setState(() => _votingItemIds.remove(itemId));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _buttonBg, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: _buttonBg))),
          ],
        ),
        backgroundColor: _secondaryText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _buttonBg, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: _buttonBg))),
          ],
        ),
        backgroundColor: _iconBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Maombi ya Kura',
          style: TextStyle(
            color: _primaryText,
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
                    color: _iconBg,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _iconBg),
              onPressed: _handleRefresh,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = filter['value']!);
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _iconBg : _buttonBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _iconBg : _accent.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    filter['label']!,
                    style: TextStyle(
                      color: isSelected ? _buttonBg : _secondaryText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitialLoading && !_hasCachedData) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _iconBg),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.error_outline_rounded, size: 32, color: _secondaryText),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _secondaryText),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleRefresh,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.refresh_rounded, size: 18, color: _buttonBg),
                          SizedBox(width: 8),
                          Text('Jaribu Tena', style: TextStyle(color: _buttonBg, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.how_to_vote_rounded, size: 32, color: _secondaryText),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hakuna maombi yanayosubiri kura',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Maombi yote yameshughulikiwa',
                style: TextStyle(
                  fontSize: 12,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: _iconBg,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _pendingItems.length,
        itemBuilder: (context, index) {
          final item = _pendingItems[index];
          return _buildVotingItem(item);
        },
      ),
    );
  }

  Widget _buildVotingItem(Map<String, dynamic> item) {
    final itemId = item['id']?.toString() ?? '';

    // Detect if this is a loan application based on presence of loan-specific fields
    final isLoanApplication = item['application_id'] != null || item['principal_amount'] != null;

    // Parse fields with fallbacks for both generic voting items and loan applications
    String type;
    String title;
    String description;
    String? createdBy;
    String? createdAt;

    if (isLoanApplication) {
      // Loan application data structure
      type = 'loan_application';
      final applicantName = item['applicant_name']?.toString() ?? 'Mwombaji';
      final principalAmount = double.tryParse(item['principal_amount']?.toString() ?? '0') ?? 0;
      final tenure = item['tenure']?.toString() ?? '?';
      title = 'Ombi la Mkopo - $applicantName';
      description = 'Kiasi: TZS ${_formatNumber(principalAmount)} | Muda: $tenure miezi';
      createdBy = applicantName;
      createdAt = item['application_date']?.toString() ?? item['created_at']?.toString();
    } else {
      // Generic voting item structure
      type = item['type']?.toString() ?? item['voteable_type']?.toString() ?? 'voting_case';
      title = item['title']?.toString() ?? item['description']?.toString() ?? 'Ombi';
      description = item['description']?.toString() ?? item['reason']?.toString() ?? '';
      createdBy = item['created_by_name']?.toString() ?? item['requester_name']?.toString();
      createdAt = item['created_at']?.toString();
    }

    final status = item['status']?.toString() ?? 'pending';

    // Voting data
    final voting = item['voting'] as Map<String, dynamic>? ?? {};
    final yesCount = voting['yes_count'] as int? ?? 0;
    final noCount = voting['no_count'] as int? ?? 0;
    final abstainCount = voting['abstain_count'] as int? ?? 0;
    final totalVotes = voting['total_votes'] as int? ?? 0;
    final approvalPercentage = (voting['approval_percentage'] as num?)?.toDouble() ?? 0.0;
    final approvalThreshold = (voting['approval_threshold'] as num?)?.toDouble() ?? 50.0;
    final hasVoted = voting['user_has_voted'] == true;
    final userVote = voting['user_vote']?.toString();

    // Extract config for dynamic min_votes
    final config = voting['config'] as Map<String, dynamic>? ?? {};
    final minVotes = config['min_votes'] as int?;
    final totalMembers = config['total_members'] as int?;

    final isVoting = _votingItemIds.contains(itemId);

    return VotingCard(
      title: title,
      description: description,
      type: type,
      status: status,
      createdBy: createdBy,
      createdAt: createdAt,
      yesCount: yesCount,
      noCount: noCount,
      abstainCount: abstainCount,
      totalVotes: totalVotes,
      approvalPercentage: approvalPercentage,
      approvalThreshold: approvalThreshold,
      minVotes: minVotes,
      totalMembers: totalMembers,
      hasVoted: hasVoted,
      userVote: userVote,
      isLoading: isVoting,
      onVoteYes: () => _castVote(item, 'yes'),
      onVoteNo: () => _castVote(item, 'no'),
      onVoteAbstain: () => _castVote(item, 'abstain'),
      onTap: () => _showItemDetails(item),
      additionalContent: _buildAdditionalContent(item, type),
    );
  }

  Widget? _buildAdditionalContent(Map<String, dynamic> item, String type) {
    switch (type.toLowerCase()) {
      case 'membership_removal':
      case 'membership_removal_request':
        final memberName = item['member_name']?.toString();
        final removalType = item['removal_type']?.toString();
        if (memberName != null) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_off_rounded, size: 16, color: _buttonBg),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (removalType != null)
                        Text(
                          _getRemovalTypeLabel(removalType),
                          style: const TextStyle(fontSize: 11, color: _secondaryText),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return null;

      case 'expense_request':
        final amount = item['amount'];
        final category = item['category']?.toString();
        if (amount != null) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments_rounded, size: 16, color: _buttonBg),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TZS ${_formatAmount(amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _primaryText,
                      ),
                    ),
                    if (category != null)
                      Text(
                        category,
                        style: const TextStyle(fontSize: 11, color: _secondaryText),
                      ),
                  ],
                ),
              ],
            ),
          );
        }
        return null;

      case 'fine_approval':
      case 'fine_approval_request':
        final amount = item['amount'];
        final fineType = item['fine_type']?.toString();
        final memberName = item['member_name']?.toString();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (memberName != null)
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.person_rounded, size: 14, color: _buttonBg),
                    ),
                    const SizedBox(width: 8),
                    Text(memberName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              if (amount != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Faini: TZS ${_formatAmount(amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _primaryText),
                ),
              ],
              if (fineType != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Aina: $fineType',
                  style: const TextStyle(fontSize: 11, color: _secondaryText),
                ),
              ],
            ],
          ),
        );

      default:
        return null;
    }
  }

  String _getRemovalTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'voluntary':
        return 'Hiari';
      case 'disciplinary':
        return 'Nidhamu';
      case 'inactive':
        return 'Kutokuwa hai';
      case 'deceased':
        return 'Amefariki';
      default:
        return type;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num = double.tryParse(amount.toString()) ?? 0;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? item['voteable_type']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: _buttonBg, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Maelezo Kamili',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _secondaryText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailRow('Aina', _getTypeLabel(type)),
                    _buildDetailRow('Hali', item['status']?.toString() ?? '-'),
                    _buildDetailRow('Kichwa', item['title']?.toString() ?? '-'),
                    _buildDetailRow('Maelezo', item['description']?.toString() ?? item['reason']?.toString() ?? '-'),
                    if (item['amount'] != null)
                      _buildDetailRow('Kiasi', 'TZS ${_formatAmount(item['amount'])}'),
                    if (item['member_name'] != null)
                      _buildDetailRow('Mwanachama', item['member_name'].toString()),
                    if (item['created_by_name'] != null)
                      _buildDetailRow('Aliyetuma', item['created_by_name'].toString()),
                    if (item['created_at'] != null)
                      _buildDetailRow('Tarehe', item['created_at'].toString()),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'membership_removal':
      case 'membership_removal_request':
        return 'Kuondoa Mwanachama';
      case 'expense_request':
        return 'Ombi la Matumizi';
      case 'katiba_change':
      case 'katiba_change_request':
        return 'Mabadiliko ya Katiba';
      case 'fine_approval':
      case 'fine_approval_request':
        return 'Idhini ya Faini';
      case 'loan_application':
        return 'Ombi la Mkopo';
      case 'voting_case':
        return 'Kura ya Kawaida';
      default:
        return type;
    }
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)},000';
    }
    return value.toStringAsFixed(0);
  }
}
