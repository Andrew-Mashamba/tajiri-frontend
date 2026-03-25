import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/feed/feed_screen.dart';
import 'screens/feed/create_post_screen.dart';
import 'screens/clips/createstory_screen.dart';
import 'screens/campaigns/create_campaign_screen.dart';
import 'screens/feed/post_detail_screen.dart';
import 'screens/feed/saved_posts_screen.dart';
import 'screens/feed/musicgallerywidget_screen.dart';
import 'screens/michangogallerywidget_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/messages/conversations_screen.dart';
import 'screens/messages/search_conversations_screen.dart';
import 'screens/messages/select_user_for_chat_screen.dart';
import 'screens/friends/chat_screen.dart';
import 'models/message_models.dart';
import 'screens/photos/photos_screen.dart';
import 'screens/photos/album_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/clips/clips_screen.dart';
import 'screens/groups/events_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/shop/create_product_screen.dart';
import 'screens/shop/product_detail_screen.dart';
import 'screens/shop/seller_orders_screen.dart';
import 'screens/shop/order_detail_screen.dart';
import 'screens/shop/cart_screen.dart';
import 'screens/shop/checkout_screen.dart';
import 'models/shop_models.dart' show Product, DeliveryMethod, Cart;
import 'services/local_storage_service.dart';
import 'services/theme_notifier.dart';
import 'services/language_notifier.dart';
import 'services/fcm_service.dart';
import 'l10n/app_strings.dart';
import 'l10n/app_strings_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

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
    if (mounted) setState(() => _themeReady = true);
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
            return MaterialApp(
              navigatorKey: _appNavigatorKey,
              title: 'Tajiri',
              debugShowCheckedModeBanner: false,
              theme: _lightTheme,
              darkTheme: _darkTheme,
              themeMode: ThemeNotifier.instance.value,
              locale: locale,
              home: const SplashScreen(),
              builder: (context, child) {
                return AppStringsScope(
                  strings: AppStrings(LanguageNotifier.instance.value),
                  child: child ?? const SizedBox.shrink(),
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
                  return SearchScreen(currentUserId: snapshot.data!);
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

          case 'login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
        }

        // Default fallback
        return MaterialPageRoute(builder: (_) => const SplashScreen());
          },
        );
          },
        );
      },
    );
  }
}
