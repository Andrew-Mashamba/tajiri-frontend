import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'HttpService.dart';
import 'DataStore.dart';
import 'sajiriKikoba.dart';
import 'searchForKikoba.dart';
import 'searchOrCreatekikoba.dart';
import 'vicoba.dart';
import 'waitDialog.dart';
import 'services/vikoba_list_cache_service.dart';
import 'getKikobaData.dart';
import 'appColor.dart';
import '../services/local_storage_service.dart';



class VikobaListPage extends StatefulWidget {
  const VikobaListPage({super.key});

  @override
  _NewsListPageState createState() => _NewsListPageState();
}

class _NewsListPageState extends State<VikobaListPage>
    with AutomaticKeepAliveClientMixin<VikobaListPage> {
  final Logger _logger = Logger();
  bool isSelected = false;

  bool get _isSwahili =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  // Loading and caching state
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  bool _isRefreshing = false;

  // Firestore listener
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  // Local data copy
  List<vicoba> _vikobaData = [];

  @override
  bool get wantKeepAlive => true;

  // Minimalist monochrome color palette from design guidelines
  static const Color primaryColor = Color(0xFF1A1A1A);  // Dark charcoal
  static const Color accentColor = Color(0xFF666666);    // Medium gray
  static const Color backgroundColor = Color(0xFFFAFAFA); // Light gray background
  static const Color cardColor = Colors.white;            // Pure white for cards
  static const Color textColor = Color(0xFF1A1A1A);      // Dark text
  static const Color secondaryTextColor = Color(0xFF666666); // Secondary text
  static const Color dividerColor = Color(0xFFE0E0E0);   // Light divider
  static const Color shadowColor = Color(0x1A000000);    // Subtle shadow

  @override
  void initState() {
    super.initState();
    _logger.i('VikobaListPage initialized');
    _loadData();
    _setupFirestoreListener();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  /// Load data: first from cache for instant display, then from backend API
  Future<void> _loadData() async {
    final userId = DataStore.currentUserId;
    if (userId == null || userId.isEmpty) {
      _logger.e('[VikobaList] Cannot load data - userId is empty');
      setState(() => _isInitialLoading = false);
      return;
    }

    // Step 1: Load cached data for instant display
    final cachedData = await VikobaListCacheService.getVikobaList(userId);
    if (cachedData != null && cachedData.isNotEmpty && mounted) {
      setState(() {
        _vikobaData = cachedData;
        DataStore.myVikobaList = cachedData;
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[VikobaList] Loaded ${cachedData.length} cached vikobas');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend();
  }

  /// Fetch fresh data from backend API
  Future<void> _fetchDataFromBackend({bool forceRefresh = false}) async {
    final userId = DataStore.currentUserId;
    if (userId == null || userId.isEmpty) {
      _logger.e('[VikobaList] Cannot fetch - userId is empty');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Check connectivity
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _logger.w('[VikobaList] No internet connection');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        if (_hasCachedData) _showConnectivitySnackbar();
      }
      return;
    }

    try {
      final freshData = await HttpService().getData2xp();

      if (mounted) {
        setState(() {
          _vikobaData = freshData;
          DataStore.myVikobaList = freshData;
          _hasCachedData = freshData.isNotEmpty;
          _isInitialLoading = false;
        });
      }

      // Cache the fresh data
      await VikobaListCacheService.saveVikobaList(userId, freshData);
      _logger.d('[VikobaList] Fetched and cached ${freshData.length} vikobas');
    } catch (e) {
      _logger.e('[VikobaList] Error fetching from backend: $e');
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  /// Check if device has internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      _logger.e('[VikobaList] Connectivity check error: $e');
      return true; // Assume connected on error
    }
  }

  /// Setup Firestore listener for VikobaUpdates
  void _setupFirestoreListener() {
    final userId = DataStore.currentUserId;
    if (userId == null || userId.isEmpty) {
      _logger.w('[VikobaList] No user ID, skipping Firestore listener');
      return;
    }

    _logger.i('[VikobaList] Setting up Firestore listener for user: $userId');

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('VikobaUpdates')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!snapshot.exists || _isInitialLoading) return;

        final notificationData = snapshot.data();
        final newVersion = notificationData?['version'] as int?;
        final updatedAt = notificationData?['updatedAt'];
        final effectiveVersion = newVersion ?? updatedAt?.hashCode;

        if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
          _logger.i('[VikobaList] Change notification: version $_lastKnownVersion -> $effectiveVersion');
          _lastKnownVersion = effectiveVersion;

          await VikobaListCacheService.saveVersion(userId, effectiveVersion);
          await VikobaListCacheService.clearCache(userId);
          _fetchDataFromBackend(forceRefresh: true);
        }
      },
      onError: (error) {
        _logger.e('[VikobaList] Firestore listener error: $error');
      },
    );
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    final isConnected = await _hasInternetConnection();
    if (!isConnected) {
      _showConnectivitySnackbar();
      return;
    }

    setState(() => _isRefreshing = true);
    await _fetchDataFromBackend(forceRefresh: true);
    if (mounted) setState(() => _isRefreshing = false);
  }

  /// Show offline snackbar
  void _showConnectivitySnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isSwahili
                    ? 'Hakuna mtandao. Unaona data iliyohifadhiwa.'
                    : 'No internet. Showing cached data.',
                style: const TextStyle(fontSize: 13),
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

  Widget _buildKikobaItem(BuildContext context, vicoba kikoba, int position) {
    _logger.d('Building kikoba item: ${kikoba.kikobaname}');

    final isPending = kikoba.membershipStatus == "pending";
    final isFromCurrentUser = kikoba.source == DataStore.currentUserId;

    if (isPending && !isFromCurrentUser) {
      return _buildInvitationItem(kikoba, position);
    } else if (isPending && isFromCurrentUser) {
      return _buildPendingRequestItem(kikoba);
    } else {
      return _buildActiveKikobaItem(context, kikoba);
    }
  }

  Widget _buildInvitationItem(vicoba kikoba, int position) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.mail_outline, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  _isSwahili ? 'Mwaliko wa Kujiunga' : 'Invitation to Join',
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildKikobaTileContent(kikoba),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(kikoba, position),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestItem(vicoba kikoba) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSwahili ? 'Ombi lako linasubiri kuidhinishwa' : 'Your request is pending approval',
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _buildKikobaTileContent(kikoba),
        ],
      ),
    );
  }

  Widget _buildActiveKikobaItem(BuildContext context, vicoba kikoba) {
    return Column(
      children: [
        _buildKikobaTile(
          kikoba,
          onTap: () => _onTapItem(context, kikoba),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildKikobaTile(vicoba kikoba, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          kikoba.kikobaname,
          style: const TextStyle(
            fontSize: 15.0,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            kikoba.maelezokuhusukikoba,
            style: const TextStyle(
              fontSize: 12.0,
              color: secondaryTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: dividerColor, width: 1),
          ),
          child: ClipOval(
            child: kikoba.kikobaImage.isNotEmpty && kikoba.kikobaImage != 'noimage'
                ? Image.network(
                    kikoba.kikobaImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.group, color: primaryColor, size: 24),
                  )
                : Icon(Icons.group, color: primaryColor, size: 24),
          ),
        ),
        trailing: onTap == null
            ? null
            : Icon(Icons.arrow_forward_ios, size: 16.0, color: secondaryTextColor),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionButtons(vicoba kikoba, int position) {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            text: _isSwahili ? "Kataa" : "Decline",
            isPrimary: false,
            onPressed: () => _handleRejectInvitation(kikoba.requestId, position),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildButton(
            text: _isSwahili ? "Kubali" : "Accept",
            isPrimary: true,
            onPressed: () => _handleAcceptInvitation(kikoba, position),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed, bool isPrimary = false}) {
    return Material(
      color: isPrimary ? primaryColor : cardColor,
      borderRadius: BorderRadius.circular(8),
      elevation: isPrimary ? 2 : 0,
      shadowColor: shadowColor,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isPrimary ? null : Border.all(color: dividerColor, width: 1),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.0,
                color: isPrimary ? Colors.white : textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKikobaTileContent(vicoba kikoba) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        kikoba.kikobaname,
        style: const TextStyle(
          fontSize: 15.0,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          kikoba.maelezokuhusukikoba,
          style: const TextStyle(
            fontSize: 12.0,
            color: secondaryTextColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: dividerColor, width: 1),
        ),
        child: ClipOval(
          child: kikoba.kikobaImage.isNotEmpty && kikoba.kikobaImage != 'noimage'
              ? Image.network(
                  kikoba.kikobaImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.group, color: primaryColor, size: 24),
                )
              : Icon(Icons.group, color: primaryColor, size: 24),
        ),
      ),
    );
  }

  Future<void> _handleRejectInvitation(String requestId, int position) async {
    _logger.i('Rejecting invitation with requestId: $requestId');

    DataStore.waitDescription = "Maamuzi yanatumwa...";
    _showWaitDialog("Tafadhali Subiri", "Usajiri unafanyika...");

    try {
      final result = await HttpService.rejectInvitation(requestId);
      _logger.d('Rejection result: $result');

      if (!mounted) return;

      if (result.trim() == "success") {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _vikobaData.removeAt(position);
          DataStore.myVikobaList = List.from(_vikobaData);
        });
        // Update cache
        final userId = DataStore.currentUserId;
        if (userId != null && userId.isNotEmpty) {
          await VikobaListCacheService.saveVikobaList(userId, _vikobaData);
        }
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorDialog("Kuna tatizo la mtandao, tafadhali jaribu tena");
      }
    } catch (e, stackTrace) {
      _logger.e('Error rejecting invitation', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorDialog("Kuna tatizo la mtandao, tafadhali jaribu tena");
    }
  }

  Future<void> _handleAcceptInvitation(vicoba kikoba, int position) async {
    _logger.i('Accepting invitation for kikoba: ${kikoba.kikobaname}');

    DataStore.waitDescription = "Maamuzi yanatumwa...";
    _showWaitDialog("Tafadhali Subiri", "Usajiri unafanyika...");

    try {
      final result = await HttpService.acceptInvitation(kikoba.requestId);
      _logger.d('Acceptance result: $result');

      if (!mounted) return;

      if (result.trim() == "success") {
        await _postJoinNotification(kikoba);
        Navigator.of(context, rootNavigator: true).pop();
        _onTapItem(context, kikoba);
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorDialog("Kuna tatizo la mtandao, tafadhali jaribu tena");
      }
    } catch (e, stackTrace) {
      _logger.e('Error accepting invitation', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorDialog("Kuna tatizo la mtandao, tafadhali jaribu tena");
    }
  }

  Future<void> _postJoinNotification(vicoba kikoba) async {
    try {
      _logger.d('Posting join notification for kikoba: ${kikoba.kikobaname}');

      final postComment = "Mjumbe mpya, ndugu ${DataStore.currentUserName}, Kajiunga na kikundi hichi.";
      final uuid = const Uuid().v4();
      final dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      final thedate = dateFormat.format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('${kikoba.kikobaid}barazaMessages')
          .add({
        'posterName': DataStore.currentUserName,
        'posterId': DataStore.currentUserId,
        'posterNumber': DataStore.userNumber,
        'posterPhoto': "",
        'postComment': postComment,
        'postImage': '',
        'postType': 'taarifaYakujiunga',
        'postId': uuid,
        'postTime': thedate,
        'kikobaId': kikoba.kikobaid,
      });

      _logger.i('Successfully posted join notification');
    } catch (e, stackTrace) {
      _logger.e('Error posting join notification', error: e, stackTrace: stackTrace);
    }
  }

  void _onTapItem(BuildContext context, vicoba article) {
    _logger.i('Navigating to kikoba details: ${article.kikobaname}');

    // Set current kikoba details
    DataStore.currentKikobaId = article.kikobaid;
    DataStore.currentKikobaName = article.kikobaname;

    // Populate group bank account details from kikoba data
    if (article.groupAccountNumber != null && article.groupAccountNumber!.isNotEmpty) {
      DataStore.payingAccount = article.groupAccountNumber!;
      _logger.i('Set group account: ${article.groupAccountNumber}');
    }

    if (article.groupBankName != null && article.groupBankName!.isNotEmpty) {
      DataStore.payingBank = article.groupBankName!;
      _logger.i('Set group bank name: ${article.groupBankName}');
    }

    if (article.groupBankCode != null && article.groupBankCode!.isNotEmpty) {
      DataStore.payingBIN = article.groupBankCode!;
      _logger.i('Set group bank code: ${article.groupBankCode}');
    }

    Navigator.of(context).push(_createRouteToKikobaData());
  }

  Route _createRouteToKikobaData() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => getKikobaData(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _showWaitDialog(String title, String description) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return waitDialog(
          title: title,
          descriptions: description,
          text: "",
        );
      },
    );
  }

  Future<void> _showErrorDialog(String message) async {
    _logger.w('Showing error dialog: $message');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _isSwahili ? 'Kuna tatizo' : 'Error',
            style: const TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
              child: Text(
                _isSwahili ? 'Sawa' : 'OK',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKikobaListView(List<vicoba> kikobas) {
    return ListView.builder(
      itemCount: kikobas.length,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemBuilder: (context, position) {
        return _buildKikobaItem(context, kikobas[position], position);
      },
    );
  }

  /// Build skeleton loading animation
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: List.generate(6, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSkeletonCard(),
        )),
      ),
    );
  }

  /// Build individual skeleton card
  Widget _buildSkeletonCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300.withValues(alpha: value),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 16,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300.withValues(alpha: value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300.withValues(alpha: value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow skeleton
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300.withValues(alpha: value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    _logger.i('No kikobas found, redirecting to search/create');

    Future.delayed(Duration.zero, () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const searchOrcreate(
            message: "Huna kikoba kilichosajiliwa. Tafadhali sajili au tafuta kikoba.",
          ),
        ),
      );
    });

    return const Scaffold();
  }

  Widget _buildMainContent() {
    // Show empty state only after loading is complete and data is empty
    if (!_isInitialLoading && _vikobaData.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: primaryColor,
        child: _isInitialLoading && !_hasCachedData
            ? _buildSkeletonLoading()
            : _buildKikobaListView(_vikobaData),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildBottomAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.search_rounded,
                label: _isSwahili ? 'Tafuta' : 'Search',
                onPressed: () {
                  _logger.d('Search button pressed');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchBarx()),
                  );
                },
              ),
              _buildBottomNavItem(
                icon: Icons.add_circle_outline_rounded,
                label: _isSwahili ? 'Ongeza' : 'Create',
                onPressed: () {
                  _logger.d('Add kikoba button pressed');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => sajiriKikoba()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({required IconData icon, required String label, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: primaryColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    _logger.d('Building VikobaListPage');
    return _buildMainContent();
  }
}