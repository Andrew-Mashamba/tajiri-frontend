# TAJIRI App Navigation Tree

> **~90+ unique screens/pages, 35+ named routes, 15+ modal sheets**

---

## Entry Point

```
SplashScreen
├── [logged in] ──→ HomeScreen
└── [not logged in] ──→ LoginScreen
    ├── [login success] ──→ HomeScreen
    └── "Create Account" ──→ OnboardingScreen
        ├── Chapter 0 (Kufahamiana): NameStep → PhotoStep
        ├── Chapter 1 (Mahali): PhoneStep → PinStep → LocationStep
        ├── Chapter 2 (Masomo): EducationLevelStep → [branch]
        │   ├── primary:        SchoolStep(primary)
        │   ├── secondary:      SchoolStep(primary) → SchoolStep(secondary)
        │   ├── alevel:         SchoolStep(primary) → SchoolStep(secondary) → SchoolStep(alevel)
        │   ├── postSecondary:  SchoolStep(primary) → SchoolStep(secondary) → SchoolStep(postsecondary)
        │   └── university:     SchoolStep(primary) → SchoolStep(secondary) → SchoolStep(alevel) → UniversityStep
        ├── Chapter 3 (Maisha): EmployerStep
        └── CompletionScreen ──→ HomeScreen (clears stack)
```

---

## HomeScreen (5-Tab Bottom Navigation)

---

### Tab 0: FeedScreen (/feed)

```
FeedScreen
├── AppBar
│   ├── 🔍 Search ──→ UniversalSearchScreen (/search)
│   │   ├── Post result ──→ PostDetailScreen (/post/:id)
│   │   └── User result ──→ ProfileScreen (/profile/:id)
│   ├── 🔖 Saved ──→ SavedPostsScreen (/saved-posts)
│   │   └── Post tap ──→ PostDetailScreen
│   └── 🔔 Notifications ──→ NotificationsScreen (/notifications)
├── FAB ──→ CreatePostScreen (/create-post)
│   ├── Text ──→ CreateTextPostScreen
│   ├── Image ──→ CreateImagePostScreen
│   │   └── Edit photo ──→ PhotoEditorScreen
│   ├── Audio ──→ CreateAudioPostScreen
│   ├── Short Video ──→ CreateShortVideoScreen
│   ├── Drafts ──→ _AllDraftsScreen (private)
│   └── Scheduled ──→ _ScheduledPostsScreen (private)
├── Post interactions
│   ├── Post tap ──→ FullScreenPostViewerScreen
│   │   ├── Comment ──→ [sheet] CommentBottomSheet
│   │   ├── Share ──→ [sheet] SharePostSheet
│   │   ├── Edit ──→ EditPostScreen
│   │   ├── Video Reply ──→ VideoReplyScreen
│   │   ├── Video Stitch ──→ VideoStitchScreen
│   │   ├── Music artist ──→ ProfileScreen (/profile/:id/music)
│   │   └── Thread ──→ ThreadViewerScreen (/thread/:id)
│   ├── User avatar ──→ ProfileScreen (/profile/:id)
│   ├── Comment icon ──→ [sheet] CommentBottomSheet
│   │   └── User tap ──→ ProfileScreen
│   ├── Share icon ──→ [sheet] SharePostSheet
│   ├── Hashtag ──→ HashtagScreen
│   │   └── Post/User/Thread navigation (same as feed)
│   ├── Mention ──→ SearchScreen (legacy)
│   └── Thread card ──→ ThreadViewerScreen
├── Feed tabs
│   ├── Posts tab (default feed)
│   ├── Friends tab (friends-only feed)
│   └── Live tab ──→ StreamsScreen (inline)
│       ├── Stream tap ──→ StreamViewerScreen
│       │   ├── Tip ──→ SendTipScreen
│       │   └── [dialogs] info/report/end
│       └── Go Live ──→ GoLiveScreen
│           ├── Backstage ──→ BackstageScreen
│           └── Start ──→ LiveBroadcastScreen
│               └── Advanced ──→ LiveBroadcastScreenAdvanced
├── Story row
│   ├── Story tap ──→ StoryViewerScreen
│   │   ├── Reply ──→ ChatScreen (/chat/:id)
│   │   └── Subscribe ──→ SubscribeToCreatorScreen
│   └── Add story ──→ CreateStoryScreen (/create-story)
├── Discover section (DiscoverFeedContent)
│   └── Thread/User/Edit/VideoReply/VideoStitch navigation
├── DigestScreen (/digest)
│   └── Post tap ──→ PostDetailScreen / FullScreenPostViewerScreen
├── PostDetailScreen (/post/:id)
│   └── User/Edit/Comment/Thread/VideoReply/VideoStitch navigation
├── ThreadViewerScreen (/thread/:id)
│   └── User/Post/Edit/Thread/VideoReply/VideoStitch/Comment navigation
├── BattleThreadScreen (/battle/:id)
│   └── Post/User/Thread/VideoReply/VideoStitch navigation
└── SponsoredPostsScreen (/sponsored-posts)
    └── Creator tap ──→ ProfileScreen
```

