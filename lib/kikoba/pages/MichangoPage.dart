import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../DataStore.dart';
import '../HttpService.dart';
import '../services/page_cache_service.dart';
import 'MchangoDetailPage.dart';

// Monochrome Design Guidelines Colors
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);
const _successColor = Color(0xFF4CAF50);
const _errorColor = Color(0xFFF44336);

class MichangoPage extends StatefulWidget {
  const MichangoPage({Key? key}) : super(key: key);

  @override
  State<MichangoPage> createState() => _MichangoPageState();
}

class _MichangoPageState extends State<MichangoPage> {
  final Logger _logger = Logger();
  final formatCurrency = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

  List<dynamic> _michango = [];

  // ============ State for caching and real-time updates ============
  /// IMPORTANT: All data is fetched from the BACKEND API.
  /// Firestore is used ONLY for change notifications, NOT for data.
  bool _isInitialLoading = true;
  bool _hasCachedData = false;
  bool _isRefreshing = false;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  int? _lastKnownVersion;

  @override
  void initState() {
    super.initState();
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
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty) {
      _logger.e('[MichangoPage] Cannot load data - kikobaId or visitorId is empty');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    // Step 1: Try to load cached data for instant display
    final cachedData = await PageCacheService.getMichangoData(visitorId, kikobaId);
    if (cachedData != null && mounted) {
      _applyCachedData(cachedData);
      setState(() {
        _hasCachedData = true;
        _isInitialLoading = false;
      });
      _logger.d('[MichangoPage] Loaded cached data for instant display');
    }

    // Step 2: Fetch fresh data from BACKEND API
    await _fetchDataFromBackend(showLoadingIfNoCachedData: !_hasCachedData);
  }

  /// Apply cached data
  void _applyCachedData(Map<String, dynamic> data) {
    if (data['michango'] != null) {
      _michango = List<dynamic>.from(data['michango']);
    }
  }

  /// Fetch fresh data from backend API and cache it
  /// IMPORTANT: All data comes from the backend, NOT from Firestore!
  Future<void> _fetchDataFromBackend({bool showLoadingIfNoCachedData = false, bool forceRefresh = false}) async {
    final kikobaId = DataStore.currentKikobaId;
    final visitorId = DataStore.currentUserId;

    if (kikobaId.isEmpty || visitorId.isEmpty) return;

    if (showLoadingIfNoCachedData && mounted) {
      setState(() => _isInitialLoading = true);
    }

    try {
      _logger.d('[MichangoPage] Fetching kikoba contributions from backend...');

      final response = await HttpService.getKikobaMichango();

      if (mounted) {
        if (response != null && response['success'] == true) {
          final michango = response['michango'] as List<dynamic>? ?? [];
          _logger.d('[MichangoPage] Fetched ${michango.length} contributions from backend');

          setState(() {
            _michango = michango;
            _isInitialLoading = false;
            _hasCachedData = true;
          });

          // Cache the data for next time
          await PageCacheService.saveMichangoData(visitorId, kikobaId, {
            'michango': michango,
            'fetchedAt': DateTime.now().toIso8601String(),
          });
        } else {
          _logger.e('[MichangoPage] Failed to fetch contributions');
          setState(() => _isInitialLoading = false);

          if (!_hasCachedData && response != null) {
            final errorMessage = response['message'] ?? 'Imeshindwa kupakua michango';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      }
    } catch (e) {
      _logger.e('[MichangoPage] Error fetching data from backend: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
        if (!_hasCachedData) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tatizo la mtandao. Tafadhali jaribu tena.')),
          );
        }
      }
    }
  }

