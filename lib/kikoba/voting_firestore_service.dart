import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'DataStore.dart';
import 'kikoba_firebase.dart';

/// Model for a voting case from Firestore
class VotingCase {
  final String caseId;
  final String caseType;
  final String kikobaId;
  final String applicantId;
  final String applicantName;
  final double? principalAmount;
  final int? tenure;
  final String status;
  final int yesVotes;
  final int noVotes;
  final int abstainVotes;
  final DateTime createdAt;
  final String? description;
  final String? title;
  final double? approvalThreshold;
  final Map<String, dynamic>? extraData;

  VotingCase({
    required this.caseId,
    required this.caseType,
    required this.kikobaId,
    required this.applicantId,
    required this.applicantName,
    this.principalAmount,
    this.tenure,
    required this.status,
    required this.yesVotes,
    required this.noVotes,
    required this.abstainVotes,
    required this.createdAt,
    this.description,
    this.title,
    this.approvalThreshold,
    this.extraData,
  });

  factory VotingCase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VotingCase(
      caseId: data['caseId'] ?? doc.id,
      caseType: data['caseType'] ?? data['type'] ?? 'unknown',
      kikobaId: data['kikobaId'] ?? '',
      applicantId: data['applicantId'] ?? data['userId'] ?? '',
      applicantName: data['applicantName'] ?? data['userName'] ?? '',
      principalAmount: (data['principalAmount'] ?? data['amount'])?.toDouble(),
      tenure: data['tenure'] is int ? data['tenure'] : int.tryParse(data['tenure']?.toString() ?? ''),
      status: data['status'] ?? 'pending',
      yesVotes: data['yesVotes'] ?? 0,
      noVotes: data['noVotes'] ?? 0,
      abstainVotes: data['abstainVotes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? data['maelezo'],
      title: data['title'],
      approvalThreshold: data['approvalThreshold']?.toDouble() ?? 66.67,
      extraData: data,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'caseId': caseId,
      'caseType': caseType,
      'kikobaId': kikobaId,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'principalAmount': principalAmount,
      'tenure': tenure,
      'status': status,
      'yesVotes': yesVotes,
      'noVotes': noVotes,
      'abstainVotes': abstainVotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'title': title,
      'approvalThreshold': approvalThreshold,
    };
  }

  int get totalVotes => yesVotes + noVotes + abstainVotes;

  double get approvalPercentage {
    if (totalVotes == 0) return 0;
    return (yesVotes / totalVotes) * 100;
  }

  bool get hasReachedThreshold => approvalPercentage >= (approvalThreshold ?? 66.67);

  /// Convert to thecase format for compatibility with existing UI
  Map<String, dynamic> toTheCaseJson() {
    return {
      'id': caseId,
      'caseID': caseId,
      'kikobaID': kikobaId,
      'userID': applicantId,
      'type': caseType,
      'maelezo': description ?? '',
      'title': title,
      'status': status,
      'chairmansVote': '',
      'secretarysVote': '',
      'quarantorsVote': '',
      'othersVote': yesVotes.toString(),
      'othersVoteNo': noVotes.toString(),
      'numberOfVoters': totalVotes.toString(),
      'date': createdAt.toIso8601String(),
      'dateTime': createdAt.toIso8601String(),
      'fiftyPercentCheck': '',
      'seventyFivePercentCheck': '',
      'aHundredPercentCheck': '',
      'voting': {
        'yes_count': yesVotes,
        'no_count': noVotes,
        'abstain_count': abstainVotes,
        'total_votes': totalVotes,
        'approval_percentage': approvalPercentage,
        'approval_threshold': approvalThreshold ?? 66.67,
        'has_reached_threshold': hasReachedThreshold,
      },
      // Extra data for specific case types
      'amount': principalAmount,
      'tenure': tenure,
      'applicant_name': applicantName,
    };
  }
}

