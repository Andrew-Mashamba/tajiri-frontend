import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sticker_service.dart';

/// Standalone sticker browser widget that fetches sticker packs
/// and displays them in a tabbed grid. Returns sticker data via [onStickerTap].
///
/// Falls back to a set of default emoji stickers if the API fails.
/// Tabs: Recent | Emojis | Popular (+ any server packs).
class StickerBrowser extends StatefulWidget {
  /// Called when the user taps a sticker.
  final void Function(Sticker sticker) onStickerTap;

  /// Height of the browser panel.
  final double height;

  const StickerBrowser({
    super.key,
    required this.onStickerTap,
    this.height = 320,
  });

  @override
  State<StickerBrowser> createState() => _StickerBrowserState();
}

class _StickerBrowserState extends State<StickerBrowser>
    with SingleTickerProviderStateMixin {
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const String _recentStickerKey = 'recent_sticker_ids';
  static const int _maxRecent = 24;

  late TabController _tabController;
  List<StickerPack> _serverPacks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<Sticker> _recentStickers = [];
  final TextEditingController _searchController = TextEditingController();

  /// Default emoji stickers used in the Emojis tab.
  static final List<Sticker> _emojiStickers = [
    '😀', '😂', '😍', '🥰', '😎', '🤔', '😢', '😡',
    '👍', '👎', '❤️', '🔥', '🎉', '💯', '🙏', '✨',
    '😊', '🥺', '😭', '🤣', '😘', '🤗', '😱', '🤩',
    '😏', '🥳', '😴', '🤯', '😤', '🤮', '🥵', '🤡',
    '👻', '💀', '🤖', '👽', '🦄', '🐶', '🐱', '🐼',
    '🌈', '🌟', '💎', '🎶', '🎯', '🏆', '💪', '🙌',
  ].asMap().entries.map((e) => Sticker(id: e.key, imageUrl: '', emoji: e.value)).toList();

  /// Popular stickers — curated subset.
  static final List<Sticker> _popularStickers = [
    '👍', '❤️', '😂', '🔥', '💯', '🎉', '🙏', '✨',
    '😍', '🥰', '😎', '🤩', '💪', '🏆', '🙌', '🎶',
    '💀', '🤡', '😭', '🤣', '😘', '🥳', '😱', '💎',
  ].asMap().entries.map((e) => Sticker(id: 1000 + e.key, imageUrl: '', emoji: e.value)).toList();

  @override
  void initState() {
    super.initState();
    // 3 built-in tabs: Recent, Emojis, Popular
    _tabController = TabController(length: 3, vsync: this);
    _loadPacks();
    _loadRecentStickers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPacks() async {
    final packs = await StickerService.getPacks();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _serverPacks = packs;
      });
    }
  }

  Future<void> _loadRecentStickers() async {
    final prefs = await SharedPreferences.getInstance();
    final recentIds = prefs.getStringList(_recentStickerKey) ?? [];
    if (mounted) {
      setState(() {
        _recentStickers = recentIds
            .map((raw) {
              // Stored as "id|emoji" or "id|url"
              final parts = raw.split('|');
              if (parts.length < 2) return null;
              final id = int.tryParse(parts[0]) ?? 0;
              final value = parts.sublist(1).join('|');
              // If value is a single emoji (1-4 chars, non-ASCII), treat as emoji
              final isEmoji = value.isNotEmpty && !value.startsWith('http');
              return Sticker(
                id: id,
                imageUrl: isEmoji ? '' : value,
                emoji: isEmoji ? value : null,
              );
            })
            .whereType<Sticker>()
            .toList();
      });
    }
  }

  Future<void> _trackRecentSticker(Sticker sticker) async {
    final key = '${sticker.id}|${sticker.emoji ?? sticker.imageUrl}';
    final prefs = await SharedPreferences.getInstance();
    final recentIds = prefs.getStringList(_recentStickerKey) ?? [];
    recentIds.remove(key);
    recentIds.insert(0, key);
    if (recentIds.length > _maxRecent) {
      recentIds.removeRange(_maxRecent, recentIds.length);
    }
    await prefs.setStringList(_recentStickerKey, recentIds);
    if (mounted) {
      _loadRecentStickers();
    }
  }

  void _onStickerTap(Sticker sticker) {
    _trackRecentSticker(sticker);
    widget.onStickerTap(sticker);
  }

  /// All stickers flattened for search.
  List<Sticker> get _allStickers {
    final all = <Sticker>[..._emojiStickers, ..._popularStickers];
    for (final pack in _serverPacks) {
      all.addAll(pack.stickers);
    }
    return all;
  }

  List<Sticker> get _filteredStickers {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _allStickers.where((s) {
      final emoji = s.emoji ?? '';
      return emoji.contains(q) || emoji.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: const TextStyle(fontSize: 14, color: _primaryText),
                decoration: InputDecoration(
                  hintText: 'Tafuta sticker...',
                  hintStyle: const TextStyle(fontSize: 13, color: _secondaryText),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _secondaryText),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close_rounded, size: 18, color: _secondaryText),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Show search results if searching
          if (_searchQuery.isNotEmpty)
            Expanded(child: _buildStickerGridFromList(_filteredStickers, emptyLabel: 'Hakuna matokeo'))
          else ...[
            // Tab bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: _primaryText,
                unselectedLabelColor: _secondaryText,
                indicatorColor: _primaryText,
                indicatorWeight: 2,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: '\u{1F550} Hivi karibuni'),
                  Tab(text: '\u{1F600} Emoji'),
                  Tab(text: '\u2B50 Maarufu'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: _primaryText),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Recent tab
                        _recentStickers.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Sticker ulizotumia hivi karibuni zitaonekana hapa',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _secondaryText, fontSize: 13),
                                  ),
                                ),
                              )
                            : _buildStickerGridFromList(_recentStickers),
                        // Emojis tab
                        _buildStickerGridFromList(_emojiStickers),
                        // Popular tab
                        _buildStickerGridFromList(_popularStickers),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStickerGridFromList(List<Sticker> stickers, {String? emptyLabel}) {
    if (stickers.isEmpty) {
      return Center(
        child: Text(
          emptyLabel ?? 'Hakuna sticker',
          style: const TextStyle(color: _secondaryText, fontSize: 13),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return GestureDetector(
          onTap: () => _onStickerTap(sticker),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: sticker.emoji != null && sticker.emoji!.isNotEmpty
                ? Center(
                    child: Text(sticker.emoji!, style: const TextStyle(fontSize: 28)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.network(
                      sticker.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: _secondaryText,
                        size: 24,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
