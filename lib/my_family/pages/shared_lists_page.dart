// lib/my_family/pages/shared_lists_page.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';
import '../services/my_family_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SharedListsPage extends StatefulWidget {
  final int userId;
  final List<FamilyMember> members;

  const SharedListsPage({
    super.key,
    required this.userId,
    required this.members,
  });

  @override
  State<SharedListsPage> createState() => _SharedListsPageState();
}

class _SharedListsPageState extends State<SharedListsPage>
    with SingleTickerProviderStateMixin {
  final MyFamilyService _service = MyFamilyService();
  late TabController _tabCtrl;

  List<SharedList> _allLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadLists();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    final result = await _service.getLists(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _allLists = result.items;
      });
    }
  }

  List<SharedList> _listsForType(SharedListType type) {
    return _allLists.where((l) => l.type == type).toList();
  }

  void _showCreateListSheet() {
    final nameCtrl = TextEditingController();
    SharedListType selectedType = SharedListType.values[_tabCtrl.index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: _kCardBg,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unda Orodha Mpya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                    decoration: InputDecoration(
                      labelText: 'Jina la Orodha',
                      labelStyle: const TextStyle(
                          fontSize: 13, color: _kSecondary),
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: SharedListType.values.map((type) {
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(type.icon,
                                size: 14,
                                color: selectedType == type
                                    ? Colors.white
                                    : _kPrimary),
                            const SizedBox(width: 4),
                            Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedType == type
                                    ? Colors.white
                                    : _kPrimary,
                              ),
                            ),
                          ],
                        ),
                        selected: selectedType == type,
                        onSelected: (_) =>
                            setSheetState(() => selectedType = type),
                        selectedColor: _kPrimary,
                        backgroundColor:
                            _kPrimary.withValues(alpha: 0.06),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final result = await _service.createList(
                          userId: widget.userId,
                          name: nameCtrl.text.trim(),
                          type: selectedType.name,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (result.success && mounted) _loadLists();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Unda Orodha',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItemSheet(SharedList list) {
    final titleCtrl = TextEditingController();
    int? assignedMemberId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: _kCardBg,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ongeza kwenye "${list.name}"',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                    decoration: InputDecoration(
                      labelText: 'Kipengele',
                      labelStyle: const TextStyle(
                          fontSize: 13, color: _kSecondary),
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (widget.members.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Teua Mwanafamilia',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        FilterChip(
                          label: Text(
                            'Yeyote',
                            style: TextStyle(
                              fontSize: 12,
                              color: assignedMemberId == null
                                  ? Colors.white
                                  : _kPrimary,
                            ),
                          ),
                          selected: assignedMemberId == null,
                          onSelected: (_) => setSheetState(
                              () => assignedMemberId = null),
                          selectedColor: _kPrimary,
                          backgroundColor:
                              _kPrimary.withValues(alpha: 0.06),
                          side: BorderSide.none,
                          checkmarkColor: Colors.white,
                        ),
                        ...widget.members.map((m) {
                          return FilterChip(
                            label: Text(
                              m.name.split(' ').first,
                              style: TextStyle(
                                fontSize: 12,
                                color: assignedMemberId == m.id
                                    ? Colors.white
                                    : _kPrimary,
                              ),
                            ),
                            selected: assignedMemberId == m.id,
                            onSelected: (_) => setSheetState(
                                () => assignedMemberId = m.id),
                            selectedColor: _kPrimary,
                            backgroundColor:
                                _kPrimary.withValues(alpha: 0.06),
                            side: BorderSide.none,
                            checkmarkColor: Colors.white,
                          );
                        }),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        final result = await _service.addListItem(
                          listId: list.id,
                          title: titleCtrl.text.trim(),
                          assignedMemberId: assignedMemberId,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (result.success && mounted) _loadLists();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ongeza',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleItem(SharedListItem item) async {
    final result = await _service.toggleListItem(item.id);
    if (result.success && mounted) _loadLists();
  }

  Future<void> _deleteList(SharedList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Orodha'),
        content: Text('Una uhakika unataka kufuta "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana',
                style: TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ndio, Futa',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _service.deleteList(list.id);
      if (result.success && mounted) _loadLists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Orodha za Familia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: SharedListType.values
              .map((t) => Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.icon, size: 16),
                        const SizedBox(width: 4),
                        Text(t.displayName),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadLists,
              color: _kPrimary,
              child: TabBarView(
                controller: _tabCtrl,
                children: SharedListType.values
                    .map((type) => _buildListTab(type))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildListTab(SharedListType type) {
    final lists = _listsForType(type);
    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon,
                size: 48, color: _kPrimary.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              'Hakuna orodha za ${type.displayName.toLowerCase()}',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _showCreateListSheet,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Unda Orodha'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return _SharedListCard(
          list: list,
          onAddItem: () => _showAddItemSheet(list),
          onToggleItem: _toggleItem,
          onDelete: () => _deleteList(list),
        );
      },
    );
  }
}

class _SharedListCard extends StatelessWidget {
  final SharedList list;
  final VoidCallback onAddItem;
  final ValueChanged<SharedListItem> onToggleItem;
  final VoidCallback onDelete;

  const _SharedListCard({
    required this.list,
    required this.onAddItem,
    required this.onToggleItem,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(list.type.icon, size: 20, color: _kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (list.totalCount > 0)
                        Text(
                          '${list.completedCount}/${list.totalCount} vimekamilika',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded,
                      size: 20, color: _kPrimary),
                  onPressed: onAddItem,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 18,
                      color: _kSecondary.withValues(alpha: 0.5)),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          // Progress bar
          if (list.totalCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: list.progress,
                  backgroundColor: _kPrimary.withValues(alpha: 0.06),
                  color: _kPrimary,
                  minHeight: 3,
                ),
              ),
            ),
          // Items
          if (list.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...list.items.map((item) => _ItemRow(
                  item: item,
                  onToggle: () => onToggleItem(item),
                )),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final SharedListItem item;
  final VoidCallback onToggle;

  const _ItemRow({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isDone
                    ? _kPrimary
                    : Colors.transparent,
                border: Border.all(
                  color: item.isDone
                      ? _kPrimary
                      : _kPrimary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: item.isDone
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  color: item.isDone ? _kSecondary : _kPrimary,
                  decoration:
                      item.isDone ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.assignedMemberName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.assignedMemberName!,
                  style: const TextStyle(fontSize: 10, color: _kSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
