// lib/business/widgets/business_switcher.dart
import 'package:flutter/material.dart';
import '../models/business_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class BusinessSwitcher extends StatelessWidget {
  final List<Business> businesses;
  final Business? selected;
  final ValueChanged<Business> onChanged;
  final VoidCallback? onAddNew;

  const BusinessSwitcher({
    super.key,
    required this.businesses,
    this.selected,
    required this.onChanged,
    this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_rounded, size: 20, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selected?.id,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _kSecondary),
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  ...businesses.map((b) => DropdownMenuItem<int>(
                        value: b.id,
                        child: Text(
                          b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                  if (onAddNew != null)
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 18, color: _kSecondary),
                          SizedBox(width: 8),
                          Text('Ongeza Biashara',
                              style: TextStyle(
                                  color: _kSecondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                ],
                onChanged: (val) {
                  if (val == -1 && onAddNew != null) {
                    onAddNew!();
                    return;
                  }
                  final biz = businesses.firstWhere(
                    (b) => b.id == val,
                    orElse: () => businesses.first,
                  );
                  onChanged(biz);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
