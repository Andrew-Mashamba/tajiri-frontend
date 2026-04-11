// lib/skincare/pages/products_page.dart
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';
import '../services/skincare_service.dart';
import '../widgets/product_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProductsPage extends StatefulWidget {
  final int userId;
  final SkinProfile? skinProfile;
  const ProductsPage({super.key, required this.userId, this.skinProfile});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with SingleTickerProviderStateMixin {
  final SkincareService _service = SkincareService();
  late TabController _tabController;

  final List<_Category> _categories = [
    _Category('cleanser', 'Sabuni'),
    _Category('moisturizer', 'Moisturizer'),
    _Category('sunscreen', 'Sunscreen'),
    _Category('serum', 'Serum'),
    _Category('treatment', 'Tiba'),
  ];

  List<SkinProduct> _products = [];
  bool _isLoading = true;
  SkinType? _filterSkinType;
  SkinConcern? _filterConcern;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadProducts();
    });
    _filterSkinType = widget.skinProfile?.skinType;
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final category = _categories[_tabController.index].key;
    final result = await _service.getProducts(
      category: category,
      skinType: _filterSkinType?.name,
      concern: _filterConcern?.name,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _products = result.items;
      });
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chuja Bidhaa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 16),
              const Text('Aina ya Ngozi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Zote'),
                    selected: _filterSkinType == null,
                    onSelected: (_) => setSheetState(() => _filterSkinType = null),
                    selectedColor: _kPrimary.withValues(alpha: 0.12),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                  ...SkinType.values.map((t) => ChoiceChip(
                        label: Text(t.displayName),
                        selected: _filterSkinType == t,
                        onSelected: (_) => setSheetState(() => _filterSkinType = t),
                        selectedColor: _kPrimary.withValues(alpha: 0.12),
                        labelStyle: const TextStyle(fontSize: 12),
                      )),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Tatizo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Zote'),
                    selected: _filterConcern == null,
                    onSelected: (_) => setSheetState(() => _filterConcern = null),
                    selectedColor: _kPrimary.withValues(alpha: 0.12),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                  ...SkinConcern.values.map((c) => ChoiceChip(
                        label: Text(c.displayName),
                        selected: _filterConcern == c,
                        onSelected: (_) => setSheetState(() => _filterConcern = c),
                        selectedColor: _kPrimary.withValues(alpha: 0.12),
                        labelStyle: const TextStyle(fontSize: 12),
                      )),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadProducts();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Tafuta', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetail(SkinProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            // Product image
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(product.imageUrl!, fit: BoxFit.contain,
                        errorBuilder: (_, e, s) => const Icon(Icons.face_retouching_natural_rounded, size: 48, color: _kSecondary)),
                    )
                  : const Icon(Icons.face_retouching_natural_rounded, size: 48, color: _kSecondary),
            ),
            const SizedBox(height: 16),
            // Name & brand
            Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kPrimary)),
            if (product.brand != null)
              Text(product.brand!, style: const TextStyle(fontSize: 14, color: _kSecondary)),
            const SizedBox(height: 8),
            // Price & rating & TMDA
            Row(
              children: [
                Text('TZS ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(width: 12),
                if (product.rating > 0) ...[
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                  const SizedBox(width: 2),
                  Text(product.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
                const Spacer(),
                if (product.isTmdaApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF4CAF50)),
                        SizedBox(width: 4),
                        Text('TMDA Imeidhinishwa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Description
            if (product.description != null) ...[
              Text(product.description!, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.5)),
              const SizedBox(height: 16),
            ],
            // Skin types
            if (product.skinTypes.isNotEmpty) ...[
              const Text('Inafaa kwa:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: product.skinTypes.map((t) => Chip(
                      label: Text(t.displayName, style: const TextStyle(fontSize: 11)),
                      avatar: Icon(t.icon, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Concerns
            if (product.concerns.isNotEmpty) ...[
              const Text('Inasaidia:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: product.concerns.map((c) => Chip(
                      label: Text(c.displayName, style: const TextStyle(fontSize: 11)),
                      avatar: Icon(c.icon, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Ingredients
            if (product.ingredients.isNotEmpty) ...[
              const Text('Viambato:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.ingredients.join(', '),
                  style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bidhaa za Ngozi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: _kPrimary, size: 22),
            onPressed: _showFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (q) {
                    _searchQuery = q.trim();
                    _loadProducts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Tafuta bidhaa...',
                    hintStyle: TextStyle(fontSize: 13, color: _kSecondary.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _kSecondary),
                    filled: true,
                    fillColor: _kCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              // Category tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: _kPrimary,
                unselectedLabelColor: _kSecondary,
                indicatorColor: _kPrimary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabAlignment: TabAlignment.start,
                tabs: _categories.map((c) => Tab(text: c.label)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_rounded, size: 48, color: _kSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text('Hakuna bidhaa zilizopatikana', style: TextStyle(fontSize: 14, color: _kSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ProductTile(
                          product: _products[index],
                          onTap: () => _showProductDetail(_products[index]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _Category {
  final String key;
  final String label;
  const _Category(this.key, this.label);
}
