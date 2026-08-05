import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../affiliate/screens/affiliate_dashboard_screen.dart';
import '../../affiliate/screens/commission_history_screen.dart';
import '../../affiliate/screens/influencer_payouts_screen.dart';
import '../../affiliate/screens/referral_links_screen.dart';
import '../../buyer/screens/cart_screen.dart';
import '../../buyer/screens/category_screen.dart';
import '../../buyer/screens/checkout_screen.dart';
import '../../buyer/screens/flash_deals_screen.dart';
import '../../buyer/screens/marketplace_screen.dart';
import '../../buyer/screens/nearby_products_screen.dart';
import '../../buyer/screens/order_detail_screen.dart';
import '../../buyer/screens/order_tracking_screen.dart';
import '../../buyer/screens/product_detail_screen.dart';
import '../../buyer/screens/recently_viewed_screen.dart';
import '../../buyer/screens/recommended_products_screen.dart';
import '../../buyer/screens/seller_shop_profile_screen.dart';
import '../../buyer/screens/service_detail_screen.dart';
import '../../buyer/screens/shop_screen.dart';
import '../../buyer/screens/wishlist_screen.dart';
import '../../chat/screens/customer_support_screen.dart';
import '../../chat/screens/seller_inbox_screen.dart';
import '../../chat/screens/shop_chat_screen.dart';
import '../../inventory/screens/restock_alerts_screen.dart';
import '../../inventory/screens/stock_management_screen.dart';
import '../../inventory/screens/warehouse_screen.dart';
import '../../live/screens/live_auction_screen.dart';
import '../../live/screens/live_product_showcase_screen.dart';
import '../../live/screens/live_stream_screen.dart';
import '../../moderation/screens/banned_sellers_screen.dart';
import '../../moderation/screens/moderation_queue_screen.dart';
import '../../moderation/screens/reported_products_screen.dart';
import '../../payments/screens/payment_methods_screen.dart';
import '../../payments/screens/payout_methods_screen.dart';
import '../../payments/screens/shop_wallet_screen.dart';
import '../../payments/screens/transaction_history_screen.dart';
import '../../reviews/screens/product_reviews_list_screen.dart';
import '../../reviews/screens/seller_reviews_screen.dart';
import '../../reviews/screens/write_review_screen.dart';
import '../../search/screens/shop_search_results_screen.dart';
import '../../search/screens/shop_search_screen.dart';
import '../../search/screens/trending_searches_screen.dart';
import '../../seller/screens/ad_campaigns_screen.dart';
import '../../seller/screens/boost_post_screen.dart';
import '../../seller/screens/create_product_post_screen.dart';
import '../../seller/screens/create_product_screen.dart';
import '../../seller/screens/create_service_post_screen.dart';
import '../../seller/screens/create_shop_ad_screen.dart';
import '../../seller/screens/my_shop_screen.dart';
import '../../seller/screens/promotions_screen.dart';
import '../../seller/screens/seller_analytics_screen.dart';
import '../../seller/screens/seller_inventory_screen.dart';
import '../../seller/screens/seller_notifications_screen.dart';
import '../../seller/screens/seller_orders_screen.dart';
import '../../seller/screens/seller_payouts_screen.dart';
import '../../seller/screens/seller_wallet_screen.dart';
import '../../seller/screens/service_editor_screen.dart';
import '../../seller/screens/shop_customization_screen.dart';
import '../../shipping/screens/delivery_zones_screen.dart';
import '../../shipping/screens/shipment_tracking_screen.dart';
import '../../shipping/screens/shipping_methods_screen.dart';
import '../../social_commerce/screens/creator_shop_screen.dart';
import '../../social_commerce/screens/live_shopping_screen.dart';
import '../../social_commerce/screens/product_posts_screen.dart';
import '../../social_commerce/screens/service_posts_screen.dart';
import '../../social_commerce/screens/shoppable_feed_screen.dart';
import '../../social_commerce/screens/social_product_detail_screen.dart';
import '../../social_commerce/screens/sponsored_posts_screen.dart';
import '../../social_commerce/screens/trending_products_screen.dart';
import '../../subscriptions/screens/creator_membership_screen.dart';
import '../../subscriptions/screens/premium_seller_screen.dart';
import '../../subscriptions/screens/subscription_plans_screen.dart';

