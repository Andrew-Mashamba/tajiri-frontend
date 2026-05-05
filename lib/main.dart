import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/feed/feed_screen.dart';
import 'screens/feed/create_post_screen.dart';
import 'screens/clips/createstory_screen.dart';
import 'screens/campaigns/create_campaign_screen.dart';
import 'screens/feed/post_detail_screen.dart';
import 'screens/feed/thread_viewer_screen.dart';
import 'screens/feed/digest_screen.dart';
import 'screens/feed/saved_posts_screen.dart';
import 'creator/screens/weekly_report_screen.dart';
import 'mymusic/widgets/music_gallery_widget_screen.dart';
import 'screens/michangogallerywidget_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/messages/conversations_screen.dart';
import 'screens/messages/search_conversations_screen.dart';
import 'screens/messages/select_user_for_chat_screen.dart';
import 'screens/friends/chat_screen.dart';
import 'models/message_models.dart';
import 'photos/screens/photos_screen.dart';
import 'photos/screens/album_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'creator/screens/creator_revenue_report_screen.dart';
import 'creator/screens/earnings_provenance_screen.dart';
import 'creator/screens/creator_tier_screen.dart';
import 'screens/profile/followers/followers_manage_screen.dart';
import 'screens/profile/following/following_manage_screen.dart';
import 'screens/profile/friends/friends_manage_screen.dart';
import 'screens/profile/subscribers/subscribers_manage_screen.dart';
import 'services/network_state_service.dart';
import 'widgets/offline_banner_host.dart';
import 'screens/clips/clips_screen.dart';
import 'screens/groups/events_screen.dart';
// ignore: unused_import
import 'screens/search/search_screen.dart'; // Retained: used by other screens
import 'screens/search/universal_search_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shop/create_product_screen.dart';
import 'screens/shop/product_detail_screen.dart';
import 'screens/shop/seller_orders_screen.dart';
import 'screens/shop/order_detail_screen.dart';
import 'screens/shop/cart_screen.dart';
import 'screens/shop/checkout_screen.dart';
import 'screens/shop/wishlist_screen.dart';
import 'screens/analytics/analytics_dashboard_screen.dart';
import 'screens/feed/battle_thread_screen.dart';
import 'creator/screens/creator_revenue_screen.dart';
import 'creator/screens/sponsored_posts_screen.dart';
import 'revenue/pages/revenue_index_page.dart';
import 'myphotos/pages/my_photos_page.dart';
import 'myvideos/pages/my_videos_page.dart';
import 'mymusic/pages/my_music_page.dart';
import 'myfiles/pages/my_files_page.dart';
import 'creator/screens/income_source_detail_screen.dart';
import 'creator/screens/income_activity_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/privacy_settings_screen.dart';
import 'screens/settings/security/security_settings_screen.dart';
import 'screens/settings/security/security_activity_screen.dart';
import 'screens/settings/security/sessions_screen.dart';
import 'screens/settings/security/two_factor_biometric_screen.dart';
import 'screens/settings/security/pin_change_screen.dart';
import 'creator/screens/settings_screen.dart';
import 'screens/feed/tea_chat_screen.dart';
import 'screens/biashara/biashara_home_screen.dart';
import 'screens/biashara/create_ad_campaign_screen.dart';
import 'screens/biashara/campaign_detail_screen.dart';
import 'screens/biashara/deposit_ad_balance_screen.dart';
import 'screens/audio_rooms/audio_rooms_discovery_screen.dart';
import 'screens/audio_rooms/audio_room_screen.dart';
// AudioRoom model used via route arguments only; service called by screen imports.
import 'models/shop_models.dart' show Product, DeliveryMethod, Cart;
import 'services/local_storage_service.dart';
import 'services/theme_notifier.dart';
import 'services/language_notifier.dart';
import 'services/fcm_service.dart';
import 'services/event_tracking_service.dart';
import 'services/ad_service.dart';
import 'services/background_sync_service.dart';
import 'games/pages/game_challenge_accept_screen.dart';
import 'services/message_database.dart';
import 'l10n/app_strings.dart';
import 'l10n/app_strings_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob
  MobileAds.instance.initialize();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize event tracking for Flywheel engine
  await EventTrackingService.getInstance();

  // Initialize Firebase with options from firebase_options.dart (FlutterFire CLI)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FcmService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Firebase] Init failed: $e');
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Ensure LocalStorageService is ready before background tasks use it
  await LocalStorageService.getInstance();

  // Ensure message SQLite database is created before app renders
  await MessageDatabase.instance.database;

  // Fire-and-forget: refresh feed cache if stale (>15 min)
  BackgroundSyncService.instance.initialize().ignore();

  // Start app-wide connectivity listener (drives the offline banner).
  NetworkStateService.instance.start().ignore();

  runApp(const TajiriApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) debugPrint('[FCM] Background: ${message.messageId}');
}

