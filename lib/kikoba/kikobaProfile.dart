import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'DataStore.dart';
import 'vicobaList.dart';
import 'HttpService.dart';

// Design Guidelines Colors (Monochrome)
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _accentColor = Color(0xFF999999);
const _iconBg = Color(0xFF1A1A1A);

class KikobaProfilePage extends StatefulWidget {
  const KikobaProfilePage({super.key});

  @override
  State<KikobaProfilePage> createState() => _KikobaProfilePageState();
}

class _KikobaProfilePageState extends State<KikobaProfilePage> {
  final Logger _logger = Logger();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = true;
  bool _hasError = false;
  bool _isRequesting = false;

  // Basic kikoba info
  late String _kikobaId;
  late String _kikobaName;
  late String _description;
  late String _location;
  late String _kikobaImage;
  late int _memberCount;

  // Creator info
  late String _creatorName;
  late String _creatorId;

  // User status
  bool _isMember = false;
  String? _userRole;
  bool _hasPendingRequest = false;

  // Bank details
  String? _bankAccountNumber;
  String? _bankName;

  // Stats (optional)
  int _totalLoans = 0;
  int _activeLoans = 0;
  int _balance = 0;

  // Katiba (optional)
  int _adaAmount = 0;
  int _hisaAmount = 0;

  @override
  void initState() {
    super.initState();
    _logger.i('KikobaProfilePage initialized');
    _loadKikobaData();
  }

  Future<void> _loadKikobaData() async {
    _logger.d('Loading kikoba data for ID: ${DataStore.visitedKikobaId}');

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Build URL with new endpoint format: /api/kikoba/{kikobaId}
      final uri = Uri.parse("${HttpService.baseUrl}kikoba/${DataStore.visitedKikobaId}").replace(
        queryParameters: {
          'userId': DataStore.currentUserId,
          'include': 'katiba,stats',
        },
      );

      final response = await http.get(
        uri,
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 10));

