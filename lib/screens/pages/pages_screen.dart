import 'package:flutter/material.dart';
import '../../models/page_models.dart';
import '../../services/page_service.dart';
import 'page_detail_screen.dart';
import '../groups/createpage_screen.dart';

class PagesScreen extends StatefulWidget {
  final int currentUserId;

  const PagesScreen({super.key, required this.currentUserId});

  @override
  State<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends State<PagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageService _pageService = PageService();

  List<PageModel> _discoverPages = [];
  List<PageModel> _myPages = [];
  List<PageModel> _likedPages = [];
  List<PageCategory> _categories = [];
  String? _selectedCategory;
  bool _isLoadingDiscover = true;
  bool _isLoadingMyPages = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategories();
    _loadPages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _pageService.getCategories();
    setState(() => _categories = categories);
  }

  Future<void> _loadPages() async {
    _loadDiscoverPages();
    _loadMyPages();
    _loadLikedPages();
  }

  Future<void> _loadDiscoverPages() async {
    setState(() => _isLoadingDiscover = true);
    final result = await _pageService.getPages(
      currentUserId: widget.currentUserId,
      category: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _isLoadingDiscover = false;
        if (result.success) _discoverPages = result.pages;
      });
    }
  }

  Future<void> _loadMyPages() async {
    setState(() => _isLoadingMyPages = true);
    final result = await _pageService.getUserPages(widget.currentUserId);
    if (mounted) {
      setState(() {
        _isLoadingMyPages = false;
        if (result.success) _myPages = result.pages;
      });
    }
  }

  Future<void> _loadLikedPages() async {
    final result = await _pageService.getLikedPages(widget.currentUserId);
    if (mounted && result.success) {
      setState(() => _likedPages = result.pages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurasa'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gundua'),
            Tab(text: 'Zinazopendwa'),
            Tab(text: 'Kurasa Zangu'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildLikedTab(),
          _buildMyPagesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'pages_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePageScreen(creatorId: widget.currentUserId),
            ),
          );
          if (result == true) _loadPages();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Category filter
        if (_categories.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(null, 'Zote');
                }
                final category = _categories[index - 1];
                return _buildCategoryChip(category.value, category.label);
              },
            ),
          ),
        Expanded(
          child: _isLoadingDiscover
              ? const Center(child: CircularProgressIndicator())
              : _discoverPages.isEmpty
                  ? _buildEmptyState('Hakuna kurasa')
                  : RefreshIndicator(
                      onRefresh: _loadDiscoverPages,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _discoverPages.length,
                        itemBuilder: (context, index) => _buildPageCard(_discoverPages[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String? value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? value : null);
          _loadDiscoverPages();
        },
      ),
    );
  }

  Widget _buildLikedTab() {
    if (_likedPages.isEmpty) {
      return _buildEmptyState('Hujapenda kurasa yoyote');
    }
    return RefreshIndicator(
      onRefresh: _loadLikedPages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _likedPages.length,
        itemBuilder: (context, index) => _buildPageCard(_likedPages[index]),
      ),
    );
  }

  Widget _buildMyPagesTab() {
    if (_isLoadingMyPages) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myPages.isEmpty) {
      return _buildEmptyState('Huna kurasa', showCreate: true);
    }
    return RefreshIndicator(
      onRefresh: _loadMyPages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myPages.length,
        itemBuilder: (context, index) => _buildPageCard(_myPages[index], showRole: true),
      ),
    );
  }

  Widget _buildEmptyState(String message, {bool showCreate = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pages_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          if (showCreate) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePageScreen(creatorId: widget.currentUserId),
                  ),
                );
                if (result == true) _loadPages();
              },
              child: const Text('Unda Ukurasa'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageCard(PageModel page, {bool showRole = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PageDetailScreen(
                pageId: page.id,
                currentUserId: widget.currentUserId,
              ),
            ),
          ).then((_) => _loadPages());
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Profile photo
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.blue.shade100,
                child: page.profilePhotoUrl != null
                    ? Image.network(page.profilePhotoUrl!, fit: BoxFit.cover)
                    : Icon(Icons.storefront, size: 40, color: Colors.blue.shade300),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            page.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (page.isVerified)
                          const Icon(Icons.verified, size: 16, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      page.category,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.thumb_up, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${page.likesCount}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${page.followersCount}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        if (showRole && page.userRole != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              page.userRole!,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
