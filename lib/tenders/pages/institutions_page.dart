// Browse and follow tender-publishing institutions
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';
import '../services/tender_service.dart';
import '../widgets/institution_tile.dart';
import 'institution_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class InstitutionsPage extends StatefulWidget {
  const InstitutionsPage({super.key});

  @override
  State<InstitutionsPage> createState() => _InstitutionsPageState();
}

class _InstitutionsPageState extends State<InstitutionsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Institution> _institutions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    if (mounted) setState(() => _isLoading = true);
    final result = await TenderService.getInstitutions(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      category: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _institutions = result.institutions;
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value.trim());
      _loadInstitutions();
    });
  }

  void _onCategorySelected(String? cat) {
    setState(() => _selectedCategory = cat);
    _loadInstitutions();
  }

  Future<void> _toggleFollow(int index) async {
    final inst = _institutions[index];
    final wasFollowed = inst.isFollowed;

    // Optimistic update
    setState(() {
      _institutions[index] = inst.copyWith(isFollowed: !wasFollowed);
    });

    final result = wasFollowed
        ? await TenderService.unfollowInstitution(inst.slug)
        : await TenderService.followInstitution(inst.slug);

    if (!result.success && mounted) {
      // Revert
      setState(() {
        _institutions[index] = inst.copyWith(isFollowed: wasFollowed);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Imeshindwa'), backgroundColor: const Color(0xFFD32F2F)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          (AppStringsScope.of(context)?.isSwahili ?? false) ? 'Taasisi' : 'Institutions',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: _kCardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14, color: _kPrimary),
              decoration: InputDecoration(
                hintText: (AppStringsScope.of(context)?.isSwahili ?? false) ? 'Tafuta taasisi...' : 'Search institutions...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _kSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: _kSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: _kBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category chips
          Container(
            color: _kCardBg,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(null, (AppStringsScope.of(context)?.isSwahili ?? false) ? 'Zote' : 'All'),
                  ...InstitutionCategory.values.where((c) => c != InstitutionCategory.other).map(
                    (c) => _buildChip(c.valueEn, (AppStringsScope.of(context)?.isSwahili ?? false) ? c.label : c.valueEn),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _institutions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.business_outlined, size: 48, color: _kSecondary),
                            const SizedBox(height: 12),
                            Text(
                              (AppStringsScope.of(context)?.isSwahili ?? false) ? 'Hakuna taasisi zilizopatikana' : 'No institutions found',
                              style: const TextStyle(fontSize: 15, color: _kSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? ((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Jaribu maneno mengine' : 'Try different keywords')
                                  : ((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Taasisi zitaonekana hapa' : 'Institutions will appear here'),
                              style: TextStyle(fontSize: 13, color: _kSecondary.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInstitutions,
                        color: _kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 32),
                          itemCount: _institutions.length,
                          itemBuilder: (context, index) {
                            final inst = _institutions[index];
                            return InstitutionTile(
                              institution: inst,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InstitutionDetailPage(slug: inst.slug, institution: inst),
                                  ),
                                );
                              },
                              onFollowToggle: () => _toggleFollow(index),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String? categoryValue, String label) {
    final selected = _selectedCategory == categoryValue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _onCategorySelected(selected ? null : categoryValue),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? Colors.white : _kPrimary,
        ),
        backgroundColor: _kBackground,
        selectedColor: _kPrimary,
        checkmarkColor: Colors.white,
        side: BorderSide(color: selected ? _kPrimary : _kSecondary.withValues(alpha: 0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
