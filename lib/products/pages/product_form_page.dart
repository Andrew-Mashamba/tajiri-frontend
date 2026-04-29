import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/shop_category_picker.dart';
import '../models/product_models.dart';
import '../services/product_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);

class ProductFormPage extends StatefulWidget {
  final int businessId;
  final bool isDefaultShop;
  final int userId;
  final String token;
  final BusinessProduct? product;

  const ProductFormPage({
    super.key,
    required this.businessId,
    required this.isDefaultShop,
    required this.userId,
    required this.token,
    this.product,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _uploadProgress;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _compareAtCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _deliveryFeeCtrl;
  late final TextEditingController _deliveryNotesCtrl;
  late final TextEditingController _pickupAddressCtrl;
  late final TextEditingController _downloadUrlCtrl;
  late final TextEditingController _downloadLimitCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _serviceLocationCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _categoryCtrl;

  ProductType _type = ProductType.physical;
  ProductStatus _status = ProductStatus.active;
  ProductCondition _condition = ProductCondition.brandNew;
  String _currency = 'TZS';
  bool _allowPickup = true;
  bool _allowDelivery = false;
  bool _allowShipping = false;

  List<Object> _allImages = []; // String for existing URLs, XFile for new picks
  int? _selectedCategoryId;
  String? _categoryBreadcrumb;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isEditing => widget.product != null;

  bool get _canSave =>
      _titleCtrl.text.trim().isNotEmpty && _priceCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _compareAtCtrl = TextEditingController(
        text: p?.compareAtPrice != null ? p!.compareAtPrice!.toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stockQuantity.toString() : '0');
    _locationCtrl = TextEditingController(text: p?.locationName ?? '');
    _deliveryFeeCtrl = TextEditingController(
        text: p?.deliveryFee != null ? p!.deliveryFee!.toStringAsFixed(0) : '');
    _deliveryNotesCtrl = TextEditingController(text: p?.deliveryNotes ?? '');
    _pickupAddressCtrl = TextEditingController(text: p?.pickupAddress ?? '');
    _downloadUrlCtrl = TextEditingController(text: p?.downloadUrl ?? '');
    _downloadLimitCtrl = TextEditingController(
        text: p?.downloadLimit != null ? p!.downloadLimit!.toString() : '');
    _durationCtrl = TextEditingController(
        text: p?.durationMinutes != null ? p!.durationMinutes!.toString() : '');
    _serviceLocationCtrl = TextEditingController(text: p?.serviceLocation ?? '');
    _tagsCtrl = TextEditingController(text: p?.tags.join(', ') ?? '');
    _categoryCtrl = TextEditingController(text: p?.categoryName ?? '');

    if (p != null) {
      _type = p.type;
      _status = p.status;
      _condition = p.condition;
      _currency = p.currency;
      _allowPickup = p.allowPickup;
      _allowDelivery = p.allowDelivery;
      _allowShipping = p.allowShipping;
      _allImages = List<Object>.from(p.images);
      _selectedCategoryId = p.categoryId;
      _categoryBreadcrumb = p.categoryName;
    }
    _titleCtrl.addListener(() => setState(() {}));
    _priceCtrl.addListener(() => setState(() {}));
    _compareAtCtrl.addListener(() => setState(() {}));
  }

  Future<void> _pickCategory() async {
    final sel = await ShopCategoryPicker.show(
      context,
      initialCategoryId: _selectedCategoryId,
    );
    if (sel == null) return;
    setState(() {
      _selectedCategoryId = sel.id;
      _categoryBreadcrumb = sel.breadcrumb;
      _categoryCtrl.text = sel.breadcrumb;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _compareAtCtrl.dispose(); _stockCtrl.dispose(); _locationCtrl.dispose();
    _deliveryFeeCtrl.dispose(); _deliveryNotesCtrl.dispose();
    _pickupAddressCtrl.dispose(); _downloadUrlCtrl.dispose();
    _downloadLimitCtrl.dispose(); _durationCtrl.dispose();
    _serviceLocationCtrl.dispose(); _tagsCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        final remaining = 10 - _allImages.length;
        _allImages.addAll(picked.take(remaining));
      });
    }
  }

