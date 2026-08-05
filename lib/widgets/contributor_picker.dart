// lib/widgets/contributor_picker.dart
//
// Contributor picker — closes G-F-005 frontend wiring per posts.md §VI.
// Used from post composers and post-detail to add/remove contributors and
// declare revenue-share splits. Aggregate share_pct must <= 100; the widget
// previews remaining share so creators can keep splits consistent.

import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';
import '../services/contributor_service.dart';
import '../services/profile_service.dart';

class ContributorPicker extends StatefulWidget {
  /// Existing contributors (rendered as removable chips).
  final List<PostContributor> existing;

  /// Owner of the post — required for backend authorization.
  final int ownerUserId;

  /// Optional post id. When null, the widget operates in "compose" mode and
  /// returns selections via [onChanged] without hitting the API.
  final int? postId;

  /// Token for authenticated API calls.
  final String? token;

  /// Fired whenever the working selection changes (compose mode).
  final ValueChanged<List<ContributorDraft>>? onChanged;

  /// Fired after a successful add (post-detail mode).
  final ValueChanged<PostContributor>? onAdded;

  /// Fired after a successful remove (post-detail mode).
  final ValueChanged<int>? onRemoved;

  const ContributorPicker({
    super.key,
    required this.ownerUserId,
    this.existing = const [],
    this.postId,
    this.token,
    this.onChanged,
    this.onAdded,
    this.onRemoved,
  });

  @override
  State<ContributorPicker> createState() => _ContributorPickerState();
}

/// Compose-mode draft (no DB id yet).
class ContributorDraft {
  final int userId;
  final String name;
  final String? handle;
  final String? photoUrl;
  final String role;
  final double sharePct;

  const ContributorDraft({
    required this.userId,
    required this.name,
    this.handle,
    this.photoUrl,
    required this.role,
    required this.sharePct,
  });

  ContributorDraft copyWith({String? role, double? sharePct}) => ContributorDraft(
        userId: userId,
        name: name,
        handle: handle,
        photoUrl: photoUrl,
        role: role ?? this.role,
        sharePct: sharePct ?? this.sharePct,
      );
}

