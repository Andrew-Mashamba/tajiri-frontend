import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kError = Color(0xFFDC2626);

// ─── Bilingual label helper ─────────────────────────────────────────────

String _productTypeLabel(BuildContext context, ProductType type) {
  final s = AppStringsScope.of(context);
  switch (type) {
    case ProductType.physical:
      return s?.productTypePhysical ?? 'Physical';
    case ProductType.digital:
      return s?.productTypeDigital ?? 'Digital';
    case ProductType.service:
      return s?.productTypeService ?? 'Service';
  }
}

/// Screen for creating a new product listing
class CreateProductScreen extends StatefulWidget {
  final int currentUserId;

  const CreateProductScreen({super.key, required this.currentUserId});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ShopService _shopService = ShopService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _comparePriceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryNotesController = TextEditingController();

  // State
  ProductType _productType = ProductType.physical;
  ProductCondition _condition = ProductCondition.brandNew;
  final List<File> _images = [];
  List<ProductCategory> _categories = [];
  int? _selectedCategoryId;
  bool _allowPickup = true;
  bool _allowDelivery = false;
  bool _allowShipping = false;
  bool _isLoading = false;
  bool _isSaving = false;

  Timer? _autoSaveTimer;
  static const _draftKey = 'shop_product_draft';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDraft();
    _titleController.addListener(_scheduleSave);
    _descriptionController.addListener(_scheduleSave);
    _priceController.addListener(_scheduleSave);
    _comparePriceController.addListener(_scheduleSave);
    _stockController.addListener(_scheduleSave);
    _locationController.addListener(_scheduleSave);
    _deliveryFeeController.addListener(_scheduleSave);
    _pickupAddressController.addListener(_scheduleSave);
    _deliveryNotesController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _stockController.dispose();
    _locationController.dispose();
    _deliveryFeeController.dispose();
    _pickupAddressController.dispose();
    _deliveryNotesController.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final draft = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'price': _priceController.text,
      'comparePrice': _comparePriceController.text,
      'stock': _stockController.text,
      'location': _locationController.text,
      'deliveryFee': _deliveryFeeController.text,
      'pickupAddress': _pickupAddressController.text,
      'deliveryNotes': _deliveryNotesController.text,
      'productType': _productType.value,
      'condition': _condition.value,
      'allowPickup': _allowPickup,
      'allowDelivery': _allowDelivery,
      'allowShipping': _allowShipping,
      'categoryId': _selectedCategoryId,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft));
    debugPrint('[CreateProduct] Draft auto-saved');
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return;
    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      // Only restore if there is meaningful content
      final hasContent = (draft['title'] as String?)?.isNotEmpty == true ||
          (draft['description'] as String?)?.isNotEmpty == true ||
          (draft['price'] as String?)?.isNotEmpty == true;
      if (!hasContent) return;
      setState(() {
        _titleController.text = draft['title'] as String? ?? '';
        _descriptionController.text = draft['description'] as String? ?? '';
        _priceController.text = draft['price'] as String? ?? '';
        _comparePriceController.text = draft['comparePrice'] as String? ?? '';
        _stockController.text = (draft['stock'] as String?)?.isNotEmpty == true
            ? draft['stock'] as String
            : '1';
        _locationController.text = draft['location'] as String? ?? '';
        _deliveryFeeController.text = draft['deliveryFee'] as String? ?? '';
        _pickupAddressController.text = draft['pickupAddress'] as String? ?? '';
        _deliveryNotesController.text = draft['deliveryNotes'] as String? ?? '';
        _productType = ProductType.fromString(draft['productType'] as String?);
        _condition = ProductCondition.fromString(draft['condition'] as String?);
        _allowPickup = draft['allowPickup'] as bool? ?? true;
        _allowDelivery = draft['allowDelivery'] as bool? ?? false;
        _allowShipping = draft['allowShipping'] as bool? ?? false;
        if (draft['categoryId'] != null) {
          _selectedCategoryId = draft['categoryId'] as int?;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft restored'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final result = await _shopService.getCategories();
    if (mounted) {
      setState(() {
        if (result.success) {
          _categories = result.categories;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final s = AppStringsScope.of(context);

    if (_images.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.maxImagesReached ?? 'Maximum 10 images allowed')),
      );
      return;
    }

    final picked = await _imagePicker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked.isNotEmpty) {
      final remaining = 10 - _images.length;
      final toAdd = picked.take(remaining).map((xf) => File(xf.path)).toList();
      setState(() {
        _images.addAll(toAdd);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.addAtLeastOneImage ?? 'Please add at least one image')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await _shopService.createProduct(
      sellerId: widget.currentUserId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      type: _productType,
      price: double.tryParse(_priceController.text) ?? 0,
      compareAtPrice: _comparePriceController.text.isNotEmpty
          ? double.tryParse(_comparePriceController.text)
          : null,
      stockQuantity: int.tryParse(_stockController.text) ?? 1,
      categoryId: _selectedCategoryId,
      condition: _condition,
      locationName: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      allowPickup: _allowPickup,
      allowDelivery: _allowDelivery,
      allowShipping: _allowShipping,
      deliveryFee: _deliveryFeeController.text.isNotEmpty
          ? double.tryParse(_deliveryFeeController.text)
          : null,
      pickupAddress: _pickupAddressController.text.trim().isNotEmpty
          ? _pickupAddressController.text.trim()
          : null,
      deliveryNotes: _deliveryNotesController.text.trim().isNotEmpty
          ? _deliveryNotesController.text.trim()
          : null,
      images: _images,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result.success) {
      await _clearDraft();
      if (!mounted) return;
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.productCreated ?? 'Product created successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to create product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const HeroIcon(HeroIcons.xMark, style: HeroIconStyle.outline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s?.addProduct ?? 'Add Product',
          style: const TextStyle(
            color: _kPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProduct,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      s?.save ?? 'Save',
                      style: const TextStyle(
                        color: _kPrimaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Images Section
              _buildImagesSection(s),
              const SizedBox(height: 24),

              // Basic Info Section
              _buildSectionTitle(s?.basicInfo ?? 'Basic Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: s?.productTitle ?? 'Product Title',
                hint: s?.productTitleHint ?? 'Enter product name',
                validator: (v) => v?.trim().isEmpty == true
                    ? (s?.requiredField ?? 'This field is required')
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: s?.description ?? 'Description',
                hint: s?.descriptionHint ?? 'Describe your product...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Product Type
              _buildProductTypeSelector(s),
              const SizedBox(height: 16),

              // Category
              _buildCategorySelector(s),
              const SizedBox(height: 16),

              // Condition (for physical products)
              if (_productType == ProductType.physical) ...[
                _buildConditionSelector(s),
                const SizedBox(height: 16),
              ],

              // Pricing Section
              const SizedBox(height: 8),
              _buildSectionTitle(s?.pricing ?? 'Pricing'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: s?.price ?? 'Price (TZS)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v?.trim().isEmpty == true) {
                          return s?.requiredField ?? 'Required';
                        }
                        final price = double.tryParse(v ?? '');
                        if (price == null || price <= 0) {
                          return s?.invalidPrice ?? 'Invalid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _comparePriceController,
                      label: s?.comparePrice ?? 'Compare Price',
                      hint: s?.optional ?? 'Optional',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock (for physical products)
              if (_productType == ProductType.physical) ...[
                _buildTextField(
                  controller: _stockController,
                  label: s?.stockQuantity ?? 'Stock Quantity',
                  hint: '1',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
              ],

              // Location & Delivery Section
              if (_productType == ProductType.physical) ...[
                const SizedBox(height: 8),
                _buildSectionTitle(s?.locationDelivery ?? 'Location & Delivery'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _locationController,
                  label: s?.location ?? 'Location',
                  hint: s?.locationHint ?? 'e.g., Dar es Salaam',
                ),
                const SizedBox(height: 16),
                _buildDeliveryOptions(s),
                const SizedBox(height: 16),
                if (_allowPickup)
                  _buildTextField(
                    controller: _pickupAddressController,
                    label: s?.pickupAddress ?? 'Pickup Address',
                    hint: s?.pickupAddressHint ?? 'Where can buyers pick up?',
                  ),
                if (_allowDelivery || _allowShipping) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _deliveryFeeController,
                    label: s?.deliveryFee ?? 'Delivery Fee (TZS)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _deliveryNotesController,
                    label: s?.deliveryNotes ?? 'Delivery Notes',
                    hint: s?.deliveryNotesHint ?? 'Delivery terms, areas covered, etc.',
                    maxLines: 2,
                  ),
                ],
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _kPrimaryText,
      ),
    );
  }

  Widget _buildImagesSection(AppStrings? s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(s?.productImages ?? 'Product Images'),
        const SizedBox(height: 4),
        Text(
          s?.imagesHint ?? 'Add up to 10 images. First image will be the cover.',
          style: const TextStyle(fontSize: 13, color: _kSecondaryText),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kDivider, width: 2, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HeroIcon(HeroIcons.camera, size: 28, color: _kSecondaryText),
                      const SizedBox(height: 4),
                      Text(
                        '${_images.length}/10',
                        style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                      ),
                    ],
                  ),
                ),
              ),
              // Image previews
              ..._images.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kPrimaryText,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s?.cover ?? 'Cover',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: _kError,
                              shape: BoxShape.circle,
                            ),
                            child: const HeroIcon(
                              HeroIcons.xMark,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimaryText,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kTertiaryText),
            filled: true,
            fillColor: _kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimaryText, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kError),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTypeSelector(AppStrings? s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s?.productType ?? 'Product Type',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ProductType.values.map((type) {
            final isSelected = type == _productType;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != ProductType.values.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _productType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimaryText : _kSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _kPrimaryText : _kDivider,
                      ),
                    ),
                    child: Text(
                      _productTypeLabel(context, type),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : _kSecondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(AppStrings? s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s?.category ?? 'Category',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimaryText,
          ),
        ),
        const SizedBox(height: 6),
        if (_isLoading)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDivider),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDivider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedCategoryId,
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    s?.selectCategory ?? 'Select category',
                    style: const TextStyle(color: _kTertiaryText),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(s?.noCategory ?? 'No category'),
                  ),
                  ..._categories.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConditionSelector(AppStrings? s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s?.condition ?? 'Condition',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ProductCondition.values.map((cond) {
            final isSelected = cond == _condition;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: cond != ProductCondition.values.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _condition = cond),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimaryText : _kSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _kPrimaryText : _kDivider,
                      ),
                    ),
                    child: Text(
                      cond.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : _kSecondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeliveryOptions(AppStrings? s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s?.deliveryOptions ?? 'Delivery Options',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        _buildCheckOption(
          label: s?.allowPickup ?? 'Allow Pickup',
          value: _allowPickup,
          onChanged: (v) => setState(() => _allowPickup = v ?? false),
        ),
        _buildCheckOption(
          label: s?.allowDelivery ?? 'Allow Delivery',
          value: _allowDelivery,
          onChanged: (v) => setState(() => _allowDelivery = v ?? false),
        ),
        _buildCheckOption(
          label: s?.allowShipping ?? 'Allow Shipping',
          value: _allowShipping,
          onChanged: (v) => setState(() => _allowShipping = v ?? false),
        ),
      ],
    );
  }

  Widget _buildCheckOption({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: _kPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: _kPrimaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
