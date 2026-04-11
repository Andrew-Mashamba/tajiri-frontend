// lib/fundi/pages/find_fundi_page.dart
import 'package:flutter/material.dart';
import '../models/fundi_models.dart';
import '../services/fundi_service.dart';
import '../widgets/fundi_card.dart';
import 'fundi_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FindFundiPage extends StatefulWidget {
  final int userId;
  final ServiceCategory? initialCategory;

  const FindFundiPage({super.key, required this.userId, this.initialCategory});

  @override
  State<FindFundiPage> createState() => _FindFundiPageState();
}

class _FindFundiPageState extends State<FindFundiPage> {
  final FundiService _service = FundiService();
  final _searchController = TextEditingController();

  ServiceCategory? _selectedCategory;
  List<Fundi> _fundis = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _search();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);
    final result = await _service.findFundis(
      service: _selectedCategory?.name,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      availableOnly: true,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _fundis = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tafuta Fundi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: _kCardBg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Tafuta jina au eneo...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  onPressed: () {},
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ),

          // Category filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Zote'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                      _search();
                    },
                    selectedColor: _kPrimary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: _selectedCategory == null ? _kPrimary : _kSecondary,
                      fontWeight: _selectedCategory == null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                ...ServiceCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.displayName),
                        selected: _selectedCategory == cat,
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat);
                          _search();
                        },
                        selectedColor: _kPrimary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: _selectedCategory == cat ? _kPrimary : _kSecondary,
                          fontWeight: _selectedCategory == cat ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _fundis.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.engineering_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Hakuna fundi amepatikana', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _search,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _fundis.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final fundi = _fundis[i];
                            return FundiCard(
                              fundi: fundi,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FundiProfilePage(userId: widget.userId, fundi: fundi),
                                ),
                              ).then((_) {
                                if (mounted) _search();
                              }),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
