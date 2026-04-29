import 'package:flutter/material.dart';
import '../../business/models/business_models.dart';
import '../../business/pages/business_profile_page.dart';
import '../../biz_services/pages/biz_service_form_page.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/product_models.dart';
import '../services/product_service.dart';
import 'product_form_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProductsPage extends StatefulWidget {
  final int businessId;
  final bool isDefaultShop;
  final Business business;
  final bool showAppBar;
  final bool isOwner;

  const ProductsPage({
    super.key,
    required this.businessId,
    required this.isDefaultShop,
    required this.business,
    this.showAppBar = true,
    this.isOwner = true,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _loading = true;
  List<BusinessProduct> _products = [];
  String? _token;
  int _userId = 0;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId ?? 0;
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final products = await ProductService.getProducts(
      token: _token!,
      businessId: widget.businessId,
      userId: _userId,
      isDefaultShop: widget.isDefaultShop,
    );
    if (mounted) setState(() { _loading = false; _products = products; });
  }

  void _openForm({BusinessProduct? product}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          businessId: widget.businessId,
          isDefaultShop: widget.isDefaultShop,
          userId: _userId,
          token: _token ?? '',
          product: product,
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  void _showDetail(BusinessProduct p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ProductDetailSheet(
        product: p,
        isSwahili: _isSwahili,
        token: _token ?? '',
        businessId: widget.businessId,
        userId: _userId,
        isDefaultShop: widget.isDefaultShop,
        isOwner: widget.isOwner,
        onStatusChanged: _load,
        onEdit: () { Navigator.pop(ctx); _openForm(product: p); },
        onDelete: () async {
          Navigator.pop(ctx);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dCtx) => AlertDialog(
              title: Text(_isSwahili ? 'Futa "${p.title}"?' : 'Delete "${p.title}"?'),
              content: Text(_isSwahili ? 'Haiwezi kurudishwa' : 'This cannot be undone'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: Text(_isSwahili ? 'Hapana' : 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: Text(_isSwahili ? 'Futa' : 'Delete',
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirmed != true || !mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          final ok = await ProductService.deleteProduct(
            token: _token!,
            businessId: widget.businessId,
            userId: _userId,
            isDefaultShop: widget.isDefaultShop,
            productId: p.id,
          );
          if (!mounted) return;
          messenger.showSnackBar(SnackBar(
            content: Text(ok
                ? (_isSwahili ? 'Bidhaa imefutwa' : 'Product deleted')
                : (_isSwahili ? 'Imeshindikana' : 'Failed')),
            backgroundColor: ok ? null : Colors.red,
          ));
          if (ok) _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(_isSwahili ? 'Bidhaa' : 'Products',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: _kCardBg,
              foregroundColor: _kPrimary,
              elevation: 0,
            )
          : null,
      floatingActionButton: widget.isOwner
          ? FloatingActionButton(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              onPressed: () => _openForm(),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              color: _kPrimary,
              onRefresh: _load,
              child: _products.isEmpty
                  ? _buildEmpty()
                  : _buildProductList(),
            ),
    );
  }

  Widget _buildDiscoverabilityBanner() {
    int score = 0;
    final List<({IconData icon, String label, VoidCallback onTap})> actions = [];

    void goToProfile() => Navigator.push(context, MaterialPageRoute(
        builder: (_) => BusinessProfilePage(userId: _userId, business: widget.business)));

    if (widget.business.logoUrl != null && widget.business.logoUrl!.isNotEmpty) {
      score += 20;
    } else {
      actions.add((
        icon: Icons.account_circle_outlined,
        label: _isSwahili ? 'Ongeza nembo ya biashara (+20)' : 'Add business logo (+20)',
        onTap: goToProfile,
      ));
    }

    if (_products.length >= 3) {
      score += 20;
    } else {
      actions.add((
        icon: Icons.inventory_2_outlined,
        label: _isSwahili ? 'Ongeza bidhaa 3+ (+20)' : 'Add 3+ products (+20)',
        onTap: _openForm,
      ));
    }

    if (_products.isNotEmpty && _products.any((p) => p.description != null && p.description!.isNotEmpty)) {
      score += 15;
    } else if (_products.isNotEmpty) {
      actions.add((
        icon: Icons.description_outlined,
        label: _isSwahili ? 'Ongeza maelezo kwenye bidhaa (+15)' : 'Add descriptions to products (+15)',
        onTap: _openForm,
      ));
    }

    actions.add((
      icon: Icons.miscellaneous_services_outlined,
      label: _isSwahili ? 'Ongeza huduma kwenye biashara (+20)' : 'Add services to your business (+20)',
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BizServiceFormPage(businessId: widget.businessId, token: _token ?? ''))),
    ));

    if (widget.business.sector != null && widget.business.sector!.isNotEmpty) {
      score += 15;
    } else {
      actions.add((
        icon: Icons.category_outlined,
        label: _isSwahili ? 'Weka sekta ya biashara (+15)' : 'Fill in your business sector (+15)',
        onTap: goToProfile,
      ));
    }

    if (widget.business.phone != null && widget.business.phone!.isNotEmpty) {
      score += 10;
    } else {
      actions.add((
        icon: Icons.phone_outlined,
        label: _isSwahili ? 'Ongeza nambari ya simu (+10)' : 'Add business phone number (+10)',
        onTap: goToProfile,
      ));
    }

    if (_products.isEmpty) return const SizedBox.shrink();

    final displayActions = actions.take(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFFF57F17)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _isSwahili ? 'Uonekano: $score/100' : 'Discoverability score: $score/100',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF57F17)),
            )),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: const Color(0xFFFFE082),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF57F17)),
              minHeight: 6,
            ),
          ),
          if (displayActions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...displayActions.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: a.onTap,
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  Icon(a.icon, size: 13, color: const Color(0xFFF57F17)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(a.label,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFF57F17)))),
                  const Icon(Icons.chevron_right, size: 13, color: Color(0xFFF57F17)),
                ]),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                if (widget.isDefaultShop) _buildShopBanner(),
                if (widget.isOwner) _buildDiscoverabilityBanner(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final p = _products[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProductCard(product: p, isDefaultShop: widget.isDefaultShop, onTap: () => _showDetail(p)),
                );
              },
              childCount: _products.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/tea'),
              icon: const Icon(Icons.support_agent_rounded, color: _kPrimary, size: 18),
              label: Text(
                _isSwahili
                    ? 'Uliza Shangazi kuhusu Bei za Bidhaa'
                    : 'Ask Shangazi about Product Pricing',
                style: const TextStyle(color: _kPrimary, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSwahili
                  ? 'Hizi ni bidhaa za Duka lako — mabadiliko yataonekana kwenye soko'
                  : 'These are your Shop products — changes here update your marketplace listing',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                if (widget.isOwner && widget.isDefaultShop) _buildShopBanner(),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _isSwahili ? 'Bado hakuna bidhaa' : 'No products yet',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isOwner
                            ? (_isSwahili
                                ? 'Ongeza bidhaa kwanza ili wanunuzi wakupate'
                                : 'Add products so buyers can find your business')
                            : (_isSwahili
                                ? 'Biashara hii bado haijaorodhesha bidhaa.'
                                : 'This business hasn\'t listed any products yet.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _kSecondary, fontSize: 14),
                      ),
                      if (widget.isOwner) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(_isSwahili ? 'Ongeza Bidhaa' : 'Add Product'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pushNamed('/tea'),
                          icon: const Icon(Icons.support_agent_rounded, color: _kPrimary, size: 18),
                          label: Text(
                            _isSwahili ? 'Uliza Shangazi' : 'Ask Shangazi',
                            style: const TextStyle(color: _kPrimary, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final BusinessProduct product;
  final bool isDefaultShop;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.isDefaultShop, required this.onTap});

  Color _statusColor(ProductStatus s) {
    switch (s) {
      case ProductStatus.active: return Colors.green;
      case ProductStatus.draft: return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.thumbnail.isNotEmpty
                            ? Image.network(product.thumbnail, width: 56, height: 56, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder())
                            : _placeholder(),
                      ),
                      if (product.images.length > 1)
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${product.images.length}',
                                style: const TextStyle(fontSize: 9, color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary)),
                          ),
                          if (isDefaultShop) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Shop',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                      color: Color(0xFF1565C0))),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text('TZS ${_fmt(product.price)}',
                            style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(product.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(product.statusLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: _statusColor(product.status))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.visibility_outlined, size: 13, color: _kSecondary),
                const SizedBox(width: 3),
                Text('${product.viewsCount}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                const SizedBox(width: 10),
                Icon(Icons.favorite_outline_rounded, size: 13, color: _kSecondary),
                const SizedBox(width: 3),
                Text('${product.favoritesCount}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                const SizedBox(width: 10),
                Icon(Icons.shopping_bag_outlined, size: 13, color: _kSecondary),
                const SizedBox(width: 3),
                Text('${product.ordersCount}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                if (product.status == ProductStatus.active &&
                    product.categoryName != null && product.categoryName!.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isSwahili
                          ? 'Inaonekana: ${product.categoryName}'
                          : 'Visible: ${product.categoryName}',
                      style: const TextStyle(fontSize: 10, color: Colors.teal,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56, height: 56,
    color: Colors.grey.shade100,
    child: const Icon(Icons.image_outlined, color: Colors.grey),
  );

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ProductDetailSheet extends StatefulWidget {
  final BusinessProduct product;
  final bool isSwahili;
  final String token;
  final int businessId;
  final int userId;
  final bool isDefaultShop;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatusChanged;
  const _ProductDetailSheet({
    required this.product,
    required this.isSwahili,
    required this.token,
    required this.businessId,
    required this.userId,
    required this.isDefaultShop,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  late ProductStatus _status;
  bool _patchingStatus = false;

  @override
  void initState() {
    super.initState();
    _status = widget.product.status;
  }

  Future<void> _setStatus(ProductStatus s) async {
    if (s == _status || _patchingStatus) return;
    if (s == ProductStatus.soldOut) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: Text(widget.isSwahili ? 'Bidhaa Imeisha?' : 'Mark as Out of Stock?'),
          content: Text(widget.isSwahili
              ? 'Bidhaa hii itaonekana kuwa haipatikani kwa wanunuzi'
              : 'This product will appear as unavailable to buyers'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx, false),
                child: Text(widget.isSwahili ? 'Hapana' : 'Cancel')),
            TextButton(onPressed: () => Navigator.pop(dCtx, true),
                child: Text(widget.isSwahili ? 'Ndio' : 'Confirm',
                    style: const TextStyle(color: _kPrimary))),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() { _status = s; _patchingStatus = true; });
    final ok = await ProductService.patchProductStatus(
      token: widget.token,
      businessId: widget.businessId,
      userId: widget.userId,
      isDefaultShop: widget.isDefaultShop,
      productId: widget.product.id,
      status: s,
    );
    if (!mounted) return;
    setState(() => _patchingStatus = false);
    if (!ok) {
      setState(() => _status = widget.product.status);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili ? 'Imeshindikana' : 'Failed to update status'),
        backgroundColor: Colors.red,
      ));
    } else {
      final String msg;
      switch (s) {
        case ProductStatus.active:
          msg = widget.isSwahili ? 'Sasa inaonekana kama Inapatikana' : 'Now showing as Active';
        case ProductStatus.draft:
          msg = widget.isSwahili ? 'Sasa inaonekana kama Rasimu' : 'Now showing as Draft';
        case ProductStatus.soldOut:
          msg = widget.isSwahili ? 'Sasa inaonekana kama Imeisha' : 'Now showing as Out of Stock';
        case ProductStatus.archived:
          msg = widget.isSwahili ? 'Sasa imehifadhiwa' : 'Now showing as Archived';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      widget.onStatusChanged();
    }
  }

  Color _statusColor(ProductStatus s) {
    switch (s) {
      case ProductStatus.active: return Colors.green;
      case ProductStatus.draft: return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _statusLabel(ProductStatus s) {
    switch (s) {
      case ProductStatus.active: return widget.isSwahili ? 'Inapatikana' : 'Active';
      case ProductStatus.draft: return widget.isSwahili ? 'Rasimu' : 'Draft';
      case ProductStatus.soldOut: return widget.isSwahili ? 'Imeisha' : 'Sold Out';
      case ProductStatus.archived: return widget.isSwahili ? 'Imehifadhiwa' : 'Archived';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.product.images.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: widget.product.images.length,
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(widget.product.images[i], fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.image_outlined, color: Colors.grey))),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(widget.product.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('TZS ${_fmt(widget.product.price)}',
                          style: const TextStyle(fontSize: 16, color: _kSecondary)),
                      if (widget.product.compareAtPrice != null &&
                          widget.product.compareAtPrice! > widget.product.price) ...[
                        const SizedBox(width: 8),
                        Text('TZS ${_fmt(widget.product.compareAtPrice!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            )),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 16, children: [
                    _detailRow(Icons.inventory_2_outlined,
                        widget.isSwahili ? 'Hifadhi: ${widget.product.stockQuantity}' : 'Stock: ${widget.product.stockQuantity}'),
                    _detailRow(Icons.category_outlined,
                        widget.isSwahili
                            ? 'Aina: ${widget.product.type.name}'
                            : 'Type: ${widget.product.type.name}'),
                    _detailRow(Icons.star_outline_rounded,
                        widget.isSwahili
                            ? 'Hali: ${widget.product.condition.name}'
                            : 'Condition: ${widget.product.condition.name}'),
                  ]),
                  if (widget.product.allowPickup || widget.product.allowDelivery || widget.product.allowShipping) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, children: [
                      if (widget.product.allowPickup)
                        _optionChip(Icons.storefront_outlined,
                            widget.isSwahili ? 'Kuchukua' : 'Pickup'),
                      if (widget.product.allowDelivery)
                        _optionChip(Icons.delivery_dining_rounded,
                            widget.isSwahili ? 'Uwasilishaji' : 'Delivery'),
                      if (widget.product.allowShipping)
                        _optionChip(Icons.local_shipping_outlined,
                            widget.isSwahili ? 'Usafirishaji' : 'Shipping'),
                    ]),
                  ],
                  if (widget.product.ordersCount > 0 && widget.product.price > 0) ...[
                    const SizedBox(height: 8),
                    _detailRow(Icons.trending_up_rounded,
                        '${widget.isSwahili ? 'Mapato ya Makisio' : 'Revenue Estimate'}: TZS ${_fmt(widget.product.ordersCount * widget.product.price)}'),
                  ],
                  if (widget.product.description != null) ...[
                    const SizedBox(height: 12),
                    Text(widget.product.description!, style: const TextStyle(color: _kSecondary)),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    _statChip(Icons.visibility_outlined, '${widget.product.viewsCount}',
                        widget.isSwahili ? 'Maoni' : 'Views'),
                    const SizedBox(width: 8),
                    _statChip(Icons.favorite_outline_rounded, '${widget.product.favoritesCount}',
                        widget.isSwahili ? 'Kupenda' : 'Favorites'),
                    const SizedBox(width: 8),
                    _statChip(Icons.shopping_bag_outlined, '${widget.product.ordersCount}',
                        widget.isSwahili ? 'Mauzo' : 'Orders'),
                    if (widget.product.rating > 0) ...[
                      const SizedBox(width: 8),
                      _statChip(Icons.star_outline_rounded,
                          widget.product.rating.toStringAsFixed(1),
                          widget.isSwahili ? 'Ukadiriaji' : 'Rating'),
                    ],
                  ]),
                  if (widget.product.viewsThisWeek > 0 || widget.product.viewsLastWeek > 0) ...[
                    const SizedBox(height: 8),
                    _detailRow(Icons.trending_up_rounded,
                        widget.isSwahili
                            ? 'Wiki hii: ${widget.product.viewsThisWeek} maoni  |  Wiki iliyopita: ${widget.product.viewsLastWeek}'
                            : 'This week: ${widget.product.viewsThisWeek} views  |  Last week: ${widget.product.viewsLastWeek}'),
                  ],
                  if (widget.product.conversionRate > 0) ...[
                    const SizedBox(height: 4),
                    _detailRow(Icons.swap_horiz_rounded,
                        widget.isSwahili
                            ? 'Kiwango cha ubadilishaji: ${widget.product.conversionRate.toStringAsFixed(1)}%'
                            : 'Conversion rate: ${widget.product.conversionRate.toStringAsFixed(1)}%'),
                  ],
                  if (widget.isOwner) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.isSwahili ? 'Hali ya Bidhaa' : 'Product Status',
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ProductStatus.values.map((s) => ChoiceChip(
                        label: _patchingStatus && s == _status
                            ? const SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                            : Text(_statusLabel(s)),
                        selected: _status == s,
                        selectedColor: _statusColor(s).withValues(alpha: 0.15),
                        onSelected: (_patchingStatus) ? null : (_) => _setStatus(s),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _status == s ? _statusColor(s) : _kSecondary,
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (widget.isDefaultShop)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushNamed('/shop/product/${widget.product.id}'),
                          icon: const Icon(Icons.storefront_rounded, color: _kPrimary),
                          label: Text(widget.isSwahili ? 'Tazama Dukani' : 'View in Shop',
                              style: const TextStyle(color: _kPrimary)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _kPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ),
                  if (widget.isOwner)
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          label: Text(widget.isSwahili ? 'Futa' : 'Delete',
                              style: const TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_rounded),
                          label: Text(widget.isSwahili ? 'Hariri' : 'Edit'),
                          style: FilledButton.styleFrom(
                              backgroundColor: _kPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: _kSecondary),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12, color: _kSecondary)),
    ]);
  }

  Widget _optionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: _kSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
      ]),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _kSecondary),
        const SizedBox(width: 4),
        Text('$value $label',
            style: const TextStyle(fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
