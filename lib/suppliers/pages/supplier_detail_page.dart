// lib/suppliers/pages/supplier_detail_page.dart
// Full-screen supplier detail: shop/owner overview + tabs for
// Catalog (Products & Services), Purchase Orders (history), and New Order.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../screens/calls/outgoing_call_flow_screen.dart';
import '../../services/local_storage_service.dart';
import '../../services/message_service.dart';
import 'supplier_catalog_item_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);

class SupplierDetailPage extends StatefulWidget {
  final int businessId;
  final Supplier supplier;
  /// Whether the viewer owns the business. Non-owners see a read-only
  /// catalog (no add/edit/delete) and no "New Order" tab.
  final bool isOwner;
  /// Viewer's user id — used to open in-app chat and 1:1 calls with the
  /// supplier owner.
  final int currentUserId;

  const SupplierDetailPage({
    super.key,
    required this.businessId,
    required this.supplier,
    required this.currentUserId,
    this.isOwner = true,
  });

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final TabController _catalogSubTabCtrl;
  String? _token;

  // ── Catalog tab ────────────────────────────────────────────────────────
  List<SupplierCatalogItem> _catalog = [];
  bool _catalogLoading = true;
  final _catalogSearchCtrl = TextEditingController();
  String _catalogSearch = '';
  _CatalogSort _catalogSort = _CatalogSort.nameAsc;

  List<SupplierCatalogItem> get _products =>
      _catalog.where((i) => i.kind != SupplierCatalogItemKind.service).toList();
  List<SupplierCatalogItem> get _services =>
      _catalog.where((i) => i.kind == SupplierCatalogItemKind.service).toList();

  // ── Purchase orders tab ────────────────────────────────────────────────
  List<PurchaseOrder> _pos = [];
  bool _posLoading = true;

  // ── Recurring purchase orders (shown inside Orders tab) ────────────────
  List<RecurringPurchaseOrder> _recurring = [];
  bool _recurringLoading = true;

  // ── New order tab ──────────────────────────────────────────────────────
  final Map<String, _OrderLine> _orderLines = {}; // key: "cat_<id>" or "adhoc_<n>"
  int _adhocCounter = 0;
  DateTime? _expectedDate;
  final _notesCtrl = TextEditingController();
  bool _submittingOrder = false;

