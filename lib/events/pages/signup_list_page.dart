// lib/events/pages/signup_list_page.dart
import 'package:flutter/material.dart';
import '../models/signup_list.dart';
import '../models/event_strings.dart';
import '../services/event_organizer_service.dart';
import '../../services/local_storage_service.dart';

class SignupListPage extends StatefulWidget {
  final int eventId;

  const SignupListPage({super.key, required this.eventId});

  @override
  State<SignupListPage> createState() => _SignupListPageState();
}

class _SignupListPageState extends State<SignupListPage> {
  final _service = EventOrganizerService();
  List<SignupList> _lists = [];
  bool _loading = true;
  String? _error;
  int _currentUserId = 0;
  late EventStrings _s;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _s = EventStrings(isSwahili: lang == 'sw');
    _currentUserId = widget.eventId; // user context from parent
    await _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lists = await _service.getSignupLists(eventId: widget.eventId);
      if (mounted) setState(() { _lists = lists; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = _s.loadError; _loading = false; });
    }
  }

  Future<void> _toggleItem(SignupItem item) async {
    final wasClaimed = item.isClaimed;
    if (wasClaimed && item.userId != _currentUserId) return; // can't unclaim others

    final result = wasClaimed
        ? await _service.unclaimSignupItem(itemId: item.id)
        : await _service.claimSignupItem(itemId: item.id);

    if (!mounted) return;
    if (result.success) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? _s.loadError),
          backgroundColor: const Color(0xFF1A1A1A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA);
    final fg = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A1A);
    final surface = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        title: Text(_s.signupList, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _error != null
                ? _buildError(fg)
                : _lists.isEmpty
                    ? _buildEmpty(fg)
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: fg,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _lists.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (_, i) => _buildList(_lists[i], surface, fg),
                        ),
                      ),
      ),
    );
  }

  Widget _buildList(SignupList list, Color surface, Color fg) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              list.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Divider(height: 1, color: fg.withOpacity(0.08)),
          ...list.items.map((item) => _buildItem(item, fg)),
        ],
      ),
    );
  }

  Widget _buildItem(SignupItem item, Color fg) {
    final isMyItem = item.userId == _currentUserId;
    final canInteract = !item.isClaimed || isMyItem;

    return InkWell(
      onTap: canInteract ? () => _toggleItem(item) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              item.isClaimed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: item.isClaimed ? fg : fg.withOpacity(0.35),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.isClaimed ? fg.withOpacity(0.5) : fg,
                      fontSize: 14,
                      decoration: item.isClaimed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.claimedBy != null)
                    Text(
                      '${item.claimedBy!.firstName} ${item.claimedBy!.lastName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg.withOpacity(0.45), fontSize: 12),
                    ),
                ],
              ),
            ),
            if (item.quantity != null)
              Text(
                'x${item.quantity}',
                style: TextStyle(color: fg.withOpacity(0.45), fontSize: 12),
              ),
            if (isMyItem && item.isClaimed) ...[
              const SizedBox(width: 8),
              Icon(Icons.close_rounded, size: 16, color: fg.withOpacity(0.4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(Color fg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: TextStyle(color: fg.withOpacity(0.6))),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: Text(_s.tryAgain, style: TextStyle(color: fg))),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color fg) {
    return Center(
      child: Text(
        _s.noEvents,
        style: TextStyle(color: fg.withOpacity(0.45), fontSize: 14),
      ),
    );
  }
}
