// Browse all tenders with search, tabs, and filters
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';
import '../services/tender_service.dart';
import '../widgets/tender_card.dart';
import 'tender_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BrowseTendersPage extends StatefulWidget {
  final String? initialCategory;
  final String? institutionSlug;

  const BrowseTendersPage({super.key, this.initialCategory, this.institutionSlug});

  @override
  State<BrowseTendersPage> createState() => _BrowseTendersPageState();
}

class _BrowseTendersPageState extends State<BrowseTendersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String? _selectedCategory;
  String _searchQuery = '';

  // Active tab
  List<Tender> _activeTenders = [];
  bool _activeLoading = true;

  // Closed tab
  List<Tender> _closedTenders = [];
  bool _closedLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCategory = widget.initialCategory;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1 && _closedLoading) {
          _loadClosed();
        }
      }
    });
    _loadActive();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadActive() async {
    if (mounted) setState(() => _activeLoading = true);
    final result = await TenderService.getTenders(
      status: 'active',
      category: _selectedCategory,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      institutionSlug: widget.institutionSlug,
    );
    if (mounted) {
      setState(() {
        _activeLoading = false;
        if (result.success) {
          _activeTenders = result.tenders
            ..sort((a, b) => (a.daysRemaining).compareTo(b.daysRemaining));
        }
      });
    }
  }

  Future<void> _loadClosed() async {
    if (mounted) setState(() => _closedLoading = true);
    final result = await TenderService.getTenders(
      status: 'closed',
      category: _selectedCategory,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      institutionSlug: widget.institutionSlug,
    );
    if (mounted) {
      setState(() {
        _closedLoading = false;
        if (result.success) {
          _closedTenders = result.tenders;
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value.trim());
      _loadActive();
      if (_tabController.index == 1) _loadClosed();
    });
  }

  void _onCategorySelected(String? cat) {
    setState(() => _selectedCategory = cat);
    _loadActive();
    if (_tabController.index == 1) _loadClosed();
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
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
          isSwahili ? 'Zabuni' : 'Tenders',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: isSwahili ? 'Hai' : 'Active'),
            Tab(text: isSwahili ? 'Zimefungwa' : 'Closed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: _kCardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14, color: _kPrimary),
              decoration: InputDecoration(
                hintText: isSwahili ? 'Tafuta zabuni...' : 'Search tenders...',
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
                  _buildChip(null, isSwahili ? 'Zote' : 'All'),
                  ...TenderCategory.values.where((c) => c != TenderCategory.other).map(
                    (c) => _buildChip(c.valueEn, isSwahili ? c.label : c.valueEn),
                  ),
                ],
              ),
            ),
          ),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTenderList(_activeTenders, _activeLoading, _loadActive),
                _buildTenderList(_closedTenders, _closedLoading, _loadClosed),
              ],
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

  Widget _buildTenderList(List<Tender> tenders, bool loading, Future<void> Function() onRefresh) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    if (loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    if (tenders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              isSwahili ? 'Hakuna zabuni zilizopatikana' : 'No tenders found',
              style: const TextStyle(fontSize: 15, color: _kSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? (isSwahili ? 'Jaribu maneno mengine' : 'Try different keywords')
                  : (isSwahili ? 'Zabuni mpya zitaonekana hapa' : 'New tenders will appear here'),
              style: TextStyle(fontSize: 13, color: _kSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: tenders.length,
        itemBuilder: (context, index) {
          final tender = tenders[index];
          return TenderCard(
            tender: tender,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TenderDetailPage(tenderId: tender.tenderId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
