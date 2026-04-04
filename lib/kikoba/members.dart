import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:vicoba/DataStore.dart';
import 'package:vicoba/HttpService.dart';
import 'addMjumbe.dart';
import 'pages/conversations_page.dart';
import 'pages/chat_page.dart';
import 'services/members_cache_service.dart';

final Logger _membersLogger = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

// Minimalist monochrome color palette from design guidelines
const Color primaryColor = Color(0xFF1A1A1A);
const Color accentColor = Color(0xFF666666);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF1A1A1A);
const Color secondaryTextColor = Color(0xFF666666);

class membersScreen extends StatefulWidget {
  const membersScreen({super.key});

  @override
  _membersScreenState createState() => _membersScreenState();
}

class _membersScreenState extends State<membersScreen>
    with AutomaticKeepAliveClientMixin<membersScreen>, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  // Data
  Map<String, dynamic>? _membersData;
  Map<String, dynamic>? _leaderboardData;
  bool _isLoading = true;
  bool _isLeaderboardView = false;
  String? _error;
  bool _hasCachedData = false;

  // Filters
  String _sortBy = 'activity';
  String _statusFilter = 'all';
  String? _roleFilter;

  // Chat
  int _unreadMessageCount = 0;

  // Tab controller for sort options
  late TabController _sortTabController;

  // Currency formatter
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'en_US');

  // Firestore listener for real-time notifications
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  @override
  void initState() {
    super.initState();
    _sortTabController = TabController(length: 3, vsync: this);
    _sortTabController.addListener(_onSortTabChanged);
    _loadMembersWithCache();
    _setupFirestoreListener();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final userId = DataStore.currentUserId;
    if (userId == null) return;

    final count = await HttpService.getUnreadCount(userId);
    if (!mounted) return;
    setState(() => _unreadMessageCount = count);
  }

  @override
  void dispose() {
    _sortTabController.removeListener(_onSortTabChanged);
    _sortTabController.dispose();
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  void _onSortTabChanged() {
    if (!_sortTabController.indexIsChanging) {
      final sortOptions = ['activity', 'name', 'registration_date'];
      setState(() {
        _sortBy = sortOptions[_sortTabController.index];
      });
      _loadMembersWithCache(forceRefresh: true);
    }
  }

  /// Check if device has internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      _membersLogger.e('[MEMBERS] Connectivity check error: $e');
      return true; // Assume connected on error
    }
  }

  /// Set up Firestore listener for real-time updates
  void _setupFirestoreListener() {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null || kikobaId.isEmpty) {
      _membersLogger.w('[MEMBERS] No kikoba ID, skipping Firestore listener');
      return;
    }

    _membersLogger.i('[MEMBERS] Setting up Firestore listener for kikoba: $kikobaId');

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('MembersUpdates')
        .doc(kikobaId)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!snapshot.exists || _isLoading) return;

        final data = snapshot.data();
        final newVersion = data?['version'] as int?;
        final updatedAt = data?['updatedAt'];
        final effectiveVersion = newVersion ?? updatedAt?.hashCode;

        if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
          _membersLogger.i('[MEMBERS] Version changed: $_lastKnownVersion -> $effectiveVersion, refreshing...');
          _lastKnownVersion = effectiveVersion;
          await MembersCacheService.saveVersion(kikobaId, effectiveVersion);
          _loadMembersWithCache(forceRefresh: true);
        }
      },
      onError: (error) {
        _membersLogger.e('[MEMBERS] Firestore listener error: $error');
      },
    );
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

  /// Load members with cache support
  Future<void> _loadMembersWithCache({bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId ?? '';
    _membersLogger.i('[MEMBERS] Loading data (forceRefresh: $forceRefresh, sort: $_sortBy, status: $_statusFilter)');

    // 1. Try to show cached data immediately
    if (!forceRefresh && !_hasCachedData) {
      final cached = await MembersCacheService.getMembers(
        kikobaId,
        sortBy: _sortBy,
        statusFilter: _statusFilter,
      );
      if (cached != null) {
        _membersLogger.i('[MEMBERS] Showing cached data instantly');
        _lastKnownVersion = await MembersCacheService.getVersion(kikobaId);
        if (mounted) {
          setState(() {
            _membersData = cached;
            _hasCachedData = true;
            _isLoading = false;
            _error = null;
          });
        }
      }
    }

    // 2. Check connectivity
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _membersLogger.w('[MEMBERS] No internet connection');
      if (mounted) {
        setState(() => _isLoading = false);
        if (_hasCachedData) {
          _showConnectivitySnackbar();
        }
      }
      return;
    }

    // 3. Set loading state only if no cached data
    if (!_hasCachedData) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    // 4. Fetch fresh data from backend
    try {
      final data = await HttpService.getMembersWithDetails(
        sortBy: _sortBy,
        status: _statusFilter,
        role: _roleFilter,
      );

      if (!mounted) return;

      if (data == null) {
        if (!_hasCachedData) {
          setState(() {
            _error = 'Imeshindikana kupata wanachama';
            _isLoading = false;
          });
        }
        return;
      }

      // Cache the fresh data
      await MembersCacheService.saveMembers(
        kikobaId,
        data,
        sortBy: _sortBy,
        statusFilter: _statusFilter,
      );

      setState(() {
        _membersData = data;
        _hasCachedData = true;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      _membersLogger.e('[MEMBERS] Error loading members: $e');
      if (!mounted) return;
      if (!_hasCachedData) {
        setState(() {
          _error = 'Kosa: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Pull-to-refresh handler with connectivity check
  Future<void> _refreshMembers() async {
    _membersLogger.i('[MEMBERS] Pull-to-refresh triggered');

    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _showConnectivitySnackbar();
      return;
    }

    await _loadMembersWithCache(forceRefresh: true);
  }

  /// Load leaderboard with connectivity check
  Future<void> _loadLeaderboardWithConnectivity() async {
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _showConnectivitySnackbar();
      return;
    }

    await _loadLeaderboard();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await HttpService.getMembersWithDetails(
        sortBy: _sortBy,
        status: _statusFilter,
        role: _roleFilter,
      );

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _error = 'Imeshindikana kupata wanachama';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _membersData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kosa: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final data = await HttpService.getMembersLeaderboard(limit: 15);

      if (!mounted) return;

      setState(() {
        _leaderboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleLeaderboard() {
    setState(() {
      _isLeaderboardView = !_isLeaderboardView;
    });
    if (_isLeaderboardView && _leaderboardData == null) {
      _loadLeaderboard();
    }
  }

  void _openConversations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConversationsPage()),
    ).then((_) => _loadUnreadCount());
  }

  Future<void> _startChatWithMember(Map<String, dynamic> member) async {
    final currentUserId = DataStore.currentUserId;
    final recipientId = member['user_id']?.toString() ?? member['id']?.toString();

    if (currentUserId == null || recipientId == null) return;

    // Don't allow chatting with yourself
    if (currentUserId == recipientId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Huwezi kujitumia ujumbe')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
    );

    try {
      final result = await HttpService.startConversation(
        senderId: currentUserId,
        recipientId: recipientId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (result != null && result['conversation_id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: result['conversation_id'],
              recipientName: member['name'] ?? 'Unknown',
              recipientId: recipientId,
              recipientPhone: member['phone'],
              firebasePath: result['firebase_path'],
            ),
          ),
        ).then((_) => _loadUnreadCount());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imeshindwa kuanza mazungumzo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kosa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _isLeaderboardView ? _loadLeaderboardWithConnectivity : _refreshMembers,
          color: primaryColor,
          child: CustomScrollView(
            slivers: [
              // Header with summary
              SliverToBoxAdapter(child: _buildHeader()),
              // Filter/Sort tabs
              if (!_isLeaderboardView)
                SliverToBoxAdapter(child: _buildFilters()),
              // Content
              if (_isLoading && !_hasCachedData)
                SliverFillRemaining(child: _buildSkeletonLoading())
              else if (_error != null && !_hasCachedData)
                SliverFillRemaining(child: _buildErrorState())
              else if (_isLeaderboardView)
                _buildLeaderboardList()
              else
                _buildMembersList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => addMjumbe()),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final summary = _membersData?['summary'];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with leaderboard toggle
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
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
                      _isLeaderboardView ? 'Leaderboard' : 'Wanachama',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      _isLeaderboardView
                          ? 'Wanachama bora kwa utendaji'
                          : 'Orodha ya wanachama wote',
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Messages button
              GestureDetector(
                onTap: _openConversations,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: accentColor,
                      ),
                      if (_unreadMessageCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                            child: Text(
                              _unreadMessageCount > 9 ? '9+' : '$_unreadMessageCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Leaderboard toggle
              GestureDetector(
                onTap: _toggleLeaderboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isLeaderboardView ? primaryColor : cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isLeaderboardView ? primaryColor : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 16,
                        color: _isLeaderboardView ? Colors.white : accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Top',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isLeaderboardView ? Colors.white : accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Summary cards
          if (summary != null && !_isLeaderboardView) ...[
            const SizedBox(height: 16),
            _buildSummaryCards(summary),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final financials = summary['financial_totals'] ?? {};

    return Column(
      children: [
        // Member counts row
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.groups_rounded,
                label: 'Jumla',
                value: '${summary['total_members'] ?? 0}',
                subtitle: 'wanachama',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.check_circle_rounded,
                label: 'Hai',
                value: '${summary['active_members'] ?? 0}',
                subtitle: '${(summary['activity_rate'] ?? 0).toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.star_rounded,
                label: 'Wastani',
                value: '${(summary['average_activity_score'] ?? 0).toStringAsFixed(0)}',
                subtitle: 'alama',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Financial totals row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildFinancialItem(
                  'Hisa',
                  financials['total_shares_value'] ?? 0,
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFE5E5E5)),
              Expanded(
                child: _buildFinancialItem(
                  'Akiba',
                  financials['total_savings_balance'] ?? 0,
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFE5E5E5)),
              Expanded(
                child: _buildFinancialItem(
                  'Mikopo',
                  financials['total_outstanding_loans'] ?? 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String label, num value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(value),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Sort tabs
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: TabBar(
              controller: _sortTabController,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: accentColor,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Utendaji'),
                Tab(text: 'Jina'),
                Tab(text: 'Tarehe'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Status filter chips
          Row(
            children: [
              _buildFilterChip('Wote', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Hai', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('Wasio hai', 'inactive'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = value;
          _hasCachedData = false; // Reset cache flag for new filter
        });
        _loadMembersWithCache(forceRefresh: true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE5E5E5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(6, (index) => _buildSkeletonMemberCard()),
      ),
    );
  }

  Widget _buildSkeletonMemberCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSkeletonBox(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonBox(width: 140, height: 16),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(width: 100, height: 12),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSkeletonBox(width: 40, height: 20),
                  const SizedBox(height: 4),
                  _buildSkeletonBox(width: 30, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSkeletonBox(width: double.infinity, height: 40)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonBox(width: double.infinity, height: 40)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonBox(width: double.infinity, height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    double borderRadius = 6,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.6),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: accentColor),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Kuna tatizo',
            style: const TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMembers,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Jaribu tena', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    final members = _membersData?['members'] as List<dynamic>? ?? [];

    if (members.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline_rounded, size: 64, color: accentColor),
              const SizedBox(height: 16),
              const Text(
                'Hakuna wanachama',
                style: TextStyle(fontSize: 16, color: secondaryTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final member = members[index];
            return _buildMemberCard(member);
          },
          childCount: members.length,
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final activityRating = member['activity_rating'] ?? {};
    final financialSummary = member['financial_summary'] ?? {};
    final hisa = financialSummary['hisa'] ?? {};
    final akiba = financialSummary['akiba'] ?? {};
    final loanSummary = member['loan_summary'] ?? {};

    final grade = activityRating['grade'] ?? 'N/A';
    final score = activityRating['score'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Stack(
        children: [
          // Main card content - tappable to show details
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showMemberDetails(member),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // Top row: Avatar, name, grade, score (with space for chat button)
                    Row(
                      children: [
                        // Avatar with grade badge
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFF0F0F0),
                              child: Text(
                                _getInitials(member['name'] ?? ''),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _getGradeColor(grade),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    grade,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Name and role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      member['role_code'] ?? 'Mjumbe',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: member['status'] == 'active'
                                          ? const Color(0xFF4CAF50)
                                          : accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    member['status'] == 'active' ? 'Hai' : 'Amesimama',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Score
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(score is num ? score : 0).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const Text(
                              'alama',
                              style: TextStyle(
                                fontSize: 10,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        // Space for chat button
                        const SizedBox(width: 52),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bottom row: Financial summary
                    Row(
                      children: [
                        _buildMemberFinancialItem(
                          'Hisa',
                          _parseNum(hisa['total_shares']),
                        ),
                        _buildMemberFinancialItem(
                          'Akiba',
                          _parseNum(akiba['current_balance']),
                        ),
                        _buildMemberFinancialItem(
                          'Mkopo',
                          _parseNum(loanSummary['outstanding_balance']),
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Chat button - positioned on top right, outside the InkWell
          Positioned(
            top: 14,
            right: 14,
            child: Material(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _startChatWithMember(member),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to parse dynamic values to num (handles String and num)
  num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  Widget _buildMemberFinancialItem(String label, num value, {bool isLast = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  right: BorderSide(color: Color(0xFFE5E5E5)),
                ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currencyFormat.format(value),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList() {
    final leaderboard = _leaderboardData?['leaderboard'] as List<dynamic>? ?? [];

    if (leaderboard.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'Hakuna data',
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final member = leaderboard[index];
            return _buildLeaderboardCard(member, index);
          },
          childCount: leaderboard.length,
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(Map<String, dynamic> member, int index) {
    final rank = member['rank'] ?? (index + 1);
    final grade = member['activity_grade'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3
              ? _getRankColor(rank).withValues(alpha: 0.3)
              : const Color(0xFFE5E5E5),
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rank <= 3 ? _getRankColor(rank) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      Icons.emoji_events_rounded,
                      size: 20,
                      color: Colors.white,
                    )
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member['role'] ?? 'Mjumbe',
                  style: const TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          // Grade and score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGradeColor(grade),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(member['activity_score'] ?? 0).toStringAsFixed(0)} pts',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMemberDetails(Map<String, dynamic> member) {
    final activityRating = member['activity_rating'] ?? {};
    final financialSummary = member['financial_summary'] ?? {};
    final ada = financialSummary['ada'] ?? {};
    final hisa = financialSummary['hisa'] ?? {};
    final akiba = financialSummary['akiba'] ?? {};
    final loanSummary = member['loan_summary'] ?? {};
    final mchangoSummary = member['mchango_summary'] ?? {};
    final membershipDuration = member['membership_duration'] ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: cardColor,
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
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFF0F0F0),
                          child: Text(
                            _getInitials(member['name'] ?? ''),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${member['role_code'] ?? 'Mjumbe'} • ${member['phone'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                              Text(
                                'Mwanachama kwa ${membershipDuration['human_readable'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getGradeColor(activityRating['grade'] ?? 'N/A'),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    activityRating['grade'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${(activityRating['score'] ?? 0).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _startChatWithMember(member);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Wasiliana',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity description
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _getGradeColor(activityRating['grade'] ?? 'N/A')
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insights_rounded,
                              color: _getGradeColor(activityRating['grade'] ?? 'N/A'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                activityRating['description'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _getGradeColor(activityRating['grade'] ?? 'N/A'),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Ada Section
                      _buildDetailSection('Ada (Michango ya Mwezi)', [
                        _buildDetailRow('Jumla iliyolipwa', 'TZS ${_currencyFormat.format(_parseNum(ada['total_paid']))}'),
                        _buildDetailRow('Faini', 'TZS ${_currencyFormat.format(_parseNum(ada['total_penalties']))}'),
                        _buildDetailRow('Miezi iliyolipwa', '${_parseNum(ada['months_paid']).toInt()}'),
                        _buildDetailRow('Kiwango cha ulipaji', '${_parseNum(ada['compliance_rate']).toStringAsFixed(0)}%'),
                      ]),
                      const SizedBox(height: 16),
                      // Hisa Section
                      _buildDetailSection('Hisa', [
                        _buildDetailRow('Jumla ya mchango', 'TZS ${_currencyFormat.format(_parseNum(hisa['total_contributions']))}'),
                        _buildDetailRow('Thamani ya hisa', 'TZS ${_currencyFormat.format(_parseNum(hisa['total_shares']))}'),
                        _buildDetailRow('Asilimia', '${_parseNum(hisa['share_percentage']).toStringAsFixed(2)}%'),
                      ]),
                      const SizedBox(height: 16),
                      // Akiba Section
                      _buildDetailSection('Akiba', [
                        _buildDetailRow('Salio', 'TZS ${_currencyFormat.format(_parseNum(akiba['current_balance']))}'),
                        _buildDetailRow('Amana', 'TZS ${_currencyFormat.format(_parseNum(akiba['total_deposits']))}'),
                        _buildDetailRow('Kutoa', 'TZS ${_currencyFormat.format(_parseNum(akiba['total_withdrawals']))}'),
                        _buildDetailRow('Miamala', '${_parseNum(akiba['transaction_count']).toInt()}'),
                      ]),
                      const SizedBox(height: 16),
                      // Loans Section
                      _buildDetailSection('Mikopo', [
                        _buildDetailRow('Mikopo hai', '${_parseNum(loanSummary['active_loans']).toInt()}'),
                        _buildDetailRow('Jumla iliyokopwa', 'TZS ${_currencyFormat.format(_parseNum(loanSummary['total_borrowed']))}'),
                        _buildDetailRow('Imelipwa', 'TZS ${_currencyFormat.format(_parseNum(loanSummary['total_repaid']))}'),
                        _buildDetailRow('Deni', 'TZS ${_currencyFormat.format(_parseNum(loanSummary['outstanding_balance']))}'),
                      ]),
                      const SizedBox(height: 16),
                      // Mchango Section
                      _buildDetailSection('Mchango', [
                        _buildDetailRow('Jumla ya mchango', 'TZS ${_currencyFormat.format(_parseNum(mchangoSummary['total_contributed']))}'),
                        _buildDetailRow('Michango', '${_parseNum(mchangoSummary['contribution_count']).toInt()}'),
                        _buildDetailRow('Maombi', '${_parseNum(mchangoSummary['requests_made']).toInt()}'),
                        _buildDetailRow('Aliyopokea', 'TZS ${_currencyFormat.format(_parseNum(mchangoSummary['received_amount']))}'),
                      ]),
                      const SizedBox(height: 32),
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

  Widget _buildDetailSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return const Color(0xFF4CAF50);
      case 'B':
        return const Color(0xFF8BC34A);
      case 'C':
        return const Color(0xFFFFC107);
      case 'D':
        return const Color(0xFFFF9800);
      case 'E':
        return const Color(0xFFFF5722);
      case 'F':
        return const Color(0xFFF44336);
      default:
        return accentColor;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return accentColor;
    }
  }
}