      _logger.d('API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logger.i('Received kikoba data');

        if (responseData is List && responseData.isNotEmpty) {
          final kikobaData = responseData[0];
          _updateKikobaData(kikobaData);
        } else if (responseData is Map) {
          _updateKikobaData(responseData as Map<String, dynamic>);
        } else {
          _logger.w('Empty or invalid response data');
          setState(() => _hasError = true);
        }
      } else {
        _logger.e('API error: ${response.statusCode}');
        setState(() => _hasError = true);
      }
    } catch (e, stackTrace) {
      _logger.e('Error loading kikoba data', error: e, stackTrace: stackTrace);
      setState(() => _hasError = true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateKikobaData(Map<String, dynamic> kikobaData) {
    setState(() {
      // Basic info
      _kikobaId = kikobaData["kikobaid"]?.toString() ?? 'N/A';
      _kikobaName = kikobaData["kikobaname"]?.toString() ?? 'Jina haijulikani';
      _description = kikobaData["description"]?.toString() ??
                     kikobaData["maelezokuhusukikoba"]?.toString() ?? 'Hakuna maelezo';
      _location = kikobaData["location"]?.toString() ?? 'Eneo haijulikani';
      _kikobaImage = kikobaData["image"]?.toString() ??
                     kikobaData["kikobaImage"]?.toString() ?? '';
      _memberCount = kikobaData["member_count"] is int
          ? kikobaData["member_count"]
          : int.tryParse(kikobaData["member_count"]?.toString() ??
                         kikobaData["membersNo"]?.toString() ?? '0') ?? 0;

      // Creator info
      final creator = kikobaData["creator"];
      if (creator is Map) {
        _creatorName = creator["name"]?.toString() ?? 'N/A';
        _creatorId = creator["id"]?.toString() ?? '';
      } else {
        _creatorName = kikobaData["creatorname"]?.toString() ?? 'N/A';
        _creatorId = '';
      }

      // User status
      final userStatus = kikobaData["user_status"];
      if (userStatus is Map) {
        _isMember = userStatus["is_member"] == true;
        _userRole = userStatus["role"]?.toString();
        _hasPendingRequest = userStatus["has_pending_request"] == true;
      }

      // Bank details
      final bankDetails = kikobaData["bank_details"];
      if (bankDetails is Map) {
        _bankAccountNumber = bankDetails["account_number"]?.toString();
        _bankName = bankDetails["bank_name"]?.toString();
      }

      // Stats (optional)
      final stats = kikobaData["stats"];
      if (stats is Map) {
        _totalLoans = stats["total_loans"] is int ? stats["total_loans"] : 0;
        _activeLoans = stats["active_loans"] is int ? stats["active_loans"] : 0;
        _balance = stats["balance"] is int ? stats["balance"] : 0;
      }

      // Katiba (optional)
      final katiba = kikobaData["katiba"];
      if (katiba is Map) {
        _adaAmount = katiba["ada"] is int ? katiba["ada"] : 0;
        _hisaAmount = katiba["hisa"] is int ? katiba["hisa"] : 0;
      }
    });
  }

  Future<void> _requestMembership() async {
    if (_isRequesting) return;

    _logger.i('Requesting membership for kikoba: $_kikobaName');

    setState(() => _isRequesting = true);

    try {
      // Make direct API call to handle new response format
      final response = await http.post(
        Uri.parse("${HttpService.baseUrl}membership-request"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'visitedKikobaId': DataStore.visitedKikobaId,
          'currentUserId': DataStore.currentUserId,
          'currentUserName': DataStore.currentUserName,
          'mobileNumber': DataStore.userNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      _logger.d('Membership request response: ${response.body}');

      final responseData = json.decode(response.body);
      final code = responseData['code'];
      final message = responseData['message']?.toString() ?? '';
      final data = responseData['data'] as Map<String, dynamic>?;
      final requestDetails = responseData['request_details'] as Map<String, dynamic>?;

      // Handle response codes
      if (code == 700) {
        // Success - request submitted
        final requestId = data?['request_id']?.toString();
        final kikobaInfo = data?['kikoba'] as Map<String, dynamic>?;
        final kikobaName = kikobaInfo?['name']?.toString() ?? _kikobaName;

        _logger.i('Membership request submitted successfully. Request ID: $requestId');

        // Post to Firestore VotingCases for the voting system integration
        await _postToVotingSystem(requestId, kikobaName);

        // Note: FCM notification is handled by the backend via membership-request API

        setState(() => _hasPendingRequest = true);
        _showResultDialog(
          title: "Ombi Limetumwa",
          message: "Maombi yako yamepelekwa kwa viongozi wa kikundi '$kikobaName'. Utapokea taarifa wakati ombi lako litakapoidhinishwa.",
          isSuccess: true,
        );
      } else if (code == 701) {
        // Already a member
        setState(() => _isMember = true);
        _showResultDialog(
          title: "Tayari Mwanachama",
          message: message.isNotEmpty ? message : "Tayari wewe ni mwanachama wa kikundi hiki.",
          isSuccess: false,
        );
      } else if (code == 702) {
        // Pending request exists
        final yesVotes = requestDetails?['yes_votes'] ?? 0;
        final noVotes = requestDetails?['no_votes'] ?? 0;
        final createdAt = requestDetails?['created_at']?.toString() ?? '';

        setState(() => _hasPendingRequest = true);
        _showResultDialog(
          title: "Ombi Lipo",
          message: "Tayari una ombi linalosubiri kuidhinishwa.\n\nKura: Ndiyo $yesVotes, Hapana $noVotes",
          isSuccess: false,
        );
      } else if (code == 703) {
        // Kikoba not found
        _showResultDialog(
          title: "Kikundi Hakipatikani",
          message: message.isNotEmpty ? message : "Kikundi hiki hakipatikani kwenye mfumo.",
          isSuccess: false,
        );
      } else {
        _showResultDialog(
          title: "Tatizo",
          message: message.isNotEmpty ? message : "Kumetokea tatizo wakati wa kupeleka maombi yako. Tafadhali jaribu tena.",
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Error requesting membership', error: e, stackTrace: stackTrace);
      _showResultDialog(
        title: "Tatizo la Mtandao",
        message: "Hakuna mawasiliano. Tafadhali hakikisha una internet na jaribu tena.",
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  /// Post membership request to Firestore VotingCases for voting system integration
  Future<void> _postToVotingSystem(String? requestId, String kikobaName) async {
    _logger.d('Posting membership request to VotingCases collection');

    try {
      final caseId = requestId ?? 'MR_${const Uuid().v4()}';
      final now = DateTime.now();

      // Create voting case in Firestore
      await FirebaseFirestore.instance
          .collection('VotingCases')
          .doc(caseId)
          .set({
        'caseId': caseId,
        'caseType': 'membership_request',
        'kikobaId': DataStore.visitedKikobaId,
        'applicantId': DataStore.currentUserId,
        'applicantName': DataStore.currentUserName,
        'applicantPhone': DataStore.userNumber,
        'status': 'pending',
        'yesVotes': 0,
        'noVotes': 0,
        'abstainVotes': 0,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'title': 'Ombi la Kujiunga',
        'description': '${DataStore.currentUserName} anaomba kujiunga na kikoba "$kikobaName"',
        'approvalThreshold': 66.67, // 2/3 majority required
        'requestId': requestId,
      });

      _logger.i('Voting case created successfully: $caseId');

      // Also post to baraza messages for backwards compatibility
      final postComment = "Ndugu ${DataStore.currentUserName} anaomba kujiunga na kikoba hiki. Piga kura kwenye sehemu ya WAJIBU.";
      final dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

      await FirebaseFirestore.instance
          .collection('${DataStore.visitedKikobaId}barazaMessages')
          .add({
        'posterName': DataStore.currentUserName,
        'posterId': DataStore.currentUserId,
        'posterNumber': DataStore.userNumber,
        'posterPhoto': "",
        'postComment': postComment,
        'postImage': '',
        'postType': 'maombiyakujiunga',
        'postId': caseId,
        'postTime': dateFormat.format(now),
        'kikobaId': DataStore.visitedKikobaId,
        'votingCaseId': caseId, // Link to voting case
      });

      _logger.i('Baraza message posted successfully');
    } catch (e, stackTrace) {
      _logger.e('Error posting to voting system', error: e, stackTrace: stackTrace);
      // Don't rethrow - Firestore post is secondary to API request
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSuccess ? _iconBg : _primaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSuccess ? Icons.check_rounded : Icons.info_outline_rounded,
                color: isSuccess ? Colors.white : _secondaryText,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryText,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: _secondaryText,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Material(
              color: _primaryText,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  if (isSuccess) {
                    // Navigate to VicobaListPage and clear stack
                    Navigator.of(this.context).pop();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      "Sawa",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('Building KikobaProfilePage UI');

    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Taarifa za Kikundi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _primaryText,
          strokeWidth: 2,
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primaryBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: _secondaryText,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tatizo la Kupakua",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Hatukuweza kupakua taarifa za kikundi",
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Material(
                    color: _primaryText,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _loadKikobaData,
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          "Jaribu Tena",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            if (_adaAmount > 0 || _hisaAmount > 0) ...[
              const SizedBox(height: 16),
              _buildKatibaCard(),
            ],
            const SizedBox(height: 24),
            _buildActionButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kikoba Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kikobaImage.isNotEmpty ? null : _iconBg,
              borderRadius: BorderRadius.circular(20),
              image: _kikobaImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_kikobaImage),
                      fit: BoxFit.cover,
                      onError: (e, _) => _logger.e('Image load error', error: e),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: _iconBg.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _kikobaImage.isEmpty
                ? const Icon(Icons.groups_rounded, color: Colors.white, size: 36)
                : null,
          ),
          const SizedBox(height: 16),
          // Kikoba Name
          Text(
            _kikobaName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: _accentColor),
              const SizedBox(width: 4),
              Text(
                _location,
                style: const TextStyle(
                  fontSize: 13,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
          // User Status Badge
          if (_isMember || _hasPendingRequest || _userRole != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isMember ? _iconBg : _primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isMember
                    ? (_userRole ?? 'Mwanachama')
                    : 'Ombi Linasubiri',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isMember ? Colors.white : _secondaryText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people_outline_rounded, color: _secondaryText, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_memberCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              const Text(
                'Wanachama',
                style: TextStyle(
                  fontSize: 12,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.info_outline_rounded, 'Maelezo', _description),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.person_outline_rounded, 'Mwanzilishi', _creatorName),
          if (_bankName != null && _bankName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(Icons.account_balance_outlined, 'Benki', '$_bankName${_bankAccountNumber != null ? ' - $_bankAccountNumber' : ''}'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _primaryBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _secondaryText, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: _primaryText,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKatibaCard() {
    final formatter = NumberFormat('#,###');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Katiba',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKatibaItem('Ada', 'TSh ${formatter.format(_adaAmount)}'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKatibaItem('Hisa', 'TSh ${formatter.format(_hisaAmount)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKatibaItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    // Already a member
    if (_isMember) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primaryBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_rounded, color: _secondaryText, size: 20),
            SizedBox(width: 8),
            Text(
              'Tayari Wewe ni Mwanachama',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    // Has pending request
    if (_hasPendingRequest) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primaryBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.hourglass_top_rounded, color: _secondaryText, size: 20),
            SizedBox(width: 8),
            Text(
              'Ombi Lako Linasubiri Kuidhinishwa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    // Can request to join
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: _primaryText,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isRequesting ? null : _requestMembership,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isRequesting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Omba Kujiunga',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}