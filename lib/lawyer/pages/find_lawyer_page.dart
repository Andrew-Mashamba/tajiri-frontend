// lib/lawyer/pages/find_lawyer_page.dart
import 'package:flutter/material.dart';
import '../models/lawyer_models.dart';
import '../services/lawyer_service.dart';
import '../widgets/lawyer_card.dart';
import 'lawyer_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FindLawyerPage extends StatefulWidget {
  final int userId;
  final LegalSpecialty? initialSpecialty;
  const FindLawyerPage({super.key, required this.userId, this.initialSpecialty});
  @override
  State<FindLawyerPage> createState() => _FindLawyerPageState();
}

class _FindLawyerPageState extends State<FindLawyerPage> {
  final LawyerService _service = LawyerService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Lawyer> _lawyers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  LegalSpecialty? _selectedSpecialty;
  bool _onlineOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedSpecialty = widget.initialSpecialty;
    _scrollController.addListener(_onScroll);
    _loadLawyers();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
      _loadMore();
    }
  }

  Future<void> _loadLawyers() async {
    setState(() { _isLoading = true; _page = 1; });

    final result = await _service.findLawyers(
      specialty: _selectedSpecialty?.name,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      onlineOnly: _onlineOnly ? true : null,
      page: 1,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _lawyers = result.items;
          _hasMore = result.items.length >= 20;
          _page = 2;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await _service.findLawyers(
      specialty: _selectedSpecialty?.name,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      onlineOnly: _onlineOnly ? true : null,
      page: _page,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _lawyers.addAll(result.items);
          _hasMore = result.items.length >= 20;
          _page++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Tafuta Wakili', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadLawyers(),
              decoration: InputDecoration(
                hintText: 'Tafuta kwa jina au ofisi...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _kSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchController.clear(); _loadLawyers(); },
                      )
                    : null,
                filled: true, fillColor: _kCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filters
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                        SizedBox(width: 4),
                        Text('Mtandaoni', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    selected: _onlineOnly,
                    selectedColor: _kPrimary.withValues(alpha: 0.15),
                    onSelected: (v) { setState(() => _onlineOnly = v); _loadLawyers(); },
                  ),
                ),
                // All
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { setState(() => _selectedSpecialty = null); _loadLawyers(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedSpecialty == null ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _selectedSpecialty == null ? _kPrimary : const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        'Wote',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _selectedSpecialty == null ? Colors.white : _kPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                ...LegalSpecialty.values.map((s) {
                  final isSelected = _selectedSpecialty == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedSpecialty = _selectedSpecialty == s ? null : s);
                        _loadLawyers();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? _kPrimary : const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.icon, size: 16, color: isSelected ? Colors.white : _kSecondary),
                            const SizedBox(width: 6),
                            Text(
                              s.displayName,
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _lawyers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Hakuna wakili aliyepatikana', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLawyers,
                        color: _kPrimary,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _lawyers.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _lawyers.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: LawyerCard(
                                lawyer: _lawyers[index],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LawyerProfilePage(
                                      userId: widget.userId,
                                      lawyer: _lawyers[index],
                                    ),
                                  ),
                                ),
                              ),
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
