#!/usr/bin/env python3
"""Generate remaining docs/shop/shop.md paths under lib/shop/. Idempotent."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHOP = ROOT / "lib" / "shop"


def hdr(rel: str) -> str:
    return f"// Blueprint: docs/shop/shop.md — {rel}\n"


def write(rel: str, body: str) -> None:
    p = SHOP / rel
    if p.exists():
        return
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(body.rstrip() + "\n", encoding="utf-8")


def svc(name: str) -> str:
    return (
        hdr(f"services/{name}")
        + """import '../../integrations/shop_extended_api.dart';
import '../../data/repositories/shop_repository.dart';

class %s {
  %s({ShopExtendedApi? api, ShopRepository? repo})
      : _api = api ?? ShopExtendedApi(),
        _repo = repo ?? ShopRepository.instance;
  final ShopExtendedApi _api;
  final ShopRepository _repo;

  ShopExtendedApi get api => _api;
  ShopRepository get repository => _repo;
}
"""
        % (name, name)
    )


def prov(name: str) -> str:
    return (
        hdr(f"state/{name}")
        + """import 'package:flutter/foundation.dart';

class %s extends ChangeNotifier {
  %s();
}
"""
        % (name, name)
    )


def wgt(name: str) -> str:
    return (
        hdr(f"widgets/{name}")
        + """import 'package:flutter/material.dart';

