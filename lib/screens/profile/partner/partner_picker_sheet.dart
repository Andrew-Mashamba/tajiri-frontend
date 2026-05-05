// PartnerPickerSheet — modal bottom sheet for tagging a partner.
// Spec: profile screen relationship row "+ Tag partner" → opens this →
// 300ms debounced @handle search → user picks one → POST partner →
// sheet closes with the new PartnerLink for the caller to refresh state.
//
// Flow is unilateral (option A): no confirmation from the tagged user;
// either party can untag freely.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../models/profile_models.dart';
import '../../../services/profile_service.dart';
import '../../../widgets/user_avatar.dart';

class PartnerPickerSheet extends StatefulWidget {
  final int currentUserId;
  final int? existingPartnerId;

  const PartnerPickerSheet({
    super.key,
    required this.currentUserId,
    this.existingPartnerId,
  });

  /// Show the sheet. Returns the newly-tagged [PartnerLink] on success,
  /// or null if dismissed.
  static Future<PartnerLink?> show(
    BuildContext context, {
    required int currentUserId,
    int? existingPartnerId,
  }) {
    return showModalBottomSheet<PartnerLink>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PartnerPickerSheet(
        currentUserId: currentUserId,
        existingPartnerId: existingPartnerId,
      ),
    );
  }

  @override
  State<PartnerPickerSheet> createState() => _PartnerPickerSheetState();
}

class _PartnerPickerSheetState extends State<PartnerPickerSheet> {
  final ProfileService _service = ProfileService();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _debounce;
  bool _searching = false;
  bool _saving = false;
  String? _error;
  List<UserSearchResult> _results = [];
  UserSearchResult? _selected;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
    // Auto-focus the search field after the sheet's entrance animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onQueryChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
        _error = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String query) async {
    final results = await _service.searchUsers(
      query: query,
      excludeUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = results;
      // If the previously selected user no longer matches the new query,
      // drop the selection.
      if (_selected != null &&
          !results.any((r) => r.id == _selected!.id)) {
        _selected = null;
      }
    });
  }

  Future<void> _confirmTag() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await _service.setPartner(
      userId: widget.currentUserId,
      partnerUserId: selected.id,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _error = AppStringsScope.of(context)?.isSwahili == true
            ? 'Imeshindwa kuhifadhi mpenzi'
            : 'Failed to save partner';
      });
      return;
    }
    Navigator.of(context).pop(PartnerLink(
      id: selected.id,
      name: selected.name,
      username: selected.username,
      photoUrl: selected.photoUrl,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildHeader(isSw),
              const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5E5)),
              _buildSearchField(isSw),
              if (_error != null) _buildErrorBanner(_error!),
              Flexible(child: _buildResults(isSw)),
              if (_selected != null) _buildConfirmBar(isSw),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isSw) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isSw ? 'Mtaje mpenzi wako' : 'Tag your partner',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            iconSize: 22,
            color: const Color(0xFF666666),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isSw) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        autocorrect: false,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: isSw ? 'Tafuta kwa @handle' : 'Search by @handle',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF666666)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    _onQueryChanged();
                  },
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF999999)),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildResults(bool isSw) {
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      );
    }
    if (_searchCtrl.text.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.alternate_email_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                isSw
                    ? 'Andika @handle au jina la mpenzi wako.'
                    : 'Type your partner\'s @handle or name.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            isSw ? 'Hakuna matokeo' : 'No matches',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        final isSelected = _selected?.id == user.id;
        return _UserResultTile(
          user: user,
          selected: isSelected,
          onTap: () {
            setState(() => _selected = user);
          },
        );
      },
    );
  }

  Widget _buildConfirmBar(bool isSw) {
    final selected = _selected!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSw
                ? (selected.username != null
                    ? 'Mtaje @${selected.username} kama mpenzi wako?'
                    : 'Mtaje ${selected.name} kama mpenzi wako?')
                : (selected.username != null
                    ? 'Tag @${selected.username} as your partner?'
                    : 'Tag ${selected.name} as your partner?'),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => setState(() => _selected = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFE5E5E5)),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isSw ? 'Ghairi' : 'Cancel',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _confirmTag,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: const Color(0xFFFAFAFA),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFAFAFA),
                          ),
                        )
                      : Text(
                          isSw ? 'Mtaje' : 'Tag',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: const Color(0xFFEF9A9A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B0000)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final UserSearchResult user;
  final bool selected;
  final VoidCallback onTap;

  const _UserResultTile({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0x141A1A1A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: user.photoUrl,
                name: user.name,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name.isEmpty ? '—' : user.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.username != null && user.username!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: Color(0xFF1A1A1A),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
