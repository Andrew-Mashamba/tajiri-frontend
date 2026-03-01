import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/subscription_models.dart';
import '../../services/subscription_service.dart';
import '../../widgets/subscription_card_widget.dart';
import 'subscription_detail_screen.dart';

/// Screen showing user's active and expired subscriptions
class MySubscriptionsScreen extends StatefulWidget {
  final int currentUserId;

  const MySubscriptionsScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  final SubscriptionService _subscriptionService = SubscriptionService();

  late TabController _tabController;
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  String _currentStatus = 'active';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final statuses = ['active', 'expired', ''];
    final newStatus = statuses[_tabController.index];
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _page = 1;
      _loadSubscriptions();
    }
  }

  Future<void> _loadSubscriptions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _subscriptionService.getMySubscriptions(
      userId: widget.currentUserId,
      page: _page,
      status: _currentStatus.isNotEmpty ? _currentStatus : null,
    );

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _isLoading = false;
        _subscriptions = result.subscriptions;
        _lastPage = result.meta?.lastPage ?? 1;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result.message;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;

    setState(() => _loadingMore = true);
    _page++;

    final result = await _subscriptionService.getMySubscriptions(
      userId: widget.currentUserId,
      page: _page,
      status: _currentStatus.isNotEmpty ? _currentStatus : null,
    );

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _loadingMore = false;
        _subscriptions.addAll(result.subscriptions);
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    _page = 1;
    await _loadSubscriptions();
  }

  Future<void> _toggleAutoRenew(Subscription subscription, bool value) async {
    final result = await _subscriptionService.toggleAutoRenew(
      userId: widget.currentUserId,
      subscriptionId: subscription.id,
      autoRenew: value,
    );

    if (!mounted) return;
    if (result.success) {
      // Update local state
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        // Reload to get updated subscription
        _loadSubscriptions();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? (AppStringsScope.of(context)?.autoRenewalOn ?? 'Auto-renewal enabled')
                : (AppStringsScope.of(context)?.autoRenewalOff ?? 'Auto-renewal disabled'),
          ),
        ),
      );
    }
  }

  void _openSubscriptionDetail(Subscription subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionDetailScreen(
          subscription: subscription,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((_) => _loadSubscriptions());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(s?.mySubscriptions ?? 'My Subscriptions'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          tabs: [
            Tab(text: s?.activeSubscriptions ?? 'Active'),
            Tab(text: s?.expiredSubscriptions ?? 'Expired'),
            Tab(text: s?.allSubscriptions ?? 'All'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(s)
                : _subscriptions.isEmpty
                    ? _buildEmptyState(s)
                    : _buildSubscriptionsList(s),
      ),
    );
  }

  Widget _buildErrorState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? s?.loadingFailed ?? 'Failed to load',
              style: const TextStyle(color: _kPrimary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadSubscriptions,
              child: Text(s?.retry ?? 'Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              s?.noSubscriptionsYet ?? 'You have no subscriptions yet',
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to creators to access exclusive content',
              style: TextStyle(
                color: _kSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to discover/search
                Navigator.pushNamed(context, '/search');
              },
              icon: const Icon(Icons.explore, size: 20),
              label: Text(s?.discoverCreators ?? 'Discover Creators'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(AppStrings? s) {
    final hasMore = _page < _lastPage;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _subscriptions.length + (hasMore || _loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _subscriptions.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            if (hasMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
            }
            return const SizedBox.shrink();
          }

          final subscription = _subscriptions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SubscriptionCard(
              subscription: subscription,
              onTap: () => _openSubscriptionDetail(subscription),
              showAutoRenewToggle: subscription.isActive,
              onAutoRenewToggle: subscription.isActive
                  ? (value) => _toggleAutoRenew(subscription, value)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