---

### Tab 1: ConversationsScreen (/messages)

```
ConversationsScreen
├── Internal tabs: Chats | Groups | Calls
├── Chats tab
│   ├── Conversation tap ──→ ChatScreen (/chat/:id)
│   │   ├── Voice call ──→ OutgoingCallFlowScreen
│   │   ├── Video call ──→ OutgoingCallFlowScreen
│   │   ├── Group call ──→ [sheet] select members → OutgoingCallFlowScreen
│   │   ├── Group info ──→ GroupInfoScreen
│   │   │   └── Member tap ──→ ProfileScreen
│   │   ├── Group events ──→ GroupEventsScreen
│   │   │   ├── Event tap ──→ EventDetailScreen
│   │   │   └── Create ──→ CreateEventScreen
│   │   ├── Post link ──→ PostDetailScreen
│   │   └── [dialogs] block/report
│   ├── Search ──→ SearchConversationsScreen (/search-conversations)
│   │   └── Result ──→ ChatScreen
│   └── FAB [sheet]
│       ├── New message ──→ SelectUserForChatScreen → ChatScreen
│       └── Create group ──→ CreateGroupScreen → ChatScreen
├── Groups tab
│   └── Group tap ──→ ChatScreen
└── Calls tab
    └── Call tap [sheet]
        ├── Voice call back ──→ OutgoingCallFlowScreen
        └── Chat ──→ ChatScreen
```

---

### Tab 2: FriendsScreen (/friends)

```
FriendsScreen
├── Person tap ──→ ProfileScreen (/profile/:id)
└── Message button ──→ ChatScreen (/chat/:id)
```

---

### Tab 3: ShopScreen

```
ShopScreen
├── Product tap ──→ ProductDetailScreen (/shop/product/:id)
│   ├── Cart ──→ CartScreen (/shop/cart)
│   │   └── Checkout ──→ CheckoutScreen (/shop/checkout)
│   │       ├── [sheet] payment method
│   │       └── [dialog] confirm → OrderDetailScreen
│   ├── Buy Now ──→ CheckoutScreen
│   ├── Seller profile ──→ ProfileScreen
│   └── [sheet] delivery method, report
├── Category ──→ CategoryScreen
│   └── Product tap ──→ ProductDetailScreen
├── Cart icon ──→ CartScreen
├── Create product ──→ CreateProductScreen (/shop/create-product)
└── Seller orders ──→ SellerOrdersScreen (/shop/seller-orders)
    └── Order tap ──→ OrderDetailScreen (/shop/order/:id)
        └── Contact ──→ ChatScreen
```

---

### Tab 4: ProfileScreen (/profile/:id) — Own Profile

