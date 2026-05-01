import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/service_taxonomy_service.dart';

/// Spec F1 #1 — Three-tier service taxonomy picker.
///
/// Bottom-sheet picker with three modes:
///   1. Type-to-search (debounced) → flat results across all levels.
///   2. Browse: Category → Service Type → Service drill-down.
/// Returns the selected `TaxonomyNode` to the caller.
class ServiceTaxonomyPicker extends StatefulWidget {
  const ServiceTaxonomyPicker({super.key});

  static Future<TaxonomyNode?> show(BuildContext context) {
    return showModalBottomSheet<TaxonomyNode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: ServiceTaxonomyPicker(),
      ),
    );
  }

  @override
  State<ServiceTaxonomyPicker> createState() => _ServiceTaxonomyPickerState();
}

class _ServiceTaxonomyPickerState extends State<ServiceTaxonomyPicker> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<TaxonomyNode> _searchResults = const [];
  List<TaxonomyNode> _categories = const [];
  TaxonomyNode? _selectedCategory;
  List<TaxonomyNode> _serviceTypes = const [];
  TaxonomyNode? _selectedType;
  List<TaxonomyNode> _services = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    final cats = await ServiceTaxonomyService.categories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = _searchCtrl.text;
      if (q.trim().isEmpty) {
        setState(() => _searchResults = const []);
        return;
      }
      final res = await ServiceTaxonomyService.search(q);
      if (!mounted) return;
      setState(() => _searchResults = res);
    });
  }

  Future<void> _pickCategory(TaxonomyNode c) async {
    setState(() {
      _selectedCategory = c;
      _selectedType = null;
      _serviceTypes = const [];
      _services = const [];
      _loading = true;
    });
    final types = await ServiceTaxonomyService.children(c.id);
    if (!mounted) return;
    setState(() {
      _serviceTypes = types;
      _loading = false;
    });
  }

  Future<void> _pickType(TaxonomyNode t) async {
    setState(() {
      _selectedType = t;
      _services = const [];
      _loading = true;
    });
    final svcs = await ServiceTaxonomyService.children(t.id);
    if (!mounted) return;
    setState(() {
      _services = svcs;
      _loading = false;
    });
  }

  String _label(TaxonomyNode n, bool isSw) => isSw ? n.nameSw : n.nameEn;

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: isSw ? 'Tafuta huduma…' : 'Search services…',
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          if (_searchCtrl.text.trim().isNotEmpty)
            Expanded(child: _buildSearchView(isSw))
          else
            Expanded(child: _buildBrowseView(isSw)),
        ],
      ),
    );
  }

  Widget _buildSearchView(bool isSw) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          isSw ? 'Hakuna matokeo' : 'No matches',
          style: const TextStyle(color: Color(0xFF666666)),
        ),
      );
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (_, i) {
        final n = _searchResults[i];
        return ListTile(
          leading: Icon(
            n.level == 'service'
                ? Icons.label_rounded
                : n.level == 'service_type'
                    ? Icons.folder_rounded
                    : Icons.category_rounded,
            color: const Color(0xFF666666),
          ),
          title: Text(_label(n, isSw),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            n.breadcrumb.join('  ›  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
          ),
          onTap: () => Navigator.pop(context, n),
        );
      },
    );
  }

  Widget _buildBrowseView(bool isSw) {
    if (_loading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<Widget> trail = [];
    if (_selectedCategory != null) {
      trail.add(
        InkWell(
          onTap: () => setState(() {
            _selectedCategory = null;
            _selectedType = null;
            _serviceTypes = const [];
            _services = const [];
          }),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              _label(_selectedCategory!, isSw),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
      );
      if (_selectedType != null) {
        trail.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ));
        trail.add(
          InkWell(
            onTap: () => setState(() {
              _selectedType = null;
              _services = const [];
            }),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _label(_selectedType!, isSw),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        );
      }
    }
    return Column(
      children: [
        if (trail.isNotEmpty)
          Container(
            height: 40,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(children: trail),
          ),
        Expanded(
          child: ListView(
            children: [
              if (_selectedCategory == null)
                ..._categories.map((c) => _row(c, isSw, () => _pickCategory(c), Icons.category_rounded))
              else if (_selectedType == null)
                ..._serviceTypes.map((t) => _row(t, isSw, () => _pickType(t), Icons.folder_rounded))
              else
                ..._services.map((s) => _row(
                    s, isSw, () => Navigator.pop(context, s), Icons.label_rounded,
                    showCheck: true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(TaxonomyNode n, bool isSw, VoidCallback onTap, IconData icon,
      {bool showCheck = false}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF666666)),
      title: Text(_label(n, isSw),
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
      trailing: Icon(
        showCheck ? Icons.check_rounded : Icons.chevron_right_rounded,
        color: const Color(0xFF999999),
      ),
      onTap: onTap,
    );
  }
}
