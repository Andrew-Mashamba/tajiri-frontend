import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'DataStore.dart';
import 'mchangoRequestKwaNiaba.dart';
import 'paymentStatus.dart';
import 'selectPaymentMethod.dart';
import 'userImagePicker.dart';

import 'pages/MikopoPage.dart';
import 'HttpService.dart';
import 'adapaymentModal.dart';
import 'mchangoModal.dart';
import 'membersModal.dart';
import 'networkError.dart';
import 'appColor.dart';
import 'widgets/FinancialSummarySection.dart';
import 'services/dashboard_cache_service.dart';

final Logger _dashboardLogger = Logger(
  printer: PrettyPrinter(methodCount: 0, printTime: true),
);




class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() {
    return DashboardScreenState();
  }
}

class DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin<DashboardScreen> {
  @override
  bool get wantKeepAlive => true;
  final CurrencyTextInputFormatter formatter = CurrencyTextInputFormatter.currency(
    locale: 'en_TZ',
    symbol: '\$',
    decimalDigits: 2,
    minValue: 0,
    maxValue: 100000,
    onChange: (value) => print('Formatted value: $value'),
  );

  final TextEditingController controllerValor = TextEditingController();
  final formatCurrency = NumberFormat.simpleCurrency();
  bool error = false, dataloaded = true;
  bool dataloaded2 = true;

  // Loading and caching state
  bool _isInitialLoading = true;
  bool _hasCachedData = false;