/// Light theme per DOCS/DESIGN.md (monochrome).
ThemeData get _lightTheme => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A1A),
        brightness: Brightness.light,
        primary: const Color(0xFF1A1A1A),
        surface: const Color(0xFFFAFAFA),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );

/// Dark theme per DOCS/DESIGN.md (monochrome dark).
ThemeData get _darkTheme => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A1A),
        brightness: Brightness.dark,
        primary: const Color(0xFFE0E0E0),
        surface: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );

final GlobalKey<NavigatorState> _appNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'appNav');

class TajiriApp extends StatefulWidget {
  const TajiriApp({super.key});

  @override
  State<TajiriApp> createState() => _TajiriAppState();
}

class _TajiriAppState extends State<TajiriApp> {
  bool _themeReady = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final storage = await LocalStorageService.getInstance();
    ThemeNotifier.init(storage.getThemeMode());
    LanguageNotifier.init(storage.getLanguageCode());
    // Fire-and-forget ad settings refresh (non-blocking)
    _fetchAdSettingsIfNeeded().ignore();
    if (mounted) setState(() => _themeReady = true);
  }

  Future<void> _fetchAdSettingsIfNeeded() async {
    try {
      final storage = await LocalStorageService.getInstance();
      if (!storage.shouldRefreshAdSettings()) return;
      final token = storage.getAuthToken();
      if (token == null) return;
      final settings = await AdService.getClientSettings(token);
      if (settings.isNotEmpty) {
        await storage.saveAdSettings(settings);
        debugPrint('[AdSettings] Refreshed ${settings.length} settings from server');
      }
    } catch (e) {
      debugPrint('[AdSettings] Fetch failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeReady) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: LanguageNotifier.instance,
          builder: (context, __) {
            final locale = Locale(LanguageNotifier.instance.value);
            FcmService.setNavigatorKey(_appNavigatorKey);
            return AppStringsScope(
              strings: AppStrings(LanguageNotifier.instance.value),
              child: MaterialApp(
              navigatorKey: _appNavigatorKey,
              title: 'Tajiri',
              debugShowCheckedModeBanner: false,
              theme: _lightTheme,
              darkTheme: _darkTheme,
              themeMode: ThemeNotifier.instance.value,
              locale: locale,
              home: const SplashScreen(),
              builder: (context, child) {
                // Playbook §2218 — clamp text scaling at the root so OS
                // font enlargement (up to 3.1× on iOS) doesn't break
                // AppBars, tab bars, and primary CTAs.
                final clamped = MediaQuery.withClampedTextScaling(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.4,
                  child: child ?? const SizedBox.shrink(),
                );
                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: OfflineBannerHost(child: clamped),
                );
              },
              onGenerateRoute: (settings) {
        // Parse route names with IDs like /profile/123
        final uri = Uri.parse(settings.name ?? '');
        final pathSegments = uri.pathSegments;

        // Get current user ID helper
        Future<int> getCurrentUserId() async {
          final storage = await LocalStorageService.getInstance();
          return storage.getUser()?.userId ?? 0;
        }

        if (pathSegments.isEmpty) {
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        }

        switch (pathSegments[0]) {
          case 'home': {
            final tab = uri.queryParameters['tab'];
            final messagesTab = uri.queryParameters['messages_tab'];
            final int? initialIndex = tab == 'messages'
                ? 1
                : tab == 'friends'
                    ? 2
                    : tab == 'shop'
                        ? 3
                        : tab == 'profile'
                            ? 4
                            : null;
            final int? initialMessagesTab = messagesTab == 'groups'
                ? 1
                : messagesTab == 'calls'
                    ? 2
                    : messagesTab == 'chats'
                        ? 0
                        : null;
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return HomeScreen(
                    currentUserId: snapshot.data!,
                    initialIndex: initialIndex,
                    initialMessagesTab: initialMessagesTab,
                  );
                },
              ),
            );
          }

          case 'feed':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return FeedScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'followers':
            // /followers/manage — owner-only follower management page.
            if (pathSegments.length >= 2 && pathSegments[1] == 'manage') {
              return MaterialPageRoute(
                builder: (_) => FutureBuilder<int>(
                  future: getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      );
                    }
                    return FollowersManageScreen(currentUserId: snapshot.data!);
                  },
                ),
                settings: settings,
              );
            }
            return null;

          case 'following':
            // /following/manage — owner-only following management page.
            if (pathSegments.length >= 2 && pathSegments[1] == 'manage') {
              return MaterialPageRoute(
                builder: (_) => FutureBuilder<int>(
                  future: getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      );
                    }
                    return FollowingManageScreen(currentUserId: snapshot.data!);
                  },
                ),
                settings: settings,
              );
            }
            return null;

          case 'friends':
            // /friends/manage — owner-only friends management page.
            if (pathSegments.length >= 2 && pathSegments[1] == 'manage') {
              return MaterialPageRoute(
                builder: (_) => FutureBuilder<int>(
                  future: getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      );
                    }
                    return FriendsManageScreen(currentUserId: snapshot.data!);
                  },
                ),
                settings: settings,
              );
            }
            return null;

          case 'subscribers':
            // /subscribers/manage — creator-only subscribers management page.
            if (pathSegments.length >= 2 && pathSegments[1] == 'manage') {
              return MaterialPageRoute(
                builder: (_) => FutureBuilder<int>(
                  future: getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      );
                    }
                    return SubscribersManageScreen(currentUserId: snapshot.data!);
                  },
                ),
                settings: settings,
              );
            }
            return null;

          case 'saved-posts':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SavedPostsScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'notifications':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return NotificationsScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'post':
            if (pathSegments.length > 1) {
              final postId = int.tryParse(pathSegments[1]) ?? 0;
              if (postId > 0) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return PostDetailScreen(
                        postId: postId,
                        currentUserId: snapshot.data!,
                      );
                    },
                  ),
                );
              }
            }
            break;

          case 'creator-earnings':
            // Lands on the canonical 15-section revenue report.
            // The legacy cross-stream dashboard remains reachable
            // from the report's "Other views" footer.
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return CreatorRevenueReportScreen(creatorId: snapshot.data!);
                },
              ),
            );

          case 'earnings-provenance':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return EarningsProvenanceScreen(
                    currentUserId: snapshot.data!,
                    postId: args['postId'] as int?,
                    stream: args['stream'] as String?,
                  );
                },
              ),
            );

          case 'creator-tier':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return CreatorTierScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'thread':
            if (pathSegments.length > 1) {
              final threadId = int.tryParse(pathSegments[1]) ?? 0;
              if (threadId > 0) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ThreadViewerScreen(
                        threadId: threadId,
                        currentUserId: snapshot.data!,
                      );
                    },
                  ),
                );
              }
            }
            break;

          case 'digest':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return DigestScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'weekly-report':
            if (pathSegments.length > 1) {
              final userId = int.tryParse(pathSegments[1]) ?? 0;
              if (userId > 0) {
                return MaterialPageRoute(
                  builder: (_) => WeeklyReportScreen(userId: userId),
                );
              }
            }
            break;

          case 'analytics':
            if (pathSegments.length > 1) {
              final userId = int.tryParse(pathSegments[1]) ?? 0;
              if (userId > 0) {
                return MaterialPageRoute(
                  builder: (_) => AnalyticsDashboardScreen(userId: userId),
                );
              }
            }
            break;

          case 'battle':
            if (pathSegments.length > 1) {
              final battleId = int.tryParse(pathSegments[1]) ?? 0;
              if (battleId > 0) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      return BattleThreadScreen(battleId: battleId, currentUserId: snapshot.data!);
                    },
                  ),
                );
              }
            }
            break;

          case 'tea':
            return MaterialPageRoute(builder: (_) => const TeaChatScreen());

          case 'sponsored-posts':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return SponsoredPostsScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          // ── lib/creator/ module routes ───────────────────────────────
          // Landing = 9-card CreatorRevenueScreen (revenue sources).
          //   /creator                    → CreatorRevenueScreen (grid)
          //   /creator-earnings           → CreatorRevenueReportScreen (15-section report)
          //   /creator/source/:sourceId   → IncomeSourceDetailScreen
          //   /creator/activity           → IncomeActivityScreen
          // /mapato/* kept as alias for backward compatibility with any
          // already-deployed deep links / FCM payloads in flight.
          case 'revenue':
            return MaterialPageRoute(
              builder: (_) => const RevenueIndexPage(),
            );

          case 'my-photos':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return MyPhotosPage(userId: snapshot.data!);
                },
              ),
            );

          case 'my-videos':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return MyVideosPage(userId: snapshot.data!);
                },
              ),
            );

          case 'my-music':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return MyMusicPage(userId: snapshot.data!);
                },
              ),
            );

          case 'my-files':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return MyFilesPage(userId: snapshot.data!);
                },
              ),
            );

          case 'creator':
          case 'mapato': {
            if (pathSegments.length == 1) {
              // Landing page = the 9-card revenue-sources grid
              // (Posts / Streams / Subscribers / Brand Deals /
              // Ad Revenue / My Photos / My Videos / My Music /
              // My Files). The 15-section revenue report is reachable
              // via the prominent "Full revenue report" link on the
              // grid, and via the dedicated /creator-earnings route.
              return MaterialPageRoute(
                builder: (_) => FutureBuilder<int>(
                  future: getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Scaffold(
                      backgroundColor: const Color(0xFFFAFAFA),
                      appBar: AppBar(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A1A1A),
                        elevation: 0,
                        scrolledUnderElevation: 1,
                        title: const Text(
                          'Mapato',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      body: CreatorRevenueScreen(creatorId: snapshot.data!),
                    );
                  },
                ),
              );
            }
            if (pathSegments.length == 2 && pathSegments[1] == 'activity') {
              return MaterialPageRoute(
                builder: (_) => FutureBuilder<int>(
                  future: getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return IncomeActivityScreen(creatorId: snapshot.data!);
                  },
                ),
              );
            }
            if (pathSegments.length >= 3 && pathSegments[1] == 'source') {
              final sourceId = pathSegments[2];
              if (sourceId.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return IncomeSourceDetailScreen(
                        creatorId: snapshot.data!,
                        sourceId: sourceId,
                      );
                    },
                  ),
                );
              }
            }
            break;
          }

          case 'create-post':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<LocalStorageService>(
                future: LocalStorageService.getInstance(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final user = snapshot.data!.getUser();
                  return CreatePostScreen(
                    currentUserId: user?.userId ?? 0,
                    userName: user?.fullName,
                    userPhotoUrl: user?.profilePhotoUrl,
                  );
                },
              ),
            );

          case 'create-story':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return CreateStoryScreen(userId: snapshot.data!);
                },
              ),
            );

          case 'create-campaign':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return CreateCampaignScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'friends':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return FriendsScreen(currentUserId: snapshot.data!, isCurrentTab: true);
                },
              ),
            );

          case 'messages': {
            // Sub-tab: query ?tab=groups|calls or path /messages/groups or /messages/calls
            final messagesTab = uri.queryParameters['tab'] ??
                (pathSegments.length > 1 ? pathSegments[1] : null);
            final initialTab = messagesTab == 'groups'
                ? 1
                : messagesTab == 'calls'
                    ? 2
                    : 0;
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ConversationsScreen(
                    currentUserId: snapshot.data!,
                    initialTabIndex: initialTab,
                  );
                },
              ),
            );
          }

          case 'search-conversations':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SearchConversationsScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'select-user-chat':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SelectUserForChatScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'chat':
            if (pathSegments.length > 1) {
              final conversationId = int.tryParse(pathSegments[1]) ?? 0;
              Conversation? conversation;
              ChatPromptAfterCall? promptAfterCall;
              if (settings.arguments is Map) {
                final args = settings.arguments! as Map<String, dynamic>;
                conversation = args['conversation'] as Conversation?;
                final prompt = args['promptAfterCall'];
                if (prompt == 'voice') promptAfterCall = ChatPromptAfterCall.voice;
                if (prompt == 'video') promptAfterCall = ChatPromptAfterCall.video;
              } else if (settings.arguments is Conversation) {
                conversation = settings.arguments as Conversation;
              }
              return MaterialPageRoute(
                builder: (_) => FutureBuilder<int>(
                  future: getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ChatScreen(
                      conversationId: conversationId,
                      currentUserId: snapshot.data!,
                      conversation: conversation,
                      promptAfterCall: promptAfterCall,
                    );
                  },
                ),
              );
            }
            break;

          case 'photos':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return PhotosScreen(userId: snapshot.data!, isCurrentUser: true);
                },
              ),
            );

          case 'clips':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ClipsScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'events':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return EventsScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'search':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return UniversalSearchScreen(currentUserId: snapshot.data!);
                },
              ),
            );

          case 'album':
            if (pathSegments.length > 1) {
              final albumId = int.tryParse(pathSegments[1]) ?? 0;
              if (albumId > 0) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return AlbumDetailScreen(
                        albumId: albumId,
                        currentUserId: snapshot.data!,
                      );
                    },
                  ),
                );
              }
            }
            break;

          case 'profile':
            if (pathSegments.length > 1) {
              final userId = int.tryParse(pathSegments[1]) ?? 0;
              // Profile music gallery: /profile/:userId/music (Story 78)
              if (pathSegments.length >= 3 &&
                  pathSegments[2] == 'music' &&
                  userId > 0) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      return MusicGalleryWidgetScreen(
                        userId: userId,
                        currentUserId: snapshot.data,
                      );
                    },
                  ),
                );
              }
              // Profile Michango campaigns: /profile/:userId/michango (Story 81)
              if (pathSegments.length >= 3 &&
                  pathSegments[2] == 'michango' &&
                  userId > 0) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final currentUserId = snapshot.data;
                      return MichangoGalleryWidgetScreen(
                        userId: userId,
                        isOwnProfile: currentUserId != null && userId == currentUserId,
                        showAppBar: true,
                      );
                    },
                  ),
                );
              }
              // Profile page (view another user or own profile)
              return MaterialPageRoute(
                builder: (_) => FutureBuilder<int>(
                  future: getCurrentUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final currentUserId = snapshot.data!;
                    return ProfileScreen(
                      userId: userId,
                      currentUserId: currentUserId,
                    );
                  },
                ),
              );
            }
            break;

          case 'shop':
            // Handle shop routes: /shop/create-product, /shop/edit-product, etc.
            if (pathSegments.length > 1) {
              switch (pathSegments[1]) {
                case 'create-product':
                  return MaterialPageRoute(
                    builder: (_) => FutureBuilder<int>(
                      future: getCurrentUserId(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return CreateProductScreen(currentUserId: snapshot.data!);
                      },
                    ),
                  );

                case 'product': {
                  // Supports /shop/product/123 or /shop/product with arguments
                  int productId = 0;
                  if (pathSegments.length > 2) {
                    productId = int.tryParse(pathSegments[2]) ?? 0;
                  }
                  if (productId == 0 && settings.arguments is Map) {
                    productId = (settings.arguments as Map<String, dynamic>)['productId'] as int? ?? 0;
                  }
                  if (productId > 0) {
                    return MaterialPageRoute(
                      builder: (_) => FutureBuilder<int>(
                        future: getCurrentUserId(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return ProductDetailScreen(
                            productId: productId,
                            currentUserId: snapshot.data!,
                          );
                        },
                      ),
                    );
                  }
                  break;
                }

                case 'seller-orders':
                  return MaterialPageRoute(
                    builder: (_) => FutureBuilder<int>(
                      future: getCurrentUserId(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return SellerOrdersScreen(currentUserId: snapshot.data!);
                      },
                    ),
                  );

                case 'order': {
                  // Supports /shop/order/123 or /shop/order with arguments
                  int orderId = 0;
                  bool isSeller = false;
                  if (pathSegments.length > 2) {
                    orderId = int.tryParse(pathSegments[2]) ?? 0;
                  }
                  if (settings.arguments is Map) {
                    final args = settings.arguments as Map<String, dynamic>;
                    if (orderId == 0) {
                      orderId = args['orderId'] as int? ?? 0;
                    }
                    isSeller = args['isSeller'] == true;
                  }
                  if (orderId > 0) {
                    return MaterialPageRoute(
                      builder: (_) => FutureBuilder<int>(
                        future: getCurrentUserId(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return OrderDetailScreen(
                            orderId: orderId,
                            currentUserId: snapshot.data!,
                            isSeller: isSeller,
                          );
                        },
                      ),
                    );
                  }
                  break;
                }

                case 'cart':
                  return MaterialPageRoute(
                    builder: (_) => FutureBuilder<int>(
                      future: getCurrentUserId(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return CartScreen(currentUserId: snapshot.data!);
                      },
                    ),
                  );

                case 'wishlist':
                  return MaterialPageRoute(
                    builder: (_) => FutureBuilder<int>(
                      future: getCurrentUserId(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return WishlistScreen(currentUserId: snapshot.data!);
                      },
                    ),
                  );

                case 'checkout':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (_) => FutureBuilder<int>(
                      future: getCurrentUserId(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return CheckoutScreen(
                          currentUserId: snapshot.data!,
                          product: args?['product'] as Product?,
                          quantity: args?['quantity'] as int?,
                          deliveryMethod: args?['deliveryMethod'] as DeliveryMethod?,
                          cart: args?['cart'] as Cart?,
                        );
                      },
                    ),
                  );
              }
            }
            break;

          case 'biashara':
            // Sub-routes: /biashara/create, /biashara/deposit, /biashara/campaign/:id
            if (pathSegments.length > 1) {
              switch (pathSegments[1]) {
                case 'create':
                  return MaterialPageRoute(
                    builder: (_) => const CreateAdCampaignScreen(),
                  );
                case 'deposit':
                  return MaterialPageRoute(
                    builder: (_) => const DepositAdBalanceScreen(),
                  );
                case 'campaign':
                  if (pathSegments.length > 2) {
                    final campaignId = int.tryParse(pathSegments[2]) ?? 0;
                    if (campaignId > 0) {
                      return MaterialPageRoute(
                        builder: (_) => CampaignDetailScreen(campaignId: campaignId),
                      );
                    }
                  }
                  break;
              }
            }
            return MaterialPageRoute(
              builder: (_) => const BiasharaHomeScreen(),
            );

          case 'audio-rooms':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return AudioRoomsDiscoveryScreen(
                      currentUserId: snapshot.data!);
                },
              ),
            );

          case 'audio-room':
            if (pathSegments.length > 1) {
              final roomId = int.tryParse(pathSegments[1]) ?? 0;
              if (roomId > 0) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      return AudioRoomScreen(
                        roomId: roomId,
                        currentUserId: snapshot.data!,
                      );
                    },
                  ),
                );
              }
            }
            break;

          case 'game':
            // /game/accept/:sessionId — deep link for game challenge accept
            if (pathSegments.length >= 3 &&
                pathSegments[1] == 'accept') {
              final sessionId = int.tryParse(pathSegments[2]) ?? 0;
              if (sessionId > 0) {
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<int>(
                    future: getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return GameChallengeAcceptScreen(
                        sessionId: sessionId,
                        currentUserId: snapshot.data!,
                      );
                    },
                  ),
                );
              }
            }
            break;

          case 'login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );

          case 'onboarding':
            return MaterialPageRoute(
              builder: (_) => const OnboardingScreen(),
            );

          case 'settings': {
            // /settings, /settings/notifications, /settings/privacy,
            // /settings/security, /settings/security/activity,
            // /settings/security/sessions, /settings/security/biometric,
            // /settings/security/pin
            final sub1 = pathSegments.length > 1 ? pathSegments[1] : null;
            final sub2 = pathSegments.length > 2 ? pathSegments[2] : null;
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<int>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final uid = snapshot.data!;
                  switch (sub1) {
                    case null:
                      return SettingsScreen(currentUserId: uid);
                    case 'notifications':
                      return NotificationSettingsScreen(currentUserId: uid);
                    case 'privacy':
                      return PrivacySettingsScreen(currentUserId: uid);
                    case 'creator':
                      return CreatorSettingsScreen(currentUserId: uid);
                    case 'security':
                      switch (sub2) {
                        case 'activity':
                          return SecurityActivityScreen(currentUserId: uid);
                        case 'sessions':
                          return SessionsScreen(currentUserId: uid);
                        case 'biometric':
                          return TwoFactorBiometricScreen(currentUserId: uid);
                        case 'pin':
                          return PinChangeScreen(currentUserId: uid);
                        default:
                          return SecuritySettingsScreen(currentUserId: uid);
                      }
                    default:
                      return SettingsScreen(currentUserId: uid);
                  }
                },
              ),
            );
          }
        }

        // Default fallback
        return MaterialPageRoute(builder: (_) => const SplashScreen());
          },
        ),
        );
          },
        );
      },
    );
  }
}
