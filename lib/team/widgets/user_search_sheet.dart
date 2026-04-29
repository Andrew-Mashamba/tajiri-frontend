// lib/team/widgets/user_search_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../services/team_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class UserSearchSheet extends StatefulWidget {
  final String token;
  final void Function(PlatformUser user) onSelected;

  const UserSearchSheet({
    super.key,
    required this.token,
    required this.onSelected,
  });

  @override
  State<UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<UserSearchSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<PlatformUser> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(
        const Duration(milliseconds: 400), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    final res = await TeamService.searchPlatformUsers(widget.token, q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _results = res.data;
        _error = null;
      } else {
        _error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sw ? 'Chagua Mwanatimu' : 'Select Team Member',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: sw
                  ? 'Tafuta jina au username...'
                  : 'Search by name or username...',
              prefixIcon:
                  const Icon(Icons.search_rounded, color: _kSecondary),
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                    color: _kPrimary, strokeWidth: 2),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_error!,
                  style:
                      const TextStyle(color: Colors.red, fontSize: 13)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final u = _results[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: u.avatarUrl != null
                          ? NetworkImage(u.avatarUrl!)
                          : null,
                      child: u.avatarUrl == null
                          ? Text(
                              u.name.isNotEmpty
                                  ? u.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: _kPrimary,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(u.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _kPrimary)),
                    subtitle: Text('@${u.username}',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary)),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelected(u);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
