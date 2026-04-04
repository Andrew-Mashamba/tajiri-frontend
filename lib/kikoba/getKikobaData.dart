import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:vicoba/tabshome.dart';
import 'package:vicoba/HttpService.dart';
import 'Article.dart';
import 'DataStore.dart';
import 'OfflineDatabase.dart';
import 'RegisterOrLogin.dart';

class getKikobaData extends StatefulWidget {
  const getKikobaData({Key? key}) : super(key: key);

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<getKikobaData>
    with SingleTickerProviderStateMixin {
  static late Future<List<Article>> vikobalist;
  late final AnimationController animationController;
  late final Animation<double> animation;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _logger.i('🔵 Initializing SplashState');

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    animationController.dispose();
    _logger.i('🛑 Animation controller disposed');
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _logger.i('🚀 Starting _loadData');
      await _fetchKikobaData(DataStore.userNumber.replaceAll("+", ""));
    } catch (e, stackTrace) {
      _logger.e('❌ Error loading data', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }

  Future<void> _checkUserAuthentication() async {
    _logger.d('🔍 Checking user authentication status...');
    
    // Check if we have valid user data
    final bool hasValidUserId = DataStore.currentUserId != null && 
                               DataStore.currentUserId!.isNotEmpty && 
                               DataStore.currentUserId != "b05b4efef01c4ae89ca7284193ba21c2";
    
    final bool hasValidUserData = DataStore.currentUserName != null && 
                                 DataStore.currentUserName!.isNotEmpty &&
                                 DataStore.userNumber != null &&
                                 DataStore.userNumber!.isNotEmpty;

    _logger.d('📱 hasValidUserId: $hasValidUserId');
    _logger.d('📱 hasValidUserData: $hasValidUserData');
    _logger.d('📱 DataStore.currentUserId: ${DataStore.currentUserId}');
    _logger.d('📱 DataStore.currentUserName: ${DataStore.currentUserName}');
    _logger.d('📱 DataStore.userNumber: ${DataStore.userNumber}');

    if (!hasValidUserId || !hasValidUserData) {
      _logger.w('⚠️ User authentication invalid. Clearing stored data and redirecting to login.');
      
      // Clear all stored user data
      await _clearUserData();
      
      // Navigate to login
      await _redirectToLogin();
      return;
    }
    
    _logger.i('✅ User authentication valid. Proceeding with data fetch.');
  }

  Future<void> _clearUserData() async {
    _logger.i('🗑️ Clearing stored user data...');
    
    try {
      // Clear DataStore
      DataStore.currentUserId = "";
      DataStore.currentUserName = "";
      DataStore.userNumber = "";
      DataStore.currentUserIdid = null;
      DataStore.currentUserReg_date = null;
      DataStore.currentUserUserStatus = null;
      DataStore.currentUserIdUdid = null;
      DataStore.currentUserIdOtp = null;
      DataStore.currentKikobaIs_expired = null;
      DataStore.currentUserLocalpostImage = "assets/no-avatar.png";
      DataStore.currentUserIdRemotepostImage = "";
      DataStore.currentUserCreate_at = null;
      DataStore.userPresent = false;

      // Clear database
      await OfflineDatabase.delete();
      _logger.i('✅ Database cleared successfully');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Error clearing user data', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _redirectToLogin() async {
    _logger.i('🔄 Redirecting to login...');
    
    if (!mounted) {
      _logger.w('Widget not mounted, cannot navigate');
      return;
    }

    try {
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RegisterOrLogin(),
        ),
        (route) => false,
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Error navigating to login', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _fetchKikobaData(String phoneNumber) async {
    _logger.d('📞 Fetching data for phone: $phoneNumber');

    try {
      final cleanNumber = phoneNumber.replaceAll("+", "");
      _logger.d('🔧 Cleaned phone number: $cleanNumber');

      // Check user authentication before proceeding
      await _checkUserAuthentication();

      // Get userID - should be set during login
      String userID = DataStore.currentUserId ?? "";
      _logger.i('📱 Final userID being used: $userID');

      final url = Uri.parse(
        "${HttpService.baseUrl}data?kikobaId=${DataStore.currentKikobaId}&userID=$userID",
      );

      _logger.i('🌐 Making API request to: $url');

      final response = await http.get(
        url,
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 30));

      _handleResponse(response);
    } on TimeoutException {
      _logger.w('⏰ Request timed out');
      setState(() {
        _errorMessage = 'Request timed out. Please check your connection.';
      });
    } on http.ClientException catch (e) {
      _logger.e('🌐 Network error: ${e.message}');
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
    } catch (e, stackTrace) {
      _logger.e('❗ Unexpected error during fetch', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    }
  }

  void _handleResponse(http.Response response) {
    _logger.d('📥 Response received: Status ${response.statusCode}');
    _logger.d('📦 Raw Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        _logger.i('✅ JSON Decoded Successfully:');
        _logger.d(prettyJson(data));
        _processData(data);
        _navigateToHome();
      } catch (e, stackTrace) {
        _logger.e('❗ JSON parsing error', error: e, stackTrace: stackTrace);
        setState(() {
          _errorMessage = 'Data format error. Please contact support.';
        });
      }
    } else {
      _logger.w('⚠️ Server responded with error: ${response.statusCode}');
      setState(() {
        _errorMessage = 'Server error (${response.statusCode}). Please try again later.';
      });
    }
  }

  void _processData(dynamic data) {
    _logger.i('🔄 Processing data');

    if (data == null) {
      _logger.w('⚠️ Received null data');
      return;
    }

    if (data is! Map<String, dynamic>) {
      _logger.e('❗ Expected Map<String, dynamic> but got ${data.runtimeType}');
      throw Exception('Invalid data format');
    }

    if (data.isEmpty) {
      _logger.w('⚠️ Received empty data object');
      return;
    }

    try {
      // Log all top-level keys for debugging
      _logger.d('📋 Data keys: ${data.keys.join(', ')}');

      // Process each data type based on its key
      data.forEach((key, value) {
        _logger.d('🧩 Processing "$key": ${value != null ? prettyJson(value) : 'null'}');

        switch (key) {
          case 'allTransactions':
            if (value != null) _processTransactions(value);
            break;
          case 'monthlyAda':
            if (value != null) _processAda(value);
            break;
          case 'monthlyHisa':
            if (value != null) _processHisa(value);
            break;
          case 'akibaStatement':
            if (value != null) _processAkiba(value);
            break;
          case 'katiba':
            if (value != null) _processKatiba(value);
            break;
          case 'members':
            if (value != null) _processMembers(value);
            break;
          case 'loans':
            if (value != null) _processMikopo(value);
            break;
          case 'loanProducts':
            if (value != null) _processLoanProducts(value);
            break;
          case 'cases':
            if (value != null) _processCases(value);
            break;
          case 'michango':
            if (value != null) _processMichango(value);
            break;
          case 'faini':
            if (value != null) _processFaini(value);
            break;
          case 'controlNumbers':
            if (value != null) _processControlNumbers(value);
            break;
          default:
            _logger.d('🔸 Unprocessed key "$key": ${value != null ? prettyJson(value) : 'null'}');
        }
      });

      _logger.i('🏁 Data processing completed successfully');
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing data', error: e, stackTrace: stackTrace);
      throw Exception('Data processing failed: ${e.toString()}');
    }
  }

  // Utility for pretty print
  String prettyJson(dynamic data) {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  // Process individual sections
  void _processTransactions(dynamic transactionsData) {
    try {
      final transactions = (transactionsData is List<dynamic>)
          ? transactionsData
          : [];

      DataStore.transactionsList = transactions;
      _logger.i('🔵 [Transactions] Loaded ${transactions.length} items');
      _logger.d('📋 Transactions details:\n${prettyJson(transactions)}');
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing transactions', error: e, stackTrace: stackTrace);
      DataStore.transactionsList = [];
    }
  }

  void _processAda(dynamic adaData) {
    try {
      if (adaData is Map<String, dynamic>) {
        // Handle monthlyAda structure
        final monthlyAda = adaData.values.expand((monthData) =>
        monthData is List ? monthData : []).toList();
        DataStore.adaListList = monthlyAda;
        _logger.i('🟣 [ADA] Loaded ${monthlyAda.length} items across ${adaData.length} months');
        _logger.d('📋 ADA details:\n${prettyJson(monthlyAda)}');
      } else {
        _logger.w('⚠️ [ADA] Unexpected data format: ${adaData.runtimeType}');
        DataStore.adaListList = [];
      }
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing ADA', error: e, stackTrace: stackTrace);
      DataStore.adaListList = [];
    }
  }

  void _processHisa(dynamic hisaData) {
    try {
      if (hisaData is Map<String, dynamic>) {
        // Handle monthlyHisa structure
        final monthlyHisa = hisaData.values.expand((monthData) =>
        monthData is List ? monthData : []).toList();
        DataStore.hisaList = monthlyHisa;
        _logger.i('🟡 [HISA] Loaded ${monthlyHisa.length} items across ${hisaData.length} months');
        _logger.d('📋 HISA details:\n${prettyJson(monthlyHisa)}');
      } else {
        _logger.w('⚠️ [HISA] Unexpected data format: ${hisaData.runtimeType}');
        DataStore.hisaList = [];
      }
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing HISA', error: e, stackTrace: stackTrace);
      DataStore.hisaList = [];
    }
  }

  void _processAkiba(dynamic akibaData) {
    try {
      _logger.i('🏦 [AKIBA] Raw data type: ${akibaData.runtimeType}');
      _logger.i('🏦 [AKIBA] Raw data: ${prettyJson(akibaData)}');

      if (akibaData is List<dynamic>) {
        // Handle akibaStatement flat list structure (like transactions)
        DataStore.akibaList = akibaData;
        _logger.i('🏦 [AKIBA] ✅ Loaded ${akibaData.length} statement transactions');

        if (akibaData.isNotEmpty) {
          _logger.i('🏦 [AKIBA] First record: ${prettyJson(akibaData.first)}');
          _logger.i('🏦 [AKIBA] Sample fields - userId: ${akibaData.first['userId']}, credit: ${akibaData.first['credit']}, balance: ${akibaData.first['balance']}');
        } else {
          _logger.w('🏦 [AKIBA] ⚠️ List is empty!');
        }

        _logger.d('📋 AKIBA statement details:\n${prettyJson(akibaData)}');
      } else {
        _logger.e('❌ [AKIBA] Unexpected data format: ${akibaData.runtimeType}');
        _logger.e('❌ [AKIBA] Data content: ${prettyJson(akibaData)}');
        DataStore.akibaList = [];
      }
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing AKIBA', error: e, stackTrace: stackTrace);
      DataStore.akibaList = [];
    }
  }

  /// Extract numeric value from either a plain value or an object like {amount: 5000}
  String _extractNumericValue(dynamic value) {
    if (value == null) return '';

    // If it's a Map (object), try to get 'amount' or first numeric value
    if (value is Map) {
      if (value.containsKey('amount')) {
        return value['amount']?.toString() ?? '';
      }
      // Try to find any numeric value in the map
      for (var v in value.values) {
        if (v is num) return v.toString();
        if (v is String && double.tryParse(v) != null) return v;
      }
      return '';
    }

    // If it's already a number or string, just convert
    return value.toString();
  }

  void _processKatiba(dynamic katibaData) {
    try {
      final katibaList = (katibaData is List<dynamic>) ? katibaData : [];

      if (katibaList.isNotEmpty) {
        final katibaItem = katibaList[0];
        _logger.d('🟢 [KATIBA] Raw katiba item:\n${prettyJson(katibaItem)}');

        // Assign values safely with null checks
        DataStore.katiba = katibaItem;
        DataStore.kiingilio = _extractNumericValue(katibaItem["kiingilio"]);
        DataStore.kiingilioStatus = katibaItem["kiingilioStatus"]?.toString() ?? '';
        DataStore.ada = _extractNumericValue(katibaItem["ada"]);
        DataStore.adaStatus = katibaItem["adaStatus"]?.toString() ?? '';
        DataStore.Hisa = _extractNumericValue(katibaItem["hisa"]);
        DataStore.hisaStatus = katibaItem["hisaStatus"]?.toString() ?? '';
        DataStore.faini_ada = _extractNumericValue(katibaItem["faini_ada"]);
        DataStore.faini_adaStatus = katibaItem["faini_adaStatus"]?.toString() ?? '';
        DataStore.faini_hisa = _extractNumericValue(katibaItem["faini_hisa"]);
        DataStore.faini_hisaStatus = katibaItem["faini_hisaStatus"]?.toString() ?? '';
        DataStore.fainiVikao = _extractNumericValue(katibaItem["fainiVikao"]);
        DataStore.fainiVikaoStatus = katibaItem["fainiVikaoStatus"]?.toString() ?? '';
        DataStore.faini_michango = _extractNumericValue(katibaItem["faini_michango"]);
        DataStore.faini_michangoStatus = katibaItem["faini_michangoStatus"]?.toString() ?? '';
        DataStore.chini = katibaItem["chini"]?.toString() ?? '';
        DataStore.mikopo = katibaItem["mikopo"]?.toString() ?? '';
        DataStore.riba = double.tryParse(katibaItem["riba"]?.toString() ?? '0') ?? 0.0;
        DataStore.ribaStatus = katibaItem["ribaStatus"]?.toString() ?? '';
        DataStore.tenure = katibaItem["tenure"]?.toString() ?? '';
        DataStore.fainiyamikopo = katibaItem["fainiyamikopo"]?.toString() ?? '';
        DataStore.mikopoStatus = katibaItem["mikopoStatus"]?.toString() ?? '';

        _logger.i('✅ [KATIBA] Mapped katiba data');
      } else {
        _logger.w('⚠️ [KATIBA] Empty katiba received');
        DataStore.katiba = {};
      }
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing katiba', error: e, stackTrace: stackTrace);
      DataStore.katiba = {};
    }
  }

  void _processMembers(dynamic membersData) {
    try {
      final members = (membersData is List<dynamic>) ? membersData : [];
      DataStore.membersList = members;
      _logger.i('🟠 [MEMBERS] Loaded ${members.length} members');
      _logger.d('📋 Members details:\n${prettyJson(members)}');
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing members', error: e, stackTrace: stackTrace);
      DataStore.membersList = [];
    }
  }

  void _processMikopo(dynamic loansData) {
    try {
      final loans = (loansData is List<dynamic>) ? loansData : [];
      DataStore.mikopoList = loans;
      _logger.i('🔴 [MIKOPO] Loaded ${loans.length} loans');
      _logger.d('📋 Loans details:\n${prettyJson(loans)}');
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing loans', error: e, stackTrace: stackTrace);
      DataStore.mikopoList = [];
    }
  }

  void _processLoanProducts(dynamic loanProductsData) {
    try {
      _logger.i('💳 [LOAN PRODUCTS] Raw data type: ${loanProductsData.runtimeType}');

      if (loanProductsData is List<dynamic>) {
        DataStore.loanProducts = loanProductsData;
        _logger.i('💳 [LOAN PRODUCTS] ✅ Loaded ${loanProductsData.length} loan products');

        if (loanProductsData.isNotEmpty) {
          _logger.i('💳 [LOAN PRODUCTS] Sample products:');
          for (var i = 0; i < loanProductsData.length && i < 3; i++) {
            final product = loanProductsData[i];
            _logger.i('   ${i + 1}. ${product['name']} (${product['minAmount']}-${product['maxAmount']} TZS, ${product['interestRate']}%)');
          }
        } else {
          _logger.w('💳 [LOAN PRODUCTS] ⚠️ List is empty!');
        }

        _logger.d('📋 Full Loan Products data:\n${prettyJson(loanProductsData)}');
      } else {
        _logger.e('❌ [LOAN PRODUCTS] Unexpected data format: ${loanProductsData.runtimeType}');
        _logger.e('❌ [LOAN PRODUCTS] Data content: ${prettyJson(loanProductsData)}');
        DataStore.loanProducts = [];
      }
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing loan products', error: e, stackTrace: stackTrace);
      DataStore.loanProducts = [];
    }
  }

  void _processCases(dynamic casesData) {
    try {
      final cases = (casesData is List<dynamic>) ? casesData : [];
      DataStore.casesList = cases;
      _logger.i('🟤 [CASES] Loaded ${cases.length} cases');
      _logger.d('📋 Cases details:\n${prettyJson(cases)}');
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing cases', error: e, stackTrace: stackTrace);
      DataStore.casesList = [];
    }
  }

  void _processMichango(dynamic michangoData) {
    try {
      final michango = (michangoData is List<dynamic>) ? michangoData : [];
      DataStore.michangoList = michango;
      _logger.i('⚪ [MICHANGO] Loaded ${michango.length} contributions');
      _logger.d('📋 Contributions details:\n${prettyJson(michango)}');
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing contributions', error: e, stackTrace: stackTrace);
      DataStore.michangoList = [];
    }
  }

  void _processFaini(dynamic fainiData) {
    try {
      final faini = (fainiData is List<dynamic>) ? fainiData : [];
      DataStore.fainiList = faini;
      _logger.i('🧡 [FAINI] Loaded ${faini.length} fines');
      _logger.d('📋 Fines details:\n${prettyJson(faini)}');
    } catch (e, stackTrace) {
      _logger.e('❗ Error processing fines', error: e, stackTrace: stackTrace);
      DataStore.fainiList = [];
    }
  }

  void _processControlNumbers(dynamic controlData) {
    try {
      _logger.i('💳 Processing control numbers...');

      if (controlData is! Map<String, dynamic>) {
        _logger.w('⚠️ [CONTROL NUMBERS] Unexpected data format: ${controlData.runtimeType}');
        _clearControlNumbers();
        return;
      }

      // Process Ada control numbers
      if (controlData.containsKey('ada')) {
        DataStore.controlNumbersAda = (controlData['ada'] is List)
            ? controlData['ada']
            : [];
        _logger.i('💰 [ADA PAYMENTS] Loaded ${DataStore.controlNumbersAda.length} control numbers');
      } else {
        DataStore.controlNumbersAda = [];
      }

      // Process Hisa control numbers
      if (controlData.containsKey('hisa')) {
        DataStore.controlNumbersHisa = (controlData['hisa'] is List)
            ? controlData['hisa']
            : [];
        _logger.i('📊 [HISA PAYMENTS] Loaded ${DataStore.controlNumbersHisa.length} control numbers');
      } else {
        DataStore.controlNumbersHisa = [];
      }

      // Process Akiba control numbers
      if (controlData.containsKey('akiba')) {
        DataStore.controlNumbersAkiba = (controlData['akiba'] is List)
            ? controlData['akiba']
            : [];
        _logger.i('🏦 [AKIBA PAYMENTS] Loaded ${DataStore.controlNumbersAkiba.length} control numbers');
      } else {
        DataStore.controlNumbersAkiba = [];
      }

      final totalCount = DataStore.controlNumbersAda.length +
                        DataStore.controlNumbersHisa.length +
                        DataStore.controlNumbersAkiba.length;

      final pendingCount = DataStore.getPendingPaymentsCount();

      _logger.i('💳 [CONTROL NUMBERS] Total: $totalCount | Pending: $pendingCount');
      _logger.d('📋 Control numbers details:\n${prettyJson(controlData)}');

    } catch (e, stackTrace) {
      _logger.e('❗ Error processing control numbers', error: e, stackTrace: stackTrace);
      _clearControlNumbers();
    }
  }

  void _clearControlNumbers() {
    DataStore.controlNumbersAda = [];
    DataStore.controlNumbersHisa = [];
    DataStore.controlNumbersAkiba = [];
  }

  void _navigateToHome() {
    _logger.i('🚀 Navigating to Home (tabshome)');
    Navigator.of(context).pushReplacement(_createRoute());
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const tabshome(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Minimalist monochrome color palette from design guidelines
    const Color primaryBackground = Color(0xFFFAFAFA); // Light gray background
    const Color primaryText = Color(0xFF1A1A1A); // Dark charcoal for text
    const Color secondaryText = Color(0xFF666666); // Medium gray for secondary text
    const Color cardBackground = Colors.white; // Pure white for cards
    const Color shadowColor = Color(0x1A000000); // Subtle shadow

    return Scaffold(
      backgroundColor: primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Header Section (40% of screen) - Fixed height to prevent overflow
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Kikoba name with proper typography
                      Text(
                        DataStore.currentKikobaName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // Content Section (Flexible to prevent overflow)
              Flexible(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Loading/Error indicator with minimalist animation
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: animation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryText,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        // Error message with minimalist styling
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: secondaryText.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: secondaryText,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: secondaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Retry button with minimalist design
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
                          child: Material(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 2,
                            shadowColor: shadowColor,
                            child: InkWell(
                              onTap: _loadData,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: primaryText,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.refresh_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Jaribu Tena',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: primaryText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Bonyeza kurudia ombi',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: secondaryText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Bottom Padding
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
