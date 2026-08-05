import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../../services/local_storage_service.dart';

const Color _kBg = Color(0xFF1A1A1A);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kSuccess = Color(0xFF22C55E);
const Color _kError = Color(0xFFDC2626);
const Color _kWarning = Color(0xFFF59E0B);

/// Smartphone barcode/QR scanner for fast inventory updates.
///
/// Usage modes:
///  - [ScanMode.quickUpdate] — scan a product, tap +/- or set exact qty
///  - [ScanMode.stocktake] — scan products one by one to record physical counts
///
/// Products are matched by barcode against [Product.sku] or title search
/// fallback.
enum ScanMode { quickUpdate, stocktake }

class BarcodeStocktakeScreen extends StatefulWidget {
  const BarcodeStocktakeScreen({
    super.key,
    this.mode = ScanMode.quickUpdate,
    this.preloadedProducts,
  });

  final ScanMode mode;

  /// Pass already-loaded products to avoid re-fetching.
  final List<Product>? preloadedProducts;

  @override
  State<BarcodeStocktakeScreen> createState() => _BarcodeStocktakeScreenState();
}

class _BarcodeStocktakeScreenState extends State<BarcodeStocktakeScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final ShopRepository _repo = ShopRepository.instance;

  List<Product> _products = [];
  bool _loadingProducts = true;
  int? _sellerId;

  // Current scan state
  bool _isPaused = false;
  Product? _matchedProduct;
  bool _isUpdating = false;
  String? _feedback;
  bool _feedbackIsError = false;

  // Stocktake log: productId → counted quantity
  final Map<int, int> _stocktakeLog = {};
  int _scansThisSession = 0;

  // Manual quantity controller shown in bottom sheet
  final TextEditingController _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preloadedProducts != null) {
      _products = widget.preloadedProducts!;
      _loadingProducts = false;
      _initSeller();
    } else {
      _initAndLoad();
    }
  }

  @override
  void dispose() {
    _scanner.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSeller() async {
    final storage = await LocalStorageService.getInstance();
    if (!mounted) return;
    setState(() => _sellerId = storage.getUser()?.userId ?? 1);
  }

  Future<void> _initAndLoad() async {
    final storage = await LocalStorageService.getInstance();
    if (!mounted) return;
    _sellerId = storage.getUser()?.userId ?? 1;
    final r = await _repo.getSellerProducts(_sellerId!, perPage: 500);
    if (!mounted) return;
    setState(() {
      _loadingProducts = false;
      if (r.success) _products = r.products;
    });
  }

  // ─── Barcode detection ─────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_isPaused || _matchedProduct != null) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final raw = barcode.rawValue!;
    _handleBarcode(raw);
  }

  void _handleBarcode(String raw) {
    // 1. Try exact slug match (slug is the product's URL-safe identifier)
    Product? match = _products.where((p) => p.slug == raw).firstOrNull;

    // 2. Try tag match (sellers can add barcodes as tags)
    match ??= _products
        .where((p) => p.tags?.any((t) => t == raw) ?? false)
        .firstOrNull;

    // 3. Try partial title match (for hand-labeled QR codes)
    match ??= _products
        .where((p) => p.title.toLowerCase().contains(raw.toLowerCase()))
        .firstOrNull;

    if (match == null) {
      _showFeedback('No product found for: $raw', isError: true);
      HapticFeedback.heavyImpact();
      return;
    }

                    HapticFeedback.mediumImpact();
    setState(() {
      _isPaused = true;
      _matchedProduct = match;
      _feedback = null;
    });
    _showProductBottomSheet(match);
  }

  // ─── Product bottom sheet ──────────────────────────────────────────────────

  void _showProductBottomSheet(Product product) {
    final currentStock = _stocktakeLog[product.id] ?? product.stockQuantity;
    _qtyCtrl.text = '$currentStock';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _ProductUpdateSheet(
        product: product,
        mode: widget.mode,
        currentStock: currentStock,
        isUpdating: _isUpdating,
        qtyCtrl: _qtyCtrl,
        stocktakeLog: _stocktakeLog,
        onCancel: _resumeScanning,
        onConfirm: (newQty) => _commitUpdate(product, newQty),
      ),
    ).then((_) => _resumeScanning());
  }

  Future<void> _commitUpdate(Product product, int newQty) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    if (widget.mode == ScanMode.stocktake) {
      // In stocktake mode just record locally
      setState(() {
        _stocktakeLog[product.id] = newQty;
        _scansThisSession++;
        _isUpdating = false;
      });
      if (mounted) Navigator.of(context).pop(); // close sheet
      _showFeedback('Counted: ${product.title} → $newQty units', isError: false);
      _resumeScanning();
      return;
    }

    // Quick update mode — send to API
    final res = await _repo.updateProduct(
      productId: product.id,
      sellerId: _sellerId ?? 1,
      stockQuantity: newQty,
    );

    if (!mounted) return;
    setState(() {
      _isUpdating = false;
      _scansThisSession++;
    });
    Navigator.of(context).pop(); // close sheet

    if (res.success) {
      HapticFeedback.lightImpact();
      _showFeedback('Updated: ${product.title} → $newQty units', isError: false);
      // Update local stock cache without re-fetching
      final idx = _products.indexWhere((p) => p.id == product.id);
      if (idx != -1) {
        setState(() => _products[idx] = Product(
          id: product.id,
          sellerId: product.sellerId,
          title: product.title,
          description: product.description,
          slug: product.slug,
          type: product.type,
          status: product.status,
          price: product.price,
          compareAtPrice: product.compareAtPrice,
          currency: product.currency,
          stockQuantity: newQty,
          images: product.images,
          thumbnailPath: product.thumbnailPath,
          categoryId: product.categoryId,
          tags: product.tags,
          condition: product.condition,
          locationName: product.locationName,
          latitude: product.latitude,
          longitude: product.longitude,
          allowPickup: product.allowPickup,
          allowDelivery: product.allowDelivery,
          allowShipping: product.allowShipping,
          deliveryFee: product.deliveryFee,
          deliveryNotes: product.deliveryNotes,
          pickupAddress: product.pickupAddress,
          downloadUrl: product.downloadUrl,
          downloadLimit: product.downloadLimit,
          durationMinutes: product.durationMinutes,
          serviceLocation: product.serviceLocation,
          viewsCount: product.viewsCount,
          favoritesCount: product.favoritesCount,
          ordersCount: product.ordersCount,
          rating: product.rating,
          reviewsCount: product.reviewsCount,
          seller: product.seller,
          category: product.category,
          isFavorited: product.isFavorited,
          createdAt: product.createdAt,
          updatedAt: DateTime.now(),
        ));
      }
    } else {
      HapticFeedback.heavyImpact();
      _showFeedback(res.message ?? 'Update failed', isError: true);
    }
    _resumeScanning();
  }

  void _resumeScanning() {
    setState(() {
      _isPaused = false;
      _matchedProduct = null;
      _isUpdating = false;
    });
  }

  void _showFeedback(String msg, {required bool isError}) {
    setState(() {
      _feedback = msg;
      _feedbackIsError = isError;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _feedback = null);
    });
  }

  // ─── Manual entry (no barcode) ─────────────────────────────────────────────

  void _showManualSearch() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find Product', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 14),
            TextField(
              controller: searchCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Search by name or SKU…',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(builder: (_, setLocal) {
              final query = searchCtrl.text.toLowerCase();
              final results = query.isEmpty
                  ? <Product>[]
                  : _products
                      .where((p) =>
                          p.title.toLowerCase().contains(query) ||
                          p.slug.toLowerCase().contains(query))
                      .take(8)
                      .toList();
              searchCtrl.addListener(() => setLocal(() {}));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: results
                    .map((p) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.inventory_2_rounded, size: 18),
                          title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Stock: ${p.stockQuantity}', style: const TextStyle(fontSize: 11)),
                          onTap: () {
                            searchCtrl.dispose();
                            Navigator.pop(ctx);
                            setState(() {
                              _isPaused = true;
                              _matchedProduct = p;
                            });
                            _showProductBottomSheet(p);
                          },
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Stocktake summary ────────────────────────────────────────────────────

  void _showStocktakeSummary() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                const Expanded(child: Text('Stocktake Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, _stocktakeLog);
                  },
                  child: const Text('Save & Exit', style: TextStyle(color: _kText, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _SummaryChip(label: '${_stocktakeLog.length} scanned', icon: Icons.qr_code_scanner_rounded),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: '${_discrepancyCount()} discrepancies',
                  icon: Icons.warning_amber_rounded,
                  isWarning: _discrepancyCount() > 0,
                ),
              ]),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _stocktakeLog.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final productId = _stocktakeLog.keys.elementAt(i);
                  final counted = _stocktakeLog.values.elementAt(i);
                  final product = _products.where((p) => p.id == productId).firstOrNull;
                  final systemQty = product?.stockQuantity ?? 0;
                  final diff = counted - systemQty;
                  return ListTile(
                    dense: true,
                    title: Text(product?.title ?? 'Product #$productId', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('System: $systemQty  →  Counted: $counted'),
                    trailing: diff == 0
                        ? const Icon(Icons.check_circle_rounded, color: _kSuccess, size: 20)
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: diff > 0 ? _kSuccess.withValues(alpha: 0.1) : _kError.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              diff > 0 ? '+$diff' : '$diff',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: diff > 0 ? _kSuccess : _kError,
                                fontSize: 13,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kText, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _applyStocktake(ctx),
                  child: const Text('Apply All Counts', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _discrepancyCount() => _stocktakeLog.entries.where((e) {
        final product = _products.where((p) => p.id == e.key).firstOrNull;
        return product != null && product.stockQuantity != e.value;
      }).length;

  Future<void> _applyStocktake(BuildContext sheetCtx) async {
    Navigator.pop(sheetCtx);
    int success = 0;
    for (final entry in _stocktakeLog.entries) {
      final product = _products.where((p) => p.id == entry.key).firstOrNull;
      if (product == null) continue;
      final res = await _repo.updateProduct(
        productId: entry.key,
        sellerId: _sellerId ?? 1,
        stockQuantity: entry.value,
      );
      if (res.success) success++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $success / ${_stocktakeLog.length} products')),
      );
      Navigator.pop(context, _stocktakeLog);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isStocktake = widget.mode == ScanMode.stocktake;

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          isStocktake ? 'Stocktake Mode' : 'Scan to Update',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Torch toggle
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _scanner,
            builder: (context, state, child) => IconButton(
              icon: Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                color: state.torchState == TorchState.on
                    ? const Color(0xFFFBBF24)
                    : Colors.white,
              ),
              onPressed: () => _scanner.toggleTorch(),
              tooltip: 'Toggle torch',
            ),
          ),
          // Summary (stocktake only)
          if (isStocktake && _stocktakeLog.isNotEmpty)
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
                  onPressed: _showStocktakeSummary,
                  tooltip: 'Stocktake summary',
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: _kSuccess, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${_stocktakeLog.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          if (_loadingProducts)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            MobileScanner(
              controller: _scanner,
              onDetect: _onDetect,
            ),

          // Scan overlay
          _ScanOverlay(isPaused: _isPaused),

          // Session counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_scansThisSession scanned this session',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),

          // Feedback toast
          if (_feedback != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 104,
              left: 24, right: 24,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _feedbackIsError ? _kError : _kSuccess,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(
                      _feedbackIsError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _feedback!,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Row(children: [
                // Manual search
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Search', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: _showManualSearch,
                  ),
                ),
                if (isStocktake && _stocktakeLog.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.summarize_rounded, size: 18),
                      label: Text('${_stocktakeLog.length} counted', style: const TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: _showStocktakeSummary,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan frame overlay ────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.isPaused});
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              border: Border.all(
                color: isPaused ? const Color(0xFFFBBF24) : Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Corner brackets
                ..._corners(isPaused ? const Color(0xFFFBBF24) : Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isPaused ? 'Processing…' : 'Align barcode or QR code within the frame',
            style: TextStyle(
              color: isPaused ? const Color(0xFFFBBF24) : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners(Color color) {
    const size = 24.0;
    const w = 3.0;
    return [
      // top-left
      Positioned(top: 0, left: 0, child: _Corner(color: color, size: size, strokeWidth: w, topLeft: true)),
      // top-right
      Positioned(top: 0, right: 0, child: _Corner(color: color, size: size, strokeWidth: w, topRight: true)),
      // bottom-left
      Positioned(bottom: 0, left: 0, child: _Corner(color: color, size: size, strokeWidth: w, bottomLeft: true)),
      // bottom-right
      Positioned(bottom: 0, right: 0, child: _Corner(color: color, size: size, strokeWidth: w, bottomRight: true)),
    ];
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    required this.color,
    required this.size,
    required this.strokeWidth,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  final Color color;
  final double size;
  final double strokeWidth;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _CornerPainter(
        color: color, strokeWidth: strokeWidth,
        topLeft: topLeft, topRight: topRight,
        bottomLeft: bottomLeft, bottomRight: bottomRight,
      )),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.color, required this.strokeWidth,
    this.topLeft = false, this.topRight = false,
    this.bottomLeft = false, this.bottomRight = false,
  });

  final Color color;
  final double strokeWidth;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    if (topLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(0, h), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ─── Product update bottom sheet ──────────────────────────────────────────

class _ProductUpdateSheet extends StatefulWidget {
  const _ProductUpdateSheet({
    required this.product,
    required this.mode,
    required this.currentStock,
    required this.isUpdating,
    required this.qtyCtrl,
    required this.stocktakeLog,
    required this.onCancel,
    required this.onConfirm,
  });

  final Product product;
  final ScanMode mode;
  final int currentStock;
  final bool isUpdating;
  final TextEditingController qtyCtrl;
  final Map<int, int> stocktakeLog;
  final VoidCallback onCancel;
  final void Function(int) onConfirm;

  @override
  State<_ProductUpdateSheet> createState() => _ProductUpdateSheetState();
}

class _ProductUpdateSheetState extends State<_ProductUpdateSheet> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.currentStock;
    widget.qtyCtrl.text = '$_qty';
  }

  void _adjust(int delta) {
    setState(() {
      _qty = (_qty + delta).clamp(0, 9999);
      widget.qtyCtrl.text = '$_qty';
    });
  }

  Color get _stockColor {
    if (_qty == 0) return _kError;
    if (_qty <= 4) return _kWarning;
    return _kSuccess;
  }

  @override
  Widget build(BuildContext context) {
    final isStocktake = widget.mode == ScanMode.stocktake;
    final systemQty = widget.product.stockQuantity;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Product info
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, size: 24, color: _kMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.product.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kText),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('Slug: ${widget.product.slug}',
                        style: const TextStyle(fontSize: 11, color: _kMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),

              // System stock vs new
              if (isStocktake) ...[
                Row(children: [
                  _InfoPill(label: 'System', value: '$systemQty', color: _kMuted),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: _kMuted),
                  const SizedBox(width: 8),
                  _InfoPill(
                    label: 'Counted',
                    value: '$_qty',
                    color: _qty == systemQty ? _kSuccess : _kWarning,
                  ),
                ]),
                const SizedBox(height: 16),
              ] else ...[
                Row(children: [
                  _InfoPill(label: 'Current stock', value: '$systemQty', color: _kMuted),
                ]),
                const SizedBox(height: 16),
              ],

              // Quantity row
              Row(children: [
                // Minus
                _QtyButton(icon: Icons.remove_rounded, onTap: () => _adjust(-1)),
                const SizedBox(width: 12),
                // Input
                Expanded(
                  child: TextField(
                    controller: widget.qtyCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _stockColor,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) setState(() => _qty = parsed.clamp(0, 9999));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Plus
                _QtyButton(icon: Icons.add_rounded, onTap: () => _adjust(1)),
              ]),

              // Quick presets
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [5, 10, 20, 50, 100].map((n) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text('$n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () => setState(() {
                      _qty = n;
                      widget.qtyCtrl.text = '$n';
                    }),
                    backgroundColor: const Color(0xFFF5F5F5),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                )).toList()),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kText,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(0, 50),
                    ),
                    onPressed: widget.isUpdating ? null : () {
                      Navigator.pop(context);
                      widget.onCancel();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kText,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(0, 50),
                    ),
                    onPressed: widget.isUpdating ? null : () => widget.onConfirm(_qty),
                    child: widget.isUpdating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            isStocktake ? 'Record Count' : 'Update Stock',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small helpers ─────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 52, height: 52,
          child: Icon(icon, color: _kText, size: 24),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.icon, this.isWarning = false});
  final String label;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? _kWarning : _kText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
