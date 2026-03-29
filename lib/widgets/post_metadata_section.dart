import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';

/// Categories for content classification. Maps to content_documents.category.
const List<String> kContentCategories = [
  'entertainment',
  'news',
  'sports',
  'business',
  'technology',
  'education',
  'lifestyle',
  'music',
  'comedy',
  'fashion',
  'food',
  'travel',
  'health',
  'politics',
  'religion',
  'culture',
  'agriculture',
  'other',
];

/// Swahili labels for categories.
const Map<String, String> kCategoryLabelsSw = {
  'entertainment': 'Burudani',
  'news': 'Habari',
  'sports': 'Michezo',
  'business': 'Biashara',
  'technology': 'Teknolojia',
  'education': 'Elimu',
  'lifestyle': 'Maisha',
  'music': 'Muziki',
  'comedy': 'Vichekesho',
  'fashion': 'Mitindo',
  'food': 'Chakula',
  'travel': 'Safari',
  'health': 'Afya',
  'politics': 'Siasa',
  'religion': 'Dini',
  'culture': 'Utamaduni',
  'agriculture': 'Kilimo',
  'other': 'Nyingine',
};

const Map<String, String> kCategoryLabelsEn = {
  'entertainment': 'Entertainment',
  'news': 'News',
  'sports': 'Sports',
  'business': 'Business',
  'technology': 'Technology',
  'education': 'Education',
  'lifestyle': 'Lifestyle',
  'music': 'Music',
  'comedy': 'Comedy',
  'fashion': 'Fashion',
  'food': 'Food',
  'travel': 'Travel',
  'health': 'Health',
  'politics': 'Politics',
  'religion': 'Religion',
  'culture': 'Culture',
  'agriculture': 'Agriculture',
  'other': 'Other',
};

/// Compact metadata section for post creation screens.
/// Shows category dropdown and optional location field.
class PostMetadataSection extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final TextEditingController? locationController;

  const PostMetadataSection({
    super.key,
    this.selectedCategory,
    required this.onCategoryChanged,
    this.locationController,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final isSw = strings?.isSwahili ?? false;
    final labels = isSw ? kCategoryLabelsSw : kCategoryLabelsEn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Category dropdown
        DropdownButtonFormField<String>(
          initialValue: selectedCategory,
          decoration: InputDecoration(
            labelText:
                isSw ? 'Aina ya maudhui' : 'Content category',
            labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: Text(
            isSw ? 'Chagua aina...' : 'Choose category...',
            style: const TextStyle(color: Colors.black38, fontSize: 14),
          ),
          items: kContentCategories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(labels[cat] ?? cat,
                  style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onCategoryChanged,
          isExpanded: true,
          icon:
              const Icon(Icons.expand_more_rounded, color: Colors.black54),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(height: 12),
        // Location text field
        if (locationController != null)
          TextField(
            controller: locationController,
            decoration: InputDecoration(
              labelText: isSw ? 'Mahali' : 'Location',
              labelStyle:
                  const TextStyle(fontSize: 13, color: Colors.black54),
              hintText: isSw
                  ? 'k.m. Dar es Salaam, Kariakoo'
                  : 'e.g. Dar es Salaam, Kariakoo',
              hintStyle:
                  const TextStyle(color: Colors.black26, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: const Icon(Icons.location_on_outlined,
                  size: 20, color: Colors.black38),
            ),
            style: const TextStyle(fontSize: 14),
          ),
      ],
    );
  }
}
