// lib/screens/collections/collections_screen.dart
//
// Curation MVP — strategy posts.md §VII.
// Industry pattern: Pinterest boards.
//
// Playbook compliance:
//   - Monochrome (#1A1A1A / #666666 / #999999 / #FAFAFA / #FFFFFF)
//   - 48dp touch targets, _rounded icons
//   - Pill button (top-right of AppBar) for "New" — NO FAB
//   - Pull-to-refresh, empty / loading / error triumvirate
//   - Bilingual via AppStringsScope
//   - maxLines + ellipsis on dynamic text

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/collection_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kIconBg = Color(0xFFF5F5F5);

class CollectionsScreen extends StatefulWidget {
  /// When set, shows only this user's collections; otherwise public feed.
  final int? curatorUserId;
  final int currentUserId;

  const CollectionsScreen({
    super.key,
    this.curatorUserId,
    required this.currentUserId,
  });

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _service = CollectionService();
  List<Collection> _items = [];
  bool _loading = true;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final token = (await LocalStorageService.getInstance()).getAuthToken();
    if (!mounted) return;
    setState(() => _token = token);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.list(
        curatorUserId: widget.curatorUserId,
        token: _token,
      );
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showCreate() async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CreateCollectionSheet(
        currentUserId: widget.currentUserId,
        token: _token,
      ),
    );
    if (result == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(
        title: isSw ? 'Mikusanyo' : 'Collections',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showCreate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isSw ? 'Mpya' : 'New',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _load,
          child: _loading && _items.isEmpty
              ? const _LoadingList()
              : _error != null && _items.isEmpty
                  ? _ErrorView(onRetry: _load, isSw: isSw)
                  : _items.isEmpty
                      ? _EmptyState(isSw: isSw)
                      : _buildList(isSw),
        ),
      ),
    );
  }

  Widget _buildList(bool isSw) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final c = _items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CollectionCard(
            collection: c,
            isSw: isSw,
            currentUserId: widget.currentUserId,
            token: _token,
          ),
        );
      },
    );
  }
}

class _CollectionCard extends StatefulWidget {
  final Collection collection;
  final bool isSw;
  final int currentUserId;
  final String? token;
  const _CollectionCard({
    required this.collection,
    required this.isSw,
    required this.currentUserId,
    required this.token,
  });

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
  static final _service = CollectionService();
  bool _following = false;
  bool _busy = false;

  Collection get collection => widget.collection;
  bool get isSw => widget.isSw;

  Future<void> _toggleFollow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await _service.follow(
      collectionId: collection.id,
      userId: widget.currentUserId,
      token: widget.token,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _following = !_following;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          // UN-011: push CollectionDetailScreen which fires collection_view.
          Navigator.pushNamed(
            context,
            '/collections/board/${collection.id}',
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.collections_bookmark_rounded,
                    size: 24, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collection.description ??
                          (isSw ? 'Hakuna maelezo' : 'No description'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kSecondary,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Stat(
                          icon: Icons.image_outlined,
                          value: '${collection.itemsCount}',
                          label: isSw ? 'posts' : 'posts',
                        ),
                        const SizedBox(width: 14),
                        _Stat(
                          icon: Icons.bookmark_outline_rounded,
                          value: '${collection.followsCount}',
                          label: isSw ? 'wafuasi' : 'followers',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // UW-003 / row 61 — collection_follow·curator. Follow icon
              // on each card. Tappable; doesn't bubble up to the card tap.
              if (collection.curatorUserId != widget.currentUserId)
                IconButton(
                  onPressed: _busy ? null : _toggleFollow,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kPrimary,
                          ),
                        )
                      : Icon(
                          _following
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          size: 22,
                          color: _kPrimary,
                        ),
                  tooltip: isSw
                      ? (_following ? 'Acha kufuata' : 'Fuata')
                      : (_following ? 'Unfollow' : 'Follow'),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: _kTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _kTertiary),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: const TextStyle(
            fontSize: 11,
            color: _kTertiary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─── Create sheet ────────────────────────────────────────────────────

class _CreateCollectionSheet extends StatefulWidget {
  final int currentUserId;
  final String? token;
  const _CreateCollectionSheet({
    required this.currentUserId,
    required this.token,
  });

  @override
  State<_CreateCollectionSheet> createState() => _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends State<_CreateCollectionSheet> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  bool _isPublic = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    final id = await CollectionService().create(
      curatorUserId: widget.currentUserId,
      name: _name.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      isPublic: _isPublic,
      token: widget.token,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.pop(context, id != null);
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isSw ? 'Mkusanyiko mpya' : 'New collection',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Text(isSw ? 'Jina' : 'Name',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            maxLength: 120,
            decoration: InputDecoration(
              filled: true,
              fillColor: _kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              hintText: isSw ? 'Mfano: Picha za safari' : 'Eg: Travel photos',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Text(
              isSw ? 'Maelezo (hiari)' : 'Description (optional)',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _desc,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              filled: true,
              fillColor: _kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            title: Text(
              isSw ? 'Onyesha kwa wote' : 'Public',
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _kPrimary,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _busy ? null : _create,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      isSw ? 'Tengeneza' : 'Create',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sentinels ───────────────────────────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSw;
  const _EmptyState({required this.isSw});
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.collections_bookmark_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          isSw ? 'Hakuna mikusanyo bado' : 'No collections yet',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          isSw
              ? 'Tengeneza mkusanyiko ili kupanga posts unazopenda.'
              : 'Create a collection to organise posts you love.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isSw;
  const _ErrorView({required this.onRetry, required this.isSw});
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.error_outline_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          isSw ? 'Imeshindwa kupakia' : 'Failed to load',
          style: const TextStyle(color: _kSecondary, fontSize: 14),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(isSw ? 'Jaribu tena' : 'Retry'),
          ),
        ),
      ],
    );
  }
}
