import 'package:flutter/material.dart';
import '../models/friend_models.dart';
import '../services/friend_service.dart';
import '../services/hashtag_service.dart';

/// A text field that supports @mentions and #hashtags with suggestions.
/// Friend suggestions on @; hashtag suggestions on # (Story 86).
class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int? maxLines;
  final int minLines;
  final int currentUserId;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextStyle? style;
  final InputDecoration? decoration;
  final TextAlign? textAlign;
  /// Called when user selects a mention from suggestions (for sending mention_ids to API).
  final void Function(UserProfile user)? onMentionSelected;
  /// Called when user submits (e.g. keyboard send).
  final VoidCallback? onSubmitted;

  const MentionTextField({
    super.key,
    required this.controller,
    required this.currentUserId,
    this.hintText,
    this.maxLines,
    this.minLines = 1,
    this.onChanged,
    this.focusNode,
    this.style,
    this.decoration,
    this.textAlign,
    this.onMentionSelected,
    this.onSubmitted,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  final FriendService _friendService = FriendService();
  final HashtagService _hashtagService = HashtagService();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<UserProfile> _suggestions = [];
  List<String> _hashtagSuggestions = [];
  bool _isSearching = false;
  bool _isLoadingHashtags = false;
  String _searchQuery = '';
  bool _isMentionSearch = false;
  int _cursorPosition = 0;

  static const Color _kPrimaryText = Color(0xFF1A1A1A);
  static const Color _kSecondaryText = Color(0xFF666666);
  static const Color _kAccent = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _removeOverlay();
      return;
    }

    _cursorPosition = selection.baseOffset;

    // Find if we're in a mention or hashtag context
    final beforeCursor = text.substring(0, _cursorPosition);

    // Check for @mention
    final mentionMatch = RegExp(r'@(\w*)$').firstMatch(beforeCursor);
    if (mentionMatch != null) {
      _searchQuery = mentionMatch.group(1) ?? '';
      _isMentionSearch = true;
      _searchUsers(_searchQuery);
      return;
    }

    // Check for #hashtag
    final hashtagMatch = RegExp(r'#(\w*)$').firstMatch(beforeCursor);
    if (hashtagMatch != null) {
      _searchQuery = hashtagMatch.group(1) ?? '';
      _isMentionSearch = false;
      _searchHashtags(_searchQuery);
      return;
    }

    _removeOverlay();
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isSearching = true);

    if (query.isEmpty) {
      // Friend suggestions: show user's friends when @ with no query
      final result = await _friendService.getFriends(
        userId: widget.currentUserId,
        perPage: 10,
      );
      if (mounted) {
        setState(() {
          _isSearching = false;
          _suggestions = result.friends;
        });
        if (_suggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
      return;
    }

    final result = await _friendService.searchUsers(
      query,
      perPage: 5,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
        _suggestions = result.friends;
      });

      if (_suggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  Future<void> _searchHashtags(String query) async {
    setState(() => _isLoadingHashtags = true);

    if (query.isEmpty) {
      final result = await _hashtagService.getTrendingHashtags(limit: 8);
      if (mounted) {
        setState(() {
          _isLoadingHashtags = false;
          _hashtagSuggestions =
              result.hashtags.map((h) => h.name).take(8).toList();
        });
        if (_hashtagSuggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
      return;
    }

    final result = await _hashtagService.searchHashtags(query, limit: 8);
    if (mounted) {
      final names = result.hashtags.map((h) => h.name).toList();
      if (names.isEmpty && query.isNotEmpty) {
        names.insert(0, query);
      }
      setState(() {
        _isLoadingHashtags = false;
        _hashtagSuggestions = List<String>.from(names);
      });
      if (_hashtagSuggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccent.withOpacity(0.3)),
              ),
              child: _isMentionSearch
                  ? _buildMentionSuggestions()
                  : _buildHashtagSuggestions(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildMentionSuggestions() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _searchQuery.isEmpty
              ? 'Andika jina kutafuta rafiki'
              : 'Hakuna matokeo',
          style: const TextStyle(fontSize: 14, color: _kSecondaryText),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final user = _suggestions[index];
        return ListTile(
          minLeadingWidth: 0,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minVerticalPadding: 12,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: _kAccent.withOpacity(0.2),
            backgroundImage: user.profilePhotoUrl != null
                ? NetworkImage(user.profilePhotoUrl!)
                : null,
            child: user.profilePhotoUrl == null
                ? Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 14, color: _kPrimaryText),
                  )
                : null,
          ),
          title: Text(
            user.fullName,
            style: const TextStyle(fontSize: 14, color: _kPrimaryText),
          ),
          subtitle: user.username != null
              ? Text(
                  '@${user.username}',
                  style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                )
              : null,
          onTap: () => _insertMention(user),
        );
      },
    );
  }

  Widget _buildHashtagSuggestions() {
    if (_isLoadingHashtags) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hashtagSuggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Andika hashtag',
          style: TextStyle(fontSize: 14, color: _kSecondaryText),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _hashtagSuggestions.length,
      itemBuilder: (context, index) {
        final hashtag = _hashtagSuggestions[index];
        return ListTile(
          minLeadingWidth: 0,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minVerticalPadding: 12,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '#',
                style: TextStyle(
                  color: _kPrimaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(
            '#$hashtag',
            style: const TextStyle(fontSize: 14, color: _kPrimaryText),
          ),
          onTap: () => _insertHashtag(hashtag),
        );
      },
    );
  }

  void _insertMention(UserProfile user) {
    final text = widget.controller.text;
    final beforeCursor = text.substring(0, _cursorPosition);
    final afterCursor = text.substring(_cursorPosition);

    // Find the @ position
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex == -1) return;

    final displayName = user.username ?? user.fullName.replaceAll(' ', '');
    final newText = '${text.substring(0, atIndex)}@$displayName $afterCursor';

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: atIndex + displayName.length + 2, // +2 for @ and space
    );

    _removeOverlay();
    widget.onChanged?.call(newText);
    widget.onMentionSelected?.call(user);
  }

  void _insertHashtag(String hashtag) {
    final text = widget.controller.text;
    final beforeCursor = text.substring(0, _cursorPosition);
    final afterCursor = text.substring(_cursorPosition);

    // Find the # position
    final hashIndex = beforeCursor.lastIndexOf('#');
    if (hashIndex == -1) return;

    final newText = '${text.substring(0, hashIndex)}#$hashtag $afterCursor';

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: hashIndex + hashtag.length + 2, // +2 for # and space
    );

    _removeOverlay();
    widget.onChanged?.call(newText);
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ??
        InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
        );
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: widget.style,
        decoration: decoration,
        textAlign: widget.textAlign ?? TextAlign.start,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
        textInputAction: widget.onSubmitted != null ? TextInputAction.send : null,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}

/// Widget to display quick action buttons for inserting @ and #
class MentionHashtagBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onMentionTap;
  final VoidCallback? onHashtagTap;

  const MentionHashtagBar({
    super.key,
    required this.controller,
    this.onMentionTap,
    this.onHashtagTap,
  });

  void _insertAtCursor(String text) {
    final selection = controller.selection;
    final currentText = controller.text;

    if (!selection.isValid) {
      controller.text = currentText + text;
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      return;
    }

    final newText = currentText.substring(0, selection.baseOffset) +
        text +
        currentText.substring(selection.extentOffset);

    controller.text = newText;
    controller.selection = TextSelection.collapsed(
      offset: selection.baseOffset + text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BarAction(
          icon: Icons.alternate_email,
          label: 'Taja',
          onPressed: () {
            _insertAtCursor('@');
            onMentionTap?.call();
          },
        ),
        const SizedBox(width: 8),
        _BarAction(
          icon: Icons.tag,
          label: 'Hashtag',
          onPressed: () {
            _insertAtCursor('#');
            onHashtagTap?.call();
          },
        ),
      ],
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _BarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  static const Color _kPrimaryText = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: _kPrimaryText),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kPrimaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
