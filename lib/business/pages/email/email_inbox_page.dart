// lib/business/pages/email/email_inbox_page.dart
// Outlook-style inbox with folder drawer, swipe actions, and compose FAB.

import 'package:flutter/material.dart';
import 'email_compose_page.dart';
import 'email_detail_page.dart';
import 'email_mock_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kUnreadDot = Color(0xFF2979FF);

class EmailInboxPage extends StatefulWidget {
  final String emailAddress;
  final String displayName;

  const EmailInboxPage({
    super.key,
    required this.emailAddress,
    required this.displayName,
  });

  @override
  State<EmailInboxPage> createState() => _EmailInboxPageState();
}

class _EmailInboxPageState extends State<EmailInboxPage> {
  String _currentFolder = 'inbox';
  List<MockEmail> _emails = [];
  Map<String, int> _unreadCounts = {};
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bilingual
  bool get _isSwahili => false;

  String _folderLabel(String key) {
    const en = {
      'inbox': 'Inbox',
      'sent': 'Sent',
      'drafts': 'Drafts',
      'trash': 'Trash',
      'spam': 'Spam',
    };
    const sw = {
      'inbox': 'Kikasha',
      'sent': 'Zilizotumwa',
      'drafts': 'Rasimu',
      'trash': 'Takataka',
      'spam': 'Taka',
    };
    return (_isSwahili ? sw : en)[key] ?? key;
  }