class _ContributorPickerState extends State<ContributorPicker> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kSurface = Colors.white;
  static const _kIconBg = Color(0xFFF5F5F5);

  final ProfileService _profileSvc = ProfileService();
  final ContributorService _contribSvc = ContributorService();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  List<UserSearchResult> _searchResults = const [];
  bool _searching = false;

  // Working set (compose mode) — server-mode reads from widget.existing.
  late List<ContributorDraft> _drafts;
  late List<PostContributor> _serverList;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.existing
        .map((c) => ContributorDraft(
              userId: c.userId,
              name: c.userName ?? 'User #${c.userId}',
              handle: c.userHandle,
              photoUrl: c.userPhotoUrl,
              role: c.role,
              sharePct: c.sharePct,
            ))
        .toList();
    _serverList = List.of(widget.existing);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _isComposeMode => widget.postId == null;

  double get _allocatedShare {
    if (_isComposeMode) {
      return _drafts.fold<double>(0.0, (acc, d) => acc + d.sharePct);
    }
    return _serverList.fold<double>(0.0, (acc, c) => acc + c.sharePct);
  }

  double get _remainingShare =>
      (100.0 - _allocatedShare).clamp(0.0, 100.0).toDouble();

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _searchResults = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q.trim()));
  }

  Future<void> _runSearch(String q) async {
    final results = await _profileSvc.searchUsers(
      query: q,
      excludeUserId: widget.ownerUserId,
      limit: 10,
    );
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  bool _alreadyAdded(int userId) {
    if (_isComposeMode) {
      return _drafts.any((d) => d.userId == userId);
    }
    return _serverList.any((c) => c.userId == userId);
  }

  Future<void> _showRoleAndSharePicker(UserSearchResult user) async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    String role = kContributorRoles.first;
    double share = _remainingShare > 10 ? 10.0 : _remainingShare;

    final picked = await showModalBottomSheet<({String role, double share})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _kIconBg,
                          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                              ? const Icon(Icons.person_rounded, size: 20, color: _kTertiary)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                              if (user.username != null)
                                Text(
                                  '@${user.username!}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _kBorder),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSw ? 'Jukumu' : 'Role',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: kContributorRoles.map((r) {
                            final selected = r == role;
                            return InkWell(
                              onTap: () => setSheet(() => role = r),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 32),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? _kPrimary : _kSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: selected ? _kPrimary : _kBorder),
                                ),
                                child: Text(
                                  _roleLabel(r, isSw: isSw),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selected ? _kSurface : _kPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isSw ? 'Asilimia ya mapato' : 'Revenue share',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${share.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          min: 0,
                          max: _remainingShare,
                          value: share.clamp(0.0, _remainingShare),
                          divisions: _remainingShare > 0
                              ? _remainingShare.toInt().clamp(1, 100)
                              : 1,
                          activeColor: _kPrimary,
                          inactiveColor: _kBorder,
                          onChanged: (v) => setSheet(() => share = v),
                        ),
                        Text(
                          isSw
                              ? 'Bado: ${_remainingShare.toStringAsFixed(1)}%'
                              : 'Remaining pool: ${_remainingShare.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: _kTertiary),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: _kSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: share <= 0
                            ? null
                            : () => Navigator.pop(ctx, (role: role, share: share)),
                        child: Text(
                          isSw ? 'Ongeza' : 'Add contributor',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (picked == null || !mounted) return;
    await _commitAdd(user, picked.role, picked.share);
  }

  Future<void> _commitAdd(UserSearchResult user, String role, double share) async {
    if (_isComposeMode) {
      setState(() {
        _drafts.add(ContributorDraft(
          userId: user.id,
          name: user.name,
          handle: user.username,
          photoUrl: user.photoUrl,
          role: role,
          sharePct: share,
        ));
        _searchCtrl.clear();
        _searchResults = const [];
      });
      widget.onChanged?.call(_drafts);
      return;
    }

    setState(() => _busy = true);
    final ok = await _contribSvc.add(
      postId: widget.postId!,
      ownerUserId: widget.ownerUserId,
      userId: user.id,
      role: role,
      sharePct: share,
      token: widget.token,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        // Optimistic insert; backend canonicalizes id/accepted.
        final newC = PostContributor(
          id: -DateTime.now().millisecondsSinceEpoch,
          postId: widget.postId!,
          userId: user.id,
          role: role,
          sharePct: share,
          userName: user.name,
          userHandle: user.username,
          userPhotoUrl: user.photoUrl,
          accepted: false,
        );
        _serverList.add(newC);
        _searchCtrl.clear();
        _searchResults = const [];
        widget.onAdded?.call(newC);
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add contributor.')),
      );
    }
  }

  Future<void> _removeDraft(ContributorDraft d) async {
    setState(() => _drafts.removeWhere((x) => x.userId == d.userId));
    widget.onChanged?.call(_drafts);
  }

  Future<void> _removeServer(PostContributor c) async {
    setState(() => _busy = true);
    final ok = await _contribSvc.remove(
      postId: widget.postId!,
      contributorId: c.id,
      ownerUserId: widget.ownerUserId,
      token: widget.token,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _serverList.removeWhere((x) => x.id == c.id);
        widget.onRemoved?.call(c.id);
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove contributor.')),
      );
    }
  }

  String _roleLabel(String role, {required bool isSw}) {
    if (isSw) {
      switch (role) {
        case 'photographer':
          return 'Mpiga picha';
        case 'editor':
          return 'Mhariri';
        case 'colorist':
          return 'Mhariri wa rangi';
        case 'thumbnail_designer':
          return 'Mbunifu wa kijipicha';
        case 'caption_writer':
          return 'Mwandishi wa maelezo';
        case 'narrator':
          return 'Msimulizi';
        case 'composer':
          return 'Mtunzi wa muziki';
        case 'creative_director':
          return 'Mkurugenzi wa ubunifu';
        default:
          return role;
      }
    }
    switch (role) {
      case 'photographer':
        return 'Photographer';
      case 'editor':
        return 'Editor';
      case 'colorist':
        return 'Colorist';
      case 'thumbnail_designer':
        return 'Thumbnail designer';
      case 'caption_writer':
        return 'Caption writer';
      case 'narrator':
        return 'Narrator';
      case 'composer':
        return 'Composer';
      case 'creative_director':
        return 'Creative director';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final allocated = _allocatedShare;
    final overAllocated = allocated > 100.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSw ? 'Wachangiaji' : 'Contributors',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: overAllocated ? _kPrimary : _kIconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${allocated.toStringAsFixed(1)}% / 100%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: overAllocated ? _kSurface : _kSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isSw
                ? 'Wachangiaji wanapata mgawanyo wa mapato kutoka chapisho hili.'
                : 'Contributors split revenue from this post by role + share.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          if (_isComposeMode) ..._drafts.map(_draftRow),
          if (!_isComposeMode) ..._serverList.map(_serverRow),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: _onQueryChanged,
            enabled: !_busy && _remainingShare > 0,
            style: const TextStyle(fontSize: 14, color: _kPrimary),
            decoration: InputDecoration(
              hintText: _remainingShare > 0
                  ? (isSw ? 'Tafuta mtumiaji…' : 'Search a user…')
                  : (isSw ? 'Asilimia imeisha' : 'Pool fully allocated'),
              hintStyle: const TextStyle(fontSize: 13, color: _kTertiary),
              prefixIcon: const Icon(Icons.search_rounded, color: _kTertiary),
              filled: true,
              fillColor: _kIconBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                backgroundColor: _kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                minHeight: 2,
              ),
            ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._searchResults.map(_searchResultRow),
          ],
        ],
      ),
    );
  }

  Widget _draftRow(ContributorDraft d) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _kIconBg,
            backgroundImage: (d.photoUrl != null && d.photoUrl!.isNotEmpty)
                ? NetworkImage(d.photoUrl!)
                : null,
            child: (d.photoUrl == null || d.photoUrl!.isEmpty)
                ? const Icon(Icons.person_rounded, size: 18, color: _kTertiary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  '${_roleLabel(d.role, isSw: isSw)} · ${d.sharePct.toStringAsFixed(1)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: _kSecondary),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => _removeDraft(d),
          ),
        ],
      ),
    );
  }

  Widget _serverRow(PostContributor c) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _kIconBg,
            backgroundImage: (c.userPhotoUrl != null && c.userPhotoUrl!.isNotEmpty)
                ? NetworkImage(c.userPhotoUrl!)
                : null,
            child: (c.userPhotoUrl == null || c.userPhotoUrl!.isEmpty)
                ? const Icon(Icons.person_rounded, size: 18, color: _kTertiary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.userName ?? 'User #${c.userId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  '${_roleLabel(c.role, isSw: isSw)} · ${c.sharePct.toStringAsFixed(1)}%'
                  '${c.accepted ? '' : (isSw ? ' · Inasubiri' : ' · Pending')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: _kSecondary),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: _busy ? null : () => _removeServer(c),
          ),
        ],
      ),
    );
  }

  Widget _searchResultRow(UserSearchResult u) {
    final added = _alreadyAdded(u.id);
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return InkWell(
      onTap: added || _remainingShare <= 0
          ? null
          : () => _showRoleAndSharePicker(u),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _kIconBg,
              backgroundImage: (u.photoUrl != null && u.photoUrl!.isNotEmpty)
                  ? NetworkImage(u.photoUrl!)
                  : null,
              child: (u.photoUrl == null || u.photoUrl!.isEmpty)
                  ? const Icon(Icons.person_rounded, size: 18, color: _kTertiary)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  if (u.username != null)
                    Text(
                      '@${u.username!}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                ],
              ),
            ),
            if (added)
              Text(
                isSw ? 'Imeongezwa' : 'Added',
                style: const TextStyle(fontSize: 12, color: _kTertiary),
              )
            else
              const Icon(Icons.add_rounded, size: 20, color: _kPrimary),
          ],
        ),
      ),
    );
  }
}
