// lib/widgets/tagged_product_picker.dart
//
// UN-012 — strategy posts.md §X. Lets a creator tag shop products on a
// post during composing. Lists their own products; tapping toggles the
// product in/out of the draft. The composer collects the drafts and
// after Post::create calls PostTaggedProductService.attach.
//
// Engineering playbook: monochrome, 48dp targets, _rounded icons,
// AppStringsScope bilingual, maxLines+ellipsis.

import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';
import '../models/shop_models.dart';
import '../services/post_tagged_product_service.dart';
import '../services/shop_service.dart';

class TaggedProductPicker extends StatefulWidget {
  final int currentUserId;
  final ValueChanged<List<TaggedProductDraft>> onChanged;

  const TaggedProductPicker({
    super.key,
    required this.currentUserId,
    required this.onChanged,
  });

  @override
  State<TaggedProductPicker> createState() => _TaggedProductPickerState();
}

class _TaggedProductPickerState extends State<TaggedProductPicker> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kIconBg = Color(0xFFF5F5F5);

  final ShopService _shop = ShopService();
  List<Product> _myProducts = const [];
  final Set<int> _selectedIds = {};
  bool _loading = false;
  bool _expanded = false;

  Future<void> _hydrate() async {
    if (_myProducts.isNotEmpty) return;
    setState(() => _loading = true);
    final result = await _shop.getSellerProducts(widget.currentUserId, perPage: 30);
    if (!mounted) return;
    setState(() {
      _myProducts = result.products;
      _loading = false;
    });
  }

  void _toggle(int productId) {
    setState(() {
      if (_selectedIds.contains(productId)) {
        _selectedIds.remove(productId);
      } else {
        _selectedIds.add(productId);
      }
    });
    widget.onChanged(
      _selectedIds
          .map((id) => TaggedProductDraft(productId: id))
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded) _hydrate();
            },
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, size: 18, color: _kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSw ? 'Bidhaa zilizotambulishwa' : 'Tagged products',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kIconBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedIds.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 22,
                  color: _kSecondary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Text(
              isSw
                  ? 'Watumiaji wakitazama bidhaa kutoka chapisho hili, utapata mapato.'
                  : 'When viewers expand a tagged product, you earn product_expand·author.',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                ),
              )
            else if (_myProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  isSw
                      ? 'Hauna bidhaa kwenye duka lako bado.'
                      : 'You have no products in your shop yet.',
                  style: const TextStyle(fontSize: 13, color: _kTertiary),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _myProducts.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _kBorder),
                  itemBuilder: (_, i) {
                    final p = _myProducts[i];
                    final selected = _selectedIds.contains(p.id);
                    return InkWell(
                      onTap: () => _toggle(p.id),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _kIconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                size: 18,
                                color: _kPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${p.price.toStringAsFixed(0)} TZS',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _kTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 22,
                              color: selected ? _kPrimary : _kTertiary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