  // Firestore listener for real-time notifications
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  @override
  void initState() {
    super.initState();

    // Fetch dashboard data when page opens
    _fetchDashboardData();

    // Set up Firestore listener for real-time updates
    _setupFirestoreListener();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  /// Check if device has internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      _dashboardLogger.e('[DASHBOARD] Connectivity check error: $e');
      return true; // Assume connected on error
    }
  }

  /// Fetch dashboard data directly from BACKEND API
  ///
  /// Data flow:
  /// 1. Show cached data immediately (if available) for instant display
  /// 2. Fetch fresh data from backend API (HttpService)
  /// 3. Update DataStore and cache the fresh data locally
  ///
  /// NOTE: All data comes from backend, NOT from Firestore
  Future<void> _fetchDashboardData({bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId ?? '';
    final visitorId = DataStore.currentUserId ?? '';
    _dashboardLogger.i('[DASHBOARD] Fetching from BACKEND API (forceRefresh: $forceRefresh)...');

    // 1. Try to show cached data immediately (instant display)
    if (!forceRefresh && !_hasCachedData) {
      final cached = await DashboardCacheService.getSummary(visitorId, kikobaId);
      if (cached != null) {
        _dashboardLogger.i('[DASHBOARD] Showing cached data instantly');
        _lastKnownVersion = await DashboardCacheService.getVersion(visitorId, kikobaId);

        // Update DataStore with cached data
        _updateDataStoreFromCache(cached);

        if (mounted) {
          setState(() {
            _hasCachedData = true;
            _isInitialLoading = false;
          });
        }
      }
    }

    // 2. Check connectivity before fetching
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _dashboardLogger.w('[DASHBOARD] No internet connection');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        if (_hasCachedData) {
          _showConnectivitySnackbar();
        }
      }
      return;
    }

    // 3. Fetch fresh data from BACKEND API
    try {
      final data = await HttpService.getDashboardData(
        kikobaId: kikobaId,
        visitorId: visitorId,
      );

      if (data != null && mounted) {
        _dashboardLogger.i('[DASHBOARD] Fetch from backend: SUCCESS');

        // Update DataStore with fresh data
        _updateDataStoreFromResponse(data);

        // Cache the fresh data
        await DashboardCacheService.saveSummary(visitorId, kikobaId, data);

        setState(() {
          _hasCachedData = true;
        });
      } else {
        _dashboardLogger.w('[DASHBOARD] Fetch returned null, using existing data');
      }
    } catch (e) {
      _dashboardLogger.e('[DASHBOARD] Error fetching from backend: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  /// Update DataStore from cached data
  void _updateDataStoreFromCache(Map<String, dynamic> data) {
    try {
      if (data['adaList'] != null) DataStore.adaListList = data['adaList'];
      if (data['hisaList'] != null) DataStore.hisaList = data['hisaList'];
      if (data['akibaList'] != null) DataStore.akibaList = data['akibaList'];
      if (data['mikopoList'] != null) DataStore.mikopoList = data['mikopoList'];
      if (data['michangoList'] != null) DataStore.michangoList = data['michangoList'];
      _dashboardLogger.d('[DASHBOARD] DataStore updated from cache');
    } catch (e) {
      _dashboardLogger.e('[DASHBOARD] Error updating DataStore from cache: $e');
    }
  }

  /// Update DataStore from API response
  void _updateDataStoreFromResponse(Map<String, dynamic> data) {
    try {
      if (data['adaList'] != null) DataStore.adaListList = data['adaList'];
      if (data['hisaList'] != null) DataStore.hisaList = data['hisaList'];
      if (data['akibaList'] != null) DataStore.akibaList = data['akibaList'];
      if (data['mikopoList'] != null) DataStore.mikopoList = data['mikopoList'];
      if (data['michangoList'] != null) DataStore.michangoList = data['michangoList'];
      if (data['fainiList'] != null) DataStore.fainiList = data['fainiList'];
      _dashboardLogger.d('[DASHBOARD] DataStore updated from API response');
    } catch (e) {
      _dashboardLogger.e('[DASHBOARD] Error updating DataStore from response: $e');
    }
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

  /// Set up Firestore listener for CHANGE NOTIFICATIONS ONLY
  ///
  /// IMPORTANT: Firestore is NOT used for data fetching!
  /// - Firestore only notifies when data has changed (via version/updatedAt)
  /// - When notified, we fetch fresh data from BACKEND API (HttpService)
  /// - This keeps data source consistent (backend is source of truth)
  void _setupFirestoreListener() {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;
    if (kikobaId == null || kikobaId.isEmpty) {
      _dashboardLogger.w('[DASHBOARD] No kikoba ID, skipping Firestore listener');
      return;
    }

    _dashboardLogger.i('[DASHBOARD] Setting up Firestore listener for kikoba: $kikobaId');

    // Listen ONLY for version/timestamp changes - NOT for actual data
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('DashboardUpdates')
        .doc(kikobaId)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!snapshot.exists || _isInitialLoading) return;

        // Only read version info from Firestore (not actual data)
        final notificationData = snapshot.data();
        final newVersion = notificationData?['version'] as int?;
        final updatedAt = notificationData?['updatedAt'];

        // Use version if available, otherwise use updatedAt timestamp hash
        final effectiveVersion = newVersion ?? updatedAt?.hashCode;

        // Only refresh if version actually changed
        if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
          _dashboardLogger.i('[DASHBOARD] Change notification received: version $_lastKnownVersion -> $effectiveVersion');
          _lastKnownVersion = effectiveVersion;

          // Save version for future comparison
          await DashboardCacheService.saveVersion(visitorId ?? '', kikobaId, effectiveVersion);

          // Clear local cache since data changed
          await DashboardCacheService.clearCache(visitorId ?? '', kikobaId);

          // Fetch fresh data from BACKEND API (not Firestore!)
          _fetchDashboardData(forceRefresh: true);
        } else {
          _dashboardLogger.d('[DASHBOARD] Version unchanged, skipping refresh');
        }
      },
      onError: (error) {
        _dashboardLogger.e('[DASHBOARD] Firestore listener error: $error');
      },
    );
  }

  /// Refresh data - called by pull-to-refresh
  Future<void> _refreshData() async {
    _dashboardLogger.i('[REFRESH] Pull-to-refresh triggered');

    // Check connectivity first
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _dashboardLogger.w('[REFRESH] No internet connection');
      _showConnectivitySnackbar();
      return;
    }

    // Clear cache and fetch fresh data from backend
    final kikobaId = DataStore.currentKikobaId ?? '';
    final visitorId = DataStore.currentUserId ?? '';
    await DashboardCacheService.clearCache(visitorId, kikobaId);
    await _fetchDashboardData(forceRefresh: true);

    _dashboardLogger.i('[REFRESH] Complete');
  }

  final _controller = TextEditingController();
  final _controllerx = TextEditingController();
  final _controllerxy = TextEditingController();
  static const _locale = '';
  String _formatNumber(String s) =>
      NumberFormat.decimalPattern(_locale).format(int.parse(s));
  bool showButtons = true;

  var jumlaYaAda = "0.0 /=";
  var jumlaYaAdax = 0.0;
  var jumlaYaDeni = "0.0 /=";
  var jumlaYaDenix = 0.0;
  var jumlaYaPenati = "0.0 /=";
  var jumlaYaPenatix = 0.0;

  var kiasiSum = 0.0;
  var deniSum = 0.0;
  var penatiSum = 0.0;
  var currentDeni = "0.0 /=";
  var currentDeniFloat = 0.0;
  var currentDeniFloatStore = 0.0;

  List<adapaymentModal> adapaymentTogo = [];
  List<Map<String, dynamic>> monthlyDebtsFromTable = [];

  var kiasiSumx = 0.0;
  var deniSumx = 0.0;
  var penatiSumx = 0.0;
  var currentDenix = "0.0 /=";
  var currentDeniFloatx = 0.0;
  var currentDeniFloatStorex = 0.0;

  List<adapaymentModal> adapaymentTogox = [];

  var kiasiSumxy = 0.0;
  var deniSumxy = 0.0;
  var penatiSumxy = 0.0;
  var currentDenixy = "0.0 /=";
  var currentDeniFloatxy = 0.0;
  var currentDeniFloatStorexy = 0.0;

  double maxValue2x = 0;

  List<adapaymentModal> adapaymentTogoxy = [];

  late String ppmtz;
  late String ipmtz;
  late String pmtz;
  late String amountLeftz;
  String currentloan = "";
  bool showProgress = false;

  // WhatsApp color palette


  // static const _headerColor = Color(0xFF075E54); // WhatsApp green
  // static const _rowColor = Colors.white;
  // static const _summaryColor = Color(0xFF25D366); // WhatsApp light green
  // static const _textColor = Colors.black87;
  // static const _errorColor = _headerColor;
  // static const _lightGreyColor = Color(0xFFF5F5F5); // Light grey



