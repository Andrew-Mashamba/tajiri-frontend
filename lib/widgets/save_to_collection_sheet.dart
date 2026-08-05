// lib/widgets/save_to_collection_sheet.dart
//
// Bottom-sheet picker — used from "Save to collection" entry in PostCard /
// FullScreenPostViewer menus (G-F-001 / posts.md §VII).
// Shows the user's existing boards + an inline "New collection" row that
// creates one and adds the post in a single action.

import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';
import '../services/collection_service.dart';
import '../services/local_storage_service.dart';

class SaveToCollectionSheet extends StatefulWidget {
  final int postId;
  final int currentUserId;

  const SaveToCollectionSheet({
    super.key,
    required this.postId,
    required this.currentUserId,
  });

  /// Opens the sheet. Returns true if the post was added to a collection.
  static Future<bool> show(
    BuildContext context, {
    required int postId,
    required int currentUserId,
  }) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SaveToCollectionSheet(
        postId: postId,
        currentUserId: currentUserId,
      ),
    );
    return res == true;
  }

  @override
  State<SaveToCollectionSheet> createState() => _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState extends State<SaveToCollectionSheet> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kIconBg = Color(0xFFF5F5F5);

  final _service = CollectionService();
  final _newNameCtrl = TextEditingController();
  List<Collection> _items = const [];
  bool _loading = true;
  bool _busy = false;
  bool _showNewForm = false;
  String? _token;
  String _newCategory = 'general';

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void dispose() {
    _newNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final tok = (await LocalStorageService.getInstance()).getAuthToken();
    if (!mounted) return;
    _token = tok;
    final list = await _service.list(
      curatorUserId: widget.currentUserId,
      token: tok,
    );
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _addTo(Collection c) async {
    setState(() => _busy = true);
    final ok = await _service.addItem(
      collectionId: c.id,
      curatorUserId: widget.currentUserId,
      postId: widget.postId,
      token: _token,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imehifadhiwa kwenye "${c.name}"')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindikana kuhifadhi')),
      );
    }
  }

  Widget _categoryChip(String value, String label) {
    final selected = _newCategory == value;
    return InkWell(
      onTap: () => setState(() => _newCategory = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kPrimary : _kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _kPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _createAndAdd() async {
    final name = _newNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final id = await _service.create(
      curatorUserId: widget.currentUserId,
      name: name,
      category: _newCategory,
      token: _token,
    );
    if (id == null) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindikana kuunda mkusanyiko')),
      );
      return;
    }
    final ok = await _service.addItem(
      collectionId: id,
      curatorUserId: widget.currentUserId,
      postId: widget.postId,
      token: _token,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mkusanyiko "$name" umeundwa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isSw ? 'Hifadhi kwenye…' : 'Save to…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _showNewForm = !_showNewForm),
                    icon: const Icon(Icons.add_rounded, color: _kPrimary, size: 18),
                    label: Text(
                      isSw ? 'Mpya' : 'New',
                      style: const TextStyle(color: _kPrimary, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (_showNewForm) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _categoryChip('general', isSw ? 'Jumla' : 'General'),
                    _categoryChip('learning', isSw ? 'Kujifunza' : 'Learning'),
                    _categoryChip('gallery', isSw ? 'Picha' : 'Gallery'),
                    _categoryChip('inspiration', isSw ? 'Msukumo' : 'Inspiration'),
                    _categoryChip('reference', isSw ? 'Marejeo' : 'Reference'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newNameCtrl,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _createAndAdd(),
                        style: const TextStyle(fontSize: 14, color: _kPrimary),
                        decoration: InputDecoration(
                          hintText: isSw ? 'Jina la mkusanyiko' : 'Collection name',
                          hintStyle: const TextStyle(fontSize: 13, color: _kTertiary),
                          filled: true,
                          fillColor: _kIconBg,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _createAndAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(isSw ? 'Hifadhi' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: _kPrimary),
              )
            else if (_items.isEmpty && !_showNewForm)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    const Icon(Icons.collections_bookmark_outlined,
                        size: 40, color: _kTertiary),
                    const SizedBox(height: 8),
                    Text(
                      isSw
                          ? 'Bado huna mikusanyiko. Bonyeza Mpya kuanza.'
                          : 'No collections yet. Tap New to start.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shrinkWrap: true,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _kBorder),
                  itemBuilder: (_, i) {
                    final c = _items[i];
                    return ListTile(
                      onTap: _busy ? null : () => _addTo(c),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _kIconBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.collections_bookmark_rounded,
                            color: _kPrimary, size: 20),
                      ),
                      title: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${c.itemsCount} ${isSw ? "vipande" : "items"}',
                        style: const TextStyle(fontSize: 12, color: _kTertiary),
                      ),
                      trailing: const Icon(Icons.add_rounded,
                          size: 22, color: _kPrimary),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