```
ProfileScreen
├── AppBar actions
│   ├── Settings ──→ SettingsScreen
│   │   ├── Profile ──→ EditProfileScreen
│   │   ├── Username ──→ UsernameSettingsScreen
│   │   ├── Profile Tabs ──→ ProfileTabsSettingsScreen
│   │   ├── About ──→ AboutScreen
│   │   │   └── Edit sections ──→ [StepEditorWrapper] NameStep/PhotoStep/LocationStep/
│   │   │       EducationLevelStep/SchoolStep/UniversityStep/EmployerStep
│   │   ├── Privacy ──→ PrivacySettingsScreen
│   │   ├── Language ──→ [dialog]
│   │   ├── Logout ──→ [dialog] → SplashScreen
│   │   └── Delete account ──→ [dialog]
│   └── Popup menu
│       ├── Edit Profile ──→ EditProfileScreen
│       ├── Tajiri Pay ──→ WalletScreen
│       │   ├── Subscriptions ──→ MySubscriptionsScreen
│       │   │   ├── Creator ──→ SubscriptionDetailScreen
│       │   │   │   └── Creator profile ──→ ProfileScreen
│       │   │   └── Browse ──→ UniversalSearchScreen
│       │   ├── Earnings ──→ EarningsDashboardScreen
│       │   │   ├── Subscribers ──→ SubscriberListScreen
│       │   │   │   └── Subscriber ──→ ProfileScreen
│       │   │   ├── Payout ──→ PayoutRequestScreen
│       │   │   └── History ──→ PayoutHistoryScreen
│       │   ├── Tiers Setup ──→ SubscriptionTiersSetupScreen
│       │   └── Quick actions [sheets] Deposit/Withdraw/Transfer/Request
│       ├── Calls ──→ CallHistoryScreen
│       │   └── Call ──→ OutgoingCallFlowScreen
│       ├── Saved ──→ SavedPostsScreen
│       └── Logout ──→ [dialog]
├── Quick links
│   ├── Edit ──→ EditProfileScreen
│   ├── Settings ──→ SettingsScreen
│   └── Wallet ──→ WalletScreen
├── Creator Dashboard (inline section)
│   ├── Weekly Report ──→ WeeklyReportScreen (/weekly-report/:id)
│   │   └── Best post ──→ PostDetailScreen
│   └── Analytics ──→ AnalyticsDashboardScreen (/analytics/:id)
├── Profile tabs (configurable)
│   ├── Posts tab
│   │   ├── Post tap ──→ PostDetailScreen
│   │   ├── Create Post ──→ CreatePostScreen
│   │   └── Saved ──→ SavedPostsScreen
│   ├── Friends tab
│   │   └── Friend tap ──→ ProfileScreen
│   ├── Groups tab
│   │   ├── Group tap ──→ GroupDetailScreen
│   │   │   ├── User ──→ ProfileScreen
│   │   │   ├── Post ──→ EditPostScreen
│   │   │   ├── Create post ──→ CreateGroupPostScreen
│   │   │   ├── Events ──→ GroupEventsScreen
│   │   │   ├── Edit group ──→ CreateGroupScreen
│   │   │   ├── VideoReply/Stitch
│   │   │   └── Comment ──→ [sheet] CommentBottomSheet
│   │   ├── Discover ──→ GroupsScreen
│   │   │   └── Group ──→ GroupDetailScreen
│   │   └── Create ──→ CreateGroupScreen
│   ├── Pages tab
│   │   └── Page tap ──→ PageDetailScreen
│   │       └── User/Post/Edit/VideoReply/VideoStitch/Comment navigation
│   ├── Polls tab
│   │   ├── Poll tap ──→ PollDetailScreen
│   │   └── Create ──→ CreatePollScreen
│   ├── Music (/profile/:id/music)
│   │   └── Track tap ──→ [sheet] MusicPlayerSheet
│   │       └── Artist ──→ ProfileScreen
│   └── Michango (/profile/:id/michango)
│       ├── Create ──→ CreateCampaignScreen (/create-campaign)
│       ├── Donate ──→ DonateToCampaignScreen
│       └── Withdraw ──→ CampaignWithdrawScreen
└── Other user actions
    ├── Subscribe ──→ SubscribeToCreatorScreen
    └── Message ──→ ChatScreen
```

---

## Standalone Feature Screens (Named Routes)

### /photos

```
PhotosScreen
├── Upload ──→ _UploadPhotosScreen (private)
├── Photo tap ──→ Photo viewer
└── Album tab → AlbumDetailScreen (/album/:id)
    └── Photo tap ──→ Photo viewer
```

### /clips

```
ClipsScreen
├── Camera ──→ CreateClipScreen
│   ├── Upload ──→ UploadVideoScreen
│   └── Music ──→ MusicLibraryScreen
│       ├── Track ──→ [sheet] MusicPlayerSheet
│       ├── Artist ──→ ArtistDetailScreen
│       ├── Upload ──→ MusicUploadScreen
│       └── Recently played [sheet]
├── Clip swipe ──→ ClipPlayerScreen
│   └── Subscribe / Comment / Share [sheets]
└── Story highlights
    ├── Highlight tap ──→ HighlightViewerScreen
    └── Create ──→ CreateHighlightScreen
```

### /events

```
EventsScreen
├── Event tap ──→ EventDetailScreen
│   └── Ticket link ──→ [external browser]
└── Create ──→ CreateEventScreen
```

### /biashara

```
BiasharaHomeScreen
├── Create ──→ CreateAdCampaignScreen (/biashara/create)
├── Deposit ──→ DepositAdBalanceScreen (/biashara/deposit)
└── Campaign ──→ CampaignDetailScreen (/biashara/campaign/:id)
```

---

## FCM-Triggered (Push Notification)

```
Incoming call ──→ IncomingCallFlowScreen ──→ ActiveCallScreen
Notification tap ──→ routes to relevant screen via payload
```

---

## Modals & Bottom Sheets (Not Routes)

| Modal | Description |
|-------|-------------|
| CommentBottomSheet | Post comment (feed, detail, thread, page, group) |
| SharePostSheet | Share options |
| MusicPlayerSheet | Track playback |
| ProfileStatsBottomSheet | Followers/following list |
| MilestoneOverlay | Streak/milestone celebration |
| BattleModeOverlay | Battle mode |
| StoryAdOverlay | Story ad |
| MusicAdOverlay | Music ad |
| VideoPrerollOverlay | Video pre-roll ad |
| NativeAdCard | Feed ad |
| ConversationAdCard | Chat list ad |
| SchedulePostWidget | Date/time picker for scheduled posts |

---

## Dead/Orphaned Screens

| Screen | Status |
|--------|--------|
| MentionTextFieldScreen | Never imported |
| registration/* (old) | Superseded by onboarding/* |
| BattleModeOverlayScreen | No navigation found |
| clips/streams_screen.dart | Superseded by streams/ |
