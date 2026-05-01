import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tajirika_models.dart';
import '../services/partner_product_service.dart';
import '../widgets/partner_product_card.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Buyer-facing store page showing all products for a specific partner.
class PartnerStorePage extends StatefulWidget {
  final int partnerId;
  final String? skillCategory;

  const PartnerStorePage({
    super.key,
    required this.partnerId,
    this.skillCategory,
  });

  @override
  State<PartnerStorePage> createState() => _PartnerStorePageState();
}

class _PartnerStorePageState extends State<PartnerStorePage> {
  List<PartnerProduct> _products = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();

  String? _partnerName;
  String? _partnerPhotoUrl;
  int? _partnerRatingScore;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await PartnerProductService.listProducts(
      partnerId: widget.partnerId,
      skillCategory: widget.skillCategory,
      activeOnly: true,
      limit: 100,
    );
    if (!mounted) return;
    if (res.success) {
      _products = res.products;
      if (_products.isNotEmpty) {
        final first = _products.first;
        _partnerName = first.partnerName;
        _partnerPhotoUrl = first.partnerPhotoUrl;
        _partnerRatingScore = first.partnerJobSuccessScore;
      }
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _isLoading = false;
        _error = res.message ?? 'Failed';
      });
    }
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final res = await PartnerProductService.listProducts(
      partnerId: widget.partnerId,
      skillCategory: widget.skillCategory,
      activeOnly: true,
      query: query.isEmpty ? null : query,
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success) _products = res.products;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Duka' : 'Store',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isSw),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: isSw ? 'Tafuta bidhaa...' : 'Search products...',
                  prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: _search,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: _kSecondary),
                          ),
                        )
                      : _products.isEmpty
                          ? Center(
                              child: Text(
                                isSw ? 'Hakuna bidhaa' : 'No products',
                                style: const TextStyle(color: _kSecondary),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: _kPrimary,
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _products.length,
                                itemBuilder: (_, i) => PartnerProductCard(
                                  product: _products[i],
                                  showOwnerActions: false,
                                  onTap: () {
                                    // Product detail navigation deferred.
                                  },
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSw) {
    final name = _partnerName ?? (isSw ? 'Mshirika' : 'Partner');
    final photo = _partnerPhotoUrl;
    final rating = _partnerRatingScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: photo != null && photo.isNotEmpty
                ? NetworkImage(photo)
                : null,
            child: photo == null || photo.isEmpty
                ? const Icon(
                    Icons.storefront_rounded,
                    color: _kSecondary,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFFA726),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rating%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