  IconData _folderIcon(String key) {
    switch (key) {
      case 'inbox':
        return Icons.inbox_rounded;
      case 'sent':
        return Icons.send_rounded;
      case 'drafts':
        return Icons.drafts_rounded;
      case 'trash':
        return Icons.delete_outline_rounded;
      case 'spam':
        return Icons.warning_amber_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _emails = EmailMockService.getFolder(
          widget.emailAddress, _currentFolder);
      _unreadCounts =
          EmailMockService.getAllUnreadCounts(widget.emailAddress);
    });
  }

  void _switchFolder(String folder) {
    setState(() => _currentFolder = folder);
    _refresh();
    Navigator.of(context).pop(); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBackground,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _emails.isEmpty ? _buildEmpty() : _buildEmailList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _compose,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.edit_rounded, size: 22),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kCardBg,
      foregroundColor: _kPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.emailAddress,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(_folderLabel(_currentFolder),
              style: const TextStyle(
                  fontSize: 12, color: _kSecondary)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, size: 22),
          onPressed: _showSearch,
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    const folders = ['inbox', 'sent', 'drafts', 'trash', 'spam'];
    return Drawer(
      backgroundColor: _kCardBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                        _initials(widget.displayName.isNotEmpty
                            ? widget.displayName
                            : widget.emailAddress),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      widget.displayName.isNotEmpty
                          ? widget.displayName
                          : widget.emailAddress,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(widget.emailAddress,
                      style: const TextStyle(
                          fontSize: 13, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Divider(height: 24),
            // Folders
            ...folders.map((f) {
              final isSelected = f == _currentFolder;
              final count = _unreadCounts[f] ?? 0;
              return _FolderTile(
                icon: _folderIcon(f),
                label: _folderLabel(f),
                count: count,
                isSelected: isSelected,
                onTap: () => _switchFolder(f),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 56, color: _kSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            _isSwahili ? 'Hakuna barua pepe' : 'No emails',
            style: const TextStyle(
                fontSize: 16,
                color: _kSecondary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailList() {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _emails.length,
        itemBuilder: (context, index) {
          final email = _emails[index];
          return _EmailListTile(
            email: email,
            onTap: () => _openEmail(email),
            onDismissedLeft: () => _deleteEmail(email),
            onDismissedRight: () => _archiveEmail(email),
          );
        },
      ),
    );
  }

  void _openEmail(MockEmail email) {
    EmailMockService.markAsRead(widget.emailAddress, email.id);
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => EmailDetailPage(
        email: email,
        accountEmail: widget.emailAddress,
        accountName: widget.displayName,
      ),
    ))
        .then((_) => _refresh());
  }

  void _deleteEmail(MockEmail email) {
    EmailMockService.moveToTrash(widget.emailAddress, email.id);
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imehamishiwa takataka' : 'Moved to trash'),
        backgroundColor: _kPrimary,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _archiveEmail(MockEmail email) {
    EmailMockService.archive(widget.emailAddress, email.id);
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imehifadhiwa' : 'Archived'),
        backgroundColor: _kPrimary,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _showSearch() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.toLowerCase();
            final results = query.isEmpty
                ? <MockEmail>[]
                : EmailMockService.getFolder(widget.emailAddress, _currentFolder)
                    .where((e) =>
                        e.subject.toLowerCase().contains(query) ||
                        e.fromName.toLowerCase().contains(query) ||
                        e.preview.toLowerCase().contains(query))
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollCtrl) => Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: _isSwahili ? 'Tafuta barua pepe...' : 'Search emails...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Results
                  Expanded(
                    child: results.isEmpty
                        ? Center(
                            child: Text(
                              query.isEmpty
                                  ? (_isSwahili ? 'Andika kutafuta' : 'Type to search')
                                  : (_isSwahili ? 'Hakuna matokeo' : 'No results'),
                              style: const TextStyle(
                                  fontSize: 14, color: _kSecondary),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: results.length,
                            itemBuilder: (_, i) {
                              final email = results[i];
                              return ListTile(
                                leading: Icon(
                                  email.isRead
                                      ? Icons.email_outlined
                                      : Icons.email_rounded,
                                  color: _kSecondary,
                                  size: 20,
                                ),
                                title: Text(
                                  email.subject.isNotEmpty
                                      ? email.subject
                                      : '(No subject)',
                                  style: const TextStyle(
                                      fontSize: 14, color: _kPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  email.fromName,
                                  style: const TextStyle(
                                      fontSize: 12, color: _kSecondary),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _openEmail(email);
                                },
                              );
                            },
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

  void _compose() {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => EmailComposePage(
        fromAddress: widget.emailAddress,
        fromName: widget.displayName,
      ),
    ))
        .then((_) => _refresh());
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s@.]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ---------------------------------------------------------------------------
// Folder tile in drawer
// ---------------------------------------------------------------------------

class _FolderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FolderTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? _kPrimary.withValues(alpha: 0.07)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? _kPrimary : _kSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? _kPrimary : _kSecondary,
                    )),
              ),
              if (count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Email list tile (with swipe)
// ---------------------------------------------------------------------------

class _EmailListTile extends StatelessWidget {
  final MockEmail email;
  final VoidCallback onTap;
  final VoidCallback onDismissedLeft;
  final VoidCallback onDismissedRight;

  const _EmailListTile({
    required this.email,
    required this.onTap,
    required this.onDismissedLeft,
    required this.onDismissedRight,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !email.isRead;
    final dateStr = _formatDate(email.date);
    final initials = _initials(email.fromName);
    final avatarColor = _avatarColor(email.fromName);

    return Dismissible(
      key: ValueKey(email.id),
      background: Container(
        color: const Color(0xFF4CAF50),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.archive_rounded,
            color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        color: const Color(0xFFE53935),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDismissedRight();
        } else {
          onDismissedLeft();
        }
        return false; // We handle removal ourselves
      },
      child: Material(
        color: _kCardBg,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread dot
                SizedBox(
                  width: 10,
                  child: isUnread
                      ? Container(
                          margin: const EdgeInsets.only(top: 16),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _kUnreadDot,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Sender + date
                      Row(
                        children: [
                          Expanded(
                            child: Text(email.fromName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: _kPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text(dateStr,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isUnread
                                      ? _kPrimary
                                      : _kSecondary)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Row 2: Subject + attachment
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                                email.subject.isNotEmpty
                                    ? email.subject
                                    : '(No subject)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _kPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (email.hasAttachments)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.attach_file_rounded,
                                  size: 15, color: _kSecondary),
                            ),
                          if (email.isFlagged)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.flag_rounded,
                                  size: 15, color: Color(0xFFFF9800)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Row 3: Preview
                      Text(email.preview,
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s@.]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF546E7A),
      const Color(0xFF5C6BC0),
      const Color(0xFF26A69A),
      const Color(0xFF8D6E63),
      const Color(0xFF78909C),
      const Color(0xFF7E57C2),
      const Color(0xFF42A5F5),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
      const Color(0xFF66BB6A),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDay =
        DateTime(date.year, date.month, date.day);

    if (emailDay == today) {
      final h = date.hour;
      final m = date.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:$m $ampm';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (emailDay == yesterday) return 'Yesterday';

    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month]} ${date.day}';
  }
}
