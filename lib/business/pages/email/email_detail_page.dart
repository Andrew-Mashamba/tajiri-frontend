// lib/business/pages/email/email_detail_page.dart
// Email reading view — shows full email content with reply/forward actions.

import 'package:flutter/material.dart';
import 'email_compose_page.dart';
import 'email_mock_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmailDetailPage extends StatefulWidget {
  final MockEmail email;
  final String accountEmail;
  final String accountName;

  const EmailDetailPage({
    super.key,
    required this.email,
    required this.accountEmail,
    required this.accountName,
  });

  @override
  State<EmailDetailPage> createState() => _EmailDetailPageState();
}

class _EmailDetailPageState extends State<EmailDetailPage> {
  late MockEmail _email;
  bool _showRecipients = false;

  // Bilingual
  bool get _isSwahili => false;
  String get _replyLabel => _isSwahili ? 'Jibu' : 'Reply';
  String get _replyAllLabel => _isSwahili ? 'Jibu Wote' : 'Reply All';
  String get _forwardLabel => _isSwahili ? 'Tuma Mbele' : 'Forward';
  String get _deleteLabel => _isSwahili ? 'Futa' : 'Delete';
  String get _toLabel => _isSwahili ? 'Kwa' : 'To';
  String get _ccLabel => 'CC';
  String get _attachmentsLabel =>
      _isSwahili ? 'Viambatisho' : 'Attachments';

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    // Mark as read
    EmailMockService.markAsRead(widget.accountEmail, _email.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _email.isFlagged
                  ? Icons.flag_rounded
                  : Icons.flag_outlined,
              color: _email.isFlagged
                  ? const Color(0xFFFF9800)
                  : _kSecondary,
              size: 22,
            ),
            onPressed: _toggleFlag,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22),
            onPressed: _delete,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            color: _kCardBg,
            onSelected: _onMenuAction,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'unread',
                child: Text(
                    _isSwahili ? 'Weka haijasomwa' : 'Mark as unread',
                    style: const TextStyle(fontSize: 14)),
              ),
              PopupMenuItem(
                value: 'flag',
                child: Text(
                    _email.isFlagged
                        ? (_isSwahili ? 'Ondoa bendera' : 'Unflag')
                        : (_isSwahili ? 'Weka bendera' : 'Flag'),
                    style: const TextStyle(fontSize: 14)),
              ),
              PopupMenuItem(
                value: 'move',
                child: Text(
                    _isSwahili ? 'Hamishia folda' : 'Move to folder',
                    style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(_email.subject.isNotEmpty ? _email.subject : '(No subject)',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                  height: 1.3)),
          const SizedBox(height: 16),

          // Sender row
          _buildSenderRow(),
          const SizedBox(height: 12),

          // Recipients (collapsible)
          _buildRecipients(),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          const SizedBox(height: 20),

          // Body
          SelectableText(_email.body,
              style: const TextStyle(
                  fontSize: 15,
                  color: _kPrimary,
                  height: 1.6)),
          const SizedBox(height: 24),

          // Attachments
          if (_email.hasAttachments &&
              _email.attachments != null &&
              _email.attachments!.isNotEmpty)
            _buildAttachments(),
        ],
      ),
    );
  }

  Widget _buildSenderRow() {
    final initials = _initials(_email.fromName);
    final avatarColor = _avatarColor(_email.fromName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: avatarColor,
            borderRadius: BorderRadius.circular(21),
          ),
          alignment: Alignment.center,
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_email.fromName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary)),
              const SizedBox(height: 2),
              Text(_email.from,
                  style: const TextStyle(
                      fontSize: 13, color: _kSecondary)),
            ],
          ),
        ),
        Text(_formatDateTime(_email.date),
            style: const TextStyle(fontSize: 12, color: _kSecondary)),
      ],
    );
  }

  Widget _buildRecipients() {
    return GestureDetector(
      onTap: () => setState(() => _showRecipients = !_showRecipients),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$_toLabel: ',
                  style: const TextStyle(
                      fontSize: 13,
                      color: _kSecondary,
                      fontWeight: FontWeight.w500)),
              Expanded(
                child: Text(
                  _showRecipients
                      ? _email.to.join(', ')
                      : (_email.to.isNotEmpty
                          ? _email.to.first
                          : 'me'),
                  style: const TextStyle(
                      fontSize: 13, color: _kSecondary),
                  maxLines: _showRecipients ? 5 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _showRecipients
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: _kSecondary,
              ),
            ],
          ),
          if (_showRecipients &&
              _email.cc != null &&
              _email.cc!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_ccLabel: ',
                    style: const TextStyle(
                        fontSize: 13,
                        color: _kSecondary,
                        fontWeight: FontWeight.w500)),
                Expanded(
                  child: Text(_email.cc!.join(', '),
                      style: const TextStyle(
                          fontSize: 13, color: _kSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_attachmentsLabel,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary)),
        const SizedBox(height: 10),
        ...(_email.attachments ?? []).map((att) => _AttachmentTile(
              attachment: att,
              onTap: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_isSwahili
                        ? 'Kupakua "${att.name}"...'
                        : 'Downloading "${att.name}"...'),
                    backgroundColor: _kPrimary,
                    duration: const Duration(seconds: 2),
                  ));
                }
              },
            )),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(
            top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomAction(
            icon: Icons.reply_rounded,
            label: _replyLabel,
            onTap: () => _reply(replyAll: false),
          ),
          _BottomAction(
            icon: Icons.reply_all_rounded,
            label: _replyAllLabel,
            onTap: () => _reply(replyAll: true),
          ),
          _BottomAction(
            icon: Icons.forward_rounded,
            label: _forwardLabel,
            onTap: _forward,
          ),
          _BottomAction(
            icon: Icons.delete_outline_rounded,
            label: _deleteLabel,
            onTap: _delete,
          ),
        ],
      ),
    );
  }

  // -- Actions ---------------------------------------------------------------

  void _toggleFlag() {
    EmailMockService.flagEmail(widget.accountEmail, _email.id);
    final updated =
        EmailMockService.getEmail(widget.accountEmail, _email.id);
    if (updated != null && mounted) {
      setState(() => _email = updated);
    }
  }

  void _delete() {
    EmailMockService.moveToTrash(widget.accountEmail, _email.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'unread':
        EmailMockService.markAsUnread(
            widget.accountEmail, _email.id);
        if (mounted) Navigator.of(context).pop();
        break;
      case 'flag':
        _toggleFlag();
        break;
      case 'move':
        _showMoveDialog();
        break;
    }
  }

  void _showMoveDialog() {
    final folders = ['inbox', 'sent', 'drafts', 'trash', 'spam'];
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: folders.map((f) {
              final label = {
                    'inbox': _isSwahili ? 'Kikasha' : 'Inbox',
                    'sent': _isSwahili ? 'Zilizotumwa' : 'Sent',
                    'drafts': _isSwahili ? 'Rasimu' : 'Drafts',
                    'trash': _isSwahili ? 'Takataka' : 'Trash',
                    'spam': 'Spam',
                  }[f] ??
                  f;
              return ListTile(
                leading: const Icon(Icons.folder_outlined,
                    color: _kSecondary, size: 20),
                title: Text(label,
                    style: const TextStyle(
                        fontSize: 14, color: _kPrimary)),
                onTap: () {
                  EmailMockService.moveToFolder(
                      widget.accountEmail, _email.id, f);
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _reply({required bool replyAll}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EmailComposePage(
        fromAddress: widget.accountEmail,
        fromName: widget.accountName,
        replyTo: _email,
        replyAll: replyAll,
      ),
    ));
  }

  void _forward() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EmailComposePage(
        fromAddress: widget.accountEmail,
        fromName: widget.accountName,
        forwardEmail: _email,
      ),
    ));
  }

  // -- Helpers ---------------------------------------------------------------

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

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDay = DateTime(date.year, date.month, date.day);

    final h = date.hour;
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final time = '$h12:$m $ampm';

    if (emailDay == today) return time;

    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month]} ${date.day}, ${date.year} $time';
  }
}

// ---------------------------------------------------------------------------
// Attachment tile
// ---------------------------------------------------------------------------

class _AttachmentTile extends StatelessWidget {
  final MockAttachment attachment;
  final VoidCallback onTap;

  const _AttachmentTile({required this.attachment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _kBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Row(
              children: [
                Icon(_fileIcon(attachment.type),
                    size: 22, color: _kSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(attachment.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(attachment.size,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.download_rounded,
                    size: 20, color: _kSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _fileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// Bottom action button
// ---------------------------------------------------------------------------

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: _kSecondary),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: _kSecondary)),
          ],
        ),
      ),
    );
  }
}