static const _headerColor = AppColors.primary;               // Green header

  // Define constant padding
  static const EdgeInsets cellPadding = EdgeInsets.all(8.0);

  Route _routeTopaymentStatus() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => paymentStatus(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Show skeleton loading while initial data loads
    if (_isInitialLoading && !_hasCachedData) {
      return _buildSkeletonLoading();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 1,
        itemBuilder: (context, i) => Column(
          children: <Widget>[
            const SizedBox(height: 16),

            // Member Profile Card
            _buildMemberProfileCard(),

            const SizedBox(height: 16),

            // Financial Summary Section
            const FinancialSummarySection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Build skeleton loading state
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card skeleton
          _buildSkeletonCard(height: 200),
          const SizedBox(height: 16),
          // Section title skeleton
          _buildSkeletonBox(width: 120, height: 24),
          const SizedBox(height: 8),
          _buildSkeletonBox(width: 200, height: 16),
          const SizedBox(height: 20),
          // Financial cards skeleton
          _buildSkeletonCard(height: 90),
          const SizedBox(height: 12),
          _buildSkeletonCard(height: 90),
          const SizedBox(height: 12),
          _buildSkeletonCard(height: 90),
          const SizedBox(height: 12),
          _buildSkeletonCard(height: 90),
          const SizedBox(height: 12),
          _buildSkeletonCard(height: 90),
          const SizedBox(height: 12),
          _buildSkeletonCard(height: 90),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({double height = 80}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(value),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBox({required double width, required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(value),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  // Member Profile Card following design guidelines
  Widget _buildMemberProfileCard() {
    const primaryBg = Color(0xFFFAFAFA);
    const cardBg = Color(0xFFFFFFFF);
    const primaryText = Color(0xFF1A1A1A);
    const secondaryText = Color(0xFF666666);
    const accentColor = Color(0xFF999999);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Section
            SizedBox(
              height: 80,
              width: 80,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: DataStore.currentUserIdRemotepostImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: DataStore.currentUserIdRemotepostImage,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 80,
                              color: accentColor.withOpacity(0.2),
                              child: const Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Icon(Icons.person, size: 40, color: secondaryText),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(Icons.person, size: 40, color: secondaryText),
                          ),
                  ),
                  // Camera Button
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _headerColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => goimagePicker(context),
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              DataStore.currentUserName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _headerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Mjumbe',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _headerColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider
            Container(
              height: 1,
              color: accentColor.withOpacity(0.2),
            ),

            const SizedBox(height: 16),

            // Phone Number Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _headerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    color: _headerColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Namba ya Simu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DataStore.userNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }






  goimagePicker(BuildContext appContext) {
    print("SEARCH IMAGES");
    Navigator.of(context).push(_routeTouserImagePicker());
  }

  Route _routeTouserImagePicker() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          userImagePicker(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void showUSSDProcessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Jinsi ya kulipa"),
              content: SizedBox(
                //height: 70000,
                width: 70000,
                child: Wrap(children: [
                  Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(""),
                                    Text("TIGO"),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(""),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text('Bonyeza *150*01#'),
                                    Text('Bonyeza 2'),
                                    Text('Bonyeza 4'),
                                    Text('Ingiza kiasi'),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(""),
                                    Text("MPESA"),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(""),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text('Bonyeza *150*01#'),
                                    Text('Bonyeza 2'),
                                    Text('Bonyeza 4'),
                                    Text('Ingiza kiasi'),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                            ],
                          )
                        ],
                      ),
                    ],
                  )
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Route _routeToselectPaymentMethode() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          selectPaymentMethode(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  String goCalculate(amount) {
    //amount = amount * -1;
    //formatCurrency.format(deniSum + penatiSum).replaceAll("\$", "");
    return "-${formatCurrency.format(amount).replaceAll("\$", "")}";
  }

  String goCalculate2(double currentDeniFloatx, double goCalculate) {
    currentDeniFloat = currentDeniFloatx - goCalculate;

    return currentDeniFloat.toString();
  }

  void showComfirmDialog2() {
    currentDeniFloatx = currentDeniFloatStorex;

    print(adapaymentTogox.toString());

    List<adapaymentModal> users = adapaymentTogox.toList();

    var ww = [];
    for (int ctr = 0; ctr <= users.asMap().length - 1; ctr++) {
      print(jsonEncode(users.asMap()[ctr]));
      ww.add(users.asMap()[ctr]);
    }
    DataStore.adaPaymentMapx = ww;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Taarifa za manunuzi"),
              content: SizedBox(
                //height: 70000,
                width: 70000,
                child: ListView(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    children: [
                      Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(""),
                                        Text("Jumla ya kiasi"),
                                        SizedBox(
                                          height: 10,
                                        ),
                                      ]),
                                  Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        Text(""),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Text(formatCurrency
                                            .format(currentDeniFloatStorex)
                                            .replaceAll("\$", "")),
                                        SizedBox(
                                          height: 10,
                                        ),
                                      ])
                                ],
                              )
                            ],
                          ),

                          Divider(
                            height: 5.0,
                          ),

                          Column(
                            children: [
                              for (int index = 0; index < ww.length; index++)
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(ww[index].date),

                                              //Text(goCalculate(ww[index].amount)),
                                              SizedBox(
                                                height: 10,
                                              ),
                                            ]),
                                        Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                            children: [
                                              //Text(goCalculate2(currentDeniFloat,ww[index].amount)),
                                              //formatCurrency.format(deniSum + penatiSum).replaceAll("\$", "");
                                              Text(goCalculate(
                                                  ww[index].amount)),
                                              SizedBox(
                                                height: 10,
                                              ),
                                            ])
                                      ],
                                    )
                                  ],
                                )
                            ],
                          ),

                          ////////////////////////////////////////////

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ), backgroundColor: _headerColor,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  child: const Text(
                                    'Nunua',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'halter',
                                      fontSize: 14,
                                      //package: 'flutter_credit_card',
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  DataStore.paymentAmount =
                                      currentDeniFloatStorex;
                                  //Navigator.of(context).pushReplacement(_routeToselectPaymentMethode());

                                  showUSSDProcessDialog();
                                },
                              ),
                            ],
                          )
                        ],
                      )
                    ]),
              ),
            );
          },
        );
      },
    );
  }

  String goCalculate22(amount) {
    amount = amount * -1;
    return amount.toString();
  }

  String goCalculate222(double currentDeniFloatx, double goCalculate) {
    currentDeniFloatx = currentDeniFloatx - goCalculate;

    return currentDeniFloatx.toString();
  }





  void showUsers() {
    try {
      AwesomeDialog(
        context: context,
        headerAnimationLoop: false,
        dialogType: DialogType.info,
        body: ListView(
          shrinkWrap: true,
          children: [
            _dialogHeader("Chagua mjumbe"),
            _penaltyInputSection(),
            const SizedBox(height: 10),
            datalist() ?? const Text("Hakuna data."),
            const SizedBox(height: 20),
          ],
        ),
      ).show();
    } catch (e) {
      debugPrint("Error in showUsers: $e");
      _showErrorDialog("Tatizo limetokea wakati wa kuonesha ujumbe.");
    }
  }

  void showBlockUsers() {
    try {
      AwesomeDialog(
        context: context,
        headerAnimationLoop: false,
        dialogType: DialogType.info,
        body: ListView(
          shrinkWrap: true,
          children: [
            _dialogHeader("Chagua mjumbe"),
            _inputWithLabel(
              label: "Sababu ya kumtoa",
              controller: _controllerxy,
              inputType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            datalisty() ?? const Text("Hakuna data."),
            const SizedBox(height: 20),
          ],
        ),
      ).show();
    } catch (e) {
      debugPrint("Error in showBlockUsers: $e");
      _showErrorDialog("Tatizo limetokea wakati wa kuonesha ujumbe.");
    }
  }

  void showMchangiwaUsers() {
    try {
      AwesomeDialog(
        context: context,
        headerAnimationLoop: false,
        dialogType: DialogType.info,
        body: ListView(
          shrinkWrap: true,
          children: [
            _dialogHeader("Chagua mjumbe"),
            const SizedBox(height: 10),
            datalistyz() ?? const Text("Hakuna data."),
            const SizedBox(height: 20),
          ],
        ),
      ).show();
    } catch (e) {
      debugPrint("Error in showMchangiwaUsers: $e");
      _showErrorDialog("Tatizo limetokea wakati wa kuonesha ujumbe.");
    }
  }



  Widget _dialogHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _penaltyInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputWithLabel(
          label: "Sababu ya penati",
          controller: _controllerx,
          inputType: TextInputType.text,
        ),
        const SizedBox(height: 10),
        _inputWithLabel(
          label: "Kiasi cha penati",
          controller: _controller,
          inputType: TextInputType.number,
          prefixText: "TZS ",
          onChanged: (string) {
            string = _formatNumber(string.replaceAll(',', ''));
            _controller.value = TextEditingValue(
              text: string,
              selection: TextSelection.collapsed(offset: string.length),
            );
          },
        ),
      ],
    );
  }

  Widget _inputWithLabel({
    required String label,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    String? prefixText,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixText: prefixText,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: _headerColor, width: 0.0),
            ),
          ),
          keyboardType: inputType,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: "Hitilafu",
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }



  Widget datalist() {
    //print(data);
    //print("LOOOK HEERE");
    //print(DataStore.transactionsList);
    List<Widget>? membersShowList = [];

    var data = DataStore.membersList;
    print(data);
    List<member> namelist = List<member>.from(data.map((i) {
      print(member.fromJSON(i).phone);
      membersShowList.add(InkWell(
        child: Card(
          color: Colors.black12,
          elevation: 0.0,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: ListTile(
              leading: Stack(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/no-avatar.png"),
                  ),
                ],
              ),
              title: Text(
                member.fromJSON(i).name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member.fromJSON(i).phone),
            ),
          ),
        ),
        onTap: () {
          HttpService.pigaFaini(
              _controllerx.text.toString(),
              _controller.text.toString(),
              member.fromJSON(i).userId,
              member.fromJSON(i).name)
              .then((String result) {
            //var data = json.decode(result);
            print("FAINI DATA : $data");
          });

          //final lowPrice = MoneyMaskedTextController(decimalSeparator: '.', thousandSeparator: ','); //after
          //print("SEE THISSS "+lowPrice);
          setState(() {
            // mdhaminiName = member.fromJSON(i).name;
            // mdhaminiMaelezo = member.fromJSON(i).phone;
            // mdhaminiId = member.fromJSON(i).userId;
          });

          Navigator.of(context, rootNavigator: true).pop('dialog');
        },
      ));

      return member.fromJSON(i);
    }));

    return Column(children: membersShowList);
  }

  Widget datalisty() {
    //print(data);
    //print("LOOOK HEERE");
    //print(DataStore.transactionsList);
    List<Widget>? membersShowList = [];

    var data = DataStore.membersList;
    print(data);
    List<member> namelist = List<member>.from(data.map((i) {
      print(member.fromJSON(i).phone);
      membersShowList.add(InkWell(
        child: Card(
          color: Colors.black12,
          elevation: 0.0,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: ListTile(
              leading: Stack(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/no-avatar.png"),
                  ),
                ],
              ),
              title: Text(
                member.fromJSON(i).name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member.fromJSON(i).phone),
            ),
          ),
        ),
        onTap: () {
          HttpService.futaMtu(_controllerxy.text.toString(),
              member.fromJSON(i).userId, member.fromJSON(i).name)
              .then((String result) {
            //var data = json.decode(result);
            print("FAINI DATA : $result");

            if (result == "7") {
              var postComment = '${DataStore.currentUserName} anapendekeza kumfuta uanachama ndugu ${member.fromJSON(i).name}. Sababu ni ${_controllerxy.text}.';
              print("THE TEXT $postComment");
              //var uuid = Uuid();
              var uuid = Uuid();
              DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
              String thedate = dateFormat.format(DateTime.now());

              CollectionReference users = FirebaseFirestore.instance
                  .collection('${DataStore.currentKikobaId}barazaMessages');

              // Call the user's CollectionReference to add a new user
              users
                  .add({
                'posterName': DataStore.currentUserName,
                'posterId': DataStore.currentUserId,
                'posterNumber': DataStore.userNumber,
                'posterPhoto': "",
                'postComment': postComment,
                'postImage': '',
                'postType': 'KufutaUwanachama',
                'postId': uuid.v4(),
                'postTime': thedate,
                'kikobaId': DataStore.currentKikobaId
              })
                  .then((value) => print("User Added"))
                  .catchError((error) => print("Failed to add user: $error"));
            } else {}
          });

          //final lowPrice = MoneyMaskedTextController(decimalSeparator: '.', thousandSeparator: ','); //after
          //print("SEE THISSS "+lowPrice);
          setState(() {
            // mdhaminiName = member.fromJSON(i).name;
            // mdhaminiMaelezo = member.fromJSON(i).phone;
            // mdhaminiId = member.fromJSON(i).userId;
          });

          Navigator.of(context, rootNavigator: true).pop('dialog');
        },
      ));

      return member.fromJSON(i);
    }));

    return Column(children: membersShowList);
  }

  Widget datalistyz() {
    //print(data);
    //print("LOOOK HEERE");
    //print(DataStore.transactionsList);
    List<Widget>? membersShowList = [];

    var data = DataStore.membersList;
    print(data);
    List<member> namelist = List<member>.from(data.map((i) {
      print(member.fromJSON(i).phone);
      membersShowList.add(InkWell(
        child: Card(
          color: Colors.black12,
          elevation: 0.0,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: ListTile(
              leading: Stack(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/no-avatar.png"),
                  ),
                ],
              ),
              title: Text(
                member.fromJSON(i).name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member.fromJSON(i).phone),
            ),
          ),
        ),
        onTap: () {
          DataStore.kwaniabaName = member.fromJSON(i).name;
          DataStore.kwaniabaId = member.fromJSON(i).userId;

          Navigator.of(context, rootNavigator: true).pop('dialog');

          var date = DateTime.now().toString();

          var dateParse = DateTime.parse(date);

          var formattedDate = "${dateParse.month}/${dateParse.year}";

          DataStore.paymentService = "mchango";
          DataStore.maelezoYaMalipo =
          "${DataStore.currentUserName} Anaomba mchago wa";
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => mchangoRequestKwaNiaba()),
          );
        },
      ));

      return member.fromJSON(i);
    }));

    return Column(children: membersShowList);
  }

  void showComfirmDialogFutaMkopo(String loanID, double ppmt, double ipmt,
      double pmt, String month, String tenure, String interest) {
    //principalandinterest(loanID);
    print("THE LOAN ID : $loanID");
    print("ppmt : $ppmt");
    print("ipmt : $ipmt");
    print("pmt : $pmt");
    //print("amountLeft : "+amountLeft.toString());

    var totalx = formatCurrency.format(ppmt + ipmt).replaceAll("\$", "");
    ppmtz = formatCurrency
        .format(double.parse(ppmt.toString()))
        .replaceAll("\$", "");
    ipmtz = formatCurrency
        .format(double.parse(ipmt.toString()))
        .replaceAll("\$", "");
    pmtz = formatCurrency
        .format(double.parse(pmt.toString()))
        .replaceAll("\$", "");
    //amountLeftz = formatCurrency.format(double.parse(amountLeft.toString())).replaceAll("\$", "");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Taarifa za malipo"),
              content: SizedBox(
                //height: 70000,
                width: 70000,
                child: Wrap(children: [
                  Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(""),
                                    Text("Kiasi cha mkopo"),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(""),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(formatCurrency
                                        .format(double.parse(currentloan))
                                        .replaceAll("\$", "")),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ])
                            ],
                          )
                        ],
                      ),
                      Divider(
                        height: 5.0,
                      ),
                      Column(
                        children: [
                          //Text("OYAAAA"),
                          Column(
                            children: [
                              Text("Mkopo uliobaki : $ppmtz"),
                              Text("Riba iliobaki : $ipmtz"),
                              Text("Kiasi unacho lipia : $totalx")
                            ],
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ), backgroundColor: _headerColor,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              child: const Text(
                                'Lipa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'halter',
                                  fontSize: 14,
                                  //package: 'flutter_credit_card',
                                ),
                              ),
                            ),
                            onPressed: () async {
                              // HttpService.futaMkopo(loanID).then((String result){
                              //   setState(() {
                              //     print (result);
                              //     var data = json.decode(result);
                              //     print ("FUTA MKOPO RESULTS : "+data.toString());
                              //
                              //
                              //
                              //
                              //   });
                              // });

                              DataStore.paymentService = "closeloan";
                              DataStore.paidServiceId = loanID;
                              DataStore.personPaidId = DataStore.currentUserId;
                              DataStore.maelezoYaMalipo = "${DataStore
                                  .currentUserName} kafuta mkopo wake wote wa shilingi ${formatCurrency
                                  .format(double.parse(currentloan))
                                  .replaceAll("\$", "")}, aliopewa tarehe $month, kwa muda wa miezi ${double.parse(tenure).toStringAsFixed(0)}, kwa riba ya asilimia $interest. Kiasi cha mkopo kilichokua kimebaki ni shilingi $ppmtz. Riba iliyo kua imebaki ni shilingi $ipmtz. Jumla ya kiasi alicho lipa ni shilingi $totalx";
                              DataStore.paymentAmount = totalx.toString();

                              Navigator.of(context).push(
                                  _routeToselectPaymentMethode());
                            },
                          ),
                        ],
                      )
                    ],
                  )
                ]),
              ),
            );
          },
        );
      },
    );
  }

  void showComfirmDialogTopUpMkopo(String loanID, double ppmt, double ipmt,
      double pmt, String month, String tenure, String interest) {
    //principalandinterest(loanID);
    print("THE LOAN ID : $loanID");
    print("ppmt : $ppmt");
    print("ipmt : $ipmt");
    print("pmt : $pmt");
    //print("amountLeft : "+amountLeft.toString());

    var totalx = formatCurrency.format(ppmt + ipmt).replaceAll("\$", "");
    ppmtz = formatCurrency
        .format(double.parse(ppmt.toString()))
        .replaceAll("\$", "");
    ipmtz = formatCurrency
        .format(double.parse(ipmt.toString()))
        .replaceAll("\$", "");
    pmtz = formatCurrency
        .format(double.parse(pmt.toString()))
        .replaceAll("\$", "");
    //amountLeftz = formatCurrency.format(double.parse(amountLeft.toString())).replaceAll("\$", "");

    //DataStore.maelezoYaMalipo = DataStore.currentUserName + " amepewa Top-up ya mkopo wa shilingi , mwezi " + formattedDate.toString() + ", shilingi " + formatCurrency.format(double.parse(item.rejesho.toString())).replaceAll("\$", "");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Taarifa za malipo"),
              content: SizedBox(
                //height: 70000,
                width: 70000,
                child: Wrap(children: [
                  Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(""),
                                    Text(""),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(""),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(""),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ])
                            ],
                          )
                        ],
                      ),
                      Divider(
                        height: 5.0,
                      ),
                      Column(
                        children: [
                          //Text("OYAAAA"),
                          Column(
                            children: [
                              Text("Mkopo uliobaki : $ppmtz"),
                              Text("Riba iliobaki : $ipmtz"),
                              Text(
                                  "Kiasi kitakacho katwa kutoka kwenye mkopo mpya : $totalx")
                            ],
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ), backgroundColor: _headerColor,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              child: const Text(
                                'Omba Top Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'halter',
                                  fontSize: 14,
                                  //package: 'flutter_credit_card',
                                ),
                              ),
                            ),
                            onPressed: () async {
                              // HttpService.futaMkopo(loanID).then((String result){
                              //   setState(() {
                              //     print (result);
                              //     var data = json.decode(result);
                              //     print ("FUTA MKOPO RESULTS : "+data.toString());
                              //
                              //
                              //
                              //
                              //   });
                              // });

                              DataStore.paymentService = "topup";
                              DataStore.paidServiceId = loanID;
                              DataStore.personPaidId = DataStore.currentUserId;
                              DataStore.maelezoYaMalipo = "${DataStore
                                  .currentUserName} kafuta mkopo wake wote wa shilingi ${formatCurrency
                                  .format(double.parse(currentloan))
                                  .replaceAll("\$", "")}, aliopewa tarehe $month, kwa muda wa miezi ${double.parse(tenure).toStringAsFixed(0)}, kwa riba ya asilimia $interest. Kiasi cha mkopo kilichokua kimebaki ni shilingi $ppmtz. Riba iliyo kua imebaki ni shilingi $ipmtz. Jumla ya kiasi alicho lipa ni shilingi $totalx";
                              DataStore.paymentAmount = totalx.toString();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MikopoPage()),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  )
                ]),
              ),
            );
          },
        );
      },
    );
  }

  void showComfirmDialogFutaMchango(mchangoModal item) {
    //principalandinterest(loanID);

    String amountx = formatCurrency
        .format(double.parse(item.amountPaid.toString()))
        .replaceAll("\$", "");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Kufunga Mchango"),
              content: SizedBox(
                //height: 70000,
                width: 70000,
                child: Wrap(children: [
                  Column(
                    children: [
                      if (showProgress) CircularProgressIndicator(),
                      Divider(
                        height: 5.0,
                      ),
                      Column(
                        children: [
                          //Text("OYAAAA"),
                          Column(
                            children: [
                              Text("Tarehe ya mwisho ni : ${item.tareheyamwisho}"),
                              Text("Kiasi utakacho pokea ni  : ${item.amountPaid}"),
                              Text("Kiasi kitatumwa kwenye namba : ${DataStore.userNumber}")
                            ],
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ), backgroundColor: _headerColor,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              child: const Text(
                                'Funga Mchango',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'halter',
                                  fontSize: 14,
                                  //package: 'flutter_credit_card',
                                ),
                              ),
                            ),
                            onPressed: () async {
                              setState(() {
                                showProgress = true;
                              });

                              DataStore.paymentService = "fungamchango";
                              DataStore.paidServiceId = item.id;
                              DataStore.personPaidId = DataStore.currentUserId;
                              DataStore.maelezoYaMalipo = "${DataStore
                                  .currentUserName} kafunga mchango wake aliomba tarehe ${item.reg_date}. Aliomba mchango huu kwaajili ya ${item.maelezo}. Tarehe ya mwisho kuchangia ni ${item.tareheyamwisho} Kiasi kilichongwa, ambacho kimetumwa kwenye namba yake ${DataStore.userNumber} Ni shilingi ${formatCurrency
                                  .format(double.parse(
                                  item.amountPaid.toString()))
                                  .replaceAll("\$", "")}";
                              DataStore.paymentAmount =
                                  item.amountPaid.toString();

                              HttpService.fungaMchango().then((String result) {
                                setState(() {
                                  showProgress = false;
                                  print(result);
                                  if (result == "done") {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop('dialog');
                                    Navigator.of(context).push(
                                        _routeTopaymentStatus());
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => networkError()),
                                    );
                                  }
                                });
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  )
                ]),
              ),
            );
          },
        );
      },
    );
  }

  List<TableRow> fainilistnyx() {
    List<TableRow> listings = [];

    // Add the table headers first
    listings.add(
      TableRow(children: [
        Column(children: [Text("Kiasi", style: TextStyle(fontWeight: FontWeight.bold))]),
        Column(children: [Text("Maelezo", style: TextStyle(fontWeight: FontWeight.bold))]),
        Column(children: [Text("", style: TextStyle(fontWeight: FontWeight.bold))]),
      ]),
    );

    // Safely access the data, ensuring it's not null
    var data = DataStore.fainiList;
    print("MCHANGOLIST");
    print(DataStore.fainiList);
    print("END");

    // Ensure data is not null and has elements
    if (data != null && data.isNotEmpty) {
      for (int i = 0; i < data.length; i++) {
        var t = data[i];
        if (t != null) {
          try {
            // Safely convert the dynamic data to a map
            Map<String, dynamic> datax = Map<String, dynamic>.from(t);

            // Safely access keys to avoid null errors
            String amount = datax["amount"] ?? "N/A";
            String sababu = datax["sababu"] ?? "No reason provided";
            String affectedUserId = datax["affectedUserId"] ?? "";

            // Only add the row if the affectedUserId matches the current user
            if (affectedUserId == DataStore.currentUserId) {
              listings.add(TableRow(children: [
                Column(children: [Text(amount)]),
                Column(children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                    child: Text(sababu, style: TextStyle(fontSize: 12)),
                  ),
                ]),
                Column(children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: _headerColor,
                      backgroundColor: Colors.white,
                      shadowColor: _headerColor,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      minimumSize: Size(100, 40),
                    ),
                    child: Text("Lipa", style: TextStyle(fontSize: 10.0)),
                    onPressed: () {
                      try {
                        var date = DateTime.now().toString();
                        var dateParse = DateTime.parse(date);

                        DataStore.paymentService = "mchango";
                        DataStore.paidServiceId = datax["id"];
                        DataStore.personPaidId = affectedUserId;
                        DataStore.paymentAmount = amount;
                        DataStore.maelezoYaMalipo =
                        "${DataStore.currentUserName} Kalipa faini ya shilingi $amount";

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => selectPaymentMethode()),
                        );
                      } catch (e) {
                        print("Error during payment navigation: $e");
                        _showErrorDialog("Failed to process the payment. Please try again.");
                      }
                    },
                  ),
                ]),
              ]));
            }
          } catch (e) {
            print("Error in data processing: $e");
            // Optionally add a fallback row in case of data issues
            listings.add(TableRow(children: [
              Column(children: [Text("Error processing data")]),
              Column(children: [Text("N/A")]),
              Column(children: [Text("N/A")]),
            ]));
          }
        }
      }
    } else {
      listings.add(TableRow(children: [
        Column(children: [Text("No data available")]),
        Column(children: [Text("No records to show")]),
        Column(children: [Text("")]),
      ]));
    }

    return listings;
  }

}
