// lib/events/widgets/person_picker_sheet.dart
// Reusable bottom sheet for selecting a TAJIRI user or adding a non-TAJIRI person.
// Used by: committee setup, guest management, invitation assignment, follow-up.
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../models/people_search_models.dart';
import '../../services/people_search_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Result from the person picker.
/// Either a TAJIRI user (userId != null) or an external person (phone != null).
class PickedPerson {
  final int? userId;
  final String name;
  final String? phone;
  final String? avatarUrl;

  PickedPerson({this.userId, required this.name, this.phone, this.avatarUrl});

  bool get isTajiriUser => userId != null;
}

/// Shows a bottom sheet to search and select a TAJIRI user,
/// or manually add a non-TAJIRI person by name + phone.
///
/// Returns [PickedPerson] or null if cancelled.
Future<PickedPerson?> showPersonPickerSheet(
  BuildContext context, {
  String? title,
  bool allowExternal = true,
}) {
  return showModalBottomSheet<PickedPerson>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _PersonPickerBody(
      title: title,
      allowExternal: allowExternal,
    ),
  );
}

class _PersonPickerBody extends StatefulWidget {
  final String? title;
  final bool allowExternal;

  const _PersonPickerBody({this.title, this.allowExternal = true});

  @override
  State<_PersonPickerBody> createState() => _PersonPickerBodyState();
}

class _PersonPickerBodyState extends State<_PersonPickerBody> {
  final _searchController = TextEditingController();
  final _searchService = PeopleSearchService();

  List<PersonSearchResult> _results = [];
  bool _isSearching = false;
  bool _showManualEntry = false;
  int? _currentUserId;

  // Manual entry
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUserId = _getCurrentUserId();
  }

  int? _getCurrentUserId() {
    final user = LocalStorageService.instanceSync?.getUser();
    return user?.userId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    final result = await _searchService.search(
      userId: _currentUserId ?? 0,
      query: query.trim(),
      perPage: 15,
    );
    if (mounted) {
      setState(() {
        _isSearching = false;
        if (result.success && result.response != null) {
          _results = result.response!.people;
        }
      });
    }
  }

  void _selectPerson(PersonSearchResult person) {
    String? avatarUrl;
    if (person.profilePhotoPath != null && person.profilePhotoPath!.isNotEmpty) {
      avatarUrl = '${ApiConfig.storageUrl}/${person.profilePhotoPath!.replaceFirst(RegExp(r'^/'), '')}';
    }
    Navigator.pop(context, PickedPerson(
      userId: person.id,
      name: '${person.firstName} ${person.lastName}'.trim(),
      avatarUrl: avatarUrl,
    ));
  }

  void _submitManual() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, PickedPerson(
      name: name,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    final isSwahili = lang == 'sw';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              widget.title ?? (isSwahili ? 'Chagua Mtu' : 'Select Person'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 12),

            // Toggle: Search TAJIRI / Add manually
            if (widget.allowExternal && !_showManualEntry)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showManualEntry = true),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(isSwahili ? 'Ongeza mtu asiye kwenye TAJIRI' : 'Add non-TAJIRI person'),
                  style: TextButton.styleFrom(foregroundColor: _kSecondary, textStyle: const TextStyle(fontSize: 12)),
                ),
              ),

            if (_showManualEntry) ...[
              // Manual entry form
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showManualEntry = false),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: Text(isSwahili ? 'Tafuta kwenye TAJIRI' : 'Search TAJIRI'),
                  style: TextButton.styleFrom(foregroundColor: _kSecondary, textStyle: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isSwahili ? 'Jina kamili *' : 'Full name *',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.person_rounded, size: 20, color: _kSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: isSwahili ? 'Nambari ya simu (hiari)' : 'Phone number (optional)',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: _kSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _nameController.text.trim().isNotEmpty ? _submitManual : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isSwahili ? 'Ongeza' : 'Add'),
                ),
              ),
            ] else ...[
              // Search field
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: isSwahili ? 'Tafuta jina au username...' : 'Search name or username...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _kSecondary),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),

              // Results
              Flexible(
                child: _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _searchController.text.length < 2
                                ? (isSwahili ? 'Andika angalau herufi 2' : 'Type at least 2 characters')
                                : (isSwahili ? 'Hakuna matokeo' : 'No results'),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (_, i) => _buildPersonTile(_results[i]),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonTile(PersonSearchResult person) {
    String? avatarUrl;
    if (person.profilePhotoPath != null && person.profilePhotoPath!.isNotEmpty) {
      avatarUrl = '${ApiConfig.storageUrl}/${person.profilePhotoPath!.replaceFirst(RegExp(r'^/'), '')}';
    }

    return InkWell(
      onTap: () => _selectPerson(person),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          person.firstName.isNotEmpty ? person.firstName[0].toUpperCase() : '?',
                          style: const TextStyle(color: _kSecondary, fontWeight: FontWeight.w600, fontSize: 16),
                        )
                      : null,
                ),
                if (person.isOnline)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${person.firstName} ${person.lastName}'.trim(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (person.username != null) ...[
                        Text('@${person.username}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                        const SizedBox(width: 8),
                      ],
                      if (person.locationString != null)
                        Flexible(
                          child: Text(
                            person.locationString!,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (person.mutualFriendsCount > 0)
                    Text(
                      '${person.mutualFriendsCount} mutual',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                ],
              ),
            ),

            // Select indicator
            const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