/// Model for a vote record
class VoteRecord {
  final String oderId;
  final String voterId;
  final String voterName;
  final String vote; // 'yes', 'no', 'abstain'
  final DateTime votedAt;

  VoteRecord({
    required this.oderId,
    required this.voterId,
    required this.voterName,
    required this.vote,
    required this.votedAt,
  });

  factory VoteRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoteRecord(
      oderId: doc.id,
      voterId: data['voterId'] ?? '',
      voterName: data['voterName'] ?? '',
      vote: data['vote'] ?? '',
      votedAt: (data['votedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'voterId': voterId,
      'voterName': voterName,
      'vote': vote,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }
}

/// Service for real-time voting sync via Firestore
///
/// Uses a SINGLE collection architecture for automatic index management:
/// - Collection: `VotingCases` (single collection for all kikobas)
/// - Filter by: `kikobaId` field
/// - This requires only ONE composite index for all kikobas
class VotingFirestoreService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static FirebaseFirestore get _firestore => KikobaFirebase.firestore;

  // Single collection name for all voting cases
  static const String _votingCasesCollection = 'VotingCases';
  static const String _votesCollection = 'Votes';

  // Stream subscriptions
  static StreamSubscription<QuerySnapshot>? _casesSubscription;
  static StreamSubscription<QuerySnapshot>? _singleCaseSubscription;

  // Callbacks
  static void Function(List<VotingCase> cases)? onCasesUpdated;
  static void Function(VotingCase case_)? onSingleCaseUpdated;

  /// Start listening to all pending voting cases for a kikoba
  /// Uses single collection with kikobaId filter (no per-kikoba indexes needed)
  static void listenToPendingCases({
    String? kikobaId,
    void Function(List<VotingCase> cases)? onUpdate,
  }) {
    final kId = kikobaId ?? DataStore.currentKikobaId ?? '';
    if (kId.isEmpty) {
      _logger.w('Cannot listen to cases: No kikoba ID');
      return;
    }

    // Cancel existing subscription
    _casesSubscription?.cancel();

    _logger.i('═══════════════════════════════════════════════════════════');
    _logger.i('🔔 FIRESTORE LISTENER START');
    _logger.i('═══════════════════════════════════════════════════════════');
    _logger.i('📂 Collection: $_votingCasesCollection');
    _logger.i('🔍 Filter: kikobaId == $kId AND status == pending');
    _logger.i('📊 Order: createdAt DESC');
    _logger.i('───────────────────────────────────────────────────────────');

    _casesSubscription = _firestore
        .collection(_votingCasesCollection)
        .where('kikobaId', isEqualTo: kId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _logger.i('📬 Firestore snapshot received');
        _logger.i('   Documents: ${snapshot.docs.length}');
        _logger.i('   From cache: ${snapshot.metadata.isFromCache}');

        final cases = snapshot.docs
            .map((doc) => VotingCase.fromFirestore(doc))
            .toList();

        // Update DataStore for compatibility
        DataStore.casesList = cases.map((c) => c.toTheCaseJson()).toList();

        // Log case details
        for (var c in cases) {
          _logger.d('   📋 Case: ${c.caseId} | Type: ${c.caseType} | Yes: ${c.yesVotes} No: ${c.noVotes}');
        }

        // Call callback
        onUpdate?.call(cases);
        onCasesUpdated?.call(cases);
      },
      onError: (error) {
        _logger.e('───────────────────────────────────────────────────────────');
        _logger.e('❌ Firestore listener error');
        _logger.e('───────────────────────────────────────────────────────────');
        _logger.e('   Error: $error');

        // Check if it's an index error
        if (error.toString().contains('index')) {
          _logger.e('   💡 This is an INDEX error. The required index should be auto-created.');
          _logger.e('   💡 Check Firebase Console > Firestore > Indexes');
        }
      },
    );
  }