  Future<void> _showPostSaveNudge() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
            const SizedBox(height: 12),
            Text(
              _isSwahili
                  ? (_isEditing ? 'Bidhaa imesasishwa!' : 'Bidhaa imeongezwa!')
                  : (_isEditing ? 'Product updated!' : 'Product saved!'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/create-post');
                },
                icon: const Icon(Icons.share_rounded),
                label: Text(_isSwahili ? 'Shiriki kama Chapisho' : 'Share as Post'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/tea');
                },
                icon: const Icon(Icons.support_agent_rounded, color: _kPrimary),
                label: Text(_isSwahili ? 'Uliza Shangazi kuhusu Bei' : 'Ask Shangazi about Pricing',
                    style: const TextStyle(color: _kPrimary)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/budget');
                },
                icon: const Icon(Icons.account_balance_wallet_outlined, color: _kPrimary),
                label: Text(
                  _isSwahili ? 'Weka Lengo la Mapato' : 'Set Revenue Goal',
                  style: const TextStyle(color: _kPrimary),
                ),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_isSwahili ? 'Maliza' : 'Done',
                  style: const TextStyle(color: _kPrimary)),
            ),
          ],
        ),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_allImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Ongeza picha moja angalau' : 'Add at least one image'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final existingImages = _allImages.whereType<String>().toList();
    final newImages = _allImages.whereType<XFile>().toList();

    setState(() { _saving = true; _uploadProgress = null; });

    final tags = _tagsCtrl.text.split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final product = BusinessProduct(
      id: widget.product?.id ?? 0,
      businessId: widget.businessId,
      isShopProduct: widget.isDefaultShop,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      type: _type,
      status: _status,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      compareAtPrice: _compareAtCtrl.text.isEmpty
          ? null : double.tryParse(_compareAtCtrl.text),
      currency: _currency,
      stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
      categoryId: _selectedCategoryId,
      categoryName: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      condition: _condition,
      locationName: _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
      allowPickup: _allowPickup,
      allowDelivery: _allowDelivery,
      allowShipping: _allowShipping,
      deliveryFee: _deliveryFeeCtrl.text.isEmpty
          ? null : double.tryParse(_deliveryFeeCtrl.text),
      deliveryNotes: _deliveryNotesCtrl.text.isEmpty ? null : _deliveryNotesCtrl.text,
      pickupAddress: _pickupAddressCtrl.text.isEmpty ? null : _pickupAddressCtrl.text,
      downloadUrl: _downloadUrlCtrl.text.isEmpty ? null : _downloadUrlCtrl.text,
      downloadLimit: _downloadLimitCtrl.text.isEmpty
          ? null : int.tryParse(_downloadLimitCtrl.text),
      durationMinutes: _durationCtrl.text.isEmpty
          ? null : int.tryParse(_durationCtrl.text),
      serviceLocation: _serviceLocationCtrl.text.isEmpty ? null : _serviceLocationCtrl.text,
      tags: tags,
      images: existingImages,
    );

    final result = _isEditing
        ? await ProductService.updateProduct(
            token: widget.token,
            businessId: widget.businessId,
            userId: widget.userId,
            isDefaultShop: widget.isDefaultShop,
            product: product,
            newImages: newImages,
            onImageProgress: (current, total) {
              if (mounted) setState(() => _uploadProgress = 'Uploading $current/$total images...');
            },
          )
        : await ProductService.createProduct(
            token: widget.token,
            businessId: widget.businessId,
            userId: widget.userId,
            isDefaultShop: widget.isDefaultShop,
            product: product,
            images: newImages,
            onImageProgress: (current, total) {
              if (mounted) setState(() => _uploadProgress = 'Uploading $current/$total images...');
            },
          );

    if (!mounted) return;
    setState(() { _saving = false; _uploadProgress = null; });

    if (result.success) {
      await _showPostSaveNudge();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? (_isSwahili ? 'Imeshindikana' : 'Failed')),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(_isEditing
            ? (_isSwahili ? 'Hariri Bidhaa' : 'Edit Product')
            : (_isSwahili ? 'Ongeza Bidhaa' : 'Add Product'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
            )
          else
            TextButton(
              onPressed: _canSave ? _save : null,
              child: Text(_isSwahili ? 'Hifadhi' : 'Save',
                  style: TextStyle(
                      color: _canSave ? _kPrimary : Colors.grey,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_saving && _uploadProgress != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))),
                    const SizedBox(width: 10),
                    Text(_uploadProgress!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
                  ]),
                ),
              _section(_isSwahili ? 'Maelezo ya Msingi' : 'Basic Info'),
              _card(Column(children: [
                _field(_titleCtrl, _isSwahili ? 'Jina la bidhaa' : 'Product title',
                    required: true),
                _field(_descCtrl, _isSwahili ? 'Maelezo' : 'Description',
                    maxLines: 3),
                _dropdown<ProductType>(
                  label: _isSwahili ? 'Aina' : 'Type',
                  value: _type,
                  items: [
                    DropdownMenuItem(value: ProductType.physical, child: Text(_isSwahili ? 'Bidhaa halisi' : 'Physical')),
                    DropdownMenuItem(value: ProductType.digital, child: Text(_isSwahili ? 'Dijitali' : 'Digital')),
                    DropdownMenuItem(value: ProductType.service, child: Text(_isSwahili ? 'Huduma' : 'Service')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                if (_type == ProductType.physical)
                  _dropdown<ProductCondition>(
                    label: _isSwahili ? 'Hali' : 'Condition',
                    value: _condition,
                    items: [
                      DropdownMenuItem(value: ProductCondition.brandNew, child: Text(_isSwahili ? 'Mpya kabisa' : 'Brand New')),
                      DropdownMenuItem(value: ProductCondition.used, child: Text(_isSwahili ? 'Imetumika' : 'Used')),
                      DropdownMenuItem(value: ProductCondition.refurbished, child: Text(_isSwahili ? 'Imefanyiwa kazi' : 'Refurbished')),
                    ],
                    onChanged: (v) => setState(() => _condition = v!),
                  ),
                _field(_tagsCtrl, _isSwahili ? 'Lebo (tenganisha kwa koma)' : 'Tags (comma-separated)'),
                _buildCategoryPickerTile(),
              ])),

              _section(_isSwahili ? 'Bei' : 'Pricing'),
              _card(Column(children: [
                _dropdown<String>(
                  label: _isSwahili ? 'Sarafu' : 'Currency',
                  value: _currency,
                  items: const [
                    DropdownMenuItem(value: 'TZS', child: Text('TZS — Tanzanian Shilling')),
                    DropdownMenuItem(value: 'USD', child: Text('USD — US Dollar')),
                    DropdownMenuItem(value: 'KES', child: Text('KES — Kenyan Shilling')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR — Euro')),
                    DropdownMenuItem(value: 'GBP', child: Text('GBP — British Pound')),
                  ],
                  onChanged: (v) => setState(() => _currency = v!),
                ),
                _field(_priceCtrl, _currency, required: true, keyboardType: TextInputType.number,
                    prefix: '$_currency '),
                _field(_compareAtCtrl, _isSwahili ? 'Bei ya awali (optional)' : 'Compare at price',
                    keyboardType: TextInputType.number, prefix: '$_currency '),
                if (_priceCtrl.text.trim().isNotEmpty && _compareAtCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$_currency ${_compareAtCtrl.text.trim()}  →  $_currency ${_priceCtrl.text.trim()}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ])),

              _section(_isSwahili ? 'Picha' : 'Images'),
              _card(_buildImagePicker()),

              if (_type == ProductType.physical || _type == ProductType.service) ...[
                _section(_isSwahili ? 'Stoki' : 'Stock'),
                _card(Column(children: [
                  _field(_stockCtrl, _isSwahili ? 'Idadi ya stoki' : 'Stock quantity',
                      keyboardType: TextInputType.number),
                  _dropdown<ProductStatus>(
                    label: _isSwahili ? 'Hali ya orodha' : 'Listing status',
                    value: _status,
                    items: [
                      DropdownMenuItem(value: ProductStatus.active, child: Text(_isSwahili ? 'Hai' : 'Active')),
                      DropdownMenuItem(value: ProductStatus.draft, child: Text(_isSwahili ? 'Rasimu' : 'Draft')),
                      DropdownMenuItem(value: ProductStatus.soldOut, child: Text(_isSwahili ? 'Imeisha' : 'Sold Out')),
                      DropdownMenuItem(value: ProductStatus.archived, child: Text(_isSwahili ? 'Imehifadhiwa' : 'Archived')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ])),
              ] else ...[
                _section(_isSwahili ? 'Hali ya Orodha' : 'Listing Status'),
                _card(_dropdown<ProductStatus>(
                  label: _isSwahili ? 'Hali ya orodha' : 'Listing status',
                  value: _status,
                  items: [
                    DropdownMenuItem(value: ProductStatus.active, child: Text(_isSwahili ? 'Hai' : 'Active')),
                    DropdownMenuItem(value: ProductStatus.draft, child: Text(_isSwahili ? 'Rasimu' : 'Draft')),
                    DropdownMenuItem(value: ProductStatus.archived, child: Text(_isSwahili ? 'Imehifadhiwa' : 'Archived')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                )),
              ],

              _section(_isSwahili ? 'Utoaji' : 'Delivery'),
              _card(Column(children: [
                SwitchListTile(
                  value: _allowPickup, activeColor: _kPrimary,
                  title: Text(_isSwahili ? 'Kuchukua' : 'Pickup available'),
                  onChanged: (v) => setState(() => _allowPickup = v),
                ),
                if (_allowPickup)
                  _field(_pickupAddressCtrl, _isSwahili ? 'Mahali pa kuchukua' : 'Pickup address'),
                SwitchListTile(
                  value: _allowDelivery, activeColor: _kPrimary,
                  title: Text(_isSwahili ? 'Uwasilishaji' : 'Delivery available'),
                  onChanged: (v) => setState(() => _allowDelivery = v),
                ),
                if (_allowDelivery) ...[
                  _field(_deliveryFeeCtrl, _isSwahili ? 'Ada ya uwasilishaji' : 'Delivery fee',
                      keyboardType: TextInputType.number, prefix: 'TZS '),
                  _field(_deliveryNotesCtrl, _isSwahili ? 'Maelezo ya utoaji' : 'Delivery notes'),
                ],
                SwitchListTile(
                  value: _allowShipping, activeColor: _kPrimary,
                  title: Text(_isSwahili ? 'Usafirishaji' : 'Shipping available'),
                  onChanged: (v) => setState(() => _allowShipping = v),
                ),
              ])),

              if (_type == ProductType.physical) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: _card(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSwahili ? 'Mahali' : 'Location',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationCtrl,
                        decoration: InputDecoration(
                          hintText: _isSwahili ? 'Mji, Mtaa...' : 'City, Neighborhood...',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  )),
                ),
              ],

              if (_type == ProductType.digital) ...[
                _section(_isSwahili ? 'Dijitali' : 'Digital'),
                _card(Column(children: [
                  _field(_downloadUrlCtrl, 'Download URL'),
                  _field(_downloadLimitCtrl, _isSwahili ? 'Kikomo cha upakuaji' : 'Download limit',
                      keyboardType: TextInputType.number),
                ])),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final count = _allImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 88,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            itemCount: count + (count < 10 ? 1 : 0),
            onReorder: (oldIndex, newIndex) {
              if (oldIndex >= count || newIndex > count) return;
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _allImages.removeAt(oldIndex);
                _allImages.insert(newIndex, item);
              });
            },
            itemBuilder: (_, i) {
              if (i == count) {
                return SizedBox(
                  key: const ValueKey('add_btn'),
                  width: 72,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }
              final item = _allImages[i];
              return ReorderableDragStartListener(
                key: ValueKey('img_$i'),
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _imageThumb(
                    child: item is String
                        ? Image.network(item, width: 72, height: 72, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                        : Image.file(File((item as XFile).path), width: 72, height: 72,
                            fit: BoxFit.cover),
                    onRemove: () async {
                      if (_allImages.length == 1) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(_isSwahili ? 'Futa Picha?' : 'Remove Photo?'),
                            content: Text(_isSwahili
                                ? 'Bidhaa bila picha haionyeshwi vizuri.'
                                : 'Products without a photo get less visibility.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(_isSwahili ? 'Acha' : 'Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(_isSwahili ? 'Futa' : 'Remove',
                                    style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                      }
                      setState(() => _allImages.removeAt(i));
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text('$count / 10  •  ${_isSwahili ? "Buruta kupanga upya" : "Drag to reorder"}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _imageThumb({required Widget child, required Future<void> Function() onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 72, height: 72, child: child)),
        Positioned(
          top: 0, right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPickerTile() {
    final hasSelection = _selectedCategoryId != null && _categoryBreadcrumb != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickCategory,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.category_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isSwahili ? 'Jamii' : 'Category',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(
                      hasSelection
                          ? _categoryBreadcrumb!
                          : (_isSwahili ? 'Chagua jamii ya duka' : 'Select shop category'),
                      style: TextStyle(
                        fontSize: 14,
                        color: hasSelection ? _kPrimary : Colors.grey,
                        fontWeight: hasSelection ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasSelection)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    _selectedCategoryId = null;
                    _categoryBreadcrumb = null;
                    _categoryCtrl.text = '';
                  }),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: _kPrimary, letterSpacing: 0.5)),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1,
       TextInputType? keyboardType, String? prefix, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? (_isSwahili ? 'Hii inahitajika' : 'Required')
                : null
            : null,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}
