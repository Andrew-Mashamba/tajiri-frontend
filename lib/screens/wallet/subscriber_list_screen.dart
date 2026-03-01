import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/subscription_models.dart';
import '../../services/subscription_service.dart';
import '../../widgets/subscription_card_widget.dart';

/// Screen showing creator's subscriber list with tier filtering
class SubscriberListScreen extends StatefulWidget {
  final int currentUserId;

  const SubscriberListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<SubscriberListScreen> createState() => _SubscriberListScreenState();
}

class _SubscriberListScreenState extends State<SubscriberListScreen> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  final SubscriptionService _subscriptionService = SubscriptionService();

  List<Subscription> _subscribers = [];
  List<SubscriptionTier> _tiers = [];
  int? _selectedTierId;
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Load tiers for filter and subscribers
    final tiersResult = await _subscriptionService.getCreatorTiers(widget.currentUserId);
    final subscribersResult = await _subscriptionService.getSubscribers(
      userId: widget.currentUserId,
      page: 1,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (tiersResult.success) {
        _tiers = tiersResult.tiers;
      }
      if (subscribersResult.success) {
        _subscribers = subscribersResult.subscriptions;
        _lastPage = subscribersResult.meta?.lastPage ?? 1;
        _totalCount = subscribersResult.meta?.total ?? 0;
      } else {
        _error = subscribersResult.message;
      }
    });
  }

  Future<void> _loadSubscribers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _subscriptionService.getSubscribers(
      userId: widget.currentUserId,
      page: _page,
      tierId: _selectedTierId,
    );

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _isLoading = false;
        _subscribers = result.subscriptions;
        _lastPage = result.meta?.lastPage ?? 1;
        _totalCount = result.meta?.total ?? 0;
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

    final result = await _subscriptionService.getSubscribers(
      userId: widget.currentUserId,
      page: _page,
      tierId: _selectedTierId,
    );

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _loadingMore = false;
        _subscribers.addAll(result.subscriptions);
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    _page = 1;
    await _loadSubscribers();
  }

  void _selectTier(int? tierId) {
    if (tierId == _selectedTierId) return;
    setState(() {
      _selectedTierId = tierId;
      _page = 1;
    });
    _loadSubscribers();
  }

  void _openSubscriberProfile(Subscription subscription) {
    final subscriber = subscription.subscriber;
    if (subscriber != null) {
      Navigator.pushNamed(context, '/profile/${subscriber.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(s?.mySubscribers ?? 'My Subscribers'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tier filter chips
            if (_tiers.isNotEmpty) _buildTierFilter(s),

            // Total count
            if (!_isLoading && _error == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${s?.totalSubscribers ?? 'Total'}: $_totalCount',
                      style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState(s)
                      : _subscribers.isEmpty
                          ? _buildEmptyState(s)
                          : _buildSubscribersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierFilter(AppStrings? s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip(
              label: s?.allSubscriptions ?? 'All',
              isSelected: _selectedTierId == null,
              onTap: () => _selectTier(null),
            ),
            const SizedBox(width: 8),
            ..._tiers.map((tier) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: tier.name,
                    isSelected: _selectedTierId == tier.id,
                    onTap: () => _selectTier(tier.id),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? _kPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _kPrimary : _kSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _kPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
              onPressed: _loadSubscribers,
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
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              s?.noSubscribersYet ?? 'No subscribers yet',
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s?.createContentToAttract ?? 'Create great content to attract subscribers',
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribersList() {
    final hasMore = _page < _lastPage;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _subscribers.length + (hasMore || _loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _subscribers.length) {
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

          final subscription = _subscribers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SubscriberCard(
              subscription: subscription,
              onTap: () => _openSubscriberProfile(subscription),
            ),
          );
        },
      ),
    );
  }
}
