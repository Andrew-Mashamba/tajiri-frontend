import 'package:flutter/material.dart';
import '../../models/shop_models.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kDivider = Color(0xFFE0E0E0);

class ShopFilterResult {
  final double? minPrice;
  final double? maxPrice;
  final ProductCondition? condition;
  final double? minRating;
  final ProductType? type;

  const ShopFilterResult({this.minPrice, this.maxPrice, this.condition, this.minRating, this.type});
}

class FilterBottomSheet extends StatefulWidget {
  final ShopFilterResult? currentFilters;
  final void Function(ShopFilterResult) onApply;

  const FilterBottomSheet({super.key, this.currentFilters, required this.onApply});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  ProductCondition? _condition;
  double? _minRating;
  ProductType? _type;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.currentFilters?.minPrice ?? 0,
      widget.currentFilters?.maxPrice ?? 5000000,
    );
    _condition = widget.currentFilters?.condition;
    _minRating = widget.currentFilters?.minRating;
    _type = widget.currentFilters?.type;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryText)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 5000000);
                    _condition = null;
                    _minRating = null;
                    _type = null;
                  });
                },
                child: const Text('Clear All', style: TextStyle(color: Color(0xFF999999))),
              ),
            ],
          ),
          const Divider(color: _kDivider),

          // Price range
          const SizedBox(height: 8),
          const Text('Price Range (TZS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000000,
            divisions: 100,
            activeColor: _kPrimaryText,
            labels: RangeLabels(
              '${(_priceRange.start / 1000).toStringAsFixed(0)}K',
              '${(_priceRange.end / 1000).toStringAsFixed(0)}K',
            ),
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(_priceRange.start / 1000).toStringAsFixed(0)}K TZS', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
              Text('${(_priceRange.end / 1000).toStringAsFixed(0)}K TZS', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            ],
          ),

          // Condition
          const SizedBox(height: 16),
          const Text('Condition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, ...ProductCondition.values].map((c) {
              final selected = _condition == c;
              final label = c == null ? 'All' : c == ProductCondition.brandNew ? 'New' : c == ProductCondition.used ? 'Used' : 'Refurbished';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                selectedColor: _kPrimaryText,
                labelStyle: TextStyle(color: selected ? Colors.white : _kPrimaryText),
                onSelected: (_) => setState(() => _condition = c),
              );
            }).toList(),
          ),

          // Rating
          const SizedBox(height: 16),
          const Text('Minimum Rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, 4.0, 3.0, 2.0, 1.0].map((r) {
              final selected = _minRating == r;
              final label = r == null ? 'Any' : '${r.toStringAsFixed(0)}+ \u2605';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                selectedColor: _kPrimaryText,
                labelStyle: TextStyle(color: selected ? Colors.white : _kPrimaryText),
                onSelected: (_) => setState(() => _minRating = r),
              );
            }).toList(),
          ),

          // Apply button
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(ShopFilterResult(
                  minPrice: _priceRange.start > 0 ? _priceRange.start : null,
                  maxPrice: _priceRange.end < 5000000 ? _priceRange.end : null,
                  condition: _condition,
                  minRating: _minRating,
                  type: _type,
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
