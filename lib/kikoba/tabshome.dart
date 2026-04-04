import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'DataStore.dart';
import 'vicobaList.dart';

import 'HttpService.dart';
import 'bankServices.dart';
import 'baraza.dart';
import 'casesModal.dart';
import 'dashboard_screen.dart';
import 'getKikobaData.dart';
import 'katiba.dart';
import 'mahesabu.dart';
import 'majukumu.dart';
import 'members.dart';
import 'voting_firestore_service.dart';
import 'services/offline_vote_queue.dart';
import 'OfflineDatabase.dart';
import 'RegisterOrLogin.dart';
import 'utils/retry_helper.dart';

import 'appColor.dart';


class tabshome extends StatefulWidget {
  const tabshome({Key? key}) : super(key: key);

  @override
  _TabshomeState createState() => _TabshomeState();
}

class _TabshomeState extends State<tabshome>
    with AutomaticKeepAliveClientMixin<tabshome>, SingleTickerProviderStateMixin {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  late FirebaseMessaging _messaging;
  late TabController _tabController;
  bool _showFab = true;
  bool _showIndicator = false;
  bool _btnEnabled = true;
  int _pendingCasesCount = 0;

  // static const Color primaryColor = Color(0xFF005AA9);
  // static const Color accentColor = Color(0xFFC25B1D);


  // static const Color backgroundColor = Color(0xFFF5F5F5);
  // static const Color cardColor = Colors.white;
  // static const Color textColor = Color(0xFF333333);
  // static const Color secondaryTextColor = Color(0xFF666666);


  // Minimalist monochrome color palette from design guidelines
  static const Color primaryColor = Color(0xFF1A1A1A);       // Dark charcoal
  static const Color accentColor = Color(0xFF666666);        // Medium gray
  static const Color backgroundColor = Color(0xFFFAFAFA);    // Light gray background
  static const Color cardColor = Colors.white;               // Pure white for cards
  static const Color textColor = Color(0xFF1A1A1A);         // Dark text
  static const Color secondaryTextColor = Color(0xFF666666); // Secondary text


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _logger.i('Initializing Tabshome state');

    _initializeFirebase();
    _setupTabController();
    _showPendingCases();
    _startVotingListener();
  }

  /// Start listening to voting cases via Firestore for real-time updates
  void _startVotingListener() {
    _logger.i('🔔 Starting Firestore voting listener');

    VotingFirestoreService.listenToPendingCases(
      onUpdate: (cases) {
        _logger.i('📬 Real-time update: ${cases.length} pending voting cases');
        if (mounted) {
          setState(() {
            _pendingCasesCount = cases.length;
          });
        }
      },
    );
  }

  Future<void> _initializeFirebase() async {
    try {
      _logger.d('Initializing Firebase Messaging');
      _messaging = FirebaseMessaging.instance;

      // On iOS, wait for APNs token before subscribing to topics
      if (Platform.isIOS) {
        _logger.d('iOS detected, waiting for APNs token...');
        String? apnsToken;
        int retries = 0;
        const maxRetries = 10;

        while (apnsToken == null && retries < maxRetries) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            retries++;
            _logger.d('APNs token not ready, retry $retries/$maxRetries');
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        if (apnsToken == null) {
          _logger.w('APNs token not available after $maxRetries retries, skipping topic subscription');
          return;
        }
        _logger.i('APNs token obtained successfully');
      }

      final topics = [
        "OTP",
        "${DataStore.currentKikobaId}KufutaUwanachama",
        "${DataStore.currentKikobaId}newLoanRequest",
        "${DataStore.currentKikobaId}taarifaYamualiko",
        "${DataStore.currentKikobaId}newKikaoRequest",
        "OTP${DataStore.userNumber.replaceAll("+", "").trim()}",
      ];

      for (final topic in topics) {
        await _messaging.subscribeToTopic(topic);
        _logger.d('Subscribed to topic: $topic');
      }

      final token = await _messaging.getToken();
      _logger.i('FCM Token: $token');
    } catch (e, stackTrace) {
      _logger.e('Error initializing Firebase', error: e, stackTrace: stackTrace);
    }
  }

  void _setupTabController() {
    _logger.d('Setting up tab controller with initial index: ${DataStore.defaultTab}');
    _tabController = TabController(
      vsync: this,
      initialIndex: DataStore.defaultTab,
      length: 5,
    );

    _tabController.addListener(() {
      setState(() {
        _showFab = _tabController.index == 1;
      });
      _logger.d('Tab changed to index: ${_tabController.index}');
    });
  }

  void _showPendingCases() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _logger.d('Checking pending cases');
      _updatePendingCasesCount();

      // Check if we should auto-open voting sheet from notification click
      if (DataStore.showVotingSheetOnLoad) {
        _logger.i('Auto-opening Wajibu sheet from notification click');
        DataStore.showVotingSheetOnLoad = false; // Reset flag
        _showCasesBottomSheet();
      }
      // Also auto-show if there are pending cases (existing behavior)
      else if (_pendingCasesCount > 0) {
        _showCasesBottomSheet();
      }
    });
  }

  void _updatePendingCasesCount() {
    if (DataStore.casesList != null && DataStore.casesList!.isNotEmpty) {
      setState(() {
        _pendingCasesCount = DataStore.casesList!.length;
      });
    } else {
      setState(() {
        _pendingCasesCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    VotingFirestoreService.stopListening();
    _logger.i('Disposing Tabshome resources');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _logger.d('Building Tabshome UI');

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildTabBarView(),
    );
  }

  AppBar _buildAppBarx() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1.5,
      title: Text(
        DataStore.currentKikobaName,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: accentColor),
        onPressed: () => _navigateToVikobaList(),
      ),
      bottom: _buildTabBar(),
      actions: [_buildBankServicesIcon()],
    );
  }


  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        DataStore.currentKikobaName,
        style: const TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: textColor, size: 24),
        onPressed: () => _navigateToVikobaList(),
      ),
      bottom: _buildTabBar(),
      actions: [
        // Vote/Wajibu icon with badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.how_to_vote_rounded, color: accentColor, size: 24),
              onPressed: _pendingCasesCount > 0 ? _showCasesBottomSheet : null,
              tooltip: 'Wajibu',
            ),
            if (_pendingCasesCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    _pendingCasesCount > 9 ? '9+' : '$_pendingCasesCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: accentColor, size: 24),
          onSelected: (value) {
            if (value == 'bank_services') {
              _navigateToBankServices();
            } else if (value == 'help') {
              _showHelp();
            } else if (value == 'logout') {
              _showLogoutConfirmation();
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'bank_services',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_rounded, size: 20, color: textColor),
                    SizedBox(width: 12),
                    Text(
                      'Bank Services',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded, size: 20, color: textColor),
                    SizedBox(width: 12),
                    Text(
                      'Msaada',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Ondoka',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildBankServicesIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: GestureDetector(
        onTap: _navigateToBankServices,
        child: const Icon(
          Icons.home_work,
          size: 24.0,
          color: accentColor,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        color: Colors.white,
        child: TabBar(
          isScrollable: false,
          controller: _tabController,
          // Remove default indicator - we use custom animated indicators
          indicator: const BoxDecoration(),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelPadding: EdgeInsets.zero,
          tabs: _buildTabItems(),
        ),
      ),
    );
  }

  List<Widget> _buildTabItems() {
    return const [
      Tab(
        height: 60,
        child: _TabIcon(icon: Icons.forum_rounded, index: 0, label: 'Baraza'),
      ),
      Tab(
        height: 60,
        child: _TabIcon(icon: Icons.dashboard_rounded, index: 1, label: 'Mimi'),
      ),
      Tab(
        height: 60,
        child: _TabIcon(icon: Icons.account_balance_wallet_rounded, index: 2, label: 'Hesabu'),
      ),
      Tab(
        height: 60,
        child: _TabIcon(icon: Icons.groups_rounded, index: 3, label: 'Wanachama'),
      ),
      Tab(
        height: 60,
        child: _TabIcon(icon: Icons.menu_book_rounded, index: 4, label: 'Katiba'),
      ),
    ];
  }

  // Alternative: Use fluid tabs with labels (uncomment to use)
  // List<Widget> _buildFluidTabItems() {
  //   return const [
  //     Tab(
  //       height: 56,
  //       child: _FluidTabIcon(icon: Icons.forum_rounded, label: 'Baraza', index: 0),
  //     ),
  //     Tab(
  //       height: 56,
  //       child: _FluidTabIcon(icon: Icons.dashboard_rounded, label: 'Kwangu', index: 1),
  //     ),
  //     Tab(
  //       height: 56,
  //       child: _FluidTabIcon(icon: Icons.account_balance_wallet_rounded, label: 'Hesabu', index: 2),
  //     ),
  //     Tab(
  //       height: 56,
  //       child: _FluidTabIcon(icon: Icons.groups_rounded, label: 'Wadau', index: 3),
  //     ),
  //     Tab(
  //       height: 56,
  //       child: _FluidTabIcon(icon: Icons.menu_book_rounded, label: 'Katiba', index: 4),
  //     ),
  //   ];
  // }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      physics: const BouncingScrollPhysics(),
      children: const [
        baraza(),
        DashboardScreen(),
        mahesabu(),
        membersScreen(),
        katiba(),
      ],
    );
  }





  void _showCasesBottomSheet() {
    try {
      _logger.d('Attempting to show cases bottom sheet');

      // Check both DataStore (legacy) and Firestore
      final hasLegacyCases = DataStore.casesList != null && DataStore.casesList!.isNotEmpty;

      if (!hasLegacyCases && _pendingCasesCount == 0) {
        _logger.w('No cases to display');
        return;
      }

      // Log raw Wajibu data if available
      if (hasLegacyCases) {
        _logger.i('═══════════════════════════════════════════════════════');
        _logger.i('📋 WAJIBU DATA (Raw from DataStore.casesList):');
        _logger.i('═══════════════════════════════════════════════════════');
        _logger.i('Total cases: ${DataStore.casesList!.length}');
        for (int i = 0; i < DataStore.casesList!.length; i++) {
          _logger.i('─────────────────────────────────────────────────────');
          _logger.i('Case #${i + 1}:');
          _logger.i(json.encode(DataStore.casesList![i]));
        }
        _logger.i('═══════════════════════════════════════════════════════');
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildRealtimeCasesBottomSheet(),
      );
    } catch (e, stackTrace) {
      _logger.e('Error showing cases bottom sheet', error: e, stackTrace: stackTrace);
      _showErrorSnackbar('Error loading cases: ${e.toString()}');
    }
  }

  /// Build bottom sheet with real-time Firestore streaming
  Widget _buildRealtimeCasesBottomSheet() {
    final kikobaId = DataStore.currentKikobaId ?? '';

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('${kikobaId}VotingCases')
                      .where('status', isEqualTo: 'pending')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Merge Firestore cases with legacy DataStore cases
                    List<thecase> cases = [];

                    // Add Firestore cases
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final votingCase = VotingCase.fromFirestore(doc);
                        cases.add(thecase.fromJSON(votingCase.toTheCaseJson()));
                      }
                    }

                    // Add legacy DataStore cases (if not already in Firestore)
                    if (DataStore.casesList != null) {
                      final firestoreCaseIds = cases.map((c) => c.caseID).toSet();
                      final legacyCases = _parseCaseItems(DataStore.casesList!);
                      for (var legacyCase in legacyCases) {
                        if (!firestoreCaseIds.contains(legacyCase.caseID)) {
                          cases.add(legacyCase);
                        }
                      }
                    }

                    return _buildBottomSheetContent(
                      context,
                      setSheetState,
                      scrollController,
                      cases,
                      snapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build the content of the bottom sheet
  Widget _buildBottomSheetContent(
    BuildContext context,
    StateSetter setSheetState,
    ScrollController scrollController,
    List<thecase> cases,
    bool isLoading,
  ) {
    return Column(
      children: [
        // Handle bar
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
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.how_to_vote_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Wajibu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Live indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${cases.length} ${cases.length == 1 ? 'suala linahitaji' : 'masuala yanahitaji'} kura yako',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Loading indicator
        if (_showIndicator || isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        const Divider(height: 24),
        // Cases list or empty state
        Expanded(
          child: cases.isEmpty
              ? _buildEmptyCasesState()
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: cases.length,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  itemBuilder: (context, index) => _buildCaseCard(
                    context,
                    setSheetState,
                    cases[index],
                    index,
                    cases,
                  ),
                ),
        ),
      ],
    );
  }

  /// Empty state when no cases
  Widget _buildEmptyCasesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Hakuna masuala yanayosubiri kura',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Umekamilisha wajibu wako wote',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  List<thecase> _parseCaseItems(List<dynamic> rawCases) {
    return rawCases.map((item) {
      try {
        return thecase.fromJSON(item);
      } catch (e) {
        _logger.w('Error parsing case item: $e');
        return null;
      }
    }).whereType<thecase>().toList();
  }

  Widget _buildCaseCard(
    BuildContext context,
    StateSetter setSheetState,
    thecase caseItem,
    int index,
    List<thecase> cases,
  ) {
    final isVotingCase = caseItem.type.toLowerCase() == 'voting_case';
    final isMultipleChoice = caseItem.isMultipleChoice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case type badge and category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCaseTypeLabel(caseItem.type),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              if (caseItem.category != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCategoryLabel(caseItem.category!),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (caseItem.deadline != null)
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      caseItem.deadline!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title (if available) and description
          if (caseItem.title != null && caseItem.title!.isNotEmpty) ...[
            Text(
              caseItem.title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            caseItem.maelezo,
            style: TextStyle(
              fontSize: caseItem.title != null ? 14 : 15,
              fontWeight: caseItem.title != null ? FontWeight.w400 : FontWeight.w500,
              color: caseItem.title != null ? Colors.grey[700] : textColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Voting status section - different for voting cases vs legacy
          if (isVotingCase && caseItem.yesCount != null)
            _buildUnifiedVotingStatus(caseItem)
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildVotingRowModern("Mwenyekiti", caseItem.chairmansVote),
                  const SizedBox(height: 8),
                  _buildVotingRowModern("Katibu", caseItem.secretarysVote),
                  const SizedBox(height: 8),
                  _buildVotingRowModern("Mdhamini", caseItem.quarantorsVote),
                  const SizedBox(height: 8),
                  _buildCommitteeVotesModern(caseItem),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Voting progress indicator
          if (isVotingCase && caseItem.approvalPercentage != null)
            _buildUnifiedVotingProgress(caseItem)
          else
            _buildVotingProgress(caseItem),
          const SizedBox(height: 16),

          // Action buttons - different for multiple choice vs yes/no
          if (isMultipleChoice)
            _buildMultipleChoiceOptions(context, setSheetState, caseItem, index, cases)
          else
            Row(
              children: [
                Expanded(
                  child: _buildVoteButton(
                    label: "Kataa",
                    icon: Icons.close_rounded,
                    isPrimary: false,
                    isReject: true,
                    onPressed: _btnEnabled
                        ? () => _handleVote(
                              context,
                              setSheetState,
                              caseItem,
                              index,
                              cases,
                              "no",
                            )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVoteButton(
                    label: "Sitaki",
                    icon: Icons.remove_circle_outline_rounded,
                    isPrimary: false,
                    isAbstain: true,
                    onPressed: _btnEnabled
                        ? () => _handleVote(
                              context,
                              setSheetState,
                              caseItem,
                              index,
                              cases,
                              "abstain",
                            )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVoteButton(
                    label: "Kubali",
                    icon: Icons.check_rounded,
                    isPrimary: true,
                    onPressed: _btnEnabled
                        ? () => _handleVote(
                              context,
                              setSheetState,
                              caseItem,
                              index,
                              cases,
                              "yes",
                            )
                        : null,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Category label helper
  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'general': return 'Kawaida';
      case 'policy': return 'Sera';
      case 'financial': return 'Fedha';
      case 'membership': return 'Uanachama';
      case 'event': return 'Tukio';
      case 'other': return 'Nyingine';
      default: return category;
    }
  }

  // Unified voting status for new voting API
  Widget _buildUnifiedVotingStatus(thecase caseItem) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVoteCountChip(
                label: 'Ndiyo',
                count: caseItem.yesCount ?? 0,
                color: Colors.green,
                icon: Icons.thumb_up_rounded,
              ),
              _buildVoteCountChip(
                label: 'Hapana',
                count: caseItem.noCount ?? 0,
                color: Colors.red,
                icon: Icons.thumb_down_rounded,
              ),
              _buildVoteCountChip(
                label: 'Sitaki',
                count: caseItem.abstainCount ?? 0,
                color: Colors.grey,
                icon: Icons.remove_circle_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Jumla: ${caseItem.totalVotes ?? 0} kura',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteCountChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Unified voting progress for new voting API
  Widget _buildUnifiedVotingProgress(thecase caseItem) {
    final percentage = caseItem.approvalPercentage ?? 0;
    final threshold = caseItem.approvalThreshold ?? 66.67;
    final hasReached = caseItem.hasReachedThreshold ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Asilimia ya Kukubalika',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}% / ${threshold.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasReached ? Colors.green : Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: (percentage / 100).clamp(0, 1),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: hasReached ? Colors.green : primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Threshold marker
            Positioned(
              left: (threshold / 100) * (MediaQuery.of(context).size.width - 80),
              child: Container(
                width: 2,
                height: 8,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Multiple choice options for voting cases
  Widget _buildMultipleChoiceOptions(
    BuildContext context,
    StateSetter setSheetState,
    thecase caseItem,
    int index,
    List<thecase> cases,
  ) {
    final options = caseItem.options ?? [];
    final optionVotes = caseItem.optionVotes ?? {};
    final totalOptionVotes = optionVotes.values.fold(0, (sum, v) => sum + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chagua moja:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          final votes = optionVotes[option] ?? 0;
          final percentage = totalOptionVotes > 0 ? (votes / totalOptionVotes * 100) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: _btnEnabled
                  ? () => _handleOptionVote(
                        context,
                        setSheetState,
                        caseItem,
                        index,
                        cases,
                        option,
                      )
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$votes kura',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Handle voting on multiple choice option
  Future<void> _handleOptionVote(
    BuildContext context,
    StateSetter setSheetState,
    thecase caseItem,
    int index,
    List<thecase> cases,
    String option,
  ) async {
    setState(() {
      _showIndicator = true;
      _btnEnabled = false;
    });
    setSheetState(() {});

    try {
      final response = await HttpService.voteOnVotingCaseOption(
        caseId: caseItem.caseID.isNotEmpty ? caseItem.caseID : caseItem.id,
        option: option,
      );

      if (response['success'] == true) {
        _showSuccessSnackbar('Umechagua: $option');
        // Update case or remove from list
        if (mounted) {
          setSheetState(() {
            cases.removeAt(index);
            _pendingCasesCount = cases.length;
            if (DataStore.casesList != null && DataStore.casesList!.length > index) {
              DataStore.casesList!.removeAt(index);
            }
          });
          setState(() {
            _pendingCasesCount = cases.length;
          });
        }
        if (cases.isEmpty && mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showErrorSnackbar(response['message'] ?? 'Imeshindwa kupiga kura');
      }
    } catch (e) {
      _showErrorSnackbar('Kosa: $e');
    } finally {
      if (mounted) {
        setState(() {
          _showIndicator = false;
          _btnEnabled = true;
        });
        setSheetState(() {});
      }
    }
  }

  String _getCaseTypeLabel(String type) {
    switch (type.toLowerCase()) {
      // === LOAN REQUESTS ===
      case 'mkopo':
        return 'Ombi la Mkopo';

      // === MEMBERSHIP ===
      case 'uanachama':
        return 'Ombi la Uanachama';
      case 'mjumbe_mpya':
      case 'new_member':
        return 'Kuongeza Mwanachama Mpya';
      case 'kufuta_uanachama':
      case 'remove_member':
        return 'Kuondoa Mwanachama';

      // === CONTRIBUTIONS ===
      case 'mchango':
      case 'michango':
        return 'Ombi la Mchango';
      case 'mchango_niaba':
      case 'contribution_behalf':
        return 'Mchango kwa Niaba';

      // === FINES ===
      case 'faini':
        return 'Faini';

      // === EXPENSES ===
      case 'matumizi':
      case 'expense':
        return 'Ombi la Matumizi';
      case 'matumizi_mpya':
      case 'new_expense':
        return 'Matumizi Mapya';

      // === KATIBA CHANGES ===
      case 'katiba':
      case 'katiba_change':
        return 'Mabadiliko ya Katiba';
      case 'katiba_kiingilio':
        return 'Kubadili Kiingilio';
      case 'katiba_ada':
        return 'Kubadili Ada';
      case 'katiba_hisa':
        return 'Kubadili Hisa';
      case 'katiba_riba':
        return 'Kubadili Riba';
      case 'katiba_faini':
        return 'Kubadili Faini';
      case 'katiba_loan_product':
        return 'Kubadili Bidhaa ya Mkopo';

      // === VOTING API TYPES ===
      case 'membership_request':
        return 'Ombi la Uanachama';
      case 'membership_removal':
        return 'Kuondoa Mwanachama';
      case 'loan_application':
        return 'Ombi la Mkopo';
      case 'akiba_withdrawal':
        return 'Kutoa Akiba';
      case 'expense_request':
        return 'Ombi la Matumizi';
      case 'fine_approval':
        return 'Kuidhinisha Faini';
      case 'proxy_mchango':
        return 'Mchango kwa Niaba';
      case 'voting_case':
        return 'Kesi ya Kura';

      default:
        return type;
    }
  }

  Widget _buildVotingRowModern(String role, String? vote) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            role,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildVoteIndicatorModern(vote),
      ],
    );
  }

  Widget _buildVoteIndicatorModern(String? vote) {
    if (vote == "1") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 14, color: Colors.green[700]),
            const SizedBox(width: 4),
            Text(
              'Amekubali',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    } else if (vote == "0") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 14, color: Colors.red[700]),
            const SizedBox(width: 4),
            Text(
              'Amekataa',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Hajapigia',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildCommitteeVotesModern(thecase caseItem) {
    final yesVotes = int.tryParse(caseItem.othersVote) ?? 0;
    final noVotes = int.tryParse(caseItem.othersVoteNo) ?? 0;
    final totalVotes = yesVotes + noVotes;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'Wajumbe',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 14, color: Colors.green[600]),
              const SizedBox(width: 2),
              Text(
                '$yesVotes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
              Container(
                width: 1,
                height: 12,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Icon(Icons.close_rounded, size: 14, color: Colors.red[600]),
              const SizedBox(width: 2),
              Text(
                '$noVotes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              if (totalVotes > 0) ...[
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Text(
                  'Jumla: $totalVotes',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVotingProgress(thecase caseItem) {
    final yesVotes = int.tryParse(caseItem.othersVote) ?? 0;
    final noVotes = int.tryParse(caseItem.othersVoteNo) ?? 0;
    final totalVoters = int.tryParse(caseItem.numberOfVoters) ?? 0;
    final totalVotes = yesVotes + noVotes;

    // Calculate approval percentage
    final approvalPercentage = totalVotes > 0 ? (yesVotes / totalVotes * 100) : 0.0;

    // Determine threshold (check which percentage check is active)
    int threshold = 50;
    if (caseItem.aHundredPercentCheck == '1') {
      threshold = 100;
    } else if (caseItem.seventyFivePercentCheck == '1') {
      threshold = 75;
    } else if (caseItem.fiftyPercentCheck == '1') {
      threshold = 50;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Maendeleo ya Kura',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: approvalPercentage >= threshold
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${approvalPercentage.toStringAsFixed(0)}% Wamekubali',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: approvalPercentage >= threshold
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Yes votes (green)
              FractionallySizedBox(
                widthFactor: totalVotes > 0 ? yesVotes / totalVotes : 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[500],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Threshold marker
              Positioned(
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: threshold / 100,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 2,
                      height: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalVotes/${totalVoters > 0 ? totalVoters : "?"} wamepigia kura',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Kizingiti: $threshold%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback? onPressed,
    bool isReject = false,
    bool isAbstain = false,
  }) {
    Color bgColor;
    Color textColorButton;
    Color borderColor;

    if (isPrimary) {
      bgColor = Colors.green[600]!;
      textColorButton = Colors.white;
      borderColor = Colors.green[600]!;
    } else if (isReject) {
      bgColor = Colors.white;
      textColorButton = Colors.red[600]!;
      borderColor = Colors.red[300]!;
    } else if (isAbstain) {
      bgColor = Colors.white;
      textColorButton = Colors.grey[600]!;
      borderColor = Colors.grey[300]!;
    } else {
      bgColor = Colors.white;
      textColorButton = textColor;
      borderColor = Colors.grey[300]!;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: textColorButton,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColorButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVote(
      BuildContext context,
      StateSetter setState,
      thecase caseItem,
      int index,
      List<thecase> cases,
      String vote,
      ) async {
    _logger.i('═══════════════════════════════════════════════════════════');
    _logger.i('🗳️ VOTE FLOW START');
    _logger.i('═══════════════════════════════════════════════════════════');
    _logger.i('📋 Case ID: ${caseItem.caseID}');
    _logger.i('📋 Case Type: ${caseItem.type}');
    _logger.i('📋 User ID: ${caseItem.userID}');
    _logger.i('📋 Vote: $vote');
    _logger.i('───────────────────────────────────────────────────────────');

    // Store original values for rollback
    final originalYesCount = caseItem.yesCount ?? 0;
    final originalNoCount = caseItem.noCount ?? 0;
    final originalAbstainCount = caseItem.abstainCount ?? 0;
    final originalTotal = caseItem.totalVotes ?? 0;

    _logger.d('📊 Original vote counts:');
    _logger.d('   Yes: $originalYesCount | No: $originalNoCount | Abstain: $originalAbstainCount | Total: $originalTotal');

    // OPTIMISTIC UPDATE: Update UI immediately
    _logger.i('⚡ STEP 1: Optimistic UI Update');
    setState(() {
      _showIndicator = true;
      _btnEnabled = false;

      // Optimistically update vote counts
      if (vote == 'yes') {
        caseItem.yesCount = originalYesCount + 1;
        _logger.d('   ✓ Incremented YES count: ${originalYesCount} → ${caseItem.yesCount}');
      } else if (vote == 'no') {
        caseItem.noCount = originalNoCount + 1;
        _logger.d('   ✓ Incremented NO count: ${originalNoCount} → ${caseItem.noCount}');
      } else if (vote == 'abstain') {
        caseItem.abstainCount = originalAbstainCount + 1;
        _logger.d('   ✓ Incremented ABSTAIN count: ${originalAbstainCount} → ${caseItem.abstainCount}');
      }
      caseItem.totalVotes = (caseItem.totalVotes ?? 0) + 1;
    });
    _logger.i('   ✅ UI updated immediately (optimistic)');

    try {
      // Check if online
      _logger.i('⚡ STEP 2: Connection Check');
      final isOnline = VotingFirestoreService.isConnected;
      _logger.i('   📡 Connection status: ${isOnline ? "ONLINE ✅" : "OFFLINE ❌"}');

      if (!isOnline) {
        // OFFLINE: Queue vote for later sync
        _logger.w('───────────────────────────────────────────────────────────');
        _logger.w('📴 OFFLINE MODE - Queuing vote for later sync');
        _logger.w('───────────────────────────────────────────────────────────');

        await OfflineVoteQueue.queueVote(
          caseId: caseItem.caseID,
          type: caseItem.type,
          vote: vote,
          position: '1',
          userId: caseItem.userID,
        );

        final pendingCount = await OfflineVoteQueue.getPendingCount();
        _logger.i('   📥 Vote queued successfully');
        _logger.i('   📊 Total pending votes in queue: $pendingCount');

        _showInfoSnackbar('Kura imehifadhiwa. Itasajiliwa ukiingia mtandaoni.');
        _removeCaseAndCloseIfEmpty(context, setState, cases, index);

        _logger.i('═══════════════════════════════════════════════════════════');
        _logger.i('🗳️ VOTE FLOW END (Queued for offline sync)');
        _logger.i('═══════════════════════════════════════════════════════════');
        return;
      }

      // ONLINE: Send vote with retry
      _logger.i('⚡ STEP 3: Sending Vote to Server');
      _logger.i('   🌐 Endpoint: HttpService.vote()');
      _logger.i('   📤 Params: type=${caseItem.type}, position=1, caseId=${caseItem.caseID}, vote=$vote');
      _logger.i('   ⏱️ Timeout: 30 seconds');
      _logger.i('   🔄 Max retries: 2');

      final stopwatch = Stopwatch()..start();

      final result = await retryWithBackoff(
        () => HttpService.vote(
          caseItem.type,
          "1",
          caseItem.caseID,
          vote,
          caseItem.userID,
        ).timeout(const Duration(seconds: 30)),
        maxRetries: 2,
        initialDelay: const Duration(seconds: 1),
        onRetry: (attempt, error) {
          _logger.w('   🔄 Retry attempt $attempt due to: $error');
        },
      );

      stopwatch.stop();
      _logger.i('   ⏱️ Request completed in ${stopwatch.elapsedMilliseconds}ms');

      final data = json.decode(result);
      _logger.i('⚡ STEP 4: Processing Server Response');
      _logger.d('   📥 Raw response: $data');

      final status = data["status"]?.toString().trim();
      final message = data["message"]?.toString().trim();
      _logger.i('   📋 Status: $status');
      _logger.i('   📋 Message: $message');

      if (status == "success" || message == "voted") {
        _logger.i('───────────────────────────────────────────────────────────');
        _logger.i('✅ VOTE SUCCESS');
        _logger.i('───────────────────────────────────────────────────────────');
        _logger.i('   Vote recorded on server');
        _logger.i('   Optimistic update confirmed');

        _showSuccessSnackbar('Kura yako imesajiliwa');
        _removeCaseAndCloseIfEmpty(context, setState, cases, index);

      } else if (status == "error" && message == "ALREADY_VOTED") {
        _logger.i('───────────────────────────────────────────────────────────');
        _logger.i('ℹ️ ALREADY VOTED');
        _logger.i('───────────────────────────────────────────────────────────');
        _logger.i('   User has already voted on this case');
        _logger.i('   Removing case from list');

        _showInfoSnackbar('Umeshapiga kura kwenye suala hili');
        _removeCaseAndCloseIfEmpty(context, setState, cases, index);

      } else if (status == "error") {
        _logger.e('───────────────────────────────────────────────────────────');
        _logger.e('❌ VOTE FAILED - Server Error');
        _logger.e('───────────────────────────────────────────────────────────');
        _logger.e('   Error message: $message');
        _logger.e('   Rolling back optimistic update...');

        // ROLLBACK: Revert optimistic update
        _rollbackVote(setState, caseItem, vote, originalYesCount, originalNoCount, originalAbstainCount);
        _showErrorSnackbar(message ?? "Imeshindwa kupiga kura");

      } else {
        _logger.i('───────────────────────────────────────────────────────────');
        _logger.i('📝 VOTE PROCESSED (with message)');
        _logger.i('───────────────────────────────────────────────────────────');

        if (message != null && message.isNotEmpty) {
          _logger.i('   Posting vote message to baraza: $message');
          await _postVoteMessage(message);
        }
        _removeCaseAndCloseIfEmpty(context, setState, cases, index);
      }

    } on TimeoutException {
      _logger.w('───────────────────────────────────────────────────────────');
      _logger.w('⏰ TIMEOUT - Queuing vote for later');
      _logger.w('───────────────────────────────────────────────────────────');
      _logger.w('   Request timed out after 30 seconds');
      _logger.w('   Queuing vote for background sync...');

      // Queue for later if timeout
      await OfflineVoteQueue.queueVote(
        caseId: caseItem.caseID,
        type: caseItem.type,
        vote: vote,
        position: '1',
        userId: caseItem.userID,
      );

      final pendingCount = await OfflineVoteQueue.getPendingCount();
      _logger.i('   📥 Vote queued. Total pending: $pendingCount');

      _showInfoSnackbar('Mtandao unasuasua. Kura itasajiliwa baadaye.');
      _removeCaseAndCloseIfEmpty(context, setState, cases, index);

    } catch (e, stackTrace) {
      _logger.e('───────────────────────────────────────────────────────────');
      _logger.e('❌ EXCEPTION CAUGHT');
      _logger.e('───────────────────────────────────────────────────────────');
      _logger.e('   Error: $e');
      _logger.e('   Stack trace:', error: e, stackTrace: stackTrace);

      // Check if network error - queue for later
      final isNetworkError = e.toString().contains('SocketException') ||
          e.toString().contains('Connection');

      _logger.e('   Is network error: $isNetworkError');

      if (isNetworkError) {
        _logger.w('   📴 Network error detected - queuing vote');

        await OfflineVoteQueue.queueVote(
          caseId: caseItem.caseID,
          type: caseItem.type,
          vote: vote,
          position: '1',
          userId: caseItem.userID,
        );

        final pendingCount = await OfflineVoteQueue.getPendingCount();
        _logger.i('   📥 Vote queued. Total pending: $pendingCount');

        _showInfoSnackbar('Hakuna mtandao. Kura itasajiliwa ukiingia mtandaoni.');
        _removeCaseAndCloseIfEmpty(context, setState, cases, index);
      } else {
        _logger.e('   🔄 Non-network error - rolling back optimistic update');
        // ROLLBACK: Revert optimistic update for other errors
        _rollbackVote(setState, caseItem, vote, originalYesCount, originalNoCount, originalAbstainCount);
        _showErrorSnackbar('Kosa: ${e.toString()}');
      }
    } finally {
      setState(() {
        _showIndicator = false;
        _btnEnabled = true;
      });

      _logger.i('═══════════════════════════════════════════════════════════');
      _logger.i('🗳️ VOTE FLOW END');
      _logger.i('═══════════════════════════════════════════════════════════');
    }
  }

  /// Rollback optimistic vote update
  void _rollbackVote(
    StateSetter setState,
    thecase caseItem,
    String vote,
    int originalYes,
    int originalNo,
    int originalAbstain,
  ) {
    _logger.w('🔄 ROLLBACK: Reverting optimistic update');
    _logger.w('   Restoring: Yes=$originalYes, No=$originalNo, Abstain=$originalAbstain');

    setState(() {
      caseItem.yesCount = originalYes;
      caseItem.noCount = originalNo;
      caseItem.abstainCount = originalAbstain;
      caseItem.totalVotes = originalYes + originalNo + originalAbstain;
      _btnEnabled = true;
    });

    _logger.w('   ✅ Rollback complete');
  }

  /// Show info snackbar (neutral)
  void _showInfoSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _removeCaseAndCloseIfEmpty(
      BuildContext context,
      StateSetter setSheetState,
      List<thecase> cases,
      int index,
      ) {
    _logger.d('📋 Removing case at index $index from list');
    _logger.d('   Cases before: ${cases.length}');

    setSheetState(() {
      cases.removeAt(index);
      _btnEnabled = true;
    });

    // Update parent state to refresh badge count
    setState(() {
      _pendingCasesCount = cases.length;
      if (DataStore.casesList != null && DataStore.casesList!.length > index) {
        DataStore.casesList!.removeAt(index);
      }
    });

    _logger.d('   Cases after: ${cases.length}');
    _logger.d('   Badge count updated to: $_pendingCasesCount');

    if (cases.isEmpty) {
      _logger.i('   📭 No more cases - closing bottom sheet');
      Navigator.of(context).pop();
    }
  }

  Future<void> _postVoteMessage(String message) async {
    try {
      _logger.d('Posting vote message: $message');

      final uuid = const Uuid();
      final dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      final thedate = dateFormat.format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('${DataStore.currentKikobaId}barazaMessages')
          .add({
        'posterName': DataStore.currentUserName,
        'posterId': DataStore.currentUserId,
        'posterNumber': DataStore.userNumber,
        'posterPhoto': "",
        'postComment': message,
        'postImage': '',
        'postType': 'taarifaYamualiko',
        'postId': uuid.v4(),
        'postTime': thedate,
        'kikobaId': DataStore.currentKikobaId,
      });

      _logger.i('Vote message posted successfully');
    } catch (e, stackTrace) {
      _logger.e('Error posting vote message', error: e, stackTrace: stackTrace);
    }
  }

  void _navigateToVikobaList() {
    _logger.d('Navigating to Vikoba list');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VikobaListPage()),
    );
  }

  void _navigateToBankServices() {
    _logger.d('Navigating to Bank Services');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const bankServices()),
    );
  }

  void _showHelp() {
    _logger.d('Showing Help');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Color(0xFF1A1A1A)),
              SizedBox(width: 12),
              Text(
                'Msaada',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kwa msaada zaidi wasiliana nasi:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.phone, size: 18, color: Color(0xFF666666)),
                  SizedBox(width: 8),
                  Text('+255 123 456 789'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email, size: 18, color: Color(0xFF666666)),
                  SizedBox(width: 8),
                  Text('support@vicoba.co.tz'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Sawa',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    _logger.d('Showing logout confirmation');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Ondoka',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Una uhakika unataka kuondoka kwenye akaunti yako?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Hapana',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              child: const Text(
                'Ndiyo, Ondoka',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    _logger.i('Performing logout');
    try {
      // Truncate local database tables
      await OfflineDatabase.truncateAll();
      _logger.i('Local database tables truncated');

      // Clear user data from DataStore
      DataStore.currentUserId = '';
      DataStore.currentUserName = '';
      DataStore.userNumber = '';
      DataStore.myVikobaList = [];
      DataStore.currentKikobaId = '';
      DataStore.currentKikobaName = '';
      DataStore.visitedKikobaId = '';

      // Navigate to login/register screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RegisterOrLogin()),
          (route) => false,
        );
      }
    } catch (e) {
      _logger.e('Logout error: $e');
      _showErrorSnackbar('Imeshindwa kuondoka. Jaribu tena.');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// class _TabIconx extends StatelessWidget {
//   final IconData icon;
//   final int index;
//
//   const _TabIcon({
//     required this.icon,
//     required this.index,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final tabState = context.findAncestorStateOfType<_TabshomeState>()!;
//     final isSelected = tabState._tabController.index == index;
//
//     return Icon(
//       icon,
//       size: 24,
//       color: isSelected ? Colors.redAccent : Colors.grey[400],
//     );
//   }
// }

/// Modern animated tab icon with scale, bounce, and color transitions
class _TabIcon extends StatefulWidget {
  final IconData icon;
  final int index;
  final String? label;

  const _TabIcon({
    required this.icon,
    required this.index,
    this.label,
  });

  @override
  State<_TabIcon> createState() => _TabIconState();
}

class _TabIconState extends State<_TabIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  TabController? _tabController;
  bool _wasSelected = false;

  static const Color selectedColor = Color(0xFF1A1A1A);
  static const Color unselectedColor = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Scale animation with elastic curve for bounce effect
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Bounce animation for vertical movement
    _bounceAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabState = context.findAncestorStateOfType<_TabshomeState>();
    if (tabState != null && _tabController != tabState._tabController) {
      _tabController?.removeListener(_handleTabChange);
      _tabController = tabState._tabController;
      _tabController?.addListener(_handleTabChange);

      // Check initial state
      _wasSelected = _tabController?.index == widget.index;
      if (_wasSelected) {
        _animationController.value = 1.0;
      }
    }
  }

  void _handleTabChange() {
    if (!mounted) return;
    final isSelected = _tabController?.index == widget.index;

    if (isSelected == true && !_wasSelected) {
      _animationController.forward(from: 0);
    } else if (isSelected == false && _wasSelected) {
      _animationController.reverse();
    }
    _wasSelected = isSelected ?? false;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _tabController?.index == widget.index;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: unselectedColor,
                end: isSelected == true ? selectedColor : unselectedColor,
              ),
              duration: const Duration(milliseconds: 250),
              builder: (context, color, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated icon container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.all(isSelected == true ? 8 : 6),
                      decoration: BoxDecoration(
                        color: isSelected == true
                            ? selectedColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: color,
                      ),
                    ),
                    // Tab label below icon
                    if (widget.label != null)
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontSize: isSelected == true ? 11 : 10,
                          fontWeight: isSelected == true ? FontWeight.w600 : FontWeight.w500,
                          color: color,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.label!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Alternative: Fluid animated tab with expanding pill and label
class _FluidTabIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;

  const _FluidTabIcon({
    required this.icon,
    required this.label,
    required this.index,
  });

  @override
  State<_FluidTabIcon> createState() => _FluidTabIconState();
}

class _FluidTabIconState extends State<_FluidTabIcon> {
  TabController? _tabController;

  static const Color selectedColor = Color(0xFF1A1A1A);
  static const Color unselectedColor = Color(0xFF999999);
  static const Color pillColor = Color(0xFFF0F0F0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabState = context.findAncestorStateOfType<_TabshomeState>();
    if (tabState != null && _tabController != tabState._tabController) {
      _tabController?.removeListener(_handleTabChange);
      _tabController = tabState._tabController;
      _tabController?.addListener(_handleTabChange);
    }
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _tabController?.index == widget.index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isSelected == true ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: 12 + (value * 8),
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Color.lerp(Colors.transparent, pillColor, value),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isSelected == true ? 1.1 : 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, scale, _) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: Color.lerp(unselectedColor, selectedColor, value),
                    ),
                  );
                },
              ),
              // Animated label that expands
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: isSelected == true ? null : 0,
                  child: Padding(
                    padding: EdgeInsets.only(left: value * 8),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: value.clamp(0.0, 1.0),
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedColor,
                        ),
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Premium animated tab with ripple and glow effects
class _PremiumTabIcon extends StatefulWidget {
  final IconData icon;
  final int index;

  const _PremiumTabIcon({
    required this.icon,
    required this.index,
  });

  @override
  State<_PremiumTabIcon> createState() => _PremiumTabIconState();
}

class _PremiumTabIconState extends State<_PremiumTabIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  TabController? _tabController;
  bool _wasSelected = false;

  static const Color selectedColor = Color(0xFF1A1A1A);
  static const Color unselectedColor = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabState = context.findAncestorStateOfType<_TabshomeState>();
    if (tabState != null && _tabController != tabState._tabController) {
      _tabController?.removeListener(_handleTabChange);
      _tabController = tabState._tabController;
      _tabController?.addListener(_handleTabChange);

      _wasSelected = _tabController?.index == widget.index;
    }
  }

  void _handleTabChange() {
    if (!mounted) return;
    final isSelected = _tabController?.index == widget.index;

    if (isSelected == true && !_wasSelected) {
      _controller.forward(from: 0);
    }
    _wasSelected = isSelected ?? false;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _tabController?.index == widget.index;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect behind icon
            if (isSelected == true)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _glowAnimation.value * 0.3,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            // Main icon
            Transform.scale(
              scale: isSelected == true ? _scaleAnimation.value : 1.0,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(
                  begin: unselectedColor,
                  end: isSelected == true ? selectedColor : unselectedColor,
                ),
                duration: const Duration(milliseconds: 200),
                builder: (context, color, _) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected == true
                          ? selectedColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: color,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}