  /// Set up Firestore listener for CHANGE NOTIFICATIONS ONLY
  /// IMPORTANT: Firestore is NOT used for data fetching!
  void _setupFirestoreListener() {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return;

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('FinancialUpdates')
        .doc(kikobaId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final notificationData = snapshot.data();
      if (notificationData == null) return;

      // Only read version info from Firestore (not actual data)
      final newVersion = notificationData['michango_version'] as int?;
      final updatedAt = notificationData['michango_updated_at'];
      int? effectiveVersion = newVersion;

      if (effectiveVersion == null && updatedAt != null) {
        if (updatedAt is Timestamp) {
          effectiveVersion = updatedAt.millisecondsSinceEpoch;
        }
      }

      // If version changed, fetch fresh data from BACKEND API
      if (effectiveVersion != null && effectiveVersion != _lastKnownVersion) {
        _logger.d('[MichangoPage] Firestore notification: version changed');
        _lastKnownVersion = effectiveVersion;
        await _fetchDataFromBackend(forceRefresh: true);
      }
    }, onError: (e) {
      _logger.e('[MichangoPage] Firestore listener error: $e');
    });
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hakuna mtandao. Tafadhali jaribu tena.')),
        );
      }
      return;
    }

    setState(() => _isRefreshing = true);
    await _fetchDataFromBackend(forceRefresh: true);
    setState(() => _isRefreshing = false);
  }

  // Get all kikoba contributions
  List<dynamic> get _allMichango => _michango;

  int get _totalMichango => _allMichango.length;
  int get _activeMichango => _allMichango.where((m) =>
    m['status']?.toString().toLowerCase() != 'completed' &&
    m['status']?.toString().toLowerCase() != 'closed'
  ).length;
  int get _completedMichango => _allMichango.where((m) =>
    m['status']?.toString().toLowerCase() == 'completed' ||
    m['status']?.toString().toLowerCase() == 'closed'
  ).length;

  double get _totalAmount {
    if (_allMichango.isEmpty) return 0.0;
    double total = 0.0;
    for (var mchango in _allMichango) {
      final targetAmount = mchango['targetAmount'] ?? mchango['target_amount'] ?? mchango['amount'];
      if (targetAmount != null) {
        if (targetAmount is num) {
          total += (targetAmount as num).toDouble();
        } else if (targetAmount is String) {
          total += double.tryParse(targetAmount) ?? 0.0;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _iconBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Michango',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: _showOmbaMchangoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: _isInitialLoading && !_hasCachedData
            ? _buildSkeletonLoading()
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildStatisticsSection(),
                      const SizedBox(height: 16),
                      _buildMichangoList(),
                      const SizedBox(height: 16),
                      _buildActionButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Build skeleton loading animation
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            color: _iconBg,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSkeletonCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSkeletonCard()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSkeletonCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSkeletonCard()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(4, (index) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 0.7),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(value * 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.3), shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.3), borderRadius: BorderRadius.circular(4))),
                              const SizedBox(height: 6),
                              Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(4))),
                            ],
                          ),
                        ),
                        Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.grey.withOpacity(value * 0.2), borderRadius: BorderRadius.circular(8))),
                      ],
                    ),
                  );
                },
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(value * 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(width: 80, height: 20, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 4),
              Container(width: 50, height: 12, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      color: _iconBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Jumla', '$_totalMichango', Icons.volunteer_activism)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Inaendelea', '$_activeMichango', Icons.pending_actions)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Malipo', '$_completedMichango', Icons.check_circle)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Kiasi', formatCurrency.format(_totalAmount), Icons.payments)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMichangoList() {
    if (_allMichango.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: _accentColor),
            const SizedBox(height: 16),
            Text('Hakuna michango', style: TextStyle(fontSize: 16, color: _secondaryText)),
            const SizedBox(height: 8),
            Text('Bonyeza \"+\" kuomba mchango', style: TextStyle(fontSize: 13, color: _accentColor)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Orodha ya Michango', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText)),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allMichango.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final mchango = _allMichango[index];
              return _buildMchangoCard(mchango);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMchangoCard(Map<String, dynamic> mchango) {
    final title = mchango['ainayaMchango'] ?? mchango['title'] ?? mchango['name'] ?? 'Mchango';
    final description = mchango['maelezo'] ?? mchango['description'] ?? '';
    final targetAmount = mchango['targetAmount'] ?? mchango['target_amount'] ?? mchango['amount'];
    final amountPerPerson = mchango['amountPerPerson'] ?? mchango['amount_per_person'];
    final tarehe = mchango['tarehe'] ?? mchango['date'] ?? mchango['deadline'];
    final status = mchango['status'] ?? 'active';
    final isCompleted = status.toString().toLowerCase() == 'completed' || status.toString().toLowerCase() == 'closed';

    String amountStr = 'Kiasi haijawekwa';
    if (targetAmount != null) {
      if (targetAmount is num) {
        amountStr = formatCurrency.format(targetAmount);
      } else if (targetAmount is String) {
        final parsed = double.tryParse(targetAmount);
        amountStr = parsed != null ? formatCurrency.format(parsed) : targetAmount;
      }
    }

    String perPersonStr = '';
    if (amountPerPerson != null) {
      if (amountPerPerson is num) {
        perPersonStr = '${formatCurrency.format(amountPerPerson)}/mtu';
      } else if (amountPerPerson is String) {
        final parsed = double.tryParse(amountPerPerson);
        perPersonStr = parsed != null ? '${formatCurrency.format(parsed)}/mtu' : '';
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MchangoDetailPage(mchango: mchango),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _iconBg.withOpacity(0.1),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.volunteer_activism,
                  color: _iconBg,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: _primaryText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description.toString(),
                        style: TextStyle(fontSize: 12, color: _secondaryText),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? _successColor.withOpacity(0.1) : _iconBg.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isCompleted ? _successColor : _iconBg),
                ),
                child: Text(
                  isCompleted ? 'Imekamilika' : 'Hai',
                  style: TextStyle(
                    color: isCompleted ? _successColor : _iconBg,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lengo:', style: TextStyle(fontSize: 11, color: _accentColor)),
                    const SizedBox(height: 2),
                    Text(amountStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryText)),
                    if (perPersonStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(perPersonStr, style: TextStyle(fontSize: 11, color: _secondaryText)),
                    ],
                  ],
                ),
              ),
              if (tarehe != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Tarehe:', style: TextStyle(fontSize: 11, color: _accentColor)),
                    const SizedBox(height: 2),
                    Text(tarehe.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryText)),
                  ],
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _iconBg,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _showOmbaMchangoDialog,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 20),
              SizedBox(width: 8),
              Text('Omba Mchango', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // Show bottom sheet to request a new contribution
  void _showOmbaMchangoDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetAmountController = TextEditingController();
    final amountPerPersonController = TextEditingController();
    final tareheController = TextEditingController();
    DateTime? selectedDate;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _iconBg,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Omba Mchango',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Jaza fomu hii kuomba mchango',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: _iconBg, size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Ombi lako litatumwa kwa wanachama wote wa kikundi',
                                style: TextStyle(fontSize: 13, color: _primaryText),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Fields
                      const Text(
                        'Taarifa za Mchango',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryText),
                      ),
                      const SizedBox(height: 16),

                      // Aina ya Mchango
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Aina ya Mchango *',
                          hintText: 'Mfano: Harusi, Msiba, Elimu',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category_rounded),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Maelezo
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Maelezo *',
                          hintText: 'Eleza sababu ya mchango kwa ufupi',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Icons.description_rounded),
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Target Amount
                      TextField(
                        controller: targetAmountController,
                        decoration: InputDecoration(
                          labelText: 'Kiasi cha Lengo (TZS) *',
                          hintText: '500,000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.savings_rounded),
                          prefixText: 'TZS ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CurrencyInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount Per Person
                      TextField(
                        controller: amountPerPersonController,
                        decoration: InputDecoration(
                          labelText: 'Kiasi kwa Kila Mtu (TZS) *',
                          hintText: '10,000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.person_rounded),
                          prefixText: 'TZS ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CurrencyInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: _iconBg,
                                    onPrimary: Colors.white,
                                    surface: _cardBg,
                                    onSurface: _primaryText,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setSheetState(() {
                              selectedDate = picked;
                              tareheController.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: TextField(
                            controller: tareheController,
                            decoration: InputDecoration(
                              labelText: 'Tarehe ya Mwisho *',
                              hintText: 'Chagua tarehe',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.calendar_today_rounded),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                              helperText: selectedDate != null
                                  ? 'Siku ${selectedDate!.difference(DateTime.now()).inDays} kutoka leo'
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: _accentColor),
                        ),
                        child: const Text('Ghairi', style: TextStyle(color: _primaryText)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                // Comprehensive validation
                                final validationError = _validateMchangoForm(
                                  titleController.text,
                                  descriptionController.text,
                                  targetAmountController.text,
                                  amountPerPersonController.text,
                                  selectedDate,
                                );

                                if (validationError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(validationError), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                // Set loading state
                                setSheetState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  final response = await HttpService.createMchango(
                                    ainayaMchango: titleController.text.trim(),
                                    maelezo: descriptionController.text.trim(),
                                    tarehe: tareheController.text,
                                    targetAmount: double.parse(targetAmountController.text.replaceAll(',', '')),
                                    amountPerPerson: double.parse(amountPerPersonController.text.replaceAll(',', '')),
                                  );

                                  // Parse response
                                  if (response != null && response['success'] == true) {
                                    // Close sheet on success
                                    if (mounted) {
                                      Navigator.pop(context);
                                      _showSuccessDialog('Mafanikio', 'Ombi la mchango limetumwa kikamilifu');
                                      _loadData(); // Refresh list
                                    }
                                  } else {
                                    // Keep sheet open on error, just reset loading state
                                    setSheetState(() {
                                      isSubmitting = false;
                                    });

                                    if (mounted) {
                                      final errorMessage = response?['message'] ?? 'Imeshindwa kutuma ombi. Tafadhali jaribu tena.';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  // Reset loading state on error
                                  setSheetState(() {
                                    isSubmitting = false;
                                  });

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Tatizo la muunganisho. Tafadhali jaribu tena.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _iconBg,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('Tuma Ombi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Validate mchango form
  String? _validateMchangoForm(
    String title,
    String description,
    String targetAmount,
    String amountPerPerson,
    DateTime? date,
  ) {
    // Check required fields
    if (title.trim().isEmpty) {
      return 'Tafadhali ingiza jina la mchango';
    }

    if (title.trim().length < 3) {
      return 'Jina la mchango liwe na herufi 3 au zaidi';
    }

    if (description.trim().isEmpty) {
      return 'Tafadhali ingiza maelezo ya mchango';
    }

    if (description.trim().length < 10) {
      return 'Maelezo yawe na herufi 10 au zaidi';
    }

    if (targetAmount.isEmpty) {
      return 'Tafadhali ingiza kiasi cha lengo';
    }

    if (amountPerPerson.isEmpty) {
      return 'Tafadhali ingiza kiasi kwa kila mtu';
    }

    if (date == null) {
      return 'Tafadhali chagua tarehe ya mwisho';
    }

    // Validate amounts
    final target = double.tryParse(targetAmount.replaceAll(',', ''));
    final perPerson = double.tryParse(amountPerPerson.replaceAll(',', ''));

    if (target == null || target <= 0) {
      return 'Kiasi cha lengo si sahihi';
    }

    if (perPerson == null || perPerson <= 0) {
      return 'Kiasi kwa mtu si sahihi';
    }

    if (target < perPerson) {
      return 'Kiasi cha lengo kiwe kikubwa au sawa na kiasi kwa mtu';
    }

    // Validate minimum amounts
    if (target < 1000) {
      return 'Kiasi cha lengo kiwe angalau TZS 1,000';
    }

    if (perPerson < 100) {
      return 'Kiasi kwa mtu kiwe angalau TZS 100';
    }

    // Validate date is in future
    if (date.isBefore(DateTime.now())) {
      return 'Tarehe ya mwisho iwe siku ya baadaye';
    }

    // Check if date is too far in future (more than 1 year)
    if (date.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      return 'Tarehe ya mwisho isiwe zaidi ya mwaka mmoja';
    }

    return null;
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: _errorColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: _iconBg),
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: _successColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: _iconBg),
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
  }

}

// Currency Input Formatter - formats numbers with thousand separators
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove any existing commas
    final value = newValue.text.replaceAll(',', '');

    // Parse the number
    final number = int.tryParse(value);
    if (number == null) {
      return oldValue;
    }

    // Format with thousand separators
    final formatter = NumberFormat('#,###', 'en_US');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