  // ── Buyer context (individual vs business) ─────────────────────────────
  /// 'individual' or 'business'. Defaults to business since the viewer arrived
  /// from a business profile.
  String _buyerType = 'business';
  /// When buyer_type is 'business', which of the viewer's owned businesses is
  /// placing the order. Pre-set to the business the viewer navigated from.
  int? _selectedBuyerBusinessId;
  List<Business> _myBusinesses = [];
  bool _loadingMyBusinesses = true;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: widget.isOwner ? 3 : 2,
      vsync: this,
    );
    _catalogSubTabCtrl = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _catalogSubTabCtrl.dispose();
    _notesCtrl.dispose();
    _catalogSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _selectedBuyerBusinessId = widget.businessId;
    if (_token == null || widget.supplier.id == null) {
      if (mounted) {
        setState(() {
          _catalogLoading = false;
          _posLoading = false;
          _loadingMyBusinesses = false;
        });
      }
      return;
    }
    await Future.wait(
        [_loadCatalog(), _loadPOs(), _loadRecurring(), _loadMyBusinesses()]);
  }

  Future<void> _loadMyBusinesses() async {
    if (_token == null) return;
    final res =
        await BusinessService.getMyBusinesses(_token!, widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _loadingMyBusinesses = false;
      if (res.success) {
        _myBusinesses = res.data;
        // If the currently-selected buyer business isn't in the user's owned
        // list (edge case), fall back to the first owned business.
        if (_selectedBuyerBusinessId != null &&
            !_myBusinesses.any((b) => b.id == _selectedBuyerBusinessId) &&
            _myBusinesses.isNotEmpty) {
          _selectedBuyerBusinessId = _myBusinesses.first.id;
        }
      }
    });
  }

  Future<void> _loadRecurring() async {
    if (_token == null) return;
    final res = await BusinessService.getRecurringPurchaseOrders(
        _token!, widget.businessId);
    if (!mounted) return;
    setState(() {
      _recurringLoading = false;
      if (res.success) {
        _recurring = res.data
            .where((r) => r.supplierId == widget.supplier.id)
            .toList();
      }
    });
  }

  Future<void> _loadCatalog() async {
    if (_token == null || widget.supplier.id == null) return;
    final res =
        await BusinessService.getSupplierCatalog(_token!, widget.supplier.id!);
    if (!mounted) return;
    setState(() {
      _catalogLoading = false;
      if (res.success) _catalog = res.data;
    });
  }

  Future<void> _loadPOs() async {
    if (_token == null) return;
    final res =
        await BusinessService.getPurchaseOrders(_token!, widget.businessId);
    if (!mounted) return;
    setState(() {
      _posLoading = false;
      if (res.success) {
        _pos = res.data
            .where((po) => po.supplierId == widget.supplier.id)
            .toList();
      }
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────

  /// Opens (or creates) a 1:1 chat with the supplier owner.
  Future<void> _openChat() async {
    final ownerId = widget.supplier.ownerUserId;
    if (ownerId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final result =
        await MessageService().getPrivateConversation(widget.currentUserId, ownerId);
    if (!mounted) return;
    if (result.success && result.conversation != null) {
      Navigator.pushNamed(
        context,
        '/chat/${result.conversation!.id}',
        arguments: <String, dynamic>{'conversation': result.conversation},
      );
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindikana kufungua gumzo'
              : 'Could not open chat')));
    }
  }

  /// Starts a 1:1 voice or video call with the supplier owner.
  Future<void> _startCall(String type) async {
    final ownerId = widget.supplier.ownerUserId;
    if (ownerId == null) return;
    final s = widget.supplier;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OutgoingCallFlowScreen(
          currentUserId: widget.currentUserId,
          authToken: _token,
          calleeId: ownerId,
          calleeName: s.ownerName?.isNotEmpty == true
              ? s.ownerName!
              : (s.ownerUsername?.isNotEmpty == true ? s.ownerUsername! : s.name),
          calleeAvatarUrl: _resolveOwnerPhoto(s.ownerPhotoPath),
          type: type,
        ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    final hasOwnerStrip = s.isPlatformLinked && _hasOwnerData(s);
    final statusBar = MediaQuery.paddingOf(context).top;
    final contentHeight =
        _shopTopBarHeight(s) + (hasOwnerStrip ? _kOwnerStripHeight : 0);
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(statusBar + contentHeight),
        child: Material(
          color: _kCardBg,
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.only(top: statusBar),
            child: _buildShopTopBar(s, hasOwnerStrip: hasOwnerStrip),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: _kCardBg,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _kPrimary,
                unselectedLabelColor: _kSecondary,
                indicatorColor: _kPrimary,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: [
                  Tab(text: _isSwahili ? 'Bidhaa' : 'Catalog'),
                  Tab(text: _isSwahili ? 'Maagizo' : 'Orders'),
                  if (widget.isOwner)
                    Tab(text: _isSwahili ? 'Agiza' : 'New Order'),
                ],
              ),
            ),
            Container(height: 1, color: _kBorder),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildCatalogTab(),
                  _buildOrdersTab(),
                  if (widget.isOwner) _buildNewOrderTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _shopTopBarHeight(Supplier s) {
    // Toolbar (56) + shop info (avatar 44 + padding) + action row (~40) + paddings
    double h = kToolbarHeight + 108;
    if (s.tinNumber != null && s.tinNumber!.isNotEmpty) h += 14;
    if (s.address != null && s.address!.isNotEmpty) h += 16;
    return h;
  }

  static const double _kOwnerStripHeight = 52;

  // ── Shop top bar (replaces the old overview card) ──────────────────────

  Widget _buildShopTopBar(Supplier s, {required bool hasOwnerStrip}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toolbar row: back + shop name + (optional) menu
        SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: _isSwahili ? 'Rudi' : 'Back',
              ),
              Expanded(
                child: Text(
                  s.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (s.isPlatformLinked && s.platformBusinessId != null)
                IconButton(
                  icon: const Icon(Icons.storefront_rounded,
                      color: _kPrimary, size: 20),
                  tooltip: _isSwahili ? 'Fungua duka' : 'Open shop profile',
                  onPressed: () => Navigator.pushNamed(
                      context, '/profile/${s.platformBusinessId}'),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
        // Shop info row (logo, handle, TIN, address)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(
                imageUrl: s.logoUrl,
                initial: s.name.isNotEmpty ? s.name[0] : '?',
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s.handle != null && s.handle!.isNotEmpty)
                      Text('@${s.handle}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    if (s.tinNumber != null && s.tinNumber!.isNotEmpty)
                      Text('TIN: ${s.tinNumber}',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    if (s.address != null && s.address!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: _kSecondary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(s.address!,
                                style: const TextStyle(
                                    fontSize: 11, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Action row — in-app chat, voice call, video call with the supplier owner.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: _actionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: _isSwahili ? 'Gumzo' : 'Chat',
                  onTap: _openChat,
                  enabled: s.ownerUserId != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionBtn(
                  icon: Icons.call_rounded,
                  label: _isSwahili ? 'Piga' : 'Call',
                  onTap: () => _startCall('voice'),
                  enabled: s.ownerUserId != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionBtn(
                  icon: Icons.videocam_rounded,
                  label: _isSwahili ? 'Video' : 'Video',
                  onTap: () => _startCall('video'),
                  enabled: s.ownerUserId != null,
                ),
              ),
            ],
          ),
        ),
        // Owner strip (platform-linked only)
        if (hasOwnerStrip)
          Container(
            height: _kOwnerStripHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: _kPrimary.withValues(alpha: 0.04),
            child: Row(
              children: [
                _avatar(
                  imageUrl: _resolveOwnerPhoto(s.ownerPhotoPath),
                  initial: (s.ownerName ?? s.ownerUsername ?? '?')
                          .trim()
                          .isNotEmpty
                      ? (s.ownerName ?? s.ownerUsername!)[0]
                      : '?',
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(_isSwahili ? 'MMILIKI' : 'OWNER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.grey.shade600,
                              )),
                        ],
                      ),
                      Text(
                        s.ownerName != null && s.ownerName!.isNotEmpty
                            ? (s.ownerUsername != null &&
                                    s.ownerUsername!.isNotEmpty
                                ? '${s.ownerName}  @${s.ownerUsername}'
                                : s.ownerName!)
                            : (s.ownerUsername != null &&
                                    s.ownerUsername!.isNotEmpty
                                ? '@${s.ownerUsername}'
                                : '—'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (s.ownerUserId != null)
                  IconButton(
                    icon: const Icon(Icons.call_rounded,
                        size: 18, color: _kPrimary),
                    onPressed: () => _startCall('voice'),
                    tooltip: _isSwahili ? 'Piga mmiliki' : 'Call owner',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  bool _hasOwnerData(Supplier s) =>
      (s.ownerName != null && s.ownerName!.isNotEmpty) ||
      (s.ownerUsername != null && s.ownerUsername!.isNotEmpty) ||
      (s.ownerPhone != null && s.ownerPhone!.isNotEmpty) ||
      (s.ownerEmail != null && s.ownerEmail!.isNotEmpty);

  String? _resolveOwnerPhoto(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return ApiConfig.sanitizeUrl(path);
    // Build against storage base.
    final base = ApiConfig.storageUrl;
    return ApiConfig.sanitizeUrl(
        '${base.endsWith('/') ? base : '$base/'}${path.startsWith('/') ? path.substring(1) : path}');
  }

  Widget _avatar({String? imageUrl, required String initial, double size = 40}) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _kPrimary.withValues(alpha: 0.08),
      backgroundImage:
          (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? Text(initial.toUpperCase(),
              style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary))
          : null,
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: enabled ? _kPrimary : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: enabled ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: enabled ? Colors.white : Colors.grey.shade500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Catalog tab ────────────────────────────────────────────────────────

  Widget _buildCatalogTab() {
    if (widget.supplier.id == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _isSwahili
                ? 'Hifadhi msambazaji kwanza kabla ya kuongeza bidhaa.'
                : 'Save this supplier before adding items to the catalog.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kSecondary),
          ),
        ),
      );
    }

    if (_catalogLoading) {
      return const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      children: [
        // Products / Services sub-tabs
        Container(
          color: _kCardBg,
          child: TabBar(
            controller: _catalogSubTabCtrl,
            labelColor: _kPrimary,
            unselectedLabelColor: _kSecondary,
            indicatorColor: _kPrimary,
            indicatorWeight: 2,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(
                height: 42,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(
                        '${_isSwahili ? "Bidhaa" : "Products"} (${_products.length})'),
                  ],
                ),
              ),
              Tab(
                height: 42,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.handyman_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(
                        '${_isSwahili ? "Huduma" : "Services"} (${_services.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: _kBorder),
        // Search + sort (shared across sub-tabs)
        Container(
          color: _kCardBg,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _catalogSearchCtrl,
                    onChanged: (v) => setState(() => _catalogSearch = v),
                    decoration: InputDecoration(
                      hintText: _isSwahili ? 'Tafuta' : 'Search',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: _kSecondary),
                      suffixIcon: _catalogSearch.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: _kSecondary),
                              onPressed: () {
                                _catalogSearchCtrl.clear();
                                setState(() => _catalogSearch = '');
                              },
                            ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<_CatalogSort>(
                tooltip: _isSwahili ? 'Panga' : 'Sort',
                icon: const Icon(Icons.sort_rounded, color: _kPrimary),
                onSelected: (v) => setState(() => _catalogSort = v),
                itemBuilder: (_) => _CatalogSort.values
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(
                                _catalogSort == s
                                    ? Icons.check_rounded
                                    : Icons.circle_outlined,
                                size: 14,
                                color: _catalogSort == s
                                    ? _kPrimary
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              Text(_sortLabel(s),
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        Container(height: 1, color: _kBorder),
        Expanded(
          child: TabBarView(
            controller: _catalogSubTabCtrl,
            children: [
              _buildCatalogList(_products, isService: false),
              _buildCatalogList(_services, isService: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogList(List<SupplierCatalogItem> source,
      {required bool isService}) {
    final filtered = _applyCatalogFilter(source);

    if (source.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCatalog,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 40),
            Icon(
                isService
                    ? Icons.handyman_outlined
                    : Icons.inventory_2_outlined,
                size: 48,
                color: _kSecondary),
            const SizedBox(height: 12),
            Center(
              child: Text(
                isService
                    ? (_isSwahili ? 'Hakuna huduma bado.' : 'No services yet.')
                    : (_isSwahili ? 'Hakuna bidhaa bado.' : 'No products yet.'),
                style: const TextStyle(fontSize: 14, color: _kSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCatalog,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                _isSwahili
                    ? 'Hakuna inayolingana.'
                    : 'No items match your search.',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCatalog,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.62,
        ),
        itemCount: filtered.length,
        itemBuilder: (_, i) =>
            _buildCatalogCard(filtered[i], isService: isService),
      ),
    );
  }

  Widget _buildCatalogCard(SupplierCatalogItem item,
      {required bool isService}) {
    final fallbackIcon = isService
        ? Icons.handyman_rounded
        : Icons.inventory_2_rounded;
    final typeBadge = isService
        ? (_isSwahili ? 'Huduma' : 'Service')
        : (_isSwahili ? 'Bidhaa' : 'Product');

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCatalogItemDetail(item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image area with type badge overlay.
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: _kPrimary.withValues(alpha: 0.05),
                      child: (item.imageUrl != null &&
                              item.imageUrl!.isNotEmpty)
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(fallbackIcon,
                                    size: 38, color: _kSecondary),
                              ),
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _kPrimary),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(fallbackIcon,
                                  size: 38, color: _kSecondary),
                            ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeBadge,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    if (widget.isOwner)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Material(
                          color: _kPrimary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _openCatalogItemDetail(item),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.add_shopping_cart_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Title + detail + price block.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.detail != null &&
                          item.detail!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.detail!.trim(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _kSecondary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      _buildCardMetaRow(item, isService: isService),
                      const SizedBox(height: 4),
                      _buildCardPriceRow(item),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardMetaRow(SupplierCatalogItem item,
      {required bool isService}) {
    final chips = <Widget>[];

    if (isService) {
      if (item.availability != null &&
          item.availability!.isNotEmpty &&
          item.availability != 'available') {
        chips.add(_metaChip(
          _humanize(item.availability!),
          color: item.availability == 'unavailable'
              ? Colors.red.shade700
              : _kSecondary,
        ));
      }
      if (item.durationMinutes != null && item.durationMinutes! > 0) {
        chips.add(_metaChip(_fmtDuration(item.durationMinutes!)));
      }
    } else {
      if (item.stockQuantity != null) {
        if (item.stockQuantity! <= 0) {
          chips.add(_metaChip(
            _isSwahili ? 'Imeisha' : 'Out of stock',
            color: Colors.red.shade700,
          ));
        } else if (item.stockQuantity! <= 5) {
          chips.add(_metaChip(
            _isSwahili
                ? 'Baki ${item.stockQuantity}'
                : '${item.stockQuantity} left',
            color: Colors.orange.shade800,
          ));
        }
      }
      if (item.condition != null &&
          item.condition!.isNotEmpty &&
          item.condition != 'brand_new') {
        chips.add(_metaChip(_humanize(item.condition!)));
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _metaChip(String text, {Color color = _kSecondary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCardPriceRow(SupplierCatalogItem item) {
    final currency = (item.currency ?? 'TZS').toUpperCase();
    if (item.unitPrice <= 0) {
      return Text(
        _isSwahili ? 'Bei haijawekwa' : 'Price not set',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _kSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final hasCompare = item.compareAtPrice != null &&
        item.compareAtPrice! > item.unitPrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            '$currency ${_fmtMoney(item.unitPrice)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasCompare) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _fmtMoney(item.compareAtPrice!),
              style: const TextStyle(
                fontSize: 10,
                color: _kSecondary,
                decoration: TextDecoration.lineThrough,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  String _humanize(String raw) {
    if (raw.isEmpty) return raw;
    final words = raw.replaceAll('_', ' ').split(' ');
    return words
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _fmtDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  List<SupplierCatalogItem> _applyCatalogFilter(
      List<SupplierCatalogItem> src) {
    final q = _catalogSearch.trim().toLowerCase();
    final list = q.isEmpty
        ? List<SupplierCatalogItem>.from(src)
        : src
            .where((i) => i.name.toLowerCase().contains(q))
            .toList();
    switch (_catalogSort) {
      case _CatalogSort.nameAsc:
        list.sort((a, b) => a.name
            .toLowerCase()
            .compareTo(b.name.toLowerCase()));
        break;
      case _CatalogSort.nameDesc:
        list.sort((a, b) => b.name
            .toLowerCase()
            .compareTo(a.name.toLowerCase()));
        break;
      case _CatalogSort.priceLowHigh:
        list.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        break;
      case _CatalogSort.priceHighLow:
        list.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
        break;
      case _CatalogSort.recent:
        // Keep server order (assume server returns newest first or by id desc).
        break;
    }
    return list;
  }

  String _sortLabel(_CatalogSort s) {
    final sw = _isSwahili;
    switch (s) {
      case _CatalogSort.nameAsc:
        return sw ? 'Jina (A→Z)' : 'Name (A→Z)';
      case _CatalogSort.nameDesc:
        return sw ? 'Jina (Z→A)' : 'Name (Z→A)';
      case _CatalogSort.priceLowHigh:
        return sw ? 'Bei (ndogo→kubwa)' : 'Price (low → high)';
      case _CatalogSort.priceHighLow:
        return sw ? 'Bei (kubwa→ndogo)' : 'Price (high → low)';
      case _CatalogSort.recent:
        return sw ? 'Mpya' : 'Most recent';
    }
  }

  // Quick-order sheet: tap a catalog item → confirm qty/price → create draft PO
  Future<void> _openCatalogItemDetail(SupplierCatalogItem item) async {
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SupplierCatalogItemPage(
          item: item,
          supplier: widget.supplier,
          businessId: widget.businessId,
          currentUserId: widget.currentUserId,
          isOwner: widget.isOwner,
        ),
      ),
    );
    if (placed == true && mounted) {
      await _loadPOs();
      if (mounted) _tabCtrl.animateTo(1);
    }
  }

  // ── Orders tab ─────────────────────────────────────────────────────────

  Widget _buildOrdersTab() {
    if (_posLoading || _recurringLoading) {
      return const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    Future<void> refresh() =>
        Future.wait([_loadPOs(), _loadRecurring()]).then((_) {});

    if (_pos.isEmpty && _recurring.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _isSwahili
                    ? 'Hakuna maagizo yaliyotengenezwa kwa msambazaji huyu.'
                    : 'No purchase orders yet for this supplier.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _kSecondary),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isOwner)
              Center(
                child: FilledButton.icon(
                  onPressed: () => _tabCtrl.animateTo(2),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label:
                      Text(_isSwahili ? 'Tengeneza Agizo' : 'Create Order'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final activeRecurring =
        _recurring.where((r) => r.isActive).toList(growable: false);

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (activeRecurring.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
              child: Row(
                children: [
                  const Icon(Icons.event_repeat_rounded,
                      size: 14, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _isSwahili ? 'Ratiba za maagizo' : 'Scheduled orders',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: _kSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${activeRecurring.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kSecondary,
                    ),
                  ),
                ],
              ),
            ),
            for (final rec in activeRecurring)
              _RecurringPOCard(
                rec: rec,
                isSwahili: _isSwahili,
                canManage: widget.isOwner,
                onEdit: widget.isOwner
                    ? () => _openRecurringForm(existing: rec)
                    : null,
                onCancel: widget.isOwner
                    ? () => _cancelRecurring(rec)
                    : null,
                onRunNow: widget.isOwner
                    ? () => _runRecurringNow(rec)
                    : null,
              ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
              child: Text(
                _isSwahili ? 'Historia ya maagizo' : 'Order history',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: _kSecondary,
                ),
              ),
            ),
          ],
          if (_pos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _isSwahili
                      ? 'Bado hakuna agizo lililotumwa.'
                      : 'No orders placed yet.',
                  style:
                      const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ),
            )
          else
            for (int i = 0; i < _pos.length; i++)
              _POCard(
                po: _pos[i],
                isSwahili: _isSwahili,
                canReorder: widget.isOwner,
                onReorder:
                    widget.isOwner ? () => _reorderPO(_pos[i]) : null,
                onRecurring: widget.isOwner
                    ? () => _openRecurringForm(
                          seedLines: _pos[i]
                              .items
                              .map((it) => _OrderLine(
                                    description: it.description,
                                    quantity: it.quantity,
                                    unitPrice: it.unitPrice,
                                  ))
                              .toList(),
                        )
                    : null,
              ),
        ],
      ),
    );
  }

  void _reorderPO(PurchaseOrder po) {
    if (po.items.isEmpty) return;
    setState(() {
      _orderLines.clear();
      for (final item in po.items) {
        final key = 'reorder_${_adhocCounter++}';
        _orderLines[key] = _OrderLine(
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
        );
      }
      _expectedDate = null;
      _notesCtrl.clear();
    });
    _tabCtrl.animateTo(2);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isSwahili
          ? 'Bidhaa zimeongezwa. Hakiki kisha tengeneza agizo.'
          : 'Items copied. Review and create the order.'),
    ));
  }

  void _openRecurringForm({
    List<_OrderLine>? seedLines,
    RecurringPurchaseOrder? existing,
  }) {
    final lines = seedLines ??
        existing?.items
            .map((i) => _OrderLine(
                  description: i.description,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                ))
            .toList() ??
        <_OrderLine>[];
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Ongeza bidhaa kwanza.'
            : 'Add items first.'),
      ));
      return;
    }

    RecurringFrequency frequency =
        existing?.frequency ?? RecurringFrequency.monthly;
    DateTime nextRun = existing?.nextRunDate ??
        DateTime.now().add(const Duration(days: 7));
    DateTime? endDate = existing?.endDate;
    int? maxOrders = existing?.maxOrders;
    int? deliveryOffsetDays = existing?.deliveryOffsetDays ?? 3;
    bool autoSend = existing?.autoSend ?? false;
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final maxCtrl = TextEditingController(
        text: existing?.maxOrders?.toString() ?? '');
    final offsetCtrl =
        TextEditingController(text: deliveryOffsetDays.toString());
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        Future<void> save() async {
          if (_token == null) return;
          setSt(() => saving = true);
          final items = lines
              .where((l) => l.description.trim().isNotEmpty && l.quantity > 0)
              .map((l) => {
                    'description': l.description.trim(),
                    'quantity': l.quantity,
                    'unit_price': l.unitPrice,
                    'total_price': l.total,
                  })
              .toList();
          final body = <String, dynamic>{
            'user_business_id': widget.businessId,
            'supplier_id': widget.supplier.id,
            'supplier_name': widget.supplier.name,
            'items': items,
            'frequency': frequency.name,
            'next_run_date':
                '${nextRun.year.toString().padLeft(4, '0')}-${nextRun.month.toString().padLeft(2, '0')}-${nextRun.day.toString().padLeft(2, '0')}',
            if (endDate != null)
              'end_date':
                  '${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}',
            if (maxOrders != null) 'max_orders': maxOrders,
            if (deliveryOffsetDays != null)
              'delivery_offset_days': deliveryOffsetDays,
            'auto_send': autoSend,
            if (notesCtrl.text.trim().isNotEmpty)
              'notes': notesCtrl.text.trim(),
          };
          final messenger = ScaffoldMessenger.of(context);
          final res = existing != null && existing.id != null
              ? await BusinessService.updateRecurringPurchaseOrder(
                  _token!, existing.id!, body)
              : await BusinessService.createRecurringPurchaseOrder(
                  _token!, widget.businessId, body);
          if (!ctx.mounted) return;
          if (!res.success) {
            setSt(() => saving = false);
            messenger.showSnackBar(SnackBar(
                content: Text(res.message ??
                    (_isSwahili ? 'Imeshindikana' : 'Failed')),
                backgroundColor: Colors.red));
            return;
          }
          Navigator.of(ctx).pop();
          await _loadRecurring();
          messenger.showSnackBar(SnackBar(
              content: Text(existing != null
                  ? (_isSwahili ? 'Imesasishwa' : 'Updated')
                  : (_isSwahili
                      ? 'Agizo la kila mara limeandaliwa'
                      : 'Recurring order scheduled'))));
        }

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    existing != null
                        ? (_isSwahili
                            ? 'Hariri Agizo la Kila Mara'
                            : 'Edit Recurring Order')
                        : (_isSwahili
                            ? 'Agizo la Kila Mara'
                            : 'Set up Recurring Order'),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 6),
                Text(
                    '${lines.length} ${_isSwahili ? "bidhaa" : "items"}  •  ${widget.supplier.name}',
                    style: const TextStyle(
                        fontSize: 12, color: _kSecondary)),
                const SizedBox(height: 16),
                // Frequency
                DropdownButtonFormField<RecurringFrequency>(
                  initialValue: frequency,
                  onChanged: (v) =>
                      setSt(() => frequency = v ?? RecurringFrequency.monthly),
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Muda' : 'Frequency',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: RecurringFrequency.values
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(recurringFrequencyLabel(f,
                                swahili: _isSwahili)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                // Next run date
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: nextRun,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) setSt(() => nextRun = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      border: Border.all(color: _kBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Text(
                          _isSwahili ? 'Tarehe ya kwanza' : 'First run',
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                        ),
                        const Spacer(),
                        Text(
                            DateFormat('dd MMM yyyy').format(nextRun),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: offsetCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => deliveryOffsetDays =
                            int.tryParse(v.trim()),
                        decoration: InputDecoration(
                          labelText: _isSwahili
                              ? 'Siku za kupokea'
                              : 'Delivery offset (days)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            maxOrders = int.tryParse(v.trim()),
                        decoration: InputDecoration(
                          labelText: _isSwahili
                              ? 'Idadi ya juu (hiari)'
                              : 'Max orders (optional)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // End date (optional)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ??
                          nextRun.add(const Duration(days: 180)),
                      firstDate: nextRun,
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) setSt(() => endDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      border: Border.all(color: _kBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_busy_rounded,
                            size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Text(
                          _isSwahili ? 'Tarehe ya mwisho' : 'End date',
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                        ),
                        const Spacer(),
                        Text(
                            endDate != null
                                ? DateFormat('dd MMM yyyy').format(endDate!)
                                : (_isSwahili ? 'Hakuna' : 'None'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: endDate != null
                                  ? _kPrimary
                                  : Colors.grey.shade500,
                            )),
                        if (endDate != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: _kSecondary),
                            onPressed: () => setSt(() => endDate = null),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  value: autoSend,
                  onChanged: (v) => setSt(() => autoSend = v),
                  activeThumbColor: _kPrimary,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      _isSwahili
                          ? 'Tuma kiotomatiki (sent)'
                          : 'Auto-send generated orders',
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                      _isSwahili
                          ? 'Hali itakuwa "sent" badala ya "draft".'
                          : 'POs will be marked "sent" instead of "draft".',
                      style: const TextStyle(
                          fontSize: 11, color: _kSecondary)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText:
                        _isSwahili ? 'Maelezo (hiari)' : 'Notes (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.event_repeat_rounded, size: 18),
                    label: Text(
                      existing != null
                          ? (_isSwahili ? 'Sasisha' : 'Update')
                          : (_isSwahili ? 'Hifadhi Ratiba' : 'Save Schedule'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        notesCtrl.dispose();
        maxCtrl.dispose();
        offsetCtrl.dispose();
      });
    });
  }

  Future<void> _cancelRecurring(RecurringPurchaseOrder rec) async {
    if (_token == null || rec.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(_isSwahili
            ? 'Sitisha Ratiba?'
            : 'Stop Recurring Order?'),
        content: Text(_isSwahili
            ? 'Hakuna maagizo mapya yatatengenezwa.'
            : 'No new orders will be generated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: Text(_isSwahili ? 'Ghairi' : 'Cancel')),
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(_isSwahili ? 'Sitisha' : 'Stop')),
        ],
      ),
    );
    if (confirmed != true) return;
    final res =
        await BusinessService.cancelRecurringPurchaseOrder(_token!, rec.id!);
    if (!mounted) return;
    if (res.success) {
      await _loadRecurring();
      messenger.showSnackBar(SnackBar(
          content: Text(_isSwahili ? 'Imesitishwa' : 'Stopped')));
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(res.message ??
              (_isSwahili ? 'Imeshindikana' : 'Failed')),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _runRecurringNow(RecurringPurchaseOrder rec) async {
    if (_token == null || rec.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final res =
        await BusinessService.runRecurringPurchaseOrderNow(_token!, rec.id!);
    if (!mounted) return;
    if (res.success) {
      await Future.wait([_loadRecurring(), _loadPOs()]);
      messenger.showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Agizo jipya limetengenezwa'
              : 'Order generated')));
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(res.message ??
              (_isSwahili ? 'Imeshindikana' : 'Failed')),
          backgroundColor: Colors.red));
    }
  }

  // ── New Order tab ──────────────────────────────────────────────────────

  Widget _buildBuyerContextSection() {
    final ownedCount = _myBusinesses.length;
    final selectedBiz = ownedCount > 0
        ? _myBusinesses.firstWhere(
            (b) => b.id == _selectedBuyerBusinessId,
            orElse: () => _myBusinesses.first,
          )
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSwahili ? 'Unaagiza kama' : 'Ordering as',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kPrimary),
          ),
          const SizedBox(height: 8),
          // Segmented individual / business
          Row(
            children: [
              Expanded(
                child: _buyerTypePill(
                  value: 'individual',
                  icon: Icons.person_outline_rounded,
                  label: _isSwahili ? 'Mtu binafsi' : 'Individual',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buyerTypePill(
                  value: 'business',
                  icon: Icons.storefront_outlined,
                  label: _isSwahili ? 'Biashara' : 'Business',
                ),
              ),
            ],
          ),
          // Business picker — shown only when 'business' is chosen AND user
          // owns 2+ businesses. With one business it's implicit.
          if (_buyerType == 'business' && ownedCount >= 2) ...[
            const SizedBox(height: 10),
            Text(
              _isSwahili ? 'Biashara inayoagiza' : 'Placing business',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _selectedBuyerBusinessId,
              isDense: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
              ),
              items: _myBusinesses
                  .map((b) => DropdownMenuItem<int>(
                        value: b.id,
                        child: Text(b.name,
                            style: const TextStyle(
                                fontSize: 13, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBuyerBusinessId = v),
            ),
          ] else if (_buyerType == 'business' && selectedBiz != null) ...[
            const SizedBox(height: 6),
            Text(
              selectedBiz.name,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else if (_buyerType == 'business' && _loadingMyBusinesses) ...[
            const SizedBox(height: 6),
            const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ],
      ),
    );
  }

  Widget _buyerTypePill({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final selected = _buyerType == value;
    return Material(
      color: selected ? _kPrimary : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _buyerType = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? Colors.white : _kSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _kSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewOrderTab() {
    if (widget.supplier.id == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _isSwahili
                ? 'Hifadhi msambazaji kwanza.'
                : 'Save the supplier first.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kSecondary),
          ),
        ),
      );
    }

    final selectedLines = _orderLines.values.toList();
    final subtotal = selectedLines.fold<double>(
        0, (sum, line) => sum + line.total);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              // Buyer context (individual vs business)
              _buildBuyerContextSection(),
              const SizedBox(height: 14),
              // Catalog pick list
              Text(
                _isSwahili ? 'Chagua bidhaa' : 'Pick items',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
              const SizedBox(height: 8),
              if (_catalogLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else if (_catalog.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    border: Border.all(color: _kBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _isSwahili
                        ? 'Hakuna bidhaa kwenye orodha. Ongeza chini au kwenye kichupo cha Bidhaa.'
                        : 'No catalog items. Add below or from the Catalog tab.',
                    style:
                        const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                )
              else
                ..._catalog.map((item) {
                  final key = 'cat_${item.id}';
                  final line = _orderLines[key];
                  final selected = line != null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      border: Border.all(
                          color: selected ? _kPrimary : _kBorder,
                          width: selected ? 1.2 : 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: selected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _orderLines[key] = _OrderLine(
                                      description: item.name,
                                      quantity:
                                          item.defaultQuantity.toDouble(),
                                      unitPrice: item.unitPrice,
                                    );
                                  } else {
                                    _orderLines.remove(key);
                                  }
                                });
                              },
                              activeColor: _kPrimary,
                              visualDensity: VisualDensity.compact,
                            ),
                            Expanded(
                              child: Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary)),
                            ),
                          ],
                        ),
                        if (selected) ...[
                          const SizedBox(height: 4),
                          _OrderLineEditor(
                            line: line,
                            onChanged: (updated) {
                              setState(() => _orderLines[key] = updated);
                            },
                            isSwahili: _isSwahili,
                          ),
                        ],
                      ],
                    ),
                  );
                }),

              // Ad-hoc lines
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _isSwahili ? 'Bidhaa nyingine' : 'Custom items',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        final key = 'adhoc_${_adhocCounter++}';
                        _orderLines[key] = _OrderLine(
                          description: '',
                          quantity: 1,
                          unitPrice: 0,
                        );
                      });
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(_isSwahili ? 'Ongeza' : 'Add'),
                    style: TextButton.styleFrom(foregroundColor: _kPrimary),
                  ),
                ],
              ),
              ..._orderLines.entries
                  .where((e) => e.key.startsWith('adhoc_'))
                  .map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          border: Border.all(color: _kBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AdhocLineEditor(
                                line: e.value,
                                onChanged: (updated) {
                                  setState(
                                      () => _orderLines[e.key] = updated);
                                },
                                isSwahili: _isSwahili,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: _kSecondary),
                              onPressed: () {
                                setState(() => _orderLines.remove(e.key));
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      )),

              // Expected delivery + notes
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expectedDate ?? now.add(const Duration(days: 3)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _expectedDate = picked);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    border: Border.all(color: _kBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 18, color: _kSecondary),
                      const SizedBox(width: 10),
                      Text(
                        _expectedDate != null
                            ? DateFormat('dd MMM yyyy').format(_expectedDate!)
                            : (_isSwahili
                                ? 'Tarehe ya kupokea'
                                : 'Expected delivery'),
                        style: TextStyle(
                          fontSize: 13,
                          color: _expectedDate != null
                              ? _kPrimary
                              : _kSecondary,
                          fontWeight: _expectedDate != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      _isSwahili ? 'Maelezo (hiari)' : 'Notes (optional)',
                  filled: true,
                  fillColor: _kCardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Totals footer + submit
        Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            border: Border(top: BorderSide(color: _kBorder)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSwahili
                          ? 'Jumla (kabla ya VAT)'
                          : 'Subtotal (before VAT)',
                      style: const TextStyle(
                          fontSize: 12, color: _kSecondary),
                    ),
                    Text('TZS ${_fmtMoney(subtotal)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: (_orderLines.isEmpty || _submittingOrder)
                        ? null
                        : _submitOrder,
                    icon: _submittingOrder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSwahili
                        ? 'Tengeneza Agizo'
                        : 'Create Purchase Order'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitOrder() async {
    if (_token == null) return;
    final lines = _orderLines.values
        .where((l) => l.description.trim().isNotEmpty && l.quantity > 0)
        .toList();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Ongeza angalau bidhaa moja'
              : 'Add at least one item')));
      return;
    }

    setState(() => _submittingOrder = true);

    final items = lines
        .map((l) => {
              'description': l.description.trim(),
              'quantity': l.quantity,
              'unit_price': l.unitPrice,
              'total_price': l.total,
            })
        .toList();

    final isIndividual = _buyerType == 'individual';
    if (!isIndividual && _selectedBuyerBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Chagua biashara inayofanya agizo'
              : 'Pick the business placing this order')));
      return;
    }

    final body = <String, dynamic>{
      'buyer_type': _buyerType,
      'buyer_user_id': widget.currentUserId,
      'user_business_id': isIndividual ? null : _selectedBuyerBusinessId,
      'supplier_id': widget.supplier.id,
      'supplier_name': widget.supplier.name,
      'items': items,
      'expected_delivery_date': _expectedDate?.toIso8601String(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'status': 'draft',
    };

    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await BusinessService.createPurchaseOrder(
          _token!,
          isIndividual ? null : _selectedBuyerBusinessId,
          body);
      if (!mounted) return;
      setState(() => _submittingOrder = false);
      if (!res.success) {
        messenger.showSnackBar(SnackBar(
            content: Text(res.message ??
                (_isSwahili ? 'Imeshindikana' : 'Failed')),
            backgroundColor: Colors.red));
        return;
      }
      // Reset form
      setState(() {
        _orderLines.clear();
        _notesCtrl.clear();
        _expectedDate = null;
      });
      await _loadPOs();
      messenger.showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Agizo limetengenezwa kama rasimu'
              : 'Order created as draft')));
      _tabCtrl.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingOrder = false);
      messenger.showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindikana. Jaribu tena.'
              : 'Failed. Please try again.'),
          backgroundColor: Colors.red));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Local helpers / small widgets
// ─────────────────────────────────────────────────────────────────────────

enum _CatalogSort { nameAsc, nameDesc, priceLowHigh, priceHighLow, recent }

String _fmtMoney(double v) {
  final f = NumberFormat('#,##0', 'en_US');
  return f.format(v);
}

/// Editable order line (used both for catalog picks and custom items).
class _OrderLine {
  String description;
  double quantity;
  double unitPrice;

  _OrderLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

/// Qty + price editor for a catalog-backed line.
class _OrderLineEditor extends StatefulWidget {
  final _OrderLine line;
  final ValueChanged<_OrderLine> onChanged;
  final bool isSwahili;
  const _OrderLineEditor(
      {required this.line, required this.onChanged, required this.isSwahili});

  @override
  State<_OrderLineEditor> createState() => _OrderLineEditorState();
}

class _OrderLineEditorState extends State<_OrderLineEditor> {
  late final TextEditingController _qty;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(
        text: widget.line.quantity % 1 == 0
            ? widget.line.quantity.toInt().toString()
            : widget.line.quantity.toString());
    _price = TextEditingController(
        text: widget.line.unitPrice > 0
            ? widget.line.unitPrice.toStringAsFixed(0)
            : '');
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_OrderLine(
      description: widget.line.description,
      quantity: double.tryParse(_qty.text.trim()) ?? 0,
      unitPrice: double.tryParse(_price.text.trim()) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              onChanged: (_) => _emit(),
              decoration: InputDecoration(
                labelText: widget.isSwahili ? 'Idadi' : 'Qty',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              onChanged: (_) => _emit(),
              decoration: InputDecoration(
                labelText: widget.isSwahili ? 'Bei' : 'Unit price',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('= ${_fmtMoney(widget.line.total)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
        ],
      ),
    );
  }
}

/// Inline editor for an ad-hoc (non-catalog) line with description + qty + price.
class _AdhocLineEditor extends StatefulWidget {
  final _OrderLine line;
  final ValueChanged<_OrderLine> onChanged;
  final bool isSwahili;
  const _AdhocLineEditor(
      {required this.line, required this.onChanged, required this.isSwahili});

  @override
  State<_AdhocLineEditor> createState() => _AdhocLineEditorState();
}

class _AdhocLineEditorState extends State<_AdhocLineEditor> {
  late final TextEditingController _desc;
  late final TextEditingController _qty;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.line.description);
    _qty = TextEditingController(
        text: widget.line.quantity % 1 == 0
            ? widget.line.quantity.toInt().toString()
            : widget.line.quantity.toString());
    _price = TextEditingController(
        text: widget.line.unitPrice > 0
            ? widget.line.unitPrice.toStringAsFixed(0)
            : '');
  }

  @override
  void dispose() {
    _desc.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_OrderLine(
      description: _desc.text,
      quantity: double.tryParse(_qty.text.trim()) ?? 0,
      unitPrice: double.tryParse(_price.text.trim()) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _desc,
          onChanged: (_) => _emit(),
          decoration: InputDecoration(
            hintText: widget.isSwahili ? 'Jina la bidhaa' : 'Item description',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 70,
              child: TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                onChanged: (_) => _emit(),
                decoration: InputDecoration(
                  labelText: widget.isSwahili ? 'Idadi' : 'Qty',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                onChanged: (_) => _emit(),
                decoration: InputDecoration(
                  labelText: widget.isSwahili ? 'Bei' : 'Unit price',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('= ${_fmtMoney(widget.line.total)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
          ],
        ),
      ],
    );
  }
}

/// Compact PO card for the Orders tab.
class _POCard extends StatelessWidget {
  final PurchaseOrder po;
  final bool isSwahili;
  final bool canReorder;
  final VoidCallback? onReorder;
  final VoidCallback? onRecurring;
  const _POCard({
    required this.po,
    required this.isSwahili,
    this.canReorder = false,
    this.onReorder,
    this.onRecurring,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(po.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(po.poNumber.isEmpty ? 'PO' : po.poNumber,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _localizeStatus(po.status, isSwahili),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (canReorder && (onReorder != null || onRecurring != null))
                PopupMenuButton<String>(
                  tooltip: isSwahili ? 'Vitendo' : 'Actions',
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: _kSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v == 'reorder') onReorder?.call();
                    if (v == 'recurring') onRecurring?.call();
                  },
                  itemBuilder: (_) => [
                    if (onReorder != null)
                      PopupMenuItem(
                        value: 'reorder',
                        child: Row(
                          children: [
                            const Icon(Icons.replay_rounded,
                                size: 16, color: _kPrimary),
                            const SizedBox(width: 8),
                            Text(isSwahili ? 'Rudia agizo' : 'Reorder'),
                          ],
                        ),
                      ),
                    if (onRecurring != null)
                      PopupMenuItem(
                        value: 'recurring',
                        child: Row(
                          children: [
                            const Icon(Icons.event_repeat_rounded,
                                size: 16, color: _kPrimary),
                            const SizedBox(width: 8),
                            Text(isSwahili
                                ? 'Kila mara'
                                : 'Set up recurring'),
                          ],
                        ),
                      ),
                  ],
                )
              else
                const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  '${po.items.length} ${isSwahili ? "bidhaa" : "items"}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
                const SizedBox(width: 8),
                const Text('•',
                    style: TextStyle(fontSize: 11, color: _kSecondary)),
                const SizedBox(width: 8),
                Text(
                  po.createdAt != null
                      ? DateFormat('dd MMM yyyy').format(po.createdAt!)
                      : '—',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
                const Spacer(),
                Text('TZS ${_fmtMoney(po.totalAmount)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(PurchaseOrderStatus s) {
    switch (s) {
      case PurchaseOrderStatus.draft:
        return Colors.grey.shade700;
      case PurchaseOrderStatus.sent:
        return Colors.blue.shade700;
      case PurchaseOrderStatus.received:
        return Colors.green.shade700;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.orange.shade700;
      case PurchaseOrderStatus.cancelled:
        return Colors.red.shade700;
    }
  }

  String _localizeStatus(PurchaseOrderStatus s, bool sw) {
    if (sw) return poStatusLabel(s);
    switch (s) {
      case PurchaseOrderStatus.draft:
        return 'DRAFT';
      case PurchaseOrderStatus.sent:
        return 'SENT';
      case PurchaseOrderStatus.received:
        return 'RECEIVED';
      case PurchaseOrderStatus.partiallyReceived:
        return 'PARTIAL';
      case PurchaseOrderStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

/// Card for an active recurring-PO template shown at the top of the Orders tab.
class _RecurringPOCard extends StatelessWidget {
  final RecurringPurchaseOrder rec;
  final bool isSwahili;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onRunNow;

  const _RecurringPOCard({
    required this.rec,
    required this.isSwahili,
    this.canManage = false,
    this.onEdit,
    this.onCancel,
    this.onRunNow,
  });

  @override
  Widget build(BuildContext context) {
    final freqLabel = recurringFrequencyLabel(rec.frequency, swahili: isSwahili);
    final nextRun = rec.nextRunDate;
    final lineCount = rec.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_repeat_rounded,
                        size: 11, color: _kPrimary),
                    const SizedBox(width: 4),
                    Text(
                      freqLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nextRun != null
                      ? (isSwahili
                          ? 'Ijayo: ${DateFormat('dd MMM yyyy').format(nextRun)}'
                          : 'Next: ${DateFormat('dd MMM yyyy').format(nextRun)}')
                      : (isSwahili ? 'Hakuna tarehe' : 'No next date'),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  tooltip: isSwahili ? 'Vitendo' : 'Actions',
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: _kSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    switch (v) {
                      case 'run':
                        onRunNow?.call();
                        break;
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'cancel':
                        onCancel?.call();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    if (onRunNow != null)
                      PopupMenuItem(
                        value: 'run',
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 16, color: _kPrimary),
                            const SizedBox(width: 8),
                            Text(isSwahili ? 'Tengeneza sasa' : 'Run now'),
                          ],
                        ),
                      ),
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_rounded,
                                size: 16, color: _kPrimary),
                            const SizedBox(width: 8),
                            Text(isSwahili ? 'Hariri' : 'Edit'),
                          ],
                        ),
                      ),
                    if (onCancel != null)
                      PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.stop_circle_outlined,
                                size: 16, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Text(isSwahili ? 'Sitisha' : 'Cancel'),
                          ],
                        ),
                      ),
                  ],
                )
              else
                const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  '$lineCount ${isSwahili ? "bidhaa" : "items"}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
                const SizedBox(width: 8),
                const Text('•',
                    style: TextStyle(fontSize: 11, color: _kSecondary)),
                const SizedBox(width: 8),
                Text(
                  isSwahili
                      ? '${rec.totalGenerated} yamekwishatengenezwa'
                      : '${rec.totalGenerated} generated',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
                if (rec.maxOrders != null) ...[
                  const SizedBox(width: 4),
                  Text('/ ${rec.maxOrders}',
                      style: const TextStyle(
                          fontSize: 11, color: _kSecondary)),
                ],
                const Spacer(),
                Text('TZS ${_fmtMoney(rec.totalAmount)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
              ],
            ),
          ),
          if (rec.autoSend || rec.endDate != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (rec.autoSend)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSwahili ? 'Tuma kiotomatiki' : 'Auto-send',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  if (rec.endDate != null)
                    Text(
                      isSwahili
                          ? 'Hadi ${DateFormat('dd MMM yyyy').format(rec.endDate!)}'
                          : 'Until ${DateFormat('dd MMM yyyy').format(rec.endDate!)}',
                      style:
                          const TextStyle(fontSize: 10, color: _kSecondary),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