// DESIGN.md monochrome tokens
const Color _kBackground   = Color(0xFFFAFAFA);
const Color _kSurface      = Color(0xFFFFFFFF);
const Color _kPrimaryText  = Color(0xFF1A1A1A);

class ShopFeatureHubScreen extends StatefulWidget {
  const ShopFeatureHubScreen({
    super.key,
    required this.currentUserId,
    this.allowedGroups,
    this.titleOverride,
  });
  final int currentUserId;
  final List<String>? allowedGroups;
  final String? titleOverride;

  @override
  State<ShopFeatureHubScreen> createState() => _ShopFeatureHubScreenState();
}

class _ShopFeatureHubScreenState extends State<ShopFeatureHubScreen> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  // Cached once — never rebuilt on setState (fix: issue type 6 logic bug)
  late final List<_Entry> _entries;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final demoCategory = ProductCategory(id: 1, name: 'General', slug: 'general');
    final demoProduct = Product(
      id: 1,
      sellerId: widget.currentUserId,
      title: 'Demo product',
      slug: 'demo-product',
      price: 0,
      createdAt: now,
      updatedAt: now,
    );
    final demoOrder = Order(
      id: 1,
      orderNumber: 'DEMO-1',
      buyerId: widget.currentUserId,
      sellerId: widget.currentUserId,
      productId: demoProduct.id,
      quantity: 1,
      unitPrice: 0,
      subtotal: 0,
      totalAmount: 0,
      createdAt: now,
      updatedAt: now,
      product: demoProduct,
    );

    _entries = [
      _Entry(group: 'affiliate', title: 'Affiliate Dashboard', builder: (_) => AffiliateDashboardScreen()),
      _Entry(group: 'affiliate', title: 'Commission History', builder: (_) => CommissionHistoryScreen()),
      _Entry(group: 'affiliate', title: 'Influencer Payouts', builder: (_) => InfluencerPayoutsScreen()),
      _Entry(group: 'affiliate', title: 'Referral Links', builder: (_) => ReferralLinksScreen()),
      _Entry(group: 'buyer', title: 'Cart', builder: (_) => CartScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Category', builder: (_) => CategoryScreen(category: demoCategory, currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Checkout', builder: (_) => CheckoutScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Flash Deals', builder: (_) => FlashDealsScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Marketplace', builder: (_) => MarketplaceScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Nearby Products', builder: (_) => NearbyProductsScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Order Detail', builder: (_) => OrderDetailScreen(orderId: demoOrder.id, currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Order Tracking', builder: (_) => OrderTrackingScreen(order: demoOrder)),
      _Entry(group: 'buyer', title: 'Product Detail', builder: (_) => ProductDetailScreen(productId: demoProduct.id, currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Recently Viewed', builder: (_) => RecentlyViewedScreen()),
      _Entry(group: 'buyer', title: 'Recommended Products', builder: (_) => RecommendedProductsScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Seller Shop Profile', builder: (_) => SellerShopProfileScreen(sellerId: widget.currentUserId, currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Service Detail', builder: (_) => ServiceDetailScreen(productId: demoProduct.id, currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Shop', builder: (_) => ShopScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'buyer', title: 'Wishlist', builder: (_) => WishlistScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'chat', title: 'Customer Support', builder: (_) => CustomerSupportScreen()),
      _Entry(group: 'chat', title: 'Seller Inbox', builder: (_) => SellerInboxScreen()),
      _Entry(group: 'chat', title: 'Shop Chat', builder: (_) => ShopChatScreen()),
      _Entry(group: 'inventory', title: 'Restock Alerts', builder: (_) => RestockAlertsScreen()),
      _Entry(group: 'inventory', title: 'Stock Management', builder: (_) => StockManagementScreen()),
      _Entry(group: 'inventory', title: 'Warehouse', builder: (_) => WarehouseScreen()),
      _Entry(group: 'live', title: 'Live Auction', builder: (_) => LiveAuctionScreen()),
      _Entry(group: 'live', title: 'Live Product Showcase', builder: (_) => LiveProductShowcaseScreen()),
      _Entry(group: 'live', title: 'Live Stream', builder: (_) => LiveStreamScreen()),
      _Entry(group: 'moderation', title: 'Banned Sellers', builder: (_) => BannedSellersScreen()),
      _Entry(group: 'moderation', title: 'Moderation Queue', builder: (_) => ModerationQueueScreen()),
      _Entry(group: 'moderation', title: 'Reported Products', builder: (_) => ReportedProductsScreen()),
      _Entry(group: 'payments', title: 'Payment Methods', builder: (_) => PaymentMethodsScreen()),
      _Entry(group: 'payments', title: 'Payout Methods', builder: (_) => PayoutMethodsScreen()),
      _Entry(group: 'payments', title: 'Shop Wallet', builder: (_) => ShopWalletScreen(userId: widget.currentUserId)),
      _Entry(group: 'payments', title: 'Transaction History', builder: (_) => TransactionHistoryScreen()),
      _Entry(group: 'reviews', title: 'Product Reviews', builder: (_) => ProductReviewsListScreen(productId: demoProduct.id, currentUserId: widget.currentUserId)),
      _Entry(group: 'reviews', title: 'Seller Reviews', builder: (_) => SellerReviewsScreen()),
      _Entry(group: 'reviews', title: 'Write Review', builder: (_) => WriteReviewScreen()),
      _Entry(group: 'search', title: 'Search Results', builder: (_) => ShopSearchResultsScreen(query: 'demo', currentUserId: widget.currentUserId)),
      _Entry(group: 'search', title: 'Search', builder: (_) => ShopSearchScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'search', title: 'Trending Searches', builder: (_) => TrendingSearchesScreen()),
      _Entry(group: 'seller', title: 'Ad Campaigns', builder: (_) => AdCampaignsScreen()),
      _Entry(group: 'seller', title: 'Boost Post', builder: (_) => BoostPostScreen()),
      _Entry(group: 'seller', title: 'Create Product Post', builder: (_) => CreateProductPostScreen()),
      _Entry(group: 'seller', title: 'Create Product', builder: (_) => CreateProductScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'seller', title: 'Create Service Post', builder: (_) => CreateServicePostScreen()),
      _Entry(group: 'seller', title: 'Create Shop Ad', builder: (_) => CreateShopAdScreen()),
      _Entry(group: 'seller', title: 'My Shop', builder: (_) => MyShopScreen(userId: widget.currentUserId)),
      _Entry(group: 'seller', title: 'Promotions', builder: (_) => PromotionsScreen()),
      _Entry(group: 'seller', title: 'Seller Analytics', builder: (_) => SellerAnalyticsScreen(sellerId: widget.currentUserId)),
      _Entry(group: 'seller', title: 'Seller Inventory', builder: (_) => SellerInventoryScreen(sellerId: widget.currentUserId)),
      _Entry(group: 'seller', title: 'Seller Notifications', builder: (_) => SellerNotificationsScreen()),
      _Entry(group: 'seller', title: 'Seller Orders', builder: (_) => SellerOrdersScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'seller', title: 'Seller Payouts', builder: (_) => SellerPayoutsScreen()),
      _Entry(group: 'seller', title: 'Seller Wallet', builder: (_) => SellerWalletScreen()),
      _Entry(group: 'seller', title: 'Service Editor', builder: (_) => ServiceEditorScreen()),
      _Entry(group: 'seller', title: 'Shop Customization', builder: (_) => ShopCustomizationScreen()),
      _Entry(group: 'shipping', title: 'Delivery Zones', builder: (_) => DeliveryZonesScreen()),
      _Entry(group: 'shipping', title: 'Shipment Tracking', builder: (_) => ShipmentTrackingScreen()),
      _Entry(group: 'shipping', title: 'Shipping Methods', builder: (_) => ShippingMethodsScreen()),
      _Entry(group: 'social_commerce', title: 'Creator Shop', builder: (_) => CreatorShopScreen()),
      _Entry(group: 'social_commerce', title: 'Live Shopping', builder: (_) => LiveShoppingScreen()),
      _Entry(group: 'social_commerce', title: 'Product Posts', builder: (_) => ProductPostsScreen()),
      _Entry(group: 'social_commerce', title: 'Service Posts', builder: (_) => ServicePostsScreen()),
      _Entry(group: 'social_commerce', title: 'Shoppable Feed', builder: (_) => ShoppableFeedScreen()),
      _Entry(group: 'social_commerce', title: 'Social Product Detail', builder: (_) => SocialProductDetailScreen()),
      _Entry(group: 'social_commerce', title: 'Sponsored Posts', builder: (_) => SponsoredPostsScreen()),
      _Entry(group: 'social_commerce', title: 'Trending Products', builder: (_) => TrendingProductsScreen(currentUserId: widget.currentUserId)),
      _Entry(group: 'subscriptions', title: 'Creator Membership', builder: (_) => CreatorMembershipScreen()),
      _Entry(group: 'subscriptions', title: 'Premium Seller', builder: (_) => PremiumSellerScreen()),
      _Entry(group: 'subscriptions', title: 'Subscription Plans', builder: (_) => SubscriptionPlansScreen()),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Refresh = clear search and reset view (no API — entries are static)
  Future<void> _onRefresh() async {
    _searchController.clear();
    if (!mounted) return;
    setState(() => _query = '');
  }

  List<_Entry> get _filtered {
    final allowedGroups = widget.allowedGroups?.map((g) => g.toLowerCase()).toSet();
    final scoped = allowedGroups == null
        ? _entries
        : _entries.where((e) => allowedGroups.contains(e.group)).toList();
    final q = _query.trim().toLowerCase();
    final result = q.isEmpty
        ? List<_Entry>.of(scoped)
        : scoped.where((e) => e.title.toLowerCase().contains(q) || e.group.contains(q)).toList();
    result.sort((a, b) {
      final g = a.group.compareTo(b.group);
      return g != 0 ? g : a.title.compareTo(b.title);
    });
    return result;
  }

  static IconData _groupIcon(String group) {
    switch (group) {
      case 'affiliate':       return Icons.people_alt_rounded;
      case 'buyer':           return Icons.shopping_cart_rounded;
      case 'chat':            return Icons.chat_bubble_rounded;
      case 'inventory':       return Icons.inventory_2_rounded;
      case 'live':            return Icons.live_tv_rounded;
      case 'moderation':      return Icons.shield_rounded;
      case 'payments':        return Icons.account_balance_wallet_rounded;
      case 'reviews':         return Icons.star_rounded;
      case 'search':          return Icons.search_rounded;
      case 'seller':          return Icons.store_rounded;
      case 'shipping':        return Icons.local_shipping_rounded;
      case 'social_commerce': return Icons.trending_up_rounded;
      case 'subscriptions':   return Icons.workspace_premium_rounded;
      default:                return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final groupCounts = <String, int>{};
    for (final e in filtered) {
      groupCounts.update(e.group, (v) => v + 1, ifAbsent: () => 1);
    }

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          widget.titleOverride ?? 'Shop Features Hub',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _kBackground,
        foregroundColor: _kPrimaryText,
        surfaceTintColor: _kBackground,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search shop features',
                  filled: true,
                  fillColor: _kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimaryText),
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            // Summary pills — results & groups count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Expanded(child: _buildSummaryPill(label: 'Results', value: '${filtered.length}')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryPill(label: 'Groups', value: '${groupCounts.length}')),
                ],
              ),
            ),
            // Grid or empty state
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: _kPrimaryText,
                      onRefresh: _onRefresh,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 1100
                              ? 4
                              : constraints.maxWidth >= 760
                                  ? 3
                                  : 2;
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) => _buildCard(
                              context,
                              entry: filtered[i],
                              groupCount: groupCounts[filtered[i].group] ?? 0,
                              totalShown: filtered.length,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required _Entry entry,
    required int groupCount,
    required int totalShown,
  }) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: entry.builder)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _groupIcon(entry.group),
                      size: 20,
                      color: _kPrimaryText,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.group,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _kPrimaryText,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildSummaryPill(label: 'In group', value: '$groupCount')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildSummaryPill(label: 'Shown', value: '$totalShown')),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryText.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: _kPrimaryText.withValues(alpha: 0.7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasQuery = _query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No matching features' : 'No features available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Try another search keyword.'
                  : 'Features will appear here once available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry({required this.group, required this.title, required this.builder});
  final String group;
  final String title;
  final WidgetBuilder builder;
}
