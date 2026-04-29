import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';
import '../models/shop_models.dart';
import '../services/shop_service.dart';

class ShopCategorySelection {
  final int id;
  final String breadcrumb;
  final int? parentId;
  const ShopCategorySelection({
    required this.id,
    required this.breadcrumb,
    this.parentId,
  });
}

class ShopCategoryPicker extends StatefulWidget {
  final int? initialCategoryId;
  final bool showServicesOnly;

  const ShopCategoryPicker({
    super.key,
    this.initialCategoryId,
    this.showServicesOnly = false,
  });

  static Future<ShopCategorySelection?> show(
    BuildContext context, {
    int? initialCategoryId,
    bool showServicesOnly = false,
  }) {
    return showModalBottomSheet<ShopCategorySelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ShopCategoryPicker(
        initialCategoryId: initialCategoryId,
        showServicesOnly: showServicesOnly,
      ),
    );
  }

  @override
  State<ShopCategoryPicker> createState() => _ShopCategoryPickerState();
}

class _ShopCategoryPickerState extends State<ShopCategoryPicker> {
  final ShopService _shop = ShopService();
  List<ProductCategory> _roots = [];
  ProductCategory? _drilledRoot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await _shop.getCategoriesCached();
      if (!mounted) return;
      setState(() {
        _roots = cats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _selectCategory(ProductCategory cat, {ProductCategory? parent}) {
    final breadcrumb = parent != null ? '${parent.name} > ${cat.name}' : cat.name;
    Navigator.pop(
      context,
      ShopCategorySelection(
        id: cat.id,
        breadcrumb: breadcrumb,
        parentId: parent?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildHeader(isSwahili),
            const Divider(height: 1),
            Flexible(child: _buildBody(isSwahili)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSwahili) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        children: [
          if (_drilledRoot != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _drilledRoot = null),
              tooltip: isSwahili ? 'Rudi' : 'Back',
            ),
          Expanded(
            child: Text(
              _drilledRoot?.name ??
                  (isSwahili ? 'Chagua jamii' : 'Select category'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isSwahili) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(isSwahili ? 'Imeshindwa kupakia jamii' : 'Failed to load categories',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              child: Text(isSwahili ? 'Jaribu tena' : 'Retry'),
            ),
          ]),
        ),
      );
    }
    if (_roots.isEmpty) {
      return Center(
        child: Text(
          isSwahili ? 'Hakuna jamii' : 'No categories',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_drilledRoot != null) {
      final children = _drilledRoot!.children ?? [];
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.folder_outlined, color: Color(0xFF1A1A1A)),
            title: Text(isSwahili
                ? 'Jumla ya ${_drilledRoot!.name}'
                : 'All ${_drilledRoot!.name}'),
            subtitle: Text(isSwahili ? 'Chagua jamii kuu' : 'Select parent category only'),
            onTap: () => _selectCategory(_drilledRoot!),
          ),
          if (children.isNotEmpty) const Divider(height: 1),
          ...children.map((c) => ListTile(
                leading: const Icon(Icons.label_outline, color: Color(0xFF1A1A1A)),
                title: Text(c.name),
                trailing: c.productCount > 0
                    ? Text('${c.productCount}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12))
                    : null,
                onTap: () => _selectCategory(c, parent: _drilledRoot),
              )),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _roots.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final cat = _roots[i];
        final hasChildren = cat.hasChildren;
        return ListTile(
          leading: const Icon(Icons.category_outlined, color: Color(0xFF1A1A1A)),
          title: Text(cat.name),
          trailing: hasChildren
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null,
          onTap: () {
            if (hasChildren) {
              setState(() => _drilledRoot = cat);
            } else {
              _selectCategory(cat);
            }
          },
        );
      },
    );
  }
}