  /// Start listening to a specific voting case
  static void listenToCase({
    required String caseId,
    String? kikobaId,
    void Function(VotingCase case_)? onUpdate,
  }) {
    final kId = kikobaId ?? DataStore.currentKikobaId ?? '';
    if (kId.isEmpty) {
      _logger.w('Cannot listen to case: No kikoba ID');
      return;
    }

    // Cancel existing subscription
    _singleCaseSubscription?.cancel();

    _logger.i('🔔 Listening to single case: $caseId');

    // Query by caseId field in the single collection
    _singleCaseSubscription = _firestore
        .collection(_votingCasesCollection)
        .where('caseId', isEqualTo: caseId)
        .where('kikobaId', isEqualTo: kId)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final case_ = VotingCase.fromFirestore(snapshot.docs.first);
          _logger.i('📬 Case updated: ${case_.caseId}');
          _logger.d('   Yes: ${case_.yesVotes} | No: ${case_.noVotes} | Abstain: ${case_.abstainVotes}');

          onUpdate?.call(case_);
          onSingleCaseUpdated?.call(case_);
        } else {
          _logger.w('Case not found: $caseId');
        }
      },
      onError: (error) {
        _logger.e('Error listening to case: $error');
      },
    );
  }

  /// Get votes for a specific case
  static Stream<List<VoteRecord>> getVotesStream({
    required String caseId,
    String? kikobaId,
  }) {
    final kId = kikobaId ?? DataStore.currentKikobaId ?? '';

    _logger.d('📊 Getting votes stream for case: $caseId');

    // Votes stored in single Votes collection with caseId field
    return _firestore
        .collection(_votesCollection)
        .where('caseId', isEqualTo: caseId)
        .where('kikobaId', isEqualTo: kId)
        .orderBy('votedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          _logger.d('   Received ${snapshot.docs.length} votes');
          return snapshot.docs
              .map((doc) => VoteRecord.fromFirestore(doc))
              .toList();
        });
  }

  /// Check if current user has voted on a case
  static Future<VoteRecord?> getUserVote({
    required String caseId,
    String? kikobaId,
    String? userId,
  }) async {
    final kId = kikobaId ?? DataStore.currentKikobaId ?? '';
    final uId = userId ?? DataStore.currentUserId ?? '';

    _logger.d('🔍 Checking if user $uId voted on case $caseId');

    try {
      final snapshot = await _firestore
          .collection(_votesCollection)
          .where('caseId', isEqualTo: caseId)
          .where('kikobaId', isEqualTo: kId)
          .where('voterId', isEqualTo: uId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final vote = VoteRecord.fromFirestore(snapshot.docs.first);
        _logger.d('   ✅ Found vote: ${vote.vote}');
        return vote;
      }
      _logger.d('   ❌ No vote found');
      return null;
    } catch (e) {
      _logger.e('Error checking user vote: $e');
      return null;
    }
  }

  /// Get all pending cases (one-time fetch)
  static Future<List<VotingCase>> getPendingCases({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId ?? '';
    if (kId.isEmpty) return [];

    _logger.i('📥 Fetching pending cases for kikoba: $kId');

    try {
      final snapshot = await _firestore
          .collection(_votingCasesCollection)
          .where('kikobaId', isEqualTo: kId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final cases = snapshot.docs.map((doc) => VotingCase.fromFirestore(doc)).toList();
      _logger.i('   ✅ Fetched ${cases.length} pending cases');
      return cases;
    } catch (e) {
      _logger.e('Error fetching pending cases: $e');
      return [];
    }
  }

  /// Get a single case (one-time fetch)
  static Future<VotingCase?> getCase({
    required String caseId,
    String? kikobaId,
  }) async {
    final kId = kikobaId ?? DataStore.currentKikobaId ?? '';
    if (kId.isEmpty) return null;

    _logger.d('📥 Fetching case: $caseId');

    try {
      final snapshot = await _firestore
          .collection(_votingCasesCollection)
          .where('caseId', isEqualTo: caseId)
          .where('kikobaId', isEqualTo: kId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final case_ = VotingCase.fromFirestore(snapshot.docs.first);
        _logger.d('   ✅ Found case: ${case_.caseType}');
        return case_;
      }
      _logger.d('   ❌ Case not found');
      return null;
    } catch (e) {
      _logger.e('Error fetching case: $e');
      return null;
    }
  }

  /// Stop listening to cases
  static void stopListening() {
    _logger.i('🔕 Stopping voting case listeners');
    _casesSubscription?.cancel();
    _casesSubscription = null;
    _singleCaseSubscription?.cancel();
    _singleCaseSubscription = null;
  }

  /// Clean up resources
  static void dispose() {
    stopListening();
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    onCasesUpdated = null;
    onSingleCaseUpdated = null;
    onConnectionChanged = null;
  }

  // ============================================================================
  // Connection State Management
  // ============================================================================

  static StreamSubscription<DocumentSnapshot>? _connectionSubscription;
  static bool _isConnected = true;
  static void Function(bool isConnected)? onConnectionChanged;

  /// Check if currently connected to Firestore
  static bool get isConnected => _isConnected;

  /// Stream that emits connection state changes
  /// Uses Firestore's built-in connection detection
  static Stream<bool> get connectionStream {
    return _firestore
        .collection('.info')
        .doc('connected')
        .snapshots()
        .map((snapshot) {
          // If we receive a snapshot, we're connected
          _isConnected = true;
          return true;
        })
        .handleError((error) {
          _isConnected = false;
          return false;
        });
  }

  /// Alternative connection check using a lightweight document read
  static Stream<bool> get connectionStateStream {
    // Create a stream controller to manage connection state
    final controller = StreamController<bool>.broadcast();

    // Periodic check every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // Try to read from Firestore with timeout
        await _firestore
            .collection('_ping')
            .doc('connection_test')
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 3));

        if (!_isConnected) {
          _isConnected = true;
          controller.add(true);
          onConnectionChanged?.call(true);
          _logger.i('🟢 Firestore connection restored');
        }
      } catch (e) {
        if (_isConnected) {
          _isConnected = false;
          controller.add(false);
          onConnectionChanged?.call(false);
          _logger.w('🔴 Firestore connection lost');
        }
      }
    });

    // Initial check
    _checkConnection().then((connected) {
      _isConnected = connected;
      controller.add(connected);
    });

    return controller.stream;
  }

  /// One-time connection check
  static Future<bool> _checkConnection() async {
    try {
      await _firestore
          .collection('_ping')
          .doc('connection_test')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start monitoring connection state
  static void startConnectionMonitoring() {
    _logger.i('🔌 Starting Firestore connection monitoring');

    _connectionSubscription?.cancel();

    // Listen to connection changes
    connectionStateStream.listen(
      (isConnected) {
        _logger.d('Connection state: ${isConnected ? "online" : "offline"}');
      },
      onError: (e) {
        _logger.e('Connection monitoring error: $e');
      },
    );
  }

  // ============================================================================
  // Index Information
  // ============================================================================

  /// Log the required Firestore indexes for this service
  static void logRequiredIndexes() {
    _logger.i('═══════════════════════════════════════════════════════════');
    _logger.i('📋 REQUIRED FIRESTORE INDEXES');
    _logger.i('═══════════════════════════════════════════════════════════');
    _logger.i('');
    _logger.i('Collection: VotingCases');
    _logger.i('Index 1: kikobaId (ASC) + status (ASC) + createdAt (DESC)');
    _logger.i('Index 2: caseId (ASC) + kikobaId (ASC)');
    _logger.i('');
    _logger.i('Collection: Votes');
    _logger.i('Index 1: caseId (ASC) + kikobaId (ASC) + votedAt (DESC)');
    _logger.i('Index 2: caseId (ASC) + kikobaId (ASC) + voterId (ASC)');
    _logger.i('');
    _logger.i('Deploy indexes: firebase deploy --only firestore:indexes');
    _logger.i('═══════════════════════════════════════════════════════════');
  }
}