class %s extends StatelessWidget {
  const %s({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
"""
        % (name, name)
    )


def scr(name: str) -> str:
    return (
        hdr(f"screens/{name}")
        + """import 'package:flutter/material.dart';

class %s extends StatelessWidget {
  const %s({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('%s')),
      body: const Center(child: Text('Shop blueprint surface')),
    );
  }
}
"""
        % (name, name, name)
    )


# --- ads ---
ADS = [
    ("ads/campaigns/campaign_builder.dart", "CampaignBuilder", svc),
    ("ads/campaigns/campaign_scheduler.dart", "CampaignScheduler", svc),
    ("ads/targeting/audience_segment.dart", "AudienceSegment", svc),
    ("ads/targeting/targeting_engine.dart", "TargetingEngine", svc),
    ("ads/targeting/demographic_targeting.dart", "DemographicTargeting", svc),
    ("ads/targeting/geographic_targeting.dart", "GeographicTargeting", svc),
    ("ads/targeting/behavioral_targeting.dart", "BehavioralTargeting", svc),
    ("ads/targeting/retargeting_engine.dart", "RetargetingEngine", svc),
    ("ads/billing/ad_budget_manager.dart", "AdBudgetManager", svc),
    ("ads/billing/billing_service.dart", "AdsBillingService", svc),
    ("ads/billing/invoice_generator.dart", "InvoiceGenerator", svc),
    ("ads/billing/cost_calculator.dart", "CostCalculator", svc),
    ("ads/billing/ad_spending_tracker.dart", "AdSpendingTracker", svc),
    ("ads/creatives/creative_builder.dart", "CreativeBuilder", svc),
    ("ads/creatives/creative_library.dart", "CreativeLibrary", svc),
    ("ads/creatives/ad_templates.dart", "AdTemplates", svc),
    ("ads/creatives/creative_optimizer.dart", "CreativeOptimizer", svc),
    ("ads/creatives/a_b_test_manager.dart", "ABTestManager", svc),
    ("ads/analytics/campaign_analytics.dart", "CampaignAnalytics", svc),
    ("ads/analytics/impression_tracker.dart", "ImpressionTracker", svc),
    ("ads/analytics/click_tracker.dart", "ClickTracker", svc),
    ("ads/analytics/conversion_tracker.dart", "ConversionTracker", svc),
    ("ads/analytics/roi_calculator.dart", "RoiCalculator", svc),
    ("ads/analytics/performance_report.dart", "PerformanceReport", svc),
    ("ads/moderation/ad_review_queue.dart", "AdReviewQueue", svc),
    ("ads/moderation/content_checker.dart", "ContentChecker", svc),
    ("ads/moderation/policy_enforcer.dart", "PolicyEnforcer", svc),
    ("ads/moderation/approval_workflow.dart", "ApprovalWorkflow", svc),
    ("ads/delivery/ad_server.dart", "AdServer", svc),
    ("ads/delivery/ad_auction_engine.dart", "AdAuctionEngine", svc),
    ("ads/delivery/frequency_capper.dart", "FrequencyCapper", svc),
    ("ads/delivery/ad_placement_engine.dart", "AdPlacementEngine", svc),
    ("ads/delivery/delivery_optimizer.dart", "DeliveryOptimizer", svc),
]

# --- social_commerce ---
SOC = [
    ("social_commerce/screens/shoppable_feed_screen.dart", "ShoppableFeedScreen", scr),
    ("social_commerce/screens/product_posts_screen.dart", "ProductPostsScreen", scr),
    ("social_commerce/screens/service_posts_screen.dart", "ServicePostsScreen", scr),
    ("social_commerce/screens/sponsored_posts_screen.dart", "SponsoredPostsScreen", scr),
    ("social_commerce/screens/creator_shop_screen.dart", "CreatorShopScreen", scr),
    ("social_commerce/screens/live_shopping_screen.dart", "LiveShoppingScreen", scr),
    ("social_commerce/screens/social_product_detail_screen.dart", "SocialProductDetailScreen", scr),
    ("social_commerce/widgets/shoppable_post_card.dart", "ShoppablePostCard", wgt),
    ("social_commerce/widgets/sponsored_post_card.dart", "SponsoredPostCard", wgt),
    ("social_commerce/widgets/buy_now_overlay.dart", "BuyNowOverlay", wgt),
    ("social_commerce/widgets/tagged_products_section.dart", "TaggedProductsSection", wgt),
    ("social_commerce/widgets/creator_profile_header.dart", "CreatorProfileHeader", wgt),
    ("social_commerce/widgets/engagement_bar.dart", "EngagementBar", wgt),
    ("social_commerce/components/create_post_caption_section.dart", "CreatePostCaptionSection", wgt),
    ("social_commerce/components/tagged_products_picker.dart", "TaggedProductsPicker", wgt),
    ("social_commerce/components/audience_targeting_section.dart", "AudienceTargetingSection", wgt),
    ("social_commerce/components/post_boost_section.dart", "PostBoostSection", wgt),
    ("social_commerce/state/social_feed_provider.dart", "SocialFeedProvider", prov),
    ("social_commerce/state/social_posts_provider.dart", "SocialPostsProvider", prov),
    ("social_commerce/state/sponsored_posts_provider.dart", "SponsoredPostsProvider", prov),
    ("social_commerce/state/live_shopping_provider.dart", "LiveShoppingProvider", prov),
]

# --- search extras ---
SEA = [
    ("search/screens/trending_searches_screen.dart", "TrendingSearchesScreen", scr),
    ("search/widgets/search_bar.dart", "ShopSearchBar", wgt),
    ("search/widgets/recent_searches.dart", "RecentSearches", wgt),
    ("search/widgets/trending_search_chip.dart", "TrendingSearchChip", wgt),
    ("search/widgets/voice_search_button.dart", "VoiceSearchButton", wgt),
    ("search/repositories/search_repository.dart", "SearchRepository", svc),
    ("search/services/search_service.dart", "ShopSearchService", svc),
    ("search/services/ai_search_service.dart", "AiSearchService", svc),
    ("search/state/search_provider.dart", "SearchProvider", prov),
]

# --- checkout ---
CHK = [
    ("checkout/flow/shipping_step.dart", "ShippingStep", wgt),
    ("checkout/flow/payment_step.dart", "PaymentStep", wgt),
    ("checkout/flow/review_step.dart", "ReviewStep", wgt),
    ("checkout/flow/confirmation_step.dart", "ConfirmationStep", wgt),
    ("checkout/widgets/order_summary_card.dart", "OrderSummaryCard", wgt),
    ("checkout/state/checkout_flow_provider.dart", "CheckoutFlowProvider", prov),
]

# --- payments ---
PAY = [
    ("payments/screens/payment_methods_screen.dart", "PaymentMethodsScreen", scr),
    ("payments/screens/transaction_history_screen.dart", "TransactionHistoryScreen", scr),
    ("payments/screens/payout_methods_screen.dart", "PayoutMethodsScreen", scr),
    ("payments/repositories/payments_repository.dart", "PaymentsRepository", svc),
    ("payments/repositories/wallet_repository.dart", "WalletRepository", svc),
    ("payments/gateways/stripe_gateway.dart", "StripeGateway", svc),
    ("payments/gateways/paypal_gateway.dart", "PaypalGateway", svc),
    ("payments/gateways/mobile_money_gateway.dart", "MobileMoneyGateway", svc),
    ("payments/widgets/payment_method_tile.dart", "PaymentMethodTile", wgt),
    ("payments/widgets/wallet_balance_card.dart", "WalletBalanceCard", wgt),
    ("payments/state/payments_provider.dart", "PaymentsProvider", prov),
]

# --- inventory (top-level package) ---
INV = [
    ("inventory/screens/stock_management_screen.dart", "StockManagementScreen", scr),
    ("inventory/screens/warehouse_screen.dart", "WarehouseScreen", scr),
    ("inventory/screens/restock_alerts_screen.dart", "RestockAlertsScreen", scr),
    ("inventory/services/inventory_service.dart", "InventoryService", svc),
    ("inventory/services/stock_sync_service.dart", "StockSyncService", svc),
    ("inventory/widgets/stock_level_indicator.dart", "StockLevelIndicator", wgt),
    ("inventory/widgets/inventory_history_card.dart", "InventoryHistoryCard", wgt),
    ("inventory/state/inventory_provider.dart", "InventoryProvider", prov),
]

# --- shipping ---
SHP = [
    ("shipping/screens/shipping_methods_screen.dart", "ShippingMethodsScreen", scr),
    ("shipping/screens/shipment_tracking_screen.dart", "ShipmentTrackingScreen", scr),
    ("shipping/screens/delivery_zones_screen.dart", "DeliveryZonesScreen", scr),
    ("shipping/services/shipping_service.dart", "ShippingService", svc),
    ("shipping/services/courier_service.dart", "CourierService", svc),
    ("shipping/services/tracking_service.dart", "TrackingService", svc),
    ("shipping/widgets/tracking_timeline.dart", "TrackingTimeline", wgt),
    ("shipping/widgets/delivery_estimate_card.dart", "DeliveryEstimateCard", wgt),
    ("shipping/state/shipping_provider.dart", "ShippingProvider", prov),
]

# --- reviews extras ---
REV = [
    ("reviews/screens/seller_reviews_screen.dart", "SellerReviewsScreen", scr),
    ("reviews/screens/write_review_screen.dart", "WriteReviewScreen", scr),
    ("reviews/repositories/reviews_repository.dart", "ReviewsRepository", svc),
    ("reviews/widgets/review_card.dart", "ReviewCard", wgt),
    ("reviews/widgets/rating_breakdown.dart", "RatingBreakdown", wgt),
    ("reviews/state/reviews_provider.dart", "ReviewsProvider", prov),
]

# --- chat ---
CHT = [
    ("chat/screens/shop_chat_screen.dart", "ShopChatScreen", scr),
    ("chat/screens/customer_support_screen.dart", "CustomerSupportScreen", scr),
    ("chat/widgets/message_bubble.dart", "MessageBubble", wgt),
    ("chat/widgets/product_share_message.dart", "ProductShareMessage", wgt),
    ("chat/widgets/typing_indicator.dart", "TypingIndicator", wgt),
    ("chat/services/chat_service.dart", "ShopChatService", svc),
    ("chat/services/realtime_messaging_service.dart", "RealtimeMessagingService", svc),
    ("chat/state/chat_provider.dart", "ChatProvider", prov),
]

# --- live ---
LIV = [
    ("live/screens/live_stream_screen.dart", "LiveStreamScreen", scr),
    ("live/screens/live_product_showcase_screen.dart", "LiveProductShowcaseScreen", scr),
    ("live/screens/live_auction_screen.dart", "LiveAuctionScreen", scr),
    ("live/widgets/live_chat_overlay.dart", "LiveChatOverlay", wgt),
    ("live/widgets/live_reactions_bar.dart", "LiveReactionsBar", wgt),
    ("live/widgets/pinned_product_card.dart", "PinnedProductCard", wgt),
    ("live/services/livestream_service.dart", "LivestreamService", svc),
    ("live/services/realtime_viewers_service.dart", "RealtimeViewersService", svc),
    ("live/state/livestream_provider.dart", "LivestreamProvider", prov),
]

# --- moderation ---
MOD = [
    ("moderation/screens/reported_products_screen.dart", "ReportedProductsScreen", scr),
    ("moderation/screens/moderation_queue_screen.dart", "ModerationQueueScreen", scr),
    ("moderation/screens/banned_sellers_screen.dart", "BannedSellersScreen", scr),
    ("moderation/services/moderation_service.dart", "ModerationService", svc),
    ("moderation/services/ai_moderation_service.dart", "AiModerationService", svc),
    ("moderation/widgets/moderation_action_bar.dart", "ModerationActionBar", wgt),
    ("moderation/widgets/report_reason_chip.dart", "ReportReasonChip", wgt),
    ("moderation/state/moderation_provider.dart", "ModerationProvider", prov),
]

# --- subscriptions ---
SUB = [
    ("subscriptions/screens/subscription_plans_screen.dart", "SubscriptionPlansScreen", scr),
    ("subscriptions/screens/creator_membership_screen.dart", "CreatorMembershipScreen", scr),
    ("subscriptions/screens/premium_seller_screen.dart", "PremiumSellerScreen", scr),
    ("subscriptions/widgets/subscription_plan_card.dart", "SubscriptionPlanCard", wgt),
    ("subscriptions/widgets/premium_badge.dart", "PremiumBadge", wgt),
    ("subscriptions/services/subscription_service.dart", "SubscriptionService", svc),
    ("subscriptions/state/subscription_provider.dart", "SubscriptionProvider", prov),
]

# --- affiliate ---
AFF = [
    ("affiliate/screens/affiliate_dashboard_screen.dart", "AffiliateDashboardScreen", scr),
    ("affiliate/screens/referral_links_screen.dart", "ReferralLinksScreen", scr),
    ("affiliate/screens/commission_history_screen.dart", "CommissionHistoryScreen", scr),
    ("affiliate/screens/influencer_payouts_screen.dart", "InfluencerPayoutsScreen", scr),
    ("affiliate/widgets/referral_link_card.dart", "ReferralLinkCard", wgt),
    ("affiliate/widgets/commission_summary_card.dart", "CommissionSummaryCard", wgt),
    ("affiliate/widgets/earnings_chart.dart", "EarningsChart", wgt),
    ("affiliate/models/affiliate_link_model.dart", "AffiliateLinkModel", None),
    ("affiliate/models/commission_model.dart", "CommissionModel", None),
    ("affiliate/models/payout_model.dart", "PayoutModel", None),
    ("affiliate/services/affiliate_service.dart", "AffiliateService", svc),
    ("affiliate/services/commission_tracker.dart", "CommissionTracker", svc),
    ("affiliate/state/affiliate_provider.dart", "AffiliateProvider", prov),
]

# --- ai ---
AI = [
    ("ai/recommendations/recommendation_engine.dart", "RecommendationEngine", svc),
    ("ai/recommendations/trending_detector.dart", "TrendingDetector", svc),
    ("ai/semantic_search/semantic_search_service.dart", "SemanticSearchService", svc),
    ("ai/semantic_search/query_intent_classifier.dart", "QueryIntentClassifier", svc),
    ("ai/moderation/ai_content_moderator.dart", "AiContentModerator", svc),
    ("ai/moderation/fake_review_detector.dart", "FakeReviewDetector", svc),
    ("ai/auto_tagging/auto_tagging_service.dart", "AutoTaggingService", svc),
    ("ai/smart_pricing/dynamic_pricing_engine.dart", "DynamicPricingEngine", svc),
    ("ai/smart_pricing/price_elasticity_model.dart", "PriceElasticityModel", svc),
    ("ai/ai_chat/shop_assistant.dart", "ShopAssistant", svc),
    ("ai/ai_chat/seller_support_bot.dart", "SellerSupportBot", svc),
    ("ai/content_generation/product_description_generator.dart", "ProductDescriptionGenerator", svc),
    ("ai/content_generation/ad_copy_generator.dart", "AdCopyGenerator", svc),
]

# --- analytics ---
AN = [
    ("analytics/tracking/analytics_tracker.dart", "AnalyticsTracker", svc),
    ("analytics/tracking/event_logger.dart", "EventLogger", svc),
    ("analytics/tracking/conversion_tracker.dart", "ConversionTracker", svc),
    ("analytics/events/product_viewed_event.dart", "ProductViewedEvent", None),
    ("analytics/events/add_to_cart_event.dart", "AddToCartEvent", None),
    ("analytics/events/checkout_started_event.dart", "CheckoutStartedEvent", None),
    ("analytics/events/purchase_completed_event.dart", "PurchaseCompletedEvent", None),
    ("analytics/events/ad_clicked_event.dart", "AdClickedEvent", None),
    ("analytics/services/analytics_service.dart", "ShopAnalyticsFacade", svc),
]

# --- notifications ---
NOT = [
    ("notifications/services/push_notification_service.dart", "ShopPushNotificationService", svc),
    ("notifications/services/in_app_notification_service.dart", "InAppNotificationService", svc),
    ("notifications/models/notification_model.dart", "ShopNotificationModel", None),
    ("notifications/state/notifications_provider.dart", "NotificationsProvider", prov),
]

# --- events (remaining) ---
EVT = [
    ("events/product_post_published_event.dart", "ProductPostPublishedEvent", None),
    ("events/ad_campaign_started_event.dart", "AdCampaignStartedEvent", None),
    ("events/livestream_started_event.dart", "LivestreamStartedEvent", None),
]

# --- testing ---
TST = [
    ("testing/fixtures/fake_orders.dart", "fake_orders", "fixture"),
    ("testing/fixtures/fake_sellers.dart", "fake_sellers", "fixture"),
    ("testing/mocks/mock_payment_service.dart", "MockPaymentService", "mock"),
    ("testing/mocks/mock_shipping_service.dart", "MockShippingService", "mock"),
    ("testing/factories/product_factory.dart", "ProductFactory", "factory"),
    ("testing/factories/order_factory.dart", "OrderFactory", "factory"),
]

# --- integrations ---
INT = [
    ("integrations/social/social_feed_service.dart", "SocialFeedShopBridge", svc),
    ("integrations/social/post_share_service.dart", "PostShareShopBridge", svc),
    ("integrations/social/social_engagement_service.dart", "SocialEngagementShopBridge", svc),
    ("integrations/maps/maps_service.dart", "MapsShopBridge", svc),
    ("integrations/maps/geolocation_service.dart", "GeolocationShopBridge", svc),
]

# --- common remaining ---
COM = [
    ("common/widgets/service_card.dart", "ServiceCard", wgt),
    ("common/widgets/seller_card.dart", "SellerCard", wgt),
    ("common/widgets/rating_stars.dart", "RatingStars", wgt),
    ("common/widgets/loading_indicator.dart", "LoadingIndicator", wgt),
    ("common/widgets/empty_state.dart", "EmptyState", wgt),
    ("common/widgets/price_tag.dart", "PriceTag", wgt),
    ("common/widgets/network_image_widget.dart", "NetworkImageWidget", wgt),
    ("common/dialogs/delete_confirmation_dialog.dart", "DeleteConfirmationDialog", wgt),
    ("common/dialogs/report_product_dialog.dart", "ReportProductDialog", wgt),
    ("common/dialogs/order_cancel_dialog.dart", "OrderCancelDialog", wgt),
    ("common/sheets/sort_bottom_sheet.dart", "SortBottomSheet", wgt),
    ("common/sheets/share_product_sheet.dart", "ShareProductSheet", wgt),
    ("common/loaders/product_shimmer.dart", "ProductShimmer", wgt),
    ("common/loaders/order_shimmer.dart", "OrderShimmer", wgt),
    ("common/loaders/analytics_shimmer.dart", "AnalyticsShimmer", wgt),
]

# --- seller extras ---
SEL = [
    ("seller/screens/service_editor_screen.dart", "ServiceEditorScreen", scr),
    ("seller/screens/seller_wallet_screen.dart", "SellerWalletScreen", scr),
    ("seller/screens/seller_payouts_screen.dart", "SellerPayoutsScreen", scr),
    ("seller/screens/shop_customization_screen.dart", "ShopCustomizationScreen", scr),
    ("seller/screens/create_product_post_screen.dart", "CreateProductPostScreen", scr),
    ("seller/screens/create_service_post_screen.dart", "CreateServicePostScreen", scr),
    ("seller/screens/create_shop_ad_screen.dart", "CreateShopAdScreen", scr),
    ("seller/screens/boost_post_screen.dart", "BoostPostScreen", scr),
    ("seller/screens/ad_campaigns_screen.dart", "AdCampaignsScreen", scr),
    ("seller/screens/promotions_screen.dart", "PromotionsScreen", scr),
    ("seller/screens/seller_notifications_screen.dart", "SellerNotificationsScreen", scr),
    ("seller/widgets/analytics_chart.dart", "AnalyticsChart", wgt),
    ("seller/widgets/sales_summary_card.dart", "SalesSummaryCard", wgt),
    ("seller/widgets/inventory_alert_card.dart", "InventoryAlertCard", wgt),
    ("seller/widgets/ad_budget_selector.dart", "AdBudgetSelector", wgt),
    ("seller/widgets/audience_selector.dart", "AudienceSelector", wgt),
    ("seller/widgets/campaign_performance_card.dart", "CampaignPerformanceCard", wgt),
    ("seller/components/product_form.dart", "ProductForm", wgt),
    ("seller/components/service_form.dart", "ServiceForm", wgt),
    ("seller/components/pricing_section.dart", "PricingSection", wgt),
    ("seller/components/media_upload_section.dart", "MediaUploadSection", wgt),
    ("seller/components/inventory_section.dart", "InventorySection", wgt),
    ("seller/components/shipping_options_section.dart", "ShippingOptionsSection", wgt),
    ("seller/state/seller_products_provider.dart", "SellerProductsProvider", prov),
    ("seller/state/seller_orders_provider.dart", "SellerOrdersProvider", prov),
    ("seller/state/seller_analytics_provider.dart", "SellerAnalyticsProvider", prov),
    ("seller/state/ads_provider.dart", "AdsProvider", prov),
    ("seller/state/promotions_provider.dart", "PromotionsProvider", prov),
]

# --- buyer extras ---
BUY = [
    ("buyer/widgets/featured_products_carousel.dart", "FeaturedProductsCarousel", wgt),
    ("buyer/widgets/category_grid.dart", "CategoryGrid", wgt),
    ("buyer/widgets/product_reviews_preview.dart", "ProductReviewsPreview", wgt),
    ("buyer/widgets/related_products_section.dart", "RelatedProductsSection", wgt),
    ("buyer/components/checkout_address_section.dart", "CheckoutAddressSection", wgt),
    ("buyer/components/checkout_payment_section.dart", "CheckoutPaymentSection", wgt),
    ("buyer/components/checkout_summary_section.dart", "CheckoutSummarySection", wgt),
    ("buyer/components/product_info_section.dart", "ProductInfoSection", wgt),
    ("buyer/components/seller_info_section.dart", "SellerInfoSection", wgt),
    ("buyer/state/wishlist_provider.dart", "WishlistProvider", prov),
    ("buyer/state/checkout_provider.dart", "CheckoutProvider", prov),
    ("buyer/state/marketplace_provider.dart", "MarketplaceProvider", prov),
]


def model_stub(name: str) -> str:
    return (
        hdr(f"models/{name}")
        + """/// Placeholder model — replace with fields when affiliate API stabilizes.
class %s {
  const %s();
}
"""
        % (name, name)
    )


def event_stub(name: str) -> str:
    return (
        hdr(f"events/{name}")
        + """class %s {
  const %s({this.payload});
  final Object? payload;
}
"""
        % (name, name)
    )


def analytics_event_stub(name: str) -> str:
    return event_stub(name)


def notif_model_stub(name: str) -> str:
    return (
        hdr(f"models/{name}")
        + """class ShopNotificationModel {
  const ShopNotificationModel({this.title});
  final String? title;
}
"""
    )


def fixture_orders() -> str:
    return (
        hdr("testing/fixtures/fake_orders.dart")
        + """import '../../../models/shop_models.dart';

List<Order> fakeShopOrders() => [];
"""
    )


def fixture_sellers() -> str:
    return (
        hdr("testing/fixtures/fake_sellers.dart")
        + """List<Map<String, dynamic>> fakeSellers() => [];
"""
    )


def mock_pay() -> str:
    return (
        hdr("testing/mocks/mock_payment_service.dart")
        + """class MockPaymentService {
  Future<bool> pay() async => true;
}
"""
    )


def mock_ship() -> str:
    return (
        hdr("testing/mocks/mock_shipping_service.dart")
        + """class MockShippingService {
  Future<double> quote() async => 0;
}
"""
    )


def factory_prod() -> str:
    return (
        hdr("testing/factories/product_factory.dart")
        + """import '../../../models/shop_models.dart';
import '../fixtures/fake_products.dart';

Product sampleProduct() => fakeShopProducts().first;
"""
    )


def factory_ord() -> str:
    return (
        hdr("testing/factories/order_factory.dart")
        + """import '../../../models/shop_models.dart';

Order sampleOrder() => throw UnimplementedError();
"""
    )


def route_file(filename: str, class_name: str, routes: list[tuple[str, str]]) -> str:
    lines = [
        hdr(f"routes/{filename}"),
        "/// Named routes — mirror `ShopRoutes` / `main.dart`.\n",
        f"abstract final class {class_name} {{\n",
    ]
    for k, v in routes:
        lines.append(f"  static const String {k} = '{v}';\n")
    lines.append("}\n")
    return "".join(lines)


def main() -> None:
    batches = [
        ADS,
        SOC,
        SEA,
        CHK,
        PAY,
        INV,
        SHP,
        REV,
        CHT,
        LIV,
        MOD,
        SUB,
        AFF,
        AI,
        AN,
        NOT,
        EVT,
        TST,
        INT,
        COM,
        SEL,
        BUY,
    ]

    for batch in batches:
        for item in batch:
            if len(item) == 3 and item[2] == "fixture":
                rel, _, kind = item
                if rel.endswith("fake_orders.dart"):
                    write(rel, fixture_orders())
                elif rel.endswith("fake_sellers.dart"):
                    write(rel, fixture_sellers())
                continue
            if len(item) == 3 and item[2] == "mock":
                rel = item[0]
                if "payment" in rel:
                    write(rel, mock_pay())
                else:
                    write(rel, mock_ship())
                continue
            if len(item) == 3 and item[2] == "factory":
                rel = item[0]
                if "product_factory" in rel:
                    write(rel, factory_prod())
                else:
                    write(rel, factory_ord())
                continue

            rel, cls, gen = item
            if gen is None:
                if "affiliate/models" in rel:
                    write(rel, model_stub(cls))
                elif "notification_model" in rel:
                    write(rel, notif_model_stub("ShopNotificationModel"))
                elif "analytics/events" in rel:
                    write(rel, analytics_event_stub(cls))
                elif "events/" in rel and rel.startswith("events/"):
                    write(rel, event_stub(cls))
                continue
            write(rel, gen(cls))

    # routes
    write(
        "routes/buyer_routes.dart",
        route_file(
            "buyer_routes.dart",
            "BuyerRoutes",
            [
                ("shop", "/shop"),
                ("cart", "/shop/cart"),
                ("checkout", "/shop/checkout"),
            ],
        ),
    )
    write(
        "routes/seller_routes.dart",
        route_file(
            "seller_routes.dart",
            "SellerRoutes",
            [
                ("createProduct", "/shop/create-product"),
                ("sellerOrders", "/shop/seller-orders"),
            ],
        ),
    )
    write(
        "routes/social_commerce_routes.dart",
        route_file(
            "social_commerce_routes.dart",
            "SocialCommerceRoutes",
            [
                ("trending", "/shop/trending"),
            ],
        ),
    )
    write(
        "routes/checkout_routes.dart",
        route_file(
            "checkout_routes.dart",
            "CheckoutRoutes",
            [
                ("checkout", "/shop/checkout"),
            ],
        ),
    )

    # Seller aliases per shop.md naming (import required for typedef — export alone is not in scope)
    write(
        "seller/screens/seller_dashboard_screen.dart",
        hdr("seller/screens/seller_dashboard_screen.dart")
        + "import 'my_shop_screen.dart' show MyShopScreen;\n\n"
        + "export 'my_shop_screen.dart' show MyShopScreen;\n\n"
        + "typedef SellerDashboardScreen = MyShopScreen;\n",
    )
    write(
        "seller/screens/product_editor_screen.dart",
        hdr("seller/screens/product_editor_screen.dart")
        + "import 'create_product_screen.dart' show CreateProductScreen;\n\n"
        + "export 'create_product_screen.dart' show CreateProductScreen;\n\n"
        + "typedef ProductEditorScreen = CreateProductScreen;\n",
    )

    print("bulk generation complete")


if __name__ == "__main__":
    main()
