import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/friend_models.dart';
import '../../services/friend_service.dart';
import '../../widgets/user_avatar.dart';

// DESIGN.md: background #FAFAFA, primary text #1A1A1A, secondary #666666, min touch 48dp
const Color _kBg = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const double _kMinTouchHeight = 48.0;

/// Users tab content for global search. Search by name, username via GET /api/users/search.
class UserSearchTab extends StatefulWidget {
  final int currentUserId;

  const UserSearchTab({super.key, required this.currentUserId});

  @override
  State<UserSearchTab> createState() => _UserSearchTabState();
}

class _UserSearchTabState extends State<UserSearchTab> {
  final FriendService _friendService = FriendService();
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 350);

  List<UserProfile> _results = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {
      if (value.trim().isEmpty) {
        _results = [];
        _error = null;
        _hasSearched = false;
      }
    });
    if (value.trim().isEmpty) return;
    _debounce = Timer(_debounceDuration, () {
      if (mounted) _performSearch(_queryController.text.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    final result = await _friendService.searchUsers(query);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _results = result.success ? result.friends : [];
      _error = result.success ? null : (result.message ?? 'Imeshindwa kutafuta');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _queryController,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Tafuta kwa jina au jina la mtumiaji...',
                hintStyle: const TextStyle(color: _kSecondaryText, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _kSecondaryText, size: 24),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: _kSecondaryText),
                        onPressed: () {
                          _queryController.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(color: _kPrimaryText, fontSize: 14),
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return Center(
        child: Text(
          'Andika jina au jina la mtumiaji kutafuta',
          style: TextStyle(color: _kSecondaryText, fontSize: 14),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _kSecondaryText, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => _performSearch(_queryController.text.trim()),
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Hakuna matokeo',
              style: TextStyle(color: _kSecondaryText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _results[index];
        return Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile/${user.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: _kMinTouchHeight),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  UserAvatar(
                    photoUrl: user.profilePhotoUrl,
                    name: user.fullName,
                    radius: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: _kPrimaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.username != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: _kSecondaryText,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: _kSecondaryText, size: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
